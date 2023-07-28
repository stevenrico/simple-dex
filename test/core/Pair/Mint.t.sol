// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { PairBase } from "./Base.t.sol";

import { Math } from "@openzeppelin/utils/math/Math.sol";

contract MintTest is PairBase {
    event Mint(address indexed sender, uint256 amountA, uint256 amountB);

    function setUp() public override {
        super.setUp();
    }

    function testMintWhenTotalSupplyIsZero() external {
        address recipient = _liquidityProviders[0];

        uint256 amountA =
            _addLiquidity(recipient, TokenOne, address(PairX), 100);
        uint256 amountB =
            _addLiquidity(recipient, TokenTwo, address(PairX), 100);

        vm.expectEmit(true, false, false, true, address(PairX));
        emit Mint(recipient, amountA, amountB);

        vm.prank(recipient);
        uint256 liquidityTokens = PairX.mint(recipient);

        uint256 expectedAmount = Math.sqrt(amountA * amountB);

        assertEq(liquidityTokens, expectedAmount);
        assertEq(PairX.balanceOf(recipient), expectedAmount);

        _itUpdatesReserves(PairX, amountA, amountB);
    }

    function testMintWhenTotalSupplyIsGreaterThanZero() external {
        address recipient = _liquidityProviders[0];

        uint256 reserveA;
        uint256 reserveB;

        uint256 expectedRecipientBalance;

        {
            uint256 amountA =
                _addLiquidity(recipient, TokenOne, address(PairX), 50);
            uint256 amountB =
                _addLiquidity(recipient, TokenTwo, address(PairX), 50);

            vm.prank(recipient);
            uint256 liquidityTokens = PairX.mint(recipient);

            reserveA += amountA;
            reserveB += amountB;

            expectedRecipientBalance += liquidityTokens;
        }

        {
            uint256 totalSupply = PairX.totalSupply();

            uint256 amountA =
                _addLiquidity(recipient, TokenOne, address(PairX), 50);
            uint256 amountB =
                _addLiquidity(recipient, TokenTwo, address(PairX), 50);

            vm.prank(recipient);
            uint256 liquidityTokens = PairX.mint(recipient);

            uint256 expectedAmount = Math.min(
                amountA * totalSupply / reserveA,
                amountB * totalSupply / reserveB
            );

            expectedRecipientBalance += expectedAmount;

            assertEq(liquidityTokens, expectedAmount);
            assertEq(PairX.balanceOf(recipient), expectedRecipientBalance);

            _itUpdatesReserves(PairX, reserveA + amountA, reserveB + amountB);
        }
    }
}
