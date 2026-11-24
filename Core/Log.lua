-- RP Forge: chat output and the error log.
local _, RPF = ...

local PREFIX = "|cffd9a441RP Forge|r: "
local MAX_ERRORS = 50

local recentErrors = {}

function RPF.Print(message)
    DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. tostring(message))
end

function RPF.Debug(message)
    if RPF.db and RPF.db.settings.debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cff888888RP Forge debug:|r " .. tostring(message))
    end
end

-- Keep an error so it can be shown with /rpf errors and copied into a bug report.
function RPF.LogError(where, err)
    local entry = {
        at = time(),
        where = tostring(where),
        message = tostring(err),
        version = RPF.VERSION,
    }
    table.insert(recentErrors, 1, entry)
    while #recentErrors > MAX_ERRORS do
        table.remove(recentErrors)
    end
    if RPF.db then
        RPF.db.errors = recentErrors
    end
    if RPF.db and RPF.db.settings.debug then
        RPF.Print("|cffff6060error in " .. entry.where .. ":|r " .. entry.message)
    end
end

function RPF.GetErrors()
    return recentErrors
end

function RPF.ClearErrors()
    wipe(recentErrors)
end

-- Run a function and log any error instead of breaking the caller.
function RPF.SafeCall(where, fn, ...)
    local args, count = { ... }, select("#", ...)
    local ok, err = xpcall(function()
        return fn(unpack(args, 1, count))
    end, function(e)
        return tostring(e) .. "\n" .. (debugstack and debugstack(2, 6, 0) or "")
    end)
    if not ok then
        RPF.LogError(where, err)
    end
    return ok
end

-- Called by Core\Data.lua once saved data exists, so errors survive a reload.
function RPF.RestoreErrors(saved)
    if type(saved) ~= "table" then return end
    for i = #saved, 1, -1 do
        if type(saved[i]) == "table" then
            table.insert(recentErrors, 1, saved[i])
        end
    end
    while #recentErrors > MAX_ERRORS do
        table.remove(recentErrors)
    end
end
