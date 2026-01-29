# SL Choreography System

A web-based choreography planner with a custom LSL engine for Second Life animesh dancers.

**[Full Wiki](docs/wiki.md)** — comprehensive guide covering all features, data structures, setup, and integration.

## Components

| Component | File | Spec | Status |
|-----------|------|------|--------|
| Spatial Choreographer | `choreographer.html` | [docs/choreographer-spec.md](docs/choreographer-spec.md) | Done |
| LSL Engine (Animesh) | `lsl/dancer.lsl`, `lsl/controller.lsl` | [docs/lsl-engine-spec.md](docs/lsl-engine-spec.md) | Done (testing pending) |
| LSL Engine (Avatar) | `lsl/avatar-controller.lsl`, `lsl/avatar-slot.lsl`, `lsl/avatar-mover.lsl` | [docs/wiki.md#real-avatar-system](docs/wiki.md#real-avatar-system) | Done |
| Timeline Planner | `timeline.html` | [docs/timeline-spec.md](docs/timeline-spec.md) | Done |

## File Structure

```
SL-Choreography/
  choreographer.html          — Spatial choreography planner
  timeline.html               — Dance timeline planner
  ChoreoToolLogo.png          — Logo asset
  lsl/
    dancer.lsl                — Dancer animesh script (v4.1)
    controller.lsl            — Central controller script (v4.1)
    avatar-controller.lsl     — Avatar system master controller (v1.0)
    avatar-slot.lsl           — Avatar animation slot script (v1.0)
    avatar-mover.lsl          — Avatar mover prim script (v1.0)
  docs/
    choreographer-spec.md     — Choreographer specification
    lsl-engine-spec.md        — LSL engine specification
    timeline-spec.md          — Timeline planner specification
    wiki.md                   — Full system wiki
  CHOREOGRAPHY-SYSTEM-SPEC.md — This overview
```

## Version History

- v1: Basic planner with top-down view, 6 dancers
- v2: 3-panel view, formations, 12 dancers, timing groups, stage shapes
- v3: Stage center, notecard export with per-dancer @pos_offset, project persistence
- v4: Custom LSL engine with HTTP-in web integration, Live Control panel
- v5: Dance Timeline Planner (animation library, song timeline, per-group tracks, visual playback)
- v6: Animation Sets with configurable mirror naming rules, per-block mirror toggle
- v7: Separated specs, CSV import for bulk-loading animation libraries
- v8: System wiki documentation
- v9: Real-avatar choreography system (avatar-controller, avatar-slot, avatar-mover scripts)
