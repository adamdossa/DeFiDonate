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

//"GDAI", "GDAI", 18, "0x5592ec0cfb4dbc12d3ab100b257153436a1f0fea", "0x6D7F0754FFeb405d23C51CE938289d4835bE3b14", "0x85523D0f76B3A6C3c05b2CfBb0558B45541f100B", 100
contract DeFiDonate is ERC20, ERC20Detailed {
    using SafeMath for uint256;

    GovernanceToken public governanceToken;
    ERC20 public depositToken;
    ICompound public compound;

    address public charity;
    uint256 public epochLength;
    uint256 public coolOffLength;

    mapping (address => uint256) public updatedBlock;

    uint256 public nextEpoch;

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
        governanceToken = new GovernanceToken("GOV1", "GOV2", 18);
        depositToken = ERC20(_depositToken);
        compound = ICompound(_compound);
        charity = _charity;
        epochLength = _epochLength;
        coolOffLength = _coolOffLength;
        nextEpoch = block.timestamp.add(epochLength);
    }

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

    function unwrap(uint256 _amount) external {
        require(_amount <= balanceOf(msg.sender));
        update(msg.sender);
        _burn(msg.sender, _amount);
        require(compound.redeemUnderlying(_amount) == 0);
        require(depositToken.transfer(msg.sender, _amount));
        emit Unwrapped(msg.sender, _amount);
    }

    function transfer(address _recipient, uint256 _amount) public returns (bool) {
        update(msg.sender);
        update(_recipient);
        super.transfer(_recipient, _amount);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        update(msg.sender);
        update(_spender);
        super.approve(_spender, _value);
        return true;
    }

    function transferFrom(address _sender, address _recipient, uint256 _amount) public returns (bool) {
        update(_sender);
        update(_recipient);
        super.transferFrom(_sender, _recipient, _amount);
        return true;
    }

    function update(address _account) public {
        uint256 interest = accrued(_account);
        emit Accrued(_account, interest);
        require(governanceToken.mint(_account, interest));
        updatedBlock[_account] = block.number;
    }

    function accrued(address _account) public view returns (uint256) {
        return block.number.sub(updatedBlock[_account]).mul(balanceOf(_account));
    }

    address chosenCharity;
    address largestCharity;
    uint256 largestVote;
    uint256 rolledEpoch;
    mapping (address => uint256) public votes;

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

    function restartEpoch() external {
        require(block.timestamp >= nextEpoch);
        nextEpoch = block.timestamp.add(epochLength);
        if (charity != address(0)) {
            uint256 interest = compound.balanceOfUnderlying(address(this)).sub(totalSupply());
            require(compound.redeemUnderlying(interest) == 0);
            require(depositToken.transfer(charity, interest));
            emit Donated(charity, interest);
        }
        charity = chosenCharity;
    }

}
