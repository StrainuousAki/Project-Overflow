# Project: Overflow Roadmap

## Documentation status

- **Reviewed for:** Build 49.80
- **Scope:** Project documentation
- **Status:** active reference
- **Compatibility rule:** Deprecated modules, calls, and probes remain documented and callable until a dedicated removal release.
- **Terminology:** “Deprecated” means supported legacy compatibility; “diagnostic-only” means it must not be treated as an authoritative gameplay path.


## Stable foundation

- Keep save-slot profile synchronization predictable across manual saves, manual loads, continue, and autosave recovery.
- Keep vitality base-HP migration guarded so older profiles cannot double-apply or lose their bonus.
- Preserve the attaché-case busy poll and early-exit fade as the progression panel's visibility contract.
- Keep cursor calibration resolution-aware without bringing back the older fixed-resolution mappings.

## Gameplay integration

- Finish validating action-speed channels against real combat animations and weapon timing.
- Continue connecting derived stats to gameplay only when a native call has been observed and can be safely restored.
- Balance the active enemy XP rewards after the database has enough complete playthrough data.

## Presentation

- Refine the outer XP ring while preserving native HP and ammo readability.
- Keep overflow health layers readable at high max-HP values and during uncommon HUD states such as cutscenes.
- Move development-only controls out of everyday UI as systems become stable.

## Enemy framework

- Finish coverage for missing mutations, bosses, and special encounters.
- Keep recent-kill history bounded and lightweight.
- Continue validating BioRand identity matching against multiple seeds and campaigns.

## Documentation

- Record confirmed native types and calls in the RE Engine reference as they are tested.
- Keep the changelog focused on behavior users can observe, not speculative hooks.

## Build 49.39 maintenance milestone

- [x] Document authoritative walk/run and reload paths.
- [x] Mark retained compatibility shims and diagnostic probes.
- [x] Standardize module maintenance headers across every Lua script.
- [x] Refresh subsystem ownership documents.
- [ ] Continue reducing developer-panel noise after each runtime path is validated.
- [ ] Remove deprecated code only in a separately announced compatibility-breaking release.

## Deprecation and compatibility policy

Project: Overflow currently favors compatibility over deletion. Legacy module paths, fallback hooks, reflection probes, and debug counters remain available when they are useful for old profiles, external scripts, alternate characters, or future RE Engine changes.

Authoritative systems are named explicitly in the relevant documentation. New code should call those paths first. Deprecated paths should receive bug fixes only when required to preserve compatibility; they should not gain new gameplay responsibilities.
