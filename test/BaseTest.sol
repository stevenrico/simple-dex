// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Test } from "@forge-std/Test.sol";
import { Users } from "./utils/Users.sol";
import { MockERC20 } from "./mocks/MockERC20.sol";

import { PoolTokenERC20 } from "contracts/core/PoolTokenERC20.sol";

contract BaseTest is Test, Users {
    /* solhint-disable */
    PoolTokenERC20 internal PoolToken;

    MockERC20 internal TokenOne;
    MockERC20 internal TokenTwo;
    /* solhint-enable */

    mapping(address => uint256) internal _tokenDistributions;

    address private _owner;

    address[] internal _liquidityProviders;

    function setUp() public virtual {
        uint256 ownersId = _createUserGroup("OWNER");
        _owner = _createUser(ownersId, 100 ether);

        vm.startPrank(_owner);

        PoolToken = new PoolTokenERC20();

        TokenOne = new MockERC20("Token One", "TKN1");
        TokenTwo = new MockERC20("Token Two", "TKN2");

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
                TokenOne, liquidityProvider, _tokenDistributions[address(TokenOne)]
            );
            _itMintsTokens(
                TokenTwo, liquidityProvider, _tokenDistributions[address(TokenTwo)]
            );
        }
    }
}
