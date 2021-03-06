pragma solidity ^0.5.0;

// Everyone who deposits funds is issued time tokens.
// 1 CHAR token is equivalent to 1 DAI for 1 block and represents your voting power
// There are three phases - voting, deposit and donate
// In the voting phase CHAR holders vote on the address they would like to receive funds from the next deposit phase.
// In the deposit phases people can depositnpm
// Each epoch (e.g. 1000 blocks)

import 'openzeppelin-solidity/contracts/token/ERC20/ERC20Mintable.sol';
import 'openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol';
import './IDeFiDonate.sol';

contract GovernanceToken is ERC20Mintable, ERC20Detailed {

    IDeFiDonate public deFiDonate;

    constructor (string memory _name, string memory _symbol, uint8 _decimals) public
        ERC20Detailed(_name, _symbol, _decimals)
    {
        deFiDonate = IDeFiDonate(msg.sender);
    }

    // Used when voting with this token
    function burn(address _account, uint256 _amount) external onlyMinter {
        _burn(_account, _amount);
    }

    // Add on any accrued interest when calculating balances
    // NB - this breaks totalSupply (e.g. sum over all addresses of balanceOf != totalSupply)
    function balanceOf(address _account) public view returns (uint256) {
        return super.balanceOf(_account).add(deFiDonate.accrued(_account));
    }

    function blockNumber() public view returns (uint256) {
        return block.number;
    }

    function blockTime() public view returns (uint256) {
        return block.timestamp;
    }

    function transfer(address _recipient, uint256 _amount) public returns (bool) {
        // To make sure the transfer doesn't fail due to insufficient funds make sure we add
        // any accrued governance tokens before trying to transfer
        deFiDonate.update(msg.sender);
        super.transfer(_recipient, _amount);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        deFiDonate.update(msg.sender);
        super.approve(_spender, _value);
        return true;
    }

    function transferFrom(address _sender, address _recipient, uint256 _amount) public returns (bool) {
        deFiDonate.update(_sender);
        super.transferFrom(_sender, _recipient, _amount);
        return true;
    }

}
