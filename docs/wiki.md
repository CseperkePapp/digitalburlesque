# SL Choreography System — Wiki

A web-based choreography planning suite for Second Life animesh dancers, with a custom LSL engine for live in-world control.

---

## Table of Contents

1. [Overview](#overview)
2. [Spatial Choreographer (choreographer.html)](#spatial-choreographer)
   - [Interface Layout](#choreographer-interface-layout)
   - [Stage Setup](#stage-setup)
   - [Dancers](#dancers)
   - [Layers](#layers)
   - [Formations](#formations)
   - [Timing Groups](#timing-groups)
   - [Overlays & Display](#overlays--display)
   - [Export (SpotOn Format)](#export-spoton-format)
   - [Live Control](#live-control)
   - [Project Management](#choreographer-project-management)
3. [Dance Timeline Planner (timeline.html)](#dance-timeline-planner)
   - [Interface Layout](#timeline-interface-layout)
   - [Song Setup](#song-setup)
   - [Animation Library](#animation-library)
   - [Animation Sets & Mirroring](#animation-sets--mirroring)
   - [CSV Import](#csv-import)
   - [Timeline Canvas](#timeline-canvas)
   - [Animation Blocks](#animation-blocks)
   - [Section Markers & Lyrics](#section-markers--lyrics)
   - [Playback & Transport](#playback--transport)
   - [Zoom & Scroll](#zoom--scroll)
   - [Keyboard Shortcuts](#keyboard-shortcuts)
   - [Project Management](#timeline-project-management)
4. [LSL Engine](#lsl-engine)
   - [Architecture](#architecture)
   - [Controller Script (controller.lsl)](#controller-script)
   - [Dancer Script (dancer.lsl)](#dancer-script)
   - [Communication Protocol](#communication-protocol)
   - [Setup Guide](#setup-guide)
   - [Animesh vs Real Avatars](#animesh-vs-real-avatars)
   - [Real Avatar System](#real-avatar-system)
   - [LSL Constraints](#lsl-constraints)
5. [Data Structures](#data-structures)
   - [Choreographer Project (v3)](#choreographer-project-v3)
   - [Timeline Project (v2)](#timeline-project-v2)
   - [CSV Import Format](#csv-import-format)
6. [Integration Between Tools](#integration-between-tools)
7. [Version History](#version-history)

---

## Overview

The system has three components:

| Component | File | Purpose |
|-----------|------|---------|
| **Spatial Choreographer** | `choreographer.html` | Plan **where** dancers go — positions, formations, movement paths across layers |
| **Dance Timeline Planner** | `timeline.html` | Plan **when** animations play — animation library, song timeline, per-group scheduling |
| **LSL Engine** | `lsl/controller.lsl` + `lsl/dancer.lsl` | Execute choreography **in Second Life** — HTTP-in bridge, keyframed motion |

Both web tools are single-file HTML/JS/CSS applications (no frameworks, no build step). Open them directly in a browser.

---

## Spatial Choreographer

**File:** `choreographer.html`
**Spec:** `docs/choreographer-spec.md`

### Choreographer Interface Layout

```
+-------------------+-------------------------------+--------------------+
| FORMATIONS PANEL  |        VIEWS CONTAINER        |     UI PANEL       |
| (180px fixed left)|                               | (300px fixed right)|
|                   |  +----------+ +----------+    |                    |
| Formation presets |  | TOP VIEW | |FRONT VIEW|    | Dancers (1-12)     |
| Spread / Radius  |  |  (X-Y)   | |  (X-Z)   |    | Overlays           |
| Position %       |  +----------+ +----------+    | Layer control      |
|                   |  +----------+                 | Timing groups      |
|                   |  |SIDE VIEW |                 | Export             |
|                   |  |  (Y-Z)   |                 | Live Control       |
|                   |  +----------+                 | Project            |
+-------------------+-------------------------------+--------------------+
```

Three canvas views show the stage from different angles:
- **TOP (X-Y):** Bird's-eye view — horizontal and depth positioning
- **FRONT (X-Z):** Audience perspective — horizontal and height positioning
- **SIDE (Y-Z):** Wing view — depth and height positioning

Click on any view to place or move the selected dancer. All three views update together.

### Stage Setup

| Setting | Default | Description |
|---------|---------|-------------|
| Width | 15m | Stage width (X axis) |
| Depth | 10m | Stage depth (Y axis) |
| Height | 3m | Stage height (Z axis) |
| Pixels per meter | 40 | Canvas rendering resolution |

**Stage Shapes** (drawn as overlay):
- Rectangle
- Half Circle
- Half Oval
- Rect + Half Circle (thrust stage)
- Trapezoid

**Margin** overlay can be toggled on/off with adjustable size (default 1.0m) to visualize dancer boundaries.

**Stage Center** — Paste SL coordinates (e.g. from your controller prim's position) to set the world-space origin. This is used for SpotOn notecard export and Live Control data.

### Dancers

Up to **12 color-coded dancers**:

| # | Name | Color | # | Name | Color |
|---|------|-------|---|------|-------|
| 1 | Green | `#00FF00` | 7 | Cyan | `#00FFFF` |
| 2 | Violet | `#8B00FF` | 8 | Pink | `#FF69B4` |
| 3 | Blue | `#0000FF` | 9 | Mint | `#98FB98` |
| 4 | Yellow | `#FFFF00` | 10 | Plum | `#DDA0DD` |
| 5 | Orange | `#FFA500` | 11 | Sky | `#87CEEB` |
| 6 | Red | `#FF0000` | 12 | Khaki | `#F0E68C` |

Select a dancer by clicking its color button, then click on any view to place it. The dancer count can be adjusted (1–12) from the UI panel.

### Layers

Layers represent **sequential positions** in the choreography. Think of them as keyframes.

- **Layer 1** is the starting position (travel time locked to 0)
- Each subsequent layer defines where dancers move next
- Navigating to a new layer **clones** the previous layer's positions as a starting template
- **Onion skin** shows previous layer positions with exponential opacity falloff
- **Movement paths** draw dotted lines connecting each dancer's positions across layers

### Formations

15 preset formations that distribute all dancers into a pattern on the current layer:

**Lines:** Horizontal Line, Vertical Line, Diagonal, Diagonal Back
**Curves:** Circle, Semi-circle, Arc (front)
**Shapes:** V-Shape, Inverted V, Arrow
**Grids:** Grid, Staggered, Triangle
**Organic:** Scatter (random), Cluster

**Parameters:**
- **Spread** (default 1.5m): Distance multiplier between dancers
- **Radius** (default 3m): Used for circle/arc formations
- **Position %** (default 50%): Shifts formation front-to-back on stage

### Timing Groups

Controls how dancers are synchronized:

| Mode | numGroups | Behavior |
|------|-----------|----------|
| All sync | 1 | All dancers share the same travel/sleep timing |
| N groups | 2–11 | Dancers split into groups; each group shares timing |
| Individual | 12 | Each dancer has independent timing |

When you change the group count, dancers are **auto-distributed round-robin** (Dancer 1 → G1, Dancer 2 → G2, etc.). You can manually reassign any dancer to any group via dropdown selectors.

**Per-layer timing** (applied to all dancers in the same group):
- **Travel Time** (seconds): How long the movement takes (min 0.15s in SL)
- **Sleep Time** (seconds, default 10s): How long to hold position before the next movement

### Overlays & Display

- **Grid overlay**: 1-meter grid on all views
- **Center mark**: Crosshair at stage center (0,0)
- **Stage shape**: Boundary outline in selected shape
- **Margin**: Inner boundary showing safe area
- **Movement paths**: Dotted lines in dancer colors connecting layer positions
- **Front-of-stage indicators**: On TOP and SIDE views
- **Ground line**: Z=0 reference on FRONT and SIDE views

### Export (SpotOn Format)

Generates SpotOn-compatible notecards for use with the SpotOn dance system:

```
@spot_dancer <number>
@pos_offset <stageCenter + layer1 position>
@rot_offset <0, 0, 0, 1>
<relX, relY, relZ>, <rot>, travelTime, sleepTime, 0, 0.5
...
```

- **Single**: Export one dancer's notecard
- **All Dancers**: Export all dancers in one output

Positions in the notecard are **relative to the dancer's own starting position** (Layer 1).

### Live Control

Directly controls animesh dancers in Second Life via the custom LSL engine:

1. **Paste the controller URL** — displayed as hovertext on the controller prim in SL
2. **Send Data** — sends `DANCER|num|x,y,z,travel,sleep|...` for each dancer (500ms delay between dancers)
3. **Play** — sends `PLAY` command (controller broadcasts with its position as stage center)
4. **Stop** — halts all keyframed motion
5. **Reset** — returns dancers to original positions and clears data

Positions sent via Live Control are **absolute** (relative to stage center), unlike SpotOn notecard positions which are relative to each dancer's start.

### Choreographer Project Management

- **Auto-save**: Saves to `localStorage` key `choreoProject` on every change
- **Export JSON**: Downloads project as `.json` file
- **Import JSON**: Load a previously exported project
- **New Project**: Resets everything to defaults (confirms first)
- **Project version**: 3 (includes stageCenter)

---

## Dance Timeline Planner

**File:** `timeline.html`
**Spec:** `docs/timeline-spec.md`

### Timeline Interface Layout

```
+-----------------------------------------------------------------------+
| TOOLBAR: Song Title | Duration | BPM | Stop Play 0:00 | Zoom Snap | Export Import New
+------------+----------------------------------------------------------+
|            |  Time Ruler  0:00   0:10   0:20   0:30   ...             |
| ANIMATION  |  Markers     |Intro     |Verse 1    |Chorus    |         |
| LIBRARY    |  Lyrics      "When..."  "the night..." "falls..."        |
| (240px)    |  ─────────────────────────────────────────────────        |
|            |  Group 1     [=== Dance A ===][== Dance B ==]             |
| Search     |  Group 2     [====== Dance C ======]                     |
| [Dance A]  |  Group 3     [== Dance A ==][=== Dance D ===]            |
| [Dance B]  |                                                          |
| [Dance C]  |  ▼ Playback cursor (red vertical line)                   |
+------------+----------------------------------------------------------+
```

- **Left panel** (240px): Animation library — HTML-based, searchable, draggable entries
- **Main area**: Canvas-based scrollable/zoomable timeline
- **Toolbar** (top): Song info, transport controls, zoom, project buttons

### Song Setup

| Field | Default | Description |
|-------|---------|-------------|
| Title | "Untitled" | Song name (display only) |
| Duration | 3:00 | Song length in MM:SS format |
| BPM | 0 | Beats per minute (0 = no beat grid) |
| BPM Offset | 0 | Beat grid offset in seconds |

When BPM is set (> 0), the timeline shows vertical beat grid lines and snap-to-grid aligns blocks to beats.

### Animation Library

The left panel lists all SL animations available for use on the timeline.

**Each animation has:**
- **Name**: The exact SL animation name (must match what's in the animesh object inventory)
- **Duration**: Length in seconds
- **Color**: Visual color on the timeline
- **Key Moments**: Named markers at specific times within the animation (e.g. "Turn" at 4.0s)
- **Set**: Optional assignment to an animation set (for mirroring)

**Library features:**
- **Search**: Filter animations by name
- **Add/Edit/Delete**: Full CRUD via dialog
- **Mini-timeline bars**: Each entry shows a colored bar with marker dots
- **Drag to timeline**: Drag any entry onto a group track to place it
- **Export/Import Library**: Separate from project — share animation libraries between projects

### Animation Sets & Mirroring

Animation Sets define **mirror naming rules** for creating mirrored dance variants.

**How it works:**
1. Create a set (e.g. "Dakota Burlesque") with a mirror rule using `{name}` placeholder
2. Assign animations to the set
3. The mirror name is automatically derived

**Example mirror rules:**
- `{name}_Mirror` → `Dakota_Burlesque_1` becomes `Dakota_Burlesque_1_Mirror`
- `{name} (mirror)` → `Bento Charleston 1` becomes `Bento Charleston 1 (mirror)`
- `Mirror_{name}` → `dance_slow` becomes `Mirror_dance_slow`

**On the timeline:**
- Right-click a block → "Use Mirror" to toggle mirrored playback
- Mirrored blocks show the derived mirror name with an **M** badge
- Mirror names are display-only — the original animation data is preserved

**Sets management dialog:**
- Add/Edit/Delete sets
- Each set shows its rule and animation count
- Deleting a set unassigns its animations (doesn't delete them)

**Accordion UI in library panel:**
- Animations grouped by set in collapsible sections
- Each section shows count badge and mirror rule when expanded
- "X" button removes a set and all its animations (including timeline blocks)
- "Ungrouped" section for animations not in any set

### CSV Import

Bulk-load animations from a CSV file. The format auto-detects sets and animations:

```csv
Dakota Burlesque,          ← Name with no valid duration = SET HEADER
Dakota_Burlesque_1,28.5    ← Name,duration = animation in current set
Dakota_Burlesque_2,30.0
,                           ← Empty line (ignored)
Sara Heels,                ← Another set header
Sara_Heels_Dance_1,25.3
```

**Rules:**
- Lines with a name but no valid duration → creates a new animation set
- Lines with name + valid duration → creates an animation in the current set
- Duplicate animation names are skipped
- Sets get the default mirror rule `{name}_mirror`
- Colors cycle through a 12-color palette
- Existing sets with matching names are reused (case-insensitive)

### Timeline Canvas

The main canvas renders all timeline elements with these tracks (top to bottom):

| Track | Height | Description |
|-------|--------|-------------|
| **Time Ruler** | 30px | Time labels with adaptive major/minor ticks |
| **Markers** | 26px | Section markers as colored spans |
| **Lyrics** | 24px | Lyric text at timestamps |
| **Group Tracks** | 48px each | Animation blocks per timing group |

**Left headers** (90px wide) show track names.

**Time ruler adapts to zoom:**

| Zoom level (pps) | Major ticks | Minor ticks |
|-------------------|-------------|-------------|
| < 10 | 60s | 10s |
| 10–25 | 30s | 5s |
| 25–100 | 10s | 1s |
| 100–200 | 5s | 1s |
| > 200 | 1s | 0.5s |

**Beat grid** (when BPM > 0): Vertical lines at every beat. Every 4th beat is brighter (50% alpha vs 20%).

### Animation Blocks

Blocks are the colored rectangles on group tracks representing scheduled animations.

**Creating blocks:**
- Drag an animation from the library panel onto a group track
- Block appears at the drop position with the animation's default duration

**Editing blocks:**
- **Move**: Drag the body of the block left/right
- **Resize**: Drag the left or right edge (6px grab zone) — minimum 0.5s
- **Delete**: Select and press Delete/Backspace
- **Edit label**: Double-click to set a custom label
- **Toggle mirror**: Right-click → "Use Mirror" / "Use Original"
- **Select**: Click to highlight (white border)

**Snap to grid**: When BPM is set and Snap is enabled, block start times and edges snap to the nearest beat.

**Visual appearance:**
- Rounded rectangle (4px radius) in the animation's color at 80% opacity
- Text label (animation name or custom label)
- Key moment triangles at marker positions
- Mirror badge ("M") when mirrored
- White 2px border when selected

### Section Markers & Lyrics

**Section Markers** (colored spans on the markers track):
- Double-click the markers track to add a new marker
- Right-click to edit or delete
- Each marker has: label, time, color
- Markers render as colored regions from their time to the next marker

**Lyrics** (text on the lyrics track):
- Double-click the lyrics track to add
- Right-click to edit or delete
- Each lyric has: text, time
- Displayed as text at their timestamp position

### Playback & Transport

Visual-only playback (no audio — planned for future):

| Control | Action |
|---------|--------|
| **Play/Pause** button | Start/pause the cursor sweep |
| **Stop** button | Reset cursor to 0:00 |
| **Click ruler** | Seek to clicked time |
| **Space bar** | Toggle Play/Pause |

The red playback cursor sweeps at real-time speed using `requestAnimationFrame`. The canvas auto-scrolls to keep the cursor visible (100px margin).

**Time display** shows current position in MM:SS format.

### Zoom & Scroll

| Action | Effect |
|--------|--------|
| **Mouse wheel** | Horizontal scroll |
| **Ctrl + wheel** | Zoom in/out toward cursor position |
| **Zoom +/- buttons** | ×1.3 zoom in/out |

**Zoom range:** 0.1× to 20× (base: 40 pixels per second).

### Keyboard Shortcuts

| Key | Action | Condition |
|-----|--------|-----------|
| **Space** | Toggle Play/Pause | Not in input field or dialog |
| **Delete** / **Backspace** | Delete selected block | Block must be selected |

### Timeline Project Management

- **Auto-save**: `localStorage` key `choreoTimelineProject`
- **Export/Import**: JSON file, separate from choreographer project
- **New Project**: Resets to defaults with sample data
- **Export/Import Library**: Animation library only (for sharing between projects)
- **Import CSV**: Bulk-load animations with auto-set detection
- **Project version**: 2 (includes animationSets, setId, mirrored)
- **Migration**: v1 → v2 auto-migrates on load (adds sets and mirror fields)

---

## LSL Engine

**Files:** `lsl/controller.lsl`, `lsl/dancer.lsl`
**Spec:** `docs/lsl-engine-spec.md`
**Version:** 4.1

### Architecture

```
Browser (choreographer.html)
    │
    │  HTTP POST (no-cors)
    ▼
Controller Prim (controller.lsl)
    │  llRequestURL() → HTTP-in endpoint
    │  llRegionSay(channel -9876543)
    ▼
Dancer Animesh 1 (dancer.lsl)     ← object description = "1"
Dancer Animesh 2 (dancer.lsl)     ← object description = "2"
Dancer Animesh 3 (dancer.lsl)     ← object description = "3"
...up to 12
```

The controller prim sits at **stage center**. Its world position is used as the origin for all dancer positions.

### Controller Script

**File:** `lsl/controller.lsl` (v4.1)

**Global state:**
- `CHOREO_CHANNEL` = `-9876543` — broadcast channel
- `g_url` — current HTTP-in URL (temporary, changes on region restart)
- `g_urlReqId` — request key for URL allocation

**Startup:**
1. Requests HTTP URL via `llRequestURL()`
2. On grant: stores URL, displays it as green hovertext, chats it to owner
3. On deny: shows red error hovertext

**HTTP request handling:**

| POST body | Action | Response |
|-----------|--------|----------|
| `PLAY` | Broadcasts `PLAY\|<controller_position>` to all dancers | 200 "PLAY sent" |
| `STOP` | Broadcasts `STOP` | 200 "STOP sent" |
| `RESET` | Broadcasts `RESET` | 200 "RESET sent" |
| `DANCER\|num\|...` | Forwards entire message to all dancers | 200 "Dancer N loaded" |
| Other POST | Rejected | 400 "Unknown command" |
| Non-POST | Rejected | 405 "Use POST" |

**Region restart handling:** Detects `CHANGED_REGION` or `CHANGED_REGION_START`, requests a new URL automatically.

### Dancer Script

**File:** `lsl/dancer.lsl` (v4.1)

**Global state:**
- `g_dancerNum` — dancer number (1–12), read from object description
- `g_positions` — list of `[vector, float travel, float sleep, ...]` per layer
- `g_layerCount` — number of loaded layers
- `g_startPos` / `g_startRot` — original position/rotation for reset

**Commands received (via `llListen`):**

| Command | Behavior |
|---------|----------|
| `DANCER\|num\|x,y,z,t,s\|...` | If `num` matches this dancer: parse and store position data |
| `PLAY\|<center>` | Teleport to `center + layer0_pos`, then run keyframed motion through remaining layers |
| `STOP` | Halt all keyframed motion immediately |
| `RESET` | Stop motion, teleport to original position, restore rotation, clear data |

**Keyframe building (on PLAY):**
1. Teleport to layer 0 absolute position via `llSetRegionPos()`
2. If layer 0 has sleep > 0.1s, add `ZERO_VECTOR` + sleep as first keyframe
3. For each subsequent layer: compute **delta vector** (position change from previous), use travel time (min 0.15s)
4. If layer has sleep > 0.1s, add hold keyframe
5. Execute via `llSetKeyframedMotion(keyframes, [KFM_MODE, KFM_FORWARD, KFM_DATA, KFM_TRANSLATION])`

The `KFM_TRANSLATION` mode means position-only movement — no rotation changes.

### Communication Protocol

**Web Tool → Controller (HTTP POST body):**
```
DANCER|<num>|<x,y,z,travel,sleep>|<x,y,z,travel,sleep>|...
PLAY
STOP
RESET
```

**Controller → Dancers (llRegionSay on channel -9876543):**
```
DANCER|<num>|<x,y,z,travel,sleep>|...    (forwarded as-is)
PLAY|<controller_position>                (center reference added)
STOP
RESET
```

**Position format:** Pipe-delimited segments. Each position segment is comma-separated: `x,y,z,travelTime,sleepTime`

### Setup Guide

1. **Rez a prim** at stage center. This is your controller.
2. Put `controller.lsl` into the controller prim's inventory.
3. The script will request an HTTP URL and display it as hovertext.
4. **Rez animesh dancers** around the stage area.
5. Put `dancer.lsl` into each animesh object's inventory.
6. Set each animesh object's **Description** to its dancer number (1–12).
7. In `choreographer.html`, paste the controller URL into the **Live Control** URL input.
8. Click **Send Data** to load positions, then **Play** to execute.

### Animesh vs Real Avatars

The LSL engine currently targets **animesh dancers** (NPC-like mesh objects). However, Second Life also supports triggering animations on **real avatars**. The two approaches differ significantly in how animations are stored and controlled.

| Aspect | Animesh Dancers | Real Avatars |
| ------ | --------------- | ------------ |
| **LSL function** | `llStartObjectAnimation("name")` | `llStartAnimation("name")` |
| **Animation storage** | In each animesh object's own inventory | In the controller prim's inventory |
| **Permissions** | None required (object controls itself) | `PERMISSION_TRIGGER_ANIMATION` from each avatar |
| **Setup** | Place anims in each dancer object | Place all anims in one controller prim |
| **Script location** | One script per animesh object | Controller script requests permission from each avatar |
| **Stopping** | `llStopObjectAnimation("name")` | `llStopAnimation("name")` |

**Why the difference?**

- `llStartObjectAnimation()` only looks in the **calling object's own inventory**. There is no way to play an animation from another object's inventory on an animesh. Each animesh dancer must contain every animation it will ever play.
- `llStartAnimation()` plays an animation on the **avatar that granted permission**, and searches the **calling object's inventory** for the animation. This means a single controller prim can hold all animations and trigger them on multiple avatars.

**Template dancer workflow (animesh):**

Since each animesh dancer needs the same set of animations plus the dancer script, the recommended workflow is:

1. Build a **template animesh object** containing:
   - `dancer.lsl` script
   - All animations the choreography uses
2. **Duplicate** (copy) the template for each dancer position needed
3. **Set the object description** on each copy to its dancer number (`1`, `2`, `3`, etc.)
4. The `on_rez()` handler in `dancer.lsl` calls `llResetScript()`, which re-reads the description — no script editing required

This works because `dancer.lsl` reads its dancer number from `llGetObjectDesc()` on startup, and `on_rez()` triggers a full reset on every rez.

**Real avatar workflow:**

The real-avatar system uses a "central controller + slot scripts" architecture (see [Real Avatar System](#real-avatar-system) below). Key points:

1. All animations stored in the controller prim (shared inventory)
2. Multiple slot scripts in the controller (one per dancer), each holding `PERMISSION_TRIGGER_ANIMATION` from one avatar
3. Separate mover prims handle avatar seating and keyframed motion
4. Avatars sit on movers; the slot scripts handle animation playback

### Real Avatar System

**Files:** `lsl/avatar-controller.lsl`, `lsl/avatar-slot.lsl`, `lsl/avatar-mover.lsl`
**Version:** 1.0

Uses a "central controller + slot scripts" architecture (similar to SpotOn and other SL dance HUDs). Runs on channel `-9876544`, separate from the animesh system's `-9876543`.

#### Avatar System Architecture

```
Browser (choreographer.html / timeline.html)
    │ HTTP POST
    ▼
Controller Prim (at stage center)
├── avatar-controller.lsl       ← master: HTTP-in, routes commands
├── avatar-slot 1               ← permissions + animation for avatar A
├── avatar-slot 2               ← permissions + animation for avatar B
├── avatar-slot N...
├── dance_animation_1.bvh
├── dance_animation_2.bvh
└── ...
    │                                    │
    │ llRegionSay(-9876544)              │ llMessageLinked(slot#)
    │ movement commands                  │ animation commands
    ▼                                    ▼
Mover Prim 1 (desc="1")          Slot 1 → llStartAnimation() on avatar A
Mover Prim 2 (desc="2")          Slot 2 → llStartAnimation() on avatar B
```

#### Controller Prim Contents

| Script / Asset | Purpose |
| -------------- | ------- |
| `avatar-controller.lsl` | Master script: HTTP-in bridge, routes commands to movers and slots |
| `avatar-slot 1` ... `avatar-slot N` | Copies of `avatar-slot.lsl`, one per dancer. Each holds animation permission for one avatar |
| Dance animations | Shared inventory — all slot scripts access the same animation files |

**How slot scripts work:** Each copy reads its slot number from its own script name via `llGetScriptName()` (e.g., `"avatar-slot 3"` → slot 3). This is the standard LSL pattern used by SpotOn, ZHAO, and other multi-avatar systems. Since each LSL script can only hold `PERMISSION_TRIGGER_ANIMATION` from one avatar at a time, you need N scripts for N dancers.

#### Mover Prims

One mover prim per dancer position. Each contains `avatar-mover.lsl` with the object description set to the dancer number (1–12). Movers provide:

- **Sit target** — `llSitTarget()` so avatars can sit
- **Sit detection** — `changed(CHANGED_LINK)` notifies the controller when an avatar sits or stands
- **Keyframed motion** — same position storage and `llSetKeyframedMotion()` logic as `dancer.lsl`

The mover does NOT handle animations — that is the slot scripts' job.

#### Avatar System Communication

**HTTP commands (browser → controller):**

| Command | Action |
| ------- | ------ |
| `DANCER\|num\|positions...` | Forward to movers (movement data) |
| `PLAY` | Forward to movers with center position |
| `STOP` | Forward to movers + broadcast STOPALL to slots |
| `RESET` | Forward to movers + release all slots |
| `ANIM\|num\|animName` | Start animation on dancer via slot script |
| `ANIMSTOP\|num\|animName` | Stop specific animation via slot |
| `ANIMSTOP\|num\|ALL` | Stop all animations on dancer |

**Channel messages (movers ↔ controller on -9876544):**

| Direction | Message | Purpose |
| --------- | ------- | ------- |
| Mover → Controller | `AVATAR_SIT\|num\|avatarKey` | Avatar sat on mover |
| Mover → Controller | `AVATAR_UNSIT\|num` | Avatar stood up |
| Controller → Movers | `DANCER\|...`, `PLAY\|...`, `STOP`, `RESET` | Movement commands |

**Link messages (controller → slots, within same prim):**

| num param | str param | id param | Purpose |
| --------- | --------- | -------- | ------- |
| dancerNum | `ASSIGN` | avatarKey | Assign avatar to slot |
| dancerNum | `RELEASE` | — | Release avatar from slot |
| dancerNum | `ANIM\|name` | — | Start animation |
| dancerNum | `ANIMSTOP\|name` | — | Stop specific animation |
| 0 | `STOPALL` | — | Stop all (broadcast to all slots) |

#### Setup Guide (Real Avatars)

1. **Rez a prim** at stage center — this is the controller.
2. Put `avatar-controller.lsl` into the controller prim.
3. Copy `avatar-slot.lsl` and rename copies to `avatar-slot 1`, `avatar-slot 2`, ... `avatar-slot N` (one per dancer needed).
4. Put all slot script copies into the controller prim.
5. Put all **dance animation files** into the controller prim.
6. The controller will request an HTTP URL and display it as hovertext.
7. **Rez mover prims** around the stage (can be invisible/tiny prims).
8. Put `avatar-mover.lsl` into each mover prim.
9. Set each mover prim's **Description** to its dancer number (`1`, `2`, `3`, ...).
10. Participating avatars **right-click → Sit** on their assigned mover prim.
11. The mover detects the sit and notifies the controller.
12. The slot script requests animation permission — the avatar must **Accept** the dialog.
13. In the web tool, paste the controller URL and send position/animation data.

### LSL Constraints

| Limit | Value | Impact |
|-------|-------|--------|
| Script memory | 64KB (mono) | Keep data compact |
| Keyframes per call | 255 max | Long choreographies may need splitting |
| Chat message | 1024 bytes max | May need to split large dancer data |
| HTTP body | 2048 bytes max | May need chunked transfer |
| HTTP URLs | Temporary | Change on region restart (handled automatically) |
| Min movement time | 0.15s | Clamped in dancer script to prevent drift |

---

## Data Structures

### Choreographer Project (v3)

```javascript
{
    version: 3,
    layers: [                           // Array of layers
        [                               // Each layer: array of 12 dancer slots
            { x, y, z, t, s, r },       // Position, travel, sleep, rotation
            null,                        // null = dancer not placed
            ...
        ]
    ],
    currentLayer: 0,
    dancerCount: 6,
    numGroups: 1,
    dancerGroups: [1,1,1,1,1,1,1,1,1,1,1,1],  // Group assignment per dancer
    stageCenter: { x: 128, y: 128, z: 25 },
    stageShape: "rectangle",
    marginVisible: false,
    marginSize: 1.0,
    showPaths: true,
    // ... UI state values
}
```

### Timeline Project (v2)

```javascript
{
    version: 2,
    song: {
        title: "Untitled",
        duration: 180,          // seconds
        bpm: 0,                 // 0 = no beat grid
        bpmOffset: 0
    },
    animationSets: [
        {
            id: "set_...",
            name: "Dakota Burlesque",
            mirrorRule: "{name}_Mirror"
        }
    ],
    animationLibrary: [
        {
            id: "anim_...",
            name: "Dakota_Burlesque_1",
            duration: 28.5,
            color: "#4488FF",
            markers: [{ time: 14.0, label: "Turn" }],
            setId: "set_..."        // or "" for ungrouped
        }
    ],
    markers: [
        { id: "mkr_...", time: 0, label: "Intro", color: "#FF6644" }
    ],
    lyrics: [
        { id: "lyr_...", time: 5, text: "When the music starts..." }
    ],
    groups: [
        {
            id: "grp_...",
            name: "Group 1",
            groupIndex: 1,          // Maps to choreographer timing groups
            color: "#00FF00",
            blocks: [
                {
                    id: "blk_...",
                    animationId: "anim_...",
                    startTime: 0,
                    duration: 28.5,
                    label: "",          // Custom label (empty = use anim name)
                    mirrored: false
                }
            ]
        }
    ],
    viewState: {
        scrollX: 0,
        zoom: 1.0,
        snapToGrid: false
    }
}
```

### CSV Import Format

```csv
Set Name,               ← line with name but no valid duration = set header
animation_name_1,28.5   ← name,duration = animation in that set
animation_name_2,30.0
,                        ← empty line (ignored)
Another Set,
another_anim,25.3
```

The parser uses `lastIndexOf(',')` to split name from duration, so animation names can contain commas if needed (though not recommended).

---

## Integration Between Tools

The choreographer and timeline are **separate tools** with separate project data and separate `localStorage` keys. They connect through a shared concept: **timing groups**.

```
choreographer.html                          timeline.html
┌─────────────────────┐                    ┌─────────────────────┐
│ dancerGroups[]      │                    │ groups[]            │
│ D1 → Group 1       │◄── manual match ──►│ Group 1 track       │
│ D2 → Group 2       │                    │ Group 2 track       │
│ D3 → Group 1       │                    │ Group 3 track       │
│ ...                 │                    │ ...                 │
│                     │                    │                     │
│ WHERE dancers go    │                    │ WHAT they dance     │
│ (positions, layers) │                    │ (animations, timing)│
└─────────────────────┘                    └─────────────────────┘
         │                                           │
         │ sendToSL()                                │ (future)
         ▼                                           ▼
    controller.lsl ──────► dancer.lsl ──── llSetKeyframedMotion()
    (HTTP-in)        (positions)           llStartObjectAnimation()
                                           (future: animations)
```

**Current integration:**
- Both tools use `groupIndex` numbering — the user matches these manually
- The choreographer handles spatial data (positions + timing groups)
- The timeline handles temporal data (animation schedules per group)

**Future integration (planned):**
- Combined "Advanced" page linking both tools via shared project data
- Animation playback via `llStartObjectAnimation()` / `llStopObjectAnimation()` sent through the LSL engine
- Audio file loading with waveform visualization
- Auto BPM detection from audio

---

## Version History

| Version | Changes |
|---------|---------|
| **v1** | Basic planner with top-down view, 6 dancers |
| **v2** | 3-panel view, formations, 12 dancers, timing groups, stage shapes |
| **v3** | Stage center, notecard export with per-dancer `@pos_offset`, project persistence |
| **v4** | Custom LSL engine with HTTP-in web integration, Live Control panel |
| **v5** | Dance Timeline Planner — animation library, song timeline, per-group tracks, visual playback |
| **v6** | Animation Sets with configurable mirror naming rules, per-block mirror toggle |
| **v7** | Separated specs, CSV import for bulk-loading animation libraries |
| **v8** | System wiki documentation |
| **v9** | Real-avatar choreography system — avatar-controller, avatar-slot, avatar-mover scripts |
