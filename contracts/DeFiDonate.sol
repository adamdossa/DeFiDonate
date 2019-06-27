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
    //TODO: Make epochLength a timestamp
    uint256 public epochLength;

    mapping (address => uint256) public updatedBlock;

    uint256 public nextEpoch;

    // Capture wrapped charity DAI as a token so it can be transferred / sent
    // deposit / redeem becomes wrap / unwrap
    // CharityToken is minted separately

    constructor(string memory _name, string memory _symbol, uint8 _decimals, address _depositToken, address _compound, address _charity, uint256 _epochLength) public
        ERC20Detailed(_name, _symbol, _decimals)
    {
        governanceToken = new GovernanceToken("GOV1", "GOV2", 18);
        depositToken = ERC20(_depositToken);
        compound = ICompound(_compound);
        charity = _charity;
        epochLength = _epochLength;
        nextEpoch = block.number.add(epochLength);
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
    }

    function unwrap(uint256 _amount) external {
        require(_amount <= balanceOf(msg.sender));
        update(msg.sender);
        _burn(msg.sender, _amount);
        require(compound.redeemUnderlying(_amount) == 0);
        require(depositToken.transfer(msg.sender, _amount));
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
        require(governanceToken.mint(_account, accrued(_account)));
        updatedBlock[_account] = block.number;
    }

    function accrued(address _account) public view returns (uint256) {
        return block.number.sub(updatedBlock[_account]).mul(balanceOf(_account));
    }

    function restartEpoch() external {
        require(block.number >= nextEpoch);
        nextEpoch = block.number.add(epochLength);
        uint256 interest = compound.balanceOfUnderlying(address(this)).sub(totalSupply());
        require(compound.redeemUnderlying(interest) == 0);
        require(depositToken.transfer(charity, interest));
    }

}
