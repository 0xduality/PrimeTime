// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.16;

import {Script} from "forge-std/Script.sol";

import {PrimeTime} from "../src/PrimeTime.sol";
import {Renderer} from "../src/Renderer.sol";

/// @notice A very simple deployment script
contract Deploy is Script {
    /// @notice The main script entrypoint
    /// @return erc721 The deployed contract
    function run() external returns (PrimeTime erc721) {
        vm.startBroadcast();
        Renderer r = new Renderer();
        erc721 = new PrimeTime("PrimeTime", "PT");
        erc721.setRenderer(address(r));
        vm.stopBroadcast();
    }
}
