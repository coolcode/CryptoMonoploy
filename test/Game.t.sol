// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Test, console } from "forge-std/Test.sol";
import { Gold } from "src/core/Gold.sol";
import { Property } from "src/core/Property.sol";
import { Mapdata, TYPE_LOTTERY, TYPE_JAIL } from "src/core/interfaces/IMap.sol";
import { SquareMap } from "src/core/SquareMap.sol";
import { Game, UserInfo } from "src/v1/Game.sol";
import { DeploymentEnv } from "./mocks/DeploymentEnv.sol";

contract GameTest is Test, DeploymentEnv {
    address owner = address(0xFFFF);
    address vault = address(0xEEEE);
    address alice = address(0xA11CE);

    Property nft;
    Gold gold;
    SquareMap map;
    Game game;

    uint256 constant initializedAmount = 1_000_000e18;

    function setUp() public {
        vm.label(owner, "Owner");
        vm.deal(owner, 1000 ether);
        vm.label(proxyAdmin, "ProxyAdmin");
        vm.deal(proxyAdmin, 1000 ether);
        vm.label(alice, "Alice");

        nft = new Property();
        gold = new Gold();
        map = new SquareMap();

        map.set(5, Mapdata({ land: TYPE_LOTTERY, price: 0, reward: 100, fee: 0 }));
        map.set(10, Mapdata({ land: TYPE_JAIL, price: 0, reward: 0, fee: 200 }));

        bytes memory bytecode = type(Game).creationCode;
        bytes memory initializedData = abi.encodeWithSelector(Game.initialize.selector, owner, nft, gold, map, vault);
        game = Game(deployProxy("Game", bytecode, initializedData));

        gold.approve(address(game), type(uint256).max);
        game.deposit(vault, initializedAmount);

        gold.transfer(alice, initializedAmount);
        vm.startPrank(alice);
        gold.approve(address(game), type(uint256).max);
        game.deposit(alice, initializedAmount);
        vm.stopPrank();
    }

    function test_balance() external {
        assertEq(game.balanceOf(vault), initializedAmount, "vault balance");
        assertEq(game.balanceOf(alice), initializedAmount, "alice balance");
    }

    function test_withdraw() external {
        vm.prank(alice);
        game.withdraw(alice, initializedAmount);
        assertEq(game.balanceOf(alice), 0, "alice balance (deposit on game)");
        assertEq(gold.balanceOf(alice), initializedAmount, "alice balance (owned)");
    }

    function test_roll() external {
        vm.startPrank(owner);
        game.moveTo(alice, 1, 2);
        vm.stopPrank();

        UserInfo memory userInfo = game.userInfo(alice);
        assertEq(userInfo.pos, 3, "pos = 3");
    }

    function test_lottery() external {
        vm.startPrank(owner);
        game.moveTo(alice, 1, 4);
        vm.stopPrank();

        UserInfo memory userInfo = game.userInfo(alice);
        assertEq(userInfo.pos, 5, "pos = 5");
        assertEq(game.balanceOf(alice), initializedAmount + 100e18, "alice balance");
    }

    function test_jail() external {
        vm.startPrank(owner);
        game.moveTo(alice, 1, 4);
        game.moveTo(alice, 1, 4);
        vm.stopPrank();

        UserInfo memory userInfo = game.userInfo(alice);
        assertEq(userInfo.pos, 10, "pos = 10");
        assertEq(game.balanceOf(alice), initializedAmount + 100e18 - 200e18, "alice balance");
    }

    function testFuzz_SetNumber(uint256 x) external {
        //assertEq(123, x);
    }
}
