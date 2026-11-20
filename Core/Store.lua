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
    -- A.realm() always returns a usable bucket (Forever fallback). First Last is identity.
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
    if type(A.store.scores) ~= "table" then A.store.scores = {} end
    if type(A.store.sightings) ~= "table" then A.store.sightings = {} end
    if type(A.store.ignored) ~= "table" then A.store.ignored = {} end
    if A.migratePlaces then A.migratePlaces() end
    local s = A.store.settings
    if s.sound == nil then s.sound = true end
    if not A.soundById(s.alertSound) then s.alertSound = "raid" end
    if s.banner == nil then s.banner = true end
    if s.world == nil then s.world = true end
    if s.battlegrounds == nil then s.battlegrounds = false end
    if s.instances == nil then s.instances = false end
    if s.minimapButton == nil then s.minimapButton = true end
    if s.deathOffer == nil then s.deathOffer = true end
    if s.tooltips == nil then s.tooltips = true end
    if s.targetButton == nil then s.targetButton = true end
    if s.partyAnnounce == nil then s.partyAnnounce = false end
    if s.nameplateBadge == nil then s.nameplateBadge = true end
    s.minimapAngle = tonumber(s.minimapAngle) or 220
    s.cooldown = tonumber(s.cooldown) or 60
    A.lastAlert = {}
    A.pendingKiller = nil
    A.invalidateMatchIndex()
    A.ready = true
    return true
end

-- Mute alerts for a listed enemy without withdrawing reports. Local only — not whispered.
function A.isIgnored(enemyKey)
    if not A.store or type(A.store.ignored) ~= "table" or not A.plain(enemyKey, "string") then return false end
    return type(A.store.ignored[enemyKey]) == "table"
end

function A.ignoreEnemy(name, realm)
    local who = A.sender(name) or A.identity(name, realm)
    if not who then return false, "Use a full character name." end
    A.store.ignored = A.store.ignored or {}
    A.store.ignored[who.key] = { name = who.name, realm = who.realm }
    if A.changed then A.changed() end
    return true
end

function A.unignoreEnemy(name, realm)
    local who = A.sender(name) or A.identity(name, realm)
    if not who or not A.store.ignored then return false, "That enemy is not muted." end
    if not A.store.ignored[who.key] then return false, "That enemy is not muted." end
    A.store.ignored[who.key] = nil
    if A.changed then A.changed() end
    return true
end

-- Zone + clock when a listed enemy was last visible to this client.
function A.recordSighting(enemyKey, place)
    if not A.ready or not A.plain(enemyKey, "string") then return end
    place = A.normalizePlace(place or "world")
    A.store.sightings = A.store.sightings or {}
    local zone = A.call(GetZoneText) or A.call(GetRealZoneText) or ""
    if not A.plain(zone, "string") then zone = "" end
    A.store.sightings[A.slotKey(enemyKey, place)] = { ts = A.clock() or 0, zone = zone }
end

function A.sightingFor(enemyKey, place)
    if not A.store or type(A.store.sightings) ~= "table" or not A.plain(enemyKey, "string") then return nil end
    local row = A.store.sightings[A.slotKey(enemyKey, A.normalizePlace(place or "world"))]
    if type(row) ~= "table" then return nil end
    return { ts = tonumber(row.ts) or 0, zone = A.plain(row.zone, "string") and row.zone or "" }
end

-- Count local sighting slots. placeFilter nil = all places; otherwise world|battleground.
function A.sightingCount(placeFilter)
    if not A.store or type(A.store.sightings) ~= "table" then return 0 end
    placeFilter = placeFilter and A.normalizePlace(placeFilter) or nil
    local n = 0
    for key, row in pairs(A.store.sightings) do
        if type(row) == "table" and (tonumber(row.ts) or 0) > 0 then
            if not placeFilter then
                n = n + 1
            else
                local _, place = A.splitSlot(key)
                if A.normalizePlace(place) == placeFilter then n = n + 1 end
            end
        end
    end
    return n
end

function A.formatSeenWhen(seen, now)
    if type(seen) ~= "table" then return nil end
    local ts = tonumber(seen.ts) or 0
    if ts <= 0 then return nil end
    now = tonumber(now) or A.clock() or 0
    local ago = math.max(0, math.floor(now - ts))
    if ago < 60 then return "just now" end
    if ago < 3600 then return math.floor(ago / 60) .. "m ago" end
    if ago < 86400 then return math.floor(ago / 3600) .. "h ago" end
    return math.floor(ago / 86400) .. "d ago"
end

-- Short label for list rows: "Elwynn 3m ago" or "3m ago".
function A.formatSeenShort(seen, now)
    local when = A.formatSeenWhen(seen, now)
    if not when then return "" end
    local zone = type(seen) == "table" and A.plain(seen.zone, "string") and seen.zone or ""
    if zone ~= "" then
        if #zone > 14 then zone = zone:sub(1, 13) .. "..." end
        return zone .. " · " .. when
    end
    return when
end

-- Move legacy enemy-only keys onto place-scoped slots. Missing place → world.
function A.migratePlaces()
    if type(A.store.reports) ~= "table" then return end
    for owner, bucket in pairs(A.store.reports) do
        if type(bucket) == "table" then
            local neu = {}
            for key, r in pairs(bucket) do
                if type(r) == "table" then
                    local enemyKey, place = A.splitSlot(key)
                    place = A.placeOrWorld(r.place or place)
                    r.place = place
                    local slot = A.slotKey(enemyKey, place)
                    local prev = neu[slot]
                    if not prev or (tonumber(r.rev) or 0) > (tonumber(prev.rev) or 0) then
                        neu[slot] = r
                    end
                end
            end
            A.store.reports[owner] = neu
        end
    end
    A.invalidateMatchIndex()
end

function A.changed()
    if A.refresh then A.refresh() end
    if A.refreshOptions then A.refreshOptions() end
end

function A.trust(name)
    local who = A.sender(name)
    -- Forever identity is First Last (or First-Last on the wire). Slash path must match the Friends UI.
    if not who or not who.name:find("%s") or who.key == A.me.key then
        return false, "Enter your friend's first name and surname."
    end
    if who.realm:gsub("%s", ""):lower() ~= A.realm():gsub("%s", ""):lower() then
        return false, "This first version shares with friends on your realm."
    end
    if not A.store.friends[who.key] and A.count(A.store.friends) >= A.MAX_FRIENDS then
        return false, "Friend limit reached (20)."
    end
    A.store.friends[who.key] = who
    A.invalidateMatchIndex()
    A.changed()
    return true
end

function A.untrust(name)
    local who = A.sender(name)
    if not who then return false end
    A.store.friends[who.key] = nil
    if not A.store.owners[who.key] then A.store.reports[who.key] = nil end
    if type(A.store.lastReceived) == "table" then A.store.lastReceived[who.key] = nil end
    if type(A.store.lastHeard) == "table" then A.store.lastHeard[who.key] = nil end
    if type(A.store.lastSent) == "table" then A.store.lastSent[who.key] = nil end
    if A.dropPeer then A.dropPeer(who.key) end
    A.invalidateMatchIndex()
    A.changed()
    return true
end

function A.validReport(r)
    return type(r) == "table" and A.plain(r.name, "string") and A.plain(r.realm, "string")
        and A.plain(r.note, "string") and r.name:find("%s") ~= nil
        and A.identity(r.name, r.realm) ~= nil
        and A.text(r.name, 64) == r.name and A.text(r.realm, 48) == r.realm
        and A.plain(r.rev, "number") and r.rev >= 1 and r.rev <= 2147483647 and r.rev == math.floor(r.rev)
        and type(r.deleted) == "boolean" and A.modes[r.mode] == true
        and A.text(r.note, 96) == r.note
        and (r.place == nil or A.normalizePlace(r.place) ~= nil)
end

function A.merge(owner, r)
    if not A.validReport(r) then return false end
    local who = A.identity(r.name, r.realm)
    local place = A.placeOrWorld(r.place)
    r.place = place
    local slot = A.slotKey(who.key, place)
    local bucket = A.store.reports[owner] or {}
    local old = bucket[slot]
    if old and old.rev >= r.rev then return false end
    -- Tombstones count towards this bound. Never evict a removal and revive stale data.
    if not old and A.count(bucket) >= A.MAX_REPORTS then return false end
    -- Withdrawn reports keep identity for sync, but reasons should not linger locally.
    if r.deleted then
        r = { name = r.name, realm = r.realm, note = "", mode = r.mode, rev = r.rev, deleted = true, place = place }
    end
    A.store.reports[owner] = bucket
    bucket[slot] = r
    A.invalidateMatchIndex()
    A.changed()
    return true
end

function A.report(name, note, mode, deleted, realm, place)
    local who = A.identity(name, realm)
    note, mode = A.text(note or "", 96), mode or "AVENGE"
    place = A.placeOrWorld(place or (A.listPlace and A.listPlace()) or "world")
    if not who or not who.name:find("%s") or not note or not A.modes[mode] then
        return false, "Use a full name, a reason up to 96 bytes, and AVENGE / AVOID / WATCH."
    end
    local slot = A.slotKey(who.key, place)
    local old = A.store.reports[A.me.key][slot]
    local r = { name = who.name, realm = who.realm, note = deleted and "" or note, mode = mode,
        rev = old and old.rev + 1 or 1, deleted = deleted == true, place = place }
    if not A.merge(A.me.key, r) then return false, "Report limit reached (200, including removals)." end
    if A.broadcast then A.broadcast(r) end
    return true
end

function A.targetReport(note, mode, place)
    if not A.flag(UnitIsPlayer, "target") or not A.flag(UnitIsEnemy, "player", "target") then
        return false, "Target an enemy player first."
    end
    local who = A.unitName("target")
    if not who then return false, "Target identity is unavailable. Try outside combat." end
    return A.report(who.name, note, mode, false, who.realm, place)
end

function A.entries(placeFilter)
    local rows = {}
    placeFilter = placeFilter and A.normalizePlace(placeFilter) or nil
    for owner, bucket in pairs(A.store.reports) do
        if A.store.owners[owner] or A.store.friends[owner] then
            for key, r in pairs(bucket) do
                if not r.deleted then
                    local place = A.normalizePlace(r.place)
                    if not placeFilter or place == placeFilter then
                        rows[#rows + 1] = { key = key, owner = owner, report = r, place = place }
                    end
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

-- Rebuild when reports/friends change. Lookup by enemy First Last (case-insensitive).
function A.invalidateMatchIndex()
    A._matchIndexDirty = true
end

function A.rebuildMatchIndex()
    local index = {}
    if A.store and type(A.store.reports) == "table" then
        for owner, bucket in pairs(A.store.reports) do
            if A.store.owners[owner] or A.store.friends[owner] then
                for stored, r in pairs(bucket) do
                    if type(r) == "table" and not r.deleted then
                        local name = A.enemyName(stored)
                        if name then
                            local fold = name:lower()
                            local list = index[fold]
                            if not list then
                                list = {}
                                index[fold] = list
                            end
                            list[#list + 1] = {
                                owner = owner,
                                report = r,
                                place = A.normalizePlace(r.place),
                            }
                        end
                    end
                end
            end
        end
    end
    for _, list in pairs(index) do
        table.sort(list, function(a, b) return a.owner < b.owner end)
    end
    A._matchIndex = index
    A._matchIndexDirty = false
end

-- Match listed enemies for alerts. placeFilter nil = any place (arenas).
function A.match(key, placeFilter)
    local name = A.enemyName(key)
    if not name then return {} end
    if A._matchIndexDirty or not A._matchIndex then A.rebuildMatchIndex() end
    placeFilter = placeFilter and A.normalizePlace(placeFilter) or nil
    local list = A._matchIndex[name:lower()]
    if not list then return {} end
    if not placeFilter then
        local copy = {}
        for i = 1, #list do copy[i] = list[i] end
        return copy
    end
    local matches = {}
    for i = 1, #list do
        local row = list[i]
        if row.place == placeFilter then matches[#matches + 1] = row end
    end
    return matches
end
