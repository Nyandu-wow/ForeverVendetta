# Forever Vendetta — Security notes

## Threat model

This is a LAN-party notepad, not an anti-cheat system. Trusted friends can lie in their own reports. The addon must not let strangers write into your store, impersonate authors, talk to the Internet, or automate combat.

## Controls

| Risk | Control |
|---|---|
| Impersonation | Report author is Blizzard's whisper sender only. Packets never choose the owner. |
| Stranger writes | Only WHISPER + trusted full name. Guild/party/raid ignored. |
| Malformed packets | Length cap 255; fields re-run through `A.text` / mode allow-list before merge. |
| Stale reasons after withdraw | Tombstones clear notes locally and on the wire. |
| Trust removal race | `A.dropPeer` clears the send queue immediately on untrust. |
| Data exfiltration | No HTTP, sockets, WebAPI, or companion. Addon whispers only. |
| Code injection | No `loadstring` / `RunScript`. Plain Lua source only. |
| Secret Forever values | Secret/inaccessible name or realm values are skipped. |

## Residual risks

- Trusted friends receive the enemy names and active reasons you choose to share.
- They can copy that data outside the addon.
- Chat/screenshots can show banner text while it is on screen.
