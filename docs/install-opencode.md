# Primal Instinct — opencode Install Guide

Native integration for [opencode](https://opencode.ai). All 7 skills, 4 slash commands, and an always-on plugin hook.

## Prerequisites

- opencode installed (`brew install sst/tap/opencode` or see [opencode.ai/docs](https://opencode.ai/docs))
- Git
- Repo cloned somewhere persistent (e.g. `~/primal-instinct` or `~/Documents/opencode/primal-instinct`)

```bash
git clone https://github.com/8-BitBirdman/primal-instinct.git ~/primal-instinct
```

Replace `~/primal-instinct` with your actual path in the snippets below.

---

## 1. Register Skills (Global)

Edit `~/.config/opencode/opencode.json` (create if missing):

```json
{
  "$schema": "https://opencode.ai/config.json",
  "skills": {
    "paths": [
      "~/primal-instinct/skills",
      "~/primal-instinct/primal-compress"
    ]
  }
}
```

Skills loaded:

| Skill | Trigger |
|-------|---------|
| `primal` | "primal mode", "be brief", `/primal` |
| `primal-commit` | "write a commit", `/commit` |
| `primal-review` | "review this PR", `/review` |
| `primal-help` | "primal help", `/primal-help` |
| `primal-stats` | `/primal-stats` |
| `primal-compress` | `/primal:compress FILEPATH` |
| `primalcrew` | "delegate to subagent", "save context" |

---

## 2. Register Slash Commands (Global)

opencode auto-loads `*.toml` from `~/.config/opencode/command/`. Symlink the repo's commands so updates propagate via `git pull`:

```bash
mkdir -p ~/.config/opencode/command
ln -sf ~/primal-instinct/commands/primal.toml          ~/.config/opencode/command/
ln -sf ~/primal-instinct/commands/primal-commit.toml   ~/.config/opencode/command/
ln -sf ~/primal-instinct/commands/primal-review.toml   ~/.config/opencode/command/
ln -sf ~/primal-instinct/commands/primal-init.toml     ~/.config/opencode/command/
```

Available after restart: `/primal`, `/primal-commit`, `/primal-review`, `/primal-init`.

---

## 3. Always-On Mode (Optional but Recommended)

Two layers ensure primal stays active across every session and every agent.

### Layer A — Instructions File

Append to `~/.config/opencode/AGENTS.md`:

```markdown
## Primal Mode (Always-On, Default: ultra)

ACTIVE EVERY RESPONSE. Persist across turns. Off only on explicit "stop primal" / "normal mode".

Drop: articles (a/an/the), filler (just/really/basically/actually), pleasantries, hedging.
Fragments OK. Short synonyms. Technical terms exact. Code/errors/identifiers unchanged.
Ultra: abbreviate prose (DB/auth/cfg/req/res/fn/impl), arrows for causality (X → Y).

Pattern: `[thing] [action] [reason]. [next].`

Auto-clarity exceptions (drop primal temporarily):
- Security warnings, irreversible ops, destructive confirmations
- Multi-step where fragment order risks misread
- User asks clarification

Resume immediately after.
```

Reference it in `opencode.json`:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "instructions": ["~/.config/opencode/AGENTS.md"],
  "skills": { "paths": ["~/primal-instinct/skills", "~/primal-instinct/primal-compress"] }
}
```

### Layer B — Plugin Hook

Inject the rule into every chat's system message — covers empty projects, projects with overridden `instructions:`, subagents, and compaction. Create `~/.config/opencode/plugin/primal-always-on.js`:

```js
const PRIMAL_RULES = `[PRIMAL ULTRA — ALWAYS ON | system-injected]
Respond terse. Drop articles (a/an/the), filler (just/really/basically), hedging (might/could/perhaps), pleasantries.
Fragments OK. Short synonyms. Code, identifiers, error strings, paths: unchanged exact.
Abbreviate prose only (DB/auth/cfg/req/res/fn/impl). Arrows for causality (X → Y).
Pattern: [thing] [action] [reason]. [next].
Drop primal temporarily ONLY for: security warnings, irreversible/destructive ops, multi-step where fragment order risks misread, user asks to clarify.
Resume immediately after.
Off only on explicit "stop primal" / "normal mode" from the user.`

const inject = (existing) =>
  existing && existing.includes("PRIMAL ULTRA — ALWAYS ON")
    ? existing
    : existing
      ? `${PRIMAL_RULES}\n\n${existing}`
      : PRIMAL_RULES

export default async () => ({
  "chat.params": async (_input, output) => {
    output.system = inject(output.system)
  },
  "experimental.chat.system.transform": async (_input, output) => {
    if (typeof output.system === "string") {
      output.system = inject(output.system)
    } else if (Array.isArray(output.system)) {
      const hasPrimal = output.system.some(
        (p) => typeof p === "string" && p.includes("PRIMAL ULTRA — ALWAYS ON"),
      )
      if (!hasPrimal) output.system.unshift(PRIMAL_RULES)
    }
  },
})
```

opencode auto-discovers `.js`/`.ts` files in `~/.config/opencode/plugin/` — no config entry needed.

Dual-hook design ensures coverage of:
- Empty new projects with no local config
- Projects that override `instructions:` in their own `opencode.json`
- Subagent spawns (build/plan/general/explore)
- Compaction, title, and summary internal agents

---

## 4. Restart opencode

Config + plugins load once at startup. Quit and restart to activate.

```bash
# Verify skills loaded
opencode --log-level DEBUG 2>&1 | grep -i skill
```

---

## 5. Verify

```
> use ultra mode
```

Should respond like: "Ultra on." (no preamble, no closing).

```
> /primal lite
```

Switches level mid-session.

```
> stop primal
```

Disables for current session.

---

## Uninstall

```bash
rm -rf ~/.config/opencode/command/primal*.toml
rm ~/.config/opencode/plugin/primal-always-on.js
# Remove the "skills" + "Primal Mode" sections from opencode.json + AGENTS.md
```

---

## Troubleshooting

**Skills don't appear:** check `opencode --log-level DEBUG` for `ConfigInvalidError`. Most common cause: malformed `opencode.json`.

**Plugin not firing:** must export `default` as a function returning hooks object. Filename ends in `.js` or `.ts`.

**Always-on not triggering:** ensure both layers — AGENTS.md alone may be diluted by other instructions; plugin alone may be overridden by per-agent prompts.

**Symlink broken after `git pull`:** symlinks survive pulls. If you `mv` the repo, recreate them.

---

## File Layout Reference

```
~/.config/opencode/
├── opencode.json              # registers skills.paths + instructions
├── AGENTS.md                  # primal rules (always-on layer A)
├── command/
│   ├── primal.toml            # → repo
│   ├── primal-commit.toml     # → repo
│   ├── primal-review.toml     # → repo
│   └── primal-init.toml       # → repo
└── plugin/
    └── primal-always-on.js    # always-on layer B
```

Schema reference: <https://opencode.ai/config.json>
