// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.25;

contract MuliSigWallet {
    address[] public owners; // 多签持有人数组 
    mapping(address => bool) public isOwner; // 记录一个地址是否为多签持有人
    uint256 public ownerCount; // 多签持有人数量
    uint256 public threshold; // 多签执行门槛，交易至少有n个多签人签名才能被执行
    uint256 public nonce; // nonce，防止签名重放攻击

    constructor(address[] memory _owners, uint256 _threshold) {
        _setupOwners(_owners, _threshold);
    }

    function _setupOwners(address[] memory _owners, uint256 _threshold) internal  {
        require(threshold == 0, "already setted");
        require(_threshold <= _owners.length, "should less or equal the owners length");
        require(_threshold >= 1, "at least one");

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0) && owner != address(this) && !isOwner[owner]);
            owners.push(owner);
            isOwner[owner] = true;
        }

        ownerCount = _owners.length;
        threshold = _threshold;
    }

    function execTransaction(address to, uint256 value, bytes memory data, bytes memory signatures) public payable virtual returns(bool success) {
        bytes32 txHash = encodeTransactionData(to, value, data, nonce, block.chainid);
        nonce++;
        checkSignatures(txHash, signatures);
        (success,) = to.call{value: value}(data);
        require(success);
    }

    function checkSignatures(bytes32 dataHash, bytes memory signatures) public view {
        // 读取多签执行门槛
        uint256 _threshold = threshold;
        require(_threshold > 0);

        // 检查签名长度足够长
        require(signatures.length >= _threshold * 65);

        // 通过一个循环，检查收集的签名是否有效
        // 大概思路：
        // 1. 用ecdsa先验证签名是否有效
        // 2. 利用 currentOwner > lastOwner 确定签名来自不同多签（多签地址递增）
        // 3. 利用 isOwner[currentOwner] 确定签名者为多签持有人
        address lastOwner = address(0); 
        address currentOwner;
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 i;
        for (i = 0; i < _threshold; i++) {
            (v, r, s) = signatureSplit(signatures, i);
            // 利用ecrecover检查签名是否有效
            currentOwner = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash)), v, r, s);
            require(currentOwner > lastOwner && isOwner[currentOwner]);
            lastOwner = currentOwner;
        }
    }

    function signatureSplit(bytes memory signatures, uint256 pos) internal pure returns (uint8 v, bytes32 r, bytes32 s){
        // 签名的格式：{bytes32 r}{bytes32 s}{uint8 v}
        assembly {
            let signaturePos := mul(0x41, pos)
            r := mload(add(signatures, add(signaturePos, 0x20)))
            s := mload(add(signatures, add(signaturePos, 0x40)))
            v := and(mload(add(signatures, add(signaturePos, 0x41))), 0xff)
        }
    }

    function encodeTransactionData(address to, uint256 value, bytes memory data, uint256 _nonce, uint256 chainid) public pure returns (bytes32) {
        bytes32 safeTxHash =
            keccak256(
                abi.encode(
                    to,
                    value,
                    keccak256(data),
                    _nonce,
                    chainid
                )
            );
        return safeTxHash;
    }

    receive() external payable { }
}


