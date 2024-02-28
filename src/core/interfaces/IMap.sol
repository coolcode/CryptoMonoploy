// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.0;

struct Mapdata {
    uint8 land; // 0: Raw land, 2: Lottery, 3: Jail, 4: Flight, 5: Turnover
    //uint16 name;
    uint16 price;
    uint16 reward;
    uint16 fee;
}

uint16 constant EDGE_POSITION = 10000;
uint8 constant TYPE_RAW_LAND = 0;
uint8 constant TYPE_LOTTERY = 2;
uint8 constant TYPE_JAIL = 3;

interface IMap {
    function get(uint16 pos) external view returns (Mapdata memory);
}
