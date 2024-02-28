// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.0;

import { Ownable } from "openzeppelin-contracts/contracts/access/Ownable.sol";
import { AccessControl } from "openzeppelin-contracts/contracts/access/AccessControl.sol";

abstract contract MinterRole is Ownable, AccessControl {
    error UnauthorizedMinter(address minter);

    bytes32 public constant MINTER_ROLE = keccak256("MINTER");

    constructor() Ownable(msg.sender) {
        _grantRole(MINTER_ROLE, msg.sender);
    }

    modifier onlyMinter() {
        if (!hasRole(MINTER_ROLE, msg.sender)) revert UnauthorizedMinter(msg.sender);
        _;
    }

    function isMinter(address account) external view returns (bool) {
        return hasRole(MINTER_ROLE, account);
    }

    function addMinter(address account) external onlyOwner {
        grantRole(MINTER_ROLE, account);
    }

    function removeMinter(address account) external onlyOwner {
        revokeRole(MINTER_ROLE, account);
    }
}
