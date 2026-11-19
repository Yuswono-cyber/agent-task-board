/* AgentTask Board frontend.
 * Connects ONLY via window.ethereum (your own browser wallet).
 * No QR login, no pairing codes, no session stored anywhere.
 * Every transaction is previewed here first, then confirmed by YOU in your wallet.
 */
let provider = null;
let signer = null;
let account = null;
let board = null;
let agentId = null;
let pendingTx = null; // {label, fn} — filled by the preview modal, run only on confirm

const $ = (id) => document.getElementById(id);
const short = (a) => (a ? a.slice(0, 6) + "…" + a.slice(-4) : "—");
const fmtBnb = (wei) => ethers.formatEther(wei);
const isHolder = async () => {
  if (!account) return false;
  try {
    return (await agentId.balanceOf(account)) > 0n;
  } catch {
    return false;
  }
};

function setStatus(msg) {
  $("previewStatus").textContent = msg;
}

async function connectWallet() {
  if (!window.ethereum) {
    alert("No browser wallet found. Install a wallet extension (e.g. MetaMask or a BNB Chain-compatible wallet) and try again.");
    return;
  }
  provider = new ethers.BrowserProvider(window.ethereum);
  const network = await provider.getNetwork();
  if (Number(network.chainId) !== CONFIG.chainId) {
    try {
      await window.ethereum.request({
        method: "wallet_switchEthereumChain",
        params: [{ chainId: "0x" + CONFIG.chainId.toString(16) }],
      });
    } catch (e) {
      alert("Please switch your wallet to " + CONFIG.chainName + " (chain ID " + CONFIG.chainId + ").");
      return;
    }
    provider = new ethers.BrowserProvider(window.ethereum);
  }
  const accounts = await provider.send("eth_requestAccounts", []);
  account = accounts[0];
  signer = await provider.getSigner();
  agentId = new ethers.Contract(CONFIG.agentIdAddress, AGENT_ID_ABI, provider);
  if (CONFIG.contractAddress) {
    board = new ethers.Contract(CONFIG.contractAddress, BOARD_ABI, signer);
  }
  $("accountLabel").textContent = "Connected: " + short(account);
  $("connectBtn").textContent = "Connected";
  await refreshAgentIdBadge();
  await loadTasks();
}

async function refreshAgentIdBadge() {
  const badge = $("agentIdBadge");
  if (!account) {
    badge.textContent = "Agent ID: unknown";
    badge.className = "badge unknown";
    return;
  }
  const holds = await isHolder();
  badge.textContent = holds ? "Agent ID: held ✓" : "Agent ID: not held — you can post, but not accept tasks";
  badge.className = "badge " + (holds ? "yes" : "no");
}

/* ---- Transaction preview: show first, send only after the user clicks Send ---- */
function showPreview(rows, label, fn) {
  $("previewTable").innerHTML = rows
    .map(([k, v]) => `<tr><td>${k}</td><td>${v}</td></tr>`)
    .join("");
  setStatus("");
  pendingTx = { label, fn };
  $("previewModal").classList.remove("hidden");
}

async function runPendingTx() {
  if (!pendingTx) return;
  const { label, fn } = pendingTx;
  pendingTx = null;
  setStatus("Waiting for you to confirm in your wallet…");
  try {
    const tx = await fn();
    setStatus(label + " sent: " + tx.hash + " — waiting for confirmation…");
    await tx.wait();
    setStatus(label + " confirmed ✓ (" + tx.hash + ")");
    setTimeout(() => $("previewModal").classList.add("hidden"), 1200);
    await loadTasks();
  } catch (e) {
    setStatus("Transaction not sent / failed: " + (e?.info?.error?.message || e?.message || e));
  }
}

function requireBoard() {
  if (!board) {
    alert("Contract not deployed/configured yet. Set contractAddress in frontend/config.js after deployment.");
    return false;
  }
  if (!signer) {
    alert("Connect your wallet first.");
    return false;
  }
  return true;
}

/* ---- Actions ---- */
async function createTask() {
  if (!requireBoard()) return;
  const desc = $("descInput").value.trim();
  const rewardStr = $("rewardInput").value.trim();
  const deadlineStr = $("deadlineInput").value;
  if (!desc || !rewardStr || !deadlineStr) {
    alert("Fill in description, reward and deadline.");
    return;
  }
  const reward = ethers.parseEther(rewardStr);
  const deadline = Math.floor(new Date(deadlineStr).getTime() / 1000);
  if (deadline <= Math.floor(Date.now() / 1000)) {
    alert("Deadline must be in the future.");
    return;
  }
  let gas = "—";
  try {
    gas = (await board.createTask.estimateGas(desc, deadline, { value: reward })).toString();
  } catch { /* estimate may fail before preview; wallet will show its own estimate */ }
  showPreview(
    [
      ["Action", "createTask — lock escrow"],
      ["To (contract)", CONFIG.contractAddress],
      ["Value (escrow)", rewardStr + " BNB"],
      ["Description", desc.slice(0, 120)],
      ["Deadline", new Date(deadline * 1000).toLocaleString()],
      ["Estimated gas", gas + " units (wallet shows the fee)"],
      ["Platform fee", "0%"],
    ],
    "Task created",
    () => board.createTask(desc, deadline, { value: reward })
  );
}

function taskAction(taskId, action, label, valueBnb = "0") {
  if (!requireBoard()) return;
  const fnMap = {
    accept: () => board.acceptTask(taskId),
    submit: () => board.submitWork(taskId, prompt("Work proof (link, IPFS CID or hash):") || ""),
    approve: () => board.approve(taskId),
    refund: () => board.refund(taskId),
    cancel: () => board.cancelTask(taskId),
    claim: () => board.claimAfterReview(taskId),
  };
  if (action === "submit") {
    const proof = prompt("Work proof (link, IPFS CID or hash):");
    if (!proof) return;
    showPreview(
      [["Action", "submitWork"], ["To (contract)", CONFIG.contractAddress], ["Task", "#" + taskId], ["Proof", proof.slice(0, 120)], ["Value", "0 BNB"]],
      "Work submitted",
      () => board.submitWork(taskId, proof)
    );
    return;
  }
  showPreview(
    [
      ["Action", label],
      ["To (contract)", CONFIG.contractAddress],
      ["Task", "#" + taskId],
      ["Value", valueBnb + " BNB"],
      ["From", account],
    ],
    label,
    fnMap[action]
  );
}

/* ---- Task list ---- */
function statusBadge(t) {
  return `<span class="status s${t.status}">${STATUS_LABELS[t.status]}</span>`;
}

function taskCard(t, id, holder, now) {
  const reward = fmtBnb(t.reward);
  const deadline = new Date(Number(t.deadline) * 1000).toLocaleString();
  const mine = account && t.poster.toLowerCase() === account.toLowerCase();
  const imAccepter = account && t.accepter.toLowerCase() === account.toLowerCase();
  let buttons = "";
  if (t.status === 0) {
    if (holder) buttons += `<button data-act="accept" data-id="${id}">Accept (Agent ID)</button>`;
    if (mine) buttons += `<button data-act="cancel" data-id="${id}">Cancel &amp; refund</button>`;
  } else if (t.status === 1) {
    if (imAccepter) buttons += `<button data-act="submit" data-id="${id}">Submit work</button>`;
    if (mine && now >= Number(t.deadline)) buttons += `<button data-act="refund" data-id="${id}">Refund (deadline passed)</button>`;
  } else if (t.status === 2) {
    if (mine) buttons += `<button data-act="approve" data-id="${id}">Approve &amp; release ${reward} BNB</button>`;
    if (imAccepter && now >= Number(t.deadline) + 3 * 86400)
      buttons += `<button data-act="claim" data-id="${id}">Claim escrow (review window passed)</button>`;
  }
  return `<article class="task">
    <div class="task-head"><strong>#${id} ${statusBadge(t)}</strong><span>${reward} BNB</span></div>
    <p>${escapeHtml(t.descriptionHash)}</p>
    <p class="meta">Poster: ${short(t.poster)} · Accepter: ${short(t.accepter)} · Deadline: ${deadline}</p>
    ${t.proofHash ? `<p class="meta">Proof: ${escapeHtml(t.proofHash)}</p>` : ""}
    <div class="row">${buttons || '<span class="hint">No actions available for you on this task.</span>'}</div>
  </article>`;
}

function escapeHtml(s) {
  return s.replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
}

async function loadTasks() {
  const list = $("taskList");
  if (!CONFIG.contractAddress) {
    $("deployNotice").classList.remove("hidden");
    list.innerHTML = '<p class="hint">No contract configured yet.</p>';
    return;
  }
  $("deployNotice").classList.add("hidden");
  $("contractLabel").innerHTML = `Contract: <a href="${CONFIG.bscScanBase}/address/${CONFIG.contractAddress}" target="_blank" rel="noopener">${short(CONFIG.contractAddress)}</a>`;
  if (!board) board = new ethers.Contract(CONFIG.contractAddress, BOARD_ABI, provider || new ethers.JsonRpcProvider(CONFIG.rpcUrl));
  try {
    const count = Number(await board.taskCount());
    $("taskCountLabel").textContent = count + " task(s)";
    if (count === 0) {
      list.innerHTML = '<p class="hint">No tasks yet — be the first to post one.</p>';
      return;
    }
    const holder = await isHolder();
    const now = Math.floor(Date.now() / 1000);
    let html = "";
    for (let i = count - 1; i >= 0; i--) {
      const t = await board.getTask(i);
      html += taskCard(t, i, holder, now);
    }
    list.innerHTML = html;
    list.querySelectorAll("button[data-act]").forEach((b) => {
      b.addEventListener("click", () => {
        const id = Number(b.dataset.id);
        const act = b.dataset.act;
        const labels = { accept: "Accept task", approve: "Approve & release escrow", refund: "Refund escrow", cancel: "Cancel task", claim: "Claim escrow" };
        taskAction(id, act, labels[act] || act);
      });
    });
  } catch (e) {
    list.innerHTML = `<p class="hint">Could not load tasks: ${escapeHtml(e?.message || String(e))}</p>`;
  }
}

$("connectBtn").addEventListener("click", connectWallet);
$("createBtn").addEventListener("click", createTask);
$("refreshBtn").addEventListener("click", loadTasks);
$("previewConfirmBtn").addEventListener("click", runPendingTx);
$("previewCancelBtn").addEventListener("click", () => {
  pendingTx = null;
  $("previewModal").classList.add("hidden");
});
$("agentIdLink").href = CONFIG.bscScanBase + "/token/" + CONFIG.agentIdAddress;
if (window.ethereum) {
  window.ethereum.on("accountsChanged", () => window.location.reload());
  window.ethereum.on("chainChanged", () => window.location.reload());
}
loadTasks();
