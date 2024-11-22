// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.25;

import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";

contract NFTSwap is IERC721Receiver {
    event List(
        address indexed seller, 
        address indexed nfgAddr, 
        uint256 indexed tokenId, 
        uint256 price
    );
    event Purchase(
        address indexed buyer, 
        address indexed nftAddr, 
        uint256 indexed  tokenId, 
        uint256 price
    );
    event Revoke(
        address indexed seller, 
        address indexed nftAddr, 
        uint256 indexed tokenId
    );
    event Update(
        address indexed seller, 
        address indexed nftAddr, 
        uint256 indexed tokenId, 
        uint256 price
    );
    event Received(
        address indexed operator,
        address indexed from,
        uint256 indexed toknerId,
        bytes data
    );

    struct Order {
        address owner;
        uint256 price;
    }

    mapping(address => mapping(uint256 => Order)) public nftList;

    // 在 NFTSwap 中，用户使用 ETH 购买 NFT。因此，合约需要实现 receive() 函数来接收 ETH。
    receive() external payable { }

    function list(address _nftAddr, uint256 _tokenId, uint256 _price) public {
        IERC721 _nft = IERC721(_nftAddr);
        require(_nft.getApproved(_tokenId) == address(this));
        require(_price > 0);

        Order storage _order = nftList[_nftAddr][_tokenId];
        _order.owner = msg.sender;
        _order.price = _price;

        _nft.safeTransferFrom(msg.sender, address(this), _tokenId);

        emit List(msg.sender, _nftAddr, _tokenId, _price);
    }

    function purchase(address _nftAddr, uint256 _tokenId) public payable {
        Order storage _order = nftList[_nftAddr][_tokenId];
        require(msg.value >= _order.price);
        require(_order.price > 0);

        IERC721 _nft = IERC721(_nftAddr);
        require(_nft.ownerOf(_tokenId) == address(this));

        _nft.safeTransferFrom(address(this), msg.sender, _tokenId);

        payable(_order.owner).transfer(_order.price);
        payable(msg.sender).transfer(msg.value - _order.price);

        delete nftList[_nftAddr][_tokenId];

        emit Purchase(msg.sender, _nftAddr, _tokenId, _order.price);
    }

    function revoke(address _nftAddr, uint256 _tokenId) public {
        Order storage _order = nftList[_nftAddr][_tokenId];
        require(_order.owner == msg.sender);
        IERC721 _nft = IERC721(_nftAddr);
        require(_nft.ownerOf(_tokenId) == address(this));

        _nft.safeTransferFrom(address(this), msg.sender, _tokenId);

        delete nftList[_nftAddr][_tokenId];

        emit Revoke(msg.sender, _nftAddr, _tokenId);
    }

    function update(address _nftAddr, uint256 _tokenId, uint256 _price) public {
        require(_price > 0);
        Order storage _order = nftList[_nftAddr][_tokenId];
        require(_order.owner == msg.sender);
        IERC721 _nft = IERC721(_nftAddr);
        require(_nft.ownerOf(_tokenId) == address(this));

        _order.price = _price;

        emit Update(msg.sender, _nftAddr, _tokenId, _price);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns(bytes4){
        emit Received(operator, from, tokenId, data);
        return IERC721Receiver.onERC721Received.selector;
    }
}