// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/utils/Counters.sol";
// security mechanism that prevents reentrancy attacks
// A procedure is re-entrant if its execution can be interrupted in the middle, initiated over (re-entered), and both runs can complete without any errors in execution.
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "hardhat/console.sol";

contract NFTMarket is ReentrancyGuard {
    using Counters for Counters.Counter;
    // each individual itme that is created
    Counters.Counter private _itemIds;
    // number of items sold
    Counters.Counter private _itemsSold;

    // contract owner makes commission on every item sold via listing fee
    address payable owner;
    // listing price
    uint256 listingPrice = 0.025 ether;

    // set owner as the person deploying the contract
    constructor() {
        owner = payable(msg.sender);
    }

    // MarketItem object
    struct MarketItem {
        uint256 itemId;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    // pass in item id that returns the market item
    mapping(uint256 => MarketItem) private idToMarketItem;

    // event each time market item is created for front end
    event MarketItemCreated(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );

    /* Returns the listing price of the contract */
    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    /* Places an item for sale on the marketplace */
    // pass in nftContract address, tokenId and price for NFT to list
    // nonReentrant prevents reentry attack
    function createMarketItem(address nftContract, uint256 tokenId, uint256 price) public payable nonReentrant {
        // make sure price is greater then 0
        require(price > 0, "Price must be at least 1 wei");
        // make sure person is sending in listing price with transaction
        require(msg.value == listingPrice, "Price must be equal to listing price");

        // increment item id
        _itemIds.increment();
        // id of item that is currently going for sale
        uint256 itemId = _itemIds.current();

        // set value for mapping equal to marke item
        idToMarketItem[itemId] = MarketItem(
            itemId,
            nftContract,
            tokenId,
            payable(msg.sender),
            // owner is no one since seller is putting it for sale and no one has bought yet
            payable(address(0)),
            price,
            false
        );

        // transfer ownership from person to this current smart contract
        // IERC721 from open zeppelin
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        // emit event
        emit MarketItemCreated(
            itemId,
            nftContract,
            tokenId,
            msg.sender,
            address(0),
            price,
            false
        );
    }

    /* Creates the sale of a marketplace item */
    /* Transfers ownership of the item, as well as funds between parties */
    function createMarketSale(address nftContract, uint256 itemId) public payable nonReentrant {
        // create price variable equal to the current item price found in the MarketItem struct
        uint256 price = idToMarketItem[itemId].price;
        // create tokenId variable equal to the current tokenId found in the MarketItem struct
        uint256 tokenId = idToMarketItem[itemId].tokenId;
        // make sure the value passed is is equal to the price
        require(msg.value == price, "Please submit the asking price in order to complete the purchase");

        // transfer money from transaction to seller
        idToMarketItem[itemId].seller.transfer(msg.value);
        // transfer ownership of token from this smart contract's address to the buyer
        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
        // set value for owner to be the buyer
        idToMarketItem[itemId].owner = payable(msg.sender);
        // set value to sold
        idToMarketItem[itemId].sold = true;
        // increment items sold by 1
        _itemsSold.increment();
        // pay the owner of the contract the listing price
        payable(owner).transfer(listingPrice);
    }

    /* Returns all unsold market items */
    function fetchMarketItems() public view returns (MarketItem[] memory) {
        // var itemCount is the total number of items currently created
        uint256 itemCount = _itemIds.current();
        // unsoldItemCount is total value created minus total items sold
        uint256 unsoldItemCount = _itemIds.current() - _itemsSold.current();
        // local value for incrementing a number to loop over array
        uint256 currentIndex = 0;

        // empty array of MarketItem called items and the length is the number of unsoldItems
        MarketItem[] memory items = new MarketItem[](unsoldItemCount);
        // loop over total number of items that have been created
        for (uint256 i = 0; i < itemCount; i++) {
            // check to see if item is unsold
            // if so then insert into array of MarketItem
            if (idToMarketItem[i + 1].owner == address(0)) {
                // id of item that we're interacting with
                uint256 currentId = i + 1;
                // get the current MarketItem
                MarketItem storage currentItem = idToMarketItem[currentId];
                // insert the curernt item into the items array at the current index
                items[currentIndex] = currentItem;
                // add 1 to currentIndex
                currentIndex += 1;
            }
        }
        // return array
        return items;
    }

    /* Returns only items that a user has purchased */
    function fetchMyNFTs() public view returns (MarketItem[] memory) {
        // total item count
        uint256 totalItemCount = _itemIds.current();
        // itemCount counter for items that the individual user has purchased
        uint256 itemCount = 0;
        // local value for incrementing a number to loop over array
        uint256 currentIndex = 0;
        
        // loop over each market Item and if the owner is there then add 1 to item count
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].owner == msg.sender) {
                itemCount += 1;
            }
        }

        // create array equal to the item count
        MarketItem[] memory items = new MarketItem[](itemCount);
        // loop over total number of items that have been created
        for (uint256 i = 0; i < totalItemCount; i++) {
            // check and see if owner is equal to msg.sender
            if (idToMarketItem[i + 1].owner == msg.sender) {
                // set current id
                uint256 currentId = i + 1;
                // get current item
                MarketItem storage currentItem = idToMarketItem[currentId];
                // insert item into array
                items[currentIndex] = currentItem;
                // add 1 to currentIndex
                currentIndex += 1;
            }
        }
        // return array
        return items;
    }

    /* Returns only items a user has created */
    function fetchItemsCreated() public view returns (MarketItem[] memory) {
        // total item count
        uint256 totalItemCount = _itemIds.current();
        // itemCount counter for items that the individual user has purchased
        uint256 itemCount = 0;
        // local value for incrementing a number to loop over array
        uint256 currentIndex = 0;

        // loop over each market Item and if the seller is there then add 1 to item count
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].seller == msg.sender) {
                itemCount += 1;
            }
        }

        // create array equal to the item count
        MarketItem[] memory items = new MarketItem[](itemCount);
        // loop over total number of items that have been created
        for (uint256 i = 0; i < totalItemCount; i++) {
            // check and see if seller is equal to msg.sender
            if (idToMarketItem[i + 1].seller == msg.sender) {
                // set current id
                uint256 currentId = i + 1;
                // get current item
                MarketItem storage currentItem = idToMarketItem[currentId];
                // insert item into array
                items[currentIndex] = currentItem;
                // add 1 to currentIndex
                currentIndex += 1;
            }
        }
        // return array
        return items;
    }
}
