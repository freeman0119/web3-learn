// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

// 任何人都可以发送金额到合约
// 只有 owner 可以取款
// 3 种取钱方式

contract EtherWallet {
    address payable public immutable owner;

    event Log(string fundName, address from, uint256 value, bytes data);

    constructor() {
        owner = payable(msg.sender);
    }

    receive() external payable {
        emit Log("receive", msg.sender, msg.value, "");
    }

    function withdraw1() external {
        require(msg.sender == owner, "not owner");
        payable(msg.sender).transfer(100);
    }

    function widthdraw2() external {
        require(msg.sender == owner, "not owner");
        bool success = payable(msg.sender).send(200);
        require(success, "send failed");
    }

    function withdraw3() external {
        require(msg.sender == owner, "not owner");
        (bool success,) = msg.sender.call{value: address(this).balance}("");
        require(success, "call failed");
    }
}