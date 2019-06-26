pragma solidity ^0.5.0;

// Everyone who deposits funds is issued time tokens.
// 1 CHAR token is equivalent to 1 DAI for 1 block and represents your voting power
// There are three phases - voting, deposit and donate
// In the voting phase CHAR holders vote on the address they would like to receive funds from the next deposit phase.
// In the deposit phases people can depositnpm
// Each epoch (e.g. 1000 blocks)

import 'openzeppelin-solidity/contracts/token/ERC20/ERC20Mintable.sol';
import 'openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol';

contract CharityToken is ERC20Mintable, ERC20Detailed {

    constructor (string memory _name, string memory _symbol, uint8 _decimals) public
        ERC20Detailed(_name, _symbol, _decimals)
    {}

    /**
     * @dev Destoys `amount` tokens from the caller.
     *
     * See `ERC20._burn`.
     */
    function burn(uint256 amount) external onlyMinter {
        _burn(msg.sender, amount);
    }

}
