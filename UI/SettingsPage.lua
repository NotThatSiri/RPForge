-- RP Forge: the Settings page, opened from the cogwheel in the title bar.
-- Settings pages (General, Appearance, and later ones) are tabs across the top of it.
local _, RPF = ...
local UI = RPF.UI

local tabs, tabOrder = {}, {}
local body
local tabButtons = {}
local currentTab

-- tab = { key, title, order, build = function(frame) end, onShow = function(frame) end }
function UI.RegisterSettingsPage(tab)
    assert(tab.key and tab.title and tab.build, "RegisterSettingsPage needs key, title and build")
    tab.order = tab.order or 100
    tabs[tab.key] = tab
    tabOrder[#tabOrder + 1] = tab
    table.sort(tabOrder, function(a, b) return a.order < b.order end)
end

local function RefreshTabs()
    for _, b in ipairs(tabButtons) do
        local active = b.tab.key == currentTab
        b.style = active and "primary" or nil
        b:Refresh()
    end
end

function UI.ShowSettingsTab(key)
    local tab = tabs[key] or tabs[currentTab or ""] or tabOrder[1]
    if not tab or not body then return end
    for _, other in pairs(tabs) do
        if other.frame then other.frame:Hide() end
    end
    if not tab.frame then
        tab.frame = CreateFrame("Frame", nil, body)
        tab.frame:SetAllPoints(body)
        RPF.SafeCall("build settings " .. tab.key, tab.build, tab.frame)
    end
    currentTab = tab.key
    RPF.db.lastSettingsTab = tab.key
    tab.frame:Show()
    if tab.onShow then RPF.SafeCall("show settings " .. tab.key, tab.onShow, tab.frame) end
    RefreshTabs()
end

UI.RegisterPage({
    key = "settings",
    title = "Settings",
    hidden = true,
    build = function(page)
        -- A rebuilt window (new theme) needs fresh tab frames.
        for _, tab in pairs(tabs) do tab.frame = nil end
        local heading = UI.Text(page, "Settings", 20, "accent")
        heading:SetPoint("TOPLEFT", 28, -26)

        tabButtons = {}
        local x = 28
        for _, tab in ipairs(tabOrder) do
            local b = UI.Button(page, tab.title, 120, 26)
            b.tab = tab
            b:SetPoint("TOPLEFT", x, -64)
            b:SetScript("OnClick", function() UI.ShowSettingsTab(tab.key) end)
            tabButtons[#tabButtons + 1] = b
            x = x + 126
        end
        UI.Divider(page, -100, 28)

        body = CreateFrame("Frame", nil, page)
        body:SetPoint("TOPLEFT", 28, -116)
        body:SetPoint("BOTTOMRIGHT", -28, 16)
    end,
    onShow = function()
        UI.ShowSettingsTab(currentTab or RPF.db.lastSettingsTab)
    end,
})

function UI.OpenSettings(tabKey)
    if tabKey then currentTab = tabKey end
    UI.OpenWindow("settings")
end

function UI.ToggleSettings()
    if UI.CurrentPage() == "settings" then
        UI.ShowPage(UI.previousPage or "home")
    else
        UI.OpenSettings()
    end
end
