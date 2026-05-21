# billing-stop.ps1
# Stop hook — runs when Claude is about to end the session.
# If billing is enabled and a legal matter is active, outputs a block decision
# so Claude is asked to run the billing panel before the session closes.
#
# Block format (Claude Code Stop hook API):
#   {"decision":"block","reason":"<message Claude will act on>"}
# Exit 0 in all cases — non-zero exit would surface a hook error, not a clean block.

$configPath = Join-Path $env:USERPROFILE ".claude\plugins\config\claude-for-legal\billing\CLAUDE.md"
if (-not (Test-Path $configPath)) { exit 0 }

$config = Get-Content $configPath -Raw -ErrorAction SilentlyContinue
if (-not $config -or $config -match '\[PLACEHOLDER\]') { exit 0 }
if ($config -notmatch 'Billing panel at end of session: enabled') { exit 0 }

# Scan installed legal plugins for an active matter
$plugins = @('commercial-legal','ip-legal','corporate-legal','ai-governance-legal','product-legal','litigation-legal')
$activeMatter = $null
$activePlugin = $null
foreach ($plugin in $plugins) {
    $pPath = Join-Path $env:USERPROFILE ".claude\plugins\config\claude-for-legal\$plugin\CLAUDE.md"
    if (Test-Path $pPath) {
        $pContent = Get-Content $pPath -Raw -ErrorAction SilentlyContinue
        # Match "Active matter: <slug>" but not "none" variants
        if ($pContent -match 'Active matter:\s*(?!none)(\S+)') {
            $activeMatter = $matches[1].Trim()
            $activePlugin = $plugin
            break
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
