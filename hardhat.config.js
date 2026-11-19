require("@nomicfoundation/hardhat-toolbox");

/**
 * Networks read keys from environment variables only — never commit keys.
 *   BSC_TESTNET_RPC_URL / BSC_RPC_URL : public RPC endpoint
 *   DEPLOYER_PRIVATE_KEY             : deployer key (testnet throwaway or mainnet deployer)
 *   AGENT_ID_ADDRESS                 : Agent ID contract (mainnet 0x60b9262456de011f7d15a54cdd8c48baaa8b022f)
 */
const { BSC_TESTNET_RPC_URL, BSC_RPC_URL, DEPLOYER_PRIVATE_KEY } = process.env;

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.24",
    settings: { optimizer: { enabled: true, runs: 200 } },
  },
  networks: {
    hardhat: {},
    bscTestnet: {
      url: BSC_TESTNET_RPC_URL || "https://data-seed-prebsc-1-s1.binance.org:8545",
      chainId: 97,
      accounts: DEPLOYER_PRIVATE_KEY ? [DEPLOYER_PRIVATE_KEY] : [],
    },
    bsc: {
      url: BSC_RPC_URL || "https://bsc-dataseed.binance.org",
      chainId: 56,
      accounts: DEPLOYER_PRIVATE_KEY ? [DEPLOYER_PRIVATE_KEY] : [],
    },
  },
};
