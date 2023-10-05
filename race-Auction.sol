// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
//import "contracts/Admin.sol";


contract RaceAuction is Ownable{
 //errors   
 error RaceAuction__NotAdmin();
 error RaceAuction__InvalidBasePrice();
 error RaceAuction__InvalidDuration();

 struct Auction{
 uint256 tokenId;
 uint256 basePrice;
 uint256 duration;//duration of auction to
 uint256 startTime;//auction start time
 uint256 endTime;
//address payable[] s_bidders;
//address seller;
 bool ended;

 }

 uint256 AuctionCount;
 IERC721 NFT;
 Auction auction;

 mapping (address admin => bool) admins;
 mapping(uint256 AuctionCount => Auction)public auctionCountToAuction;


 function setNftContract(address _address) external onlyOwner returns (bool){
 NFT = IERC721(_address);
 return true;

 }


 function addNFT(uint256 _tokenId,uint256 _basePrice, uint256 _duration) external view returns (bool){ //investor
 _addNFT(_tokenId, _basePrice, _duration);
 return true;
 }

 function addAdmin(address _address) external onlyOwner returns(bool){//onlyDIC
 admins[_address] = true;
 return true;
 }

 function removeAdmin(address _address) external onlyOwner returns(bool){//onlyDIC
 admins[_address] =false;
 return true;
 }

 function _addNFT(uint256 _tokenId, uint256 _basePrice, uint256 _duration) internal view returns (bool){
 if(NFT.ownerOf(_tokenId) !=msg.sender){
 revert RaceAuction__NotAdmin();
 }
 if(_basePrice == 0){
 revert RaceAuction__InvalidBasePrice();
 }

 }


 function CreateAuction(uint256 _tokenId, uint256 _basePrice, uint256 _duration) external onlyOwner() { //onlyDIC
    if (NFT.ownerOf(_tokenId) != msg.sender) {
        revert RaceAuction__NotAdmin();
    }
    if (_basePrice == 0) {
        revert RaceAuction__InvalidBasePrice();
    }
    if (_duration <= 0) {
        revert RaceAuction__InvalidDuration();
    }

    //Auction storage auction = auctionCountToAuction[AuctionCount];
    auction.tokenId = _tokenId;
    auction.basePrice = _basePrice;
    auction.duration = _duration;
    auction.endTime = block.timestamp + _duration;
    auction.ended = false;
    AuctionCount++;
}

function makeBid(uint256 _itemId) public payable {}
}

