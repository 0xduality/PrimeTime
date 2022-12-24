// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.16;

import "forge-std/Test.sol";
import "../src/PrimeTime.sol";
import "../src/IPrimeTimeErrors.sol";
import "@solbase/utils/LibString.sol";
import {Owned} from "@solbase/auth/Owned.sol";

contract PrimeTimeTest is Test, IPrimeTimeErrors {
    using LibString for uint256;

    PrimeTime public nft;
    address deployer;

    function setUp() public {
        nft = new PrimeTime("PrimeTime", "PT");
        deployer = tx.origin;
    }

    function testHappyCase() public {
    }
}
