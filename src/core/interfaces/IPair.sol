// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface IPair {
    event Mint(address indexed sender, uint256 amountA, uint256 amountB);

    function mint(address recipient) external returns (uint256 liquidtyTokens);
}
