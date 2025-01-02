require("@nomicfoundation/hardhat-ignition");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.4.18",
      },
      {
        version: "0.5.16",
      },
      {
        version: "0.6.6",
      },
      {
        version: "0.6.12",
      },
    ],
  },
};
