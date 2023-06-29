// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {CrowdFund} from "../../src/CrowdFund.sol";
import {DeployCrowdFund} from "../../script/DeployCrowdFund.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";




contract CrowdFundTest is StdCheats, Test {
    CrowdFund public crowdFund;
    HelperConfig public helperConfig;

    uint256 public constant SEND_VALUE = 0.1 ether; // just an amount to pass the requirement 
    uint256 public constant STARTING_USER_BALANCE = 10 ether;
    uint256 public constant GAS_PRICE = 1;          // setting a gas price -since gas price is 0 on anvil local chain                    

    address public constant USER = address(1);    

    function setUp() public {

        DeployCrowdFund deployer = new DeployCrowdFund();
        (crowdFund, helperConfig) = deployer.run();
        console.log("Deployer address: ", address(deployer));
        console.log("msg.sender from setUp : ", msg.sender);

        vm.deal(USER, STARTING_USER_BALANCE); 
    }

    function testVersionCheck() public {

        uint256 returnedVersion = crowdFund.getVersion();

        assertEq(returnedVersion, 4); 

    }

    function testPriceFeedSetCorrectly() public {

        address returnedPriceFeed = address(crowdFund.getPriceFeedContract());
        address expectedPriceFeed = helperConfig.activeNetworkConfig();
        console.log("Price Feed Address", expectedPriceFeed);
        assertEq(returnedPriceFeed, expectedPriceFeed);
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert();
        crowdFund.fund{value : 0.01 ether}();
    }

    function testOwnerAddr() public {
        address returnedOwner = crowdFund.getOwner();
        address expectedOwner = msg.sender;

        console.log("MSG.SENDER: ", msg.sender);

        assertEq(returnedOwner, expectedOwner);
    }


    function testFundUpdatesFundedDataStructure() public {
        vm.startPrank(USER);
        crowdFund.fund{value : 2* SEND_VALUE}();
        crowdFund.fund{value : SEND_VALUE}();
        vm.stopPrank();

        uint256 recordedFund = crowdFund.getAddrToAmountFunded(USER);

        assertEq(3*SEND_VALUE, recordedFund);
    }


    function testAddsFunderToArrayOfFunders() public {
    
        vm.startPrank(USER);
        crowdFund.fund{value : SEND_VALUE}();
        vm.stopPrank();

        address returnedAddr = crowdFund.getFunderAddrArray(0);

        assertEq(USER, returnedAddr);

    }


    modifier funded() {
        vm.prank(USER);
        crowdFund.fund{value : SEND_VALUE}();
        assert(address(crowdFund).balance > 0);
        _;
    }


    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        crowdFund.withdraw();
    }   
    

    /* 
    Testing pattern

    1. Arrange 
    2. Act
    3. Assert 
    
    */


   function testWithdrawFromSingleFunder() public funded {
         
        // 1. Arrange
        uint256 initialOwnerBalance = crowdFund.getOwner().balance;
        uint256 initialCrowdFundBalance =  address(crowdFund).balance;

        vm.txGasPrice(GAS_PRICE);
        uint256 gasStart = gasleft();

        // 2. Act
        vm.startPrank(crowdFund.getOwner());
        crowdFund.withdraw();
        vm.stopPrank();

        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice; 
        console.log("tx.gasprice :", tx.gasprice);
        console.log("Gas Used :", gasUsed);

        uint256 finalOwnerBalance = crowdFund.getOwner().balance;
        uint256 finalCrowdFundBalance = address(crowdFund).balance;

        // 3. Assert
        assertEq(finalOwnerBalance /* + gasUsed */,   
                initialOwnerBalance + initialCrowdFundBalance);
        assertEq(finalCrowdFundBalance, 0); 

   }


   function testWithDrawFromMultipleFunders() public funded { 

        // 1. Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 2;
        
        // 2. Act
        for (uint160 i = startingFunderIndex; i < numberOfFunders + startingFunderIndex; i++ ) {
            hoax(address(i), STARTING_USER_BALANCE);
            crowdFund.fund{value : SEND_VALUE}();
            console.log("address ", i);
            console.log("is:", address(i));
        }

        // 1. Arrange
        uint256 initialOwnerBalance = crowdFund.getOwner().balance;
        uint256 initialCrowdFundBalance =  address(crowdFund).balance;
        console.log("Initial Owner Balance :", initialOwnerBalance);

        // 2. Act
        vm.prank(crowdFund.getOwner());
        crowdFund.withdraw();

        uint256 finalOwnerBalance = crowdFund.getOwner().balance;
        // uint256 finalCrowdFundBalance = address(crowdFund).balance;

        // 3. Assert
        assertEq(finalOwnerBalance, initialOwnerBalance + initialCrowdFundBalance);
        assertEq(finalOwnerBalance, initialOwnerBalance+ ((numberOfFunders + 1) * SEND_VALUE) );  // 10 + 1 funder from funded
}   

}
