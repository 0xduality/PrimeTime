// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.16;

import {Owned} from "@solbase/auth/Owned.sol";
import {ReentrancyGuard} from "@solbase/utils/ReentrancyGuard.sol";
import "@solbase/utils/SafeTransferLib.sol";
import "@solbase/utils/LibString.sol";
import {ERC721} from "./ERC721.sol";
import {IPrimeTimeErrors} from "./IPrimeTimeErrors.sol";
import {IRenderer} from "./IRenderer.sol";

// Simplified version of BotThis where every wallet can only bid on one NFT
contract PrimeTime is Owned(tx.origin), ReentrancyGuard, ERC721, IPrimeTimeErrors {
    using SafeTransferLib for address;
    using LibString for uint256;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event NewPrice(uint256 price);
    event NewRenderer(address r);
    event AllowMultiple(bool enabled);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    struct DateTime {
        uint16 year;
        uint8 month;
        uint8 day;
        uint8 hour;
        uint8 minute;
        uint8 second;
    }

    address public renderer;
    bool public allowMultiple;
    uint256 public mintPrice;
    mapping(uint32 => bool) public minted;
    uint40[] public dataOf;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        mintPrice = 0.1 ether;
        emit NewPrice(mintPrice);
    }

    function mint() external payable nonReentrant {
        if (msg.sender != tx.origin)
            revert NotEOAError();
        if (msg.value < mintPrice) {
            revert BelowMintPriceError();
        }
        if (block.timestamp > type(uint32).max) {
            revert PrimeTimeEndedError();
        }
        uint32 timestamp = uint32(block.timestamp);
        if (!allowMultiple && minted[timestamp]) {
            revert AlreadyMintedError();
        }
        minted[timestamp] = true;
        uint32 tokenId = uint32(dataOf.length);
        DateTime memory dt = _dateTimeFromTimestamp(timestamp);
        uint8 traits = _primeTraits(timestamp, dt);
        uint40 value = timestamp;
        value = (value << 8) | traits;
        dataOf.push(value);
        _safeMint(msg.sender, tokenId);
    }

    function setMintPrice(uint256 price) external onlyOwner {
        mintPrice = price;
        emit NewPrice(price);
    }

    function toggleAllowMultiple() external onlyOwner {
        bool newValue = !allowMultiple;
        allowMultiple = newValue;
        emit AllowMultiple(newValue);
    }

    function withdraw() external onlyOwner {
        msg.sender.safeTransferETH(address(this).balance);
    }

    function setRenderer(address rendererContract) external onlyOwner {
        renderer = rendererContract;
        emit NewRenderer(rendererContract);
    }

    function _isPrime(uint256 n) internal view returns (bool) {
        if (n < 2) {
            return false;
        }
        if (n == 2) {
            return true;
        }
        if (n >= 4759123141) {
            revert PrimeTimeEndedError();
        }
        if (n % 2 == 0) {
            return false;
        }
        uint256 s = 0;
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

    function _modExp(uint256 _b, uint256 _e, uint256 _m) internal view returns (uint256 result) {
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
            let value := add(pointer, 0xc0)

            // Call the precompiled contract 0x05 = bigModExp
            if iszero(staticcall(gas(), 0x05, pointer, 0xc0, value, 0x20)) { revert(0, 0) }

            result := mload(value)
        }
    }

    function _civilFromDays(uint256 z) internal pure returns (uint16 y, uint8 m, uint8 d) {
        z += 719468;
        uint256 era = z / 146097;
        uint256 doe = z - era * 146097; // [0, 146096]
        uint256 yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365; // [0, 399]
        y = uint16(yoe + era * 400);
        uint256 doy = doe - (365 * yoe + yoe / 4 - yoe / 100); // [0, 365]
        uint256 mp = (5 * doy + 2) / 153; // [0, 11]
        d = uint8(doy - (153 * mp + 2) / 5 + 1); // [1, 31]
        if (mp < 10) {
            m = uint8(mp + 3);
        } else {
            m = uint8(mp - 9);
        }
        y = m <= 2 ? y + 1 : y;
    }

    function _dateTimeFromTimestamp(uint256 timestamp) internal pure returns (DateTime memory datetime) {
        (uint16 year, uint8 month, uint8 day) = _civilFromDays(timestamp / 86400);
        datetime.year = year;
        datetime.month = month;
        datetime.day = day;
        uint256 secondsFromMidnight = timestamp % 86400;
        datetime.second = uint8(secondsFromMidnight % 60);
        datetime.minute = uint8((secondsFromMidnight / 60) % 60);
        datetime.hour = uint8(secondsFromMidnight / 3600);
    }

    function dateTimeFromTimestamp(uint256 timestamp) external pure returns (DateTime memory datetime) {
        return _dateTimeFromTimestamp(timestamp);
    }

    function _primeTraits(uint32 timestamp, DateTime memory dt) internal view returns (uint8 traits) {
        traits = (_isPrime(timestamp) ? 1 : 0);
        traits = (traits << 1) | (_isPrime(dt.year) ? 1 : 0);
        traits = (traits << 1) | (_isPrime(dt.month) ? 1 : 0);
        traits = (traits << 1) | (_isPrime(dt.day) ? 1 : 0);
        traits = (traits << 1) | (_isPrime(dt.hour) ? 1 : 0);
        traits = (traits << 1) | (_isPrime(dt.minute) ? 1 : 0);
        traits = (traits << 1) | (_isPrime(dt.second) ? 1 : 0);
    }

    function isPrime(uint256 n) external view returns (bool) {
        return _isPrime(n);
    }

    function modExp(uint256 _b, uint256 _e, uint256 _m) external view returns (uint256 result) {
        return _modExp(_b, _e, _m);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (tokenId >= dataOf.length) {
            revert TokenDoesNotExist();
        }

        if (renderer == address(0)) {
            return "";
        }
        uint40 data = dataOf[tokenId];
        uint32 timestamp = uint32(data >> 8);
        uint256 traits = data & 0xff;

        DateTime memory datetime = _dateTimeFromTimestamp(uint256(timestamp));
        return IRenderer(renderer).tokenURI(
            tokenId,
            traits,
            timestamp,
            datetime.year,
            datetime.month,
            datetime.day,
            datetime.hour,
            datetime.minute,
            datetime.second
        );
    }
}
