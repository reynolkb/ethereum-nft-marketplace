// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/utils/Counters.sol";
// allows for setTokenURI
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
// easy way to increment numbers
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "hardhat/console.sol";

// inhertis from storage which inherits from ERC721
contract NFT is ERC721URIStorage {
    // add counters to smart contract
    using Counters for Counters.Counter;
    // first token id is 1, second id is 2, etc
    Counters.Counter private _tokenIds;
    // address for marketplace that we want to allow the nft to be able to ineract with
    // want to give marketplace ability to transfer ownership from it's separate contract
    address contractAddress;

    // set marketplace address
    constructor(address marketplaceAddress) ERC721("Metaverse", "METT") {
        // first deploy the market, then deploy this contract
        contractAddress = marketplaceAddress;
    }

    // minting new tokens
    // only pass in tokenURI
    function createToken(string memory tokenURI) public returns (uint256) {
        // increment token ids
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        // mint token
        _mint(msg.sender, newItemId);
        // set token uri
        _setTokenURI(newItemId, tokenURI);
        // give the marketplace approval to transact the token between users from it's own contract
        setApprovalForAll(contractAddress, true);
        // return item id since we minting token in one transaction and setting it for sale in another transaction
        return newItemId;
    }
}
