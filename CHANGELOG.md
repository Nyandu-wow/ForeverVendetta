# Forever Vendetta

## 0.1.42

- Forever identity is First Last. When realm APIs are empty/secret, fall back to `Forever` so init is not blocked — realm is only an internal storage key, not a player-facing requirement.

## 0.1.41

- Fix init never becoming ready when `GetUnitName(..., true)` returns `First Last-RealmLabel` that does not match the local realm string (identity rejected the hyphen). Strips the suffix; prefers UnitName-style APIs first.
- `/fv` retries init and rebuilds minimap/hooks if login was too early; clearer unread realm/name messages.

## 0.1.40

- Split `UI/Window.lua` into tab modules: `Widgets`, `Banner`, `Friends`, `Alerts`; window shell uses shared `ctx` (`A._win`) and `A.UI` helpers. No behavior change intended.

## 0.1.39

- `/fv status` adds current place, messaging hold (clear / combat lockdown / restricted), and sighting count.
- Seen filter copy: sightings are local SavedVariables, not “this weekend only.”
- Dropped unused session `A.lastSeen` (sightings already use `A.recordSighting`).

## 0.1.38

- `/fv status` shows muted count and world/BG/arenas toggles for soak checks.
- Class icons are Forever Vanilla only (no Death Knight).
- Friend-report history uses more editor height when the attacker strip is hidden.
- Acceptance checklist covers race icons, banner Mute, and `/fv status`.

## 0.1.37

- Enemy list filters: **Muted** and **Seen** (plus existing stance chips).
- Warning banner **Mute** silences alerts for that enemy locally; reports stay.
- Shared stance labels via `A.stanceLabel` (Detect / Tips / chat).

## 0.1.36

- Race icons use Forever's character-create atlas coords (Horde on the second/fourth rows). Tauren no longer paints as Draenei.

## 0.1.35

- Indexed `A.match` by enemy First Last (rebuild on report/friend changes) so the 1 Hz detect path does not walk every report bucket.
- One nameplate pass per tick: badges and alerts share `A.detect` (no double plate match). Badges still update when alerts are place-gated off.

## 0.1.34

- `/fv trust` and inbound enemy reports require a Forever **First Last** name (same rule as the Friends UI). Single-token names are rejected.

## 0.1.33

- Friends-first empty World state with **Open Friends**; editor history no longer overlaps recent attackers.
- Friends sync health strip; Confirm removal / Confirm remove labels; Alerts Extras tooltips; clearer party/raid announce wording.
- README honesty: optional party announce leaves friends-only; chat vs sound/banner; local D/K.
- Login sync once (no LOGIN+PEW double sync); minimap drag OnUpdate only while dragging; `.pkgmeta` ignores `.cache` / npm.

## 0.1.32

- Enemy list shows last seen on each row and sorts recently seen enemies to the top.
- Right-click an enemy player: **Add to Forever Vendetta** (Classic unit menu and modern menus when available).
- Muted enemies show “muted” on the list row.

## 0.1.31

- Dropped Guessed/Logged labels from UI copy; death-offer and attacker notes read naturally.

## 0.1.30

- Removed redundant Alerts copy explaining arenas vs dungeons/raids.

## 0.1.29

- Version shown in the window title, bottom corner, and `/fv status`.
- Alerts tab cleaned up (grouped left column, no overlapping slider labels, denser sound grid).
- Warning sounds: added Quest and Coin (built-in Classic kits).

## 0.1.28

- Arena alerts are arenas-only. Dungeons and raids never warn, even with the arenas toggle on (`/fv arenas`).

## 0.1.27

- Death **Add killer** offer only for confirmed enemy players (Player GUID, non-mob damage meter, or live enemy player unit). PvE monster deaths no longer pop the dialog.

## 0.1.26

- Alerts tab layout: no overlapping controls; extras fit inside the panel. Instance option clarified for arenas.

## 0.1.25

- **Mute alerts** for a listed enemy without withdrawing reports (`Mute alerts` / `/fv ignore`). Local only.
- Opt-in **party/raid announce** on listed sightings — short name + stance only, never the reason.
- **Nameplate V mark** for listed enemies (grey when muted).

## 0.1.24

- Enemy unit tooltips show Forever Vendetta stance and reason when the player is listed (opt-out on Alerts).
- **FV** button on the target frame opens a report draft for the current enemy (FV* if you already reported them here).
- **Recent attackers** strip (Guessed from death recap / targeting you) with one-click report drafts.

## 0.1.23

- After a death, offer **Add as Avenge** for the guessed killer from death recap / damage taken (opt-out on Alerts). Guessed — never auto-added.
- Listed enemies remember **last seen** zone and time (Logged) for tooltips after a nameplate / target / focus / mouseover hit.

## 0.1.22

- Separate **World** and **Battlegrounds** tabs, each with its own enemy list and notes.
- Local death/kill tallies (D/K) from death recap, damage meter, and PARTY_KILL — Guessed, not combat-log truth, and not shared over whispers.
- Alerts only fire for enemies listed on the matching place tab (World vs BG).

## 0.1.21

- Friends can pick a readable First Last name from your in-game / Battle.net friends list. That only fills the name; mutual trust is still required.
- Alerts split open world, battlegrounds, and other instances. Warnings show `[World]`, `[Battleground]`, `[Arena]`, or `[Instance]`.

## 0.1.20

- Friends shows whether a whisper has arrived from each trusted character, with a copyable `/fv trust` line for them to add you.
- Sync status (queue, last outbound whisper, errors) stays visible on the Friends tab and in `/fv status`.

## 0.1.19

- The window closes again: the title drag and tab pages no longer sit over the X, Escape closes even from a text field, and a close handler is wired if the frame template omits one.

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
