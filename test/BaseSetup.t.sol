// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {Deploy__AlieMINI} from "../script/DeployAlieMINI.s.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {AlieMINICollection} from "../src/AlieMINICollection.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

abstract contract BaseSetUp is Test {
    using Strings for uint256;

    AlieMINICollection alieminiCollection;
    HelperConfig config;

    uint64 price;
    uint64 totalSupply;
    uint8 maxMintsPerAddress;
    uint8 devFee;
    uint256 deployerKey;

    address DEV;
    address OWNER = makeAddr("owner");
    address USER_1 = makeAddr("user1");

    uint256 public constant DEAL_AMOUNT = 100e18;
    uint256 public constant DEV_FEE_PRECISION = 100;

    event MintedMINI(address indexed to, uint256 tokenId);
    event AirdroppedMINI(address indexed to, uint256 tokenId);
    event PriceChanged(uint64 newPrice);
    event WithdrawnSuccessful();
    event BaseURIChanged();

    function setUp() public virtual {
        Deploy__AlieMINI deployer = new Deploy__AlieMINI();
        (alieminiCollection, config) = deployer.run();

        (price, totalSupply, maxMintsPerAddress, devFee, deployerKey) = config.activeConstructorConfig();

        DEV = vm.addr(deployerKey);
        vm.deal(USER_1, DEAL_AMOUNT);

        vm.startPrank(DEV);
        alieminiCollection.transferOwnership(OWNER);
        vm.stopPrank();
    }
}
