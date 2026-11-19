# Forever Vendetta

## 0.1.18

- Forever Vendetta appears under Options → AddOns, with an open button and minimap toggle.
- The minimap button follows Forever's stock circular map radius so it sits on the ring instead of inside the chrome.

## 0.1.17

- A minimap button opens the blacklist (left-click) and Friends (right-click). Drag it around the minimap. Alerts can hide it. Stock Forever also lists Forever Vendetta in the minimap addon menu.

## 0.1.16

- Alerts sound choices stay inside the window. The list is Classic-era sounds Forever can play: Raid, Ready, Ping, Auction, Level, Tell. Older names such as Drums fall back to Raid.

## 0.1.15

- Alerts lets you pick the warning sound. Raid warning stays the default. The choice is saved with your other alert settings and is not shared.

## 0.1.14

- The window uses metal trim, a rock panel, and character-sheet tabs.
- Blacklist rows, the report header, and the warning show a class icon and a race icon when the client can read them. They are not saved or whispered.

## 0.1.13

- One dark ledger. Quiet controls, burgundy only for the selected tab and for remove or withdraw.
- Friends, blacklist, and alerts each keep their own actions. A single page hides its pager.

## 0.1.12

- One window again. The page is parchment inside the normal frame, with Blacklist, Friends, and Alerts as tabs in the header.
- List and detail share that page, split by a single rule.

## 0.1.11

- Window opens as a two-page Forever spellbook using the game's spellbook panel art.
- Side tabs switch Blacklist, Friends, and Alerts. List and detail sit on facing pages.
- Parchment ink colors replace the flat dark panels.

## 0.1.10

- Blacklist rows are denser, with clearer Mixed chips and author summaries.
- Each friend's report is shown as its own block with a stance-colored edge.
- Stance buttons use stance colors, and a short hint follows the selected stance.
- Warning banner hierarchy is category, title, then detail. Slash command is `/fv` only.

## 0.1.9

- Banner color and label follow the stance. Mixed reports stay neutral and name one author.
- The enemy name box locks while a saved enemy is selected, so a typo cannot create a second report.
- Friend rows say "Last report" and the sync line shows the whisper queue.
- README states the reload queue limit and that chat still prints when sound and banner are off.

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
