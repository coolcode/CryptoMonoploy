//SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.0;

import { ERC20 } from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "./AdminRole.sol";

contract Gold is ERC20 {
    constructor() ERC20("Gold Coin", "GOLD") {
        _mint(msg.sender, 1_000_000_000e18);
    }
}
