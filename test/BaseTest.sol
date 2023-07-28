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

    mapping(address token => mapping(address user => uint256 amount)) internal
        _tokenDistributions;

    address private _owner;

    address[] internal _liquidityProviders;
    address[] internal _traders;

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

        _mintMockTokensForUsers(liquidityProviders, TokenOne, 5000);
        _mintMockTokensForUsers(liquidityProviders, TokenTwo, 1000);

        (, address[] memory traders) = _createUserGroup("TRADER", 2, 100 ether);
        _traders = traders;

        _mintMockTokensForUsers(traders, TokenOne, 50);
        _mintMockTokensForUsers(traders, TokenTwo, 10);
    }

    function _mintMockTokensForUsers(
        address[] memory accounts,
        MockERC20 token,
        uint256 amount
    ) private {
        amount = amount * 10 ** token.decimals();

        for (uint256 i = 0; i < accounts.length; i++) {
            address account = accounts[i];

            vm.startPrank(account);

            token.mint(amount);

            _tokenDistributions[address(token)][account] = amount;

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
                _tokenDistributions[address(TokenOne)][liquidityProvider]
            );
            _itMintsTokens(
                TokenTwo,
                liquidityProvider,
                _tokenDistributions[address(TokenTwo)][liquidityProvider]
            );
        }
    }

    function testTraders() external {
        for (uint256 i = 0; i < _liquidityProviders.length; i++) {
            address trader = _traders[i];

            _itMintsTokens(
                TokenOne, trader, _tokenDistributions[address(TokenOne)][trader]
            );
            _itMintsTokens(
                TokenTwo, trader, _tokenDistributions[address(TokenTwo)][trader]
            );
        }
    }
}
