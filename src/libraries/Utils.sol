// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { IPair } from "contracts/core/interfaces/IPair.sol";

library Utils {
    function sortTokens(address token0, address token1)
        internal
        pure
        returns (address tokenA, address tokenB)
    {
        (tokenA, tokenB) = token0 < token1 ? (token0, token1) : (token1, token0);
    }

    function getReserves(address pair, address token0, address token1)
        internal
        returns (uint256 reserveA, uint256 reserveB)
    {
        (address tokenA,) = sortTokens(token0, token1);
        (uint256 reserve0, uint256 reserve1) = IPair(pair).getReserves();
        (reserveA, reserveB) =
            token0 == tokenA ? (reserve0, reserve1) : (reserve1, reserve0);
    }
}
