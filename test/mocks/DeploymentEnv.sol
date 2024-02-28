// SPDX-License-Identifier: GPLv3

pragma solidity ^0.8.0;

import { console } from "forge-std/console.sol";
import { Vm } from "forge-std/Vm.sol";
import { TransparentUpgradeableProxy, ITransparentUpgradeableProxy } from "openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { ERC1967Proxy } from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { ProxyAdmin } from "openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";

abstract contract DeploymentEnv {
    Vm private vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
    address internal proxyAdmin = address(0x1111);

    function deployProxy(bytes memory bytecode, bytes memory data) internal returns (address) {
        //console.log("deploying %s", contractName);
        address impl = deployCode(bytecode);
        //console.log("****  impl (%s): %s", contractName, impl);
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(impl, proxyAdmin, data);
        //ERC1967Proxy proxy = new ERC1967Proxy(impl, data);
        //console.log("****  proxy (%s): %s", contractName, address(proxy));
        return address(proxy);
    }

    function upgradeProxy(address proxy, address newImpl, bytes memory data) internal returns (address) {
        address proxyAdminContract = vm.computeCreateAddress(proxy, 1);
        address proxyAdminContractOwner = ProxyAdmin(proxyAdminContract).owner();
        console.log("****  proxy admin: %s, owner: %s", proxyAdminContract, proxyAdminContractOwner);
        require(proxyAdminContractOwner == proxyAdmin, "wrong proxy admin");
        // vm.startPrank(proxyAdmin);
        ProxyAdmin(proxyAdminContract).upgradeAndCall(ITransparentUpgradeableProxy(proxy), newImpl, data);
        // vm.stopPrank();
        console.log("****  upgrade proxy: %s", proxy);
        return proxy;
    }

    function deployCode(bytes memory bytecode) internal returns (address addr) {
        // console.log("*** bytecode: %s", bytecode.toHex());
        /// @solidity memory-safe-assembly
        assembly {
            addr := create(0, add(bytecode, 0x20), mload(bytecode))
        }

        require(addr != address(0), "Upgrades deployCode: Deployment failed.");
    }
}
