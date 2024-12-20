// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract ArrayRemoveByShifting {
  uint256[] public arr;

  function remove(uint256 _index) public {
    arr[_index] = arr[arr.length - 1];
    arr.pop();
  }
}