// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.0;

contract PropertyBase {
    /* 32b: gene, 32[40b]: time, 72[16b]: sell price, 88[16b]: rent price  */
    uint256[] public properties;

    mapping(uint32 => uint16) public indexToPos;

    constructor() public {}
}
