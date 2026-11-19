const { ethers } = require("hardhat");

async function main() {
  const [poster, worker] = await ethers.getSigners();
  const Mock = await ethers.getContractFactory("MockAgentId");
  const agentId = await Mock.deploy();
  await agentId.waitForDeployment();
  await agentId.mint(worker.address);

  const Board = await ethers.getContractFactory("AgentTaskBoard");
  const board = await Board.deploy(await agentId.getAddress());
  const deployReceipt = await board.deploymentTransaction().wait();
  console.log("deploy gas:", deployReceipt.gasUsed.toString());

  const deadline = (await ethers.provider.getBlock("latest")).timestamp + 3600;
  const reward = ethers.parseEther("0.01");
  const log = async (label, txPromise) => {
    const receipt = await (await txPromise).wait();
    console.log(label, "gas:", receipt.gasUsed.toString());
  };
  await log("createTask  ", board.connect(poster).createTask("ipfs://QmDesc", deadline, { value: reward }));
  await log("acceptTask  ", board.connect(worker).acceptTask(0));
  await log("submitWork  ", board.connect(worker).submitWork(0, "ipfs://QmProof"));
  await log("approve     ", board.connect(poster).approve(0));

  // second task for refund/cancel gas
  await board.connect(poster).createTask("ipfs://QmDesc2", deadline, { value: reward });
  await log("cancelTask  ", board.connect(poster).cancelTask(1));
  await board.connect(poster).createTask("ipfs://QmDesc3", deadline, { value: reward });
  await board.connect(worker).acceptTask(2);
  await ethers.provider.send("evm_increaseTime", [3601]);
  await ethers.provider.send("evm_mine");
  await log("refund      ", board.connect(poster).refund(2));
}
main().catch((e) => { console.error(e); process.exitCode = 1; });
