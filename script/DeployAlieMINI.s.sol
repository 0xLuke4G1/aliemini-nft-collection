// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {AlieMINICollection} from "../src/AlieMINICollection.sol";

contract Deploy__AlieMINI is Script {
    HelperConfig config; // helper config

    function run() external returns (AlieMINICollection, HelperConfig) {
        config = new HelperConfig();
        (uint64 price, uint64 totalSupply, uint8 maxMintsPerAddress, uint8 devFee, uint256 deployerKey) =
            config.activeConstructorConfig();

        vm.startBroadcast(deployerKey);

        AlieMINICollection alieminiCollection = new AlieMINICollection(price,totalSupply,maxMintsPerAddress,devFee);

        vm.stopBroadcast();
        return (alieminiCollection, config);
    }
}
