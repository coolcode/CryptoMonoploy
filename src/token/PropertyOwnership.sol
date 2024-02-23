// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.0;

import "../utils/AdminRole.sol";
import "./PropertyEnumerable.sol";

contract PropertyOwnership is AdminRole, PropertyEnumerable {
    constructor() public ERC721("MONOPOLY", "MON") {}

    function transfer(address _from, address _to, uint256 _id) external onlyAdmin {
        if (_from == address(0)) {
            _mint(_to, _id);
        } else if (_to == address(0)) {
            _burn(_id);
        } else {
            _transfer(_from, _to, _id);
        }
    }

    /* override ERC721*/
    function ownerOf(uint256 id) public view override returns (address) {
        if (_exists(id)) {
            return super.ownerOf(id);
        }

        return address(0);
    }
}
