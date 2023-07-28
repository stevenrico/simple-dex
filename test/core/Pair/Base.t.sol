// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { BaseTest } from "../../BaseTest.sol";

import { MockERC20 } from "tests/mocks/MockERC20.sol";
import { Pair } from "contracts/core/Pair.sol";

contract PairBase is BaseTest {
    function setUp() public virtual override {
        super.setUp();
    }

    function _itUpdatesReserves(
        Pair pair,
        uint256 expectedAmountA,
        uint256 expectedAmountB
    ) internal {
        (uint256 reserveA, uint256 reserveB) = pair.getReserves();

        assertEq(reserveA, expectedAmountA);
        assertEq(reserveB, expectedAmountB);
    }

    function _addLiquidity(
        address liquidityProvider,
        MockERC20 token,
        address pair,
        uint256 ratio
    ) internal returns (uint256 amount) {
        uint256 totalDistribution =
            _tokenDistributions[address(token)][liquidityProvider];
        amount = totalDistribution * ratio / 100;

        vm.prank(liquidityProvider);
        token.transfer(pair, amount);
    }
}
