local _, A = ...

A.PLACES = { world = true, battleground = true }

function A.normalizePlace(place)
    if place == "battleground" or place == "bg" or place == "pvp" then return "battleground" end
    if place == "world" or place == nil or place == "" then return "world" end
    return nil
end

function A.placeOrWorld(place)
    return A.normalizePlace(place) or "world"
end

function A.tabPlace(view)
    if view == "battlegrounds" then return "battleground" end
    return "world"
end

-- Storage slot for one enemy report in one place. Legacy keys have no |p: suffix.
function A.slotKey(enemyKey, place)
    if not A.plain(enemyKey, "string") then return nil end
    return enemyKey .. "|p:" .. A.normalizePlace(place)
end

function A.splitSlot(slot)
    if not A.plain(slot, "string") then return nil, "world" end
    local key, place = slot:match("^(.-)|p:(.+)$")
    if key then return key, A.normalizePlace(place) end
    return slot, "world"
end

-- Shared UI/chat labels for report stances (not whispered).
A.STANCE_LABEL = { AVENGE = "Avenge", AVOID = "Avoid", WATCH = "Watch" }

function A.stanceLabel(mode)
    return (mode and A.STANCE_LABEL[mode]) or "Listed"
end

-- Place filter for alerts/badges: world and battleground are strict; arenas match any listed place.
function A.alertPlaceFilter()
    local here = A.pvpPlace and A.pvpPlace() or "world"
    if here == "battleground" then return "battleground", here end
    if here == "world" then return "world", here end
    return nil, here
end

-- Where the player is right now, from instance/PvP APIs when readable.
-- world | battleground | arena | instance | unknown
function A.pvpPlace()
    local inInstance, instanceType = A.call(IsInInstance)
    if A.plain(instanceType, "string") then
        local t = instanceType:lower()
        if t == "pvp" then return "battleground" end
        if t == "arena" then return "arena" end
        if t == "party" or t == "raid" or t == "scenario" then return "instance" end
        if t == "none" then return "world" end
    end
    if inInstance == true then
        if type(C_PvP) == "table" and A.flag(C_PvP.IsPVPMap) then return "battleground" end
        return "instance"
    end
    if inInstance == false then return "world" end
    if type(C_PvP) == "table" and A.flag(C_PvP.IsPVPMap) then return "battleground" end
    return "unknown"
end

function A.pvpPlaceLabel(place)
    place = place or A.pvpPlace()
    if place == "battleground" then return "Battleground" end
    if place == "arena" then return "Arena" end
    if place == "instance" then return "Instance" end
    if place == "world" then return "World" end
    return "Unknown"
end

-- True when alerts are allowed in the current place. Defaults:
-- world on, battlegrounds off, arenas off. Dungeons/raids never alert.
-- settings.instances is the SavedVariables key for the arenas toggle (kept for older builds).
function A.alertsAllowedHere()
    local place = A.pvpPlace()
    local s = A.store and A.store.settings
    if type(s) ~= "table" then return place == "world" end
    if place == "world" then return s.world ~= false end
    if place == "battleground" then return s.battlegrounds == true end
    if place == "arena" then return s.instances == true end
    if place == "instance" then return false end
    return false
end

local function pushFriend(out, seen, name)
    local who = A.sender(name) or A.identity(name)
    if not who or not who.name:find("%s") then return end
    if who.key == (A.me and A.me.key) then return end
    if seen[who.key] then return end
    seen[who.key] = true
    out[#out + 1] = who
end

local function readFriendInfoName(info)
    if type(info) ~= "table" then return nil end
    if A.plain(info.name, "string") then return info.name end
    if A.plain(info.absoluteName, "string") then return info.absoluteName end
end

-- Collect readable First Last names from the in-game friends list and Battle.net
-- characters on this realm. Convenience only — never auto-trusts anyone.
function A.gameFriends()
    local out, seen = {}, {}
    local realm = A.realm()
    local norm = realm:gsub("%s", ""):lower()

    if type(C_FriendList) == "table" then
        local n = A.call(C_FriendList.GetNumFriends)
        if A.plain(n, "number") then
            for i = 1, n do
                local info = A.call(C_FriendList.GetFriendInfoByIndex, i)
                if not info and type(C_FriendList.GetFriendInfo) == "function" then
                    -- Older signature path; skip if index API missing.
                end
                pushFriend(out, seen, readFriendInfoName(info))
            end
        end
    end

    if type(C_BattleNet) == "table" and type(C_BattleNet.GetFriendAccountInfo) == "function" then
        local n = A.call(C_BattleNet.GetNumFriends) or A.call(BNGetNumFriends)
        if A.plain(n, "number") then
            for i = 1, n do
                local account = A.call(C_BattleNet.GetFriendAccountInfo, i)
                local g = account and account.gameAccountInfo
                if type(g) == "table" then
                    local realmName = g.realmName or g.realmDisplayName
                    local sameRealm = true
                    if A.plain(realmName, "string") and norm ~= "" then
                        sameRealm = realmName:gsub("%s", ""):lower() == norm
                    end
                    if sameRealm then pushFriend(out, seen, g.characterName) end
                end
            end
        end
    end

    table.sort(out, function(a, b) return a.name < b.name end)
    return out
end
