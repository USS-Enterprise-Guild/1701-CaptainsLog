# Captain's Log - Upload Helper
# Finds the TurtleWoW combat log, zips it, archives the original,
# and opens Explorer so you can drag the zip into #combat-logs on Discord.

$CommonPaths = @(
    "C:\Games\TurtleWoW",
    "C:\TurtleWoW",
    "D:\Games\TurtleWoW",
    "$env:PROGRAMFILES\TurtleWoW"
)

$WowPath = $null
foreach ($path in $CommonPaths) {
    if (Test-Path "$path\Logs") {
        $WowPath = $path
        break
    }
}

if (-not $WowPath) {
    $WowPath = Read-Host "Enter your TurtleWoW installation path"
    if (-not (Test-Path "$WowPath\Logs")) {
        Write-Host "Logs folder not found at $WowPath\Logs" -ForegroundColor Red
        exit 1
    }
}

$LogFile = "$WowPath\Logs\WoWCombatLog.txt"

if (-not (Test-Path $LogFile)) {
    Write-Host "Combat log not found at $LogFile" -ForegroundColor Red
    Write-Host "Make sure you have combat logging enabled (use the Captain's Log addon or /combatlog)." -ForegroundColor Yellow
    exit 1
}

$DateStr = Get-Date -Format "yyyy-MM-dd-HHmm"
$OutDir = "$WowPath\Logs\uploads"
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$ZipPath = "$OutDir\CaptainsLog-$DateStr.zip"
Compress-Archive -Path $LogFile -DestinationPath $ZipPath -Force
Write-Host "Zipped to: $ZipPath" -ForegroundColor Green

# Archive the original log so a fresh one starts next session
$BackupPath = "$WowPath\Logs\WoWCombatLog-$DateStr.bak"
Move-Item $LogFile $BackupPath
Write-Host "Original log archived to: $BackupPath" -ForegroundColor Yellow

# Open Explorer with the zip selected for easy drag-and-drop
explorer.exe /select, $ZipPath

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Drag the zip into #combat-logs on Discord!" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
