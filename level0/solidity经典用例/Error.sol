// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Error {
  function testRequire(uint256 _i) public pure {
    require(_i > 10, "Input must be greater than 10");
  }

  function testRevert(uint256 _i) public pure {
    if (_i <= 10) {
      revert("Input must be greater than 10");
    }
  }

  uint256 public num;

  function testAssert() public view {
    assert(num == 0);
  }

  error InsufficientBalance(uint256 balance, uint256 _withdrawAmount);
  function testCustomError(uint256 _withdrawAmount) public view {
    uint256 bal = address(this).balance;
    if (bal < _withdrawAmount) {
      revert InsufficientBalance({
        balance: bal,
        _withdrawAmount: _withdrawAmount
      });
    }
  }
}