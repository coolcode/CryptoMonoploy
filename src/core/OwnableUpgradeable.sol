//SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.0;

import { OwnableUpgradeable as OzOwnableUpgradeable } from "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";

abstract contract OwnableUpgradeable is OzOwnableUpgradeable {
    uint16 private _version;

    function version() public view returns (uint16) {
        return _version;
    }

    function setVersion(uint16 v) internal {
        _version = v;
    }
}
