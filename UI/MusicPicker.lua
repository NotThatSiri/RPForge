-- RP Forge: pick a theme tune from the game's music, with a search and a preview.
-- UI.PickMusic(current, onPick) opens it; onPick(file) gets the chosen music file ID.
-- Music names come from LibRPMedia (in Libs).
local _, RPF = ...
local UI = RPF.UI

local ROWS = 12
local ROW_HEIGHT = 30

local window
local all, shown
local page = 1
local playing -- file ID being previewed

local function Media()
    return LibStub and LibStub:GetLibrary("LibRPMedia-1.2", true)
end

-- "zone/elwynn forest/day_01" -> "Elwynn Forest, day 01"
function UI.MusicName(file)
    local media = Media()
    local info = media and media:GetMusicInfoByFile(file)
    local raw = info and info.names and info.names[1]
    if not raw then return file and ("Music " .. tostring(file)) or "None" end
    local parts = {}
    for part in raw:gmatch("[^/\\]+") do parts[#parts + 1] = part end
    local text = table.concat(parts, ", ", math.max(1, #parts - 1)):gsub("_", " ")
    return (text:gsub("^%l", string.upper))
end

local function Duration(seconds)
    seconds = math.floor(tonumber(seconds) or 0)
    if seconds <= 0 then return "" end
    return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
end

function UI.PlayTune(file)
    if not file then return end
    StopMusic()
    PlayMusic(file)
    playing = file
end

function UI.StopTune()
    StopMusic()
    playing = nil
end

function UI.IsTunePlaying(file)
    return playing ~= nil and playing == file
end

local function LoadMusic()
    if all then return all end
    all = {}
    local media = Media()
    if media then
        for i = 1, media:GetNumMusic() do
            local info = media:GetMusicInfoByIndex(i)
            if info then
                all[#all + 1] = { file = info.file, name = UI.MusicName(info.file), search = strlower(table.concat(info.names or {}, " ")), duration = info.duration }
            end
        end
        table.sort(all, function(a, b) return a.name < b.name end)
    end
    return all
end

local function ShowPage(n)
    local pages = math.max(1, math.ceil(#shown / ROWS))
    page = math.max(1, math.min(pages, n))
    for i, row in ipairs(window.rows) do
        local tune = shown[(page - 1) * ROWS + i]
        row.tune = tune
        row:SetShown(tune ~= nil)
        if tune then
            row.name:SetText(tune.name)
            row.length:SetText(Duration(tune.duration))
            row.play.label:SetText(UI.IsTunePlaying(tune.file) and "Stop" or "Play")
            UI.Backdrop(row, tune.file == window.current and "selected" or "panel", tune.file == window.current and "accent" or "panel")
        end
    end
    window.pageLabel:SetText(#shown == 0 and "No music matches." or ("Page " .. page .. " of " .. pages .. "   (" .. #shown .. " tracks)"))
    window.prev:SetEnabled(page > 1)
    window.next:SetEnabled(page < pages)
end

local function Filter(text)
    local words = {}
    for word in strlower(text or ""):gmatch("%S+") do words[#words + 1] = word end
    if #words == 0 then
        shown = LoadMusic()
    else
        shown = {}
        for _, tune in ipairs(LoadMusic()) do
            local ok = true
            for _, word in ipairs(words) do
                if not tune.search:find(word, 1, true) then ok = false break end
            end
            if ok then shown[#shown + 1] = tune end
        end
    end
    ShowPage(1)
end

local function Build()
    window = CreateFrame("Frame", "RPForgeMusicPicker", UIParent, UI.BACKDROP_TEMPLATE)
    window:SetSize(520, ROWS * (ROW_HEIGHT + 4) + 160)
    window:SetPoint("CENTER")
    window:SetFrameStrata("FULLSCREEN_DIALOG")
    window:SetToplevel(true)
    window:EnableMouse(true)
    window:SetMovable(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", window.StartMoving)
    window:SetScript("OnDragStop", window.StopMovingOrSizing)
    window:SetScript("OnHide", function() UI.StopTune() end)
    tinsert(UISpecialFrames, "RPForgeMusicPicker")
    UI.Backdrop(window, "window", "border")
    window.themeKey = UI.themeKey

    local title = UI.Text(window, "Choose a theme tune", 16, "accent")
    title:SetPoint("TOPLEFT", 20, -16)

    window.search = UI.EditBox(window, 480, 26)
    window.search:SetPoint("TOPLEFT", 20, -44)
    window.searchHint = UI.Text(window.search, "Search, for example: elwynn, tavern, orgrimmar", 11, "muted")
    window.searchHint:SetPoint("LEFT", 8, 0)
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

    window.rows = {}
    for i = 1, ROWS do
        local row = CreateFrame("Button", nil, window, UI.BACKDROP_TEMPLATE)
        row:SetHeight(ROW_HEIGHT)
        row:SetPoint("TOPLEFT", 20, -80 - (i - 1) * (ROW_HEIGHT + 4))
        row:SetPoint("RIGHT", window, "RIGHT", -20, 0)
        row.play = UI.Button(row, "Play", 60, 22)
        row.play:SetPoint("LEFT", 4, 0)
        row.play:SetScript("OnClick", function()
            if not row.tune then return end
            if UI.IsTunePlaying(row.tune.file) then UI.StopTune() else UI.PlayTune(row.tune.file) end
            ShowPage(page)
        end)
        row.name = UI.Text(row, "", 12, "text")
        row.name:SetPoint("LEFT", row.play, "RIGHT", 10, 0)
        row.name:SetPoint("RIGHT", row, "RIGHT", -60, 0)
        row.name:SetWordWrap(false)
        row.length = UI.Text(row, "", 11, "muted", "RIGHT")
        row.length:SetPoint("RIGHT", -10, 0)
        row:SetScript("OnClick", function(self)
            if not self.tune then return end
            local file = self.tune.file
            window:Hide()
            if window.onPick then RPF.SafeCall("pick music", window.onPick, file) end
        end)
        row:SetScript("OnEnter", function(self) if self.tune and self.tune.file ~= window.current then UI.Backdrop(self, "panelAlt", "border") end end)
        row:SetScript("OnLeave", function() ShowPage(page) end)
        window.rows[i] = row
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

    window:EnableMouseWheel(true)
    window:SetScript("OnMouseWheel", function(_, delta) ShowPage(page - delta) end)
end

function UI.PickMusic(current, onPick)
    if not Media() then
        RPF.Print("the music list isn't available.")
        return
    end
    if window and window.themeKey ~= UI.themeKey then
        window:Hide()
        window = nil
    end
    if not window then Build() end
    window.current, window.onPick = current, onPick
    window.search:SetText("")
    window.searchHint:Show()
    shown = LoadMusic()
    local start = 1
    for i, tune in ipairs(shown) do
        if tune.file == current then start = math.ceil(i / ROWS) break end
    end
    ShowPage(start)
    window:Show()
    window:Raise()
end
