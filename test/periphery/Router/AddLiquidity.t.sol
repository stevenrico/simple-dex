// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { BaseTest } from "../../BaseTest.sol";

contract AddLiquidityTest is BaseTest {
    function setUp() public override {
        super.setUp();
    }

    function testTransferToPair() external {
        address tokenA = address(TokenOne);
        uint256 amountA = _tokenDistributions[tokenA];

        address tokenB = address(TokenTwo);
        uint256 amountB = _tokenDistributions[tokenB];

        vm.startPrank(_liquidityProviders[0]);

        TokenOne.approve(address(RouterX), amountA);
        TokenTwo.approve(address(RouterX), amountB);

        (,, uint256 liquidityTokens) = RouterX.addLiquidity(
            tokenA, tokenB, amountA, amountB, _liquidityProviders[0]
        );

        vm.stopPrank();

        assertEq(TokenOne.balanceOf(address(PairX)), amountA);
        assertEq(TokenOne.balanceOf(_liquidityProviders[0]), 0);
        assertEq(TokenTwo.balanceOf(address(PairX)), amountB);
        assertEq(TokenTwo.balanceOf(_liquidityProviders[0]), 0);

        assertEq(PairX.balanceOf(_liquidityProviders[0]), liquidityTokens);
    }

    function testRevertIfTransferWithoutApproval() external {
        address tokenA = address(TokenOne);
        uint256 amountA = _tokenDistributions[tokenA];

        address tokenB = address(TokenTwo);
        uint256 amountB = _tokenDistributions[tokenB];

        vm.expectRevert("ERC20: insufficient allowance");
        vm.prank(_liquidityProviders[0]);
        RouterX.addLiquidity(
            tokenA, tokenB, amountA, amountB, _liquidityProviders[0]
        );

        assertEq(TokenOne.balanceOf(address(PairX)), 0);
        assertEq(TokenOne.balanceOf(_liquidityProviders[0]), amountA);
        assertEq(TokenTwo.balanceOf(address(PairX)), 0);
        assertEq(TokenTwo.balanceOf(_liquidityProviders[0]), amountB);

        assertEq(PairX.balanceOf(_liquidityProviders[0]), 0);
    }
}
