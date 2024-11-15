// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract IfElse {
  function foo(uint256 x) public pure returns (uint256) {
    if (x < 10) {
      return 0;
    } else if (x < 20) {
      return 1;
    } else {
      return 2;
    }
  }
}