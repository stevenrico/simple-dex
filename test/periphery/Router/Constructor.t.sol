// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { BaseTest } from "../../BaseTest.sol";

contract Constructor is BaseTest {
    function setUp() public override {
        super.setUp();
    }

    function testPair() external {
        assertEq(RouterX.getPair(), address(PairX));
    }
}
