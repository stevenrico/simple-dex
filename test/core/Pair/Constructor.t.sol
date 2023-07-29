// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { BaseTest } from "../../BaseTest.sol";

import { Utils } from "contracts/libraries/Utils.sol";

contract Constructor is BaseTest {
    function setUp() public override {
        super.setUp();
    }

    function testTokens() external {
        (address tokenA, address tokenB) = PairX.getTokens();

        (address expectedTokenA, address expectedTokenB) =
            Utils.sortTokens(address(TokenOne), address(TokenTwo));

        assertEq(tokenA, expectedTokenA);
        assertEq(tokenB, expectedTokenB);
    }
}
