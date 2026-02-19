-- RPLLCollector: Creates the RPLL frame for SuperWowCombatLogger.
-- If standalone SuperWowCombatLogger is loaded first (via OptionalDeps),
-- RPLL already exists and we skip creation.

if not RPLL then
    RPLL = CreateFrame("Frame", "RPLL")
    RPLL:SetScript("OnEvent", function()
        local handler = this[event]
        if type(handler) == "function" then
            handler(arg1, arg2, arg3, arg4)
        end
    end)
end
