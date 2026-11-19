const hre = require("hardhat");

// Agent ID contract on BNB Chain (SPACE ID Agent ID, ERC-721, non-transferable)
const MAINNET_AGENT_ID = "0x60b9262456de011f7d15a54cdd8c48baaa8b022f";

async function main() {
  const agentId = process.env.AGENT_ID_ADDRESS || MAINNET_AGENT_ID;
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deployer:", deployer.address);
  console.log("Agent ID contract:", agentId);
  console.log("Network:", hre.network.name, "chainId:", (await hre.ethers.provider.getNetwork()).chainId);

  const Board = await hre.ethers.getContractFactory("AgentTaskBoard");
  const board = await Board.deploy(agentId);
  await board.waitForDeployment();
  const address = await board.getAddress();
  console.log("AgentTaskBoard deployed to:", address);
  console.log("Verify on BscScan with: npx hardhat verify --network <network>", address, agentId);
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});
