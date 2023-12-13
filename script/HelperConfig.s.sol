// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";

contract HelperConfig is Script {
    struct ConstructorConfig {
        uint64 _price;
        uint64 _totalSupply;
        uint8 _maxMintsPerAddress;
        uint8 _devFee;
        uint256 _deployerKey;
    }

    ConstructorConfig public activeConstructorConfig;

    uint256 public constant ANVIL_DEPLOYER_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    constructor() {
        if (block.chainid == 137) {
            activeConstructorConfig = getPolygonPoSConstructorConfig();
        } else if (block.chainid == 11155111) {
            activeConstructorConfig = getSepoliaConstructorConfig();
        } else if (block.chainid == 80001) {
            activeConstructorConfig = getMumbaiConstructorConfig();
        } else {
            activeConstructorConfig = getAnvilConstructorConfig();
        }
    }

    function getAnvilConstructorConfig() public pure returns (ConstructorConfig memory config) {
        config = ConstructorConfig({
            _price: 1e17,
            _totalSupply: 125,
            _maxMintsPerAddress: 5,
            _devFee: 10,
            _deployerKey: ANVIL_DEPLOYER_KEY
        });
    }

    function getSepoliaConstructorConfig() public view returns (ConstructorConfig memory config) {
        config = ConstructorConfig({
            _price: 1e17,
            _totalSupply: 125,
            _maxMintsPerAddress: 5,
            _devFee: 10,
            _deployerKey: vm.envUint("PRIVATE_KEY")
        });
    }

    function getMumbaiConstructorConfig() public view returns (ConstructorConfig memory config) {
        config = ConstructorConfig({
            _price: 1e17,
            _totalSupply: 125,
            _maxMintsPerAddress: 5,
            _devFee: 10,
            _deployerKey: vm.envUint("PRIVATE_KEY")
        });
    }

    function getPolygonPoSConstructorConfig() public view returns (ConstructorConfig memory config) {
        config = ConstructorConfig({
            _price: 1e18,
            _totalSupply: 125,
            _maxMintsPerAddress: 3,
            _devFee: 20,
            _deployerKey: vm.envUint("PRIVATE_KEY")
        });
    }
}
