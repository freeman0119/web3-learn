const { ethers, upgrades } = require("hardhat");

async function main() {
  const CrowdfundingPlatform = await ethers.getContractFactory("CrowdfundingPlatform");
  const platform = await upgrades.deployProxy(CrowdfundingPlatform, ["0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"], { initializer: "initialize" });

  await platform.waitForDeployment();
  console.log("CrowdfundingPlatform deployed to:", platform.target);
}

main();