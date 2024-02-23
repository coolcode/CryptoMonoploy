// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20Burnable.sol";
import "../utils/AdminRole.sol";

/**
 * @title ERC20Token
 * @dev Very simple ERC20 Token example, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `ERC20` functions.
 */
contract ERC20Token is ERC20, AdminRole {
    uint256 private constant INITIAL_SUPPLY = 10 ** 18 * (10 ** 18);
    /* candy cannot convert back to ETH */
    mapping(address => uint256) private _candies;
    uint256 private _release_candies = 0;
    uint256 private _release_token = 0;

    event TransferCandy(address indexed from, address indexed to, uint256 value);
    event SendCandy(address indexed to, uint256 value);
    event BurnCandy(address indexed to, uint256 value);
    event Refund(address indexed to, uint256 value);

    constructor() public ERC20("CC Token https://github.com/coolcode", "CC") {
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    /**
     * @dev Transfer token for a specified address
     * @param from The address to transfer from.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function safeTransfer(address from, address to, uint256 value) public onlyAdmin returns (bool) {
        uint256 bal = balanceOf(from);
        if (bal < value) {
            value = bal;
        }
        if (from == address(0)) {
            _mint(to, value);
            _release_token = _release_token.add(value);
        } else if (to == address(0)) {
            _burn(from, value);
        } else {
            _transfer(from, to, value);
        }
        //emit SafeTransfer(from, to, value);
        return true;
    }

    /**
     * @dev Internal function that mints an amount of the token of a given
     * account.
     * @param account The account whose tokens will be minted.
     * @param value The amount that will be minted.
     * @return A boolean that indicates if the operation was successful.
     */
    function safeMint(address account, uint256 value) public onlyAdmin returns (bool) {
        _mint(account, value);
        _release_token = _release_token.add(value);
        //emit SafeTransfer(address(0), account, value);
        return true;
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account.
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     * @return A boolean that indicates if the operation was successful.
     */
    function safeBurn(address account, uint256 value) public onlyAdmin returns (bool) {
        _burn(account, value);
        uint256 candyAmount = _candies[account];
        if (candyAmount > 0) {
            if (candyAmount > value) {
                _candies[account] = candyAmount.sub(value);
                emit BurnCandy(account, value);
            } else {
                _candies[account] = 0;
                emit BurnCandy(account, candyAmount);
            }
        }
        //emit SafeTransfer(account, address(0), value);
        return true;
    }

    /**
     * @dev Internal function that refunds an amount of the token of a given
     * account.
     * @param account The account whose tokens will be refunded.
     * @param value The amount that will be refunded.
     * @return A boolean that indicates if the operation was successful.
     */
    function safeRefund(address account, uint256 value) public onlyAdmin returns (bool) {
        require(value <= balanceOf(account), "refund value > balance");
        _burn(account, value);
        emit Refund(account, value);
        return true;
    }

    /**
     * @dev Internal function that send an amount of the candy of a given
     * account.
     * @param account The account whose tokens will be sent.
     * @param value The amount that will be sent.
     * @return A boolean that indicates if the operation was successful.
     */
    function sendCandy(address account, uint256 value) external onlyAdmin returns (bool) {
        // uint256 v = _candies[account].add(value);
        if (!isAdmin(account)) {
            _candies[account] = _candies[account].add(value);
        }
        _mint(account, value);
        _release_candies = _release_candies.add(value);
        emit SendCandy(account, value);
        return true;
    }

    function tokenOf(address account) public view returns (uint256) {
        return balanceOf(account).sub(_candies[account]);
    }

    function candyOf(address account) public view returns (uint256) {
        return _candies[account];
    }

    function tokenRate() public view returns (uint256) {
        return _release_token.mul(1000) / (_release_token.add(_release_candies));
    }

    /* override */
    function _transfer(address from, address to, uint256 value) internal override {
        require(value <= balanceOf(from), "insufficient balance");
        if (!isAdmin(msg.sender)) {
            require(value <= tokenOf(from), "insufficient token");
        }

        if (isAdmin(msg.sender) || isAdmin(to)) {
            //consume candy first
            uint256 candyAmount = _candies[from];
            if (candyAmount > 0) {
                if (candyAmount > value) {
                    candyAmount = value;
                }
                _candies[from] = _candies[from].sub(candyAmount);
                //_candies[to] = candyAmount.add(candyAmount);
                emit TransferCandy(from, to, candyAmount);
            }
        }
        super._transfer(from, to, value);
    }
}
