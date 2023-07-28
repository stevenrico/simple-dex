// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { PairBase } from "./Base.t.sol";

import { Math } from "@openzeppelin/utils/math/Math.sol";

import { MockERC20 } from "tests/mocks/MockERC20.sol";
import { Pair } from "contracts/core/Pair.sol";

contract SwapTest is PairBase {
    event Swap(
        address indexed sender,
        address indexed recipient,
        uint256 amountAIn,
        uint256 amountAOut,
        uint256 amountBIn,
        uint256 amountBOut
    );

    function setUp() public override {
        super.setUp();
    }

    function testSwapOfTokenAForTokenB() external {
        address liquidityProvider = _liquidityProviders[0];

        uint256 reserveA =
            _addLiquidity(liquidityProvider, TokenOne, address(PairX), 100);
        uint256 reserveB =
            _addLiquidity(liquidityProvider, TokenTwo, address(PairX), 100);

        vm.prank(liquidityProvider);
        PairX.mint(liquidityProvider);

        address trader = _traders[0];

        uint256 traderBalanceA = _tokenDistributions[address(TokenOne)][trader];
        uint256 traderBalanceB = _tokenDistributions[address(TokenTwo)][trader];

        uint256 amountAIn = traderBalanceA;
        uint256 amountBOut = amountAIn * reserveB / (amountAIn + reserveA);

        vm.startPrank(trader);

        // [Q] Should I test for `event Transfer(...)`?
        TokenOne.transfer(address(PairX), amountAIn);

        vm.expectEmit(true, true, false, true, address(PairX));
        emit Swap(trader, trader, amountAIn, 0, 0, amountBOut);

        PairX.swap(0, amountBOut, trader);

        vm.stopPrank();

        uint256 expectedAmountA = reserveA + amountAIn;
        uint256 expectedAmountB = reserveB - amountBOut;

        assertEq(TokenOne.balanceOf(address(PairX)), expectedAmountA);
        assertEq(TokenTwo.balanceOf(address(PairX)), expectedAmountB);

        _itUpdatesReserves(PairX, expectedAmountA, expectedAmountB);

        assertEq(TokenOne.balanceOf(trader), 0);
        assertEq(TokenTwo.balanceOf(trader), traderBalanceB + amountBOut);
    }

    function testSwapOfTokenBForTokenA() external {
        address liquidityProvider = _liquidityProviders[0];

        uint256 reserveA =
            _addLiquidity(liquidityProvider, TokenOne, address(PairX), 100);
        uint256 reserveB =
            _addLiquidity(liquidityProvider, TokenTwo, address(PairX), 100);

        vm.prank(liquidityProvider);
        PairX.mint(liquidityProvider);

        address trader = _traders[0];

        uint256 traderBalanceA = _tokenDistributions[address(TokenOne)][trader];
        uint256 traderBalanceB = _tokenDistributions[address(TokenTwo)][trader];

        uint256 amountBIn = traderBalanceB;
        uint256 amountAOut = amountBIn * reserveA / (amountBIn + reserveB);

        vm.startPrank(trader);

        // [Q] Should I test for `event Transfer(...)`?
        TokenTwo.transfer(address(PairX), amountBIn);

        vm.expectEmit(true, true, false, true, address(PairX));
        emit Swap(trader, trader, 0, amountAOut, amountBIn, 0);

        PairX.swap(amountAOut, 0, trader);

        vm.stopPrank();

        uint256 expectedAmountA = reserveA - amountAOut;
        uint256 expectedAmountB = reserveB + amountBIn;

        assertEq(TokenOne.balanceOf(address(PairX)), expectedAmountA);
        assertEq(TokenTwo.balanceOf(address(PairX)), expectedAmountB);

        _itUpdatesReserves(PairX, expectedAmountA, expectedAmountB);

        assertEq(TokenOne.balanceOf(trader), traderBalanceA + amountAOut);
        assertEq(TokenTwo.balanceOf(trader), 0);
    }

    function testRevertWhenBothAmountOutAreZero() external {
        address trader = _traders[0];

        vm.expectRevert("Pair: Insufficient output amount");
        vm.prank(trader);
        PairX.swap(0, 0, trader);
    }

    function testRevertWhenPairHasZeroLiquidity() external {
        address trader = _traders[0];

        uint256 amountOut = 1000 * 10 ** 18;

        vm.startPrank(trader);

        vm.expectRevert("Pair: Insufficient liquidity");
        PairX.swap(amountOut, 0, trader);

        vm.expectRevert("Pair: Insufficient liquidity");
        PairX.swap(0, amountOut, trader);

        vm.stopPrank();
    }

    function testRevertWhenPairHasLowLiquidity() external {
        address liquidityProvider = _liquidityProviders[0];

        _addLiquidity(liquidityProvider, TokenOne, address(PairX), 5);
        _addLiquidity(liquidityProvider, TokenTwo, address(PairX), 5);

        vm.prank(liquidityProvider);
        PairX.mint(liquidityProvider);

        address trader = _traders[0];

        uint256 amountOut = 1000 * 10 ** 18;

        vm.startPrank(trader);

        vm.expectRevert("Pair: Insufficient liquidity");
        PairX.swap(amountOut, 0, trader);

        vm.expectRevert("Pair: Insufficient liquidity");
        PairX.swap(0, amountOut, trader);

        vm.stopPrank();
    }

    function testRevertWhenRecipientIsInvalid() external {
        address liquidityProvider = _liquidityProviders[0];

        _addLiquidity(liquidityProvider, TokenOne, address(PairX), 100);
        _addLiquidity(liquidityProvider, TokenTwo, address(PairX), 100);

        vm.prank(liquidityProvider);
        PairX.mint(liquidityProvider);

        address trader = _traders[0];

        uint256 amountOut = 50 * 10 ** 18;

        vm.startPrank(trader);

        vm.expectRevert("Pair: Invalid recipient");
        PairX.swap(amountOut, 0, address(TokenOne));

        vm.expectRevert("Pair: Invalid recipient");
        PairX.swap(0, amountOut, address(TokenOne));

        vm.expectRevert("Pair: Invalid recipient");
        PairX.swap(amountOut, 0, address(TokenTwo));

        vm.expectRevert("Pair: Invalid recipient");
        PairX.swap(0, amountOut, address(TokenTwo));

        vm.stopPrank();
    }

    function testRevertWhenAmountInIsZero() external {
        address liquidityProvider = _liquidityProviders[0];

        _addLiquidity(liquidityProvider, TokenOne, address(PairX), 100);
        _addLiquidity(liquidityProvider, TokenTwo, address(PairX), 100);

        vm.prank(liquidityProvider);
        PairX.mint(liquidityProvider);

        address trader = _traders[0];

        uint256 amountOut = 50 * 10 ** 18;

        vm.startPrank(trader);

        vm.expectRevert("Pair: Insufficient input amount");
        PairX.swap(amountOut, 0, trader);

        vm.expectRevert("Pair: Insufficient input amount");
        PairX.swap(0, amountOut, trader);

        vm.stopPrank();
    }

    function testRevertWhenAmountInIsNotEnoughForSwapOfTokenAForTokenB()
        external
    {
        address liquidityProvider = _liquidityProviders[0];

        uint256 reserveA =
            _addLiquidity(liquidityProvider, TokenOne, address(PairX), 100);
        uint256 reserveB =
            _addLiquidity(liquidityProvider, TokenTwo, address(PairX), 100);

        vm.prank(liquidityProvider);
        PairX.mint(liquidityProvider);

        address trader = _traders[0];

        uint256 traderBalanceA = _tokenDistributions[address(TokenOne)][trader];

        uint256 amountAIn = traderBalanceA;
        uint256 amountBOut = amountAIn * reserveB / (amountAIn + reserveA);

        vm.startPrank(trader);

        TokenOne.transfer(address(PairX), amountAIn / 2);

        vm.expectRevert("Pair: K");
        PairX.swap(0, amountBOut, trader);

        vm.stopPrank();
    }

    function testRevertWhenAmountInIsNotEnoughForSwapOfTokenBForTokenA()
        external
    {
        address liquidityProvider = _liquidityProviders[0];

        uint256 reserveA =
            _addLiquidity(liquidityProvider, TokenOne, address(PairX), 100);
        uint256 reserveB =
            _addLiquidity(liquidityProvider, TokenTwo, address(PairX), 100);

        vm.prank(liquidityProvider);
        PairX.mint(liquidityProvider);

        address trader = _traders[0];

        uint256 traderBalanceB = _tokenDistributions[address(TokenTwo)][trader];

        uint256 amountBIn = traderBalanceB;
        uint256 amountAOut = amountBIn * reserveA / (amountBIn + reserveB);

        vm.startPrank(trader);

        TokenTwo.transfer(address(PairX), amountBIn / 2);

        vm.expectRevert("Pair: K");
        PairX.swap(amountAOut, 0, trader);

        vm.stopPrank();
    }
}
