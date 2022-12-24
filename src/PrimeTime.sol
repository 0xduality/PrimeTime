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

    constructor(string memory _name, string memory _symbol) {
    }

    /// @notice Sets the token URI
    function setURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }
}
