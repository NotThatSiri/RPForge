-- RP Forge: pick one of the game's icons, with a search by name.
-- UI.PickIcon(current, onPick) opens it; onPick(icon) gets the chosen icon (a file ID), or nil for "no icon".
--
-- Icon names come from LibRPMedia (in Libs), which lists every icon in the WoW Forever client.
-- Without it, the picker falls back to the macro window's icons, without names or search.
local _, RPF = ...
local UI = RPF.UI

local COLUMNS, ROWS = 10, 6
local PER_PAGE = COLUMNS * ROWS
local SIZE, GAP = 38, 6

local window
local all       -- every icon: { id = fileID, name = "inv_sword_04" or nil }
local shown     -- the icons matching the search
local page = 1

local function Media()
    return LibStub and LibStub:GetLibrary("LibRPMedia-1.2", true)
end

local function LoadIcons()
    if all then return all end
    all = {}
    local media = Media()
    if media and media:GetNumIcons() > 0 then
        for i = 1, media:GetNumIcons() do
            all[#all + 1] = { id = media:GetIconIDByIndex(i), name = media:GetIconNameByIndex(i) }
        end
    else
        local ids = {}
        if GetMacroIcons then pcall(GetMacroIcons, ids) end
        if GetMacroItemIcons then pcall(GetMacroItemIcons, ids) end
        for _, id in ipairs(ids) do all[#all + 1] = { id = id } end
    end
    return all
end

local function ShowPage(n)
    local pages = math.max(1, math.ceil(#shown / PER_PAGE))
    page = math.max(1, math.min(pages, n))
    for i, b in ipairs(window.buttons) do
        local icon = shown[(page - 1) * PER_PAGE + i]
        b.iconInfo = icon
        b:SetShown(icon ~= nil)
        if icon then b:SetIcon(icon.id) end
        UI.Backdrop(b, "panelAlt", (icon and icon.id == window.current) and "accent" or "border")
    end
    window.pageLabel:SetText(#shown == 0 and "No icons match." or ("Page " .. page .. " of " .. pages .. "   (" .. #shown .. " icons)"))
    window.prev:SetEnabled(page > 1)
    window.next:SetEnabled(page < pages)
end

-- Words in the search must all appear in the icon's name ("sword fire" finds fiery swords).
local function Filter(text)
    local words = {}
    for word in strlower(text or ""):gmatch("%S+") do words[#words + 1] = word end
    if #words == 0 then
        shown = LoadIcons()
    else
        shown = {}
        for _, icon in ipairs(LoadIcons()) do
            local name = icon.name and strlower(icon.name)
            if name then
                local ok = true
                for _, word in ipairs(words) do
                    if not name:find(word, 1, true) then ok = false break end
                end
                if ok then shown[#shown + 1] = icon end
            end
        end
    end
    ShowPage(1)
end

local function Build()
    window = CreateFrame("Frame", "RPForgeIconPicker", UIParent, UI.BACKDROP_TEMPLATE)
    local width = COLUMNS * (SIZE + GAP) - GAP + 40
    window:SetSize(width, ROWS * (SIZE + GAP) - GAP + 160)
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
    window.themeKey = UI.themeKey

    local title = UI.Text(window, "Choose an icon", 16, "accent")
    title:SetPoint("TOPLEFT", 20, -16)

    local searchable = Media() ~= nil and LoadIcons()[1] ~= nil and LoadIcons()[1].name ~= nil
    window.search = UI.EditBox(window, width - 40, 26)
    window.search:SetPoint("TOPLEFT", 20, -44)
    window.searchHint = UI.Text(window.search, searchable and "Search, for example: sword, fire, book" or "Search isn't available", 11, "muted")
    window.searchHint:SetPoint("LEFT", 8, 0)
    window.search:SetEnabled(searchable)
    -- Wait a moment after typing stops, so long lists don't filter on every key.
    local pending
    window.search:SetScript("OnTextChanged", function(self, userInput)
        window.searchHint:SetShown(self:GetText() == "")
        if not userInput then return end
        if pending then pending:Cancel() end
        pending = C_Timer.NewTimer(0.25, function() Filter(self:GetText()) end)
    end)
    window.search:SetScript("OnEnterPressed", function(self)
        if pending then pending:Cancel() end
        Filter(self:GetText())
        self:ClearFocus()
    end)

    window.buttons = {}
    for i = 1, PER_PAGE do
        local b = UI.IconButton(window, SIZE)
        local column, row = (i - 1) % COLUMNS, math.floor((i - 1) / COLUMNS)
        b:SetPoint("TOPLEFT", 20 + column * (SIZE + GAP), -82 - row * (SIZE + GAP))
        b:SetScript("OnClick", function(self)
            window:Hide()
            if window.onPick then RPF.SafeCall("pick icon", window.onPick, self.value) end
        end)
        b:SetScript("OnEnter", function(self)
            UI.Backdrop(self, "panelAlt", "accent")
            if self.iconInfo and self.iconInfo.name then
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                GameTooltip:AddLine(self.iconInfo.name, 1, 1, 1)
                GameTooltip:Show()
            end
        end)
        b:SetScript("OnLeave", function(self)
            UI.Backdrop(self, "panelAlt", (self.iconInfo and self.iconInfo.id == window.current) and "accent" or "border")
            GameTooltip:Hide()
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
    window.search:SetText("")
    window.searchHint:Show()
    shown = LoadIcons()
    -- Open on the page that holds the current icon.
    local start = 1
    for i, icon in ipairs(shown) do
        if icon.id == current then start = math.ceil(i / PER_PAGE) break end
    end
    ShowPage(start)
    window:Show()
    window:Raise()
end
