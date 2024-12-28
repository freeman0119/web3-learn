const { ethers, upgrades } = require("hardhat");

async function main() {

  // 获取合约工厂
  const RccToken = await ethers.getContractFactory("RccToken");
  // // 部署合约
  // const rccToken = await RccToken.deploy();

  // // 等待合约部署完成
  // await rccToken.deployed();

  // console.log("RccToken deployed to:", rccToken.address);

  // console.log("Deploying RCCStake...");

  const rccTokenAddr = "0x264e0349deEeb6e8000D40213Daf18f8b3dF02c3";
  const startBlock = 7370459;
  const endBlock = 10000000;
  const rccPerBlock = "20000000000000000";

  // 部署 RCCStake 合约
  const RCCStake = await ethers.getContractFactory("RCCStake");
  const rccStake = await upgrades.deployProxy(RCCStake, [rccTokenAddr, startBlock, endBlock, rccPerBlock], { initializer: "initialize" });
  console.log("RCCStake deployed to:", await rccStake.getAddress());
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
