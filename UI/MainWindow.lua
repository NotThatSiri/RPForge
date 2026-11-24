-- RP Forge: the main window. Features add pages with RPF.UI.RegisterPage; the side navigation lists them.
local _, RPF = ...
local UI = RPF.UI

local WIDTH, HEIGHT = 980, 640
local TITLE_HEIGHT = 32
local NAV_WIDTH = 190

local pages, pageOrder = {}, {}
local window, nav, content
local navButtons = {}
local currentKey

-- page = { key, title, section, order, hidden, build = function(frame) end, onShow = function(frame) end }
-- build runs once, the first time the page is opened. onShow runs every time it is shown.
-- hidden pages are not listed in the side menu (Settings opens from the cogwheel instead).
function UI.RegisterPage(page)
    assert(page.key and page.title and page.build, "RegisterPage needs key, title and build")
    page.section = page.section or "RP Forge"
    page.order = page.order or 100
    pages[page.key] = page
    pageOrder[#pageOrder + 1] = page
    table.sort(pageOrder, function(a, b)
        if a.section ~= b.section then return (a.sectionOrder or 100) < (b.sectionOrder or 100) end
        if a.order ~= b.order then return a.order < b.order end
        return a.title < b.title
    end)
    if window then UI.RebuildNav() end
end

local function SavePosition()
    local point, _, relativePoint, x, y = window:GetPoint(1)
    RPF.db.window = { point = point, relativePoint = relativePoint, x = x, y = y }
end

local function RestorePosition()
    local saved = RPF.db.window
    window:ClearAllPoints()
    if saved and saved.point then
        window:SetPoint(saved.point, UIParent, saved.relativePoint or saved.point, saved.x or 0, saved.y or 0)
    else
        window:SetPoint("CENTER")
    end
end

local function NavButton(page)
    local b = CreateFrame("Button", nil, nav, UI.BACKDROP_TEMPLATE)
    b:SetHeight(28)
    b.page = page
    b.label = UI.Text(b, page.title, 12, "text")
    b.label:SetPoint("LEFT", 14, 0)
    b.bar = b:CreateTexture(nil, "ARTWORK")
    b.bar:SetTexture(UI.WHITE)
    b.bar:SetWidth(3)
    b.bar:SetPoint("TOPLEFT")
    b.bar:SetPoint("BOTTOMLEFT")
    local a = UI.Color("accent")
    b.bar:SetVertexColor(a[1], a[2], a[3], 1)

    function b:Refresh()
        local selected = currentKey == self.page.key
        local hover = self:IsMouseOver()
        local bg = selected and UI.Color("selected") or (hover and UI.Color("panelAlt")) or nil
        if bg then
            UI.Backdrop(self, selected and "selected" or "panelAlt", selected and "selected" or "panelAlt")
        else
            self:SetBackdrop(nil)
        end
        self.bar:SetShown(selected)
        UI.SetTextColor(self.label, selected and "accent" or "text")
    end

    b:SetScript("OnEnter", function(self) self:Refresh() end)
    b:SetScript("OnLeave", function(self) self:Refresh() end)
    b:SetScript("OnClick", function(self) UI.ShowPage(self.page.key) end)
    return b
end

function UI.RebuildNav()
    for _, b in ipairs(navButtons) do b:Hide() end
    for _, header in ipairs(nav.headers or {}) do header:Hide() end
    navButtons, nav.headers = {}, {}
    local y, lastSection = -10, nil
    local listed = {}
    for _, page in ipairs(pageOrder) do
        -- Hidden pages are opened another way (Settings from the cogwheel) and are not listed.
        if not page.hidden then listed[#listed + 1] = page end
    end
    for _, page in ipairs(listed) do
        if page.section ~= lastSection then
            lastSection = page.section
            local header = UI.Text(nav, string.upper(page.section), 10, "muted")
            header:SetPoint("TOPLEFT", 14, y - 6)
            nav.headers[#nav.headers + 1] = header
            y = y - 26
        end
        local b = NavButton(page)
        b:SetPoint("TOPLEFT", 0, y)
        b:SetPoint("TOPRIGHT", 0, y)
        b:Refresh()
        navButtons[#navButtons + 1] = b
        y = y - 30
    end
end

function UI.ShowPage(key)
    local page = pages[key] or pageOrder[1]
    if not page then return end
    for _, other in pairs(pages) do
        if other.frame then other.frame:Hide() end
    end
    if not page.frame then
        page.frame = CreateFrame("Frame", nil, content)
        page.frame:SetAllPoints(content)
        RPF.SafeCall("build page " .. page.key, page.build, page.frame)
    end
    if currentKey and currentKey ~= page.key then UI.previousPage = currentKey end
    currentKey = page.key
    RPF.db.lastPage = page.key
    page.frame:Show()
    if page.onShow then RPF.SafeCall("show page " .. page.key, page.onShow, page.frame) end
    for _, b in ipairs(navButtons) do b:Refresh() end
    if window and window.cog then window.cog:Refresh() end
end

function UI.CurrentPage()
    return currentKey
end

local function Build()
    window = CreateFrame("Frame", "RPForgeMainWindow", UIParent, UI.BACKDROP_TEMPLATE)
    window:SetSize(WIDTH, HEIGHT)
    window:SetFrameStrata("HIGH")
    window:SetToplevel(true)
    window:SetClampedToScreen(true)
    window:SetMovable(true)
    window:EnableMouse(true)
    window:Hide()
    UI.Backdrop(window, "window", "border")
    if not tContains(UISpecialFrames, "RPForgeMainWindow") then
        table.insert(UISpecialFrames, "RPForgeMainWindow") -- Escape closes it
    end

    -- Title bar: drag to move.
    local title = CreateFrame("Frame", nil, window, UI.BACKDROP_TEMPLATE)
    title:SetPoint("TOPLEFT", 1, -1)
    title:SetPoint("TOPRIGHT", -1, -1)
    title:SetHeight(TITLE_HEIGHT)
    UI.Backdrop(title, "panel", "panel")
    title:EnableMouse(true)
    title:RegisterForDrag("LeftButton")
    title:SetScript("OnDragStart", function() window:StartMoving() end)
    title:SetScript("OnDragStop", function()
        window:StopMovingOrSizing()
        SavePosition()
    end)
    local name = UI.Text(title, RPF.NAME, 14, "accent")
    name:SetPoint("LEFT", 12, 0)
    local version = UI.Text(title, RPF.VERSION, 11, "muted")
    version:SetPoint("LEFT", name, "RIGHT", 8, -1)

    local close = CreateFrame("Button", nil, title)
    close:SetSize(TITLE_HEIGHT, TITLE_HEIGHT)
    close:SetPoint("RIGHT", 0, 0)
    -- RP Forge's own X (Media\Icons\Close.tga), coloured like the cogwheel.
    close.icon = close:CreateTexture(nil, "ARTWORK")
    close.icon:SetTexture("Interface\\AddOns\\" .. RPF.ADDON .. "\\Media\\Icons\\Close")
    close.icon:SetPoint("CENTER")
    close.icon:SetSize(14, 14)
    local function TintClose(self, key)
        local c = UI.Color(key)
        self.icon:SetVertexColor(c[1], c[2], c[3], 1)
    end
    TintClose(close, "muted")
    close:SetScript("OnEnter", function(self) TintClose(self, "bad") end)
    close:SetScript("OnLeave", function(self) TintClose(self, "muted") end)
    close:SetScript("OnClick", function() window:Hide() end)

    -- Cogwheel: opens Settings, or goes back to the previous page when Settings is open.
    local cog = CreateFrame("Button", nil, title)
    cog:SetSize(TITLE_HEIGHT - 6, TITLE_HEIGHT - 6)
    cog:SetPoint("RIGHT", close, "LEFT", -2, 0)
    cog.icon = cog:CreateTexture(nil, "ARTWORK")
    -- RP Forge's own cogwheel (Media\Icons\Cog.tga), drawn white so the theme can colour it.
    cog.icon:SetTexture("Interface\\AddOns\\" .. RPF.ADDON .. "\\Media\\Icons\\Cog")
    cog.icon:SetPoint("CENTER")
    cog.icon:SetSize(15, 15)
    function cog:Refresh()
        local active = currentKey == "settings"
        local c = UI.Color((active or self:IsMouseOver()) and "accent" or "muted")
        self.icon:SetVertexColor(c[1], c[2], c[3], 1)
    end
    cog:SetScript("OnEnter", function(self)
        self:Refresh()
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:AddLine("Settings", 1, 0.82, 0.45)
        GameTooltip:Show()
    end)
    cog:SetScript("OnLeave", function(self) self:Refresh(); GameTooltip:Hide() end)
    cog:SetScript("OnClick", function() UI.ToggleSettings() end)
    window.cog = cog
    cog:Refresh()

    local line = window:CreateTexture(nil, "ARTWORK")
    line:SetTexture(UI.WHITE)
    local c = UI.Color("border")
    line:SetVertexColor(c[1], c[2], c[3], 1)
    line:SetHeight(1)
    line:SetPoint("TOPLEFT", 1, -(TITLE_HEIGHT + 1))
    line:SetPoint("TOPRIGHT", -1, -(TITLE_HEIGHT + 1))

    -- Side navigation.
    nav = CreateFrame("Frame", nil, window, UI.BACKDROP_TEMPLATE)
    nav:SetPoint("TOPLEFT", 1, -(TITLE_HEIGHT + 2))
    nav:SetPoint("BOTTOMLEFT", 1, 1)
    nav:SetWidth(NAV_WIDTH)
    UI.Backdrop(nav, "panel", "panel")
    local navLine = window:CreateTexture(nil, "ARTWORK")
    navLine:SetTexture(UI.WHITE)
    navLine:SetVertexColor(c[1], c[2], c[3], 1)
    navLine:SetWidth(1)
    navLine:SetPoint("TOPLEFT", nav, "TOPRIGHT", 0, 0)
    navLine:SetPoint("BOTTOMLEFT", nav, "BOTTOMRIGHT", 0, 0)

    -- Content area for pages.
    content = CreateFrame("Frame", nil, window)
    content:SetPoint("TOPLEFT", nav, "TOPRIGHT", 1, 0)
    content:SetPoint("BOTTOMRIGHT", -1, 1)

    window:SetScript("OnHide", function()
        if GameTooltip:IsOwned(window) then GameTooltip:Hide() end
    end)

    RestorePosition()
    UI.RebuildNav()
end

function UI.OpenWindow(key)
    if not window then Build() end
    window:Show()
    window:Raise()
    UI.ShowPage(key or currentKey or RPF.db.lastPage)
end

function UI.ToggleWindow()
    if window and window:IsShown() then
        window:Hide()
    else
        UI.OpenWindow()
    end
end

-- A new theme: throw the window away and build it again in the new colours, on the same page.
RPF.Listen("THEME_CHANGED", function()
    if not window then return end
    local wasShown, key = window:IsShown(), currentKey
    window:Hide()
    window:SetParent(nil)
    window = nil
    for _, page in pairs(pages) do page.frame = nil end
    navButtons = {}
    if wasShown then UI.OpenWindow(key) end
end)

function UI.IsWindowShown()
    return window ~= nil and window:IsShown()
end

function UI.ResetWindowPosition()
    RPF.db.window = nil
    if window then RestorePosition() end
end

RPF.AddCommand("open", "Open the RP Forge window", function() UI.OpenWindow() end)
RPF.AddCommand("reset", "Move the RP Forge window back to the middle of the screen", function()
    UI.ResetWindowPosition()
    RPF.Print("window moved back to the middle of the screen.")
end)
