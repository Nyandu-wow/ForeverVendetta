# Forever Vendetta — CurseForge project page

Upload `dist/ForeverVendetta-0.1.9.zip` (or run `node scripts/upload-curseforge.mjs` after setup).

- Game version: **WoW Forever 1.60.1**
- Release type: **Beta** for first moderation
- Category: Miscellaneous (closest fit for a friends-only notepad with visible-unit warnings)
- Avatar: `media/avatar-400.png` (original 400×400 PNG)
- Source: https://github.com/Nyandu-wow/ForeverVendetta
- ForeverLAN is separate: https://github.com/Nyandu-wow/ForeverLAN

Read `POLICY.md`, `PRIVACY.md`, and `SECURITY.md` before submitting.

## Summary (≤ 1 sentence)

Friends-only enemy notes for WoW Forever, shared by whisper, with a warning when a listed player is already visible.

## Description (English first)

### What it does

Forever Vendetta is a small, free addon for a private group of friends on **WoW Forever**. You keep short notes about enemy players (Avenge, Avoid, or Watch). Friends you explicitly add by full character name can share those notes with each other.

When a listed enemy is already visible as a nameplate, target, focus, or mouseover, the addon can play the built-in raid-warning sound, show a short banner, and print a short chat line. Instance warnings stay off unless you turn them on.

### What it does not do

- It does **not** connect to the Internet or upload data.
- It does **not** reveal stealth, scan the zone, or find hidden players.
- It does **not** auto-target, auto-attack, count kills, or play the game for you.
- It does **not** turn Battle.net friends into trusted sync partners automatically.
- Shared notes are friends' opinions, not a verified threat rating.

### How to use

1. Install and enable Forever Vendetta.
2. Type `/fv`. Open **Friends** and add each other's full names (`First Last`). Both sides must do this.
3. On **Blacklist**, use **Add target** or type a full name, write a reason, choose a stance, and save.
4. Enable enemy nameplates (and Always show nameplates) if you want the earliest warning.
5. Open **Alerts** to toggle sound/banner, set the repeat cooldown, and use **Preview alert**.

### Privacy and sharing

Reports stay in local SavedVariables. Sync uses WoW addon whispers only, between characters you typed in by name. Chat shows name and stance only. Withdrawn reports clear their reason before sync. Removing a trusted friend stops sharing and drops queued messages to them.

### Conduct

Play within the World of Warcraft Terms of Use. This addon is a personal and friends-only notepad for players you can already see. Do not use it to harass or mistreat others.

### Policy

Free of charge. Unobfuscated Lua. No in-game ads or donation prompts. Source: GitHub and this CurseForge package.

### Changelog

Paste the matching section from `CHANGELOG.md` into the file form.

### Links

Source: https://github.com/Nyandu-wow/ForeverVendetta

## Upload setup

1. Create project at https://authors.curseforge.com/ (game: World of Warcraft).
2. Copy `curseforge.example.json` → `curseforge.json` and set `projectId`.
3. Copy `.env.example` → `.env` and set `CURSEFORGE_API_TOKEN`.
4. `node scripts/upload-curseforge.mjs --list-versions` then `node scripts/upload-curseforge.mjs`.
