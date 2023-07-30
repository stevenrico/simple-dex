// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Test } from "@forge-std/Test.sol";

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

import { Users } from "test/utils/Users.sol";
import { MockERC20 } from "test/mocks/MockERC20.sol";
import { MaliciousERC20 } from "./MaliciousERC20.sol";

import { Pair } from "contracts/core/Pair.sol";

import { Utils } from "contracts/libraries/Utils.sol";

import { console } from "@forge-std/console.sol";

contract ReEntrancyTest is Test, Users {
    /* solhint-disable */
    MockERC20 internal TokenGood;
    MaliciousERC20 internal TokenEvil;

    Pair internal PairX;
    /* solhint-enable */

    mapping(address token => mapping(address user => uint256 amount)) internal
        _tokenDistributions;

    mapping(address token => uint256 scale) internal _scales;

    address private _owner;
    address private _attacker;

    address[] internal _liquidityProviders;

    function setUp() public {
        uint256 ownersId = _createUserGroup("OWNER");
        _owner = _createUser(ownersId, 100 ether);

        uint256 attackersId = _createUserGroup("ATTACKER");
        _attacker = _createUser(attackersId, 100 ether);

        vm.prank(_owner);
        TokenGood = new MockERC20("Token Good", "TKGD");

        vm.startPrank(_attacker);

        TokenEvil = new MaliciousERC20();

        address tokenGood = address(TokenGood);
        address tokenEvil = address(TokenEvil);

        (address tokenA, address tokenB) =
            Utils.sortTokens(tokenGood, tokenEvil);

        PairX = new Pair(tokenA, tokenB);

        uint256 decimalsA =
            tokenA == tokenGood ? TokenGood.decimals() : TokenEvil.decimals();
        uint256 decimalsB =
            tokenB == tokenGood ? TokenGood.decimals() : TokenEvil.decimals();

        _scales[tokenA] = 10 ** decimalsA;
        _scales[tokenB] = 10 ** decimalsB;

        TokenEvil.setPair(address(PairX));

        TokenGood.mint(5000 * _scales[tokenGood]);
        TokenEvil.mint(5000 * _scales[tokenEvil]);

        _tokenDistributions[tokenGood][_attacker] = 5000 * _scales[tokenGood];
        _tokenDistributions[tokenEvil][_attacker] = 5000 * _scales[tokenEvil];

        vm.stopPrank();

        (, address[] memory liquidityProviders) =
            _createUserGroup("LIQUIDITY PROVIDER", 2, 100 ether);
        _liquidityProviders = liquidityProviders;

        _mintMockTokensForUsers(liquidityProviders, TokenGood, 5000);
        _mintMaliciousTokensForUsers(liquidityProviders, TokenEvil, 5000);
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

    function _mintMaliciousTokensForUsers(
        address[] memory accounts,
        MaliciousERC20 token,
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

    function testAttackOnMint() external {
        (address tokenA, address tokenB) = PairX.getTokens();

        address liquidityProvider = _liquidityProviders[0];

        _addLiquidity(liquidityProvider, tokenA, address(PairX), 100);
        _addLiquidity(liquidityProvider, tokenB, address(PairX), 100);

        console.log("*--[Hack] Mint: normal call start");
        console.log("|");

        vm.prank(liquidityProvider);
        PairX.mint(liquidityProvider);

        console.log("|");
        console.log("*--[Hack] Mint: normal call end");
        console.log(" \\_____________________________");
        console.log(" /");

        _addLiquidity(_attacker, tokenA, address(PairX), 100);
        _addLiquidity(_attacker, tokenB, address(PairX), 100);

        vm.startPrank(_attacker);

        TokenEvil.setAttackOn("MINT");

        console.log("*--[Hack] Mint: normal call start");
        console.log("|");

        PairX.mint(_attacker);

        console.log("|");
        console.log("*--[Hack] Mint: normal call end");
        console.log(" \\_____________________________");
        console.log(" /");

        uint256 balanceAfterHack = PairX.balanceOf(_attacker);
        PairX.transfer(address(PairX), balanceAfterHack);

        (uint256 amountA, uint256 amountB) = PairX.burn(_attacker);

        console.log("*--[HACK] Burn:");
        console.log("|");
        console.log("    Before => After:");
        console.log(
            "    amountA:",
            _tokenDistributions[tokenA][_attacker],
            "=>",
            amountA
        );
        console.log(
            "    diff:", amountA - _tokenDistributions[tokenA][_attacker]
        );
        console.log(
            "    amountB:",
            _tokenDistributions[tokenB][_attacker],
            "=>",
            amountB
        );
        console.log(
            "    diff:", amountB - _tokenDistributions[tokenB][_attacker]
        );
        console.log(" \\_____________________________");

        vm.stopPrank();
    }

    function _addLiquidity(
        address liquidityProvider,
        address token,
        address pair,
        uint256 ratio
    ) internal returns (uint256 amount) {
        uint256 totalDistribution =
            _tokenDistributions[token][liquidityProvider];
        amount = totalDistribution * ratio / 100;

        vm.prank(liquidityProvider);
        IERC20(token).transfer(pair, amount);
    }
}
