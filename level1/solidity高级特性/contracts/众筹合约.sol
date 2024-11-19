// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

// 众筹合约分为两种角色：一个是受益人，一个是资助者。

// 两种角色:
//      受益人   beneficiary => address         => address 类型
//      资助者   funders     => address:amount  => mapping 类型 或者 struct 类型

// 状态变量按照众筹的业务：
// 状态变量
//      筹资目标数量    fundingGoal
//      当前募集数量    fundingAmount
//      资助者列表      funders
//      资助者人数      fundersKey

// 需要部署时候传入的数据:
//      受益人
//      筹资目标数量

contract CrowdFund {
    address public immutable beneficiary;
    uint256 public immutable fundingGoal;
    uint256 public fundingAmount;
    mapping(address => uint256) public funders;
    mapping(address => bool) private fundersInserted;
    address[] public fundersKey;

    bool public available = true;

    // 部署时，设置受益人，和金额
    constructor(address _beneficiary, uint256 _goal){
        beneficiary = _beneficiary;
        fundingGoal = _goal;
    }

    function contrubute() external payable {
        require(available, "crowdfund is closed");

        uint256 potentialFundingAmount = fundingAmount + msg.value;
        uint256 refundAmount = 0;

        if (potentialFundingAmount > fundingGoal) {
            refundAmount = potentialFundingAmount - fundingGoal;
            funders[msg.sender] += (msg.value - refundAmount);
            fundingAmount += (msg.value - refundAmount);
        } else {
            funders[msg.sender] += msg.value;
            fundingAmount += msg.value;
        }

        if (!fundersInserted[msg.sender]) {
            fundersInserted[msg.sender] = true;
            fundersKey.push(msg.sender);
        }

        if (refundAmount > 0) {
            payable(msg.sender).transfer(refundAmount);
        }
    }

    function close() external returns(bool) {
        if (fundingAmount < fundingGoal) {
            return false;
        }

        uint256 amount = fundingAmount;

        fundingAmount = 0;
        available = false;
        payable(beneficiary).transfer(amount);
        return true;
    }

    function fundersLength() public view returns(uint256) {
        return fundersKey.length;
    }
}