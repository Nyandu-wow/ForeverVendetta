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

local STANCE_LABEL = { AVENGE = "Avenge", AVOID = "Avoid", WATCH = "Watch" }

function A.alert(name, matches, test, face)
    local first = matches[1]
    local mixed = false
    for i = 2, #matches do
        if matches[i].report.mode ~= first.report.mode then mixed = true break end
    end
    -- Chat stays short so screenshots and chat logs do not archive private reasons.
    -- The banner may show one author's reason, with that author's name attached.
    local prefix = test and "TEST - " or ""
    local mode = nil
    local title
    if mixed then
        title = prefix .. name .. " - " .. #matches .. " reports"
    else
        mode = first.report.mode
        title = prefix .. name .. " - " .. (STANCE_LABEL[mode] or "Listed")
    end
    local detail = first.report.note ~= "" and first.report.note or "Listed enemy"
    detail = detail .. " (" .. A.personName(first.owner) .. ")"
    if #matches > 1 then detail = detail .. " + " .. (#matches - 1) .. " more" end
    A.print(title)
    if A.store.settings.sound then A.playSound() end
    if A.store.settings.banner and A.showBanner then A.showBanner(title, detail, test, mode, face) end
end

function A.detect(unit)
    if not A.ready then return end
    if not A.store.settings.instances and A.flag(IsInInstance) then return end
    if not A.flag(UnitIsPlayer, unit) or not A.flag(UnitIsEnemy, "player", unit) then return end
    local who = A.unitName(unit)
    if not who then return end
    A.rememberFace(unit, who.key)
    local matches = A.match(who.key)
    if #matches == 0 then return end
    local now = A.clock()
    if not now then return end
    A.lastSeen[who.key] = now
    if A.lastAlert[who.key] and now - A.lastAlert[who.key] < A.store.settings.cooldown then return end
    A.lastAlert[who.key] = now
    A.alert(who.name, matches, nil, A.faceFor(who.key))
end
