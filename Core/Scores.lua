local _, A = ...

-- Local death/kill tallies from death recap, damage meter, and PARTY_KILL —
-- not the combat log. Never whispered.

local SETTLE = 0.6
local KILL_DEDUPE = 5
local ATTACKER_CAP = 12
local lastKillAt = {}
local attackers = {}

local function scoreKey(enemyKey, place)
    return A.slotKey(enemyKey, place or A.normalizePlace(A.pvpPlace and A.pvpPlace() or "world"))
end

function A.scoreFor(enemyKey, place)
    if not A.store then return { deaths = 0, kills = 0 } end
    A.store.scores = A.store.scores or {}
    local slot = scoreKey(enemyKey, place)
    local row = A.store.scores[slot]
    if type(row) ~= "table" then return { deaths = 0, kills = 0 } end
    return {
        deaths = tonumber(row.deaths) or 0,
        kills = tonumber(row.kills) or 0,
    }
end

local function bump(enemyKey, place, field)
    if not A.plain(enemyKey, "string") then return end
    A.store.scores = A.store.scores or {}
    local slot = scoreKey(enemyKey, place)
    local row = A.store.scores[slot] or { deaths = 0, kills = 0 }
    row[field] = (tonumber(row[field]) or 0) + 1
    A.store.scores[slot] = row
    if A.changed then A.changed() end
end

local function isPlayerGuid(guid)
    return A.plain(guid, "string") and guid:sub(1, 7) == "Player-"
end

-- Live units only — used when death recap has a name but no Player GUID.
local function confirmLivePlayer(name)
    if not A.plain(name, "string") or name == "" then return false end
    local want = name:lower()
    local function match(unit)
        if not A.flag(UnitExists, unit) or not A.flag(UnitIsPlayer, unit) then return false end
        if not A.flag(UnitIsEnemy, "player", unit) then return false end
        local who = A.unitName(unit)
        return who and who.name:lower() == want
    end
    for _, unit in ipairs({ "target", "focus", "mouseover", "targettarget" }) do
        if match(unit) then return true end
    end
    if C_NamePlate and type(C_NamePlate.GetNamePlates) == "function" then
        local plates = A.call(C_NamePlate.GetNamePlates) or {}
        for i = 1, #plates do
            local unit = plates[i] and plates[i].namePlateUnitToken
            if A.plain(unit, "string") and match(unit) then return true end
        end
    end
    return false
end

local function readRecap()
    local recap = C_DeathRecap
    if type(recap) ~= "table" or type(recap.HasRecapEvents) ~= "function" or type(recap.GetRecapEvents) ~= "function" then
        return nil
    end
    if not A.flag(recap.HasRecapEvents) then return nil end
    local events = A.call(recap.GetRecapEvents)
    if type(events) ~= "table" or #events == 0 then return nil end
    local read = { damage = {}, killer = nil, guids = {} }
    for i = 1, #events do
        local event = events[i]
        if type(event) == "table" then
            local name = event.sourceName
            if A.plain(name, "string") and name ~= "" then
                local guid = event.sourceGUID
                if A.plain(guid, "string") then read.guids[name] = guid end
                if i == 1 then read.killer = name end
                local amount = event.amount
                local hit = A.plain(amount, "number") and amount or 0
                read.damage[name] = (read.damage[name] or 0) + hit
            end
        end
    end
    return read
end

-- Only Player GUID, damage-meter (non-mob), or a live enemy player unit.
local function acceptPlayerSource(name, guid)
    if not A.plain(name, "string") or name == "" then return false end
    if isPlayerGuid(guid) then return true end
    if A.plain(guid, "string") then return false end -- known Creature/Pet/Vehicle etc.
    return confirmLivePlayer(name)
end

local function damageTakenNames()
    local meter = C_DamageMeter
    if type(meter) ~= "table" or type(meter.GetCombatSessionSourceFromType) ~= "function" then return nil end
    if not (Enum and Enum.DamageMeterType and Enum.DamageMeterSessionType) then return nil end
    local guid = A.call(UnitGUID, "player")
    if not A.plain(guid, "string") then return nil end
    local ok, source = pcall(meter.GetCombatSessionSourceFromType,
        Enum.DamageMeterSessionType.Current, Enum.DamageMeterType.DamageTaken, guid)
    if not ok or type(source) ~= "table" then return nil end
    local spells = source.combatSpells
    if type(spells) ~= "table" then return nil end
    local names = {}
    for i = 1, #spells do
        local spell = spells[i]
        local details = spell and spell.combatSpellDetails
        local name = details and details.unitName
        if A.plain(name, "string") and name ~= "" and A.me and name ~= A.me.name then
            if not (details.isMob == true or details.isPet == true) then
                names[name] = true
            end
        end
    end
    return names
end

-- Session-only attackers (death recap / damage taken / targeting you). Not whispered.
function A.noteAttacker(who, place, why)
    if not who or not A.plain(who.key, "string") then return end
    place = A.normalizePlace(place or "world")
    local now = A.clock() or 0
    for i = #attackers, 1, -1 do
        if attackers[i].key == who.key and attackers[i].place == place then
            table.remove(attackers, i)
        end
    end
    table.insert(attackers, 1, {
        key = who.key,
        name = who.name,
        realm = who.realm,
        place = place,
        why = A.plain(why, "string") and why or "Attacked you",
        ts = now,
    })
    while #attackers > ATTACKER_CAP do attackers[#attackers] = nil end
    if A.changed then A.changed() end
end

function A.recentAttackers(placeFilter)
    placeFilter = placeFilter and A.normalizePlace(placeFilter) or nil
    local rows = {}
    for i = 1, #attackers do
        local row = attackers[i]
        if not placeFilter or row.place == placeFilter then
            rows[#rows + 1] = row
        end
    end
    return rows
end

function A.clearAttackers()
    for i = #attackers, 1, -1 do attackers[i] = nil end
    if A.changed then A.changed() end
end

local function creditDeath(names, place)
    local credited = {}
    for name in pairs(names) do
        local who = A.sender(name) or A.identity(name)
        if who then
            bump(who.key, place, "deaths")
            A.noteAttacker(who, place, "Death recap")
            credited[#credited + 1] = who.name
        end
    end
    return credited
end

-- Prefer the death-recap killer row among confirmed players, else highest damage, else any name.
local function pickKiller(recap, names)
    names = names or {}
    if recap and A.plain(recap.killer, "string") and names[recap.killer] then
        local who = A.sender(recap.killer) or A.identity(recap.killer)
        if who then return who end
    end
    local bestName, bestHit = nil, -1
    if recap and type(recap.damage) == "table" then
        for name, hit in pairs(recap.damage) do
            if names[name] then
                local amount = tonumber(hit) or 0
                if amount > bestHit then
                    local who = A.sender(name) or A.identity(name)
                    if who then bestName, bestHit = who, amount end
                end
            end
        end
    end
    if bestName then return bestName end
    for name in pairs(names) do
        local who = A.sender(name) or A.identity(name)
        if who then return who end
    end
    return nil
end

function A.considerKillerOffer(who, place)
    if not A.ready or not who then return false end
    if A.store.settings.deathOffer == false then return false end
    place = A.normalizePlace(place or "world")
    local slot = A.slotKey(who.key, place)
    local mine = A.store.reports[A.me.key] and A.store.reports[A.me.key][slot]
    if type(mine) == "table" and not mine.deleted then return false end
    A.pendingKiller = { name = who.name, realm = who.realm, key = who.key, place = place }
    if A.showKillerOffer then A.showKillerOffer(A.pendingKiller) end
    return true
end

function A.acceptKillerOffer(mode, note)
    local pending = A.pendingKiller
    if not pending then return false, "No death offer waiting." end
    note = A.plain(note, "string") and note or "Killed me"
    mode = mode or "AVENGE"
    local ok, err = A.report(pending.name, note, mode, false, pending.realm, pending.place)
    A.pendingKiller = nil
    if A.hideKillerOffer then A.hideKillerOffer() end
    return ok, err
end

function A.dismissKillerOffer()
    A.pendingKiller = nil
    if A.hideKillerOffer then A.hideKillerOffer() end
end

function A.resolveMyDeath()
    if not A.ready then return end
    local place = A.normalizePlace(A.pvpPlace and A.pvpPlace() or "world")
    if place == "battleground" and A.store.settings.battlegrounds ~= true and A.store.settings.scoreBattlegrounds ~= true then
        -- Still count deaths in BG if the player uses the BG tab; scores are local.
    end
    -- Confirmed enemy players only — never pop Add-killer for a PvE mob.
    local names = {}
    local recap = readRecap()
    if recap then
        local function try(name)
            local guid = recap.guids and recap.guids[name]
            if acceptPlayerSource(name, guid) then names[name] = true end
        end
        for name in pairs(recap.damage) do try(name) end
        if A.plain(recap.killer, "string") then try(recap.killer) end
    end
    local meter = damageTakenNames()
    if meter then
        for name in pairs(meter) do names[name] = true end
    end
    if not next(names) then
        for _, unit in ipairs({ "target", "focus", "mouseover" }) do
            if A.flag(UnitExists, unit) and A.flag(UnitIsPlayer, unit) and A.flag(UnitIsEnemy, "player", unit) then
                local target = A.unitName(unit)
                if target then names[target.name] = true; break end
            end
        end
    end
    if not next(names) then return end
    creditDeath(names, place)
    local killer = pickKiller(recap, names)
    if killer then A.considerKillerOffer(killer, place) end
end

function A.recordMyKill(victimName)
    if not A.ready or not A.plain(victimName, "string") then return end
    local who = A.sender(victimName) or A.identity(victimName)
    if not who then return end
    local now = A.clock() or 0
    if lastKillAt[who.key] and now - lastKillAt[who.key] < KILL_DEDUPE then return end
    lastKillAt[who.key] = now
    bump(who.key, A.normalizePlace(A.pvpPlace and A.pvpPlace() or "world"), "kills")
end

function A.onPartyKill(attackerGUID, victimGUID)
    if not A.ready then return end
    local me = A.call(UnitGUID, "player")
    local pet = A.call(UnitGUID, "pet")
    local mine = A.plain(attackerGUID, "string") and A.plain(me, "string") and attackerGUID == me
    if not mine and A.plain(pet, "string") and attackerGUID == pet then mine = true end
    if not mine then return end
    local victim = A.unitName("target")
    if victim and A.plain(victimGUID, "string") then
        local targetGuid = A.call(UnitGUID, "target")
        if A.plain(targetGuid, "string") and targetGuid == victimGUID then
            A.recordMyKill(victim.name)
            return
        end
    end
    -- GUID match failed; if target is an enemy player, credit them when we got the kill event.
    if victim and A.flag(UnitIsPlayer, "target") and A.flag(UnitIsEnemy, "player", "target") then
        A.recordMyKill(victim.name)
    end
end

function A.onPlayerDead()
    if not A.ready then return end
    local after = function() A.resolveMyDeath() end
    if C_Timer and C_Timer.After then
        C_Timer.After(SETTLE, after)
    else
        after()
    end
end

-- Enemy player currently targeting you (target's target is you).
function A.scanAttackerFocus()
    if not A.ready then return end
    if not A.flag(UnitExists, "target") or not A.flag(UnitIsPlayer, "target") then return end
    if not A.flag(UnitIsEnemy, "player", "target") then return end
    if not A.flag(UnitIsUnit, "targettarget", "player") then return end
    local who = A.unitName("target")
    if not who then return end
    A.noteAttacker(who, A.normalizePlace(A.pvpPlace and A.pvpPlace() or "world"), "Targeting you")
end
