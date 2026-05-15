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

Inject the rule into every chat's system message. Create `~/.config/opencode/plugin/primal-always-on.js`:

```js
const PRIMAL_RULES = `[PRIMAL ULTRA — ALWAYS ON]
Respond terse. Drop articles, filler, hedging, pleasantries. Fragments OK.
Abbreviate prose (DB/auth/cfg/fn/impl). Arrows for causality (X → Y).
Code, identifiers, errors, paths: unchanged exact.
Pattern: [thing] [action] [reason]. [next].
Drop primal only for: security warnings, irreversible ops, multi-step where order risks misread. Resume after.
Off only on explicit "stop primal" / "normal mode".`

export default async () => ({
  "chat.params": async (_input, output) => {
    output.system = output.system ? `${PRIMAL_RULES}\n\n${output.system}` : PRIMAL_RULES
  },
})
```

opencode auto-discovers `.js`/`.ts` files in `~/.config/opencode/plugin/` — no config entry needed.

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
