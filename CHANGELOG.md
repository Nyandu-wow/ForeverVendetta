# Forever Vendetta

## 0.1.8

- UI lives under `UI/Window.lua`. CurseForge upload script and original 400×400 avatar added.
- Security: untrust drops queued whispers immediately; inbound packets re-sanitize every field.

## 0.1.7

- Code laid out under `Core/` (util, identity, store, detect), with `ForeverVendetta.lua` as the entry file.
- Privacy: withdrawn reports no longer keep or resend reasons; chat alerts omit the reason text.
- Author docs moved to `docs/` (`PRIVACY.md`, CurseForge and policy notes).

## 0.1.6

- CurseForge and Blizzard policy packaging: public source notes, clearer license, listing copy, and conduct/privacy wording.
- TOC website link points at the public GitHub repository.

## 0.1.5

- Mixed stances have neutral warnings. Friends show active reports and the last incoming update.
- Saved reports are revealed in the list. Report history has more space, and feedback clears between tabs.

## 0.1.4

- Own repository, separate from ForeverLAN.
- Addon files live at the repository root for CurseForge packaging.

## 0.1.3

- CurseForge package is this folder only: TOC, four Lua files, README, changelog, and license.
- Load tag accepts both Forever and Camelot. The addon still does not connect to the Internet.
- Window code is formatted to match the rest of the addon. Reports, sharing, and alerts are unchanged.

## 0.1.2

- One window with Blacklist, Friends, and Alerts.
- One row per enemy. Each friend's reason stays separate.
- Removing a report or a friend asks for a second click.
