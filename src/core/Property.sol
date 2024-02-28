// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.0;

import { IERC721, ERC721, IERC165 } from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import { ERC721Enumerable } from "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import { MinterRole, AccessControl } from "./MinterRole.sol";
import { IProperty, Metadata } from "./interfaces/IProperty.sol";

contract Property is IProperty, MinterRole, ERC721Enumerable {
    string private _baseTokenURI;
    mapping(uint256 => Metadata) public db;
    uint256 public lastId = 0;

    constructor() ERC721("Monoploy Property", "MOP") { }

    function mint(address to, Metadata memory data) external onlyMinter {
        lastId++;
        _mint(to, lastId);
        db[lastId] = data;
    }

    function ownerOf(uint256 tokenId) public view override(ERC721, IERC721) returns (address) {
        return _ownerOf(tokenId);
    }

    function metadata(uint256 tokenId) external view returns (Metadata memory) {
        return db[tokenId];
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721Enumerable, AccessControl) returns (bool) {
        return interfaceId == type(AccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        _baseTokenURI = _uri;
    }

    function setMetadata(uint256 tokenId, Metadata memory data) external onlyMinter {
        db[tokenId] = data;
    }
}
