// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
//import "contracts/Admin.sol";


contract RaceAuction is AccessControl{

bytes32 public constant  ONLY_ADMIN =keccak256("ONLY_ADMIN");

 //errors   
 //error RaceAuction__NotAdmin();
 error RaceAuction__InvalidBasePrice();
 error RaceAuction__InvalidDuration();
 error RaceAuction__FailedToTransferNFT();
 error RaceAuction__InvalidIpfsHash();
 error RaceAuction__SendMoreToMakeBid();
 error RaceAuction__AuctionHasEnded();

 
 struct Auction{
 uint256 tokenId;
 uint256 basePrice; //base price for auction
 uint256 duration;//duration of auction
 uint256 currentBid; //the current bid of the 
 uint256 startAt;//auction start time
 uint256 endAt; //auction ending time
 uint256 temporaryHighestBid;
 //address seller;
 address payable[] bidders;
 bool IsStarted; //auction started or not
 //string  ipfsHash;
 }

 
 address highestBidder;
 uint256 public AuctionCount;
 IERC721  NFT;
 uint256 highestBid;
 Auction auction;

 modifier isBidValid(
        uint256 tokenId,
        uint256 bidAmount
    ) {
        if (bidAmount <= AuctionDetails[tokenId].temporaryHighestBid
        ) {
            revert RaceAuction__SendMoreToMakeBid();
        }
        _;
    }

    modifier isAuctionEnded(
        //address nftAddress,
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
 mapping (address admin => bool) public admins;
 mapping(address bidders => uint256 amount)  public biddersToAmount;

//  constructor(address _admin){
//     _setupRole(ONLY_ADMIN, _admin);
//    //_setRoleAdmin(ONLY_ADMIN, _admin);
  
// }

//////////////////////////
   ///FUNCTIONS///
/////////////////////////   

function setRoleForAdmin(address _admin) public returns(bool){
_setupRole(ONLY_ADMIN, _admin);
return true;
}

 function setNftContract(address _NftContractAddress) external  returns (bool){ //onlyDIC
 require (hasRole(ONLY_ADMIN,msg.sender),"Caller is not the ADMIN");
 NFT = IERC721(_NftContractAddress);
 return true;
 }
 

 function addNFT(uint256 _tokenId, uint256 _basePrice, uint256 _duration)external view returns (bool){
    require (hasRole(ONLY_ADMIN,msg.sender),"Caller is not the ADMIN");
     if(NFT.ownerOf(_tokenId) !=msg.sender){
    
    }
    if(_basePrice == 0){
    revert RaceAuction__InvalidBasePrice();
    }
    if(_duration <= 0){
        revert RaceAuction__InvalidDuration();
    }
    return true;
 }

 function InitializeAuction( uint256 _tokenId, uint256 _basePrice, uint256 _duration) external { //onlyDIC
 require (hasRole(ONLY_ADMIN,msg.sender),"Caller is not the ADMIN");
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
    AuctionDetails[_tokenId].temporaryHighestBid= _basePrice;
    //AuctionDetails[_tokenId].seller = msg.sender;
    AuctionDetails[_tokenId].currentBid= AuctionDetails[_tokenId].temporaryHighestBid;
    AuctionDetails[_tokenId].startAt = block.timestamp;
    AuctionDetails[_tokenId].endAt = _duration+ block.timestamp;
    AuctionDetails[_tokenId].IsStarted = true;

    NFT.transferFrom(msg.sender,address(this),_tokenId);
   require(NFT.ownerOf(_tokenId) == address(this),"failed to tranfer nft");
   
    AuctionCount++;
}

// function placeBid(uint256 _tokenId) public payable isBidValid(_tokenId,msg.value) isAuctionEnded(_tokenId){
// if(AuctionDetails[_tokenId].IsStarted){

// }

// }
function placeBid(uint256 _tokenId) public payable isBidValid(_tokenId, msg.value) isAuctionEnded(_tokenId) {
    require(AuctionDetails[_tokenId].IsStarted, "Auction has not started yet");

    // Check if the bid is higher than the current highest bid
    if (msg.value > AuctionDetails[_tokenId].temporaryHighestBid) {
        // Refund the previous highest bidder
        address payable previousHighestBidder = payable(highestBidder);
        uint256 previousHighestBid = AuctionDetails[_tokenId].temporaryHighestBid;

        // Update the highest bidder and temporary highest bid
        highestBidder = msg.sender;
        AuctionDetails[_tokenId].temporaryHighestBid = msg.value;

        // Update the bid information for the bidder
        AuctionDetails[_tokenId].bidders.push(payable(msg.sender));
        biddersToAmount[msg.sender] = msg.value;

        // Refund the previous highest bidder
        if (previousHighestBidder != address(0)) {
            previousHighestBidder.transfer(previousHighestBid);
        }

        // Extend the auction duration (if necessary)

        
    } else {
        revert RaceAuction__SendMoreToMakeBid();
    }
}

function cancelAuction(uint256 _tokenId) external returns(bool){
      AuctionDetails[_tokenId].IsStarted = false;
      return true;
}

function withdrawNtf() external{}

}


