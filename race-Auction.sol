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
 error RaceAuction__SendMoreToMakeBid();
 error RaceAuction__AuctionHasEnded();
 error RaceAuction__NotAdmin();
 error RaceAuction__NftTransferFailed();
 error RaceAuction__AdminNotAllowedToBid();
 error RaceAuction__AuctionNotStarted();


 constructor(){
      _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
 }

 
 struct Auction{
 uint256 tokenId;
 uint256 basePrice; //base price for auction
 uint256 duration;//duration of auction
 uint256 startAt;//auction start time
 uint256 endAt; //auction ending time
 uint256 highestBid; //highest bid
 address highestBidder;
 address payable[] bidders;
 bool IsStarted; //auction started or not
 //string  ipfsHash;
 }

 uint256 public AuctionCount;
 IERC721  NFT;
 Auction auction;

//for cecking the bid is valid or not
//  modifier isBidValid(
//         uint256 tokenId,
//         uint256 bidAmount
//     ) {
//         if (bidAmount <= AuctionDetails[tokenId].highestBid
//         ) {
//             revert RaceAuction__SendMoreToMakeBid();
//         }
//         _;
//     }

//for checking the Auction status
    modifier isAuctionEnded(
        uint256 tokenId
    ) {
          if (
            block.timestamp - AuctionDetails[tokenId].startAt >
            AuctionDetails[tokenId].duration
        ) {
            revert RaceAuction__AuctionHasEnded();
        }
        _;
    }


 mapping(uint256 tokenId=> Auction)public AuctionDetails;
 mapping(address bidders => uint256 amount)  public biddersToAmount;

//////////////////////////
   ///FUNCTIONS///
/////////////////////////   

// function setRoleForAdmin(address _admin) public returns(bool){
// _setupRole(ONLY_ADMIN, _admin);
// return true;
// }

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
    AuctionDetails[_tokenId].endAt = _duration+ block.timestamp;
    AuctionDetails[_tokenId].IsStarted = true;
  

    NFT.transferFrom(msg.sender,address(this),_tokenId);
   
   if (NFT.ownerOf(_tokenId) != address(this)) {
        revert RaceAuction__NftTransferFailed();
   }   
    AuctionCount++;
}

function PlaceBid(uint256 _tokenId) public payable {
   
    if(hasRole(DEFAULT_ADMIN_ROLE,msg.sender)){
        revert RaceAuction__AdminNotAllowedToBid();
    }
    
    if(!AuctionDetails[_tokenId].IsStarted){
        
        revert RaceAuction__AuctionNotStarted();
    }

    if (block.timestamp > AuctionDetails[_tokenId].endAt) {
        AuctionDetails[_tokenId].IsStarted = false; 
        revert RaceAuction__AuctionHasEnded();
    }
  
    if (
    block.timestamp - AuctionDetails[_tokenId].startAt >
    AuctionDetails[_tokenId].duration
    ) {
        revert RaceAuction__AuctionHasEnded();
    }

    
     if (msg.value <= AuctionDetails[_tokenId].highestBid
        ) {
            revert RaceAuction__SendMoreToMakeBid();
        }
             
    if (msg.value > AuctionDetails[_tokenId].highestBid) {
        
        address payable previousHighestBidder = payable (AuctionDetails[_tokenId].highestBidder);
        uint256 previousHighestBid = AuctionDetails[_tokenId].highestBid;


        AuctionDetails[_tokenId].highestBidder = msg.sender;
        AuctionDetails[_tokenId].highestBid = msg.value;

        
        AuctionDetails[_tokenId].bidders.push(payable(msg.sender));
        biddersToAmount[msg.sender] = msg.value;

        
        if (previousHighestBidder != address(0)) {
            previousHighestBidder.transfer(previousHighestBid);
        }
        
    } else {
        revert RaceAuction__SendMoreToMakeBid();
    }
}

//Cancel Auction In case of emergrency
function cancelAuction(uint256 _tokenId) external returns(bool){
      AuctionDetails[_tokenId].IsStarted = false;
      AuctionCount--;
      return true;
}

//if no bidders for the nft DIC can withdraw NFT

function adminRemoveNFT(uint256 _tokenId) public {
    Auction storage auctions = AuctionDetails[_tokenId];

    if (!hasRole(DEFAULT_ADMIN_ROLE,msg.sender)){
    revert RaceAuction__NotAdmin();
 }
 
    if(!AuctionDetails[_tokenId].IsStarted){
        revert RaceAuction__AuctionNotStarted();
    }

    if (auctions.bidders.length == 0) {
        
        NFT.transferFrom(address(this), NFT.ownerOf(_tokenId), _tokenId);

        delete AuctionDetails[_tokenId];
        AuctionCount--;
        

    }
}

//function to extend duration of the Auction
function extendDurationOfAuction(uint256 _tokenId, uint256 _extendDuration) external returns (bool) {
    if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
        revert RaceAuction__NotAdmin();
    }
    
    if (!AuctionDetails[_tokenId].IsStarted) {
        revert RaceAuction__AuctionNotStarted();
    }

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


////////////////////////
  //GETTER FUNCTIONS//
////////////////////////

function getAuctionStartTime(uint256 _tokenId) public view returns (uint256 ){
    return AuctionDetails[_tokenId].startAt;
    }

function getAuctionEndingTime(uint256 _tokenId) public view returns(uint256 ){
   return AuctionDetails[_tokenId].endAt;
}


// function timeLeftInAuction(uint256 _tokenId) public view returns(uint256){
//     return AuctionDetails[_tokenId].startAt - block.timestamp;
// }

function getAuctionDuration(uint256 _tokenId) public view returns(uint256){
    return AuctionDetails[_tokenId].duration;
}

function getBasePrice(uint256 _tokenId) public view returns(uint256 ){
    return AuctionDetails[_tokenId].basePrice;
}

function getAuctionStatus(uint256 _tokenId) public view returns(bool){
   return  AuctionDetails[_tokenId].IsStarted;
}

function getWinnerAuction(uint256 _tokenId) public view returns(address){
    return AuctionDetails[_tokenId].highestBidder;
}

}

// //function PlaceBid(uint256 _tokenId) public payable {
//     // ... (your existing code)

//     if (block.timestamp > AuctionDetails[_tokenId].endAt) {
//         AuctionDetails[_tokenId].IsStarted = false; // Set the flag to false when the auction ends
//         revert RaceAuction__AuctionHasEnded();
//     }

//     // ... (the rest of your code)
// }

// function hasAuctionEnded(uint256 _tokenId) public view returns (bool) {
//     return !AuctionDetails[_tokenId].IsStarted || (block.timestamp > AuctionDetails[_tokenId].endAt);
// }


