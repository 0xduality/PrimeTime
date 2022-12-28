// SPDX-License-Identifier: AGPL-3.0
interface IRenderer {
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
    ) external view returns (string memory);
}
