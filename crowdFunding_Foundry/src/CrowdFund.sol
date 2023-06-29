//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;
import {AggregatorV3Interface} from "chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

// custom error
error CrowdFund_NotOwner();

contract CrowdFund {

    using PriceConverter for uint256;

    AggregatorV3Interface private s_priceFeed;
    uint256 public constant MINIMUM_USD = 50 * 10**18;
    address private immutable i_owner;
    address[] private s_funders;
    mapping (address => uint256) private s_addressToAmountFunded;

    // Functions Order:
    // constructor / modifier
    // receive     / fallback
    // external    / public
    // internal    / private
    // view        / pure

    constructor(address _priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(_priceFeed);
    }

    modifier onlyOwner {
        if(msg.sender != i_owner) 
            revert CrowdFund_NotOwner();
        
        _;
    }

    function fund() public payable {
      require(msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD, "Not enough eth");

      //require(PriceConverter.getConversionRate(msg.value, s_priceFeed) >= MINIMUM_USD, "You need to spend more ETH!");
      
      s_funders.push(msg.sender);
      // what if -- the same address sends fund more than once -- array elements will have repeated addresses
      s_addressToAmountFunded[msg.sender] += msg.value;  
    }
    
    /**
     * This function only exists for demonstration purposes
     * 
     * function costlyWithdraw() public onlyOwner {

        // accessing state variables in a loop is gas INEFFICIENT

        for(uint256 i=0; i < s_funders.length; i++) {
            address funder = s_funders[i];
            s_addressToAmountFunded[funder] = 0;
        }

        // clears all the addresses from the state array 
        s_funders = new address[](0);

        (bool success, ) = i_owner.call{value : address(this).balance}("");
        require(success);
    }
    */

    function withdraw() public onlyOwner {

        // copying state variable to local variable to save gas
        address[] memory l_funders = s_funders;  

        for(uint256 i=0; i < l_funders.length; i++) {
            address funder = l_funders[i];
            s_addressToAmountFunded[funder] = 0;
        }


        s_funders = new address[](0);

        (bool success, ) = i_owner.call{value : address(this).balance}("");
        require(success);
    } 

    function getVersion() public view returns(uint256) {
        return s_priceFeed.version();
    }

    function getPriceFeedContract() public view returns(AggregatorV3Interface) {
        return s_priceFeed;
    }


    function getOwner() public view returns(address) {
        return i_owner;
    }

    function getFunderAddrArray(uint16 _index) public view returns(address) {
        return s_funders[_index];
    }

    function getAddrToAmountFunded(address _funderAddr) public view returns(uint256) {  
        return s_addressToAmountFunded[_funderAddr]; 
    }   

}



