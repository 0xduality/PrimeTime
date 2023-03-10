// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.16;

/// @title Custom errors
interface IPrimeTimeErrors {
    error PrimeTimeEndedError();
    error BelowMintPriceError();
    error AlreadyMintedError();
    error TokenDoesNotExist();
    error NotEOAError();
}
