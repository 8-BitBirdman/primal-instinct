# 🥩 The Primal Bible

> **The source of truth for the Lithic Protocol and Primal Instinct ecosystem.**

---

## 🏗️ Architecture Matrix

| Component | Repository / Path | Purpose |
| :--- | :--- | :--- |
| **Primal Instinct** | `.` | Core engine, installer, and agent rule-reinforcement logic. |
| **Primal Core** | `skills/primal/` | The master prompt behavior (`SKILL.md`). Syncs to all agents. |
| **Primal Hooks** | `hooks/` | Stealth monitoring and per-turn behavioral anchoring. |
| **Primal-Mem** | `primal-compress/` | Context compression for `CLAUDE.md` and larger markdown repos. |
| **PrimalCrew** | `skills/primalcrew/` | Specialized agent personalities for delegated sub-tasks. |
| **Primal-Shrink** | `mcp-servers/` | MCP server to prune tool descriptions in the agent catalog. |

---

## 🛠️ The Sync Engine

The project uses a GitHub Actions workflow (`.github/workflows/sync-skill.yml`) to ensure behavioral consistency across all entry points.

### Propagated Paths:
- **Claude Code**: `skills/primal/SKILL.md` → `primal/SKILL.md` (and zipped into `primal.skill`)
- **Cursor**: `skills/primal/SKILL.md` → `.cursor/rules/primal.mdc` (with frontmatter)
- **Windsurf**: `skills/primal/SKILL.md` → `.windsurf/rules/primal.md` (with frontmatter)
- **Cline**: `skills/primal/SKILL.md` → `.clinerules/primal.md`
- **GitHub Copilot**: `skills/primal/SKILL.md` → `.github/copilot-instructions.md`

---

## 🍖 Behavioral Anchoring (The Stealth Hook)

Standard prompt engineering fails over long sessions because the model "drifts" back to its base training (verbosity). Primal Instinct solves this via **Stealth Hooks**:

### 1. The Anchor Hook
Every turn, the `UserPromptSubmit` hook injects a high-priority semantic sentinel. It's designed to be "invisible" to the human user but "loud" to the model's attention mechanism.

### 2. The Context Watchdog
If the agent output exceeds a certain token threshold or contains specific "hedging phrases" (e.g., "I'd be happy to"), the next turn's hook automatically escalates the Instinct Level to **Ultra** to snap the model back into compliance.

---

## 📊 Tokenomics

| Content Type | Redundancy Ratio | Primal Compression |
| :--- | :--- | :--- |
| Natural Language | High | **~75%** |
| Documentation | Medium | **~60%** |
| Code Logic | Zero | **0%** (Safety Lock) |
| Configuration | Low | **~20%** |

---

## 🧩 Extension System

Primal is designed to be modular. You can add specialized "Sub-Instincts" to `skills/`.

- **`/primal:commit`**: Specialized for ultra-terse, conventional commit messages.
- **`/primal:review`**: Targeted code reviews that only highlight critical logic failures.
- **`/primal:stats`**: Displays your lifetime token savings in the statusline.

---

## 📜 Contribution Guidelines

1.  **Lithic First**: All documentation must be written in the Primal style. No filler.
2.  **Verify Sync**: After changing `skills/primal/SKILL.md`, run `tests/verify_repo.py` to ensure local parity before pushing.
3.  **No Code Mangling**: Never suggest a compression rule that affects code blocks (`` ``` ``). Logic is sacred.

---

<p align="center">
  <b>Raw logic. No filler. Defy the weight of words.</b>
</p>
