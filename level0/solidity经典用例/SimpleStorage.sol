// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract SimpleStorage {
  uint256 public num;

  function set(uint256 _num) public {
    num = _num;
  }

  function get() public view returns (uint256) {
    return num;
  }
}