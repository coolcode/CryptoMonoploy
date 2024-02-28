// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.0;

import { PausableUpgradeable } from "openzeppelin-contracts-upgradeable/contracts/utils/PausableUpgradeable.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { CommitRevealUpgradeable } from "src/core/CommitRevealUpgradeable.sol";
import { IProperty, Metadata, MAXIMUM_NUMBER_OF_PROPERTY } from "src/core/interfaces/IProperty.sol";
import { IMap, Mapdata, EDGE_POSITION, TYPE_RAW_LAND } from "src/core/interfaces/IMap.sol";

struct CommitInfo {
    uint256 amount;
    address user;
}

struct UserInfo {
    uint16 pos;
    uint64 steps;
}

contract Game is CommitRevealUpgradeable, PausableUpgradeable {
    error InsufficientBalance();
    error InvalidLand();
    error InvalidOwner();

    IProperty public nft;
    IERC20 public gold;
    IMap public map;

    mapping(address => uint256) public balances;
    mapping(bytes32 => CommitInfo) public commits;
    mapping(address => UserInfo) public users;
    mapping(uint16 => uint256) public nftIds;

    uint256 public baseCollateral = 0;
    uint256 public basePrice = 0;
    uint256 public baseEarn = 0;
    uint16 public taxRate = 0;

    address public vault;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    //event Roll(address indexed user, uint8 dice0, uint8 dice1);

    event Move(address indexed user, uint16 pos, uint8 dice0, uint8 dice1);
    //event PayRent(address indexed user, uint16 indexed pos, uint256 fee);
    event Buy(address indexed user, uint16 indexed pos, uint256 fee);
    event Upgrade(address indexed user, uint16 indexed pos, uint256 fee);
    //event Reward(uint8 indexed group, address indexed user, uint16 indexed pos, uint256 value);

    function initialize(address _owner, IProperty _nft, IERC20 _gold, IMap _map, address _vault) external initializer {
        __Game_init(_owner, _nft, _gold, _map, _vault);
    }

    function __Game_init(address _owner, IProperty _nft, IERC20 _gold, IMap _map, address _vault) internal onlyInitializing {
        __Game_init_unchained(_owner, _nft, _gold, _map, _vault);
    }

    function __Game_init_unchained(address _owner, IProperty _nft, IERC20 _gold, IMap _map, address _vault) internal onlyInitializing {
        __Ownable_init_unchained(_owner);
        __Pausable_init_unchained();
        setVersion(1);
        nft = _nft;
        gold = _gold;
        map = _map;
        vault = _vault;

        baseCollateral = 1000 * 1e18;
        basePrice = 1e18;
        baseEarn = 1e16;
        taxRate = 300;
    }

    //receive() external payable { }

    function userInfo(address user) external view returns (UserInfo memory) {
        return users[user];
    }

    function balanceOf(address user) external view returns (uint256) {
        return balances[user];
    }

    function deposit(address user, uint256 amount) external {
        gold.transferFrom(msg.sender, address(this), amount);
        balances[user] += amount;
        emit Deposit(user, amount);
    }

    function withdraw(address user, uint256 amount) external whenNotPaused {
        balances[msg.sender] -= amount;
        gold.transfer(user, amount);
        emit Withdraw(user, amount);
    }

    function commit(uint64 commitLastBlock, bytes32 secretHash, uint8 v, bytes32 r, bytes32 s)
        external
        onlySecretSigner(commitLastBlock, secretHash, v, r, s)
        whenNotPaused
    {
        if (balances[msg.sender] < baseCollateral) revert InsufficientBalance();

        commits[secretHash] = CommitInfo({ amount: baseCollateral, user: msg.sender });
    }

    function reveal(uint256 secret) external onlyRevealer whenNotPaused {
        bytes32 secretHash = keccak256(abi.encodePacked(secret));
        uint256 n = uint256(keccak256(abi.encodePacked(secret, block.number)));
        uint256 n1 = n & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        uint256 n2 = n >> 128;
        uint8 dice0 = uint8((n1 % 6) + 1);
        uint8 dice1 = uint8((n2 % 6) + 1);
        CommitInfo memory commitInfo = commits[secretHash];
        _move(commitInfo.user, dice0, dice1);
    }

    // *********** for test only ****************/
    function moveTo(address user, uint8 r1, uint8 r2) external onlyOwner {
        _move(user, r1, r2);
    }

    function _move(address user, uint8 r1, uint8 r2) private {
        UserInfo storage userInfo = users[user];
        uint16 steps = uint16(r1 + r2);
        uint16 nextPos = userInfo.pos > 0 ? userInfo.pos + steps : steps;
        if (nextPos >= EDGE_POSITION) {
            // last position
            nextPos -= EDGE_POSITION;
        }

        userInfo.pos = nextPos;
        userInfo.steps += steps;

        emit Move(user, nextPos, r1, r2);

        Mapdata memory mapdata = map.get(nextPos);
        if (mapdata.reward > 0) {
            uint256 fee = mapdata.reward * basePrice;
            balances[user] += fee;
            balances[vault] -= fee;
        }

        if (mapdata.fee > 0) {
            uint256 fee = mapdata.fee * basePrice;
            address propertyOwner = _nftOwner(nextPos);
            if (propertyOwner != user) {
                balances[user] -= fee;
                if (propertyOwner != address(0x0)) {
                    uint256 tax = fee * taxRate / 10000;
                    balances[vault] += tax;
                    balances[propertyOwner] += (fee - tax);
                } else {
                    balances[vault] += fee;
                }
            }
        }

        // check rent

        // if (_owner == user) {
        //     // my house, rent go up!
        //     _pe.upgrade(pos, true);
        // } else {
        //     // someone's house, pay rent
        //     uint16 rent_fee = _pe.rentPrice(pos);
        //     _pe.upgrade(pos, false);

        //     uint256 token_rent = _price2Token(rent_fee);
        //     _pe.mortgage(user, address(this), token_rent);

        //     if (!_inJail(_owner)) {
        //         // rent
        //         // 12.5% to bonus pool
        //         uint256 _bonus = token_rent >> 3;
        //         _transferToken(_owner, token_rent.sub(_bonus));
        //         _transferToken(address(this), _bonus);
        //     } else {
        //         // owner is in jail, pay to prize pool
        //         _transferToken(address(this), token_rent);
        //     }
        //     emit PayRent(user, pos, rent_fee);
        // }
    }

    function nftOwner(uint16 pos) external view returns (address) {
        return _nftOwner(pos);
    }

    function _nftOwner(uint16 pos) internal view returns (address) {
        uint256 nftId = nftIds[pos];
        if (nftId == 0) {
            return address(0x0);
        }

        return nft.ownerOf(nftId);
    }

    // function needRentalFee(uint16 pos, address user) internal view returns(uint256){
    //     uint256 nftId  =  nftIds[pos];
    //     if(nftId==0){
    //         return 0;
    //     }

    //    Metadata memory metadata = nft.metadata(nftId);
    //    metadata.level* map.get(pos)
    // }

    function buy() external whenNotPaused {
        address user = msg.sender;
        UserInfo memory userinfo = users[user];
        Mapdata memory mapdata = map.get(userinfo.pos);
        if (mapdata.land != TYPE_RAW_LAND) revert InvalidLand();

        uint256 fee = mapdata.price * basePrice;
        if (balances[user] < fee) revert InsufficientBalance();

        balances[user] -= fee;
        balances[vault] += fee;

        Metadata memory metadata = Metadata({ blocknum: uint160(block.number), level: 1, score: 0 });
        nft.mint(user, metadata);
        emit Buy(user, userinfo.pos, fee);
    }

    function upgrade() external whenNotPaused {
        address user = msg.sender;
        UserInfo memory userinfo = users[user];
        Mapdata memory mapdata = map.get(userinfo.pos);
        address propertyOwner = _nftOwner(userinfo.pos);
        if (propertyOwner != user) revert InvalidOwner();

        uint256 nftId = nftIds[userinfo.pos];
        Metadata memory metadata = nft.metadata(nftId);
        uint256 fee = (metadata.level + 1) * mapdata.price * basePrice;
        if (balances[user] < fee) revert InsufficientBalance();

        balances[user] -= fee;
        balances[vault] += fee;

        metadata.level += 1;
        nft.setMetadata(nftId, metadata);
        emit Upgrade(user, userinfo.pos, fee);
    }
}
