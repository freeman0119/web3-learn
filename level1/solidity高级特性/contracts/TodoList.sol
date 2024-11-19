// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

// TodoList: 是类似便签一样功能的东西，记录我们需要做的事情，以及完成状态。

// 创建任务
// 修改任务名称
// 任务名写错的时候
// 修改完成状态：
// 手动指定完成或者未完成
// 自动切换
// 如果未完成状态下，改为完成
// 如果完成状态，改为未完成

contract TodoList {
    struct Todo {
        string name;
        bool isCompleted;
    }

    Todo[] public list;

    function create(string memory _name) external {
        list.push(Todo({name: _name, isCompleted: false}));
    }

    function modiName1(uint256 _index, string memory _name) external {
        // 方法1: 直接修改，修改一个属性时候比较省 gas
        list[_index].name = _name;
    }

    function modiName2(uint256 _index, string memory _name) external {
        // 方法2: 先获取储存到 storage，在修改多个属性的时候比较省 gas
        Todo storage temp = list[_index];
        temp.name = _name;
    }

    function modiStatus1(uint256 _index, bool _status) external {
        list[_index].isCompleted = _status;
    }

    function modiStatus2(uint _index) external {
        list[_index].isCompleted = !list[_index].isCompleted;
    }

    function get1(uint256 _index) external view returns (string memory _name, bool _status) {
        Todo memory temp = list[_index];
        return (temp.name, temp.isCompleted);
    }

    // 预期：get2 的 gas 费用比较低（相对 get1）
    function get2(uint256 _index) external  view returns (string memory _name, bool _status) {
        Todo storage temp = list[_index];
        return (temp.name, temp.isCompleted);
    }
}