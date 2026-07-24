# Equipment

## Documentation status

- **Reviewed for:** Build 49.39
- **Scope:** Subsystem status and ownership guide
- **Status:** active planning reference
- **Compatibility rule:** Deprecated modules, calls, and probes remain documented and callable until a dedicated removal release.
- **Terminology:** “Deprecated” means supported legacy compatibility; “diagnostic-only” means it must not be treated as an authoritative gameplay path.


Planned responsibility: Equipment slots, modifiers, and derived bonuses.

## Current state

**Reserved / partially integrated.**

## Ownership

- Weapon-facing runtime values are currently handled by player stat hooks
- Gun reload rate is authoritative through `chainsaw.Gun.get_ReloadSpeedRate()`
- Future equipment affixes and item-level ownership belong here

## Maintenance note

Do not move validated player hooks merely for folder symmetry; introduce adapters first.

## Deprecation and compatibility policy

Project: Overflow currently favors compatibility over deletion. Legacy module paths, fallback hooks, reflection probes, and debug counters remain available when they are useful for old profiles, external scripts, alternate characters, or future RE Engine changes.

Authoritative systems are named explicitly in the relevant documentation. New code should call those paths first. Deprecated paths should receive bug fixes only when required to preserve compatibility; they should not gain new gameplay responsibilities.
