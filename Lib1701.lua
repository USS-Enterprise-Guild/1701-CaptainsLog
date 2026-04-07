--[[
    Lib1701 - Shared utilities for 1701 addons.

    This library is designed to be embedded into multiple addons.
    The highest available version wins.
]]

local LIB_VERSION = 7
if Lib1701 and Lib1701.version and Lib1701.version >= LIB_VERSION then
    return
end

Lib1701 = {
    version = LIB_VERSION,
}

local function get_global(name)
    if getglobal then
        return getglobal(name)
    end
    return _G[name]
end

local function set_global(name, value)
    if setglobal then
        setglobal(name, value)
        return
    end
    _G[name] = value
end

local function format_prefix(prefix, color)
    return "|c" .. color .. "[" .. prefix .. "]|r "
end

local function chat_message(prefix, color, text)
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage(format_prefix(prefix, color) .. text)
    end
end

function Lib1701.Trim(text)
    if not text then
        return ""
    end
    return string.gsub(text, "^%s*(.-)%s*$", "%1")
end

function Lib1701.Message(prefix, text)
    chat_message(prefix, "FF00FFFF", text)
end

function Lib1701.Success(prefix, text)
    chat_message(prefix, "FF00FF00", text)
end

function Lib1701.Warn(prefix, text)
    chat_message(prefix, "FFFFFF00", text)
end

function Lib1701.Error(prefix, text)
    chat_message(prefix, "FFFF6060", text)
end

function Lib1701.Debug(prefix, text)
    chat_message(prefix, "FF888888", text)
end

function Lib1701.Loaded(prefix, alias)
    local usage = "Loaded."
    if alias and alias ~= "" then
        usage = usage .. " " .. alias .. " help"
    end
    Lib1701.Message(prefix, usage)
end

function Lib1701.ParseCommand(message)
    local trimmed = Lib1701.Trim(message)
    if trimmed == "" then
        return "", ""
    end

    local _, _, command, rest = string.find(trimmed, "^(%S+)%s*(.*)$")
    return string.lower(command or ""), rest or ""
end

function Lib1701.RegisterSlash(spec)
    local aliases = spec.aliases or spec.commands or {}
    local id = spec.id
    local handler = spec.handler or spec.run

    if not id or id == "" then
        error("Lib1701.RegisterSlash requires spec.id")
    end
    if type(handler) ~= "function" then
        error("Lib1701.RegisterSlash requires spec.handler")
    end
    if table.getn(aliases) == 0 then
        error("Lib1701.RegisterSlash requires at least one slash alias")
    end

    if not SlashCmdList then
        SlashCmdList = {}
    end

    local upper_id = string.upper(id)
    for index, alias in ipairs(aliases) do
        set_global("SLASH_" .. upper_id .. index, alias)
    end

    SlashCmdList[upper_id] = function(message)
        local command, rest = Lib1701.ParseCommand(message)
        return handler(command, rest, message or "")
    end
end

function Lib1701.DeepCopy(value)
    if type(value) ~= "table" then
        return value
    end

    local copied = {}
    for key, nested in pairs(value) do
        copied[key] = Lib1701.DeepCopy(nested)
    end
    return copied
end

function Lib1701.EnsureDefaults(target, defaults)
    if type(target) ~= "table" or type(defaults) ~= "table" then
        return target
    end

    for key, default_value in pairs(defaults) do
        if target[key] == nil then
            target[key] = Lib1701.DeepCopy(default_value)
        elseif type(target[key]) == "table" and type(default_value) == "table" then
            Lib1701.EnsureDefaults(target[key], default_value)
        end
    end

    return target
end

function Lib1701.MigrateSavedVariables(canonical_name, legacy_names, defaults)
    local canonical = get_global(canonical_name)

    if type(legacy_names) ~= "table" then
        legacy_names = legacy_names and { legacy_names } or {}
    end

    if type(canonical) ~= "table" then
        canonical = nil
    end

    if not canonical then
        for _, legacy_name in ipairs(legacy_names) do
            local legacy = get_global(legacy_name)
            if type(legacy) == "table" then
                canonical = legacy
                break
            end
        end
    end

    if not canonical then
        canonical = {}
    end

    Lib1701.EnsureDefaults(canonical, defaults or {})
    set_global(canonical_name, canonical)

    for _, legacy_name in ipairs(legacy_names) do
        set_global(legacy_name, canonical)
    end

    return canonical
end

function Lib1701.CreateDialog(spec)
    local dialog = {
        name = spec.name,
        titleText = spec.title,
        width = spec.width,
        height = spec.height,
        movable = spec.movable ~= false,
        escCloses = spec.escCloses ~= false,
    }

    if not CreateFrame then
        return dialog
    end

    local frame = CreateFrame("Frame", spec.name, spec.parent or UIParent)
    table.insert(UISpecialFrames or {}, spec.name)
    frame:SetWidth(spec.width or 320)
    frame:SetHeight(spec.height or 240)
    frame:SetPoint(spec.point or "CENTER", 0, 0)
    frame:SetFrameStrata(spec.strata or "DIALOG")
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:SetMovable(spec.movable ~= false)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })

    if spec.movable ~= false then
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", function()
            this:StartMoving()
        end)
        frame:SetScript("OnDragStop", function()
            this:StopMovingOrSizing()
        end)
    end

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -16)
    title:SetText(spec.title or spec.name)
    frame.titleText = title

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -5, -5)
    close:SetScript("OnClick", function()
        frame:Hide()
    end)
    frame.closeButton = close

    if spec.escCloses ~= false and UISpecialFrames then
        table.insert(UISpecialFrames, spec.name)
    end

    return frame
end

-- Parse comma-separated values, trim whitespace from each.
function Lib1701.ParseCSV(input)
    local results = {}
    if not input or input == "" then
        return results
    end

    for item in string.gfind(input, "([^,]+)") do
        local trimmed = Lib1701.Trim(item)
        if trimmed ~= "" then
            table.insert(results, trimmed)
        end
    end

    return results
end

-- Extract name from a spell/item link, or return original text.
function Lib1701.ExtractLinkName(text)
    if not text then
        return nil
    end

    local _, _, name = string.find(text, "|h%[(.-)%]|h")
    if name then
        return name
    end

    _, _, name = string.find(text, "^%[(.-)%]$")
    if name then
        return name
    end

    return Lib1701.Trim(text)
end

function Lib1701.ParseInputList(input)
    if not input or input == "" then
        return {}
    end

    local normalized = string.gsub(input, "|r|c", "|r,|c")
    normalized = string.gsub(normalized, "%]%[", "],[")

    local items = Lib1701.ParseCSV(normalized)
    local results = {}

    for _, item in ipairs(items) do
        local name = Lib1701.ExtractLinkName(item)
        if name and name ~= "" then
            table.insert(results, name)
        end
    end

    return results
end

function Lib1701.MatchesFilter(name, filter)
    if not name then
        return false
    end
    if not filter or filter == "" then
        return true
    end
    return string.find(string.lower(name), string.lower(filter)) ~= nil
end

function Lib1701.IsExactMatch(name, filter)
    if not name or not filter or filter == "" then
        return false
    end
    return string.lower(name) == string.lower(filter)
end

function Lib1701.IsValidGroupName(name)
    if not name or name == "" then
        return false, "Group name cannot be empty"
    end

    if string.find(name, "|") or string.find(name, "%[") or string.find(name, "%]") then
        return false, "Group name cannot be an item or spell link"
    end

    if string.find(name, "[^%w%-_]") then
        return false, "Group name can only contain letters, numbers, hyphens, and underscores"
    end

    return true, nil
end

function Lib1701.IsExcluded(exclusions, name)
    if not exclusions or not name then
        return false
    end

    local lower_name = string.lower(name)
    for _, excluded in ipairs(exclusions) do
        if string.lower(excluded) == lower_name then
            return true
        end
    end

    return false
end

function Lib1701.AddExclusions(exclusions, filter, get_all_items_fn)
    if not exclusions or not get_all_items_fn then
        return {}, {}
    end

    local added = {}
    local already_excluded = {}

    for _, item in ipairs(get_all_items_fn()) do
        if Lib1701.MatchesFilter(item.name, filter) then
            if Lib1701.IsExcluded(exclusions, item.name) then
                table.insert(already_excluded, item.name)
            else
                table.insert(exclusions, item.name)
                table.insert(added, item.name)
            end
        end
    end

    return added, already_excluded
end

function Lib1701.RemoveExclusions(exclusions, filter)
    if not exclusions then
        return {}, {}
    end

    local removed = {}
    local indexes = {}

    for index, excluded in ipairs(exclusions) do
        if Lib1701.MatchesFilter(excluded, filter) then
            table.insert(indexes, index)
            table.insert(removed, excluded)
        end
    end

    for index = table.getn(indexes), 1, -1 do
        table.remove(exclusions, indexes[index])
    end

    if table.getn(removed) == 0 then
        return removed, { filter }
    end

    return removed, {}
end

function Lib1701.GetGroup(groups, group_name)
    if not groups or not group_name then
        return nil, nil
    end

    local lower_name = string.lower(group_name)
    for stored_name, members in pairs(groups) do
        if string.lower(stored_name) == lower_name then
            return members, stored_name
        end
    end

    return nil, nil
end

function Lib1701.AddToGroup(groups, group_name, filter, get_all_items_fn, exclusions)
    if not groups or not get_all_items_fn then
        return {}, {}, false
    end

    local added = {}
    local skipped = {}
    local members, stored_name = Lib1701.GetGroup(groups, group_name)
    local is_new_group = members == nil

    if is_new_group then
        stored_name = group_name
        groups[stored_name] = {}
        members = groups[stored_name]
    end

    for _, item in ipairs(get_all_items_fn()) do
        if Lib1701.MatchesFilter(item.name, filter) then
            local is_exact = Lib1701.IsExactMatch(item.name, filter)
            if not is_exact and Lib1701.IsExcluded(exclusions, item.name) then
                table.insert(skipped, item.name)
            else
                local already_in_group = false
                for _, member in ipairs(members) do
                    if string.lower(member) == string.lower(item.name) then
                        already_in_group = true
                        break
                    end
                end

                if not already_in_group then
                    table.insert(members, item.name)
                    table.insert(added, item.name)
                end
            end
        end
    end

    if is_new_group and table.getn(members) == 0 then
        groups[stored_name] = nil
        is_new_group = false
    end

    return added, skipped, is_new_group
end

function Lib1701.RemoveFromGroup(groups, group_name, filter)
    local removed = {}
    local members, stored_name = Lib1701.GetGroup(groups, group_name)

    if not members then
        return removed, false
    end

    local indexes = {}
    for index, member in ipairs(members) do
        if Lib1701.MatchesFilter(member, filter) then
            table.insert(indexes, index)
            table.insert(removed, member)
        end
    end

    for index = table.getn(indexes), 1, -1 do
        table.remove(members, indexes[index])
    end

    local deleted = false
    if table.getn(members) == 0 then
        groups[stored_name] = nil
        deleted = true
    end

    return removed, deleted
end
