# SuperWowCombatLogger Finding: `strsplit` Tail Parsing Bug

## Scope

- File: `SuperWowCombatLogger.lua`
- Relevant lines: `SuperWowCombatLogger.lua:108`, `SuperWowCombatLogger.lua:121`, `SuperWowCombatLogger.lua:1117`
- Ownership: upstream SuperWowCombatLogger logic (not patched in this repo wrapper pass)

## Issue

The local helper `strsplit(pString, pPattern)` builds tokens using `strfind`, but the tail-token logic is incorrect:

- Current code at tail:
  - `cap = strfind(pString, last_end)`
- `string.find` returns numeric indices, not the substring token.
- Result: when adding the final token, the function can push a number (or wrong value) instead of the expected string segment.

## Impact

`strsplit` is used by `RPLL:DeepSubString(...)`:

- `SuperWowCombatLogger.lua:1117`
- That routine performs fuzzy matching on name-like text.

Likely symptoms:

- False negatives in partial/subtoken matching.
- Occasional false positives from malformed tail values.
- Hard-to-reproduce matching inconsistencies, especially when the last word/token is the important discriminator.

This does not appear to be a crash-level bug, but it can degrade data quality and matching reliability.

## Likely Fix

Replace tail extraction with substring extraction from `last_end` to end-of-string.

Example correction pattern:

```lua
if last_end <= strlen(pString) then
    cap = strsub(pString, last_end)
    table.insert(Table, cap)
end
```

Alternative:

- Replace the custom splitter entirely with a safer tokenization loop using `string.gmatch`.

## Risk / Compatibility

- Low behavioral risk.
- The fix is localized to helper parsing logic.
- Expected net effect is improved consistency in `DeepSubString` matching with no format changes to emitted combat log lines.
