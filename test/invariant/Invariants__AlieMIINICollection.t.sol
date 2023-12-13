// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {StdInvariant} from "forge-std/StdInvariant.sol";
import {AlieMINICollection} from "../../src/AlieMINICollection.sol";
import {BaseSetUp} from "../BaseSetup.t.sol";
import {Handler__AlieMINICollection} from "./Handler__AlieMINICollection.t.sol";

contract Invariants__AlieMINICollection is StdInvariant, BaseSetUp {
    Handler__AlieMINICollection handler;

    function setUp() public override {
        super.setUp();
        vm.prank(OWNER);
        handler = new Handler__AlieMINICollection(alieminiCollection);
        targetContract(address(handler));
    }

    // WHATE ARE OUR INVARIANTS

    // 1. Minted quantity should never exceed total supply
    function invariant__TotalMintedNeverExceedsMaxSupply() public view {
        uint256 totalTokensMinted = alieminiCollection.getTotalMinted();
        uint256 totalSupply = alieminiCollection.getTotalSupply();

        assert(totalTokensMinted <= totalSupply);
    }
}
