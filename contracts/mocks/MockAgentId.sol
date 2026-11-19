// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/// @notice Minimal ERC-721 used ONLY in tests to stand in for the real
///         Agent ID contract. Never deployed to mainnet.
contract MockAgentId is ERC721 {
    uint256 private _nextId;

    constructor() ERC721("Mock Agent ID", "MAI") {}

    function mint(address to) external returns (uint256 tokenId) {
        tokenId = _nextId;
        _nextId++;
        _mint(to, tokenId);
    }
}
