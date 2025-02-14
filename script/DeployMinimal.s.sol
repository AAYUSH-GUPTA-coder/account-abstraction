// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {MinimalAccount} from "../src/ethereum/MinimalAccount.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployMinimal is Script {
    function run() external {}

    function deployMinimalAccount() public returns (HelperConfig, MinimalAccount) {
        HelperConfig helperConfig = new HelperConfig();
        // It will give the NetworkConfig of the current chain, chain the smart contract is deploying on
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        vm.startBroadcast(config.account);

        MinimalAccount minimalAccount = new MinimalAccount(config.entryPoint);
        // doubt: why do we need to transfer ownership to the deployer? beacuse deployer already owns the contract
        minimalAccount.transferOwnership(msg.sender);

        vm.stopBroadcast();
        return (helperConfig, minimalAccount);
    }
}
