//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Base64} from "@solbase/utils/Base64.sol";
import {LibString} from "@solbase/utils/LibString.sol";

/// @title On-chain renderer
contract Renderer {
    using LibString for uint256;

    constructor() {}

    function t(uint8 x) internal pure returns (string memory) {
        return (x < 10) ? string(abi.encodePacked("0", uint256(x).toString())) : uint256(x).toString();
    }

    function s(uint256 i) internal pure returns (string memory) {
        return i == 1 ? "true" : "false";
    }

    function jsonifyTraits(uint256 primeTraits) internal pure returns (string memory) {
        return string(
            abi.encodePacked(
                '"attributes": [{"trait_type": "Prime second", "value":"',
                s(primeTraits & 1),
                '"},',
                '{"trait_type": "Prime minute", "value":"',
                s((primeTraits >> 1) & 1),
                '"},',
                '{"trait_type": "Prime hour", "value":"',
                s((primeTraits >> 2) & 1),
                '"},',
                '{"trait_type": "Prime day", "value":"',
                s((primeTraits >> 3) & 1),
                '"},',
                '{"trait_type": "Prime month", "value":"',
                s((primeTraits >> 4) & 1),
                '"},',
                '{"trait_type": "Prime year", "value":"',
                s((primeTraits >> 5) & 1),
                '"},',
                '{"trait_type": "Prime unix timestamp", "value":"',
                s((primeTraits >> 6) & 1),
                '"}]}'
            )
        );
    }

    function tokenURI(
        uint256 tokenId,
        uint256 primeTraits,
        uint32 timestamp,
        uint16 year,
        uint8 month,
        uint8 day,
        uint8 hour,
        uint8 minute,
        uint8 second
    ) external pure returns (string memory svgString) {
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    abi.encodePacked(
                        "{" '"name": "PrimeTime",',
                        '"description": "A fully on-chain NFT where traits are based on the primality of the mint time",'
                        '"image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(getSVG(tokenId, timestamp, year, month, day, hour, minute, second))),
                        '",',
                        jsonifyTraits(primeTraits)
                    )
                )
            )
        );
    }

    function getWeekdayName(uint32 timestamp) internal pure returns (string memory) {
        uint32 daysSinceEpoch = timestamp / 86400;
        uint32 weekday = (daysSinceEpoch + 4) % 7;
        if (weekday < 4) {
            if (weekday < 2) {
                if (weekday == 0) {
                    return "Sunday";
                } // weekday == 1
                else {
                    return "Monday";
                }
            } else {
                // 2 3
                if (weekday == 2) {
                    return "Tuesday";
                } // == 3
                else {
                    return "Wednesday";
                }
            }
        } else {
            if (weekday == 4) {
                return "Thursday";
            } else if (weekday == 5) {
                return "Friday";
            } // == 6
            else {
                return "Saturday";
            }
        }
    }

    function getMonthName(uint8 month) internal pure returns (string memory) {
        if (month < 7) {
            if (month < 4) {
                if (month == 1) {
                    return "January";
                } else if (month == 2) {
                    return "February";
                } else {
                    return "March";
                }
            } else {
                if (month == 4) {
                    return "April";
                } else if (month == 5) {
                    return "May";
                } else {
                    return "June";
                }
            }
        } else {
            if (month < 10) {
                if (month == 7) {
                    return "July";
                } else if (month == 8) {
                    return "August";
                } else {
                    return "September";
                }
            } else {
                if (month == 10) {
                    return "October";
                } else if (month == 11) {
                    return "November";
                } else {
                    return "December";
                }
            }
        }
    }

    function getOrdinalSuffix(uint8 day) internal pure returns (string memory) {
        if (day == 11 || day == 12) {
            return "th";
        }
        uint8 d = day % 10;
        if (d == 1) {
            return "st";
        } else if (d == 2) {
            return "nd";
        } else if (d == 3) {
            return "rd";
        } else {
            return "th";
        }
    }

    // construct image
    function getSVG(
        uint256 tokenId,
        uint32 timestamp,
        uint16 year,
        uint8 month,
        uint8 day,
        uint8 hour,
        uint8 minute,
        uint8 second
    ) internal pure returns (string memory svgString) {
        string memory date = string(
            abi.encodePacked(
                getWeekdayName(timestamp), ", ", getMonthName(month), " ", uint256(day).toString(), getOrdinalSuffix(day), " ", uint256(year).toString()
            )
        );
        string memory secondsHandRot = (6 * uint256(second)).toString();
        uint256 rotx10 = 60 * uint256(minute) + uint256(second);
        string memory minutesHandRot = string(abi.encodePacked((rotx10 / 10).toString(), ".", (rotx10 % 10).toString()));
        rotx10 = 300 * (uint256(hour) % 12) + uint256(minute) * 5;
        string memory hoursHandRot = string(abi.encodePacked((rotx10 / 10).toString(), ".", (rotx10 % 10).toString()));
        //string memory iso = string(
        //    abi.encodePacked(
        //        uint256(year).toString(), "-", t(month), "-", t(day), "T", t(hour), ":", t(minute), ":", t(second), "Z"
        //    )
        //);
        rotx10 = (timestamp / 3600) % 360;

        svgString = string(
            abi.encodePacked(
                "<?xml version='1.0' encoding='UTF-8'?>"
                "<svg xmlns:xlink='http://www.w3.org/1999/xlink' xmlns:svg='http://www.w3.org/2000/svg' xmlns='http://www.w3.org/2000/svg' width='100%' height='100%' viewBox='-100 -150 250 300'>"
                "<style>"
                ".txt { fill: navy; overflow: hidden; font-weight: bold; font-family: Arial, Helvetica, sans-serif; text-shadow: 1px 1px 1px black, 2px 2px 1px grey;}"
                "</style>" "<defs>" "<circle cx='0' cy='87' r='2.2' fill='black' id='minMarker'/>"
                "<line x1='0' y1='95' x2='0' y2='78' stroke-width='3.8' stroke='black' id='hourMarker'/>"
                "<linearGradient id='a' gradientUnits='userSpaceOnUse' x1='-100' x2='-100' y1='-150' y2='100%' gradientTransform='rotate(240)'>"
                "<stop offset='0'  stop-color='#ffffff'/>" "<stop offset='1'  stop-color='hsl(",
                rotx10.toString(),
                ", 100%, 63%)'/></linearGradient></defs>"
                "<rect x='-100' y='-150' fill='url(#a)' width='100%' height='100%'/>"
                "<g id='clock' transform='translate(25,0)'>" "<g id='markerSet'>" "<use xlink:href='#hourMarker'/>"
                "<use xlink:href='#minMarker' transform='rotate( 6)'/>"
                "<use xlink:href='#minMarker' transform='rotate(12)'/>"
                "<use xlink:href='#minMarker' transform='rotate(18)'/>"
                "<use xlink:href='#minMarker' transform='rotate(24)'/></g>"
                "<use xlink:href='#markerSet' transform='rotate( 30)'/>"
                "<use xlink:href='#markerSet' transform='rotate( 60)'/>"
                "<use xlink:href='#markerSet' transform='rotate( 90)'/>"
                "<use xlink:href='#markerSet' transform='rotate(120)'/>"
                "<use xlink:href='#markerSet' transform='rotate(150)'/>"
                "<use xlink:href='#markerSet' transform='rotate(180)'/>"
                "<use xlink:href='#markerSet' transform='rotate(210)'/>"
                "<use xlink:href='#markerSet' transform='rotate(240)'/>"
                "<use xlink:href='#markerSet' transform='rotate(270)'/>"
                "<use xlink:href='#markerSet' transform='rotate(300)'/>"
                "<use xlink:href='#markerSet' transform='rotate(330)'/>"
                "<line x1='0' y1='-65' x2='0' y2='0' stroke-width='1.7'  stroke='black' transform='rotate(",
                secondsHandRot,
                ")'/><line x1='0' y1='-83' x2='0' y2='0' stroke-width='2.8'  stroke='black' transform='rotate(",
                minutesHandRot,
                ")'/><line x1='0' y1='-51' x2='0' y2='0' stroke-width='4.53' stroke='black' transform='rotate(",
                hoursHandRot,
                ")'/><circle cx='0' cy='0' r='9' fill='black'/></g><text x='-90' y='-120' class='txt'>",
                date,
//                "</text><text x='-90' y='130' class='txt'>#",
//                tokenId.toString(),
 //               "</text><text x='55' y='130' class='txt'>",
//                uint256(timestamp).toString(),
                "</text></svg>"
            )
        );
    }
}
