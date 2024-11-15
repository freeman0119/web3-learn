// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract X {
  string public name;

  constructor(string memory _name) {
    name = _name;
  }
}

contract Y {
  string public text;

  constructor(string memory _text) {
    text = _text;
  }
}

contract B is X("Input to X"), Y("Input to Y") {}

contract C is X, Y {
  constructor(string memory _name, string memory _text) X(_name) Y(_text) {}
}

contract D is X, Y {
  constructor() X("x was called") Y("y was called") {}
}