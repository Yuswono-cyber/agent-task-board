// Sources flattened with hardhat v2.28.0 https://hardhat.org

// SPDX-License-Identifier: MIT

// File @openzeppelin/contracts/utils/introspection/IERC165.sol@v4.9.6

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


// File @openzeppelin/contracts/token/ERC721/IERC721.sol@v4.9.6

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}


// File @openzeppelin/contracts/security/ReentrancyGuard.sol@v4.9.6

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}


// File contracts/AgentTaskBoard.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.24;


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
