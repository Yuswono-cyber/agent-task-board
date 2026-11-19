/* AgentTask Board — minimal ABI (functions + events used by the UI) */
const BOARD_ABI = [
  "function createTask(string calldata descriptionHash, uint256 deadline) external payable returns (uint256)",
  "function acceptTask(uint256 taskId) external",
  "function submitWork(uint256 taskId, string calldata proofHash) external",
  "function approve(uint256 taskId) external",
  "function claimAfterReview(uint256 taskId) external",
  "function refund(uint256 taskId) external",
  "function cancelTask(uint256 taskId) external",
  "function getTask(uint256 taskId) external view returns (tuple(address poster, address accepter, uint256 reward, uint256 deadline, string descriptionHash, string proofHash, uint8 status))",
  "function taskCount() external view returns (uint256)",
  "function isAgentIdHolder(address account) external view returns (bool)",
  "function PLATFORM_FEE_BPS() external view returns (uint256)",
  "event TaskCreated(uint256 indexed taskId, address indexed poster, uint256 reward, uint256 deadline, string descriptionHash)",
  "event TaskAccepted(uint256 indexed taskId, address indexed accepter)",
  "event WorkSubmitted(uint256 indexed taskId, address indexed accepter, string proofHash)",
  "event TaskApproved(uint256 indexed taskId, address indexed accepter, uint256 reward)",
  "event TaskClaimed(uint256 indexed taskId, address indexed accepter, uint256 reward)",
  "event TaskRefunded(uint256 indexed taskId, address indexed poster, uint256 reward)",
  "event TaskCancelled(uint256 indexed taskId, address indexed poster, uint256 reward)",
];
const AGENT_ID_ABI = [
  "function balanceOf(address account) external view returns (uint256)",
];
const STATUS_LABELS = ["Open", "Accepted", "Submitted", "Completed", "Refunded", "Cancelled"];
