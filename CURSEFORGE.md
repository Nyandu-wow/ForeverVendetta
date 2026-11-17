# Forever Vendetta — CurseForge checkup

This repository is Forever Vendetta only. ForeverLAN is a separate project.

Upload `dist/ForeverVendetta-0.1.4.zip` from `powershell -File package.ps1`. On the file form, choose **WoW Forever 1.60.1**. Interface `16001` is the TOC value. The zip root is `ForeverVendetta/ForeverVendetta.toc`.

If you connect this repository as CurseForge source later, `.pkgmeta` packages the addon folder and ignores tests and tooling.

## Summary

Friends-only enemy blacklist. Reports stay on your characters and move only by whisper between people you add by full name.

## Description

Forever Vendetta keeps a shared list of enemy players for a private group of friends on WoW Forever.

Each character owns one report per enemy: a full name, a short reason, and a stance (Avenge, Avoid, or Watch). Trusted friends exchange those reports with hidden addon whispers while both characters are online. The addon does not connect to the Internet, does not include a companion program, and does not upload anything.

It warns when a listed enemy is visible on a nameplate, as your target, focus, or mouseover. It does not reveal stealth, scan the zone, count kills, or act for you. Instance warnings are off unless you turn them on.

Type `/fv`. Blacklist, Friends, and Alerts are the three tabs. Both friends must add each other's full character name. A Battle.net friend is not added automatically.

### Links

Put the source repository URL at the bottom of the CurseForge description once the remote is public.

## File changelog

Paste the latest section from `CHANGELOG.md`.

## What the zip must contain

- `ForeverVendetta/ForeverVendetta.toc`
- `Core.lua`, `Comms.lua`, `UI.lua`, `Main.lua`
- `README.md`, `CHANGELOG.md`, `LICENSE`

No tests, no ForeverLAN files, no tokens.
