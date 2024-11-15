// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Counter {
  uint256 public count;

  function get() public view returns (uint256) {
    return count;
  }

  function inc() public {
    count += 1;
  }

  function dec() public {
    count -= 1;
  }
}