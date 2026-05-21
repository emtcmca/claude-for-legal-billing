# session-start.ps1
# UserPromptSubmit hook — writes a Unix timestamp on the first user message of each session.
# Subsequent messages in the same session find the file already present and do nothing.
# The billing-stop hook reads this file to compute elapsed session time.

$configPath = Join-Path $env:USERPROFILE ".claude\plugins\config\claude-for-legal\billing\CLAUDE.md"
if (-not (Test-Path $configPath)) { exit 0 }

$config = Get-Content $configPath -Raw -ErrorAction SilentlyContinue
if (-not $config -or $config -match '\[PLACEHOLDER\]') { exit 0 }

# Resolve data path from config; handle **Data path:** (bold) and plain Data path:
$dataPath = $null
if ($config -match '\*{0,2}Data path:\*{0,2}\s*(.+)') {
    $raw = ($matches[1].Trim()) -replace '^\*+', '' -replace '\*+$', ''
    $dataPath = ($raw -replace '^~', $env:USERPROFILE).Trim()
}
if (-not $dataPath) {
    $dataPath = Join-Path $env:USERPROFILE ".claude\plugins\config\claude-for-legal\billing"
}

$sessionFile = Join-Path $dataPath ".session-start"
if (-not (Test-Path $sessionFile)) {
    $null = New-Item -ItemType Directory -Path $dataPath -Force
    [DateTimeOffset]::UtcNow.ToUnixTimeSeconds() | Set-Content -Path $sessionFile -NoNewline
}

exit 0
