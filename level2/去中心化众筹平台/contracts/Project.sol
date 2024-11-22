// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.25;

// 1.项目创建：
//  用户可以创建众筹项目，设置筹款目标、截止日期以及项目描述。
//  每个项目都有一个唯一的地址。
//  项目创建时需要记录创建者、描述、目标金额、截止日期和当前筹集金额。
// 2.资金捐赠：
//  用户可以向特定的众筹项目捐款。
//  记录每个用户的捐款金额。
//  更新项目的当前筹集金额。
// 3.项目状态更新：
//  项目可以有多个状态（进行中、成功、失败）。
//  在截止日期到来时，根据筹款是否达到目标来更新状态。
// 4.资金提取：
//  如果项目成功，项目创建者可以提取筹集的资金。
//  确保只有项目创建者可以提取资金。
// 5.资金撤回：
//  如果项目失败，捐赠者可以撤回他们的捐款。
//  确保只有在项目失败时捐赠者可以撤回资金。
// 6.可升级性：
//  使用UUPS模式实现合约的可升级性。
//  管理合约的升级。


contract Project {
  address public creator;
  string public description;
  uint256 public goalAmount;
  uint256 public deadline;
  uint256 public currentAmount;

  enum ProjectStatus {
    Ongoing,
    Success,
    Failed
  }
  ProjectStatus public status;

  struct Donation {
    address donor;
    uint256 amount;
  }
  Donation[] public donations;

  event DonationReceived(
    address indexed donor,
    uint256 amount
  );

  event ProjectChanged(
    ProjectStatus newStatus
  );

  event FundsWithdraw(
    address indexed creator,
    uint256 amount
  );

  event FundsRefunded(
    address indexed donor,
    uint256 amount
  );

  modifier onlyCreator() {
    require(msg.sender == creator, "not creator");
    _;
  }

  modifier onlyAfterDeadline() {
    require(block.timestamp >= deadline, "project is still ongoing");
    _;
  }

  function initialize(address _creator, string memory _description, uint256 _goalAmount, uint256 _duration) public {
    creator = _creator;
    description = _description;
    goalAmount = _goalAmount;
    deadline = block.timestamp + _duration;
    status = ProjectStatus.Ongoing;
  }

  function donate() external payable {
    require(status == ProjectStatus.Ongoing, "project is not ongoing");
    require(block.timestamp < deadline, "project is already finished");

    donations.push(Donation({
      donor: msg.sender,
      amount: msg.value
    }));

    currentAmount += msg.value;

    emit DonationReceived(msg.sender, msg.value);
  }

  function withdrawFunds() external onlyCreator onlyAfterDeadline {
    require(status == ProjectStatus.Success, "project is not successful");

    uint256 amount  = address(this).balance;
    payable(creator).transfer(amount);

    emit FundsWithdraw(creator, amount);
  }

  function refund() external onlyAfterDeadline {
    require(status == ProjectStatus.Failed, "project is not failed");

    uint256 totalRefund = 0;
    for (uint256 i = 0; i < donations.length; i++) {
      if (donations[i].donor == msg.sender) {
        totalRefund += donations[i].amount;
        donations[i].amount = 0;
      }
    }

    require(totalRefund > 0, "no refunds available");
    payable(msg.sender).transfer(totalRefund);

    emit FundsRefunded(msg.sender, totalRefund);
  }

  function updateProjectState() external onlyAfterDeadline {
    require(status == ProjectStatus.Ongoing, "project is not ongoing");

    if (currentAmount >= goalAmount) {
      status = ProjectStatus.Success;
    } else {
      status = ProjectStatus.Failed;
    }

    emit ProjectChanged(status);
  }
}