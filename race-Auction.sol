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
 * When borrower unable to pay loan amount to the investor, the collateralized item will be on Auction by the DIC.
 * Where bidders can participate and bid required amount for an item. The winner of the Auction will get the NFT of an item by DIC.
 * And the bid amount can be withdrawn by Admin from the contract.
 */


contract RaceAuction is AccessControl, ReentrancyGuard{

     //////////////////
       // errors //
    ///////////////// 

 error RaceAuction__InvalidBasePrice();
 error RaceAuction__InvalidDuration();
 error RaceAuciton__NotNftOwner();
 error RaceAuction__BidAmountTooLow();
 error RaceAuction__AuctionFinished();
 error RaceAuction__NftTransferFailed();
 error RaceAuction__OngoingAuction();
 error RaceAuction__NotWinner();
 error RaceAuction__InsufficientBalance();
 //error RaceAuction__InvalidIpfsHash();

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
 //string  ipfsHash;
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


  constructor(Admin adminContractAddress) {
        admin = msg.sender;

        ADMIN_CONTRACT_ADD = adminContractAddress;
    }


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


function PlaceBid(uint256 _tokenId) public payable nonReentrant(){

    require(AuctionDetails[_tokenId].endAt >= block.timestamp,"Auction is finished");
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
        revert RaceAuction__BidAmountTooLow();
    }
}

function adminRemoveNFT(uint256 _tokenId) public onlyAdmin {
    Auction storage auctions = AuctionDetails[_tokenId];
 
    if (auctions.bidders.length == 0) {
        NFT.transferFrom(address(this),msg.sender, _tokenId);
        delete AuctionDetails[_tokenId];
        AuctionCount--;
    }
}


function extendDurationOfAuction(uint256 _tokenId, uint256 _extendDuration) external onlyAdmin returns (bool) {
   
    if (_extendDuration == 0) {
        revert RaceAuction__InvalidDuration();
    }
    AuctionDetails[_tokenId].duration += _extendDuration;
    AuctionDetails[_tokenId].endAt += _extendDuration;

    return true;
}


function transferNftToWinner(uint256 _tokenId, address _winnerAddress) external onlyAdmin returns(bool){
    
    if(block.timestamp < AuctionDetails[_tokenId].endAt){
        revert RaceAuction__OngoingAuction();
    }
    if (_winnerAddress != AuctionDetails[_tokenId].highestBidder){
        revert RaceAuction__NotWinner();
    }
    NFT.transferFrom(address(this),_winnerAddress,_tokenId); // transferring Nft to winner from contract
    emit NFTTransferred(_tokenId, _winnerAddress);

    delete AuctionDetails[_tokenId];
    AuctionCount--;
    return true;
}

//NEED TO IMPROVE
//the amount will be transfer back to the investor
function withdrawAmount() external onlyAdmin nonReentrant() returns(bool) {

    uint256 balance = address(this).balance;
    
    if(balance == 0){
        revert RaceAuction__InsufficientBalance();
    }

    (bool success, ) = msg.sender.call{value: balance}("");
    require(success, "Failed to transfer funds");

    return true;
}


function getAuction(uint256 _tokenId) public view returns (Auction memory ){
    return AuctionDetails[_tokenId];
    }

}


