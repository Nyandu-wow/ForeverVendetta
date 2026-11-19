local _, A = ...

-- Early builds stored UnitFullName's surname in the realm field. Move those records
-- onto the real realm so a manual add and a nameplate hit the same enemy.
function A.repairStore()
    local realm = A.realm()
    local norm = realm:lower()
    if norm == "" or type(A.store) ~= "table" then return end
    local function bad(name, suffix)
        local last = A.plain(name, "string") and name:match("%s(%S+)$")
        return last and A.plain(suffix, "string") and last:lower() == suffix:gsub("%s", ""):lower() and last:lower() ~= norm
    end
    local function movedKey(name, suffix)
        if not bad(name, suffix) then return nil end
        local who = A.identity(name, realm)
        return who and who.key or nil
    end
    local reports = {}
    for owner, bucket in pairs(type(A.store.reports) == "table" and A.store.reports or {}) do
        local ownerName, ownerSuffix = owner:match("^(.*)%-([^%-]+)$")
        local newOwner = movedKey(ownerName, ownerSuffix) or owner
        local dest = reports[newOwner] or {}
        if type(bucket) == "table" then
            for key, r in pairs(bucket) do
                local place = key
                if type(r) == "table" and bad(r.name, r.realm) then
                    local enemy = movedKey(r.name, r.realm)
                    if enemy then r.realm = realm; place = enemy end
                end
                local prev = dest[place]
                if type(r) == "table" and (type(prev) ~= "table" or (tonumber(r.rev) or 0) > (tonumber(prev.rev) or 0)) then
                    dest[place] = r
                end
            end
        end
        reports[newOwner] = dest
    end
    local owners, friends = {}, {}
    for key, value in pairs(type(A.store.owners) == "table" and A.store.owners or {}) do
        local name, suffix = key:match("^(.*)%-([^%-]+)$")
        owners[movedKey(name, suffix) or key] = owners[movedKey(name, suffix) or key] or value
    end
    for key, peer in pairs(type(A.store.friends) == "table" and A.store.friends or {}) do
        local newKey = key
        if type(peer) == "table" and bad(peer.name, peer.realm) then
            local who = A.identity(peer.name, realm)
            if who then peer.realm, peer.key, newKey = realm, who.key, who.key end
        end
        friends[newKey] = peer
    end
    A.store.reports, A.store.owners, A.store.friends = reports, owners, friends
end

function A.init()
    ForeverVendettaDB = ForeverVendettaDB or {}
    A.db = ForeverVendettaDB
    if type(A.db.realms) ~= "table" then A.db.realms = {} end
    local realm = A.realm()
    if realm == "" then return false end
    local key = realm:lower()
    local store = A.db.realms[key]
    if type(store) ~= "table" then store = {} end
    if type(store.friends) ~= "table" then store.friends = {} end
    if type(store.reports) ~= "table" then store.reports = {} end
    if type(store.owners) ~= "table" then store.owners = {} end
    if type(store.settings) ~= "table" then store.settings = {} end
    A.db.realms[key] = store
    A.store = store
    A.me = A.unitName("player")
    if not A.me then return false end
    A.repairStore()
    A.store.owners[A.me.key] = A.me.name
    if type(A.store.reports[A.me.key]) ~= "table" then A.store.reports[A.me.key] = {} end
    local s = A.store.settings
    if s.sound == nil then s.sound = true end
    if not A.soundById(s.alertSound) then s.alertSound = "raid" end
    if s.banner == nil then s.banner = true end
    if s.instances == nil then s.instances = false end
    if s.minimapButton == nil then s.minimapButton = true end
    s.minimapAngle = tonumber(s.minimapAngle) or 220
    s.cooldown = tonumber(s.cooldown) or 60
    A.lastAlert, A.lastSeen = {}, {}
    A.ready = true
    return true
end

function A.changed()
    if A.refresh then A.refresh() end
    if A.refreshOptions then A.refreshOptions() end
end

function A.trust(name)
    local who = A.sender(name)
    if not who or who.key == A.me.key then return false, "Enter your friend's full character name." end
    if who.realm:gsub("%s", ""):lower() ~= A.realm():gsub("%s", ""):lower() then
        return false, "This first version shares with friends on your realm."
    end
    if not A.store.friends[who.key] and A.count(A.store.friends) >= A.MAX_FRIENDS then
        return false, "Friend limit reached (20)."
    end
    A.store.friends[who.key] = who
    A.changed()
    return true
end

function A.untrust(name)
    local who = A.sender(name)
    if not who then return false end
    A.store.friends[who.key] = nil
    if not A.store.owners[who.key] then A.store.reports[who.key] = nil end
    if type(A.store.lastReceived) == "table" then A.store.lastReceived[who.key] = nil end
    if A.dropPeer then A.dropPeer(who.key) end
    A.changed()
    return true
end

function A.validReport(r)
    return type(r) == "table" and A.plain(r.name, "string") and A.plain(r.realm, "string")
        and A.plain(r.note, "string") and A.identity(r.name, r.realm) ~= nil
        and A.text(r.name, 64) == r.name and A.text(r.realm, 48) == r.realm
        and A.plain(r.rev, "number") and r.rev >= 1 and r.rev <= 2147483647 and r.rev == math.floor(r.rev)
        and type(r.deleted) == "boolean" and A.modes[r.mode] == true
        and A.text(r.note, 96) == r.note
end

function A.merge(owner, r)
    if not A.validReport(r) then return false end
    local who = A.identity(r.name, r.realm)
    local bucket = A.store.reports[owner] or {}
    local old = bucket[who.key]
    if old and old.rev >= r.rev then return false end
    -- Tombstones count towards this bound. Never evict a removal and revive stale data.
    if not old and A.count(bucket) >= A.MAX_REPORTS then return false end
    -- Withdrawn reports keep identity for sync, but reasons should not linger locally.
    if r.deleted then r = { name = r.name, realm = r.realm, note = "", mode = r.mode, rev = r.rev, deleted = true } end
    A.store.reports[owner] = bucket
    bucket[who.key] = r
    A.changed()
    return true
end

function A.report(name, note, mode, deleted, realm)
    local who = A.identity(name, realm)
    note, mode = A.text(note or "", 96), mode or "AVENGE"
    if not who or not note or not A.modes[mode] then return false, "Use a full name, a reason up to 96 bytes, and AVENGE / AVOID / WATCH." end
    local old = A.store.reports[A.me.key][who.key]
    local r = { name = who.name, realm = who.realm, note = deleted and "" or note, mode = mode,
        rev = old and old.rev + 1 or 1, deleted = deleted == true }
    if not A.merge(A.me.key, r) then return false, "Report limit reached (200, including removals)." end
    if A.broadcast then A.broadcast(r) end
    return true
end

function A.targetReport(note, mode)
    if not A.flag(UnitIsPlayer, "target") or not A.flag(UnitIsEnemy, "player", "target") then
        return false, "Target an enemy player first."
    end
    local who = A.unitName("target")
    if not who then return false, "Target identity is unavailable. Try outside combat." end
    return A.report(who.name, note, mode, false, who.realm)
end

function A.entries()
    local rows = {}
    for owner, bucket in pairs(A.store.reports) do
        if A.store.owners[owner] or A.store.friends[owner] then
            for key, r in pairs(bucket) do
                if not r.deleted then
                    rows[#rows + 1] = { key = key, owner = owner, report = r }
                end
            end
        end
    end
    table.sort(rows, function(a, b)
        if a.key == b.key then return a.owner < b.owner end
        return a.key < b.key
    end)
    return rows
end

function A.match(key)
    local name = A.enemyName(key)
    local matches = {}
    for owner, bucket in pairs(A.store.reports) do
        if name and (A.store.owners[owner] or A.store.friends[owner]) then
            for stored, r in pairs(bucket) do
                if A.enemyName(stored) == name and not r.deleted then
                    matches[#matches + 1] = { owner = owner, report = r }
                end
            end
        end
    end
    table.sort(matches, function(a, b) return a.owner < b.owner end)
    return matches
end
