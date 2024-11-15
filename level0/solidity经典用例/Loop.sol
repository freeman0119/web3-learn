// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Loop {
  function loop() public {
    for (uint256 i = 0; i < 10; i++) {
      if (i == 3) {
        continue;
      }
      if (i == 5) {
        break;
      }
    }
  }
}