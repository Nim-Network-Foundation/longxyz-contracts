// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import { Test, console } from "forge-std/Test.sol";
import { Hooks } from "@v4-core/libraries/Hooks.sol";
import { PoolManager } from "@v4-core/PoolManager.sol";
import { ITokenFactory } from "src/interfaces/ITokenFactory.sol";
import { UniswapV4Initializer } from "src/UniswapV4Initializer.sol";
import { DERC20 } from "src/DERC20.sol";
import { Doppler } from "src/Doppler.sol";
import { Airlock } from "src/Airlock.sol";
import { UniswapV4Initializer } from "src/UniswapV4Initializer.sol";

// mask to slice out the bottom 14 bit of the address
uint160 constant FLAG_MASK = 0x3FFF;

// Maximum number of iterations to find a salt, avoid infinite loops
uint256 constant MAX_LOOP = 100_000;

uint160 constant flags = uint160(
    Hooks.BEFORE_INITIALIZE_FLAG | Hooks.AFTER_INITIALIZE_FLAG | Hooks.BEFORE_ADD_LIQUIDITY_FLAG
        | Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG | Hooks.BEFORE_DONATE_FLAG
);

function mineV4(
    address airlock,
    address poolManager,
    uint256 initialSupply,
    uint256 numTokensToSell,
    address numeraire,
    ITokenFactory tokenFactory,
    bytes memory tokenFactoryData,
    UniswapV4Initializer poolInitializer,
    bytes memory poolInitializerData
) view returns (bytes32, address, address) {
    (
        ,
        uint256 minimumProceeds,
        uint256 maximumProceeds,
        uint256 startingTime,
        uint256 endingTime,
        int24 startingTick,
        int24 endingTick,
        uint256 epochLength,
        int24 gamma,
        bool isToken0,
        uint256 numPDSlugs
    ) = abi.decode(
        poolInitializerData, (uint160, uint256, uint256, uint256, uint256, int24, int24, uint256, int24, bool, uint256)
    );

    bytes32 dopplerInitHash = keccak256(
        abi.encodePacked(
            type(Doppler).creationCode,
            abi.encode(
                poolManager,
                numTokensToSell,
                minimumProceeds,
                maximumProceeds,
                startingTime,
                endingTime,
                startingTick,
                endingTick,
                epochLength,
                gamma,
                isToken0,
                numPDSlugs,
                airlock
            )
        )
    );

    (
        string memory name,
        string memory symbol,
        uint256 yearlyMintCap,
        uint256 vestingDuration,
        address[] memory recipients,
        uint256[] memory amounts
    ) = abi.decode(tokenFactoryData, (string, string, uint256, uint256, address[], uint256[]));

    bytes32 tokenInitHash = keccak256(
        abi.encodePacked(
            type(DERC20).creationCode,
            abi.encode(
                name, symbol, initialSupply, airlock, airlock, yearlyMintCap, vestingDuration, recipients, amounts
            )
        )
    );

    for (uint256 salt; salt < 100_000; ++salt) {
        address hook = computeCreate2Address(bytes32(salt), dopplerInitHash, address(poolInitializer.deployer()));
        address asset = computeCreate2Address(bytes32(salt), tokenInitHash, address(tokenFactory));

        if (
            uint160(hook) & FLAG_MASK == flags && hook.code.length == 0
                && ((isToken0 && asset < numeraire) || (!isToken0 && asset > numeraire))
        ) {
            return (bytes32(salt), hook, asset);
        }
    }

    revert("AirlockMiner: could not find salt");
}

function computeCreate2Address(bytes32 salt, bytes32 initCodeHash, address deployer) pure returns (address) {
    return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), deployer, salt, initCodeHash)))));
}

// UNCOMMENT AT YOUR OWN RISK
// CAUSES COMPILE TIME YUL EXCEPTION
// contract AirlockMinerTest is Test {

//     function test_mine_works() public view {
//         (bytes32 salt, address hook, address token) = mineV4(
//             address(airlock),
//             address(manager),
//             1e27,
//             1e27,
//             address(0),
//             ITokenFactory(address(0xfac)),
//             abi.encode("Test", "TST", 1e27, 0, new address[](0), new uint256[](0)),
//             initializer,
//             abi.encode(address(0x44444), 0, 0, 0, 0, 0, int24(0), int24(0), 0, int24(0), false, 0)
//         );

//         console.log("salt: %s", uint256(salt));
//         console.log("hook: %s", hook);
//         console.log("token: %s", token);
//     }
// }
