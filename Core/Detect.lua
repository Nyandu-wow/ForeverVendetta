local _, A = ...

A.faces = A.faces or {}

local function plainToken(value)
    if not A.plain(value, "string") or value == "" then return nil end
    if issecretvalue and issecretvalue(value) then return nil end
    return value:upper():gsub("%s+", "")
end

-- Session memory only. Class and race are not part of a report and are not whispered.
function A.rememberFace(unit, key)
    if not A.plain(key, "string") or key == "" then return end
    local _, classFile = A.call(UnitClass, unit)
    local _, raceFile = A.call(UnitRace, unit)
    local sex = A.call(UnitSex, unit)
    classFile, raceFile = plainToken(classFile), plainToken(raceFile)
    if not classFile and not raceFile then return end
    local face = A.faces[key] or {}
    if classFile then face.class = classFile end
    if raceFile then face.race = raceFile end
    if A.plain(sex, "number") and (sex == 2 or sex == 3) then face.sex = sex end
    A.faces[key] = face
    local name = A.enemyName(key)
    if name then A.faces[name] = face end
end

function A.faceFor(key)
    if not A.plain(key, "string") then return nil end
    return A.faces[key] or A.faces[A.enemyName(key) or ""]
end

function A.scanFaces()
    for _, unit in ipairs({ "target", "focus", "mouseover" }) do
        if A.flag(UnitIsPlayer, unit) then
            local who = A.unitName(unit)
            if who then A.rememberFace(unit, who.key) end
        end
    end
    local plates = type(C_NamePlate) == "table" and A.call(C_NamePlate.GetNamePlates)
    if type(plates) ~= "table" then return end
    for _, plate in ipairs(plates) do
        if type(plate) == "table" then
            local unit = plate.namePlateUnitToken or plate.unitToken
            if A.plain(unit, "string") and A.flag(UnitIsPlayer, unit) then
                local who = A.unitName(unit)
                if who then A.rememberFace(unit, who.key) end
            end
        end
    end
end

function A.playSound()
    local choice = A.soundById(A.store and A.store.settings and A.store.settings.alertSound) or A.ALERT_SOUNDS[1]
    local file = choice.file
    if choice.kit and type(SOUNDKIT) == "table" and A.plain(SOUNDKIT[choice.kit], "number") then
        file = SOUNDKIT[choice.kit]
    end
    A.call(PlaySound, file, "Master")
end

local function partyAnnounce(name, mode, where)
    if A.store.settings.partyAnnounce ~= true then return end
    if not A.flag(IsInGroup) then return end
    local channel = A.flag(IsInRaid) and "RAID" or "PARTY"
    -- Short only: no reason text in public/party chat.
    local line = "Vendetta: " .. name .. " — " .. A.stanceLabel(mode) .. " [" .. where .. "]"
    if #line > 240 then line = line:sub(1, 240) end
    A.call(SendChatMessage, line, channel)
end

function A.alert(name, matches, test, face, place)
    local first = matches[1]
    local mixed = false
    for i = 2, #matches do
        if matches[i].report.mode ~= first.report.mode then mixed = true break end
    end
    -- Chat stays short so screenshots and chat logs do not archive private reasons.
    -- The banner may show one author's reason, with that author's name attached.
    local prefix = test and "TEST - " or ""
    local where = A.pvpPlaceLabel(place or (not test and A.pvpPlace()) or "world")
    local mode = nil
    local title
    if mixed then
        title = prefix .. name .. " - " .. #matches .. " reports [" .. where .. "]"
    else
        mode = first.report.mode
        title = prefix .. name .. " - " .. A.stanceLabel(mode) .. " [" .. where .. "]"
    end
    local detail = first.report.note ~= "" and first.report.note or "Listed enemy"
    detail = detail .. " (" .. A.personName(first.owner) .. ")"
    if #matches > 1 then detail = detail .. " + " .. (#matches - 1) .. " more" end
    A.print(title)
    if A.store.settings.sound then A.playSound() end
    if A.store.settings.banner and A.showBanner then
        A.showBanner(title, detail, test, mode, face, not test and name or nil)
    end
    if not test then partyAnnounce(name, mode or first.report.mode, where) end
end

function A.detect(unit)
    if not A.ready then return end
    if not A.flag(UnitIsPlayer, unit) or not A.flag(UnitIsEnemy, "player", unit) then
        if A.clearPlateBadge then A.clearPlateBadge(unit) end
        return
    end
    local who = A.unitName(unit)
    if not who then
        if A.clearPlateBadge then A.clearPlateBadge(unit) end
        return
    end
    A.rememberFace(unit, who.key)
    local placeFilter, here = nil, "world"
    if A.alertPlaceFilter then
        placeFilter, here = A.alertPlaceFilter()
    else
        here = A.pvpPlace and A.pvpPlace() or "world"
        if here == "battleground" then placeFilter = "battleground"
        elseif here == "world" then placeFilter = "world" end
    end
    local matches = A.match(who.key, placeFilter)
    if A.refreshPlateBadge then A.refreshPlateBadge(unit, who, #matches > 0) end
    -- Badge updates even when alerts are off for this place; alerts stay gated.
    if A.alertsAllowedHere and not A.alertsAllowedHere() then return end
    if not A.alertsAllowedHere and not A.store.settings.instances and A.flag(IsInInstance) then return end
    if #matches == 0 then return end
    local now = A.clock()
    if not now then return end
    if A.recordSighting then A.recordSighting(who.key, placeFilter or here) end
    if A.isIgnored and A.isIgnored(who.key) then return end
    if A.lastAlert[who.key] and now - A.lastAlert[who.key] < A.store.settings.cooldown then return end
    A.lastAlert[who.key] = now
    A.alert(who.name, matches, nil, A.faceFor(who.key), here)
end
