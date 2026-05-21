# billing-stop.ps1
# Stop hook — runs when Claude is about to end the session.
# Only blocks if: billing is enabled, a session timer is running (.session-start exists),
# and a legal matter is active. All three must be true — this prevents repeated blocking
# after the attorney has already logged or skipped time for this session.
#
# Block format (Claude Code Stop hook API):
#   {"decision":"block","reason":"<message Claude will act on>"}
# Exit 0 in all cases — non-zero exit surfaces a hook error, not a clean block.

$configPath = Join-Path $env:USERPROFILE ".claude\plugins\config\claude-for-legal\billing\CLAUDE.md"
if (-not (Test-Path $configPath)) { exit 0 }

$config = Get-Content $configPath -Raw -ErrorAction SilentlyContinue
if (-not $config -or $config -match '\[PLACEHOLDER\]') { exit 0 }

# Handle bold Markdown labels (**Billing panel at end of session:**) and plain labels
if ($config -notmatch '\*{0,2}Billing panel at end of session:\*{0,2}\s*enabled') { exit 0 }

# Resolve billing data path (handle **Data path:** and plain Data path:)
$dataPath = $null
if ($config -match '\*{0,2}Data path:\*{0,2}\s*(.+)') {
    $raw = ($matches[1].Trim()) -replace '^\*+', '' -replace '\*+$', ''
    $dataPath = ($raw -replace '^~', $env:USERPROFILE).Trim()
}
if (-not $dataPath) {
    $dataPath = Join-Path $env:USERPROFILE ".claude\plugins\config\claude-for-legal\billing"
}

# Only block if there is an active session timer.
# .session-start is created by session-start.ps1 on first message and deleted by
# billing-status after the attorney logs or skips. No file = already handled or
# timer not configured — either way, do not block.
$sessionFile = Join-Path $dataPath ".session-start"
if (-not (Test-Path $sessionFile)) { exit 0 }

# Scan installed legal plugins for an active matter
$plugins = @('commercial-legal','ip-legal','corporate-legal','ai-governance-legal','product-legal','litigation-legal')
$activeMatter = $null
$activePlugin = $null
foreach ($plugin in $plugins) {
    $pPath = Join-Path $env:USERPROFILE ".claude\plugins\config\claude-for-legal\$plugin\CLAUDE.md"
    if (Test-Path $pPath) {
        $pContent = Get-Content $pPath -Raw -ErrorAction SilentlyContinue
        # Handle **Active matter:** and plain Active matter:; exclude "none" variants
        if ($pContent -match '\*{0,2}Active matter:\*{0,2}\s*(.+)') {
            $slug = ($matches[1].Trim()) -replace '^\*+', '' -replace '\*+$', ''
            $slug = $slug.Split()[0]  # take only the first word (the slug itself)
            if ($slug -and $slug -notmatch '^none$') {
                $activeMatter = $slug
                $activePlugin = $plugin
                break
            }
        }
    }
}

if (-not $activeMatter) { exit 0 }

$output = [PSCustomObject]@{
    decision = "block"
    reason   = "Billing panel: matter '$activeMatter' ($activePlugin) is active. Run /billing:billing-status --session-end to log this session's time before closing."
} | ConvertTo-Json -Compress

Write-Output $output
exit 0
