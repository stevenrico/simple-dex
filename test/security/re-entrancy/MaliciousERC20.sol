// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { CustomERC20 } from "../utils/CustomERC20.sol";

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { IPair } from "contracts/core/interfaces/IPair.sol";

import { console } from "@forge-std/console.sol";

/**
 * @notice 'Malicious Token' is an ERC20 token for re-entrancy attacks
 */

contract MaliciousERC20 is CustomERC20 {
    address private _pair;
    address private _recipient;

    mapping(string attack => uint256 on) private _attackOn;

    uint256 private _attackCount;

    constructor() CustomERC20("Malicous Token", "MAL") {
        _attackOn["MINT"] = 0;
        _attackOn["BURN"] = 0;
    }

    function setPair(address pair) external {
        _pair = pair;
        _recipient = msg.sender;
    }

    function getPair() external view returns (address) {
        return _pair;
    }

    function setAttackOn(string memory attack) external {
        _attackOn[attack] = 1;
    }

    function unsetAttackOn(string memory attack) external {
        _attackOn[attack] = 0;
    }

    function mint(uint256 amount) external returns (bool) {
        _mint(msg.sender, amount);

        return true;
    }

    function burn(uint256 amount) external returns (bool) {
        _burn(msg.sender, amount);

        return true;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function _beforeTokenTransfer(address from, address to, uint256)
        internal
        override
    {
        if (_attackOn["BURN"] == 1 && _attackCount < 3) {
            _attackCount++;

            if (from == _pair && to == _recipient) {
                console.log("*--[Hack] Burn: attack call start");
                console.log("|");
                
                IERC20(_pair).transferFrom(_recipient, _pair, 2500 * 10 ** 18);
                
                IPair(_pair).burn(_recipient);
                
                console.log("|");
                console.log("*--[Hack] Burn: attack call end");
                console.log(" \\_____________________________");
                console.log(" /");
            }
        }
    }
}
