// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

// 建议：

// 需要写测试！！！
// 合约开发完成后部署到 sepolia 进行测试
// 可以自己在sepolia 上面发一个erc20 token 作为reward token的代币
// 第一个stake token 是所在链的native currency；如果想开其他pool，stake token 可以是erc20Token，合约自行改造调整。
// 1. 系统概述
// RCCStake 是一个基于区块链的质押系统，支持多种代币的质押，并基于用户质押的代币数量和时间长度分配 RCC 代币作为奖励。系统可提供多个质押池，每个池可以独立配置质押代币、奖励计算等。

// 2. 功能需求
// 2.1 质押功能
// 输入参数: 池 ID(_pid)，质押数量(_amount)。
// 前置条件: 用户已授权足够的代币给合约。
// 后置条件: 用户的质押代币数量增加，池中的总质押代币数量更新。
// 异常处理: 质押数量低于最小质押要求时拒绝交易。
// 2.2 解除质押功能
// 输入参数: 池 ID(_pid)，解除质押数量(_amount)。
// 前置条件: 用户质押的代币数量足够。
// 后置条件: 用户的质押代币数量减少，解除质押请求记录，等待锁定期结束后可提取。
// 异常处理: 如果解除质押数量大于用户质押的数量，交易失败。
// 2.3 领取奖励
// 输入参数: 池 ID(_pid)。
// 前置条件: 有可领取的奖励。
// 后置条件: 用户领取其奖励，清除已领取的奖励记录。
// 异常处理: 如果没有可领取的奖励，不执行任何操作。
// 2.4 添加和更新质押池
// 输入参数: 质押代币地址(_stTokenAddress)，池权重(_poolWeight)，最小质押金额(_minDepositAmount)，解除质押锁定区(_unstakeLockedBlocks)。
// 前置条件: 只有管理员可操作。
// 后置条件: 创建新的质押池或更新现有池的配置。
// 异常处理: 权限验证失败或输入数据验证失败。
// 2.5 合约升级和暂停
// 升级合约: 只有持有升级角色的账户可执行。
// 暂停/恢复操作: 可以独立控制质押、解除质押、领奖等操作的暂停和恢复。

// 4. 安全需求
// 访问控制: 使用角色基础的访问控制确保只有授权用户可以执行敏感操作。
// 重入攻击保护: 使用状态锁定模式防止重入攻击。
// 输入验证: 所有用户输入必须经过严格验证，包括参数范围检查和数据完整性验证。
// 5. 事件记录
// 每个关键操作（如质押、解除质押、领奖）都应触发事件，以便外部监听器跟踪和记录状态变化。
// 6. 接口设计
// 提供标准的 Ethereum 智能合约接口，支持 ERC20 代币操作和自定义合约方法。
// 提供前端界面调用合约的接口说明和示例代码，确保前端可以正确交互并展示合约状态。

contract RCCStake is
  Initializable,
  UUPSUpgradeable,
  PausableUpgradeable,
  AccessControlUpgradeable 
{
  using SafeERC20 for IERC20;
  using Address for address;
  using Math for uint256;

  bytes32 public constant ADMIN_ROLE = keccak256("admin_role");
  bytes32 public constant UPGRADE_ROLE = keccak256("upgrade_role");

  uint256 public constant ETH_PID = 0;

  // stTokenAddress: 质押代币的地址。
  // poolWeight: 质押池的权重，影响奖励分配。
  // lastRewardBlock: 最后一次计算奖励的区块号。
  // accRCCPerST: 每个质押代币累积的 RCC 数量。
  // stTokenAmount: 池中的总质押代币量。
  // minDepositAmount: 最小质押金额。
  // unstakeLockedBlocks: 解除质押的锁定区块数。
  struct Pool {
    address stTokenAddress;
    uint256 poolWeight;
    uint256 lastRewardBlock;
    uint256 accRCCPerST;
    uint256 stTokenAmount;
    uint256 minDepositAmount;
    uint256 unstakeLockedBlocks;
  }

  struct UnstakeRequest {
    uint256 amount;
    uint256 unlockBlocks;
  }

  // stAmount: 用户质押的代币数量。
  // finishedRCC: 已分配的 RCC 数量。
  // pendingRCC: 待领取的 RCC 数量。
  // requests: 解质押请求列表，每个请求包含解质押数量和解锁区块。
  struct User {
    uint256 stAmount;
    uint256 finishedRCC;
    uint256 pendingRCC;
    UnstakeRequest[] requests;
  }

  // 质押开始区块
  uint256 public startBlock;
  // 质押结束区块
  uint256 public endBlock;
  // 每个区块的奖励数量
  uint256 public RCCPerBlock;
  // 暂停提现
  bool public withdrawPaused;
  // pause the claim function
  bool public claimPaused;

  // RCC token
  IERC20 public RCC;

  // total pool weight
  uint256 public totalPoolWeight;
  Pool[] public pools;

  // // pool id => user address => user info
  mapping(uint256 => mapping(address => User)) public user;

  // ************************************** EVENT **************************************
  event SetRCC(IERC20 indexed RCC);

  event PauseWithdraw();

  event UnpauseWithdraw();

  event PauseClaim();

  event UnpauseClaim();

  event SetStartBlock(uint256 indexed startBlock);

  event SetEndBlock(uint256 indexed endBlock);

  event SetRCCPerBlock(uint256 indexed rccPerBlock);

  event AddPool(address indexed stTokenAddress, uint256 indexed poolWeight, uint256 indexed lastRewardBlock, uint256 minDepositAmount, uint256 unstakeLockedBlocks);

  event UpdatePoolInfo(uint256 indexed poolId, uint256 indexed minDepositAmount, uint256 indexed unstakeLockedBlocks);

  event SetPoolWeight(uint256 indexed poolId, uint256 indexed poolWeight, uint256 totalPoolWeight);

  event UpdatePool(uint256 indexed poolId, uint256 indexed lastRewardBlock, uint256 totalRCC);

  event Deposit(address indexed user, uint256 indexed poolId, uint256 amount);

  event RequestUnstake(address indexed user, uint256 indexed poolId, uint256 amount);

  event Withdraw(address indexed user, uint256 indexed poolId, uint256 amount, uint256 indexed blockNumber);

  event Claim(address indexed user, uint256 indexed poolId, uint256 rccReward);

  // ************************************** MODIFIER **************************************

  modifier checkPid(uint256 _pid) {
    require(_pid < pools.length, "invalid pid");
    _;
  }

  modifier whenNotClaimPaused() {
    require(!claimPaused, "claim paused");
    _;
  }

  modifier whenNotWithdrawPaused() {
    require(!withdrawPaused, "withdraw paused");
    _;
  }

  /**
   * 初始化，设置角色权限，rcc代币
   */
  function initialize(IERC20 _RCC, uint256 _startBlock, uint256 _endBlock, uint256 _RCCPerBlock) public initializer {
    require(_startBlock <= _endBlock && _RCCPerBlock > 0, "invalid parameters");

    __AccessControl_init();
    __UUPSUpgradeable_init();
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(UPGRADE_ROLE, msg.sender);
    _grantRole(ADMIN_ROLE, msg.sender);

    setRCC(_RCC);

    startBlock = _startBlock;
    endBlock = _endBlock;
    RCCPerBlock = _RCCPerBlock;
  }

  function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADE_ROLE) {}

  // ************************************** ADMIN FUNCTION **************************************
  /**
  * 设置rcc代币地址 
  */
  function setRCC(IERC20 _RCC) public onlyRole(ADMIN_ROLE) {
    RCC = _RCC;
    emit SetRCC(_RCC);
  }

  /**
   * 暂停提现
   */
  function pauseWithdraw() public onlyRole(ADMIN_ROLE) {
    require(!withdrawPaused, "already paused");
    withdrawPaused = true;
    emit PauseWithdraw();
  }

  /**
   * 取消暂停提现
   */
  function unpauseWithdraw() public onlyRole(ADMIN_ROLE) {
    require(withdrawPaused, "already unpaused");
    withdrawPaused = false;
    emit UnpauseWithdraw();
  }

  /**
   * 暂停索取？
   */
  function pauseClaim() public onlyRole(ADMIN_ROLE) {
    require(!claimPaused, "already paused");
    claimPaused = true;
    emit PauseClaim();
  }

  /**
   * 设置开始区块
   */
  function setStartBlock(uint256 _startBlock) public onlyRole(ADMIN_ROLE) {
    require(_startBlock <= endBlock, "start block must be smaller than end block");
    startBlock = _startBlock;
    emit SetStartBlock(_startBlock);
  }

  /**
   * 设置结束区块
   */
  function setEndBlock(uint256 _endBlock) public onlyRole(ADMIN_ROLE) {
    require(startBlock <= _endBlock, "start block must be smaller than end block");
    endBlock = _endBlock;
    emit SetEndBlock(_endBlock);
  }

  /**
   * 设置每个区块的rcc奖励数量
   */
  function setRCCPerBlock(uint256 _RCCPerBlock) public onlyRole(ADMIN_ROLE) {
    require(_RCCPerBlock > 0, "invalid reward");
    RCCPerBlock = _RCCPerBlock;
    emit SetRCCPerBlock(RCCPerBlock);
  }

  /**
   * 添加质押池
   */
  function addPool(
    address _stTokenAddress,
    uint256 _poolWeight,
    uint256 _minDepositAmount,
    uint256 _unstakeLockedBlocks,
    bool _withUpdate
  ) public onlyRole(ADMIN_ROLE) {
    // 合约的第一个质押池必须是合约的本地代币
    // Default the first pool to be nativeCurrency pool, so the first pool must be added with stTokenAddress = address(0x0)
    if (pools.length > 0) {
      require(_stTokenAddress != address(0), "invalid staking token address");
    } else {
      require(_stTokenAddress == address(0), "invalid staking token address");
    }

    require(_unstakeLockedBlocks > 0, "invalid unstake locked blocks");
    require(block.number < endBlock, "already ended");

    if (_withUpdate) {
      massUpdatePools();
    }

    uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
    totalPoolWeight = totalPoolWeight + _poolWeight;

    pools.push(Pool({
      stTokenAddress: _stTokenAddress,
      poolWeight: _poolWeight,
      lastRewardBlock: lastRewardBlock,
      accRCCPerST: 0,
      stTokenAmount: 0,
      minDepositAmount: _minDepositAmount,
      unstakeLockedBlocks: _unstakeLockedBlocks
    }));

    emit AddPool(_stTokenAddress, _poolWeight, lastRewardBlock, _minDepositAmount, _unstakeLockedBlocks);
  }

  /**
   * 更新质押池的信息，包括最小存入数量，未质押锁定区块？
   */
  function updatePoolInfo(uint256 _pid, uint256 _minDepositAmount, uint256 _unstakeLockedBlocks) public onlyRole(ADMIN_ROLE) {
    pools[_pid].minDepositAmount = _minDepositAmount;
    pools[_pid].unstakeLockedBlocks = _unstakeLockedBlocks;

    emit UpdatePoolInfo(_pid, _minDepositAmount, _unstakeLockedBlocks);
  }

  /**
   * 设置质押池的权重
   */
  function setPoolWeight(uint256 _pid, uint256 _poolWeight, bool _withUpdate) public onlyRole(ADMIN_ROLE) checkPid(_pid) {
    require(_poolWeight > 0, "invalid pool weight");

    if (_withUpdate) {
      massUpdatePools();
    }

    totalPoolWeight = totalPoolWeight - pools[_pid].poolWeight + _poolWeight;
    pools[_pid].poolWeight = _poolWeight;
    emit SetPoolWeight(_pid, _poolWeight, totalPoolWeight);
  }

  /**
   * 获取质押池的数量
   */
  function poolLength() external view returns(uint256) {
    return pools.length;
  }

  /**
   * @notice 获取form到to的区块长度，然后和每个区块奖励数量乘积，获取总的奖励
   *
   * @param _from    From block number (included)
   * @param _to      To block number (exluded)
   */
  function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256 multiplier) {
    require(_from <= _to, "invalid block range");
    if (_from < startBlock) {
      _from = startBlock;
    }
    if (_to > endBlock) {
      _to = endBlock;
    }
    require(_from <= _to, "end block must be greater than start block");
    bool success;
    (success, multiplier) = (_to - _from).tryMul(RCCPerBlock);
    require(success, "multiplier overflow");
  }

  /**
   * 根据区块号，获取待领取rcc数量
   */
  function pendingRCC(uint256 _pid, address _user) external view checkPid(_pid) returns (uint256) {
    return pendingRCCByBlockNumber(_pid, _user, block.number);
  }

  /**
   * 根据区块号，获取待领取rcc数量
   */
  function pendingRCCByBlockNumber(uint256 _pid, address _user, uint256 _blockNumber) public view checkPid(_pid) returns (uint256) {
    Pool storage pool_ = pools[_pid];
    User storage user_ = user[_pid][_user];
    uint256 accRCCPerST = pool_.accRCCPerST;
    uint256 stSupply = pool_.stTokenAmount;

    if (_blockNumber > pool_.lastRewardBlock && stSupply != 0) {
      uint256 multiplier = getMultiplier(pool_.lastRewardBlock, _blockNumber);
      uint256 rccForPool = multiplier * pool_.poolWeight / totalPoolWeight;
      accRCCPerST = accRCCPerST + rccForPool * (1 ether) / stSupply; // 1 ether调整精度，单位变成wei
    }

    return user_.stAmount * accRCCPerST / (1 ether) - user_.finishedRCC + user_.pendingRCC;
  }

  /**
   * 获取用户质押数量
   */
  function stakingBalance(uint256 _pid, address _user) external checkPid(_pid) view returns(uint256) {
    return user[_pid][_user].stAmount;
  }

  /**
   * 获取提现的数量
   */
  function withdrawAmount(uint256 _pid, address _user) public view checkPid(_pid) returns(uint256 requestAmount, uint256 pendingWithdrawAmount) {
    User storage user_ = user[_pid][_user];

    for (uint256 i = 0; i < user_.requests.length; i++) {
      if (user_.requests[i].unlockBlocks <= block.number) {
        pendingWithdrawAmount = pendingWithdrawAmount + user_.requests[i].amount;
      }
      requestAmount = requestAmount + user_.requests[i].amount;
    }
  }

  // ************************************** PUBLIC FUNCTION **************************************


  /**
   * 更新质押池信息，最后计算奖励的区块，每个质押的奖励
   */
  function updatePool(uint256 _pid) public checkPid(_pid) {
    Pool storage pool_ = pools[_pid];

    if (block.number <= pool_.lastRewardBlock) {
      return;
    }

    (bool success1, uint256 totalRCC) = getMultiplier(pool_.lastRewardBlock, block.number).tryMul(pool_.poolWeight);
    require(success1, "overflow");

    (success1, totalRCC) = totalRCC.tryDiv(totalPoolWeight);
    require(success1, "overflow");

    uint256 stSupply = pool_.stTokenAmount;
    if (stSupply > 0) {
        (bool success2, uint256 totalRCC_) = totalRCC.tryMul(1 ether);
        require(success2, "overflow");

        (success2, totalRCC_) = totalRCC_.tryDiv(stSupply);
        require(success2, "overflow");

        (bool success3, uint256 accRCCPerST) = pool_.accRCCPerST.tryAdd(totalRCC_);
        require(success3, "overflow");
        pool_.accRCCPerST = accRCCPerST;
    }

    pool_.lastRewardBlock = block.number;

    emit UpdatePool(_pid, pool_.lastRewardBlock, totalRCC);
  }

  /**
   * 更新所有质押池信息
   */
  function massUpdatePools() public {
    uint256 length = pools.length;
    for (uint256 pid = 0; pid < length; pid++) {
        updatePool(pid);
    }
  }

  /**
   * 存入eth质押池存入eth
   */
  function depositETH() public whenNotPaused() payable {
    Pool storage pool_ = pools[ETH_PID];
    require(pool_.stTokenAddress == address(0x0), "invalid staking token address");

    uint256 _amount = msg.value;
    require(_amount >= pool_.minDepositAmount, "deposit amount is too small");

    _deposit(ETH_PID, _amount);
  }

  /**
   * 存入代币，在代币的合约地址，从msg.sender转入amount数量的代币到address(this)
   * @param _pid       Id of the pool to be deposited to
   * @param _amount    Amount of staking tokens to be deposited
   */
  function deposit(uint256 _pid, uint256 _amount) public whenNotPaused() checkPid(_pid) {
      require(_pid != 0, "deposit not support ETH staking");
      Pool storage pool_ = pools[_pid];
      require(_amount > pool_.minDepositAmount, "deposit amount is too small");

      if(_amount > 0) {
        IERC20(pool_.stTokenAddress).safeTransferFrom(msg.sender, address(this), _amount);
      }

      _deposit(_pid, _amount);
  }

  /**
   * 解除质押
   * @param _pid       Id of the pool to be withdrawn from
   * @param _amount    amount of staking tokens to be withdrawn
   */
  function unstake(uint256 _pid, uint256 _amount) public whenNotPaused() checkPid(_pid) whenNotWithdrawPaused() {
      Pool storage pool_ = pools[_pid];
      User storage user_ = user[_pid][msg.sender];

      require(user_.stAmount >= _amount, "Not enough staking token balance");

      updatePool(_pid);

      uint256 pendingRCC_ = user_.stAmount * pool_.accRCCPerST / (1 ether) - user_.finishedRCC;

      if(pendingRCC_ > 0) {
          user_.pendingRCC = user_.pendingRCC + pendingRCC_;
      }

      if(_amount > 0) {
          user_.stAmount = user_.stAmount - _amount;
          user_.requests.push(UnstakeRequest({
              amount: _amount,
              unlockBlocks: block.number + pool_.unstakeLockedBlocks
          }));
      }

      pool_.stTokenAmount = pool_.stTokenAmount - _amount;
      user_.finishedRCC = user_.stAmount * pool_.accRCCPerST / (1 ether);

      emit RequestUnstake(msg.sender, _pid, _amount);
  }

  /**
   * @notice 提取解除锁定的，解除质押的代币
   *
   * @param _pid       Id of the pool to be withdrawn from
   */
  function withdraw(uint256 _pid) public whenNotPaused() checkPid(_pid) whenNotWithdrawPaused() {
    Pool storage pool_ = pools[_pid];
    User storage user_ = user[_pid][msg.sender];

    uint256 pendingWithdraw_;
    uint256 popNum_;
    for (uint256 i = 0; i < user_.requests.length; i++) {
      // 区块未解锁
      if (user_.requests[i].unlockBlocks > block.number) {
        // break; 
        // 应该用continue
        continue;
      }
      pendingWithdraw_ = pendingWithdraw_ + user_.requests[i].amount;
      popNum_++;
    }

    // 这里不对，不能保证后面的都是未解锁的 
    for (uint256 i = 0; i < user_.requests.length - popNum_; i++) {
      user_.requests[i] = user_.requests[i + popNum_];
    }

    for (uint256 i = 0; i < popNum_; i++) {
      user_.requests.pop();
    }

    if (pendingWithdraw_ > 0) {
      if (pool_.stTokenAddress == address(0x0)) {
        _safeETHTransfer(msg.sender, pendingWithdraw_);
      } else {
        IERC20(pool_.stTokenAddress).safeTransfer(msg.sender, pendingWithdraw_);
      }
    }

    emit Withdraw(msg.sender, _pid, pendingWithdraw_, block.number);
  }

  /**
   * 提取rcc token奖励
   * @param _pid       Id of the pool to be claimed from
   */
  function claim(uint256 _pid) public whenNotPaused() checkPid(_pid) whenNotClaimPaused() {
    Pool storage pool_ = pools[_pid];
    User storage user_ = user[_pid][msg.sender];

    updatePool(_pid);

    uint256 pendingRCC_ = user_.stAmount * pool_.accRCCPerST / (1 ether) - user_.finishedRCC + user_.pendingRCC;

    if(pendingRCC_ > 0) {
        user_.pendingRCC = 0;
        _safeRCCTransfer(msg.sender, pendingRCC_);
    }

    user_.finishedRCC = user_.stAmount * pool_.accRCCPerST / (1 ether);

    emit Claim(msg.sender, _pid, pendingRCC_);
  }

  // ************************************** INTERNAL FUNCTION **************************************

  /**
   * 存入代币获取rcc奖励
   * @param _pid       Id of the pool to be deposited to
   * @param _amount    Amount of staking tokens to be deposited
   */
  function _deposit(uint256 _pid, uint256 _amount) internal {
    Pool storage pool_ = pools[_pid];
    User storage user_ = user[_pid][msg.sender];

    updatePool(_pid);

    if (user_.stAmount > 0) {
      (bool success1, uint256 accST) = user_.stAmount.tryMul(pool_.accRCCPerST);
      require(success1, "user stAmount mul accRCCPerST overflow");
      (success1, accST) = accST.tryDiv(1 ether);
      require(success1, "accST div 1 ether overflow");
      
      (bool success2, uint256 pendingRCC_) = accST.trySub(user_.finishedRCC);
      require(success2, "accST sub finishedRCC overflow");

      if(pendingRCC_ > 0) {
        (bool success3, uint256 _pendingRCC) = user_.pendingRCC.tryAdd(pendingRCC_);
        require(success3, "user pendingRCC overflow");
        user_.pendingRCC = _pendingRCC;
      }
    }

    if (_amount > 0) {
      (bool success4, uint256 stAmount) = user_.stAmount.tryAdd(_amount);
      require(success4, "user stAmount overflow");
      user_.stAmount = stAmount;
    }

    (bool success5, uint256 stTokenAmount) = pool_.stTokenAmount.tryAdd(_amount);
    require(success5, "pool stTokenAmount overflow");
    pool_.stTokenAmount = stTokenAmount;

    (bool success6, uint256 finishedRCC) = user_.stAmount.tryMul(pool_.accRCCPerST);
    require(success6, "user stAmount mul accRCCPerST overflow");

    (success6, finishedRCC) = finishedRCC.tryDiv(1 ether);
    require(success6, "finishedRCC div 1 ether overflow");

    user_.finishedRCC = finishedRCC;

    emit Deposit(msg.sender, _pid, _amount);
  }

  /**
   * 提取rcc奖励
   * @param _to        Address to get transferred RCCs
   * @param _amount    Amount of RCC to be transferred
   */
  function _safeRCCTransfer(address _to, uint256 _amount) internal {
    uint256 RCCBal = RCC.balanceOf(address(this));

    if (_amount > RCCBal) {
      RCC.transfer(_to, RCCBal);
    } else {
      RCC.transfer(_to, _amount);
    }
  }

  /**
   * 提取eth
   * @param _to        Address to get transferred ETH
   * @param _amount    Amount of ETH to be transferred
   */
  function _safeETHTransfer(address _to, uint256 _amount) internal {
      (bool success, bytes memory data) = address(_to).call{
          value: _amount
      }("");

      require(success, "ETH transfer call failed");
      if (data.length > 0) {
        require(
          abi.decode(data, (bool)),
          "ETH transfer operation did not succeed"
        );
    }
  }
}