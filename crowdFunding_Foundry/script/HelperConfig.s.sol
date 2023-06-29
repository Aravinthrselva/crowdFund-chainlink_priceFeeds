// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script } from "forge-std/Script.sol";
import {MockV3Aggregator} from "../src/MockV3Aggregator.sol";

contract HelperConfig is Script {

    struct NetworkConfig {
            address priceFeed;
    }

    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8 ;

    NetworkConfig public activeNetworkConfig;

    event HelperConfig_CreatedMockPriceFeed(address priceFeed);

    constructor() {
        if(block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } 
        else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    // get the address from the -- ETH/USD aggregator contract deployed on sepolia testnet
    function getSepoliaEthConfig() public pure returns(NetworkConfig memory sepoliaNetworkConfig) {

        sepoliaNetworkConfig = NetworkConfig({
            priceFeed : 0x694AA1769357215DE4FAC081bf1f309aDC325306   // ETH / USD on sepolia
        });

    }


    // mock Aggregator on the local anvil chain
    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory anvilNetworkConfig) {    

        if(activeNetworkConfig.priceFeed != address(0)) {
            return activeNetworkConfig;
        }

        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(DECIMALS, INITIAL_PRICE);
        vm.stopBroadcast();

        emit HelperConfig_CreatedMockPriceFeed(address(mockPriceFeed));

        anvilNetworkConfig = NetworkConfig({ priceFeed : address(mockPriceFeed)});
    }

}