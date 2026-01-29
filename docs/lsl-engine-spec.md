# Custom LSL Choreography Engine

Replaces the SpotOn dependency with a custom LSL system that receives choreography data directly from the web tool via HTTP.

## Architecture

### Dancer Script (`lsl/dancer.lsl`) — one per animesh

- Placed inside each animesh dancer object
- Object description set to dancer number (1-12)
- Listens on channel `-9876543` for commands
- Stores absolute positions (relative to stage center)
- On PLAY: teleports to `center + layer0_pos`, then runs keyframed motion for subsequent layers
- Uses `llSetKeyframedMotion()` with `KFM_TRANSLATION` mode (position-only, no rotation)
- Minimum travel time clamped to 0.15s to prevent position drift
- Supports: PLAY, STOP, RESET, LOAD (DANCER data)

### Controller Script (`lsl/controller.lsl`) — one central prim

- Placed in a single control prim at stage center
- Calls `llRequestURL()` to get a temporary HTTP-in URL
- Displays URL via hovertext and chat for pasting into the web tool
- Receives HTTP POST from web tool, forwards to dancers via `llRegionSay()`
- PLAY command includes controller's position as center reference: `PLAY|<x,y,z>`
- Re-requests URL on region restart

## Data Flow

```
Web Tool  --HTTP POST-->  Controller Script  --llRegionSay-->  Dancer Scripts
                          (parses & distributes)               (execute movement)
```

## Communication Protocol

### Web Tool -> Controller (HTTP POST body)

```
DANCER|<num>|<x,y,z,travel,sleep>|<x,y,z,travel,sleep>|...
PLAY
STOP
RESET
```

### Controller -> Dancers (llRegionSay on channel -9876543)

```
DANCER|<num>|<x,y,z,travel,sleep>|...   (forwarded as-is)
PLAY|<controller_position>               (center reference added)
STOP
RESET
```

## LSL Functions Used

- `llSetKeyframedMotion(keyframes, options)` — smooth movement along path
- `llSetRegionPos(pos)` — teleport to starting position
- `llRequestURL()` / `llHTTPResponse()` — HTTP-in endpoint
- `llRegionSay(channel, message)` — broadcast commands
- `llListen(channel, "", "", "")` — receive commands
- `llGetPos()` / `llGetRot()` — current position/rotation
- `llGetObjectDesc()` — read dancer number from object description

## LSL Constraints

- Script memory limit: 64KB (mono) — keep data compact
- `llSetKeyframedMotion` max keyframes per call: 255
- Chat message max length: 1024 bytes — may need to split large choreographies
- HTTP body max: 2048 bytes — may need chunked transfer
- `llRequestURL` URLs are temporary and change on region restart

## Implementation Status

1. [x] Write dancer script — `lsl/dancer.lsl` (v4.1)
2. [x] Write controller script — `lsl/controller.lsl` (v4.1)
3. [x] Define communication protocol: pipe-delimited
4. [x] Add "Send to SL" button and URL input to web tool
5. [x] Add HTTP POST function to web tool (no-cors mode, 500ms delay)
6. [ ] Test with 2 dancers
7. [ ] Test with 6+ dancers
8. [ ] Handle edge cases (region restart URL change, split large data, error feedback)
