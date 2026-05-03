# primal — uninstaller for the SessionStart + UserPromptSubmit hooks (Windows PowerShell)
# Removes: hook files in ~/.claude/hooks, settings.json entries, and the flag file
# Usage: powershell -ExecutionPolicy Bypass -File hooks\uninstall.ps1
#   or:  irm https://raw.githubusercontent.com/8-BitBirdman/primal-instinct/main/hooks/uninstall.ps1 | iex
param()

$ErrorActionPreference = "Stop"

$ClaudeDir = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $env:USERPROFILE ".claude" }
$HooksDir = Join-Path $ClaudeDir "hooks"
$Settings = Join-Path $ClaudeDir "settings.json"
$FlagFile = Join-Path $ClaudeDir ".primal-active"

$HookFiles = @("package.json", "primal-config.js", "primal-activate.js", "primal-mode-tracker.js", "primal-stats.js", "primal-statusline.sh", "primal-statusline.ps1")

# Detect if primal is installed as a plugin
$PluginInstalled = $false
$PluginsDir = Join-Path $ClaudeDir "plugins"
if (Test-Path $PluginsDir) {
    $found = Get-ChildItem -Path $PluginsDir -Recurse -Filter "plugin.json" -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -match "primal" }
    if ($found) { $PluginInstalled = $true }
}

if ($PluginInstalled) {
    Write-Host "Primal appears to be installed as a Claude Code plugin." -ForegroundColor Yellow
    Write-Host "To uninstall the plugin, run:"
    Write-Host ""
    Write-Host "  claude plugin disable primal" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "This script removes standalone hooks (installed via install.ps1)."
    Write-Host "Continuing with standalone hook removal..."
    Write-Host ""
}

Write-Host "Uninstalling primal hooks..."

# 1. Remove hook files
$RemovedFiles = 0
foreach ($hook in $HookFiles) {
    $path = Join-Path $HooksDir $hook
    if (Test-Path $path) {
        Remove-Item $path -Force
        Write-Host "  Removed: $path"
        $RemovedFiles++
    }
}

if ($RemovedFiles -eq 0) {
    Write-Host "  No hook files found in $HooksDir"
}

# 2. Remove primal entries from settings.json (idempotent)
if (Test-Path $Settings) {
    if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
        Write-Host "WARNING: 'node' not found - cannot safely edit settings.json." -ForegroundColor Yellow
        Write-Host "         Remove the primal SessionStart and UserPromptSubmit"
        Write-Host "         entries from $Settings manually."
    } else {
        # Back up before editing
        Copy-Item $Settings "$Settings.bak" -Force

        # Pass path via env var — avoids injection if username contains a single quote.
        # Use a single-quote here-string so PowerShell does NOT expand $variables inside.
        $env:PRIMAL_SETTINGS = $Settings -replace '\\', '/'
        $env:PRIMAL_HOOKS_DIR = $HooksDir -replace '\\', '/'

        $nodeScript = @'
const fs = require('fs');
const settingsPath = process.env.PRIMAL_SETTINGS;
const hooksDir = process.env.PRIMAL_HOOKS_DIR;
const managedStatusLinePath = hooksDir + '/primal-statusline.ps1';
const settings = JSON.parse(fs.readFileSync(settingsPath, 'utf8'));

const isPrimalEntry = (entry) =>
  entry && entry.hooks && entry.hooks.some(h =>
    h.command && h.command.includes('primal')
  );

let removed = 0;
if (settings.hooks) {
  for (const event of ['SessionStart', 'UserPromptSubmit']) {
    if (Array.isArray(settings.hooks[event])) {
      const before = settings.hooks[event].length;
      settings.hooks[event] = settings.hooks[event].filter(e => !isPrimalEntry(e));
      removed += before - settings.hooks[event].length;
      if (settings.hooks[event].length === 0) {
        delete settings.hooks[event];
      }
    }
  }
  if (Object.keys(settings.hooks).length === 0) {
    delete settings.hooks;
  }
}

if (settings.statusLine) {
  const cmd = typeof settings.statusLine === 'string'
    ? settings.statusLine
    : (settings.statusLine.command || '');
  if (cmd.includes(managedStatusLinePath)) {
    delete settings.statusLine;
    console.log('  Removed primal statusLine from settings.json');
  }
}

fs.writeFileSync(settingsPath, JSON.stringify(settings, null, 2) + '\n');
console.log('  Removed ' + removed + ' primal hook entries from settings.json');
'@

        node -e $nodeScript

        # Clean up backup file left by installer
        if (Test-Path "$Settings.bak") {
            Remove-Item "$Settings.bak" -Force
            Write-Host "  Removed: $Settings.bak"
        }
    }
}

# 3. Remove flag file
if (Test-Path $FlagFile) {
    Remove-Item $FlagFile -Force
    Write-Host "  Removed: $FlagFile"
}

Write-Host ""
Write-Host "Done! Restart Claude Code to complete the uninstall." -ForegroundColor Green

# Guidance for other agents
Write-Host ""
Write-Host "Other agents:"
Write-Host "  npx skills remove primal      # Cursor, Windsurf, Cline, Copilot, etc."
Write-Host "  claude plugin disable primal   # Claude Code plugin"
Write-Host "  gemini extensions uninstall primal  # Gemini CLI"
