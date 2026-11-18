# Forever Vendetta — Blizzard and CurseForge policy notes

This file is for authors and reviewers. It lives under `docs/` and is not shipped in the install zip. See also `PRIVACY.md`.

## Blizzard UI Add-On Development Policy

| Rule | How Forever Vendetta complies |
|---|---|
| Free of charge | Distributed free. No premium features, subscriptions, or paid unlocks. |
| Code completely visible | Unobfuscated Lua. Source is public on GitHub and inside the CurseForge zip. |
| Must not harm realms or other players | Detection uses only units the client already shows. Messaging is whisper-only, queued, and rate-limited. |
| No advertisements | No ads in the addon or listing body. |
| No in-game donation requests | No donation UI, chat prompts, or paywalls. |
| No offensive material | Text is player-written reasons; the addon does not ship objectionable content. |
| Abide by WoW ToU / EULA | Players remain responsible for their own conduct. The addon does not automate play, reveal stealth, or act for the player. |

Blizzard may disable addon functionality at its discretion.

References:

- [UI Add-On Development Policy](https://us.forums.blizzard.com/en/wow/t/ui-add-on-development-policy/24534)
- [Blizzard Developer API Terms of Use](https://www.blizzard.com/en-us/legal/1b2ae6b5-5884-4c8c-b1d2-6b4d0e8e0a0a/)

## CurseForge moderation

| Expectation | How this project meets it |
|---|---|
| Clear English summary and description | The description is on the CurseForge project page. |
| Links at the bottom | GitHub and related links stay under a Links heading after the description. |
| No third-party download links | CurseForge hosts the zip. |
| Changelog on each file | Use `CHANGELOG.md`. |
| Anti-griefing | The addon is an opt-in friend notepad for enemies you can already see. It does not encourage harassment, discrimination, or automated griefing. |
| Distinct content | Original code. Concept references (Spy Forever, Playgu) are credited; no code or assets were copied. |
| Avatar 400×400 | Provide an original, non-solid, non-Blizzard-key-art PNG. No WebP. |
| Game version | Tag the file for **WoW Forever 1.60.1** (TOC Interface `16001`). |

## Design boundaries that keep the addon in policy

- Trust is explicit. Battle.net friends are not auto-added.
- Sharing uses WoW addon whispers only. No Internet, companion, account, or cloud database.
- Alerts fire only for enemy players the client already exposes as nameplate, target, focus, or mouseover.
- No stealth reveal, zone radar, combat-log hunting, auto-target, auto-attack, or kill counting.
- Instance alerts default off.
- Reports are opinions from trusted friends, not a verified threat score.

## Player responsibility

Using Forever Vendetta does not excuse violations of the World of Warcraft Terms of Use. Do not use shared lists to harass, discriminate against, or otherwise mistreat other players.
