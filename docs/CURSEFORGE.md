# Forever Vendetta — CurseForge project page

Upload `dist/ForeverVendetta-0.1.7.zip` from `powershell -File package.ps1`.

- Game version: **WoW Forever 1.60.1**
- Release type: **Beta** for the first public checkup (or Alpha if you want it hidden from the default client list)
- Category: Miscellaneous / Unit Frames / Combat (pick the closest WoW category; this is a friends-only notepad with visible-unit warnings)
- Source repository: https://github.com/Nyandu-wow/ForeverVendetta
- ForeverLAN is a different project: https://github.com/Nyandu-wow/ForeverLAN

Read `POLICY.md` before submitting. The zip must contain only `ForeverVendetta/` with TOC, four Lua files, README, CHANGELOG, and LICENSE.

## Summary (≤ 1 sentence)

Friends-only enemy notes for WoW Forever, shared by whisper, with a warning when a listed player is already visible.

## Description (English first — paste into CurseForge)

### What it does

Forever Vendetta is a small, free addon for a private group of friends on **WoW Forever**. You keep short notes about enemy players (Avenge, Avoid, or Watch). Friends you explicitly add by full character name can share those notes with each other.

When a listed enemy is already visible as a nameplate, target, focus, or mouseover, the addon can play the built-in raid-warning sound, show a short banner, and print a chat line. Instance warnings stay off unless you turn them on.

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

Reports stay in local SavedVariables. Sync uses WoW addon whispers only, between characters you typed in by name. Removing a trusted friend stops future sharing and hides their received reports.

### Conduct

Play within the World of Warcraft Terms of Use. This addon is a personal and friends-only notepad for players you can already see. Do not use it to harass or mistreat others.

### Policy

Free of charge. Unobfuscated Lua. No in-game ads or donation prompts. Source: GitHub and this CurseForge package.

### Changelog

Paste the matching section from `CHANGELOG.md` into the file form.

### Links

Source: https://github.com/Nyandu-wow/ForeverVendetta

## Avatar checklist

- [ ] Original 400×400 PNG (not WebP)
- [ ] Not a solid color
- [ ] No unlicensed Blizzard key art
- [ ] No NSFW

## File checklist

- [ ] Zip root is `ForeverVendetta/ForeverVendetta.toc`
- [ ] Includes LICENSE and CHANGELOG.md
- [ ] No tests, `.pkgmeta`, `.tools`, tokens, or ForeverLAN files
- [ ] Tagged Forever 1.60.1
- [ ] GitHub repository is **public** so Blizzard's visible-source rule is easy to verify
