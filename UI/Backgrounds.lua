-- RP Forge: banner backgrounds from the game's own pictures.
-- These are the race backgrounds the game shows behind your character in the dressing room. Each is
-- made of four pieces that together form one 318 x 383 picture.
local _, RPF = ...
local UI = RPF.UI

local Backgrounds = {}
UI.Backgrounds = Backgrounds

local PATH = "Interface\\DressUpFrame\\DressUpBackground-"
-- piece number, x, y, width, height
local PIECES = {
    { 1, 0, 0, 256, 255 },
    { 2, 256, 0, 62, 255 },
    { 3, 0, -255, 256, 128 },
    { 4, 256, -255, 62, 128 },
}
Backgrounds.WIDTH, Backgrounds.HEIGHT = 318, 383

-- Races in the original game, used when the client can't list its races.
local FALLBACK_RACES = {
    { file = "Human", name = "Human" }, { file = "Dwarf", name = "Dwarf" },
    { file = "NightElf", name = "Night Elf" }, { file = "Gnome", name = "Gnome" },
    { file = "Orc", name = "Orc" }, { file = "Scourge", name = "Undead" },
    { file = "Tauren", name = "Tauren" }, { file = "Troll", name = "Troll" },
}

function Backgrounds.PlayerRace()
    local _, file = UnitRace("player")
    return file
end

-- Does the game have this race's picture? (SetTexture says false when the file isn't there.)
local probe
local function Exists(file)
    probe = probe or UIParent:CreateTexture(nil, "BACKGROUND")
    local ok = probe:SetTexture(PATH .. file .. "1")
    probe:SetTexture(nil)
    return ok ~= false
end

-- Every race the client knows that has a background, sorted by name: { { file, name }, ... }.
local cached
function Backgrounds.Races()
    if cached then return cached end
    local list, seen = {}, {}
    if C_CreatureInfo and C_CreatureInfo.GetRaceInfo then
        for id = 1, 40 do
            local info = C_CreatureInfo.GetRaceInfo(id)
            local file = info and info.clientFileString
            if file and not seen[file] then
                seen[file] = true
                list[#list + 1] = { file = file, name = info.raceName or file }
            end
        end
    end
    if #list == 0 then list = FALLBACK_RACES end
    cached = {}
    for _, race in ipairs(list) do
        if Exists(race.file) then cached[#cached + 1] = race end
    end
    table.sort(cached, function(a, b) return a.name < b.name end)
    return cached
end

function Backgrounds.RaceName(file)
    for _, race in ipairs(Backgrounds.Races()) do
        if race.file == file then return race.name end
    end
    return file
end

-- A frame holding the four pieces, 318 x 383 before scaling.
function Backgrounds.CreateArt(parent)
    local art = CreateFrame("Frame", nil, parent)
    art:SetSize(Backgrounds.WIDTH, Backgrounds.HEIGHT)
    art.pieces = {}
    for i, piece in ipairs(PIECES) do
        local tex = art:CreateTexture(nil, "BACKGROUND")
        tex:SetPoint("TOPLEFT", piece[2], piece[3])
        tex:SetSize(piece[4], piece[5])
        art.pieces[i] = tex
    end
    return art
end

-- Show a race's background on an art frame. Returns false when the game has no such picture.
function Backgrounds.Apply(art, file)
    if not file or not Exists(file) then
        art:Hide()
        return false
    end
    for i, piece in ipairs(PIECES) do
        art.pieces[i]:SetTexture(PATH .. file .. piece[1])
    end
    art:Show()
    return true
end

-- Scale the art to fill `frame`'s width and show a band of it, `focus` of the way down (0 = top).
function Backgrounds.Fit(art, frame, focus)
    local width, height = frame:GetWidth(), frame:GetHeight()
    if not width or width <= 0 then return end
    local scale = width / Backgrounds.WIDTH
    art:SetScale(scale)
    local spare = Backgrounds.HEIGHT * scale - height
    art:ClearAllPoints()
    art:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, (math.max(0, spare) * (focus or 0.35)) / scale)
end
