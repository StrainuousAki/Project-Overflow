# Internal Module Guide

## Documentation status

- **Reviewed for:** Build 49.81
- **Scope:** Project documentation
- **Status:** active reference
- **Compatibility rule:** Deprecated modules, calls, and probes remain documented and callable until a dedicated removal release.
- **Terminology:** “Deprecated” means supported legacy compatibility; “diagnostic-only” means it must not be treated as an authoritative gameplay path.


Project: Overflow uses canonical module paths. The forwarding aliases from older builds have been removed.

## Runtime entry point

`project_overflow.lua` installs health, HUD, shader, progression-panel, and save-slot hooks. It also owns the per-frame update and draw order.

## Canonical modules

- `project_overflow.shared.context` — persistent shared state and common helpers.
- `project_overflow.systems.health.core` — health capture and direct HP/max-HP operations.
- `project_overflow.systems.health.runtime` — recurring health/stat synchronization.
- `project_overflow.systems.player.rpg` — profile, XP, levels, attributes, and persistence facade.
- `project_overflow.systems.player.stat_application` — applies derived RPG stats to captured native objects.
- `project_overflow.render.renderer` — overflow-health rendering.
- `project_overflow.xp.init` — XP-ring update, controls, and draw facade.
- `project_overflow.ui.main` — main ImGui window.
- `project_overflow.ui.inventory_progression` — attaché-case progression overlay and input mapping.

## Attaché-case visibility contract

The progression overlay opens from `chainsaw.AttacheCaseManager.get_IsAttacheCaseBusy()`. The zero-argument `requestExitAttacheCaseLight()` hook starts the close fade before the busy flag clears. The early-exit latch remains set until a real native `false -> true` busy transition proves that a new attaché-case session has started.

## Save profiles

`systems/player/game_save_sync.lua` observes native save/load operations and selects the matching profile. `systems/player/save_data.lua` owns profile paths and one-time migration from older profile locations.

## Compatibility policy

Compatibility code is kept only when it protects existing player data or a confirmed game-version difference. Empty forwarding files and duplicate public paths are not retained.

## Release initialization contract

`autorun/project_overflow.lua` initializes release-critical systems before it
registers frame or ImGui callbacks:

1. Subscribe the enemy event and reward pipeline.
2. Enable enemy XP rewards.
3. Install the native death probe.
4. Register guarded retry logic only when the death types were unavailable.
5. Register runtime update, draw, and UI callbacks.

These operations are idempotent. Reloading the Lua entry point must not stack
duplicate death hooks or duplicate XP transactions.

## Module status vocabulary

- **Authoritative:** Current production path for gameplay or persistence.
- **Compatibility shim:** Stable import that forwards to another implementation or reserves an old namespace.
- **Deprecated fallback:** Supported legacy behavior used only when the authoritative path is unavailable.
- **Diagnostic-only:** Reflection or lifecycle probe that records evidence but must not mutate gameplay.
- **Experimental:** May change between internal builds and should not be consumed as a public API.

Callers should import the canonical module named in this guide. Compatibility adapters may remain indefinitely, but new dependencies should not be added to them.

## Deprecation and compatibility policy

Project: Overflow currently favors compatibility over deletion. Legacy module paths, fallback hooks, reflection probes, and debug counters remain available when they are useful for old profiles, external scripts, alternate characters, or future RE Engine changes.

Authoritative systems are named explicitly in the relevant documentation. New code should call those paths first. Deprecated paths should receive bug fixes only when required to preserve compatibility; they should not gain new gameplay responsibilities.
