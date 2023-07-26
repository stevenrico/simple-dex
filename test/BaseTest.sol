// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Test } from "@forge-std/Test.sol";
import { Users } from "./utils/Users.sol";
import { MockERC20 } from "./mocks/MockERC20.sol";

import { LiquidityTokenERC20 } from "contracts/core/LiquidityTokenERC20.sol";
import { Pair } from "contracts/core/Pair.sol";

import { Router } from "contracts/periphery/Router.sol";

contract BaseTest is Test, Users {
    /* solhint-disable */
    LiquidityTokenERC20 internal LiquidToken;

    MockERC20 internal TokenOne;
    MockERC20 internal TokenTwo;

    Pair internal PairX;

    Router internal RouterX;
    /* solhint-enable */

    mapping(address => uint256) internal _tokenDistributions;

    address private _owner;

    address[] internal _liquidityProviders;

    function setUp() public virtual {
        uint256 ownersId = _createUserGroup("OWNER");
        _owner = _createUser(ownersId, 100 ether);

        vm.startPrank(_owner);

        LiquidToken = new LiquidityTokenERC20();

        TokenOne = new MockERC20("Token One", "TKN1");
        TokenTwo = new MockERC20("Token Two", "TKN2");

        PairX = new Pair(address(TokenOne), address(TokenTwo));

        RouterX = new Router(address(PairX));

        vm.stopPrank();

        (, address[] memory liquidityProviders) =
            _createUserGroup("LIQUIDITY PROVIDER", 2, 100 ether);
        _liquidityProviders = liquidityProviders;

        {
            uint256 amount = 500 * 10 ** TokenOne.decimals();
            _tokenDistributions[address(TokenOne)] = amount;
        }

        {
            uint256 amount = 100 * 10 ** TokenTwo.decimals();
            _tokenDistributions[address(TokenTwo)] = amount;
        }

        _mintMockTokens(liquidityProviders, TokenOne, TokenTwo);
    }

    function _mintMockTokens(
        address[] memory accounts,
        MockERC20 tokenA,
        MockERC20 tokenB
    ) private {
        for (uint256 i = 0; i < accounts.length; i++) {
            address account = accounts[i];

            vm.startPrank(account);

            tokenA.mint(_tokenDistributions[address(tokenA)]);
            tokenB.mint(_tokenDistributions[address(tokenB)]);

            vm.stopPrank();
        }
    }

    function _itMintsTokens(MockERC20 token, address account, uint256 amount)
        private
    {
        assertEq(token.balanceOf(account), amount);
    }

    function testLiquidityProviders() external {
        for (uint256 i = 0; i < _liquidityProviders.length; i++) {
            address liquidityProvider = _liquidityProviders[i];

            _itMintsTokens(
                TokenOne,
                liquidityProvider,
                _tokenDistributions[address(TokenOne)]
            );
            _itMintsTokens(
                TokenTwo,
                liquidityProvider,
                _tokenDistributions[address(TokenTwo)]
            );
        }
    }
}
