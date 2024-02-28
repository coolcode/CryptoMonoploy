// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.0;

import { IERC721Enumerable } from "openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

struct Metadata {
    uint160 blocknum; // at block number
    //uint8 rarity; // 0-4, N,R,SR,SSR,UR
    uint16 level;
    uint16 score;
}

uint16 constant MAXIMUM_NUMBER_OF_PROPERTY = 10000;

interface IProperty is IERC721Enumerable {
    function mint(address to, Metadata memory data) external;
    function metadata(uint256 tokenId) external view returns (Metadata memory);
    function setMetadata(uint256 tokenId, Metadata memory data) external;
}
