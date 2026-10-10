# Completion Plan: First Rehearsal to Community Sharing

Updated: 2026-09-05
Status: Planned; first complete in-world routine has not yet been tested.

## Intended outcome

Use SL Choreography as a private choreography tool for personal shows, with the option to share it with an SL Burlesque community. There is no plan to sell it. A blog post is optional and is not a completion requirement.

This plan updates the practical next step recorded in [DECISION.md](../DECISION.md): validate a real routine before preparing any community handoff. Keep the no-commercialization direction. Treat [future-plans.md](future-plans.md) as optional ideas, not a list of requirements for finishing.

## Milestone 1: One complete rehearsal in Second Life

Keep the first rehearsal small: one song, two dancers, a few animation changes, and a mirrored section. The goal is to plan and save a routine, run it in-world, stop it, adjust it, and replay it reliably.

### Prepare and inspect

- [ ] Choose the song and a small set of available animations, including a mirrored pair.
- [ ] Confirm whether this rehearsal uses real avatars or animesh, then select the corresponding scripts and setup instructions.
- [ ] Review the current browser tools and scripts for the chosen workflow, including the existing uncommitted changes. Preserve existing work.
- [ ] Establish how the planner, timeline, and selected in-world controller connect in the current implementation. Document any manual transfer or separate playback steps; do not assume integrated playback already works.
- [ ] Fix locally verifiable problems that block this rehearsal.
- [ ] Prepare exact setup steps and a short rehearsal checklist for the selected configuration.

### Rehearse in-world

- [ ] Set up the controller and two dancers, with the required animations and permissions.
- [ ] Plan and save the small routine; close and reopen it to verify that the saved version restores correctly.
- [ ] Load or transfer the routine using the supported workflow, recording any manual steps.
- [ ] Run the routine and check animation order, transitions, synchronization, and the mirrored section. Check spatial movement if included in this routine.
- [ ] Stop during playback and confirm both dancers stop as expected.
- [ ] Adjust the routine, save it, and replay it from the beginning.
- [ ] Check recovery after a controller reset or URL change: reconnect, reload as needed, and replay.
- [ ] Record failures and awkward steps, fix blockers, and repeat the affected checks.

Codex handles repository inspection, local fixes and checks, and written setup instructions. The owner handles Second Life setup and rehearsal actions and reports the observed results. Local checks alone do not establish in-world reliability.

### Acceptance criteria

The first milestone is complete when the routine can be saved and restored, performed with two dancers and the intended mirrored section, stopped, edited, and replayed successfully. The reconnection procedure must be understood and tested. Record remaining limitations explicitly; defer features that are unnecessary for this routine.

## Milestone 2: Ready for regular private use

- [ ] Verify export, backup, and restore for routines and dance-library data; do not rely only on browser storage.
- [ ] Rehearse a representative personal routine using the intended dancer count and duration.
- [ ] Keep a short pre-show checklist covering animations, permissions, connection, loaded routine, and stop controls.
- [ ] Review and preserve the tested version in Git without discarding unrelated work.
- [ ] Separate unresolved defects from optional enhancements.

Private-use completion means the owner can prepare, rehearse, perform, and recover a representative routine with documented, acceptable limitations.

## Milestone 3: Optional community sharing

Begin after the private workflow has been demonstrated successfully.

- [ ] Assemble a clean package containing the tested tools, scripts, and a short setup guide.
- [ ] Explain which animations recipients must supply themselves and how to configure mirrored pairs.
- [ ] Include a small example using placeholders or material permitted for redistribution.
- [ ] Select and add a license suitable for the intended sharing; non-commercial intent alone does not define license terms.
- [ ] Check the package for third-party content before distributing it. The existing decision record identifies the Abranimations timing PDF and Dance Times CSV for removal before public repository sharing, including from Git history. Plan any history rewrite separately and preserve private work.
- [ ] Let one community member try setup and a small rehearsal, then resolve the resulting blockers.
- [ ] Document known limitations and the hobby-project support expectations.

Selling, subscriptions, hosted relay infrastructure, engine ports, and a blog post are outside this completion plan. Revisit an optional feature only when a real rehearsal or community trial demonstrates a need.

## Rehearsal notes

For each run, record:

- Date and tested file version or commit:
- Dancer type and count:
- Song, animations, and routine file:
- Setup and transfer steps used:
- Expected result and observed result:
- Blockers or awkward steps:
- Fix and retest result:

## Next action

Inspect the implementation for the two-dancer rehearsal and prepare the exact setup checklist. No successful in-world rehearsal is claimed yet.
