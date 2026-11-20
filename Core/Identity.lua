local _, A = ...

-- Realm comes only from the realm APIs. Never boolean-test a secret return.
function A.realm()
    local r = A.call(GetNormalizedRealmName)
    if not (A.plain(r, "string") and r ~= "") then r = A.call(GetRealmName) end
    r = A.text(r, 48) or ""
    return (r:gsub("%s+", ""))
end

local function token(v)
    if A.plain(v, "string") and v ~= "" then return v end
end

-- Current Forever (1.60.1, build 70009+): UnitName, UnitNameUnmodified, and UnitFullName
-- return first name, surname. The second value is not a realm. Older builds sometimes
-- returned the full "First Last" plus a real realm. GetUnitName returns "First Last".
-- A single token is incomplete, so detection refuses it instead of matching the first name.
function A.unitName(unit)
    local realm = A.realm()
    local norm = realm:lower()
    local function fullFrom(first, second)
        first = token(first)
        if not first then return nil end
        local lower = first:lower()
        if lower == "unknown" or lower == "unknown entity" then return nil end
        if first:find("%s") then
            -- GetUnitName(..., true) often appends "-Realm". Forever identity forbids
            -- hyphens in the character name, so strip any trailing -Token once the body
            -- is already First Last — even when the realm label does not match ours.
            local body, suffix = first:match("^(.*)%-([^%-]+)$")
            if body and body:find("%s") and suffix then
                return body
            end
            return first
        end
        second = token(second)
        if second and not second:find("[%s%-]") and second:gsub("%s", ""):lower() ~= norm then
            return first .. " " .. second
        end
    end
    local best, blocked = nil, false
    local function hidden(v)
        if v == nil then return false end
        if issecretvalue and issecretvalue(v) then return true end
        if canaccessvalue and not canaccessvalue(v) then return true end
        return false
    end
    -- One secret name component makes the unit inaccessible. Do not backfill it
    -- from a different call that happened to return a plain string.
    local function consider(first, second)
        if hidden(first) or hidden(second) then blocked = true end
        if blocked then return end
        local full = fullFrom(first, second)
        -- Only keep candidates that identity will accept (avoids a hyphenated
        -- GetUnitName result blocking a later clean UnitName pair).
        if full and full:find("%s") and A.identity(full, realm) then best = best or full end
    end
    -- Prefer APIs that return First + Last separately before GetUnitName with server.
    if type(UnitNameUnmodified) == "function" then consider(A.call(UnitNameUnmodified, unit)) end
    if type(UnitName) == "function" then consider(A.call(UnitName, unit)) end
    if type(UnitFullName) == "function" then consider(A.call(UnitFullName, unit)) end
    if type(GetUnitName) == "function" then
        consider(A.call(GetUnitName, unit, false))
        consider(A.call(GetUnitName, unit, true))
    end
    if blocked or not best then return nil end
    return A.identity(best, realm)
end

function A.identity(name, realm)
    name = A.text(name, 64)
    realm = A.text(realm or A.realm(), 48)
    if not name or name == "" or not realm or realm == "" then return nil end
    if name:find("[-;]") or name:lower() == "unknown" or name:lower() == "unknown entity" then return nil end
    local key = name:lower() .. "-" .. realm:gsub("%s", ""):lower()
    return { name = name, realm = realm, key = key }
end

-- Chat and addon senders are "First Last" or "First-Last". The hyphen is the surname.
-- A "-Realm" suffix is accepted only when it is our realm and the name already has a space.
function A.sender(name)
    if not A.plain(name, "string") then return nil end
    local realm = A.realm()
    local norm = realm:lower()
    local body, suffix = name:match("^(.*)%-([^%-]+)$")
    if body and suffix and body:find("%s") and norm ~= "" and suffix:gsub("%s", ""):lower() == norm then
        return A.identity(body, realm)
    end
    local first, last = name:match("^(%S+)%-(%S+)$")
    if first and last then return A.identity(first .. " " .. last, realm) end
    return A.identity(name, realm)
end

function A.personName(key)
    if A.me and key == A.me.key then return A.me.name end
    local friend = A.store and A.store.friends and A.store.friends[key]
    if type(friend) == "table" and A.plain(friend.name, "string") then return friend.name end
    local stored = A.store and A.store.owners and A.store.owners[key]
    if A.plain(stored, "string") then return stored end
    if not A.plain(key, "string") then return "Unknown" end
    return (key:match("^(.-)%-[^%-]+$")) or key
end

-- Forever full names are unique in the region. Match the name even when two clients'
-- realm strings differ (ruleset label versus an internal shard name).
-- Place-scoped slots use "|p:world" / "|p:battleground"; strip that first.
function A.enemyName(key)
    if not A.plain(key, "string") then return nil end
    if A.splitSlot then
        local enemyKey = A.splitSlot(key)
        key = enemyKey or key
    else
        key = key:match("^(.-)|p:") or key
    end
    return (key:match("^(.*)%-[^%-]+$")) or key
end
