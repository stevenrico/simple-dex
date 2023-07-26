// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Test } from "@forge-std/Test.sol";
import { Users } from "./utils/Users.sol";

import { PoolTokenERC20 } from "contracts/core/PoolTokenERC20.sol";

contract BaseTest is Test, Users {
    /* solhint-disable */
    PoolTokenERC20 internal PoolToken;
    /* solhint-enable */

    address private _owner;

    function setUp() public virtual {
        uint256 ownersId = _createUserGroup("OWNERS");
        _owner = _createUser(ownersId, 100 ether);

        vm.startPrank(_owner);

        PoolToken = new PoolTokenERC20();

        vm.stopPrank();
    }
}
