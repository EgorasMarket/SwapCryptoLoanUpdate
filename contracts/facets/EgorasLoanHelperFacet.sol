// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;
import "../libraries/LibDiamond.sol";
import "../libraries/SafeDecimalMath.sol";
import "../libraries/SafeMath.sol";
import "./AppStorage.sol";
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    function mint(address account, uint256 amount) external  returns (bool);
    function burnFrom(address account, uint256 amount) external returns (bool);
}

interface NFT {
function ownerOf(uint256 tokenId) external view returns (address);
function mint(address to, uint tokenID) external returns(bool);
function burn(uint tokenID) external returns(bool);
  
}

interface LOAN {
    
      struct Loan{
        string title;
        uint amount;
        uint length;
        string image_url;
        address creator;
        bool isloan;
        string loanMetaData;
        uint inventoryFee;
        bool isConfirmed;
    }
function rewardMeta() external view returns(bool, uint, uint, uint, uint, address);
function rewardUsserMeta(uint index, uint curPeriod) external view returns(address, uint, uint);
function updatePeriods() external;
function getLoanData(uint _lID) external view returns (uint, uint, address, bool, bool);
function getAddresses() external view returns (address, address);
}



contract EgorasLoanHelperFacet {
    AppStorage internal s;
  using SafeDecimalMath for uint;
    using SafeMath for uint256;
  struct LoanPlaceholder{
        string title;
        uint amount;
        uint length;
        string image_url;
        address creator;
        bool isloan;
        string loanMetaData;
        uint inventoryFee;
        bool isConfirmed;
    }
event Bought(uint _id, string _metadata, uint _time);
event Rewarded(uint amount, address voterAddress, uint _id, uint time);
function rewardVoters() external{
LOAN ln = LOAN(address(this));
bool _HcanReward;
uint _HnextRewardDate;
uint _HcurVoterLen;
uint _HdailyIncentive;
address _HegorasEGC;
uint _HcurrentPeriod;
(_HcanReward, _HnextRewardDate, _HcurVoterLen, _HdailyIncentive, _HcurrentPeriod, _HegorasEGC) = ln.rewardMeta();
require(block.timestamp >= _HnextRewardDate, "Not yet time. Try again later");
require(_HcanReward, "No votes yet");
 IERC20 iERC20 = IERC20(_HegorasEGC);
 for (uint256 i = 0; i < _HcurVoterLen; i++) {
           address _HvoterAddress;
           uint _Hamount;
           uint _Htotal;
           (_HvoterAddress, _Hamount, _Htotal) = ln.rewardUsserMeta(i, _HcurrentPeriod);
           uint per = _Hamount.divideDecimalRound(_Htotal);
           uint reward = _HdailyIncentive.multiplyDecimalRound(per);
           require(iERC20.mint(_HvoterAddress, reward ), "Fail to mint EGC");
           emit Rewarded(reward, _HvoterAddress, _HcurrentPeriod, block.timestamp);
    } 
   
   ln.updatePeriods();
}

 function Initconstructor(
address _egorasEusd, address _egorasEgr, address _egorasEGC, uint _votingThreshold, uint _backers, uint _company, uint _branch, uint _dailyIncentive) external{
        require(address(0) != _egorasEusd, "Invalid address");
        require(address(0) != _egorasEgr, "Invalid address");
         require(address(0) != _egorasEGC, "Invalid address");
        s.egorasEGR = _egorasEgr;
        s.egorasEUSD = _egorasEusd;
        s.egorasEGC  = _egorasEGC;
        s.votingThreshold = _votingThreshold;
        s.backers = _backers;
        s.company = _company;
        s.branch = _branch;
        s.nextRewardDate = block.timestamp.add(1 days);
        s.currentPeriod = block.timestamp;
        s.dailyIncentive = _dailyIncentive;
}

function buy(uint _id, string memory _buyerMetadata) external{
   
    uint amount;
    uint length;
  
    address creator;
    bool isloan;
   

    LOAN ln = LOAN(address(this));

    bool isApproved;
     ( amount, length, creator, isloan, isApproved) = ln.getLoanData(_id);
    require(!isloan, "Invalid buy order.");
    require(isApproved, "You can't buy this asset at the moment!");
    address egorasEUSD;
    address eNFTAddress;
    (egorasEUSD, eNFTAddress) = ln.getAddresses();
    IERC20 iERC20 = IERC20(egorasEUSD);
    NFT eNFT = NFT(eNFTAddress);
    require(iERC20.allowance(msg.sender, address(this)) >= amount, "Insufficient EUSD allowance for repayment!");
    iERC20.burnFrom(msg.sender, amount);
    eNFT.burn(_id);
    emit Bought(_id,_buyerMetadata, block.timestamp); 
}

 function auction(uint _loanID, string memory _buyerMetadata) external{
  
    uint amount;
    uint length;
  
    address creator;
    bool isloan;
  
   LOAN ln = LOAN(address(this));
  
   bool isApproved;
     (amount,length, creator, isloan, isApproved) = ln.getLoanData(_loanID);
 
   require(isloan, "Invalid loan.");
   require(block.timestamp >= length, "You can't auction it now!");
   require(isApproved, "This loan is not eligible for repayment!");
   require(creator != msg.sender, "Unauthorized.");
   address egorasEUSD;
    address eNFTAddress;
    (egorasEUSD, eNFTAddress) = ln.getAddresses();
    IERC20 iERC20 = IERC20(egorasEUSD);
    NFT eNFT = NFT(eNFTAddress);
    require(iERC20.allowance(msg.sender, address(this)) >= amount, "Insufficient EUSD allowance for repayment!");
    iERC20.burnFrom(msg.sender, amount);
    eNFT.burn(_loanID);
    emit Bought(_loanID,_buyerMetadata, block.timestamp); 
 }


function getAddresses() external view returns (address, address) {
    
    return(s.egorasEUSD, s.eNFTAddress);
}
    
}