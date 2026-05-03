# CLAUDE.md — primal

## README is a product artifact

The README is not documentation. It is the product's front door — the thing non-technical people read to decide if primal is worth installing. Treat it with the same care you would treat UI copy.

**Rules for any README change:**

- Every sentence must be readable by someone who has never used an AI coding agent. If you write "SessionStart hook injects system context," that is invisible to most users — translate it.
- Keep the Before/After examples as the first thing users see. They are the entire pitch.
- The install table must always be complete and accurate. One broken install command costs a real user.
- The feature matrix (What You Get table) must stay in sync with what the code actually does. If a feature ships or is removed, update the table.
- Preserve the voice. Primal speak in README on purpose. "Brain still big." "Cost go down forever." "One rock. That it." — this is intentional brand. Don't normalize it.
- Benchmark numbers come from real runs in `benchmarks/` and `evals/`. Never invent or round numbers. Re-run if in doubt.
- When adding a new agent to the install table, always add the corresponding detail block in the `<details>` section below it.
- Readability check before any README commit: would a non-programmer understand what this does and how to install it within 60 seconds of reading?

---

## Project overview

Primal makes AI coding agents respond in compressed, primal-style prose — cutting ~65-75% of output tokens while keeping full technical accuracy. It ships as a Claude Code plugin, a Codex plugin, a Gemini CLI extension, and as agent rule files for Cursor, Windsurf, Cline, Copilot, and 40+ others via `npx skills`.

---

## File structure and what owns what

### Single source of truth files — edit only these

| File | What it controls |
|------|-----------------|
| `skills/primal/SKILL.md` | Primal behavior: instinct levels, rules, wenyan mode, auto-clarity, persistence. This is the only file to edit for primal behavior changes. |
| `rules/primal-activate.md` | The body of the always-on auto-activation rule. Injected into Cursor, Windsurf, Cline, and Copilot rule files by CI. Edit here, not in the agent-specific copies. |
| `skills/primal-commit/SKILL.md` | Primal commit message behavior. Fully independent skill. |
| `skills/primal-review/SKILL.md` | Primal code review behavior. Fully independent skill. |
| `primal-compress/SKILL.md` | Compress sub-skill behavior. |

### Auto-generated / auto-synced — do not edit directly

These files are overwritten by CI on every push to main that touches the sources above. Edits here will be lost.

| File | Synced from |
|------|-------------|
| `primal/SKILL.md` | `skills/primal/SKILL.md` |
| `plugins/primal/skills/primal/SKILL.md` | `skills/primal/SKILL.md` |
| `.cursor/skills/primal/SKILL.md` | `skills/primal/SKILL.md` |
| `.windsurf/skills/primal/SKILL.md` | `skills/primal/SKILL.md` |
| `primal.skill` | ZIP of `skills/primal/` directory |
| `.clinerules/primal.md` | `rules/primal-activate.md` |
| `.github/copilot-instructions.md` | `rules/primal-activate.md` |
| `.cursor/rules/primal.mdc` | `rules/primal-activate.md` + Cursor frontmatter |
| `.windsurf/rules/primal.md` | `rules/primal-activate.md` + Windsurf frontmatter |

---

## CI sync workflow

`.github/workflows/sync-skill.yml` triggers on push to main when `skills/primal/SKILL.md` or `rules/primal-activate.md` changes.

What it does:
1. Copies `skills/primal/SKILL.md` to all agent-specific SKILL.md locations
2. Rebuilds `primal.skill` as a ZIP of `skills/primal/`
3. Rebuilds all agent rule files from `rules/primal-activate.md`, prepending the agent-specific frontmatter (Cursor needs `alwaysApply: true`, Windsurf needs `trigger: always_on`)
4. Commits and pushes with `[skip ci]` to avoid loops

The CI bot commits as `github-actions[bot]`. After a PR merges, wait for this workflow before declaring the release complete.

---

## Hook system (Claude Code)

Three hooks ship in `hooks/`. They communicate via a flag file at `~/.claude/.primal-active`.

```
SessionStart hook ──writes "full"──▶ ~/.claude/.primal-active ◀──writes mode── UserPromptSubmit hook
                                               │
                                            reads
                                               ▼
                                      primal-statusline.sh
                                     [PRIMAL] / [PRIMAL:ULTRA] / ...
```

### `hooks/primal-activate.js` — SessionStart hook

Runs once on every Claude Code session start. Does three things:
1. Writes `"full"` to `~/.claude/.primal-active` (creates it if missing)
2. Emits the primal ruleset as hidden stdout — Claude Code injects SessionStart hook stdout as system context, invisible to the user
3. Checks `~/.claude/settings.json` for an existing statusline config; if missing, appends a nudge telling Claude to offer setup on first interaction

Silent-fails on all filesystem errors — never blocks session start.

### `hooks/primal-mode-tracker.js` — UserPromptSubmit hook

Reads JSON from stdin (Claude Code passes prompt data as JSON on this hook event). Checks if the user prompt starts with `/primal`. If yes, writes the detected mode to the flag file:
- `/primal` → `full`
- `/primal lite` → `lite`
- `/primal ultra` → `ultra`
- `/primal wenyan` or `/primal wenyan-full` → `wenyan`
- `/primal wenyan-lite` → `wenyan-lite`
- `/primal wenyan-ultra` → `wenyan-ultra`
- `/primal-commit` → `commit`
- `/primal-review` → `review`
- `/primal-compress` → `compress`

Detects "stop primal" or "normal mode" in prompt and deletes the flag file.

### `hooks/primal-statusline.sh` — Statusline badge

Reads the flag file. Outputs a colored badge string for the Claude Code statusline:
- `full` or empty → `[PRIMAL]` (orange)
- anything else → `[PRIMAL:<MODE_UPPERCASED>]` (orange)

Configured in `~/.claude/settings.json` under `statusLine.command`.

### Hook installation

**Plugin install** — hooks are wired automatically by the plugin system.

**Standalone install** — `hooks/install.sh` (macOS/Linux) or `hooks/install.ps1` (Windows) copies the three hook files into `~/.claude/hooks/` and patches `~/.claude/settings.json` to register SessionStart and UserPromptSubmit hooks plus the statusline.

**Uninstall** — `hooks/uninstall.sh` / `hooks/uninstall.ps1` removes hook files and patches settings.json.

---

## Skill system

Skills are Markdown files with YAML frontmatter consumed by Claude Code's skill/plugin system and by `npx skills` for other agents.

### Instinct levels

Defined in `skills/primal/SKILL.md`. Six levels: `lite`, `full` (default), `ultra`, `wenyan-lite`, `wenyan-full`, `wenyan-ultra`. Level persists until changed or session ends.

### Auto-clarity rule

Primal drops to normal prose automatically for: security warnings, irreversible action confirmations, multi-step sequences where fragment ambiguity risks misread, and when the user is confused or repeats a question. Resumes after the clear part. This is defined in the skill and must be preserved in any SKILL.md edit.

### primal-compress

Sub-skill in `primal-compress/SKILL.md`. Takes a file path, compresses natural-language prose to primal style, writes the compressed version to the original path, and saves a human-readable backup at `<filename>.original.md`. Validation step checks that headings, code blocks, URLs, file paths, and commands are preserved exactly. Retries up to 2 times on validation failure with targeted patches only (no full recompression). Requires Python 3.10+.

### primal-commit / primal-review

Independent skills in `skills/primal-commit/SKILL.md` and `skills/primal-review/SKILL.md`. Both have their own `description` and `name` frontmatter fields so they load independently. primal-commit generates Conventional Commits format with ≤50 char subject. primal-review outputs one-line comments in `L<line>: <severity> <problem>. <fix>.` format.

---

## Agent distribution

How primal reaches each agent type:

| Agent | Mechanism | Auto-activates? |
|-------|-----------|----------------|
| Claude Code | Plugin (hooks + skills) or standalone hooks | Yes — SessionStart hook injects rules |
| Codex | Plugin in `plugins/primal/` with `hooks.json` | Yes — SessionStart hook |
| Gemini CLI | Extension with `GEMINI.md` context file | Yes — context file loads every session |
| Cursor | `.cursor/rules/primal.mdc` with `alwaysApply: true` | Yes — always-on rule |
| Windsurf | `.windsurf/rules/primal.md` with `trigger: always_on` | Yes — always-on rule |
| Cline | `.clinerules/primal.md` (auto-discovered) | Yes — Cline injects all .clinerules files |
| Copilot | `.github/copilot-instructions.md` + `AGENTS.md` | Yes — repo-wide instructions |
| Others | `npx skills add 8-BitBirdman/primal-instinct` | No — user must say `/primal` each session |

For agents without hook systems, the minimal always-on snippet lives in README under "Want it always on?" — keep it current with `rules/primal-activate.md`.

---

## Evals

`evals/` has a three-arm harness:
- `__baseline__` — no system prompt
- `__terse__` — `Answer concisely.`
- `<skill>` — `Answer concisely.\n\n{SKILL.md}`

The honest delta for any skill is **skill vs terse**, not skill vs baseline. Baseline comparison conflates the skill with generic terseness — that is cheating. The harness is designed to prevent this.

`llm_run.py` calls `claude -p --system-prompt ...` per (prompt, arm), saves output to `evals/snapshots/results.json`. `measure.py` reads the snapshot offline with tiktoken (OpenAI BPE — approximates Claude's tokenizer, ratios are meaningful, absolute numbers are approximate).

To add a skill: drop `skills/<name>/SKILL.md`. The harness auto-discovers it. To add a prompt: append a line to `evals/prompts/en.txt`.

Snapshots are committed to git. CI reads them without API calls. Only regenerate the snapshot when SKILL.md files or prompts change.

---

## Benchmarks

`benchmarks/` runs real prompts through the Claude API (not Claude Code CLI) and records raw token counts. Results are committed as JSON in `benchmarks/results/`. The benchmark table in README is generated from these results — update it when regenerating.

To reproduce: `uv run python benchmarks/run.py` (needs `ANTHROPIC_API_KEY` in `.env.local`).

---

## Key rules for agents working here

- Edit `skills/primal/SKILL.md` for behavior changes. Never edit synced copies.
- Edit `rules/primal-activate.md` for auto-activation rule changes. Never edit agent-specific rule copies.
- The README is the most important file in the repo for user-facing impact. Optimize it for non-technical readers. Preserve the primal voice.
- Benchmark and eval numbers must be real. Never fabricate or estimate them.
- The CI workflow commits back to main after merge. Account for this when checking branch state.
- Hook files must silent-fail on all filesystem errors. Never let a hook crash block session start.
