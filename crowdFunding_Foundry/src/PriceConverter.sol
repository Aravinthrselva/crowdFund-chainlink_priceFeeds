// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        
        return uint256(answer * 10000000000);
        // The returned int256 answer is an 8 decimal number
        // Multiplying with 1 000 000 000 0 to convert ETH/USD rate to 18 decimals
    }

    // 1000000000
    // call it get fiatConversionRate, since it assumes something about decimals
    // It wouldn't work for every aggregator
    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        // ethPrice -- 18 decimals 
        // ethAmount - 18 decimals
        // (ethPrice * ethAmount) - 36 decimals
        // dividing it by 1 000 000 000 000 000 000 -- to convert the answer to 18 decimals
        
        return ethAmountInUsd;
        // the actual ETH/USD conversation rate, after adjusting the extra 0s.
    }
}