// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.25;

// 功能需求
// 1.代币基本信息：
//  代币名称
//  代币符号
//  代币小数点位数
//  代币总供应量

// 2.账户余额查询：
//  查询指定地址的代币余额。
// 3.授权机制：
//  允许用户授权第三方账户代表自己支配一定数量的代币。
// 4.转账功能：
//  从一个地址向另一个地址转移代币。
//  从一个地址向另一个地址转移代币（需要事先授权）。
// 5.代币增发和销毁：
//  代币增发：合约所有者可以增加代币供应量。
//  代币销毁：合约所有者可以销毁一定数量的代币。
// 6.事件通知：
//  转账事件：当代币转移时触发。
//  授权事件：当授权额度变化时触发。

contract MyToken {
    string private _name;
    string private _symbol;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balance;
    mapping(address => mapping(address => uint256)) private _allowances;

    address public owner;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    constructor() {
        _name = "Bitcoin";
        _symbol = "BTC";
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not the owner");
        _;
    }

    function name() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balance[account];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approval(address spender, uint256 amount) public {
        _allowances[msg.sender][spender] += amount;
        emit Approval(msg.sender, spender, amount);
    }

    function transfer(address to, uint256 amount) public {
        require(_balance[msg.sender] >= amount, "balance is not enough");
        _balance[msg.sender] -= amount;
        _balance[to] += amount;
        emit Transfer(msg.sender, to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public {
        uint256 _allowance = _allowances[from][msg.sender];
        require(_allowance >= amount, "");
        require(_balance[from] >= amount, "");

        _balance[from] -= amount;
        _balance[to] += amount;
        _allowances[from][msg.sender] -= amount;

        emit Transfer(from, to, amount);
    }

    function mint(address account, uint256 amount) public onlyOwner {
        _balance[account] += amount;
        _totalSupply += amount;
        emit Transfer(address(0), account, amount);
    }

    function burn(address account, uint256 amount) public onlyOwner {
        require(_balance[account] >= amount, "");
        _balance[account] -= amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }
}
