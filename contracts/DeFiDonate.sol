pragma solidity ^0.5.0;

// Everyone who deposits funds is issued time tokens.
// 1 CHAR token is equivalent to 1 DAI for 1 block and represents your voting power
// There are three phases - voting, deposit and donate
// In the voting phase CHAR holders vote on the address they would like to receive funds from the next deposit phase.
// In the deposit phases people can depositnpm
// Each epoch (e.g. 1000 blocks)

import 'openzeppelin-solidity/contracts/token/ERC20/ERC20.sol';
import 'openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol';
import 'openzeppelin-solidity/contracts/math/SafeMath.sol';
import './GovernanceToken.sol';
import './ICompound.sol';
import './IDeFiDonate.sol';

// Rinkeby deployment parameters
//"GDAI", "GDAI", 18, "0x5592ec0cfb4dbc12d3ab100b257153436a1f0fea", "0x6D7F0754FFeb405d23C51CE938289d4835bE3b14", "0x85523D0f76B3A6C3c05b2CfBb0558B45541f100B", 100


// Represents wrapped DAI that has been deposited to Compound
// Can be freely transferred as an ERC20
// Wrapping / Unwrapping can happen at any time

contract DeFiDonate is ERC20, ERC20Detailed {
    using SafeMath for uint256;

    GovernanceToken public governanceToken; // token which accrues to holders of wrapped DAI
    ERC20 public depositToken; // DAI token address
    ICompound public compound; // Address of compound contract

    address public charity; // Address which will receive funds at the end of the current epoch
    uint256 public epochLength; // Length of each epoch (e.g. 1 month)
    uint256 public coolOffLength; // Period of time that people have to withdraw their funds if they don't like the winning charity

    mapping (address => uint256) public updatedBlock; // Last time that governanceToken balance was updated for an address

    uint256 public nextEpoch; // Timestamp that next epoch starts on

    address public chosenCharity; // The charity that will be paid to in the following epoch
    address public largestCharity; // Charity currently winning the voting process
    uint256 public largestVote; // Number of votes the above charity has
    uint256 public rolledEpoch; // Whether or not the vote has been reset for a particular epoch
    mapping (address => uint256) public votes; // Votes for each proposed charity address

    event Accrued(address indexed _account, uint256 _accrued);
    event Wrapped(address indexed _account, uint256 _amount);
    event Unwrapped(address indexed _account, uint256 _amount);
    event Donated(address indexed _charity, uint256 _amount);

    // Capture wrapped charity DAI as a token so it can be transferred / sent
    // deposit / redeem becomes wrap / unwrap
    // CharityToken is minted separately

    constructor(string memory _name, string memory _symbol, uint8 _decimals, address _depositToken, address _compound, address _charity, uint256 _epochLength, uint256 _coolOffLength) public
        ERC20Detailed(_name, _symbol, _decimals)
    {
        require(_charity != address(0));
        require(_coolOffLength < _epochLength);
        governanceToken = new GovernanceToken(concat(_name, " - Voting"), concat(_symbol, "_VOTE", 18));
        depositToken = ERC20(_depositToken);
        compound = ICompound(_compound);
        charity = _charity;
        epochLength = _epochLength;
        coolOffLength = _coolOffLength;
        nextEpoch = block.timestamp.add(epochLength);
    }

    function concat(string _a, string _b) public pure returns (string){
        bytes memory bytes_a = bytes(_a);
        bytes memory bytes_b = bytes(_b);
        string memory length_ab = new string(bytes_a.length + bytes_b.length);
        bytes memory bytes_c = bytes(length_ab);
        uint k = 0;
        for (uint i = 0; i < bytes_a.length; i++) bytes_c[k++] = bytes_a[i];
        for (i = 0; i < bytes_b.length; i++) bytes_c[k++] = bytes_b[i];
        return string(bytes_c);
    }

    // Wrap DAI and receive back wrapped tokens on a 1-1 basis
    function wrap(uint256 _amount) external {
        require(depositToken.transferFrom(msg.sender, address(this), _amount));
        require(depositToken.approve(address(compound), _amount));
        require(compound.mint(_amount) == 0);
        if (updatedBlock[msg.sender] == 0) {
            updatedBlock[msg.sender] = block.number;
        }
        update(msg.sender);
        _mint(msg.sender, _amount);
        emit Wrapped(msg.sender, _amount);
    }

    // Unwrap your tokens back to DAI - depends on Compound liquidity
    function unwrap(uint256 _amount) external {
        require(_amount <= balanceOf(msg.sender));
        update(msg.sender);
        _burn(msg.sender, _amount);
        require(compound.redeemUnderlying(_amount) == 0);
        require(depositToken.transfer(msg.sender, _amount));
        emit Unwrapped(msg.sender, _amount);
    }

    function transfer(address _recipient, uint256 _amount) public returns (bool) {
        // Ensure that GovernanceToken balances are correctly reflected before executing transfer
        update(msg.sender);
        update(_recipient);
        super.transfer(_recipient, _amount);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        // Ensure that GovernanceToken balances are correctly reflected before executing transfer
        update(msg.sender);
        update(_spender);
        super.approve(_spender, _value);
        return true;
    }

    function transferFrom(address _sender, address _recipient, uint256 _amount) public returns (bool) {
        // Ensure that GovernanceToken balances are correctly reflected before executing transfer
        update(_sender);
        update(_recipient);
        super.transferFrom(_sender, _recipient, _amount);
        return true;
    }

    function update(address _account) public {
        // Update the GovernanceToken balance for an address - can be called at anytime by anyone
        uint256 interest = accrued(_account);
        emit Accrued(_account, interest);
        require(governanceToken.mint(_account, interest));
        updatedBlock[_account] = block.number;
    }

    // Return the amount of GovernanceTokens owed to an account
    function accrued(address _account) public view returns (uint256) {
        return block.number.sub(updatedBlock[_account]).mul(balanceOf(_account));
    }

    // Burn your GovernanceTokens in return for voting for a charity
    function vote(address _charity, uint256 _amount) external {
        require(_charity != address(0));
        bool resetVotes = false;
        if ((nextEpoch != rolledEpoch) && (block.timestamp > nextEpoch.sub(coolOffLength))) {
            rolledEpoch = nextEpoch;
            resetVotes = true;
            chosenCharity = largestCharity;
            largestCharity = address(0);
            largestVote = 0;
            votes[_charity] = 0;
        }
        update(msg.sender);
        governanceToken.burn(_amount);
        votes[_charity] = votes[_charity].add(_amount);
        if (votes[_charity] > largestVote) {
            largestCharity = _charity;
            largestVote = votes[_charity];
        }
    }

    // Can be called by anyone to pay to the current charity and roll over voting to the next epoch
    function epochDonate() external {
        require(block.timestamp >= nextEpoch);
        nextEpoch = block.timestamp.add(epochLength);
        uint256 interest = compound.balanceOfUnderlying(address(this)).sub(totalSupply());
        require(compound.redeemUnderlying(interest) == 0);
        require(depositToken.transfer(charity, interest));
        emit Donated(charity, interest);
        if (chosenCharity != address(0)) {
            charity = chosenCharity;
        }
    }

}
