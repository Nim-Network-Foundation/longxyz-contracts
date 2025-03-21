// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import { Script, console } from "forge-std/Script.sol";
import { AssetData } from "src/Airlock.sol";

interface IAirlock {
    function getAssetData(
        address asset
    ) external view returns (AssetData memory assetData);

    function migrate(
        address asset
    ) external;
}

contract MigratePoolScript is Script {
    function run() public {
        address unichainSepoliaAirlock = 0x651ab94B4777e2e4cdf96082d90C65bd947b73A4;
        address asset = 0xf106DD9B7a5e25134e4ecabe634c6caAd6e084D5;

        vm.startBroadcast();
        IAirlock airlock = IAirlock(unichainSepoliaAirlock);
        airlock.migrate(asset);

        // AssetData memory assetData = airlock.getAssetData(asset);
        // console.log("numeraire:", assetData.numeraire);
        // console.log("numTokensToSell:", assetData.numTokensToSell);
        // console.log("totalSupply:", assetData.totalSupply);
        // console.log("pool:", assetData.pool);

        vm.stopBroadcast();
    }
}
