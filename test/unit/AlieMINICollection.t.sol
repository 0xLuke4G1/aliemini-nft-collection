// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {BaseSetUp} from "../BaseSetup.t.sol";
import {AlieMINICollection} from "../../src/AlieMINICollection.sol";

contract Test__AlieMINICollection is BaseSetUp {
    function setUp() public override {
        super.setUp();
    }

    modifier changeMintState() {
        vm.prank(OWNER);
        alieminiCollection.changeMintState();
        _;
    }

    modifier minted(address to) {
        vm.prank(OWNER);
        alieminiCollection.changeMintState();
        vm.prank(to);
        alieminiCollection.mintMINI{value: price}();
        _;
    }

    function test__ContractInitialized() public view {
        assert(alieminiCollection.isMintOpen() == false);
        assert(alieminiCollection.getTotalSupply() == totalSupply);
        assert(alieminiCollection.getMaxMintsPerAddress() == maxMintsPerAddress);
        assert(alieminiCollection.getPrice() == price);
    }

    ////////// Public Mint

    // 1. Can't Mint if Mint Phase is Not Open

    function test__CantMintIfMintPhaseIsNotOpen() public {
        vm.expectRevert(AlieMINICollection.AlieMINICollection__NotAllowedToMint.selector);
        vm.prank(USER_1);
        alieminiCollection.mintMINI{value: price}();
    }

    // 2. Can't mint if exceeding Total Supply

    function test__CantMintIfExceedingTotalSupply() public changeMintState {
        AlieMINICollection newCollection = new AlieMINICollection(price, 0, maxMintsPerAddress, devFee);
        newCollection.changeMintState();

        vm.expectRevert(AlieMINICollection.AlieMINICollection__ExceedsTotalSupply.selector);
        vm.prank(USER_1);
        newCollection.mintMINI{value: price}();
    }

    // 3. Cant mint with Insufficient amount

    function test__CantMintWithInsufficientAmount() public changeMintState {
        vm.expectRevert(AlieMINICollection.AlieMINICollection__InsufficientAmount.selector);
        vm.prank(USER_1);
        alieminiCollection.mintMINI{value: price - 1}();
    }

    // 4. Cant mint if max Mint per address is exceeded

    function test__CantMintIfExceedingMaxMintPerAddress() public changeMintState {
        // @dev to facilitate the work, a new aliemini contract has been created with mint limit set to 0.
        vm.startPrank(DEV);
        AlieMINICollection newCollection = new AlieMINICollection(price, totalSupply, 1, devFee);
        newCollection.changeMintState();
        vm.stopPrank();

        vm.startPrank(USER_1);
        newCollection.mintMINI{value: price}();

        vm.expectRevert(AlieMINICollection.AlieMINICollection__MaxQuantityMintableExceeded.selector);
        newCollection.mintMINI{value: price}();
        vm.stopPrank();
    }

    // 5. Emits Minted Event

    function test__EmitMintEvent() public changeMintState {
        vm.expectEmit(address(alieminiCollection));
        emit MintedMINI(USER_1, 0);

        vm.prank(USER_1);
        alieminiCollection.mintMINI{value: price}();
    }

    // 6. Can Mint with success

    function test__CanMintWithSuccessAndSendFeeToDev() public changeMintState {
        uint256 expectedBalance = price * devFee / 100;

        vm.prank(USER_1);
        alieminiCollection.mintMINI{value: price}();

        assertEq(alieminiCollection.ownerOf(0), USER_1);
        assert(address(alieminiCollection).balance == price - expectedBalance);
        assert(DEV.balance == expectedBalance);
    }

    ////////// Airdrop Mint

    // 1. Only the Owner can Airdrop

    function test__OnlyOwnerCanMakeAirdrops() public {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(USER_1);
        alieminiCollection.airdropMINI(USER_1);
    }
    // 2. Can't mint if exceeding Total Supply

    function test__CantAirdropIfExceedingTotalSupply() public {
        // @dev to facilitate the work, a new aliemini contract has been created with total supply set to 0.
        vm.startPrank(OWNER);

        AlieMINICollection alieminiCollection0Supply = new AlieMINICollection(price,0,maxMintsPerAddress,devFee);
        alieminiCollection0Supply.changeMintState();

        vm.stopPrank();

        // @dev since 'totalSupply' is 0, when minting token 1 it should revert
        vm.prank(OWNER);
        vm.expectRevert(AlieMINICollection.AlieMINICollection__ExceedsTotalSupply.selector);
        alieminiCollection0Supply.airdropMINI(USER_1);
    }

    // 3. Emits Airdrop event

    function test__EmitAirdropEvent() public {
        vm.expectEmit(address(alieminiCollection));
        emit AirdroppedMINI(USER_1, 0);

        vm.prank(OWNER);
        alieminiCollection.airdropMINI(USER_1);
    }

    // 4. Can Airdrop with success

    function test__CanAirdropWithSuccess() public {
        vm.prank(OWNER);
        alieminiCollection.airdropMINI(USER_1);

        assertEq(alieminiCollection.ownerOf(0), USER_1);
    }

    ////////// Withraw To

    // 1. Cant withdraw if balance is zero

    function test__CantWithdrawZeroBalance() public {
        vm.expectRevert(abi.encodeWithSelector(AlieMINICollection.AlieMINICollection__CantWithdrawZero.selector));

        vm.prank(OWNER);
        alieminiCollection.withdraw();
    }

    // 2. Emits Withdrawn Event

    function test__EmitWithdrawnEvent() public minted(USER_1) {
        vm.expectEmit(address(alieminiCollection));
        emit AlieMINICollection.WithdrawnSuccessful();

        vm.prank(OWNER);
        alieminiCollection.withdraw();
    }

    // 3. Can Withdraw with success

    function test__CanWithdrawWithSuccess() public minted(USER_1) {
        uint256 expectedBalance = price * (100 - devFee) / 100;

        vm.prank(OWNER);
        alieminiCollection.withdraw();
        assert(address(alieminiCollection).balance == 0);
        assert(OWNER.balance == expectedBalance);
    }

    ////////// Setters

    function test__Setters() public minted(USER_1) {
        string memory newBaseURI = "new base uri";
        uint8 newMaxMintsPerAddress = 16;
        uint64 newPrice = 167e17;

        vm.startPrank(OWNER);
        alieminiCollection.changeMintState();
        alieminiCollection.setBaseURI(newBaseURI);
        alieminiCollection.setMaxMintsPerAddress(newMaxMintsPerAddress);
        alieminiCollection.setPrice(newPrice);
        vm.stopPrank();

        assert(alieminiCollection.isMintOpen() == false);
        assert(
            keccak256(abi.encodePacked(alieminiCollection.tokenURI(0)))
                == keccak256(abi.encodePacked(newBaseURI, "0", ".json"))
        );
        assert(alieminiCollection.getMaxMintsPerAddress() == newMaxMintsPerAddress);
        assert(alieminiCollection.getPrice() == newPrice);
        assert(alieminiCollection.getTotalMinted() == 1);
        assert(alieminiCollection.getNumberOfTokensMintend(USER_1) == 1);
    }

    // Cant Set Lower Mint Limit

    function test__CantSetLowerMintLimit() public {
        vm.expectRevert(AlieMINICollection.AlieMINICollection__MintLimitCanOnlyBeIncreased.selector);

        vm.prank(OWNER);
        alieminiCollection.setMaxMintsPerAddress(maxMintsPerAddress - 1);
    }

    // Emits Price Changed Events

    function test__SetPriceEmitsEvent() public {
        uint64 newPrice = 167404e10;

        vm.expectEmit(address(alieminiCollection));
        emit PriceChanged(newPrice);

        vm.prank(OWNER);
        alieminiCollection.setPrice(newPrice);
    }
}
