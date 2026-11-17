local _, A = ...

function A.playSound()
    -- Built-in raid warning; no bundled audio or external dependencies.
    local sound = SOUNDKIT and SOUNDKIT.RAID_WARNING or 8959
    A.call(PlaySound, sound, "Master")
end

function A.alert(name, matches, test)
    local first = matches[1]
    local title = (test and "TEST - " or "") .. name .. " - " .. first.report.mode
    for i = 2, #matches do
        if matches[i].report.mode ~= first.report.mode then
            title = (test and "TEST - " or "") .. name .. " - " .. #matches .. " reports"
            break
        end
    end
    -- Chat stays short so screenshots and chat logs do not archive private reasons.
    -- The on-screen banner may show the reason while it is visible.
    local detail = first.report.note ~= "" and first.report.note or "Listed enemy"
    detail = detail .. " (" .. A.personName(first.owner) .. ")"
    if #matches > 1 then detail = detail .. " + " .. (#matches - 1) .. " more report(s)" end
    A.print(title)
    if A.store.settings.sound then A.playSound() end
    if A.store.settings.banner and A.showBanner then A.showBanner(title, detail, test) end
end

function A.detect(unit)
    if not A.ready then return end
    if not A.store.settings.instances and A.flag(IsInInstance) then return end
    if not A.flag(UnitIsPlayer, unit) or not A.flag(UnitIsEnemy, "player", unit) then return end
    local who = A.unitName(unit)
    if not who then return end
    local matches = A.match(who.key)
    if #matches == 0 then return end
    local now = A.clock()
    if not now then return end
    A.lastSeen[who.key] = now
    if A.lastAlert[who.key] and now - A.lastAlert[who.key] < A.store.settings.cooldown then return end
    A.lastAlert[who.key] = now
    A.alert(who.name, matches)
end
