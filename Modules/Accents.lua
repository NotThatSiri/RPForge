-- RP Forge: accents.
--
-- An accent changes the words you post from the RP chat box: all of Say and Yell, and only the words in
-- "quotes" in an emote. *Actions*, ((OOC)), links and colour codes are never changed.
-- Each profile picks one accent and a strength (Light, Medium or Strong) on the Voice tab of the
-- profile editor: profile.persona.accent = { key = "dwarven", strength = 1..3 }.
--
-- An accent is a list of rules. Each rule is { strength, from, to [, where] }:
--   strength  the lowest strength that uses it: 1 Light, 2 Medium, 3 Strong
--   from      lower case. A word ("you"), a phrase ("thank you"), or with `where` a word ending ("end",
--             as in "ing" -> "in'") or beginning ("start")
--   to        what it becomes; capitals follow the original ("You" -> "Ye", "YOU" -> "YE")
local _, RPF = ...

local Accents = {}
RPF.Accents = Accents

Accents.STRENGTHS = { { 1, "Light" }, { 2, "Medium" }, { 3, "Strong" } }
Accents.STRENGTH_NAMES = { "Light", "Medium", "Strong" }

Accents.LIST = {
    -- Alliance -----------------------------------------------------------------------------------
    -- Dwarven: how the game writes its dwarves (Falstad, Kurdran, quest text). Mostly plain English with
    -- a few markers; no Scots words (ken, aboot, bairn) that players wouldn't recognise.
    --   Light: ye, yer, me, aye, lad/lass, -in'.  Medium: fer, tae, wi', an', 'em, 'tis, wee.
    --   Strong: th', o', nae, och, cannae, dinnae, laddie/lassie.
    -- "friend", "mate", "buddy" and "pal" become lad or lass (laddie or lassie at Strong) from your
    -- target's gender; with no target they stay.
    { key = "dwarven", name = "Dwarven", side = "Alliance", races = { Dwarf = true },
        words = { "dwarf", "dwarven", "wildhammer", "bronzebeard", "dark iron", "ironforge" }, ladLass = { friend = true, mate = true, buddy = true, pal = true },
        rules = {
        { 1, "you", "ye" }, { 1, "your", "yer" }, { 1, "yours", "yers" }, { 1, "yourself", "yerself" },
        { 1, "yourselves", "yerselves" }, { 1, "you're", "ye're" }, { 1, "you've", "ye've" }, { 1, "you'll", "ye'll" },
        { 1, "my", "me" }, { 1, "myself", "meself" }, { 1, "yes", "aye" }, { 1, "yeah", "aye" }, { 1, "yep", "aye" },
        { 1, "boy", "lad" }, { 1, "boys", "lads" }, { 1, "girl", "lass" }, { 1, "girls", "lasses" }, { 1, "guys", "lads" },
        { 1, "ing", "in'", "end" },
        { 2, "for", "fer" }, { 2, "to", "tae" }, { 2, "with", "wi'" }, { 2, "and", "an'" }, { 2, "them", "'em" },
        { 2, "it's", "'tis" }, { 2, "little", "wee" }, { 2, "small", "wee" }, { 2, "tiny", "wee" },
        { 3, "the", "th'" }, { 3, "of", "o'" }, { 3, "no", "nae" }, { 3, "nope", "nae" }, { 3, "not", "nae" },
        { 3, "oh", "och" },
        { 3, "can't", "cannae" }, { 3, "cant", "cannae" }, { 3, "cannot", "cannae" },
        { 3, "don't", "dinnae" }, { 3, "dont", "dinnae" }, { 3, "didn't", "didnae" }, { 3, "didnt", "didnae" },
        { 3, "won't", "willnae" }, { 3, "wouldn't", "wouldnae" }, { 3, "wouldnt", "wouldnae" },
        { 3, "couldn't", "couldnae" }, { 3, "couldnt", "couldnae" }, { 3, "shouldn't", "shouldnae" },
        { 3, "shouldnt", "shouldnae" }, { 3, "isn't", "isnae" }, { 3, "isnt", "isnae" },
        { 3, "wasn't", "wasnae" }, { 3, "wasnt", "wasnae" }, { 3, "doesn't", "doesnae" }, { 3, "doesnt", "doesnae" },
        { 3, "haven't", "havenae" }, { 3, "havent", "havenae" }, { 3, "hasn't", "hasnae" }, { 3, "hasnt", "hasnae" },
        { 3, "aren't", "arenae" }, { 3, "arent", "arenae" }, { 3, "weren't", "werenae" }, { 3, "werent", "werenae" },
        { 3, "boy", "laddie" }, { 3, "girl", "lassie" },
    } },
    { key = "gnomish", name = "Gnomish", side = "Alliance", races = { Gnome = true }, words = { "gnome", "gnomish" },
        rules = {
        { 1, "wow", "fascinating" }, { 1, "good", "splendid" }, { 1, "great", "marvellous" },
        { 1, "broken", "defective" },
        { 2, "think", "calculate" }, { 2, "idea", "hypothesis" }, { 2, "ideas", "hypotheses" },
        { 2, "problem", "malfunction" }, { 2, "problems", "malfunctions" }, { 2, "thing", "gizmo" },
        { 2, "things", "gizmos" }, { 2, "maybe", "theoretically" }, { 2, "hello", "salutations" },
        { 3, "fix", "recalibrate" }, { 3, "make", "engineer" }, { 3, "big", "gargantuan" },
        { 3, "small", "pocket-sized" }, { 3, "yes", "affirmative" }, { 3, "no", "negative" },
        { 3, "fast", "high-velocity" }, { 3, "quickly", "at optimal velocity" },
    } },
    -- Kaldorei: formal and old-fashioned rather than a sound. Night elves in the game hardly use
    -- contractions, and greet in Darnassian.
    --   Light: no contractions.  Medium: formal words.  Strong: Ishnu-alah, Elune-adore.
    { key = "kaldorei", name = "Kaldorei", side = "Alliance", races = { NightElf = true },
        words = { "night elf", "night-elf", "nightelf", "kaldorei" }, rules = {
        { 1, "don't", "do not" }, { 1, "can't", "cannot" }, { 1, "won't", "will not" }, { 1, "didn't", "did not" },
        { 1, "doesn't", "does not" }, { 1, "isn't", "is not" }, { 1, "aren't", "are not" },
        { 1, "wasn't", "was not" }, { 1, "weren't", "were not" }, { 1, "haven't", "have not" },
        { 1, "hasn't", "has not" }, { 1, "couldn't", "could not" }, { 1, "wouldn't", "would not" },
        { 1, "shouldn't", "should not" }, { 1, "i'm", "I am" }, { 1, "you're", "you are" }, { 1, "we're", "we are" },
        { 1, "they're", "they are" }, { 1, "it's", "it is" }, { 1, "that's", "that is" },
        { 1, "there's", "there is" }, { 1, "what's", "what is" }, { 1, "i'll", "I will" },
        { 1, "you'll", "you will" }, { 1, "we'll", "we will" }, { 1, "they'll", "they will" },
        { 1, "i've", "I have" }, { 1, "you've", "you have" }, { 1, "we've", "we have" },
        { 1, "they've", "they have" }, { 1, "let's", "let us" },
        { 1, "isn't it", "is it not" }, { 1, "aren't you", "are you not" }, { 1, "don't you", "do you not" },
        { 1, "can't you", "can you not" }, { 1, "won't you", "will you not" }, { 1, "didn't you", "did you not" },
        { 2, "yeah", "yes" }, { 2, "yep", "yes" }, { 2, "yup", "yes" }, { 2, "nope", "no" },
        { 2, "okay", "very well" }, { 2, "ok", "very well" }, { 2, "hi", "greetings" }, { 2, "hey", "greetings" },
        { 2, "hello", "greetings" }, { 2, "bye", "farewell" }, { 2, "goodbye", "farewell" },
        { 2, "thanks", "thank you" }, { 2, "gonna", "going to" }, { 2, "wanna", "want to" },
        { 2, "gotta", "must" }, { 2, "kid", "child" }, { 2, "kids", "children" }, { 2, "mom", "mother" },
        { 2, "dad", "father" }, { 2, "oh my god", "by Elune" }, { 2, "my god", "by Elune" },
        { 3, "hi", "Ishnu-alah" }, { 3, "hey", "Ishnu-alah" }, { 3, "hello", "Ishnu-alah" },
        { 3, "greetings", "Ishnu-alah" }, { 3, "bye", "Elune-adore" }, { 3, "goodbye", "Elune-adore" },
        { 3, "farewell", "Elune-adore" }, { 3, "teacher", "shan'do" },
    } },
    -- Horde --------------------------------------------------------------------------------------
    { key = "orcish", name = "Orcish", side = "Horde", races = { Orc = true }, words = { "orc", "mag'har", "frostwolf" },
        rules = {
        { 1, "hello", "Throm-ka" }, { 1, "hi", "Throm-ka" }, { 1, "okay", "zug zug" }, { 1, "ok", "zug zug" },
        { 1, "goodbye", "Lok'tar" }, { 1, "bye", "Lok'tar" },
        { 2, "yes", "dabu" }, { 2, "weak", "puny" }, { 2, "small", "puny" }, { 2, "victory", "lok'tar" },
        { 2, "friend", "brother" }, { 2, "friends", "brothers" },
        { 3, "my", "me" }, { 3, "are", "be" }, { 3, "is", "be" }, { 3, "fight", "smash" },
        { 3, "very", "much" },
    } },
    { key = "trollish", name = "Trollish", side = "Horde", races = { Troll = true }, words = { "troll", "darkspear" },
        rules = {
        { 1, "the", "da" }, { 1, "this", "dis" }, { 1, "that", "dat" }, { 1, "man", "mon" },
        { 1, "you", "ya" }, { 1, "your", "ya" },
        { 2, "these", "dese" }, { 2, "those", "dose" }, { 2, "them", "dem" }, { 2, "they", "dey" },
        { 2, "there", "dere" }, { 2, "with", "wit'" }, { 2, "think", "t'ink" }, { 2, "thing", "ting" },
        { 2, "things", "tings" }, { 2, "my", "me" }, { 2, "brother", "bruddah" }, { 2, "ing", "in'", "end" },
        { 3, "is", "be" }, { 3, "are", "be" }, { 3, "am", "be" }, { 3, "nothing", "nuttin'" },
        { 3, "something", "sometin'" }, { 3, "gods", "loa" }, { 3, "what", "wha'" }, { 3, "little", "likkle" },
    } },
    { key = "forsaken", name = "Forsaken", side = "Horde", races = { Scourge = true, Undead = true },
        words = { "forsaken", "undead" }, rules = {
        { 1, "hello", "greetings" }, { 1, "goodbye", "Dark Lady watch over you" },
        { 1, "bye", "Dark Lady watch over you" }, { 1, "oh my god", "Dark Lady" }, { 1, "my god", "Dark Lady" },
        { 2, "yes", "indeed" }, { 2, "die", "perish" }, { 2, "friend", "ally" }, { 2, "friends", "allies" },
        { 2, "people", "the living" }, { 2, "great", "delightful" },
        { 3, "nice", "tolerable" }, { 3, "happy", "amused" }, { 3, "awesome", "adequate" },
        { 3, "beautiful", "tolerable" }, { 3, "love", "tolerate" }, { 3, "humans", "breathers" },
        { 3, "human", "breather" },
    } },
    { key = "tauren", name = "Tauren", side = "Horde", races = { Tauren = true }, words = { "tauren" },
        rules = {
        { 1, "goodbye", "walk with the Earth Mother" }, { 1, "bye", "walk with the Earth Mother" },
        { 1, "oh my god", "Earth Mother" }, { 1, "my god", "Earth Mother" }, { 1, "hello", "peace" }, { 1, "hi", "peace" },
        { 2, "yes", "it is so" }, { 2, "okay", "so be it" }, { 2, "ok", "so be it" }, { 2, "kid", "calf" },
        { 2, "kids", "calves" }, { 2, "child", "calf" }, { 2, "children", "calves" },
        { 3, "old", "elder" }, { 3, "think", "believe" }, { 3, "hurry", "go swiftly" },
        { 3, "very", "most" },
    } },
}

Accents.BY_KEY = {}
for _, accent in ipairs(Accents.LIST) do Accents.BY_KEY[accent.key] = accent end

Accents.SAMPLE = 'Hello, friend! I don\'t think you\'re going to like this, but my little brother is coming ' ..
    'with us. Yes, the old one. *grins* ((brb))'

-- Rules -> lookups --------------------------------------------------------------------------------------

local compiled = {}

-- "thank you" -> a pattern matching it in any capitals, as whole words.
local function PhrasePattern(phrase)
    local out = {}
    for i = 1, #phrase do
        local ch = phrase:sub(i, i)
        if ch:match("%a") then
            out[#out + 1] = "[" .. ch:lower() .. ch:upper() .. "]"
        elseif ch:match("%p") then
            out[#out + 1] = "%" .. ch
        else
            out[#out + 1] = ch
        end
    end
    return "%f[%a]" .. table.concat(out) .. "%f[^%a']"
end

local function Compile(accent, strength)
    local id = accent.key .. strength
    if compiled[id] then return compiled[id] end
    local c = { words = {}, phrases = {}, ends = {}, starts = {}, beginnings = {}, longest = 0 }
    for _, rule in ipairs(accent.rules) do
        local level, from, to, where = rule[1], rule[2], rule[3], rule[4]
        if level <= strength then
            if where == "end" then
                c.ends[#c.ends + 1] = { from, to }
            elseif where == "start" then
                c.starts[#c.starts + 1] = { from, to }
            elseif from:find(" ", 1, true) then
                c.phrases[#c.phrases + 1] = { PhrasePattern(from), to, #from }
                -- "oh my god" begins with "oh" and "oh my".
                local words = {}
                for word in from:gmatch("%S+") do words[#words + 1] = word end
                for n = 1, #words - 1 do c.beginnings[table.concat(words, " ", 1, n)] = true end
                c.longest = math.max(c.longest, #words - 1)
            else
                c.words[from] = to
            end
        end
    end
    table.sort(c.phrases, function(a, b) return a[3] > b[3] end) -- longest first
    c.ladLass = accent.ladLass
    c.strong = strength >= 3
    compiled[id] = c
    return c
end

-- Capitals follow the original: "You" -> "Ye", "YOU" -> "YE".
local function MatchCase(original, replacement)
    if replacement == "" then return "" end
    if #original > 1 and original:upper() == original and original:lower() ~= original then
        return replacement:upper()
    end
    local first = original:sub(1, 1)
    if first:upper() == first and first:lower() ~= first then
        return replacement:sub(1, 1):upper() .. replacement:sub(2)
    end
    return replacement
end

-- Words of five letters or more where the ending is part of the word, not "-ing".
local KEEP_ENDING = {
    thing = true, bring = true, sting = true, swing = true, sling = true, cling = true, fling = true,
    wring = true,
    string = true, spring = true, during = true, ceiling = true, offspring = true, earring = true,
    herring = true, sibling = true, awning = true, viking = true, sterling = true, wellspring = true,
    bowstring = true, hamstring = true, plaything = true, wingding = true, evening = true,
}

-- "lad" or "lass" for your target (male or female), or nil without one. Hidden values count as unknown.
local function TargetLadLass()
    if type(UnitExists) ~= "function" or type(UnitSex) ~= "function" then return nil end
    local function Hidden(v) return issecretvalue ~= nil and issecretvalue(v) == true end
    local ok, exists = pcall(UnitExists, "target")
    if not ok or Hidden(exists) or not exists then return nil end
    local okSex, sex = pcall(UnitSex, "target")
    if not okSex or Hidden(sex) then return nil end
    if sex == 2 then return "lad" elseif sex == 3 then return "lass" end
end

local ladLass -- set by Accents.Apply: "lad", "lass" or nil

local function ChangeWord(c, word)
    local core, tail = word:match("^(.-)('*)$")
    local lower = core:lower()
    local to = c.words[lower]
    if not to and ladLass and c.ladLass and c.ladLass[lower] then
        to = c.strong and (ladLass == "lad" and "laddie" or "lassie") or ladLass
    end
    if to then return MatchCase(core, to) .. tail end
    -- Otherwise one ending rule and one beginning rule can both apply ("having" -> "'avin'").
    for _, rule in ipairs(c.ends) do
        local from = rule[1]
        if #lower >= #from + 2 and lower:sub(-#from) == from and not KEEP_ENDING[lower] then
            local ending = rule[2]
            if core:upper() == core then ending = ending:upper() end
            core = core:sub(1, #core - #from) .. ending
            break
        end
    end
    lower = core:lower()
    for _, rule in ipairs(c.starts) do
        local from = rule[1]
        if #lower > #from + 1 and lower:sub(1, #from) == from then
            local rest = core:sub(#from + 1)
            if core:sub(1, 1):match("%u") then rest = rest:sub(1, 1):upper() .. rest:sub(2) end
            core = rule[2] .. rest
            break
        end
    end
    return core .. tail
end

-- Plain words only (nothing protected inside).
local function ApplyPlain(c, text)
    -- Phrases first; their results are parked so the word rules don't change them again.
    local parked = {}
    for _, rule in ipairs(c.phrases) do
        text = text:gsub(rule[1], function(found)
            parked[#parked + 1] = MatchCase(found, rule[2])
            return "\001" .. #parked .. "\002"
        end)
    end
    text = text:gsub("%a[%a']*", function(word) return ChangeWord(c, word) end)
    return (text:gsub("\001(%d+)\002", function(i) return parked[tonumber(i)] end))
end

-- Parts never changed: ((OOC)), *actions*, links, colour codes and textures.
local PROTECTED = {
    "%(%(.-%)%)", "%(%(.*$", "%*.-%*", "%*[^*]*$", "|H.-|h.-|h", "|c%x%x%x%x%x%x%x%x", "|r", "|T.-|t", "|A.-|a",
}

local function ApplyProtected(c, text)
    local out, pos = {}, 1
    while pos <= #text do
        local bestStart, bestEnd
        for _, pattern in ipairs(PROTECTED) do
            local s, e = text:find(pattern, pos)
            if s and (not bestStart or s < bestStart) then bestStart, bestEnd = s, e end
        end
        if not bestStart then
            out[#out + 1] = ApplyPlain(c, text:sub(pos))
            break
        end
        if bestStart > pos then out[#out + 1] = ApplyPlain(c, text:sub(pos, bestStart - 1)) end
        out[#out + 1] = text:sub(bestStart, bestEnd)
        pos = bestEnd + 1
    end
    return table.concat(out)
end

-- Public -------------------------------------------------------------------------------------------------

local function Persona()
    local Profiles = RPF.Profiles
    return Profiles and Profiles.GetActive() and Profiles.GetPersona() or nil
end

-- Is the active profile In Character? Accents only change your words then.
function Accents.IsIC()
    local profile = RPF.Profiles and RPF.Profiles.GetActive()
    return profile ~= nil and profile.fields ~= nil and profile.fields.status == "ic"
end

-- Is this accent for your race: the game's race, or the race written on your profile?
function Accents.MatchesRace(accent)
    if type(UnitRace) == "function" then
        local name, file = UnitRace("player")
        if file and accent.races[file] then return true end
        for _, word in ipairs(accent.words) do
            if type(name) == "string" and name:lower():find(word, 1, true) then return true end
        end
    end
    local profile = RPF.Profiles and RPF.Profiles.GetActive()
    local race = profile and profile.fields and profile.fields.race
    if type(race) == "string" and race ~= "" then
        race = race:lower()
        for _, word in ipairs(accent.words) do
            if race:find(word, 1, true) then return true end
        end
    end
    return false
end

-- Voice tab toggle: list the accents of the other races of your faction too.
function Accents.ShowAllRaces()
    local persona = Persona()
    return persona ~= nil and persona.accentAllRaces == true
end

function Accents.SetShowAllRaces(on)
    local persona = Persona()
    if not persona then return end
    persona.accentAllRaces = on and true or nil
    -- Turning it off drops an accent that isn't for your race.
    local accent = persona.accent and Accents.BY_KEY[persona.accent.key]
    if not on and accent and not Accents.MatchesRace(accent) then persona.accent = nil end
    RPF.Profiles.PersonaChanged()
end

-- Can you pick this accent? Only your faction's, and only your race's unless the toggle is on.
function Accents.Available(accent)
    local faction = type(UnitFactionGroup) == "function" and UnitFactionGroup("player") or nil
    if faction and accent.side ~= faction then return false end
    return Accents.ShowAllRaces() or Accents.MatchesRace(accent)
end

-- The accent chosen on the active profile (accent table and strength), whether or not you are IC.
function Accents.Chosen()
    local persona = Persona()
    local choice = persona and persona.accent
    local accent = choice and Accents.BY_KEY[choice.key]
    if not accent or not Accents.Available(accent) then return nil end
    return accent, math.max(1, math.min(3, tonumber(choice.strength) or 1))
end

-- The accent to use now: the chosen one, while In Character.
function Accents.Current()
    if not Accents.IsIC() then return nil end
    return Accents.Chosen()
end

-- "Dwarven, light" and whether it is on now (In Character), or nil without an accent.
function Accents.Describe()
    local accent, strength = Accents.Chosen()
    if not accent then return nil end
    return accent.name .. ", " .. Accents.STRENGTH_NAMES[strength]:lower(), Accents.IsIC()
end

-- Choose the active profile's accent (nil = none), keeping the strength.
function Accents.Set(key)
    local Profiles = RPF.Profiles
    if not Profiles.GetActive() then return end
    local persona = Profiles.GetPersona()
    local old = persona.accent
    persona.accent = key and { key = key, strength = old and old.strength or 1 } or nil
    Profiles.PersonaChanged()
end

function Accents.SetStrength(strength)
    local persona = Persona()
    local choice = persona and persona.accent
    if not choice then return end
    choice.strength = strength
    RPF.Profiles.PersonaChanged()
end

-- The accent menu, used by the RP chat window and the Voice tab. withStrength adds the strengths and a
-- link to the Voice tab.
function Accents.ShowMenu(owner, withStrength)
    local UI = RPF.UI
    local current, strength = Accents.Chosen()
    local items = { { "No accent", function() Accents.Set(nil) end, checked = not current } }
    local any = false
    for _, accent in ipairs(Accents.LIST) do
        if Accents.Available(accent) then
            if not any then items[#items + 1] = "-" end
            any = true
            local key = accent.key
            items[#items + 1] = { accent.name, function() Accents.Set(key) end, checked = current == accent }
        end
    end
    if not any then
        items[#items + 1] = "-"
        items[#items + 1] = { "No accent for your race", nil, disabled = true }
    end
    if withStrength then
        items[#items + 1] = "-"
        for _, s in ipairs(Accents.STRENGTHS) do
            local value = s[1]
            items[#items + 1] = { s[2], function() Accents.SetStrength(value) end,
                checked = current ~= nil and strength == value, disabled = current == nil }
        end
    end
    if withStrength or not any then
        items[#items + 1] = "-"
        items[#items + 1] = { "Voice settings...", function() UI.OpenProfile("voice") end }
    end
    UI.ShowMenu(owner, items)
end

-- Change text with an accent. mode: "SAY", "YELL" or "EMOTE" (emotes: only "quoted" words).
-- accent and strength default to the active profile's, and then only while In Character.
-- who ("lad" or "lass") stands in for your target's gender, for trying the accent out.
function Accents.Apply(text, mode, accent, strength, who)
    if not accent then accent, strength = Accents.Current() end
    if not accent or not text or text == "" then return text end
    local c = Compile(accent, strength or 1)
    ladLass = c.ladLass and (who or TargetLadLass()) or nil
    if mode == "EMOTE" then
        -- Every other piece between straight quotes is speech (an open quote runs to the end).
        local pieces, inside = {}, false
        for piece in (text .. '"'):gmatch('([^"]*)"') do
            pieces[#pieces + 1] = inside and ApplyProtected(c, piece) or piece
            inside = not inside
        end
        text = table.concat(pieces, '"')
        -- Curly quotes too.
        text = text:gsub("(\226\128\156)(.-)(\226\128\157)", function(a, inner, b) return a .. ApplyProtected(c, inner) .. b end)
        return text
    end
    return ApplyProtected(c, text)
end

-- While typing: once a word is finished (the character before the cursor is not part of a word), change
-- the text before the cursor. Returns the new text and cursor (a byte position), or nil if nothing
-- changed. Applying an accent again never changes its own words, so sending can apply it once more.
function Accents.ApplyTyping(text, cursor, mode, accent, strength, who)
    if not accent then accent, strength = Accents.Current() end
    if not accent or not text or not cursor or cursor < 1 then return nil end
    local before = text:sub(1, cursor)
    if before:sub(-1):match("[%a']") or before:sub(-1):byte() >= 128 then return nil end
    -- If the last words could begin a phrase ("isn't" of "isn't it"), leave them until the phrase is
    -- finished or broken.
    local c = Compile(accent, strength or 1)
    local cut = #before + 1
    if c.longest > 0 then
        local found = {}
        for at, word in before:gmatch("()(%a[%a']*)") do found[#found + 1] = { at, word:lower() } end
        for n = math.min(c.longest, #found), 1, -1 do
            local words = {}
            for k = #found - n + 1, #found do words[#words + 1] = found[k][2] end
            if c.beginnings[table.concat(words, " ")] then
                cut = found[#found - n + 1][1]
                break
            end
        end
    end
    local head = before:sub(1, cut - 1)
    local changed = Accents.Apply(head, mode, accent, strength, who)
    if changed == head then return nil end
    return changed .. text:sub(cut), cursor + #changed - #head
end
