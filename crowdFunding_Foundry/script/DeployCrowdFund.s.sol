// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {Script } from "forge-std/Script.sol";
import {CrowdFund} from "../src/CrowdFund.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployCrowdFund is Script {

    function run() external returns(CrowdFund, HelperConfig) {

        HelperConfig helperConfig = new HelperConfig();
        address priceFeed = helperConfig.activeNetworkConfig() ;

        vm.startBroadcast();
        CrowdFund crowdFund = new CrowdFund(priceFeed);
        vm.stopBroadcast();

        return (crowdFund, helperConfig);
    }
}
