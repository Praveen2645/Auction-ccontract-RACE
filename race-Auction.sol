// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
//import "contracts/Admin.sol";


contract RaceAuction is AccessControl{

bytes32 public constant USER =keccak256("USER");


 //errors   

 error RaceAuction__InvalidBasePrice();
 error RaceAuction__InvalidDuration();
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
 //uint256 currentBid; //the current bid 
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
 modifier isBidValid(
        uint256 tokenId,
        uint256 bidAmount
    ) {
        if (bidAmount <= AuctionDetails[tokenId].highestBid
        ) {
            revert RaceAuction__SendMoreToMakeBid();
        }
        _;
    }

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

 function setNftContract(address _NftContractAddress) external  returns (bool){ //onlyDIC
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
    //AuctionDetails[_tokenId].seller = msg.sender;
   
    AuctionDetails[_tokenId].startAt = block.timestamp;
    AuctionDetails[_tokenId].endAt = _duration+ block.timestamp;
    AuctionDetails[_tokenId].IsStarted = true;
  

    NFT.transferFrom(msg.sender,address(this),_tokenId);
   
   if (NFT.ownerOf(_tokenId) != address(this)) {
        revert RaceAuction__NftTransferFailed();
   }   
    AuctionCount++;

}

function placeBid(uint256 _tokenId) public payable isBidValid(_tokenId, msg.value) isAuctionEnded(_tokenId) {
   
    if(hasRole(DEFAULT_ADMIN_ROLE,msg.sender)){
        revert RaceAuction__AdminNotAllowedToBid();
    }
    
    if(!AuctionDetails[_tokenId].IsStarted){
        revert RaceAuction__AuctionNotStarted();
    }
    
    // Check if the bid is higher than the current highest bid 
    //eg: current bid= 200
    //msg.value(300)>previousBid(200)
             
    if (msg.value > AuctionDetails[_tokenId].highestBid) {
        // Refund the previous highest bidder
        address payable previousHighestBidder = payable (AuctionDetails[_tokenId].highestBidder);
        uint256 previousHighestBid = AuctionDetails[_tokenId].highestBid;

        // Update the highest bidder and temporary highest bid
        AuctionDetails[_tokenId].highestBidder = msg.sender;
        AuctionDetails[_tokenId].highestBid = msg.value;

        // Update the bid information for the bidder
        AuctionDetails[_tokenId].bidders.push(payable(msg.sender));
        biddersToAmount[msg.sender] = msg.value;

        // Refund the previous highest bidder
        if (previousHighestBidder != address(0)) {
            previousHighestBidder.transfer(previousHighestBid);
        }

        
    } else {
        revert RaceAuction__SendMoreToMakeBid();
    }
}

function cancelAuction(uint256 _tokenId) external returns(bool){
      AuctionDetails[_tokenId].IsStarted = false;
      AuctionCount--;
      return true;
}

//if no bidders for the nft DIC can withdraw NFT

// function adminRemoveNFT(uint256 _tokenId) public {
//     Auction storage auction = AuctionDetails[_tokenId];

//     require(hasRole(ONLY_ADMIN, msg.sender), "Caller is not the admin");
//     require(auction.IsStarted, "Auction has not started yet");

//     // Check if there are no bidders for this auction
//     if (auction.bidders.length == 0) {
//         // Transfer the NFT back to the original owner
//         NFT.transferFrom(address(this), NFT.ownerOf(_tokenId), _tokenId);

//         // Reset auction details
//         delete AuctionDetails[_tokenId];

//         AuctionCount--;

//     }
// }

function extendDurationOfAuction() external {}

////////////////////////
  //GETTER FUNCTIONS//
////////////////////////

function getAuctionStartTime() public view returns (uint256 tokenId){
    AuctionDetails[tokenId].startAt;
    }

function getAuctionEndingTime() public view returns(uint256 tokenId){
    AuctionDetails[tokenId].endAt;
}

function getAuctionCurrentTime() public view returns(uint256){}

function getAuctionDuration() public view returns(uint256 tokenId){
    AuctionDetails[tokenId].duration;
}

function getBasePrice() public view returns(uint256 tokenId){
    AuctionDetails[tokenId].basePrice;
}

function getAuctionStatus() public view returns(uint256 tokenId){
    AuctionDetails[tokenId].IsStarted;
}

// function getAmountBidByAddress() public view returns(address toeknId){
//     AuctionDetails[tokenId].
// }


 
}


