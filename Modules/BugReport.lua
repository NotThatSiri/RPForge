-- RP Forge: bug reports.
--
--   * Catches Lua errors that come from RP Forge's own files, even outside RPF.SafeCall (for example
--     in a button's click script). Errors from other addons are left alone.
--   * The first error in a session prints one hint in chat pointing to /rpf bug.
--   * /rpf bug (or the button on About) opens a window with everything a bug report needs, ready to copy
--     into the bug report form on GitHub.
local _, RPF = ...
local UI = RPF.UI

local ISSUE_URL = "https://github.com/NotThatSiri/RPForge/issues/new?template=bug_report.yml"
local OUR_FILES = "AddOns[\\/]" .. RPF.ADDON .. "[\\/]"
local MAX_ERRORS_IN_REPORT = 10
local STACK_LINES = 6

local hintedThisSession = false
local window

-- Catch our errors ----------------------------------------------------------------

local function Hint()
    if hintedThisSession or (RPF.db and RPF.db.settings.debug) then return end
    hintedThisSession = true
    RPF.Print("something went wrong. Type " .. UI.ColorCode("accent") .. "/rpf bug|r to send a report.")
end

RPF.Listen("ERROR_LOGGED", Hint)

local previousHandler = geterrorhandler()
seterrorhandler(function(message, ...)
    local text = tostring(message)
    local stack = debugstack and debugstack(3, 12, 0) or ""
    if text:find(OUR_FILES) or stack:find(OUR_FILES) then
        -- Our error: keep it for the bug report, then let the game (or BugSack and friends) show it as usual.
        pcall(RPF.LogError, "lua error", text .. "\n" .. stack)
    end
    if previousHandler then return previousHandler(message, ...) end
end)

-- Build the report ------------------------------------------------------------------

local function AddonList()
    local count = (C_AddOns and C_AddOns.GetNumAddOns or GetNumAddOns)()
    local getInfo = (C_AddOns and C_AddOns.GetAddOnInfo) or GetAddOnInfo
    local isLoaded = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded
    local getMetadata = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    local loaded = {}
    for i = 1, count do
        local name = getInfo(i)
        if name and isLoaded(name) and name ~= RPF.ADDON then
            local version = getMetadata(name, "Version")
            loaded[#loaded + 1] = version and (name .. " " .. version) or name
        end
    end
    table.sort(loaded)
    return loaded
end

local function FirstLines(text, count)
    local lines = {}
    for line in tostring(text):gmatch("[^\n]+") do
        lines[#lines + 1] = line
        if #lines >= count then break end
    end
    return lines
end

function RPF.BuildBugReport()
    local out = {}
    local function Add(line) out[#out + 1] = line end

    local gameVersion, build, buildDate, interface = GetBuildInfo()
    local settings = RPF.db.settings
    Add("RP Forge " .. RPF.VERSION .. " (data " .. RPF.SCHEMA_VERSION .. ", messages " .. RPF.PROTOCOL_VERSION .. ")")
    Add("Game " .. tostring(gameVersion) .. " (build " .. tostring(build) .. ", " .. tostring(buildDate) .. ", interface " .. tostring(interface) .. "), " .. tostring(GetLocale()))
    Add("Theme " .. tostring(settings.theme) .. ", player messages " .. (settings.network and "on" or "off") .. ", debug " .. (settings.debug and "on" or "off"))
    Add("")

    local addons = AddonList()
    Add("Other addons loaded (" .. #addons .. "): " .. (#addons > 0 and table.concat(addons, ", ") or "none"))
    Add("")

    local errors = RPF.GetErrors()
    if #errors == 0 then
        Add("Errors: none logged.")
    else
        Add("Errors (" .. #errors .. ", newest first, up to " .. MAX_ERRORS_IN_REPORT .. "):")
        for i = 1, math.min(#errors, MAX_ERRORS_IN_REPORT) do
            local e = errors[i]
            Add("")
            Add(string.format("[%s] %s, v%s", date("%Y-%m-%d %H:%M", e.at or 0), tostring(e.where), tostring(e.version or "?")))
            for _, line in ipairs(FirstLines(e.message, STACK_LINES)) do
                Add("  " .. line)
            end
        end
    end
    return table.concat(out, "\n")
end

-- The window ------------------------------------------------------------------------

local function Build()
    window = CreateFrame("Frame", "RPForgeBugReport", UIParent, UI.BACKDROP_TEMPLATE)
    window:SetSize(640, 470)
    window:SetPoint("CENTER")
    window:SetFrameStrata("DIALOG")
    window:SetToplevel(true)
    window:SetClampedToScreen(true)
    window:SetMovable(true)
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", window.StartMoving)
    window:SetScript("OnDragStop", window.StopMovingOrSizing)
    UI.Backdrop(window, "window", "border")
    if not tContains(UISpecialFrames, "RPForgeBugReport") then
        table.insert(UISpecialFrames, "RPForgeBugReport")
    end

    local title = UI.Text(window, "Report a bug", 18, "accent")
    title:SetPoint("TOPLEFT", 20, -18)
    local steps = UI.Text(window,
        "1. Click in the box and press Ctrl+A, then Ctrl+C to copy everything.\n" ..
        "2. Open the bug report form (link below) in your browser and paste it under \"Errors\".\n" ..
        "3. Add what you were doing when it went wrong.", 11, "text")
    steps:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
    steps:SetPoint("RIGHT", window, "RIGHT", -20, 0)
    steps:SetSpacing(3)

    local box = UI.Panel(window, "panelAlt", "border")
    box:SetPoint("TOPLEFT", 20, -110)
    box:SetPoint("BOTTOMRIGHT", -20, 92)
    local scroll = CreateFrame("ScrollFrame", nil, box, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 8, -8)
    scroll:SetPoint("BOTTOMRIGHT", -28, 8)
    local text = CreateFrame("EditBox", nil, scroll)
    text:SetMultiLine(true)
    text:SetAutoFocus(false)
    text:SetFont(UI.FONT, 11, "")
    local c = UI.Color("text")
    text:SetTextColor(c[1], c[2], c[3], 1)
    text:SetWidth(560)
    text:SetScript("OnEscapePressed", function() window:Hide() end)
    -- Keep the report as it was built if someone types into the box.
    text:SetScript("OnTextChanged", function(self, userInput)
        if userInput and window.report then self:SetText(window.report) end
    end)
    scroll:SetScrollChild(text)
    window.text = text

    local selectAll = UI.Button(window, "Select all", 110, 26, "primary")
    selectAll:SetPoint("BOTTOMRIGHT", -20, 30)
    selectAll:SetScript("OnClick", function()
        window.text:SetFocus()
        window.text:HighlightText()
    end)

    local closeButton = UI.Button(window, "Close", 80, 26)
    closeButton:SetPoint("RIGHT", selectAll, "LEFT", -8, 0)
    closeButton:SetScript("OnClick", function() window:Hide() end)

    -- The same X as the main window, top right.
    local x = CreateFrame("Button", nil, window)
    x:SetSize(28, 28)
    x:SetPoint("TOPRIGHT", -8, -8)
    x.icon = x:CreateTexture(nil, "ARTWORK")
    x.icon:SetTexture("Interface\\AddOns\\" .. RPF.ADDON .. "\\Media\\Icons\\Close")
    x.icon:SetPoint("CENTER")
    x.icon:SetSize(14, 14)
    local function TintX(key)
        local col = UI.Color(key)
        x.icon:SetVertexColor(col[1], col[2], col[3], 1)
    end
    TintX("muted")
    x:SetScript("OnEnter", function() TintX("bad") end)
    x:SetScript("OnLeave", function() TintX("muted") end)
    x:SetScript("OnClick", function() window:Hide() end)

    local linkLabel = UI.Text(window, "BUG REPORT FORM (click, then Ctrl+C to copy)", 10, "muted")
    linkLabel:SetPoint("BOTTOMLEFT", 20, 62)
    -- The link box fills the space up to the buttons, so it can never cover them.
    local link = UI.EditBox(window, 100, 26)
    link:SetPoint("BOTTOMLEFT", 20, 30)
    link:SetPoint("RIGHT", closeButton, "LEFT", -12, 0)
    link:SetText(ISSUE_URL)
    link:SetCursorPosition(0)
    link:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    link:SetScript("OnTextChanged", function(self, userInput)
        if userInput then self:SetText(ISSUE_URL); self:HighlightText() end
    end)
end

function RPF.OpenBugReport()
    -- Rebuild after a theme change so the window matches.
    if window and window.themeKey ~= UI.themeKey then
        window:Hide()
        window = nil
    end
    if not window then Build() end
    window.themeKey = UI.themeKey
    window.report = RPF.BuildBugReport()
    window.text:SetText(window.report)
    window.text:SetCursorPosition(0)
    window:Show()
    window:Raise()
end

RPF.AddCommand("bug", "Open a bug report to copy into the form on GitHub", function()
    RPF.OpenBugReport()
end)
