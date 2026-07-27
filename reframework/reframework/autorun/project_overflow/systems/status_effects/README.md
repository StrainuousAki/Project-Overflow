# Status Effects

## Documentation status

- **Reviewed for:** Build 49.81
- **Scope:** Subsystem status and ownership guide
- **Status:** active planning reference
- **Compatibility rule:** Deprecated modules, calls, and probes remain documented and callable until a dedicated removal release.
- **Terminology:** “Deprecated” means supported legacy compatibility; “diagnostic-only” means it must not be treated as an authoritative gameplay path.


Planned responsibility: Timed effects, stacking, and modifiers.

## Current state

**Planned.**

## Ownership

- Timed player and enemy modifiers
- Stacking/refresh policies
- Save-safe serialization where appropriate

## Maintenance note

Status effects should modify derived values through public stat APIs rather than patching unrelated hooks.

## Deprecation and compatibility policy

Project: Overflow currently favors compatibility over deletion. Legacy module paths, fallback hooks, reflection probes, and debug counters remain available when they are useful for old profiles, external scripts, alternate characters, or future RE Engine changes.

Authoritative systems are named explicitly in the relevant documentation. New code should call those paths first. Deprecated paths should receive bug fixes only when required to preserve compatibility; they should not gain new gameplay responsibilities.
