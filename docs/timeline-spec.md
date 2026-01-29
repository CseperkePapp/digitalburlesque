# Dance Timeline Planner (timeline.html)

Single-file HTML/JS app for planning which SL animations play when, synced to a song. Handles the **temporal** side (what plays when) vs the choreographer's **spatial** side (where dancers go).

## Completed Features

- [x] Animation Library panel: add/edit/delete SL animations with name, duration, color, key moment markers
- [x] Mini-timeline bars in library entries showing marker positions
- [x] Canvas-based horizontal timeline with time ruler (auto-scaling ticks)
- [x] Beat grid overlay when BPM is set
- [x] Section markers track (colored spans with labels: Intro, Verse, Chorus, etc.)
- [x] Lyrics track (text at timestamps)
- [x] Per-group animation tracks (one track per timing group)
- [x] Animation blocks as colored rounded rectangles with text labels and marker triangles
- [x] Drag animations from library onto group tracks
- [x] Move blocks (drag body), resize blocks (drag edges)
- [x] Snap-to-grid (snaps to beats when BPM set and Snap enabled)
- [x] Visual playback cursor (sweeps at real-time speed, auto-scrolls)
- [x] Transport controls: Play/Pause, Stop, click-ruler-to-seek, Space bar shortcut
- [x] Scroll (mouse wheel) and zoom (Ctrl+wheel, toolbar buttons) with zoom-toward-cursor
- [x] Right-click context menus for markers, lyrics, blocks, and tracks
- [x] Double-click to add markers/lyrics, edit block labels
- [x] Add/remove/rename group tracks
- [x] Delete blocks via Delete/Backspace key
- [x] Persistence: localStorage auto-save, JSON export/import, New Project
- [x] Separate animation library export/import (for sharing between projects)
- [x] CSV import for bulk-loading animations with auto-set detection

## Animation Sets & Mirroring (v2)

- [x] Animation Sets: named groups (e.g., "burlesque") with configurable mirror naming rules
- [x] Mirror rule uses `{name}` template placeholder (e.g., `{name}_mirror`, `Mirror_{name}`, `{name} (mirror)`)
- [x] Sets management dialog (add/edit/delete sets)
- [x] Animations assigned to sets via dropdown in edit dialog
- [x] Library panel groups animations by set, shows derived mirror name
- [x] Timeline blocks can be toggled to "mirror" via right-click context menu
- [x] Mirrored blocks display the derived mirror animation name with "M" badge

## Data Structures

### Project State (v2)

```javascript
{
    version: 2,
    song: { title, duration, bpm, bpmOffset },
    animationSets: [
        { id, name, mirrorRule }    // mirrorRule e.g. "{name}_mirror"
    ],
    animationLibrary: [
        { id, name, duration, color, markers: [{ time, label }], setId }
    ],
    markers: [{ id, time, label, color }],
    lyrics: [{ id, time, text }],
    groups: [{
        id, name, groupIndex, color,
        blocks: [{ id, animationId, startTime, duration, label, mirrored }]
    }],
    viewState: { scrollX, zoom, snapToGrid }
}
```

### CSV Import Format

```csv
Set Name,               <- line with name but no duration = set header
animation_name_1,28.5   <- name,duration pairs = animations in that set
animation_name_2,30.0
,                        <- empty line = separator (ignored)
Another Set,
another_anim,25.3
```

## Planned Features

- [ ] Audio file loading (mp3) with synced playback
- [ ] Waveform visualization on timeline
- [ ] Auto BPM detection from audio
- [ ] Combined "Advanced" page linking timeline with spatial choreographer

## Integration Point

Group tracks use `groupIndex` that maps to choreographer.html's timing groups. The user matches these manually. Future "Advanced" page can link them via shared project data.
