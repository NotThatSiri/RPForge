-- RP Forge: pick one of the game's icons (the same list the macro window offers), page by page.
-- UI.PickIcon(current, onPick) opens it; onPick(icon) gets the chosen icon, or nil for "no icon".
local _, RPF = ...
local UI = RPF.UI

local COLUMNS, ROWS = 10, 6
local PER_PAGE = COLUMNS * ROWS
local SIZE, GAP = 38, 6

local window
local icons
local page = 1

local function LoadIcons()
    if icons then return icons end
    icons = {}
    if GetMacroIcons then pcall(GetMacroIcons, icons) end
    if GetMacroItemIcons then pcall(GetMacroItemIcons, icons) end
    if #icons == 0 then
        -- Older clients: a few common icons so the picker is never empty.
        icons = { 134400, 132089, 133733, 134939, 135240, 136222, 132320, 133784, 134414, 132147 }
    end
    return icons
end

local function ShowPage(n)
    local list = LoadIcons()
    local pages = math.max(1, math.ceil(#list / PER_PAGE))
    page = math.max(1, math.min(pages, n))
    for i, b in ipairs(window.buttons) do
        local icon = list[(page - 1) * PER_PAGE + i]
        b:SetShown(icon ~= nil)
        if icon then b:SetIcon(icon) end
        UI.Backdrop(b, "panelAlt", (icon ~= nil and icon == window.current) and "accent" or "border")
    end
    window.pageLabel:SetText("Page " .. page .. " of " .. pages)
    window.prev:SetEnabled(page > 1)
    window.next:SetEnabled(page < pages)
end

local function Build()
    window = CreateFrame("Frame", "RPForgeIconPicker", UIParent, UI.BACKDROP_TEMPLATE)
    local width = COLUMNS * (SIZE + GAP) - GAP + 40
    window:SetSize(width, ROWS * (SIZE + GAP) - GAP + 130)
    window:SetPoint("CENTER")
    window:SetFrameStrata("FULLSCREEN_DIALOG")
    window:SetToplevel(true)
    window:EnableMouse(true)
    window:SetMovable(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", window.StartMoving)
    window:SetScript("OnDragStop", window.StopMovingOrSizing)
    tinsert(UISpecialFrames, "RPForgeIconPicker")
    UI.Backdrop(window, "window", "border")

    local title = UI.Text(window, "Choose an icon", 16, "accent")
    title:SetPoint("TOPLEFT", 20, -16)
    window.themeKey = UI.themeKey

    window.buttons = {}
    for i = 1, PER_PAGE do
        local b = UI.IconButton(window, SIZE)
        local column, row = (i - 1) % COLUMNS, math.floor((i - 1) / COLUMNS)
        b:SetPoint("TOPLEFT", 20 + column * (SIZE + GAP), -50 - row * (SIZE + GAP))
        b:SetScript("OnClick", function(self)
            window:Hide()
            if window.onPick then RPF.SafeCall("pick icon", window.onPick, self.value) end
        end)
        b:SetScript("OnLeave", function(self)
            UI.Backdrop(self, "panelAlt", self.value == window.current and "accent" or "border")
        end)
        window.buttons[i] = b
    end

    window.prev = UI.Button(window, "<", 36, 26)
    window.prev:SetPoint("BOTTOMLEFT", 20, 18)
    window.prev:SetScript("OnClick", function() ShowPage(page - 1) end)
    window.next = UI.Button(window, ">", 36, 26)
    window.next:SetPoint("LEFT", window.prev, "RIGHT", 6, 0)
    window.next:SetScript("OnClick", function() ShowPage(page + 1) end)
    window.pageLabel = UI.Text(window, "", 11, "muted")
    window.pageLabel:SetPoint("LEFT", window.next, "RIGHT", 12, 0)

    local cancel = UI.Button(window, "Cancel", 90, 26)
    cancel:SetPoint("BOTTOMRIGHT", -20, 18)
    cancel:SetScript("OnClick", function() window:Hide() end)
    local none = UI.Button(window, "No icon", 90, 26)
    none:SetPoint("RIGHT", cancel, "LEFT", -8, 0)
    none:SetScript("OnClick", function()
        window:Hide()
        if window.onPick then RPF.SafeCall("pick icon", window.onPick, nil) end
    end)

    window:EnableMouseWheel(true)
    window:SetScript("OnMouseWheel", function(_, delta) ShowPage(page - delta) end)
end

function UI.PickIcon(current, onPick)
    if window and window.themeKey ~= UI.themeKey then
        window:Hide()
        window = nil
    end
    if not window then Build() end
    window.current, window.onPick = current, onPick
    -- Open on the page that holds the current icon.
    local start = 1
    for i, icon in ipairs(LoadIcons()) do
        if icon == current then start = math.ceil(i / PER_PAGE) break end
    end
    ShowPage(start)
    window:Show()
    window:Raise()
end
