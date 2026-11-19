// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @title AgentTaskBoard — escrow micro-task board for Agent ID holders
/// @author AgentTask Board (independent project, not affiliated with Binance)
/// @notice A poster locks BNB in escrow when creating a task. Only an address
///         holding an Agent ID (SPACE ID Agent ID, ERC-721, non-transferable)
///         can accept a task and submit work. The poster releases the escrow
///         by approving the work. If the poster never approves submitted work,
///         the worker can claim the escrow after a review window, so funds can
///         never be locked forever by an absent poster.
/// @dev Agent ID check: `IERC721(AGENT_ID).balanceOf(addr) > 0`.
///      Agent ID contract (BNB Chain): 0x60b9262456de011f7d15a54cdd8c48baaa8b022f
///      This contract has NO owner, NO admin functions, NO pause, NO mint,
///      NO fee (PLATFORM_FEE_BPS = 0) and NO way to move user funds except
///      through the documented task flows below. The deployer has zero
///      privileges after deployment.
contract AgentTaskBoard is ReentrancyGuard {
    /// @notice The Agent ID ERC-721 contract on BNB Chain.
    IERC721 public immutable agentId;

    /// @notice Platform fee in basis points. v1 = 0 (no fee is taken anywhere).
    uint256 public constant PLATFORM_FEE_BPS = 0;

    /// @notice Extra time after the deadline during which the poster may still
    ///         approve submitted work before the worker can claim the escrow.
    uint256 public constant REVIEW_WINDOW = 3 days;

    /// @notice Total number of tasks ever created (also the next task id).
    uint256 public taskCount;

    enum Status {
        Open, // created, no accepter yet
        Accepted, // accepter assigned, work not submitted
        Submitted, // work submitted, awaiting poster approval
        Completed, // approved, escrow paid to accepter
        Refunded, // escrow returned to poster after deadline
        Cancelled // cancelled by poster before acceptance, escrow returned
    }

    struct Task {
        address poster;
        address accepter;
        uint256 reward; // BNB escrowed at creation (msg.value)
        uint256 deadline; // unix timestamp
        string descriptionHash; // off-chain description (e.g. IPFS CID / hash)
        string proofHash; // work proof supplied by the accepter
        Status status;
    }

    mapping(uint256 => Task) public tasks;

    event TaskCreated(
        uint256 indexed taskId,
        address indexed poster,
        uint256 reward,
        uint256 deadline,
        string descriptionHash
    );
    event TaskAccepted(uint256 indexed taskId, address indexed accepter);
    event WorkSubmitted(
        uint256 indexed taskId,
        address indexed accepter,
        string proofHash
    );
    event TaskApproved(
        uint256 indexed taskId,
        address indexed accepter,
        uint256 reward
    );
    event TaskClaimed(
        uint256 indexed taskId,
        address indexed accepter,
        uint256 reward
    );
    event TaskRefunded(
        uint256 indexed taskId,
        address indexed poster,
        uint256 reward
    );
    event TaskCancelled(
        uint256 indexed taskId,
        address indexed poster,
        uint256 reward
    );

    error NotAgentIdHolder(address account);
    error NotPoster(address account);
    error NotAccepter(address account);
    error InvalidStatus(uint256 taskId, Status status);
    error ZeroReward();
    error DeadlineInPast();
    error DeadlineNotReached();
    error ReviewWindowNotPassed();
    error TransferFailed();

    /// @param _agentId Address of the Agent ID ERC-721 contract.
    constructor(address _agentId) {
        agentId = IERC721(_agentId);
    }

    /// @notice True if `account` holds at least one Agent ID.
    function isAgentIdHolder(address account) public view returns (bool) {
        return agentId.balanceOf(account) > 0;
    }

    /// @notice Create a task and lock `msg.value` BNB as escrow.
    /// @param descriptionHash Off-chain description reference (IPFS CID or hash).
    /// @param deadline Unix timestamp after which a refund becomes possible.
    /// @return taskId The id of the newly created task.
    function createTask(
        string calldata descriptionHash,
        uint256 deadline
    ) external payable nonReentrant returns (uint256 taskId) {
        if (msg.value == 0) revert ZeroReward();
        if (deadline <= block.timestamp) revert DeadlineInPast();

        taskId = taskCount;
        taskCount++;

        tasks[taskId] = Task({
            poster: msg.sender,
            accepter: address(0),
            reward: msg.value,
            deadline: deadline,
            descriptionHash: descriptionHash,
            proofHash: "",
            status: Status.Open
        });

        emit TaskCreated(taskId, msg.sender, msg.value, deadline, descriptionHash);
    }

    /// @notice Accept an open task. Only Agent ID holders can accept.
    /// @dev One task, one accepter. Acceptance is final (no un-accept);
    ///      the poster can only refund after the deadline if no work is submitted.
    function acceptTask(uint256 taskId) external nonReentrant {
        Task storage task = tasks[taskId];
        if (task.status != Status.Open) revert InvalidStatus(taskId, task.status);
        if (!isAgentIdHolder(msg.sender)) revert NotAgentIdHolder(msg.sender);

        task.accepter = msg.sender;
        task.status = Status.Accepted;

        emit TaskAccepted(taskId, msg.sender);
    }

    /// @notice Submit work for an accepted task. Only the accepter.
    /// @param proofHash Off-chain proof reference (IPFS CID / link / hash).
    function submitWork(
        uint256 taskId,
        string calldata proofHash
    ) external nonReentrant {
        Task storage task = tasks[taskId];
        if (task.status != Status.Accepted) revert InvalidStatus(taskId, task.status);
        if (msg.sender != task.accepter) revert NotAccepter(msg.sender);

        task.proofHash = proofHash;
        task.status = Status.Submitted;

        emit WorkSubmitted(taskId, msg.sender, proofHash);
    }

    /// @notice Approve submitted work and release the escrow to the accepter.
    ///         Only the poster. No fee is deducted (PLATFORM_FEE_BPS = 0).
    function approve(uint256 taskId) external nonReentrant {
        Task storage task = tasks[taskId];
        if (task.status != Status.Submitted) revert InvalidStatus(taskId, task.status);
        if (msg.sender != task.poster) revert NotPoster(msg.sender);

        task.status = Status.Completed;
        uint256 reward = task.reward;

        emit TaskApproved(taskId, task.accepter, reward);

        (bool ok, ) = payable(task.accepter).call{value: reward}("");
        if (!ok) revert TransferFailed();
    }

    /// @notice Claim the escrow after the poster fails to approve submitted
    ///         work within the deadline + review window. Only the accepter.
    /// @dev Prevents funds being locked forever by an absent poster.
    function claimAfterReview(uint256 taskId) external nonReentrant {
        Task storage task = tasks[taskId];
        if (task.status != Status.Submitted) revert InvalidStatus(taskId, task.status);
        if (msg.sender != task.accepter) revert NotAccepter(msg.sender);
        if (block.timestamp < task.deadline + REVIEW_WINDOW) revert ReviewWindowNotPassed();

        task.status = Status.Completed;
        uint256 reward = task.reward;

        emit TaskClaimed(taskId, task.accepter, reward);

        (bool ok, ) = payable(task.accepter).call{value: reward}("");
        if (!ok) revert TransferFailed();
    }

    /// @notice Refund the escrow to the poster after the deadline, when no
    ///         work has been submitted (task still Open or Accepted).
    ///         Only the poster. Cannot refund submitted work — approve it,
    ///         or let the accepter claim after the review window.
    function refund(uint256 taskId) external nonReentrant {
        Task storage task = tasks[taskId];
        if (task.status != Status.Open && task.status != Status.Accepted) {
            revert InvalidStatus(taskId, task.status);
        }
        if (msg.sender != task.poster) revert NotPoster(msg.sender);
        if (block.timestamp < task.deadline) revert DeadlineNotReached();

        task.status = Status.Refunded;
        uint256 reward = task.reward;

        emit TaskRefunded(taskId, task.poster, reward);

        (bool ok, ) = payable(task.poster).call{value: reward}("");
        if (!ok) revert TransferFailed();
    }

    /// @notice Cancel an open task (no accepter yet) and refund the escrow.
    ///         Only the poster.
    function cancelTask(uint256 taskId) external nonReentrant {
        Task storage task = tasks[taskId];
        if (task.status != Status.Open) revert InvalidStatus(taskId, task.status);
        if (msg.sender != task.poster) revert NotPoster(msg.sender);

        task.status = Status.Cancelled;
        uint256 reward = task.reward;

        emit TaskCancelled(taskId, task.poster, reward);

        (bool ok, ) = payable(task.poster).call{value: reward}("");
        if (!ok) revert TransferFailed();
    }

    /// @notice Read a task's full details.
    function getTask(uint256 taskId) external view returns (Task memory) {
        return tasks[taskId];
    }
}
