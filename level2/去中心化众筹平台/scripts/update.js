const { ethers, upgrades } = require("hardhat");

async function main() {
  const CrowdfundingPlatformV2 = await ethers.getContractFactory("CrowdfundingPlatformV2");
  const platform = await upgrades.upgradeProxy("0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512", CrowdfundingPlatformV2);

  console.log("CrowdfundingPlatform upgraded");
}

main();