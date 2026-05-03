---
name: primal-help
description: >
  Quick-reference card for all primal modes, skills, and commands.
  One-shot display, not a persistent mode. Trigger: /primal-help,
  "primal help", "what primal commands", "how do I use primal".
---

# Primal Instinct Help

Display this reference card when invoked. One-shot — do NOT change mode, write flag files, or persist anything. Output in primal style.

## Modes

| Mode | Trigger | What change |
|------|---------|-------------|
| **Lite** | `/primal lite` | Drop filler. Keep sentence structure. |
| **Full** | `/primal` | Drop articles, filler, pleasantries, hedging. Fragments OK. Default. |
| **Ultra** | `/primal ultra` | Extreme compression. Bare fragments. Tables over prose. |
| **Wenyan-Lite** | `/primal wenyan-lite` | Classical Chinese style, light compression. |
| **Wenyan-Full** | `/primal wenyan` | Full 文言文. Maximum classical terseness. |
| **Wenyan-Ultra** | `/primal wenyan-ultra` | Extreme. Ancient scholar on a budget. |

Mode stick until changed or session end.

## Skills

| Skill | Trigger | What it do |
|-------|---------|-----------|
| **primal-commit** | `/primal-commit` | Terse commit messages. Conventional Commits. ≤50 char subject. |
| **primal-review** | `/primal-review` | One-line PR comments: `L42: bug: user null. Add guard.` |
| **primal-compress** | `/primal:compress <file>` | Compress .md files to primal prose. Saves ~46% input tokens. |
| **primal-help** | `/primal-help` | This card. |

## Deactivate

Say "stop primal" or "normal mode". Resume anytime with `/primal`.

## Configure Default Mode

Default mode = `full`. Change it:

**Environment variable** (highest priority):
```bash
export PRIMAL_DEFAULT_MODE=ultra
```

**Config file** (`~/.config/primal/config.json`):
```json
{ "defaultMode": "lite" }
```

Set `"off"` to disable auto-activation on session start. User can still activate manually with `/primal`.

Resolution: env var > config file > `full`.

## More

Full docs: https://github.com/8-BitBirdman/primal-instinct
