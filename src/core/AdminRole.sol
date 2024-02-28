// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.0;

import { Ownable } from "openzeppelin-contracts/contracts/access/Ownable.sol";
import { AccessControl } from "openzeppelin-contracts/contracts/access/AccessControl.sol";

abstract contract AdminRole is Ownable, AccessControl {
    error UnauthorizedAdmin(address admin);

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");

    constructor() Ownable(msg.sender) {
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    modifier onlyAdmin() {
        if (!hasRole(ADMIN_ROLE, msg.sender)) revert UnauthorizedAdmin(msg.sender);
        _;
    }

    function isAdmin(address account) external view returns (bool) {
        return hasRole(ADMIN_ROLE, account);
    }

    function addAdmin(address account) external onlyOwner {
        grantRole(ADMIN_ROLE, account);
    }

    function removeAdmin(address account) external onlyOwner {
        revokeRole(ADMIN_ROLE, account);
    }
}
