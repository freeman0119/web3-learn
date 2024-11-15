// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Immutable {
  address public immutable MY_ADDRESS;
  uint256 public immutable MY_UINT256;

  constructor(uint256 _myUint) {
    MY_ADDRESS = msg.sender;
    MY_UINT256 = _myUint;
  }
}