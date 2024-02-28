// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.0;

import { Ownable } from "openzeppelin-contracts/contracts/access/Ownable.sol";
import { IMap, Mapdata } from "src/core/interfaces/IMap.sol";

contract SquareMap is IMap, Ownable(msg.sender) {
    error InvaildLength();

    mapping(uint16 => Mapdata) public db;

    function get(uint16 pos) external view returns (Mapdata memory) {
        return db[pos];
    }

    function set(uint16 pos, Mapdata memory data) external onlyOwner {
        db[pos] = data;
    }

    function setMany(uint16[] memory pos, Mapdata[] memory data) external onlyOwner {
        if (pos.length != data.length) revert InvaildLength();

        for (uint256 i = 0; i < pos.length; i++) {
            db[pos[i]] = data[i];
        }
    }
}
