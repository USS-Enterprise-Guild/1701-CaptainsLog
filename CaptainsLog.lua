-- Captain's Log
-- Auto-manages combat logging for USS Enterprise Guild raid sessions
-- Part of 1701-CaptainsLog unified addon
-- Requires: SuperWoW (for CombatLogAdd)

-- Guard: SuperWoW must be present for session markers
if not CombatLogAdd then
    DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[Captain's Log]|r SuperWoW required for session management.")
    return
end

local frame = CreateFrame("Frame")
local isLogging = false

-- Raid zones: vanilla + Turtle WoW custom content
local RAID_ZONES = {
    -- Vanilla raids
    ["Molten Core"] = true,
    ["Blackwing Lair"] = true,
    ["Onyxia's Lair"] = true,
    ["Temple of Ahn'Qiraj"] = true,
    ["Ruins of Ahn'Qiraj"] = true,
    ["Naxxramas"] = true,
    -- Turtle WoW custom raids
    ["Karazhan Crypt"] = true,
    ["Hyjal Summit"] = true,
    ["Emerald Sanctum"] = true,
    ["Lower Karazhan Halls"] = true,
    ["Caverns of Time: Black Morass"] = true,
    ["Gilneas City"] = true,
}

local function StartLogging(zone)
    LoggingCombat(1)
    isLogging = true
    CombatLogAdd("SESSION_START: " .. zone .. " " .. date("%Y-%m-%d %H:%M:%S"))
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Captain's Log]|r Combat logging started for " .. zone)
end

local function StopLogging()
    CombatLogAdd("SESSION_END: " .. date("%Y-%m-%d %H:%M:%S"))
    LoggingCombat(0)
    isLogging = false
    DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[Captain's Log]|r Combat logging stopped")
end

frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

frame:SetScript("OnEvent", function()
    local zone = GetRealZoneText()
    if RAID_ZONES[zone] and not isLogging then
        StartLogging(zone)
    elseif not RAID_ZONES[zone] and isLogging then
        StopLogging()
    end
end)

-- Slash command: /captainslog — manually toggle combat logging
SLASH_CAPTAINSLOG1 = "/captainslog"
SlashCmdList["CAPTAINSLOG"] = function()
    if isLogging then
        StopLogging()
    else
        local zone = GetRealZoneText()
        StartLogging(zone)
    end
end
