// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Variables {
  string public text = "Hello";
  uint256 public num = 123;

  function doSomething() public {
    uint i = 456;
    uint256 timestamp = block.timestamp;
    address sender = msg.sender;
  }
}