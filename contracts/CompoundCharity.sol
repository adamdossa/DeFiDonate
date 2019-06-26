pragma solidity ^0.5.0;

// Everyone who deposits funds is issued time tokens.
// 1 CHAR token is equivalent to 1 DAI for 1 block and represents your voting power
// There are three phases - voting, deposit and donate
// In the voting phase CHAR holders vote on the address they would like to receive funds from the next deposit phase.
// In the deposit phases people can depositnpm
// Each epoch (e.g. 1000 blocks)

import 'openzeppelin-solidity/contracts/token/ERC20/ERC20.sol';
import 'openzeppelin-solidity/contracts/math/SafeMath.sol';
import './CharityToken.sol';

interface CToken {
    /**
     * @notice Sender redeems cTokens in exchange for the underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemTokens The number of cTokens to redeem into underlying
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeem(uint redeemTokens) external returns (uint);
    /**
     * @notice Sender redeems cTokens in exchange for a specified amount of underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemAmount The amount of underlying to redeem
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeemUnderlying(uint redeemAmount) external returns (uint);

    /**
     * @notice Sender supplies assets into the market and receives cTokens in exchange
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param mintAmount The amount of the underlying asset to supply
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function mint(uint mintAmount) external returns (uint);

    /**
     * @notice Get the underlying balance of the `owner`
     * @dev This also accrues interest in a transaction
     * @param owner The address of the account to query
     * @return The amount of underlying owned by `owner`
     */
    function balanceOfUnderlying(address owner) external returns (uint);
}

contract CompoundCharity {
    using SafeMath for uint256;

    CharityToken public charityToken;
    ERC20 public depositToken;
    CToken public compound;

    address public charity;

    mapping (address => uint256) updatedBlock;
    mapping (address => uint256) balances;

    uint256 nextEpoch;
    uint256 depositBalance;

    constructor(address _depositToken, address _compound, address _charity) public {
        charityToken = new CharityToken("DeFiDonate", "DFD", 18);
        depositToken = ERC20(_depositToken);
        compound = CToken(_compound);
        charity = _charity;
    }

    function deposit(uint256 _amount) external {
        uint256 balance = depositToken.balanceOf(msg.sender);
        require(depositToken.transferFrom(msg.sender, address(this), _amount));
        require(depositToken.approve(address(compound), _amount));
        require(compound.mint(_amount) == 0);
        depositBalance = depositBalance.add(_amount);
        balances[msg.sender] = balances[msg.sender].add(_amount);
        if (updatedBlock[msg.sender] != 0) {
            updatedBlock[msg.sender] = block.number;
        }
        uint256 earnedCharityTokens =
            block.number.sub(updatedBlock[msg.sender]).mul(balance);
        updatedBlock[msg.sender] = block.number;
        require(charityToken.mint(msg.sender, earnedCharityTokens));
    }

    function withdraw(uint256 _amount) external {
        require(_amount <= balances[msg.sender]);
        depositBalance = depositBalance.sub(_amount);
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        require(compound.redeemUnderlying(_amount) == 0);
        require(depositToken.transfer(msg.sender, _amount));
    }

    function restartEpoch() external {
        require(block.number >= nextEpoch);
        nextEpoch = block.number;
        uint256 interest = compound.balanceOfUnderlying(address(this)).sub(depositBalance);
        require(compound.redeemUnderlying(interest) == 0);
        require(depositToken.transfer(charity, interest));
    }

}
