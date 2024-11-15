// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract DataLocations {
  uint256[] public arr;
  mapping(uint256 => address) map;

  struct MyStruct {
    uint256 foo;
  }

  mapping(uint256 => MyStruct) myStructs;

  function f() public {
    _f(arr, map, myStructs[1]);
  }

  function _f(uint256[] storage _arr, mapping(uint => address) storage _map, MyStruct storage _myStruct) internal {
    // do something
  }
}