require("@openzeppelin/hardhat-upgrades");
require("dotenv").config();
require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.27",
  networks: {
    sepolia: {
      url: process.env.SEPOLIA_RPC_URL, // 在 .env 文件中设置 RPC URL
      accounts: [process.env.PRIVATE_KEY], // 部署者的钱包私钥
    },
  },
};
