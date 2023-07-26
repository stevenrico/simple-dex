// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { ERC20 } from "@openzeppelin/token/ERC20/ERC20.sol";

/**
 * @notice 'Pool Token' is an ERC20 token for liquidity providers
 */

contract PoolTokenERC20 is ERC20 {
    constructor() ERC20("Pool Token", "POOL") { }
}
