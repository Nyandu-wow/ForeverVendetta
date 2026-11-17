# Forever Vendetta — Privacy

## What never leaves your PC

- No HTTP, accounts, analytics, or companion process.
- SavedVariables stay in the WoW account folder (`ForeverVendettaDB`).

## What trusted friends can receive

Only characters you add under **Friends** can receive addon whispers from you. Packets may include:

- Enemy full name and realm label
- Stance (Avenge / Avoid / Watch)
- Your written reason (up to 96 bytes), for active reports only
- Revision and withdrawn markers

Withdrawn reports still sync the enemy identity so friends can hide them, but the reason is cleared on the wire and in local tombstones.

## What appears on your screen

- Chat prints a short line: enemy name and stance.
- The temporary banner may show the reason while it is visible.
- Do not put secrets, real-world personal data, or other people's private information in reasons.

## Account-wide storage

Trust lists and reports are stored per realm for the Battle.net account. Your alts on that realm can see locally saved lists. Each character still authors and shares only as itself.

## Residual risks

- Anyone you trust can copy or reshare what you send them. Trust is social, not cryptographic.
- Chat and screenshots can expose banner text if you show your screen.
- Enemy names on withdrawn records are still shared so sync can remove them.

## Untrust

Removing a friend stops future sends, drops queued messages to them, hides their received reports, and clears their last-received stamp.
