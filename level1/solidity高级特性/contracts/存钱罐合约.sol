// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

// 所有人都可以存钱
// ETH
// 只有合约 owner 才可以取钱
// 只要取钱，合约就销毁掉 selfdestruct

contract Bank {
    address immutable owner;

    event Deposit(address _addr, uint256 _amount);
    event WithDraw(uint256 _amount);

    constructor() {
        owner = msg.sender;
    }

    receive() external payable { 
        emit Deposit(msg.sender, msg.value);
    }

    function withDraw() external {
        require(msg.sender == owner, "Not owner");
        emit WithDraw(address(this).balance);
        selfdestruct(payable(msg.sender));
    }
}