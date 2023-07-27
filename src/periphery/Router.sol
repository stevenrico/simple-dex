// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { SafeERC20 } from "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { IPair } from "contracts/core/interfaces/IPair.sol";

/**
 * @title Router
 * @author Steven Rico
 * @notice The 'Router' contract is used to:
 *
 * - Add liquidity
 * - Remove liquidity
 *
 * @dev The 'Router' contract interacts with:
 *
 * - Pair (src/core/Pair.sol)
 * - ERC20 tokens using OpenZeppelin (contracts/token/ERC20/ERC20.sol)
 *
 * It uses 'SafeERC20.safeTransferFrom(token, from, to, value);' for transfers.
 */
contract Router {
    address private _pair;

    /**
     * @dev Set the value for {pair}.
     */
    constructor(address pair) {
        _pair = pair;
    }

    /**
     * @dev Returns the address of the Pair.
     *
     * @return pair             The address of the Pair.
     */
    function getPair() external view returns (address) {
        return _pair;
    }

    /**
     * @dev Transfers token A and token B to Pair and mints liquidity tokens to
     * the liquidity provider.
     *
     * @custom:resource Uniswap Doc:
     * https://docs.uniswap.org/contracts/v2/reference/smart-contracts/router-02#addliquidity
     *
     * @param tokenA            A pool token.
     * @param tokenB            A pool token.
     * @param amountA           The amount of token A to add as liquidity.
     * @param amountB           The amount of token B to add as liquidity.
     * @param recipient         Recipient of the liquidty tokens.
     *
     * @return sentA            The amount of token A sent to the pool.
     * @return sentB            The amount of token B sent to the pool.
     * @return liquidityTokens  The amount of liquidity tokens minted to the recipient.
     */
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB,
        address recipient
    )
        external
        returns (uint256 sentA, uint256 sentB, uint256 liquidityTokens)
    {
        address pair = _pair;

        SafeERC20.safeTransferFrom(IERC20(tokenA), msg.sender, pair, amountA);
        SafeERC20.safeTransferFrom(IERC20(tokenB), msg.sender, pair, amountB);

        sentA = amountA;
        sentB = amountB;

        liquidityTokens = IPair(pair).mint(recipient);
    }
}
