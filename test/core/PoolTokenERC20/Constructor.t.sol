// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { BaseTest } from "../../BaseTest.sol";

contract Constructor is BaseTest {
    function setUp() public override {
        super.setUp();
    }

    function testName() external {
        assertEq(PoolToken.name(), "Pool Token");
    }

    function testSymbol() external {
        assertEq(PoolToken.symbol(), "POOL");
    }
}
