# Future Plans

## Relay Server (URL Stability)

The SL controller gets a new `llRequestURL()` on every script reset, region change, or sim restart. The current workflow requires manually re-pasting the URL into the web UI each time.

### Proposed: Pair Code + Relay Proxy

- Controller generates a short pair code (or reads one from object description)
- On every new URL grant, controller POSTs its URL to a relay: `POST /pair/{code}`
- Web UI enters the pair code once, sends all commands to the relay: `POST /relay/{code}`
- Relay forwards commands to the current SL URL
- If the SL URL changes, the controller re-registers — web UI is unaffected

### Implementation Options

| Option | Pros | Cons |
|--------|------|------|
| **Cloudflare Worker + KV** | Free tier, zero maintenance, global edge | Requires Cloudflare account |
| **Firebase Realtime DB** | No server code, real-time updates | Web UI still needs raw SL URL for commands |
| **AWS Lambda + API Gateway** | Full control, scalable | More setup, potential cost |
| **Simple VPS (Node.js)** | Most flexible | Maintenance burden |

**Recommended: Cloudflare Worker** (~50 lines of code, free, acts as a stable proxy)

### LSL Changes Required

- Add `g_relayUrl` and `g_pairCode` globals
- In `state_entry()` and `changed(CHANGED_REGION)`: call `llHTTPRequest(g_relayUrl + "/pair/" + g_pairCode, ...)` to register
- Pair code could be stored in object description (alongside mirror rules) or hardcoded

### Web UI Changes

- Replace "SL Controller URL" input with "Pair Code" input
- All `sendCommand()` calls go to `relayUrl + "/relay/" + pairCode`
- Also enables: controlling the club from phone/anywhere (not just same network)

---

## ~~Mirror Name Caching~~ (Done in v1.9)

Resolved by the explicit pairing system in v1.9. The controller now uses `g_playlistB` (a parallel list) instead of calling `getMirrorName()` on every play. Inventory lookups only happen once during playlist loading (via `findPairInInventory()`), not on every track change.

---

## Web UI Improvements

### Live Progress Bar

- Use the `PING` response (`PONG|scriptTime|playIdx|playing|autoAdvance`) to show:
  - Current track elapsed time vs total duration
  - Visual progress bar per track
  - Estimated time remaining for playlist

### Playlist Drag Reorder in Web UI

- The database page has playlist building, but the main control page (`mirror-sync.html`) could allow drag-to-reorder the active playlist before sending to SL

### Multi-Controller Support

- Some venues may have multiple controller prims (e.g., stage left / stage right)
- Web UI could manage multiple pair codes and send synchronized commands

---

## Notecard Enhancements

### Auto-Detect Durations from Database

- When loading a notecard that has no durations (e.g., `Melissa Heels`), cross-reference with the dance database to auto-fill known durations
- Only applies in the web UI (LSL can't access localStorage)

### Notecard Export from Web

- The database page already has "Export Notecard" — could also generate the SL notecard format with `name:mm:ss` durations for pasting into SL notecard objects

---

## Slot Script Optimization

The slot scripts (`mirror-slot.lsl`) still have `if (DEBUG) llOwnerSay(...)` blocks (8 occurrences). At 158 lines they're well under the 64KB limit, but for consistency with the controller:

- Strip DEBUG code from slot scripts
- Or: leave as-is (they're small enough that it doesn't matter)

---

## Choreography Timeline Integration

The `style/` directory and spec files (`choreographer-spec.md`, `timeline-spec.md`, `lsl-engine-spec.md`) suggest a planned timeline/choreography system. Future integration points:

- Timeline could drive the mirror sync controller via HTTP commands
- Choreography sequences could include group assignments, not just animation names
- Formation changes (swap groups mid-song) could be scripted
