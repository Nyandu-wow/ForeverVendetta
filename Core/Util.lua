local _, A = ...
A.PREFIX = "FVendetta1"
A.MAX_REPORTS, A.MAX_FRIENDS = 200, 20
A.modes = { AVENGE = true, AVOID = true, WATCH = true }

-- Secret values throw on boolean tests, comparison, concatenation, and arithmetic.
-- issecretvalue itself is safe. type() is not consulted until the value is readable.
function A.plain(v, kind)
    if issecretvalue and issecretvalue(v) then return false end
    if canaccessvalue and not canaccessvalue(v) then return false end
    return type(v) == kind
end

function A.call(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b = pcall(fn, ...)
    if ok then return a, b end
end

local function utf8ok(s)
    local i, n = 1, #s
    while i <= n do
        local c = s:byte(i)
        local len = 1
        if c >= 0xC2 and c <= 0xDF then len = 2
        elseif c >= 0xE0 and c <= 0xEF then len = 3
        elseif c >= 0xF0 and c <= 0xF4 then len = 4
        elseif c >= 0x80 then return false end
        if i + len - 1 > n then return false end
        for j = 1, len - 1 do
            local cc = s:byte(i + j)
            if not cc or cc < 0x80 or cc > 0xBF then return false end
        end
        i = i + len
    end
    return true
end

-- Bound bytes on the wire; reject oversized or split UTF-8 rather than cutting a character.
function A.text(v, max)
    if not A.plain(v, "string") then return nil end
    v = v:gsub("[%c|]", " "):gsub("%s+", " "):match("^%s*(.-)%s*$")
    if #v > max or not utf8ok(v) then return nil end
    return v
end

function A.clock()
    local t = A.call(GetTime)
    if A.plain(t, "number") then return t end
end

function A.count(t)
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    return n
end

function A.print(msg)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cffff7055Vendetta|r: " .. msg) end
end

-- Keep in sync with ## Version in ForeverVendetta.toc (fallback when metadata APIs are missing).
A.VERSION = "0.1.40"

function A.addonVersion()
    local name = "ForeverVendetta"
    if C_AddOns and type(C_AddOns.GetAddOnMetadata) == "function" then
        local v = A.call(C_AddOns.GetAddOnMetadata, name, "Version")
        if A.plain(v, "string") and v ~= "" then return v end
    end
    if type(GetAddOnMetadata) == "function" then
        local v = A.call(GetAddOnMetadata, name, "Version")
        if A.plain(v, "string") and v ~= "" then return v end
    end
    return A.VERSION
end

-- Built-in Classic-era SoundKit / file ids only. Skip retail kits Forever may not ship.
-- Custom .ogg in the addon folder is also allowed (PlaySoundFile); do not redistribute ripped Blizzard music.
A.ALERT_SOUNDS = {
    { id = "raid", label = "Raid", file = 8959, kit = "RAID_WARNING" },
    { id = "ready", label = "Ready", file = 8960, kit = "READY_CHECK" },
    { id = "ping", label = "Ping", file = 3175, kit = "MAP_PING" },
    { id = "auction", label = "Auction", file = 5274, kit = "AUCTION_WINDOW_OPEN" },
    { id = "level", label = "Level", file = 888 },
    { id = "tell", label = "Tell", file = 3081, kit = "TELL_MESSAGE" },
    { id = "quest", label = "Quest", file = 878, kit = "IG_QUEST_LIST_COMPLETE" },
    { id = "coin", label = "Coin", file = 120, kit = "LOOT_WINDOW_COIN_SOUND" },
}

function A.soundById(id)
    if not A.plain(id, "string") then return nil end
    for _, sound in ipairs(A.ALERT_SOUNDS) do
        if sound.id == id then return sound end
    end
end

function A.flag(fn, ...)
    local value = A.call(fn, ...)
    return A.plain(value, "boolean") and value == true
end
