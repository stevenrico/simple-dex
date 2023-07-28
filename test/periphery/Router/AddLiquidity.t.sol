// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { BaseTest } from "../../BaseTest.sol";

contract AddLiquidityTest is BaseTest {
    function setUp() public override {
        super.setUp();
    }

    function testTransferToPair() external {
        address liquidityProvider = _liquidityProviders[0];

        address tokenA = address(TokenOne);
        uint256 amountA = _tokenDistributions[tokenA][liquidityProvider];

        address tokenB = address(TokenTwo);
        uint256 amountB = _tokenDistributions[tokenB][liquidityProvider];

        vm.startPrank(liquidityProvider);

        TokenOne.approve(address(RouterX), amountA);
        TokenTwo.approve(address(RouterX), amountB);

        (,, uint256 liquidityTokens) = RouterX.addLiquidity(
            tokenA, tokenB, amountA, amountB, liquidityProvider
        );

        vm.stopPrank();

        assertEq(TokenOne.balanceOf(address(PairX)), amountA);
        assertEq(TokenOne.balanceOf(liquidityProvider), 0);
        assertEq(TokenTwo.balanceOf(address(PairX)), amountB);
        assertEq(TokenTwo.balanceOf(liquidityProvider), 0);

        assertEq(PairX.balanceOf(liquidityProvider), liquidityTokens);
    }

    function testRevertIfTransferWithoutApproval() external {
        address liquidityProvider = _liquidityProviders[0];

        address tokenA = address(TokenOne);
        uint256 amountA = _tokenDistributions[tokenA][liquidityProvider];

        address tokenB = address(TokenTwo);
        uint256 amountB = _tokenDistributions[tokenB][liquidityProvider];

        vm.expectRevert("ERC20: insufficient allowance");
        vm.prank(liquidityProvider);
        RouterX.addLiquidity(
            tokenA, tokenB, amountA, amountB, liquidityProvider
        );

        assertEq(TokenOne.balanceOf(address(PairX)), 0);
        assertEq(TokenOne.balanceOf(liquidityProvider), amountA);
        assertEq(TokenTwo.balanceOf(address(PairX)), 0);
        assertEq(TokenTwo.balanceOf(liquidityProvider), amountB);

        assertEq(PairX.balanceOf(liquidityProvider), 0);
    }
}
