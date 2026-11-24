-- RP Forge: Semantic Versioning helpers (https://semver.org).
local _, RPF = ...

-- "1.2.3" or "1.0.0-rc.2" -> { 1, 2, 3, pre = { "rc", 2 } }. Returns nil for anything else.
function RPF.ParseVersion(text)
    if type(text) ~= "string" then return nil end
    local major, minor, patch, rest = text:match("^%s*(%d+)%.(%d+)%.(%d+)(.-)%s*$")
    if not major then return nil end
    local version = { tonumber(major), tonumber(minor), tonumber(patch) }
    if rest ~= "" then
        local pre = rest:match("^%-([%w%.%-]+)$")
        if not pre then return nil end
        version.pre = {}
        for part in pre:gmatch("[^%.]+") do
            version.pre[#version.pre + 1] = tonumber(part) or part
        end
    end
    return version
end

-- Pre-release labels compare part by part: numbers below words, shorter lists first.
local function ComparePre(a, b)
    if not a and not b then return 0 end
    if not a then return 1 end -- 1.0.0 is newer than 1.0.0-rc.1
    if not b then return -1 end
    for i = 1, math.max(#a, #b) do
        local x, y = a[i], b[i]
        if x == nil then return -1 end
        if y == nil then return 1 end
        if x ~= y then
            local xn, yn = type(x) == "number", type(y) == "number"
            if xn and yn then return x < y and -1 or 1 end
            if xn then return -1 end
            if yn then return 1 end
            return tostring(x) < tostring(y) and -1 or 1
        end
    end
    return 0
end

-- -1 if a is older than b, 0 if the same, 1 if newer. nil if either is not a valid version.
function RPF.CompareVersions(a, b)
    local va, vb = RPF.ParseVersion(a), RPF.ParseVersion(b)
    if not va or not vb then return nil end
    for i = 1, 3 do
        if va[i] ~= vb[i] then return va[i] < vb[i] and -1 or 1 end
    end
    return ComparePre(va.pre, vb.pre)
end

function RPF.IsNewerVersion(candidate, than)
    return RPF.CompareVersions(candidate, than) == 1
end
