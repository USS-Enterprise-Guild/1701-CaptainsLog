# 1701 Captain's Log

World of Warcraft 1.12.1 addon for Turtle WoW that combines:

- `SuperWowCombatLogger` (combat log enrichment metadata)
- `Captain's Log` session control (auto start/stop + session markers)

The addon is designed for guild log collection and upload workflows.

## Requirements

- Turtle WoW (WoW client 1.12.1)
- [SuperWoW](https://github.com/balakethelock/SuperWoW) client patch
- [BigWigs](https://github.com/pepopo978/BigWigs) (optional — enables boss encounter tracking)

## Install

1. Copy this folder into `Interface/AddOns/` so the final path is:
`Interface/AddOns/1701-CaptainsLog/`
2. Start game and ensure **1701 Addons - Captains Log** is enabled.

If present, remove old addons:

- `AdvancedVanillaCombatLog`
- `AdvancedVanillaCombatLog_Helper`

## Addon Hierarchy (Load Order)

`1701-CaptainsLog.toc` loads files in this order:

1. `RPLLCollector.lua`
2. `SuperWowCombatLogger.lua`
3. `CaptainsLog.lua`

### What each file does

- `RPLLCollector.lua`
Creates the `RPLL` frame/event dispatcher if one does not already exist.

- `SuperWowCombatLogger.lua`
Adds extended combat metadata. If standalone `SuperWowCombatLogger` is already loaded, the bundled copy exits early.

- `CaptainsLog.lua`
Controls session lifecycle:
  - starts logging in configured raid zones
  - writes `SESSION_START` and `SESSION_END` markers
  - emits `RAID_LEADER` marker at session start
  - tracks boss encounters via BigWigs integration (`ENCOUNTER_START`, `ENCOUNTER_END: KILL`, `ENCOUNTER_END: WIPE`)
  - detects combat end and wipes (`COMBAT_END`, `WIPE`)
  - stops logging when leaving those zones
  - provides `/captainslog` manual toggle

## Behavior In Game

### Automatic mode

- Enter configured raid zone: combat logging starts.
- Leave configured raid zone: combat logging stops.
- Session markers are written into `Logs/WoWCombatLog.txt`.
- If BigWigs is installed, boss encounters are tracked automatically with pull, kill, and wipe markers.

Supported zones include vanilla raids and Turtle WoW custom raids, including:

- Karazhan Crypt
- Hyjal Summit
- Emerald Sanctum
- Lower Karazhan Halls
- Caverns of Time: Black Morass
- Gilneas City

### Manual mode

- `/captainslog` toggles logging immediately in your current zone.

## Upload Workflow

Use the scripts in `scripts/` after your raid:

- `upload.bat` (recommended): launcher for Windows users.
- `upload.ps1`: core script.

### What upload script does

1. Finds Turtle WoW path automatically by walking up from the addon folder (`.../Interface/AddOns/1701-CaptainsLog/scripts` -> `.../TurtleWoW`).
2. Falls back to common install paths.
3. Prompts for path only if auto-detection fails.
4. Reads `Logs/WoWCombatLog.txt`.
5. Creates zip in `Logs/uploads/` as `CaptainsLog-YYYY-MM-DD-HHmm.zip`.
6. Rotates original log to `WoWCombatLog-YYYY-MM-DD-HHmm.bak`.
7. Opens Explorer with the new zip selected for drag-and-drop upload.

## Why use `upload.bat` instead of double-clicking `.ps1`

On many Windows setups, PowerShell script execution is restricted by policy or signing settings.  
`upload.bat` handles this by launching PowerShell with a process-scoped bypass and runtime fallback (`powershell.exe` then `pwsh.exe`).

## Troubleshooting

- "SuperWoW required" message in game:
SuperWoW is missing or not active.

- No combat log file found:
Make sure logging started (`/captainslog`) and verify `Logs/WoWCombatLog.txt` exists.

- Upload script asks for path unexpectedly:
Confirm addon is installed under `.../TurtleWoW/Interface/AddOns/1701-CaptainsLog/`.

## Legacy Tools

`legacy/` contains original Python-based tooling from SuperWowCombatLogger for monkeylogs/turtlogs workflows.

## Credits

- **SuperWowCombatLogger** by [Shino/Pepopo](https://github.com/Pepopo/SuperWowCombatLogger)
- **SuperWoW** by [balakethelock](https://github.com/balakethelock/SuperWoW)
- **Captain's Log session management** by USS Enterprise Guild
