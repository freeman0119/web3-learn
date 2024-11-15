// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./StructDeclaration.sol";

contract Todos {

  Todo[] public todos;

  function create(string calldata _text) public {
    todos.push(Todo(_text, false));
    todos.push(Todo({text: _text, completed: false}));

    Todo memory todo;
    todo.text = _text;

    todos.push(todo);
  }

  function get(uint256 _index) public view returns (string memory text, bool completed) {
    Todo storage todo = todos[_index];
    return (todo.text, todo.completed);
  }

  function updateText(uint256 _index, string calldata _text) public {
    Todo storage todo = todos[_index];
    todo.text = _text;
  }

  function toggleCompleted(uint256 _index) public {
    Todo storage todo = todos[_index];
    todo.completed = !todo.completed;
  }
}