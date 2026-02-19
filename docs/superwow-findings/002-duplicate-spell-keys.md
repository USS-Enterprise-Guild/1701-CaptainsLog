# SuperWowCombatLogger Finding: Duplicate Keys in Spell/Consume Maps

## Scope

- File: `SuperWowCombatLogger.lua`
- Example duplicate locations:
  - `SuperWowCombatLogger.lua:151` (`11597`)
  - `SuperWowCombatLogger.lua:158` (`11722`)
  - `SuperWowCombatLogger.lua:844` (`45024`)
- Ownership: upstream data table maintenance (not patched in this repo wrapper pass)

## Issue

Several Lua table literals contain repeated numeric keys in static spell/consume lookup maps.

In Lua, later assignments overwrite earlier ones for the same key.

## Impact

Runtime impact is usually low when duplicate entries map to the same value:

- No functional change in lookup result (last value wins, often same text).

But maintenance impact is real:

- Misleads reviewers into thinking multiple distinct mappings exist.
- Makes manual updates error-prone.
- Can hide accidental value changes if a later duplicate diverges.
- Increases noise in diffs and audits.

## Likely Fix

Data hygiene pass:

1. Deduplicate repeated numeric keys in `trackedSpells`, `dbConsumes`, and related static maps.
2. Keep a single authoritative entry per spell/item ID.
3. If intentional overrides are needed, place them in an explicit override section with a comment.

Optional hardening:

- Add a lightweight pre-commit/check script that flags duplicate numeric keys in Lua table literals for these files.

## Risk / Compatibility

- Very low if deduplication preserves current final value per key.
- Recommended to verify by comparing before/after map outputs for changed keys.
