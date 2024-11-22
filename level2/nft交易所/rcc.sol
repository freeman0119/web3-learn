// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract RCCApe is ERC721 {
    uint256 public MAX_APES = 10000;
    constructor(string memory name, string memory symbol) ERC721(name, symbol) {

    }

    function _baseURI() internal  pure override returns (string memory) {
        return "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/";
    }

    function mint(address to, uint256 tokenId) public  {
        require(tokenId >= 0 && tokenId <= MAX_APES);
        _mint(to, tokenId);
    }
}