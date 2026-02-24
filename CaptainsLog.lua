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
local managedSession = false

local LoggingCombat = LoggingCombat
local GetRealZoneText = GetRealZoneText
local date = date

-- BigWigs encounter tracking (optional - only if BigWigs is loaded)
local engagedBoss = nil

if AceLibrary and AceLibrary:HasInstance("AceEvent-2.0") then
    local AceEvent = AceLibrary("AceEvent-2.0")
    local bwHandler = {}
    AceEvent:embed(bwHandler)

    function bwHandler:BigWigs_RecvSync(sync, rest, nick)
        if not managedSession then return end
        local ts = date("%Y-%m-%d %H:%M:%S")
        if sync == "BossEngaged" and rest then
            engagedBoss = rest
            CombatLogAdd("ENCOUNTER_START: " .. rest .. " " .. ts)
        elseif sync == "BossDeath" and rest then
            engagedBoss = nil
            CombatLogAdd("ENCOUNTER_END: KILL " .. rest .. " " .. ts)
        end
    end

    function bwHandler:BigWigs_RebootModule(moduleName)
        if not managedSession or not engagedBoss then return end
        local ts = date("%Y-%m-%d %H:%M:%S")
        CombatLogAdd("ENCOUNTER_END: WIPE " .. engagedBoss .. " " .. ts)
        engagedBoss = nil
    end

    bwHandler:RegisterEvent("BigWigs_RecvSync")
    bwHandler:RegisterEvent("BigWigs_RebootModule")
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Captain's Log]|r BigWigs detected, encounter tracking enabled")
end

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
    ["Emerald Sanctum"] = true,
    ["Lower Karazhan Halls"] = true,
    ["Tower of Karazhan"] = true,
}

local function StartLogging(zone)
    LoggingCombat(1)
    managedSession = true
    CombatLogAdd("SESSION_START: " .. zone .. " " .. date("%Y-%m-%d %H:%M:%S"))
    if GetRaidRosterInfo then
        for i = 1, GetNumRaidMembers() do
            local name, rank = GetRaidRosterInfo(i)
            if rank == 2 and name then
                CombatLogAdd("RAID_LEADER: " .. name .. " " .. date("%Y-%m-%d %H:%M:%S"))
                break
            end
        end
    end
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Captain's Log]|r Combat logging started for " .. zone)
end

local function StopLogging()
    CombatLogAdd("SESSION_END: " .. date("%Y-%m-%d %H:%M:%S"))
    LoggingCombat(0)
    managedSession = false
    DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[Captain's Log]|r Combat logging stopped")
end

local function SyncZoneLogging()
    local zone = GetRealZoneText()
    if not zone or zone == "" then
        return
    end

    if RAID_ZONES[zone] then
        if not managedSession then
            StartLogging(zone)
        end
    elseif managedSession then
        StopLogging()
    end
end

local function OnCombatEnd()
    if not managedSession then
        return
    end

    local total = GetNumRaidMembers()
    if total == 0 then
        return
    end

    local alive = 0
    local counted = {}
    for i = 1, total do
        local unit = "raid" .. i
        if not UnitIsDeadOrGhost(unit) then
            alive = alive + 1
        end
        counted[UnitName(unit)] = true
    end

    -- Include the player if not already counted via raid iteration
    if not counted[UnitName("player")] then
        total = total + 1
        if not UnitIsDeadOrGhost("player") then
            alive = alive + 1
        end
    end

    local ts = date("%Y-%m-%d %H:%M:%S")
    CombatLogAdd("COMBAT_END: " .. alive .. "/" .. total .. " " .. ts)

    if alive <= 3 or alive / total < 0.10 then
        CombatLogAdd("WIPE: " .. ts)
    end
end

frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")

frame:SetScript("OnEvent", function()
    if event == "PLAYER_REGEN_ENABLED" then
        OnCombatEnd()
    else
        SyncZoneLogging()
    end
end)

-- Slash command: /captainslog — manually toggle combat logging
SLASH_CAPTAINSLOG1 = "/captainslog"
SlashCmdList["CAPTAINSLOG"] = function()
    if managedSession then
        StopLogging()
    else
        local zone = GetRealZoneText()
        if not zone or zone == "" then
            zone = "Unknown Zone"
        end
        StartLogging(zone)
    end
end
