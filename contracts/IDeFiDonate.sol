pragma solidity ^0.5.0;

interface IDeFiDonate {
    function wrap(uint256 _amount) external;
    function unwrap(uint256 _amount) external;
    function update(address _account) external;
    function accrued(address _account) external view returns (uint256);
}
