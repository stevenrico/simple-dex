// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { BaseTest } from "../../BaseTest.sol";

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

import { Utils } from "contracts/libraries/Utils.sol";

contract SwapTokensForExactTokens is BaseTest {
    function setUp() public override {
        super.setUp();
    }

    function testSwapTokensForExactTokens() external {
        address liquidityProvider = _liquidityProviders[0];

        (address tokenA, address tokenB) =
            Utils.sortTokens(address(TokenOne), address(TokenTwo));

        uint256 amountA = _tokenDistributions[tokenA][liquidityProvider];
        uint256 amountB = _tokenDistributions[tokenB][liquidityProvider];

        vm.startPrank(liquidityProvider);

        IERC20(tokenA).approve(address(RouterX), amountA);
        IERC20(tokenB).approve(address(RouterX), amountB);

        (uint256 reserveA, uint256 reserveB,) = RouterX.addLiquidity(
            tokenA, tokenB, amountA, amountB, liquidityProvider
        );

        vm.stopPrank();

        address trader = _traders[0];

        address[] memory tokens = new address[](2);

        tokens[0] = tokenB;
        tokens[1] = tokenA;

        uint256 traderBalanceA = _tokenDistributions[tokenA][trader];
        uint256 traderBalanceB = _tokenDistributions[tokenB][trader];

        uint256 amountAOut = traderBalanceA;
        uint256 amountBIn =
            (amountAOut * reserveB / (reserveA - amountAOut)) + 1;

        {
            // [ERROR] Stack too deep
            uint256 oneToken = 1 * _scales[tokenB];

            uint256 amountBMax = amountBIn + oneToken;

            vm.startPrank(trader);

            IERC20(tokenB).approve(address(RouterX), amountBIn);

            RouterX.swapTokensForExactTokens(
                amountAOut, amountBMax, tokens, trader
            );

            vm.stopPrank();
        }

        uint256 expectedAmountA = reserveA - amountAOut;
        uint256 expectedAmountB = reserveB + amountBIn;

        assertEq(IERC20(tokenA).balanceOf(address(PairX)), expectedAmountA);
        assertEq(IERC20(tokenB).balanceOf(address(PairX)), expectedAmountB);

        assertEq(IERC20(tokenA).balanceOf(trader), traderBalanceA + amountAOut);
        assertEq(IERC20(tokenB).balanceOf(trader), traderBalanceB - amountBIn);
    }

    function testRevertWhenAmountInIsZero() external {
        address trader = _traders[0];

        (address tokenA, address tokenB) =
            Utils.sortTokens(address(TokenOne), address(TokenTwo));

        address[] memory tokens = new address[](2);

        tokens[0] = tokenB;
        tokens[1] = tokenA;

        vm.expectRevert("Router: Insufficient output amount");
        vm.prank(trader);
        RouterX.swapTokensForExactTokens(0, 0, tokens, trader);
    }

    function testRevertWhenPairHasZeroLiquidity() external {
        address trader = _traders[0];

        (address tokenA, address tokenB) =
            Utils.sortTokens(address(TokenOne), address(TokenTwo));

        address[] memory tokens = new address[](2);

        tokens[0] = tokenB;
        tokens[1] = tokenA;

        uint256 amountBOut = 1000 * _scales[tokenA];

        vm.expectRevert("Router: Insufficient liquidity");
        vm.prank(trader);
        RouterX.swapTokensForExactTokens(amountBOut, 0, tokens, trader);
    }

    function testRevertWhenAmountInWillNotBeLessThanMax() external {
        address liquidityProvider = _liquidityProviders[0];

        (address tokenA, address tokenB) =
            Utils.sortTokens(address(TokenOne), address(TokenTwo));

        uint256 amountA = _tokenDistributions[tokenA][liquidityProvider];
        uint256 amountB = _tokenDistributions[tokenB][liquidityProvider];

        vm.startPrank(liquidityProvider);

        IERC20(tokenA).approve(address(RouterX), amountA);
        IERC20(tokenB).approve(address(RouterX), amountB);

        (uint256 reserveA, uint256 reserveB,) = RouterX.addLiquidity(
            tokenA, tokenB, amountA, amountB, liquidityProvider
        );

        vm.stopPrank();

        address trader = _traders[0];

        address[] memory tokens = new address[](2);

        tokens[0] = tokenB;
        tokens[1] = tokenA;

        uint256 amountAOut = _tokenDistributions[tokenA][trader];
        uint256 amountBIn =
            (amountAOut * reserveB / (reserveA - amountAOut)) + 1;

        uint256 oneToken = 1 * _scales[tokenB];

        uint256 amountBMax = amountBIn - oneToken;

        vm.expectRevert("Router: Excessive input amount");
        vm.prank(trader);
        RouterX.swapTokensForExactTokens(amountAOut, amountBMax, tokens, trader);
    }
}
