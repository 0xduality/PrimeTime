// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.16;

import "forge-std/Test.sol";
import "forge-std/Test.sol";
import "../src/PrimeTime.sol";
import "../src/Renderer.sol";
import "../src/IPrimeTimeErrors.sol";
import "@solbase/utils/LibString.sol";
import {Owned} from "@solbase/auth/Owned.sol";

contract PrimeTimeTest is Test, IPrimeTimeErrors {
    using LibString for uint256;

    PrimeTime public nft;
    Renderer public renderer;
    address deployer;
    address alice;

    function setUp() public {
        string memory bidderName = "alice";
        alice = address(uint160(uint256(keccak256(bytes(bidderName)))));
        vm.label(alice, bidderName);
        vm.deal(alice, 10 ether);

        nft = new PrimeTime("PrimeTime", "PT");
        renderer = new Renderer();
        deployer = tx.origin;
        vm.prank(deployer);
        nft.setRenderer(address(renderer));
    }

    function testmodExp() public view {
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

    function testprime() public view {
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

    function testone() public view {
        require(!nft.isPrime(1663651523));
        require(nft.isPrime(1663651537));
    }

    function assertEqualDateTime(
        PrimeTime.DateTime memory dt,
        uint16 year,
        uint8 month,
        uint8 day,
        uint8 hour,
        uint8 minute,
        uint8 second
    ) internal pure {
        require(year == dt.year, "year :(");
        require(month == dt.month, "month :(");
        require(day == dt.day, "day :(");
        require(hour == dt.hour, "hour :(");
        require(minute == dt.minute, "minute :(");
        require(second == dt.second, "second :(");
    }

    function testDateTimeFromTimestamp() public {
        vm.warp(3981311999);
        PrimeTime.DateTime memory dt = nft.dateTimeFromTimestamp(block.timestamp);
        assertEqualDateTime(dt, 2096, 2, 28, 23, 59, 59);
        skip(1);
        dt = nft.dateTimeFromTimestamp(block.timestamp);
        assertEqualDateTime(dt, 2096, 2, 29, 0, 0, 0);
        vm.warp(4012934399);
        dt = nft.dateTimeFromTimestamp(block.timestamp);
        assertEqualDateTime(dt, 2097, 2, 28, 23, 59, 59);
        skip(1);
        dt = nft.dateTimeFromTimestamp(block.timestamp);
        assertEqualDateTime(dt, 2097, 3, 1, 0, 0, 0);
        vm.warp(4107542399);
        dt = nft.dateTimeFromTimestamp(block.timestamp);
        assertEqualDateTime(dt, 2100, 2, 28, 23, 59, 59);
        skip(1);
        dt = nft.dateTimeFromTimestamp(block.timestamp);
        assertEqualDateTime(dt, 2100, 3, 1, 0, 0, 0);
    }

    function testHappyCase() public {
        vm.warp(1825974673);
        vm.prank(alice, alice);
        nft.mint{value: 0.1 ether}();
        skip(3600);
        vm.prank(alice, alice);
        nft.mint{value: 0.1 ether}();
        skip(3600);
        vm.prank(alice, alice);
        nft.mint{value: 0.1 ether}();
        console.log(nft.tokenURI(0));
        console.log(nft.tokenURI(1));
        console.log(nft.tokenURI(2));
    }

    function testRandomMintTime() public {
        bytes32 state = keccak256("foo");
        for(uint i=0; i < 99; ++i){
            uint32 time = uint32(bytes4(state));
            vm.warp(time);
            vm.prank(alice, alice);
            nft.mint{value: 0.1 ether}();
            console.log(nft.tokenURI(i));
            state = keccak256(abi.encode(state));
        }
    }

    function testNonEOA() public {
        vm.prank(alice);
        vm.expectRevert(NotEOAError.selector);
        nft.mint{value: 0.1 ether}();
    }

    function testBelowMintPrice() public {
        vm.prank(alice, alice);
        vm.expectRevert(BelowMintPriceError.selector);
        nft.mint{value: 0.09 ether}();
    }

    function testEndOfTime() public {
        uint256 cusp = type(uint32).max;
        vm.warp(cusp + 1);
        vm.prank(alice, alice);
        vm.expectRevert(PrimeTimeEndedError.selector);
        nft.mint{value: 0.1 ether}();
    }

    function testUnique() public {
        vm.prank(alice, alice);
        nft.mint{value: 0.1 ether}();
        vm.prank(alice, alice);
        vm.expectRevert(AlreadyMintedError.selector);
        nft.mint{value: 0.1 ether}();
    }

    function testNonExistentToken() public {
        vm.prank(alice, alice);
        nft.mint{value: 0.1 ether}();
        vm.expectRevert(TokenDoesNotExist.selector);
        string memory uri = nft.tokenURI(420);
    }

    function testSetPrice() public {
        vm.prank(deployer);
        nft.setMintPrice(0.5 ether);
        vm.prank(alice, alice);
        vm.expectRevert(BelowMintPriceError.selector);
        nft.mint{value: 0.49 ether}();
        vm.prank(alice, alice);
        nft.mint{value: 0.5 ether}();
        uint b = deployer.balance;
        vm.prank(deployer);
        nft.withdraw();
        require(b+0.5 ether == deployer.balance, ":(");
    }

    function testSetRemderer() public {
        vm.prank(alice, alice);
        nft.mint{value: 0.1 ether}();
        address r = nft.renderer();
        string memory before = nft.tokenURI(0);
        vm.prank(deployer);
        nft.setRenderer(address(0));
        string memory mid = nft.tokenURI(0);
        vm.prank(deployer);
        nft.setRenderer(r);
        string memory restored = nft.tokenURI(0);
        require(bytes(mid).length == 0, ":|");
        require(keccak256(abi.encode(before)) == keccak256(abi.encode(restored)), ":(");
    }
}
