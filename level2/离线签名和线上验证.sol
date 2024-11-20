// SPDX-License-Identifier: MIT 
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

// 用signer对应的私钥，对account和tokenId加密，链下给需要发比的账户
// 需要发布的账户调用mint，传入account和tokenId，和第一步生成的加密结果，也就是_signature
// mint函数收到后，会对account和tokenId加密处理，然后将hash结果和_signature传入vertify
// vertify会调用ECDSA的recover方法，计算出第一步加密中用到的私钥对应的公钥，也就是signer本身
// 如果相等，说明这个account可以铸造tokenId

pragma solidity ^0.8.25;
contract SignatureNFT is ERC721 {
    address immutable public signer; // 签名地址
    mapping(address => bool) public mintedAddress;   // 记录已经mint的地址

    // 构造函数，初始化NFT合集的名称、代号、签名地址
    constructor(string memory _name, string memory _symbol, address _signer) ERC721(_name, _symbol) {
        signer = _signer;
    }

    // 利用ECDSA验证签名并mint
    function mint(address _account, uint256 _tokenId, bytes memory _signature) external
    {
        bytes32 _msgHash = getMessageHash(_account, _tokenId); // 将_account和_tokenId打包消息
        bytes32 _ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(_msgHash);

        require(verify(_ethSignedMessageHash, _signature), "Invalid signature"); // ECDSA检验通过
        require(!mintedAddress[_account], "Already minted!"); // 地址没有mint过
        _mint(_account, _tokenId); // mint
        mintedAddress[_account] = true; // 记录mint过的地址
    }

    /*
     * 将mint地址（address类型）和tokenId（uint256类型）拼成消息msgHash
     * _account: 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
     * _tokenId: 0
     * 对应的消息: 0x1bf2c0ce4546651a1a2feb457b39d891a6b83931cc2454434f39961345ac378c
     */
    function getMessageHash(address _account, uint256 _tokenId) public pure returns(bytes32){
        return keccak256(abi.encodePacked(_account, _tokenId));
    }

   // ECDSA验证，调用ECDSA库的verify()函数
    function verify(bytes32 _msgHash, bytes memory _signature) public view returns (bool){
        address recovered = ECDSA.recover(_msgHash, _signature);
        return recovered == signer;
    }
}