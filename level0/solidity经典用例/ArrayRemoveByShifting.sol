// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract ArrayRemoveByShifting {
  uint256[] public arr;

  function remove(uint256 _index) public {
    require(_index < arr.length, "Index out of bounds");

    for(uint256 i = _index; i < arr.length - 1; i++) {
      arr[i] = arr[i + 1];
    }
    arr.pop();
  }
}