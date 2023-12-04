// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "contracts/Admin.sol";

/**
 * @title RaceAuction
 * @author pr@win & Rohit
 * The contract is designed to be as minimal as possible, with basic functionalities of Auction in the Decentralize world.
 * When proposer unable to pay loan amount to the investor, the collateralized item will be on Auction by the DIC.
 * Where bidders can participate and bid required amount for an item. The winner of the Auction will get the NFT of an item by DIC.
 * And the bid amount can be withdrawn by Admin from the contract.
 */


contract RaceAuction is AccessControl, ReentrancyGuard{

   ///////////////////////
     //State Variable //
  ////////////////////////

 uint256 public AuctionCount;
 IERC721  NFT;
 Auction auction;
 address public admin;
 Admin public immutable ADMIN_CONTRACT_ADD;

 struct Auction{
 uint256 tokenId;
 uint256 basePrice;
 uint256 duration;
 uint256 startAt;
 uint256 endAt;
 uint256 highestBid;
 address highestBidder; 
 address payable[] bidders;
 
 }

 mapping(uint256 tokenId => Auction)public AuctionDetails;

     //////////////////
       //Events //
    /////////////////

    event AuctionInitialized(uint256 indexed tokenId, uint256 basePrice, uint256 duration, address indexed admin);
    event BidPlaced(uint256 indexed tokenId, address indexed bidder, uint256 bidAmount);
    event NFTTransferred(uint256 indexed tokenId, address indexed winnerAddress);


    ////////////////////
      // modifiers //
    ///////////////////

       modifier onlyAdmin() {
        require(msg.sender == admin, "DIC: Only Admin can do this action!");
        _;
    }

    ////////////////////
      // Functions //
    ////////////////////


  constructor(Admin _adminContractAddress) {
        admin = msg.sender;

        ADMIN_CONTRACT_ADD = _adminContractAddress;
    }

  /* 
  *@param _NftContractAddress - address of the NFT contract
  *@notice This function sets the NFT Contract address for this Auction contract 
  */
 function setNftContract(address _NftContractAddress) external onlyAdmin returns (bool) { 
 NFT = IERC721(_NftContractAddress);
 return true;
 }
   /* 
  *@param _tokenId- tokenId of the NFT
  *@param _basePrice- base price of the AuctionItem
  *@param _duration- duration of the Auction
  *@notice This function will initialize the collateralized item's NFT for Auction by Admin.
  * and this NFT will be transfered to the contract address
  * from the owner.After this the Auction is started.
  */
 
 function InitializeAuction( uint256 _tokenId, uint256 _basePrice, uint256 _duration) external onlyAdmin { 
    require(NFT.ownerOf(_tokenId) == msg.sender,"Not owner of NFT");
    require(_basePrice != 0,"Invalid base price");
    require (_duration > 0, "Invalid draion");
    
    AuctionDetails[_tokenId].tokenId = _tokenId;
    AuctionDetails[_tokenId].duration = _duration;
    AuctionDetails[_tokenId].basePrice = _basePrice;
    AuctionDetails[_tokenId].highestBid= _basePrice;
    AuctionDetails[_tokenId].startAt = block.timestamp;
    AuctionDetails[_tokenId].endAt = _duration + block.timestamp;
   
    NFT.transferFrom(msg.sender,address(this),_tokenId);
    emit AuctionInitialized (_tokenId, _basePrice, _duration, msg.sender);

    require(NFT.ownerOf(_tokenId) == address(this),"NFT transfer failed");
    AuctionCount++;
}
 /* 
  *@param _tokenId- tokenId of the NFT
  *@notice This function place bid for the NFTs whic are out for Auction.
  *This function have some checks, for checking the Auction is live or not, 
  *checks the bid amount,which should be high than the previous bid amount.
  *Also the previous highest bidder will get his bidded amount back as the new bidder bid the high amount
  */

function PlaceBid(uint256 _tokenId) public payable nonReentrant(){

    require(AuctionDetails[_tokenId].endAt >= block.timestamp,"Auction is ended");
    require(msg.value>= AuctionDetails[_tokenId].highestBid," Bid Amount is low");
             
    if (AuctionDetails[_tokenId].highestBid < msg.value) {
        
        address payable previousHighestBidder = payable (AuctionDetails[_tokenId].highestBidder);
        uint256 previousHighestBid = AuctionDetails[_tokenId].highestBid;

        AuctionDetails[_tokenId].highestBidder = msg.sender;
        AuctionDetails[_tokenId].highestBid = msg.value;

    if (previousHighestBidder != address(0)) {
        previousHighestBidder.transfer(previousHighestBid); 
      
    }
        emit BidPlaced(_tokenId, msg.sender, msg.value);

    } else {
        revert ("Bid Amount Too Low");
    }
}
/* 
  *@param _tokenId- tokenId of the NFT
  *@notice This function helps admin to remove NFT if no bidders for the NFT or in case of emergency.
  *As admin call this function, the Auction stopped and the NFT transfer to Admin from the contact
  *And highest bidder's amount also send back to his account
  */

function adminRemoveNFT(uint256 _tokenId) public onlyAdmin {
    Auction storage auctions = AuctionDetails[_tokenId];
    
    if (auctions.bidders.length == 0) {
        NFT.transferFrom(address(this),msg.sender, _tokenId);
        delete AuctionDetails[_tokenId];
        AuctionCount--;
    }
}
// function adminRemoveNFT(uint256 _tokenId) public onlyAdmin {
    
//     Auction storage auctions = AuctionDetails[_tokenId];

//     //require(block.timestamp < auctions.endAt,"Auction ongoing");
//       // require( auctions.bidders.length==0,"Bidders present to Bid") ;
//         payable(auctions.highestBidder).transfer(auctions.highestBid);

//         NFT.transferFrom(address(this), msg.sender, _tokenId);
    
//     delete AuctionDetails[_tokenId];
//     AuctionCount--;
// }


/* 
  *@param _tokenId- tokenId of the NFT
  *@param _extendDuration- the time want extend
  *@notice This function extend the duration of the Auction set only by Admin.
  *And can extend the duration while Auction is on.
  */


function extendDurationOfAuction(uint256 _tokenId, uint256 _extendDuration) external onlyAdmin returns (bool) {
   require(_extendDuration != 0,"Please enter the valid duration");
   require(AuctionDetails[_tokenId].endAt > block.timestamp,"Auction is Ended");

    AuctionDetails[_tokenId].duration += _extendDuration;
    AuctionDetails[_tokenId].endAt += _extendDuration;

    return true;
}

/* 
  *@param _tokenId- tokenId of the NFT
  *@param _winnerAddress- the address of the winner
  *@notice This function is call by the Admin to transfer the Nft to the winner of the Auction
  *function have some checks which chek the auction is live or not , and also checks the winner address is correct or not
  */

function transferNftToWinner(uint256 _tokenId, address _winnerAddress) external onlyAdmin returns(bool){

    require(block.timestamp > AuctionDetails[_tokenId].endAt," Auction ongoing");
    require(_winnerAddress == AuctionDetails[_tokenId].highestBidder,"Not winner");
  
    NFT.transferFrom(address(this),_winnerAddress,_tokenId);
    emit NFTTransferred(_tokenId, _winnerAddress);

    delete AuctionDetails[_tokenId];
    AuctionCount--;
    return true;
}

//NEED TO IMPROVE
//the amount will be transfer back to the investor

/* 
 
  *@notice This function is call by the Admin to withdraw the amount from the contract
  */


function withdrawAmount() external onlyAdmin nonReentrant() returns (bool) {
    uint256 balance = address(this).balance;
    require(balance > 0, "Insufficient Balance");

    payable(msg.sender).transfer(balance);

    return true;
}

function getAuction(uint256 _tokenId) public view returns (Auction memory ){
    return AuctionDetails[_tokenId];
    }

  receive() external payable {}  

}

