// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { ERC20 } from "@openzeppelin/token/ERC20/ERC20.sol";

/**
 * @notice 'Liquidity Token' is an ERC20 token for liquidity providers
 */

contract LiquidityTokenERC20 is ERC20 {
    constructor() ERC20("Liquidity Token", "LIQUID") { }
}
