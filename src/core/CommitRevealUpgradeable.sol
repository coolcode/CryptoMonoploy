// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.0;

import { AccessControlUpgradeable } from "openzeppelin-contracts-upgradeable/contracts/access/AccessControlUpgradeable.sol";

import { OwnableUpgradeable } from "./OwnableUpgradeable.sol";

abstract contract CommitRevealUpgradeable is OwnableUpgradeable, AccessControlUpgradeable {
    error ExpiredBlockNumber(uint160 blocknum);
    error UnauthorizedSecretSigner();
    error UnauthorizedRevealer(address account);

    event Commit(bytes32 secretHash);

    bytes32 public constant SECRET_SINGER_ROLE = keccak256("SECRET_SINGER");
    bytes32 public constant REVEALER_ROLE = keccak256("REVEALER");

    modifier onlySecretSigner(uint64 commitLastBlock, bytes32 secretHash, uint8 v, bytes32 r, bytes32 s) {
        if (!canCommit(commitLastBlock, secretHash, v, r, s)) revert UnauthorizedSecretSigner();
        _;
    }

    modifier onlyRevealer() {
        if (!hasRole(REVEALER_ROLE, msg.sender)) revert UnauthorizedRevealer(msg.sender);
        _;
    }

    function canCommit(uint64 commitLastBlock, bytes32 secretHash, uint8 v, bytes32 r, bytes32 s) internal virtual returns (bool isValid) {
        if (block.number > commitLastBlock) revert ExpiredBlockNumber(uint64(block.number));
        bytes32 signatureHash = keccak256(abi.encodePacked(commitLastBlock, secretHash));
        address secretSigner = ecrecover(signatureHash, v, r, s);
        isValid = hasRole(SECRET_SINGER_ROLE, secretSigner);
        emit Commit(secretHash);
    }

    // function reveal(uint256 secret) external virtual onlyRevealer {
    //     // uint256 secretHash = uint256(keccak256(abi.encodePacked(secret)));
    // }

    function isSecretSigner(address account) external view returns (bool) {
        return hasRole(SECRET_SINGER_ROLE, account);
    }

    function addSecretSigner(address account) external onlyOwner {
        grantRole(SECRET_SINGER_ROLE, account);
    }

    function removeSecretSigner(address account) external onlyOwner {
        revokeRole(SECRET_SINGER_ROLE, account);
    }

    function isRevealer(address account) external view returns (bool) {
        return hasRole(REVEALER_ROLE, account);
    }

    function addRevealer(address account) external onlyOwner {
        grantRole(REVEALER_ROLE, account);
    }

    function removeRevealer(address account) external onlyOwner {
        revokeRole(REVEALER_ROLE, account);
    }
}
