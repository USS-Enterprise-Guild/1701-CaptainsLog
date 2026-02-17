# 1701 Captain's Log

Unified combat logging addon for USS Enterprise Guild on Turtle WoW. Bundles [SuperWowCombatLogger](https://github.com/Pepopo/SuperWowCombatLogger) with automatic session management.

## Requirements

- [SuperWoW](https://github.com/balakethelock/SuperWoW) client patch

## Installation

1. Download or clone this repo into your `Interface/AddOns/` folder so it becomes `Interface/AddOns/1701-CaptainsLog/`
2. Make sure SuperWoW is installed
3. Launch the game — the addon appears as **1701 Addons - Captains Log** in the addon list

Remove `AdvancedVanillaCombatLog` and `AdvancedVanillaCombatLog_Helper` from your addons folder if they exist.

## Features

### Combat Logging (SuperWowCombatLogger)

Enriches the WoW combat log with additional data for raid log analysis:

- Armory data and pet ownership tracking
- Totem spells credited to the casting shaman
- Pet autoattacks logged under their owners
- Tracks debuff casters (Faerie Fire, Sunder Armor, Curses, etc.)
- Heal-over-time cast tracking (Rejuvenation, Regrowth, Renew)

### Session Management (Captain's Log)

Automatically starts/stops combat logging when you enter/leave raid zones:

- Writes `SESSION_START` and `SESSION_END` markers to the combat log
- Supports all vanilla raids plus Turtle WoW custom raids (Karazhan Crypt, Hyjal Summit, Emerald Sanctum, etc.)
- Manual toggle: `/captainslog`

## Coexistence with Standalone SuperWowCombatLogger

If you have the standalone `SuperWowCombatLogger` addon installed separately, this addon detects it and skips loading its bundled copy. The session management (Captain's Log) still runs. You only need one or the other — this addon includes everything.

## Companion Scripts

The `scripts/` folder contains helpers for uploading combat logs to Discord:

- **`upload.bat`** — Double-click to run (Windows)
- **`upload.ps1`** — PowerShell script that zips the combat log, archives the original, and opens Explorer for drag-and-drop upload

### Legacy Upload Tools

The `legacy/` folder contains the original Python-based upload tools from SuperWowCombatLogger for use with monkeylogs/turtlogs.

## Credits

- **SuperWowCombatLogger** by [Shino/Pepopo](https://github.com/Pepopo/SuperWowCombatLogger)
- **SuperWoW** by [balakethelock](https://github.com/balakethelock/SuperWoW)
- **Captain's Log session management** by USS Enterprise Guild
