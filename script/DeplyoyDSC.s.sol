// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./Helperconfig.s.sol";
import {DecentralisedStableCoin} from "../src/DecentralisedStableCoin.sol";
import {DSCEngine} from "../src/DSCEngine.sol";

contract DeployDSC is Script {
    address[] tokenAddress;
    address[] priceFeedAddress;

    function run() external returns (DecentralisedStableCoin, DSCEngine, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        (address wethUsdPriceFeed, address wbtcUsdPriceFeed, address weth, address wbtc, uint256 deployerKey) =
            helperConfig.activeConfig();
        tokenAddress = [weth, wbtc];
        priceFeedAddress = [wethUsdPriceFeed, wbtcUsdPriceFeed];
        vm.startBroadcast(deployerKey);
        DecentralisedStableCoin dsc = new DecentralisedStableCoin();
        DSCEngine dscEngine = new DSCEngine(tokenAddress, priceFeedAddress, address(dsc));
        dsc.transferOwnership(address(dscEngine));
        vm.stopBroadcast();
        return (dsc, dscEngine, helperConfig);
    }
}
