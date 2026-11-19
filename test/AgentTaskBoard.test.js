const { expect } = require("chai");
const { ethers } = require("hardhat");

const REWARD = ethers.parseEther("0.01");

async function deployFixture() {
  const [poster, worker, stranger] = await ethers.getSigners();

  const Mock = await ethers.getContractFactory("MockAgentId");
  const agentId = await Mock.deploy();
  await agentId.waitForDeployment();

  const Board = await ethers.getContractFactory("AgentTaskBoard");
  const board = await Board.deploy(await agentId.getAddress());
  await board.waitForDeployment();

  // worker holds a (mock) Agent ID; stranger does not.
  await agentId.mint(worker.address);

  const deadline = (await ethers.provider.getBlock("latest")).timestamp + 3600;
  return { board, agentId, poster, worker, stranger, deadline };
}

async function createTask(board, poster, reward = REWARD, deadline) {
  const dl = deadline ?? (await ethers.provider.getBlock("latest")).timestamp + 3600;
  const tx = await board.connect(poster).createTask("ipfs://QmDescription", dl, { value: reward });
  const receipt = await tx.wait();
  const taskId = 0; // first task in a fresh fixture
  return { tx, receipt, taskId, deadline: dl };
}

describe("AgentTaskBoard", function () {
  it("happy path: create -> accept -> submit -> approve pays the worker", async function () {
    const { board, poster, worker, deadline } = await deployFixture();
    await expect(board.connect(poster).createTask("ipfs://QmDesc", deadline, { value: REWARD }))
      .to.emit(board, "TaskCreated")
      .withArgs(0, poster.address, REWARD, deadline, "ipfs://QmDesc");

    await expect(board.connect(worker).acceptTask(0)).to.emit(board, "TaskAccepted").withArgs(0, worker.address);
    await expect(board.connect(worker).submitWork(0, "ipfs://QmProof"))
      .to.emit(board, "WorkSubmitted")
      .withArgs(0, worker.address, "ipfs://QmProof");

    const approveTx = board.connect(poster).approve(0);
    await expect(approveTx).to.emit(board, "TaskApproved").withArgs(0, worker.address, REWARD);
    await expect(approveTx).to.changeEtherBalances([board, worker], [-REWARD, REWARD]);

    expect((await board.getTask(0)).status).to.equal(3); // Completed
  });

  it("createTask reverts with zero value and with a past deadline", async function () {
    const { board, poster, deadline } = await deployFixture();
    await expect(board.connect(poster).createTask("x", deadline, { value: 0 }))
      .to.be.revertedWithCustomError(board, "ZeroReward");
    const past = (await ethers.provider.getBlock("latest")).timestamp - 10;
    await expect(board.connect(poster).createTask("x", past, { value: REWARD }))
      .to.be.revertedWithCustomError(board, "DeadlineInPast");
  });

  it("acceptTask reverts for non-Agent-ID holders", async function () {
    const { board, poster, stranger, deadline } = await deployFixture();
    await board.connect(poster).createTask("ipfs://QmDesc", deadline, { value: REWARD });
    await expect(board.connect(stranger).acceptTask(0))
      .to.be.revertedWithCustomError(board, "NotAgentIdHolder")
      .withArgs(stranger.address);
  });

  it("acceptTask reverts on double-accept", async function () {
    const { board, poster, worker, deadline } = await deployFixture();
    await board.connect(poster).createTask("ipfs://QmDesc", deadline, { value: REWARD });
    await board.connect(worker).acceptTask(0);
    await expect(board.connect(worker).acceptTask(0))
      .to.be.revertedWithCustomError(board, "InvalidStatus");
  });

  it("submitWork reverts for non-accepter and for unaccepted tasks", async function () {
    const { board, poster, worker, stranger, deadline } = await deployFixture();
    await board.connect(poster).createTask("ipfs://QmDesc", deadline, { value: REWARD });
    // not accepted yet
    await expect(board.connect(worker).submitWork(0, "proof"))
      .to.be.revertedWithCustomError(board, "InvalidStatus");
    await board.connect(worker).acceptTask(0);
    // stranger is not the accepter
    await expect(board.connect(stranger).submitWork(0, "proof"))
      .to.be.revertedWithCustomError(board, "NotAccepter")
      .withArgs(stranger.address);
  });

  it("approve reverts for non-poster and for unsubmitted tasks", async function () {
    const { board, poster, worker, stranger, deadline } = await deployFixture();
    await board.connect(poster).createTask("ipfs://QmDesc", deadline, { value: REWARD });
    await board.connect(worker).acceptTask(0);
    // not submitted yet
    await expect(board.connect(poster).approve(0))
      .to.be.revertedWithCustomError(board, "InvalidStatus");
    await board.connect(worker).submitWork(0, "ipfs://QmProof");
    // stranger is not the poster
    await expect(board.connect(stranger).approve(0))
      .to.be.revertedWithCustomError(board, "NotPoster")
      .withArgs(stranger.address);
  });

  it("refund reverts before the deadline; succeeds after it (no work submitted)", async function () {
    const { board, poster, worker, deadline } = await deployFixture();
    await board.connect(poster).createTask("ipfs://QmDesc", deadline, { value: REWARD });
    await board.connect(worker).acceptTask(0);
    await expect(board.connect(poster).refund(0))
      .to.be.revertedWithCustomError(board, "DeadlineNotReached");

    await ethers.provider.send("evm_increaseTime", [3601]);
    await ethers.provider.send("evm_mine");
    const refundTx = board.connect(poster).refund(0);
    await expect(refundTx).to.emit(board, "TaskRefunded").withArgs(0, poster.address, REWARD);
    await expect(refundTx).to.changeEtherBalances([board, poster], [-REWARD, REWARD]);
    expect((await board.getTask(0)).status).to.equal(4); // Refunded
  });

  it("refund reverts once work is submitted (poster must approve or worker claims later)", async function () {
    const { board, poster, worker, deadline } = await deployFixture();
    await board.connect(poster).createTask("ipfs://QmDesc", deadline, { value: REWARD });
    await board.connect(worker).acceptTask(0);
    await board.connect(worker).submitWork(0, "ipfs://QmProof");
    await ethers.provider.send("evm_increaseTime", [3601]);
    await ethers.provider.send("evm_mine");
    await expect(board.connect(poster).refund(0))
      .to.be.revertedWithCustomError(board, "InvalidStatus");
  });

  it("claimAfterReview pays the worker if the poster never approves", async function () {
    const { board, poster, worker, deadline } = await deployFixture();
    await board.connect(poster).createTask("ipfs://QmDesc", deadline, { value: REWARD });
    await board.connect(worker).acceptTask(0);
    await board.connect(worker).submitWork(0, "ipfs://QmProof");
    // inside review window: revert
    await ethers.provider.send("evm_increaseTime", [3601]);
    await ethers.provider.send("evm_mine");
    await expect(board.connect(worker).claimAfterReview(0))
      .to.be.revertedWithCustomError(board, "ReviewWindowNotPassed");
    // past deadline + 3 days: succeeds
    await ethers.provider.send("evm_increaseTime", [3 * 24 * 3600]);
    await ethers.provider.send("evm_mine");
    const claimTx = board.connect(worker).claimAfterReview(0);
    await expect(claimTx).to.emit(board, "TaskClaimed").withArgs(0, worker.address, REWARD);
    await expect(claimTx).to.changeEtherBalances([board, worker], [-REWARD, REWARD]);
  });

  it("cancelTask refunds an open task; reverts once accepted", async function () {
    const { board, poster, worker, deadline } = await deployFixture();
    await board.connect(poster).createTask("ipfs://QmDesc", deadline, { value: REWARD });
    const cancelTx = board.connect(poster).cancelTask(0);
    await expect(cancelTx).to.emit(board, "TaskCancelled").withArgs(0, poster.address, REWARD);
    await expect(cancelTx).to.changeEtherBalances([board, poster], [-REWARD, REWARD]);
    expect((await board.getTask(0)).status).to.equal(5); // Cancelled

    await board.connect(poster).createTask("ipfs://QmDesc2", deadline, { value: REWARD });
    await board.connect(worker).acceptTask(1);
    await expect(board.connect(poster).cancelTask(1))
      .to.be.revertedWithCustomError(board, "InvalidStatus");
  });

  it("isAgentIdHolder reflects Agent ID ownership; fee is 0; no owner exists", async function () {
    const { board, worker, stranger } = await deployFixture();
    expect(await board.isAgentIdHolder(worker.address)).to.equal(true);
    expect(await board.isAgentIdHolder(stranger.address)).to.equal(false);
    expect(await board.PLATFORM_FEE_BPS()).to.equal(0);
    // contract exposes no owner/admin: `owner` must not exist
    expect(board.owner).to.equal(undefined);
  });
});
