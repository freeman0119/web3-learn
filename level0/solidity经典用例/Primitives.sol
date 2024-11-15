// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Primitives {
  bool public boo = true;

  uint8 public u8 = 1;
  uint256 public u256 = 123;

  int8 public i8 = -1;
  int256 public i256 = 123;
  int256 public i = -123;

  int256 public minInt = type(int256).min;
  int256 public maxInt = type(int256).max;

  bytes1 a = 0x56;

  bool public defaultBoo; // false
  uint256 public defaultUint; // 0
  int256 public defaultInt; // 0
  address public defaultAddress; // 0x0000000000000000000000000000000000000
}