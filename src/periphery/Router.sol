// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { SafeERC20 } from "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

/**
 * @notice Router contract is used to:
 *
 * - Add liquidity
 * - Remove liquidity
 */

contract Router {
    address private _pair;

    constructor(address pair) {
        _pair = pair;
    }

    function getPair() external view returns (address) {
        return _pair;
    }
}
