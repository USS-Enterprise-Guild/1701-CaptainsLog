# Captain's Log - Upload Helper
# Finds the TurtleWoW combat log, zips it, archives the original,
# and opens Explorer so you can drag the zip into #combat-logs on Discord.

function Get-DetectedWowPath {
    $current = Resolve-Path -LiteralPath $PSScriptRoot

    while ($current) {
        $currentPath = $current.Path
        $logsPath = Join-Path $currentPath "Logs"
        if (Test-Path -LiteralPath $logsPath) {
            return $currentPath
        }

        $parentPath = Split-Path -Parent $currentPath
        if ([string]::IsNullOrEmpty($parentPath) -or $parentPath -eq $currentPath) {
            break
        }
        $current = Resolve-Path -LiteralPath $parentPath
    }

    return $null
}

function Test-LogsFolderPath {
    param(
        [string]$BasePath
    )

    if ([string]::IsNullOrWhiteSpace($BasePath)) {
        return $false
    }

    if ($BasePath -match '^[A-Za-z]:') {
        $driveName = $BasePath.Substring(0, 1)
        if (-not (Get-PSDrive -Name $driveName -ErrorAction SilentlyContinue)) {
            return $false
        }
    }

    try {
        $logsPath = Join-Path $BasePath "Logs"
        return Test-Path -LiteralPath $logsPath
    }
    catch {
        return $false
    }
}

$CommonPaths = @(
    "C:\Games\TurtleWoW",
    "C:\TurtleWoW",
    "D:\Games\TurtleWoW"
)

if (-not [string]::IsNullOrWhiteSpace($env:PROGRAMFILES)) {
    $CommonPaths += (Join-Path $env:PROGRAMFILES "TurtleWoW")
}

$WowPath = Get-DetectedWowPath
if (-not $WowPath) {
    foreach ($path in $CommonPaths) {
        if (Test-LogsFolderPath $path) {
            $WowPath = $path
            break
        }
    }
}

if (-not $WowPath) {
    $WowPath = Read-Host "Enter your TurtleWoW installation path"
    if (-not (Test-LogsFolderPath $WowPath)) {
        $DisplayLogsPath = if ([string]::IsNullOrWhiteSpace($WowPath)) {
            "Logs"
        }
        else {
            "$($WowPath.TrimEnd('\\', '/'))\\Logs"
        }

        Write-Host "Logs folder not found at $DisplayLogsPath" -ForegroundColor Red
        exit 1
    }
}

$LogFile = Join-Path $WowPath "Logs\WoWCombatLog.txt"

if (-not (Test-Path -LiteralPath $LogFile)) {
    Write-Host "Combat log not found at $LogFile" -ForegroundColor Red
    Write-Host "Make sure you have combat logging enabled (use the Captain's Log addon or /combatlog)." -ForegroundColor Yellow
    exit 1
}

$DateStr = Get-Date -Format "yyyy-MM-dd-HHmm"
$OutDir = Join-Path $WowPath "Logs\uploads"
[System.IO.Directory]::CreateDirectory($OutDir) | Out-Null

$ZipPath = Join-Path $OutDir "CaptainsLog-$DateStr.zip"
$TempZip = Join-Path $env:TEMP "CaptainsLog-$DateStr.zip"
Compress-Archive -LiteralPath $LogFile -DestinationPath $TempZip -Force
[System.IO.File]::Move($TempZip, $ZipPath)
Write-Host "Zipped to: $ZipPath" -ForegroundColor Green

# Archive the original log so a fresh one starts next session
$BackupPath = Join-Path $WowPath "Logs\WoWCombatLog-$DateStr.bak"
[System.IO.File]::Move($LogFile, $BackupPath)
Write-Host "Original log archived to: $BackupPath" -ForegroundColor Yellow

# Open Explorer with the zip selected for easy drag-and-drop
Start-Process explorer.exe -ArgumentList "/select,`"$ZipPath`""

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Drag the zip into #combat-logs on Discord!" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
