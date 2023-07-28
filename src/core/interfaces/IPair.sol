// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface IPair {
    event Mint(address indexed sender, uint256 amountA, uint256 amountB);
    event Swap(address indexed sender, address indexed recipient, uint256 amountAIn, uint256 amountAOut, uint256 amountBIn, uint256 amountBOut);

    function getTokens() external returns (address, address);
    function getReserves() external returns (uint256, uint256);

    function mint(address recipient) external returns (uint256 liquidtyTokens);

    function swap(uint256 amountAOut, uint256 amountBOut, address recipient) external;
}
