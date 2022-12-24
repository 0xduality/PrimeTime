// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.16;

import "forge-std/Test.sol";
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

    function testmodExp() public {
        require(nft.modExp(2, 3, 1) == 0);
        require(nft.modExp(2, 3, 2) == 0);
        require(nft.modExp(2, 3, 3) == 2);
        require(nft.modExp(2, 3, 4) == 0);
        require(nft.modExp(2, 3, 5) == 3);
        require(nft.modExp(2, 3, 6) == 2);
        require(nft.modExp(2, 3, 7) == 1);
        require(nft.modExp(2, 3, 8) == 0);
        require(nft.modExp(2, 3, 9) == 8);
        require(nft.modExp(3, 3, 1) == 0);
        require(nft.modExp(3, 3, 2) == 1);
        require(nft.modExp(3, 3, 3) == 0);
        require(nft.modExp(3, 3, 4) == 3);
        require(nft.modExp(3, 3, 5) == 2);
        require(nft.modExp(3, 3, 6) == 3);
        require(nft.modExp(3, 3, 7) == 6);
        require(nft.modExp(3, 3, 8) == 3);
        require(nft.modExp(3, 3, 9) == 0);
    }

    function testprime() public {
        require(nft.isPrime(3));
        require(nft.isPrime(5));
        require(nft.isPrime(7));
        require(nft.isPrime(11));
        require(nft.isPrime(13));
        require(nft.isPrime(17));
        require(nft.isPrime(19));
        require(nft.isPrime(23));
        require(nft.isPrime(29));
        require(nft.isPrime(31));
        require(nft.isPrime(37));
        require(nft.isPrime(41));
        require(nft.isPrime(43));
        require(nft.isPrime(47));
        require(nft.isPrime(53));
        require(nft.isPrime(59));
        require(nft.isPrime(61));
        require(nft.isPrime(67));
        for (uint256 i = 3; i < 30; i += 2) {
            for (uint256 j = 3; j < 30; j += 2) {
                require(!nft.isPrime(i * j));
            }
        }
    }

    function testone() public {
        require(!nft.isPrime(1663651523));
        require(nft.isPrime(1663651537));
    }

    function testHappyCase() public {}

    function testCivilFromDays() public view {
        int256 z0 = int256(1671858023) / int256(86400);
        for (int256 z = z0; z < z0 + 100; z++) {
            (int256 y, uint256 m, uint256 d) = nft.civilFromDays(z);
            console.log(uint256(z + 1));
            console.log(uint256(y), m, d);
        }
    }
}
