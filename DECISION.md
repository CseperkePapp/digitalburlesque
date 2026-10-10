# Decision Record — SL Choreography stays a hobby project

**Date:** 2026-07-06
**Status:** Decided
**Owner:** Cseperke

## Context

SL Choreography is a feature-complete, well-documented toolkit for planning and running synchronized and mirrored group dance in Second Life — a browser-based spatial choreographer, timeline planner, and dance database, plus an LSL runtime engine (controller + slot scripts) that drives the dancers in-world. The build is essentially done. The open question was what to *do* with it.

Three paths were evaluated:

1. **Commercialize** — a hybrid model: an IP-locked in-world product sold on the Marketplace, plus a hosted relay on a recurring subscription for stable connections, remote control, and licensing.
2. **Open-source it fully** — release on GitHub, optionally with a free full-permission in-world drop.
3. **Make it Unreal Engine compatible** — port or rebuild the system for UE.

## Decision

The project stays as it is: a personal **hobby project**. No commercialization, no hosted relay or subscription infrastructure, and no engine port for now. The one planned action is to **publish a blog post** about the project and what was learned building it.

## Rationale

- **The market is too niche for the effort.** SL group choreography is a sub-niche of a niche, with existing incumbents. For a solo operator, the recurring-revenue path carries ongoing commitments — relay uptime, billing, support — that outweigh the likely return.
- **The subscription engine is a business, not a feature.** Stable-URL relay + licensing + billing + support is real, continuous work, not a weekend add-on.
- **A UE (or Unity) port is a rebuild, not a port.** The LSL runtime — the hard, valuable part — is welded to Second Life's animation, permission, and networking model and does not transfer. Unreal also already ships Sequencer, a superior native animation timeline, which shrinks the tool's value there. The closest adjacent market for a *live social* dance system is social VR (Unity / VRChat / Resonite), not Unreal — and that space is likewise niche with existing tools (OpenSyncDance, VRDancing).
- **Writing it up is cheap and high-value.** A blog post captures the design and the lessons, doubles as portfolio, and keeps the door open without committing to any maintenance burden.

## Consequences

- No hosted infrastructure, billing, support channel, or uptime obligation. The tool keeps working for personal and community use via the existing manual-URL workflow.
- **Before anything is published publicly** (including linking the repo from the blog post): strip third-party content — the Abranimations timing PDF and the Dance Times CSV — from both the working files **and the git history**, and add a license file.

## What would make us revisit

- A specific, concrete application appears (a UE/VR venue, a production pipeline, or a commissioned build).
- Clear, repeated demand from other SL creators.
- Willingness to take on the operational commitment a subscription requires.

## Next action

- [ ] Write and publish a blog post about the project — the design, the mirror-sync engine, and the honest reasoning behind not commercializing it.
