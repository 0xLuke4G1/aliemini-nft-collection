// SPDX-License-Identifier: MIT

/**
 *
 *     █████╗ ██╗     ██╗███████╗███╗   ███╗██╗███╗   ██╗██╗     ██████╗ ██████╗ ██╗     ██╗     ███████╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗
 *    ██╔══██╗██║     ██║██╔════╝████╗ ████║██║████╗  ██║██║    ██╔════╝██╔═══██╗██║     ██║     ██╔════╝██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║
 *    ███████║██║     ██║█████╗  ██╔████╔██║██║██╔██╗ ██║██║    ██║     ██║   ██║██║     ██║     █████╗  ██║        ██║   ██║██║   ██║██╔██╗ ██║
 *    ██╔══██║██║     ██║██╔══╝  ██║╚██╔╝██║██║██║╚██╗██║██║    ██║     ██║   ██║██║     ██║     ██╔══╝  ██║        ██║   ██║██║   ██║██║╚██╗██║
 *    ██║  ██║███████╗██║███████╗██║ ╚═╝ ██║██║██║ ╚████║██║    ╚██████╗╚██████╔╝███████╗███████╗███████╗╚██████╗   ██║   ██║╚██████╔╝██║ ╚████║
 *    ╚═╝  ╚═╝╚══════╝╚═╝╚══════╝╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝╚═╝     ╚═════╝ ╚═════╝ ╚══════╝╚══════╝╚══════╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝
 *
 */

pragma solidity ^0.8.19;

import {ERC721A} from "erc721a/contracts/ERC721A.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title AlieMINI Collection
 * @author Luke4G1
 * @notice AlieMINI is a limited ensemble of 125 uniquely designed aliens.
 * Each NFT is a passport to an exclusive club of collectors, offering a blend of art, rarity, and digital companionship.
 * Secure your AlieMINI and add an extraterrestrial twist to your collection.
 *
 */

contract AlieMINICollection is ERC721A, Ownable, ReentrancyGuard {
    // =============================================================
    //                            ERRORS
    // =============================================================

    error AlieMINICollection__InsufficientAmount();
    error AlieMINICollection__ExceedsTotalSupply();
    error AlieMINICollection__MaxQuantityMintableExceeded();
    error AlieMINICollection__AlreadyInThisState();
    error AlieMINICollection__NotAllowedToMint();
    error AlieMINICollection__WithdrawalFailed();
    error AlieMINICollection__DevTransferFailed();
    error AlieMINICollection__CantWithdrawZero();
    error AlieMINICollection__NullValue();
    error AlieMINICollection__MintLimitCanOnlyBeIncreased();

    // =============================================================
    //                       COLLECTION INFO
    // =============================================================

    // @dev contains all info about the collection
    struct CollectionInfo {
        uint64 price; // public price
        uint64 totalSupply; // total supply
        uint8 maxMintsPerAddress; // max quantity mintable for each account
        uint8 devFee; // developer fee
        bool isMintOpen;
    }

    CollectionInfo public s_collectionInfo;

    address payable immutable i_dev; // @dev address

    string private baseExtension = ".json";
    string private s_baseTokenURI;

    // =============================================================
    //                           MODIFIERS
    // =============================================================

    modifier mintOpen() {
        if (!s_collectionInfo.isMintOpen) revert AlieMINICollection__NotAllowedToMint();
        _;
    }

    // =============================================================
    //                            EVENTS
    // =============================================================

    event MintedMINI(address indexed to, uint256 tokenId);
    event AirdroppedMINI(address indexed to, uint256 tokenId);
    event PriceChanged(uint64 newPrice);
    event WithdrawnSuccessful();
    event BaseURIChanged();

    constructor(uint64 _price, uint64 _totalSupply, uint8 _maxMintsPerAddress, uint8 _devFee)
        ERC721A("AlieMINI Collection", "MINI")
    {
        // @dev set the contract's variables
        s_collectionInfo.devFee = _devFee;
        s_collectionInfo.maxMintsPerAddress = _maxMintsPerAddress;
        s_collectionInfo.price = _price;
        s_collectionInfo.totalSupply = _totalSupply;
        // @dev set dev address
        i_dev = payable(msg.sender);
    }

    // =============================================================
    //                        MINT OPERATIONS
    // =============================================================

    function mintMINI() external payable mintOpen nonReentrant {
        if (_totalMinted() + 1 > s_collectionInfo.totalSupply) {
            revert AlieMINICollection__ExceedsTotalSupply();
        }

        if (msg.value < s_collectionInfo.price) {
            revert AlieMINICollection__InsufficientAmount();
        }

        if (_numberMinted(msg.sender) - _getAux(msg.sender) + 1 > s_collectionInfo.maxMintsPerAddress) {
            revert AlieMINICollection__MaxQuantityMintableExceeded();
        }

        _safeMint(msg.sender, 1);
        _sendFeeToDev(msg.value); // @dev sends fee to the dev

        emit MintedMINI(msg.sender, _nextTokenId() - 1);
    }

    // =============================================================
    //                           AIRDROP
    // =============================================================

    function airdropMINI(address receiver) external onlyOwner nonReentrant {
        // @dev airdrop 1 token to the address
        if (_totalMinted() + 1 > s_collectionInfo.totalSupply) {
            revert AlieMINICollection__ExceedsTotalSupply();
        }
        // using aux to track airdropped tokens
        _setAux(receiver, _getAux(receiver) + 1);

        //mint
        _safeMint(receiver, 1);
        emit AirdroppedMINI(receiver, _nextTokenId() - 1);
    }

    // =============================================================
    //                            WITHDRAW
    // =============================================================

    function withdraw() external onlyOwner nonReentrant {
        uint256 amount = address(this).balance;
        if (amount == 0) revert AlieMINICollection__CantWithdrawZero(); // @dev revert if contract hasn't funds deposited.

        (bool success,) = payable(msg.sender).call{value: amount}(""); // @dev transfer
        if (!success) revert AlieMINICollection__WithdrawalFailed();
        emit WithdrawnSuccessful();
    }

    // =============================================================
    //                           SETTERS
    // =============================================================

    //// Mint Phase
    function changeMintState() external onlyOwner {
        s_collectionInfo.isMintOpen = !s_collectionInfo.isMintOpen;
    }

    //// Base URI
    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        s_baseTokenURI = _newBaseURI;
        emit BaseURIChanged();
    }

    //// Max Number of Public Mints
    function setMaxMintsPerAddress(uint8 _newLimit) external onlyOwner {
        if (_newLimit <= s_collectionInfo.maxMintsPerAddress) revert AlieMINICollection__MintLimitCanOnlyBeIncreased();
        s_collectionInfo.maxMintsPerAddress = _newLimit;
    }

    //// Public Price
    function setPrice(uint64 _newPrice) external onlyOwner {
        s_collectionInfo.price = _newPrice;
        emit PriceChanged(_newPrice);
    }

    // =============================================================
    //                              DEV
    // =============================================================

    // @dev sends fee to the developer
    function _sendFeeToDev(uint256 amount) internal {
        uint256 devFee = (amount * s_collectionInfo.devFee) / 100;
        (bool success,) = i_dev.call{value: devFee}("");
        if (!success) revert AlieMINICollection__DevTransferFailed();
    }

    // =============================================================
    //                            GETTERS
    // =============================================================

    function _baseURI() internal view override returns (string memory) {
        return s_baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), baseExtension)) : "";
    }

    function isMintOpen() public view returns (bool) {
        return s_collectionInfo.isMintOpen;
    }

    function getTotalMinted() external view returns (uint256) {
        return _totalMinted();
    }

    function getMaxMintsPerAddress() external view returns (uint8) {
        return s_collectionInfo.maxMintsPerAddress;
    }

    function getPrice() external view returns (uint64) {
        return s_collectionInfo.price;
    }

    function getTotalSupply() external view returns (uint64) {
        return s_collectionInfo.totalSupply;
    }

    function getNumberOfTokensMintend(address account) external view returns (uint256) {
        return _numberMinted(account);
    }
}
