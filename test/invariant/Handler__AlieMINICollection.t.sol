// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {AlieMINICollection} from "../../src/AlieMINICollection.sol";
import {Test} from "forge-std/Test.sol";

contract Handler__AlieMINICollection is Test {
    AlieMINICollection alieminiCollection;

    constructor(AlieMINICollection _collection) {
        alieminiCollection = _collection;
    }

    /////// Public Mint
    function mint(address from) public {
        if (alieminiCollection.isMintOpen() == false) return;

        // return if exceeds max public mints
        uint256 numberMinted = alieminiCollection.getNumberOfTokensMintend(from);
        if (numberMinted + 1 > alieminiCollection.getMaxMintsPerAddress()) return;

        // calculation of the price and deal
        uint256 price = alieminiCollection.getPrice();
        vm.deal(from, price);

        vm.prank(from);
        alieminiCollection.mintMINI{value: price}();
    }

    /////// Airdrop

    function airdrop() public {
        // bound the airdrop amount in order to not exceed the total supply
        uint256 tokensAvailable = alieminiCollection.getTotalSupply() - alieminiCollection.getTotalMinted();
        if (tokensAvailable == 0) return;

        vm.prank(alieminiCollection.owner());
        alieminiCollection.airdropMINI(msg.sender);
    }

    //////// SET MINT STATE

    function setMintState() public {
        vm.prank(alieminiCollection.owner());
        alieminiCollection.changeMintState();
    }

    //////// WITHDRAW

    function withdraw() public {
        if (address(alieminiCollection).balance == 0) return;
        vm.prank(alieminiCollection.owner());
        alieminiCollection.withdraw();
    }

    function setMaxMints(uint256 newLimit) public {
        newLimit = bound(newLimit, alieminiCollection.getMaxMintsPerAddress(), alieminiCollection.getTotalSupply());

        vm.prank(alieminiCollection.owner());
        alieminiCollection.setMaxMintsPerAddress(uint8(newLimit));
    }

    function setPrice(uint256 newPrice) public {
        newPrice = bound(newPrice, 0, type(uint64).max);

        vm.prank(alieminiCollection.owner());
        alieminiCollection.setPrice(uint64(newPrice));
    }
}
