# Primal Hooks

These hooks are **bundled with the primal plugin** and activate automatically when the plugin is installed. No manual setup required.

If you installed primal standalone (without the plugin), you can use `bash hooks/install.sh` to wire them into your settings.json manually.

## What's Included

### `primal-activate.js` — SessionStart hook

- Runs once when Claude Code starts
- Writes `full` to `~/.claude/.primal-active` (flag file)
- Emits primal rules as hidden SessionStart context
- Detects missing statusline config and emits setup nudge (Claude will offer to help)

### `primal-mode-tracker.js` — UserPromptSubmit hook

- Fires on every user prompt, checks for `/primal` commands
- Writes the active mode to the flag file when a primal command is detected
- Supports: `full`, `lite`, `ultra`, `wenyan`, `wenyan-lite`, `wenyan-ultra`, `commit`, `review`, `compress`

### `primal-statusline.sh` / `primal-statusline.ps1` — Statusline badge script

- Reads `~/.claude/.primal-active` and outputs a colored badge
- Shows `[PRIMAL]`, `[PRIMAL:ULTRA]`, `[PRIMAL:WENYAN]`, etc.

## Statusline Badge

The statusline badge shows which primal mode is active directly in your Claude Code status bar.

**Plugin users:** If you do not already have a `statusLine` configured, Claude will detect that on your first session after install and offer to set it up for you. Accept and you're done.

If you already have a custom statusline, primal does not overwrite it and Claude stays quiet. Add the badge snippet to your existing script instead.

**Standalone users:** `install.sh` / `install.ps1` wires the statusline automatically if you do not already have a custom statusline. If you do, the installer leaves it alone and prints the merge note.

**Manual setup:** If you need to configure it yourself, add one of these to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash /path/to/primal-statusline.sh"
  }
}
```

```json
{
  "statusLine": {
    "type": "command",
    "command": "powershell -ExecutionPolicy Bypass -File C:\\path\\to\\primal-statusline.ps1"
  }
}
```

Replace the path with the actual script location (e.g. `~/.claude/hooks/` for standalone installs, or the plugin install directory for plugin installs).

**Custom statusline:** If you already have a statusline script, add this snippet to it:

```bash
primal_text=""
primal_flag="$HOME/.claude/.primal-active"
if [ -f "$primal_flag" ]; then
  primal_mode=$(cat "$primal_flag" 2>/dev/null)
  if [ "$primal_mode" = "full" ] || [ -z "$primal_mode" ]; then
    primal_text=$'\033[38;5;172m[PRIMAL]\033[0m'
  else
    primal_suffix=$(echo "$primal_mode" | tr '[:lower:]' '[:upper:]')
    primal_text=$'\033[38;5;172m[PRIMAL:'"${primal_suffix}"$']\033[0m'
  fi
fi
```

Badge examples:
- `/primal` → `[PRIMAL]`
- `/primal ultra` → `[PRIMAL:ULTRA]`
- `/primal wenyan` → `[PRIMAL:WENYAN]`
- `/primal-commit` → `[PRIMAL:COMMIT]`
- `/primal-review` → `[PRIMAL:REVIEW]`

## How It Works

```
SessionStart hook ──writes "full"──▶ ~/.claude/.primal-active ◀──writes mode── UserPromptSubmit hook
                                              │
                                           reads
                                              ▼
                                     Statusline script
                                    [PRIMAL:ULTRA] │ ...
```

SessionStart stdout is injected as hidden system context — Claude sees it, users don't. The statusline runs as a separate process. The flag file is the bridge.

## Uninstall

If installed via plugin: disable the plugin — hooks deactivate automatically.

If installed via `install.sh`:
```bash
bash hooks/uninstall.sh
```

Or manually:
1. Remove `~/.claude/hooks/primal-activate.js`, `~/.claude/hooks/primal-mode-tracker.js`, and the matching statusline script (`primal-statusline.sh` on macOS/Linux or `primal-statusline.ps1` on Windows)
2. Remove the SessionStart, UserPromptSubmit, and statusLine entries from `~/.claude/settings.json`
3. Delete `~/.claude/.primal-active`
