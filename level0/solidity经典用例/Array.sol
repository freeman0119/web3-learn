// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Array {
  uint256[] public arr;
  uint256[] public arr2 = [1, 2, 3];
  uint256[10] public myFixedArray;

  function get(uint256 i) public view returns (uint256) {
    return arr[i];
  }

  function push(uint256 i) public {
    arr.push(i);
  }

  function pop() public {
    arr.pop();
  }

  function getLength() public view returns (uint256) {
    return arr.length;
  }

  function remove(uint256 index) public {
    delete arr[index];
  }

  function examples() external {
    uint256[] memory a = new uint256[](3);
  }
}