//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Base64} from "@solbase/utils/Base64.sol";
import {LibString} from "@solbase/utils/LibString.sol";

/// @title On-chain renderer
contract Renderer {

    constructor() {}

    function s(uint256 i) internal pure returns (string memory)
    {
        return i == 1 ? "true" : "false"; 

    }

    function jsonifyTraits(uint256 primeTraits) internal pure returns (string memory)
    {
        return string(abi.encodePacked(
            '"attributes": [{"trait_type": "Prime unix timestamp", "value":"', s(primeTraits & 1), '"},',
                           '{"trait_type": "Prime year", "value":"', s((primeTraits>>1) & 1), '"},',
                           '{"trait_type": "Prime month", "value":"', s((primeTraits>>2) & 1), '"},',
                           '{"trait_type": "Prime day", "value":"', s((primeTraits>>3) & 1), '"},',
                           '{"trait_type": "Prime hour", "value":"', s((primeTraits>>4) & 1), '"},',
                           '{"trait_type": "Prime minute", "value":"', s((primeTraits>>5) & 1), '"},',
                           '{"trait_type": "Prime second", "value":"', s((primeTraits>>6) & 1), '"}]}'));
    }

    // we pass in tokenID even though we don't use it
    // in case we need it when we upgrade renderers
    function tokenURI(
        uint256 /* tokenId */, 
        uint256 primeTraits,
        uint32 timestamp,
        uint16 year,
        uint8 month,
        uint8 day,
        uint8 hour,
        uint8 minute,
        uint8 second
    ) external view returns (string memory svgString) {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            "{"
                            '"name": "PrimeTime",',
                            '"description": "A fully on-chain NFT where traits are based on the primality of the mint time",'
                            '"image": "data:image/svg+xml;base64,',
                            Base64.encode(bytes(getSVG(timestamp, year, month, day, hour, minute, second))),
                            '",',
                            jsonifyTraits(primeTraits)
                        )
                    )
                )
            );
    }

    // construct image
    function getSVG(uint32 timestamp,
        uint16 year,
        uint8 month,
        uint8 day,
        uint8 hour,
        uint8 minute,
        uint8 second)
        internal
        view
        returns (string memory svgString)
    {
        svgString = string(
            abi.encodePacked(
                "<svg xmlns='http://www.w3.org/2000/svg' width='256' height='256' viewBox='0 0 256 256' preserveAspectRatio='none'>"
                "<text x='50%' y='40%' dominant-baseline='middle' text-anchor='middle' class='title'>"
                "MINTED"
                "</text>"
                "<text x='50%' y='50%' dominant-baseline='middle' text-anchor='middle' class='title'>"
                "AT"
                "</text>"
                "</svg>"
            )
        );
    }
}