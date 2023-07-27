// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { Math } from "@openzeppelin/utils/math/Math.sol";

import { IPair } from "contracts/core/interfaces/IPair.sol";
import { LiquidityTokenERC20 } from "contracts/core/LiquidityTokenERC20.sol";

/**
 * @title Pair
 * @author Steven Rico
 * @notice The 'Pair' contract is used to:
 *
 * - mint liquidity tokens
 * - burn liquidity tokens
 * - perform swaps between token A and token B
 *
 * @dev The 'Pair' contract inherits from 'LiquidityTokenERC20'.
 */
contract Pair is IPair, LiquidityTokenERC20 {
    address private _tokenA;
    address private _tokenB;

    uint256 private _reserveA;
    uint256 private _reserveB;

    /**
     * @dev Set the value for {tokenA} and {tokenB}.
     */
    constructor(address tokenA, address tokenB) {
        _tokenA = tokenA;
        _tokenB = tokenB;
    }

    /**
     * @dev Returns the address of token A and token B.
     *
     * @return tokenA           The address of token A.
     * @return tokenB           The address of token B.
     */
    function getTokens() external view returns (address, address) {
        return (_tokenA, _tokenB);
    }

    /**
     * @dev Returns the amount of reserve A and reserve B.
     *
     * @return reserveA         The amount of reserve A.
     * @return reserveB         The amount of reserve B.
     */
    function getReserves() public view returns (uint256, uint256) {
        return (_reserveA, _reserveB);
    }

    /**
     * @dev Updates the values of {reserveA} and {reserveB}.
     *
     * @param balanceA          The balance of token A owned by the contract.
     * @param balanceB          The balance of token B owned by the contract.
     */
    function _update(uint256 balanceA, uint256 balanceB) private {
        _reserveA = balanceA;
        _reserveB = balanceB;
    }

    /**
     * @dev Mints liquidity tokens to the liquidity provider.
     *
     * Formula:
     *
     * l            amount of liquidity tokens to mint
     * tokenA       amount of token A sent by liquidity provider
     * tokenB       amount of token B sent by liquidity provider
     * reserveA     amount of token A owned by the contract
     * reserveB     amount of token B owned by the contract
     * s            total supply of liquidty tokens
     *
     * When 's == 0':
     *
     * l = (tokenA * tokenB) ^ 0.5
     *
     * When 's > 0':
     *
     * l = Math.min((tokenA * s / reserveA), (tokenB * s / reserveB))
     *
     * @param recipient         Recipient of the liquidty tokens.
     *
     * @return liquidityTokens  The amount of liquidity tokens minted to the recipient.
     */
    function mint(address recipient)
        external
        returns (uint256 liquidityTokens)
    {
        (uint256 reserveA, uint256 reserveB) = getReserves();

        uint256 balanceA = IERC20(_tokenA).balanceOf(address(this));
        uint256 balanceB = IERC20(_tokenB).balanceOf(address(this));
        uint256 amountA = balanceA - reserveA;
        uint256 amountB = balanceB - reserveB;

        uint256 totalSupply = totalSupply();

        if (totalSupply == 0) {
            liquidityTokens = Math.sqrt(amountA * amountB);
        } else {
            liquidityTokens = Math.min(
                amountA * totalSupply / reserveA,
                amountB * totalSupply / reserveB
            );
        }

        _mint(recipient, liquidityTokens);

        _update(balanceA, balanceB);

        emit Mint(msg.sender, amountA, amountB);
    }
}
