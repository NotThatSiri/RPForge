-- RP Forge: /rpf commands.
local _, RPF = ...

local commands, order = {}, {}

-- Other modules add their own commands with RPF.AddCommand.
function RPF.AddCommand(name, description, handler)
    if not commands[name] then order[#order + 1] = name end
    commands[name] = { description = description, handler = handler }
end

RPF.AddCommand("help", "List commands", function()
    RPF.Print("commands:")
    for _, name in ipairs(order) do
        DEFAULT_CHAT_FRAME:AddMessage("  |cffffffff/rpf " .. name .. "|r - " .. commands[name].description)
    end
end)

RPF.AddCommand("version", "Show the RP Forge version", function()
    RPF.Print("version " .. RPF.VERSION .. "  (data " .. RPF.SCHEMA_VERSION .. ", messages " .. RPF.PROTOCOL_VERSION .. ")")
end)

RPF.AddCommand("errors", "Show the last errors (/rpf errors clear to empty the list)", function(rest)
    if rest == "clear" then
        RPF.ClearErrors()
        RPF.Print("error list cleared.")
        return
    end
    local errors = RPF.GetErrors()
    if #errors == 0 then
        RPF.Print("no errors logged.")
        return
    end
    RPF.Print(#errors .. " error(s) logged. Most recent first:")
    for i = 1, math.min(5, #errors) do
        local e = errors[i]
        local firstLine = e.message:match("^[^\n]*")
        DEFAULT_CHAT_FRAME:AddMessage(string.format("  |cffff6060%s|r %s (%s, v%s)", date("%H:%M", e.at), firstLine, e.where, e.version or "?"))
    end
end)

RPF.AddCommand("debug", "Turn debug messages on or off", function()
    RPF.db.settings.debug = not RPF.db.settings.debug
    RPF.Print("debug messages " .. (RPF.db.settings.debug and "on." or "off."))
end)

SLASH_RPFORGE1 = "/rpf"
SLASH_RPFORGE2 = "/rpforge"
SlashCmdList.RPFORGE = function(input)
    local name, rest = strtrim(input or ""):match("^(%S*)%s*(.-)$")
    name = (name or ""):lower()
    if name == "" then name = commands.open and "open" or "help" end
    local command = commands[name]
    if not command then
        RPF.Print("unknown command '" .. name .. "'. Type /rpf help.")
        return
    end
    if not RPF.db then
        RPF.Print("still loading, try again in a moment.")
        return
    end
    RPF.SafeCall("/rpf " .. name, command.handler, rest)
end
