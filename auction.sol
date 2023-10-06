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
 error RaceAuction__FailedToTransferNFT();
 error RaceAuction__InvalidIpfsHash();
 

 struct Auction{
 uint256 tokenId;
 uint256 basePrice;
 uint256 duration;//duration of auction t
// uint256 startAt;//auction start time
 //uint256 endAt; //auction endtime
 string  ipfsHash;
 address payable[] bidders;
 address seller;
 bool ended;
 }
 
 address highestBidder;
 uint256 AuctionCount;
 IERC721  NFT;
 uint256 highestBid;
 Auction auction;
 
 mapping (address admin => bool) admins;
 mapping(uint256 AuctionCount => Auction) auctionCountToAuction;
 mapping(address bidders => uint256 amount)  biddersToAmount;

////////////////////////////
   ///FUNCTIONS///
////////////////////////////   

 function setNftContract(address _address) external onlyOwner returns (bool){
 NFT = IERC721(_address);
 return true;

 }

 function addNFT(uint256 _tokenId,uint256 _basePrice, uint256 _duration, string memory _ipfsHash) external view returns (bool){ //investor
 _addNFT(_tokenId, _basePrice, _duration,_ipfsHash);
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

 function _addNFT(uint256 _tokenId, uint256 _basePrice, uint256 _duration, string memory _ipfsHash) internal view returns (bool){
 if(NFT.ownerOf(_tokenId) !=msg.sender){
 revert RaceAuction__NotAdmin();
 }
 if(_basePrice == 0){
 revert RaceAuction__InvalidBasePrice();
 }
 if(_duration <=0){
    revert RaceAuction__InvalidDuration();
 }

 
//  
return true;
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
    auction.duration = block.timestamp + _duration;
 //   auction.startBlock= block.timestamp;
   // auction.endBlock = 
    auction.ended = false;
    AuctionCount++;
}

function placeBid(uint256 _itemId) public payable {}

function cancelAuction(uint256 _itemId) external {}

function withdraw() external{}

}

