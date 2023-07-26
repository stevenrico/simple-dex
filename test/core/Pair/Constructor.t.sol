// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { BaseTest } from "../../BaseTest.sol";

contract Constructor is BaseTest {
    function setUp() public override {
        super.setUp();
    }

    function testTokens() external {
        (address tokenA, address tokenB) = PairX.getTokens();

        assertEq(tokenA, address(TokenOne));
        assertEq(tokenB, address(TokenTwo));
    }
}
