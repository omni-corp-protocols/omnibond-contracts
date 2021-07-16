
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "./PancakeHelpers.sol";

struct Observation {
    uint timestamp;
    uint acc;
}

contract PriceFeed {
    using FixedPoint for *;

    uint public constant ethBaseUnit = 1e18;
    uint public constant expScale = 1e18;
    uint public immutable anchorPeriod = 3;
    uint public price;
    address public uniswapMarket = 0x2220EcdD9ff26DfD2605D2b489E55B2056159853;

    Observation public oldObservations;
    Observation public newObservations;

    constructor() public {
        uint cumulativePrice = currentCumulativePrice();
        oldObservations.timestamp = block.timestamp;
        newObservations.timestamp = block.timestamp;
        oldObservations.acc = cumulativePrice;
        newObservations.acc = cumulativePrice;
    }

    function updatePrice() external {
        updatePriceInternal();
    }

    function updatePriceInternal() internal {
        price = fetchAnchorPrice(expScale);
    }

    function currentCumulativePrice() internal view returns (uint) {
        (uint cumulativePrice0, ,) = PancakeOracleLibrary.currentCumulativePrices(uniswapMarket);
        return cumulativePrice0;
    }

    function fetchAnchorPrice(uint conversionFactor) internal virtual returns (uint) {
        (uint nowCumulativePrice, uint oldCumulativePrice, uint oldTimestamp) = pokeWindowValues();

        // This should be impossible, but better safe than sorry
        require(block.timestamp > oldTimestamp, "now must come after before");
        uint timeElapsed = block.timestamp - oldTimestamp;

        // Calculate uniswap time-weighted average price
        // Underflow is a property of the accumulators: https://uniswap.org/audit.html#orgc9b3190
        FixedPoint.uq112x112 memory priceAverage = FixedPoint.uq112x112(uint224((nowCumulativePrice - oldCumulativePrice) / timeElapsed));
        uint rawUniswapPriceMantissa = priceAverage.decode112with18();
        uint unscaledPriceMantissa = mul(rawUniswapPriceMantissa, conversionFactor);
        uint anchorPrice;

        anchorPrice = mul(unscaledPriceMantissa, expScale) / ethBaseUnit / expScale;

        return anchorPrice;
    }

    function pokeWindowValues() internal returns (uint, uint, uint) {
        uint cumulativePrice = currentCumulativePrice();

        Observation memory newObservation = newObservations;

        // Update new and old observations if elapsed time is greater than or equal to anchor period
        uint timeElapsed = block.timestamp - newObservation.timestamp;
        if (timeElapsed >= anchorPeriod) {
            oldObservations.timestamp = newObservation.timestamp;
            oldObservations.acc = newObservation.acc;

            newObservations.timestamp = block.timestamp;
            newObservations.acc = cumulativePrice;
        }
        return (cumulativePrice, oldObservations.acc, oldObservations.timestamp);
    }

    /// @dev Overflow proof multiplication
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) return 0;
        uint c = a * b;
        require(c / a == b, "multiplication overflow");
        return c;
    }
}