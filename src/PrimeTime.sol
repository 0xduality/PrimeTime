// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.16;

import {Owned} from "@solbase/auth/Owned.sol";
import {ReentrancyGuard} from "@solbase/utils/ReentrancyGuard.sol";
import "@solbase/utils/SafeTransferLib.sol";
import "@solbase/utils/LibString.sol";
import {ERC721} from "./ERC721.sol";
import {IPrimeTimeErrors} from "./IPrimeTimeErrors.sol";

import "forge-std/Test.sol";

// Simplified version of BotThis where every wallet can only bid on one NFT
contract PrimeTime is Owned(tx.origin), ReentrancyGuard, ERC721, IPrimeTimeErrors {
    using SafeTransferLib for address;
    using LibString for uint256;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string baseURI;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {}

    /// @notice Sets the token URI
    function setURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function isPrime(uint256 n) external returns (bool) {
        require(2 < n && n < 4759123141, "PrimeTime: ENDED");
        if (n % 2 == 0) {
            return false;
        }
        uint256 s;
        uint256 d = n - 1;
        while ((d & 1) == 0) {
            d >>= 1;
            s += 1;
        }
        // n = 2^s * d + 1, d odd
        uint256[] memory a = new uint256[](3);
        a[0] = 2;
        a[1] = 7;
        a[2] = 61;
        for (uint256 i = 0; i < 3; ++i) {
            if (a[i] >= n) {
                break;
            }
            uint256 x = _modExp(a[i], d, n);
            if (x == 1 || x == n - 1) {
                continue;
            }
            for (uint256 j = s - 1; j > 0; --j) {
                x = mulmod(x, x, n);
                if (x == n - 1) {
                    break;
                }
            }
            if (x == n - 1) {
                continue;
            }
            return false;
        }
        return true;
    }

    function modExp(uint256 _b, uint256 _e, uint256 _m) external returns (uint256 result) {
        return _modExp(_b, _e, _m);
    }

    function _modExp(uint256 _b, uint256 _e, uint256 _m) internal returns (uint256 result) {
        assembly {
            // Free memory pointer
            let pointer := mload(0x40)

            // Define length of base, exponent and modulus. 0x20 == 32 bytes
            mstore(pointer, 0x20)
            mstore(add(pointer, 0x20), 0x20)
            mstore(add(pointer, 0x40), 0x20)

            // Define variables base, exponent and modulus
            mstore(add(pointer, 0x60), _b)
            mstore(add(pointer, 0x80), _e)
            mstore(add(pointer, 0xa0), _m)

            // Store the result
            let value := mload(0xc0)

            // Call the precompiled contract 0x05 = bigModExp
            if iszero(call(not(0), 0x05, 0, pointer, 0xc0, value, 0x20)) { revert(0, 0) }

            result := mload(value)
        }
    }

    function civilFromDays(int256 z) external pure returns (int256 y, uint256 m, uint256 d) {
        return _civilFromDays(z);
    }

    function _civilFromDays(int256 z) internal pure returns (int256 y, uint256 m, uint256 d) {
        z += 719468;
        int256 era = (z >= 0 ? z : z - 146096) / 146097;
        uint256 doe = uint256(z - era * 146097); // [0, 146096]
        uint256 yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365; // [0, 399]
        y = int256(yoe) + era * 400;
        uint256 doy = doe - (365 * yoe + yoe / 4 - yoe / 100); // [0, 365]
        uint256 mp = (5 * doy + 2) / 153; // [0, 11]
        d = doy - (153 * mp + 2) / 5 + 1; // [1, 31]
        m = uint256(int256(mp) + (mp < 10 ? int256(3) : int256(-9))); // [1, 12]
        y = m <= 2 ? y + 1 : y;
    }
}
