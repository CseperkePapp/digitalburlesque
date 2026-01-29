# Spatial Choreography Planner (choreographer.html)

Single-file HTML/JS app with Canvas rendering for planning dancer positions and formations across layers.

## Completed Features

- [x] 3-panel view: TOP (X-Y), FRONT (X-Z), SIDE (Y-Z)
- [x] Up to 12 color-coded dancers (Green, Violet, Blue, Yellow, Orange, Red, Cyan, Pink, Mint, Plum, Sky, Khaki)
- [x] Layer system (unlimited layers) with onion skin (exponential opacity falloff)
- [x] Click-to-place dancers on any view
- [x] 13+ formation presets (line, circle, V-shape, grid, semicircle, arc, triangle, scatter, cluster, etc.)
- [x] Formation parameters: Spread, Radius, Position %
- [x] Stage shapes overlay: Rectangle, Half Circle, Half Oval, Rect + Half Circle, Trapezoid
- [x] Configurable stage size (W x D x H) with Apply button
- [x] Margin overlay with adjustable size
- [x] Front-of-stage indicators on TOP and SIDE views
- [x] Timing groups system (all sync, N groups, or individual)
- [x] Travel time (seconds) and Sleep time (seconds, default 10s)
- [x] Travel time locked to 0 on Layer 1 (starting position)
- [x] Movement path visualization (dotted lines in dancer colors)
- [x] Stage center input (paste SL coordinates, "Set Center" button)
- [x] Project persistence: localStorage auto-save, JSON export/import, New Project reset
- [x] SpotOn notecard export: Single dancer and All Dancers
- [x] Notecard format: @pos_offset = stageCenter + dancer's Layer 1 position; subsequent positions relative to start
- [x] Project state version 3 (includes stageCenter)

## Notecard Export Format

Each dancer's notecard contains:
```
@spot_dancer <number>
@pos_offset <stageCenter + layer1 position>
@rot_offset <0, 0, 0, 1>
<relX, relY, relZ>, <rot>, travelTime, sleepTime, 0, 0.5
...
```

Positions are relative to the dancer's own starting position (layer 1).

## Live Control

The choreographer integrates with the custom LSL engine (see [lsl-engine-spec.md](lsl-engine-spec.md)):
- URL input for pasting the controller's HTTP-in URL
- "Send Data" sends all dancer positions (absolute, relative to stage center)
- Play / Stop / Reset buttons forward commands to the controller
- Data format: `DANCER|num|x,y,z,travel,sleep|...` per dancer, with 500ms delay between sends
