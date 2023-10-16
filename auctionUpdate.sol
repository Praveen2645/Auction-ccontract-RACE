// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
//import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
//import "contracts/Admin.sol";


contract RaceAuction is AccessControl{

//bytes32 public constant ADMIN =keccak256("ADMIN");

 //errors   

 error RaceAuction__InvalidBasePrice();
 error RaceAuction__InvalidDuration();
 error RaceAuciton__NotNftOwner();
 error RaceAuction__FailedToTransferNFT();
 error RaceAuction__InvalidIpfsHash();
 error RaceAuction__SendMoreToPlaceBid();
 error RaceAuction__AuctionHasEnded();
 error RaceAuction__NotAdmin();
 error RaceAuction__NftTransferFailed();
 error RaceAuction__AdminNotAllowedToBid();
 error RaceAuction__AuctionNotStarted();
 error RaceAuction__AuctionNotEnded();
 error RaceAuction__NotWinner();
 error RaceAuction__NoBAlanceToWithdraw();
 //error RaceAuction__AuctionIsActive();


 constructor(){
      _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
 }

 struct Auction{
 uint256 tokenId;//nft Id
 uint256 basePrice;//base price for auction
 uint256 duration;//duration of auction
 uint256 startAt;//auction start time
 uint256 endAt; //auction ending time
 uint256 highestBid; //highest bid for NFT
 address highestBidder; //
 address payable[] bidders;
//  bool active; //auction active or not
 //string  ipfsHash;
 }

 uint256 public AuctionCount;
 IERC721  NFT;
 Auction auction;


 mapping(uint256 tokenId=> Auction)public AuctionDetails;
 mapping(address bidders => uint256 amount)  public biddersToAmount;
 

////////////////////////
   ///FUNCTIONS///
///////////////////////


 function setNftContract(address _NftContractAddress) external  returns (bool) { //onlyDIC
 if (!hasRole(DEFAULT_ADMIN_ROLE,msg.sender)){
    revert RaceAuction__NotAdmin();
 }
 NFT = IERC721(_NftContractAddress);
 return true;
 }
 
 function InitializeAuction( uint256 _tokenId, uint256 _basePrice, uint256 _duration) external { //onlyDIC
 if (!hasRole(DEFAULT_ADMIN_ROLE,msg.sender)){
    revert RaceAuction__NotAdmin();
 }
    if (NFT.ownerOf(_tokenId) != msg.sender) {
        revert RaceAuciton__NotNftOwner();
    }
    if (_basePrice == 0) {
        revert RaceAuction__InvalidBasePrice();
    }
    if (_duration <= 0) {
        revert RaceAuction__InvalidDuration();
    }
    
    AuctionDetails[_tokenId].tokenId = _tokenId;
    AuctionDetails[_tokenId].duration = _duration;
    AuctionDetails[_tokenId].basePrice = _basePrice;
    AuctionDetails[_tokenId].highestBid= _basePrice;
    AuctionDetails[_tokenId].startAt = block.timestamp;
    AuctionDetails[_tokenId].endAt = _duration + block.timestamp;
   
  
    NFT.transferFrom(msg.sender,address(this),_tokenId);//transferring NFt to the contract
   
   if (NFT.ownerOf(_tokenId) != address(this)) {
        revert RaceAuction__NftTransferFailed();
   }   
    AuctionCount++;
}

function PlaceBid(uint256 _tokenId) public payable {
   
    if(hasRole(DEFAULT_ADMIN_ROLE,msg.sender)){
        revert RaceAuction__AdminNotAllowedToBid();
    }
    
    // if(!AuctionDetails[_tokenId].active){
        
    //     revert RaceAuction__AuctionNotStarted();
    // }
// _duration + block.timestamp 
    if (
   AuctionDetails[_tokenId].endAt <
  block.timestamp){
        revert RaceAuction__AuctionHasEnded();
    }

     if (msg.value <= AuctionDetails[_tokenId].highestBid
        ) {
            revert RaceAuction__SendMoreToPlaceBid(); // name change
        }
             
    if (AuctionDetails[_tokenId].highestBid < msg.value) {
        
        address payable previousHighestBidder = payable (AuctionDetails[_tokenId].highestBidder);
        uint256 previousHighestBid = AuctionDetails[_tokenId].highestBid;


        AuctionDetails[_tokenId].highestBidder = msg.sender;
        AuctionDetails[_tokenId].highestBid = msg.value;

        
        // AuctionDetails[_tokenId].bidders.push(payable(msg.sender));
        biddersToAmount[msg.sender] = msg.value;//tokenid

        
        if (previousHighestBidder != address(0)) {
            previousHighestBidder.transfer(previousHighestBid); // use ccall function
            // make previous bidder maaping zero
        }
        
    } else {
        revert RaceAuction__SendMoreToPlaceBid();
    }
}

//Cancel Auction In case of emergrency
// function cancelAuction(uint256 _tokenId) external returns(bool){
//     if (!hasRole(DEFAULT_ADMIN_ROLE,msg.sender)){
//     revert RaceAuction__NotAdmin();
//  }
//     //   AuctionDetails[_tokenId].active = false;
//       AuctionCount--;
//       return true;
// }

//if no bidders for the nft DIC can withdraw NFT

function adminRemoveNFT(uint256 _tokenId) public {
    Auction storage auctions = AuctionDetails[_tokenId];

    if (!hasRole(DEFAULT_ADMIN_ROLE,msg.sender)){
    revert RaceAuction__NotAdmin();
 }
 
    // if(!AuctionDetails[_tokenId].active){
    //     revert RaceAuction__AuctionNotStarted();
    // }

    if (auctions.bidders.length == 0) {
        
        NFT.transferFrom(address(this),msg.sender, _tokenId);

        delete AuctionDetails[_tokenId];
        AuctionCount--;
    }
}

//function to extend duration of the on going Auction
function extendDurationOfAuction(uint256 _tokenId, uint256 _extendDuration) external returns (bool) {
    if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
        revert RaceAuction__NotAdmin();
    }
    
    // if (!AuctionDetails[_tokenId].active) {
    //     revert RaceAuction__AuctionNotStarted();
    // }

    if (block.timestamp >= AuctionDetails[_tokenId].endAt) {
        revert RaceAuction__AuctionHasEnded();
    }

    if (_extendDuration <= 0) {
        revert RaceAuction__InvalidDuration();
    }

    AuctionDetails[_tokenId].duration += _extendDuration;
    AuctionDetails[_tokenId].endAt += _extendDuration;

    return true;
}
//when auction end DIC transfer NFT to winner
function transferNftToWinner(uint256 _tokenId, address _winnerAddress) external  returns(bool){
    
    if(!hasRole(DEFAULT_ADMIN_ROLE,msg.sender)){
        revert RaceAuction__NotAdmin();
    }
    
    if(block.timestamp < AuctionDetails[_tokenId].endAt){
        revert RaceAuction__AuctionNotEnded();
    }
    

    if (_winnerAddress != AuctionDetails[_tokenId].highestBidder){
        revert RaceAuction__NotWinner();
    }
    NFT.transferFrom(address(this),_winnerAddress,_tokenId); // transferring Nft to winner from contract

    delete AuctionDetails[_tokenId];
    AuctionCount--;
    return true;
}


function withdrawAmount() external returns (bool) {
    
     if(hasRole(DEFAULT_ADMIN_ROLE,msg.sender)){
        revert RaceAuction__AdminNotAllowedToBid();
    }
    uint256 balance = address(this).balance;
    // require(balance > 0, "No balance to withdraw");
    if(balance == 0){
        revert RaceAuction__NoBAlanceToWithdraw();
    }
//transferring the amount to msg.sender
    (bool success, ) = msg.sender.call{value: balance}("");
    require(success, "Failed to transfer funds");

    return true;
}

////////////////////////
  //GETTER FUNCTIONS//
////////////////////////

function getAuctionStartTime(uint256 _tokenId) public view returns (uint256 ){
    return AuctionDetails[_tokenId].startAt;
    }

function getAuctionEndingTime(uint256 _tokenId) public view returns(uint256 ){
   return AuctionDetails[_tokenId].endAt;
}

function getAuctionDuration(uint256 _tokenId) public view returns(uint256){
    return AuctionDetails[_tokenId].duration;
}

function getBasePrice(uint256 _tokenId) public view returns(uint256 ){
    return AuctionDetails[_tokenId].basePrice;
}

// function getAuctionStatus(uint256 _tokenId) public view returns(bool){
//    return  AuctionDetails[_tokenId].active;
// }

// function getAuctionStatus(uint256 _tokenId) public view returns (bool) {
    
//     // return block.timestamp <= AuctionDetails[_tokenId].endAt && AuctionDetails[_tokenId].active;
// }

function getWinnerAuction(uint256 _tokenId) public view returns(address){
    return AuctionDetails[_tokenId].highestBidder;
}


}


