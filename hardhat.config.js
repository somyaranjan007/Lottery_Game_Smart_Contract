require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      chainId: 31337,
      blockConfirmations: 1,
    },
    sepolia: {
      chainId: 5,
      blockConfirmations: 3,
      url:
      accounts:
    }
  },
  solidity: "0.8.18",
  deployer: {
    default: 0,
  }
  player: {
    default: 1,
  }
};