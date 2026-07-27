# Relics

## Documentation status

- **Reviewed for:** Build 49.81
- **Scope:** Subsystem status and ownership guide
- **Status:** active planning reference
- **Compatibility rule:** Deprecated modules, calls, and probes remain documented and callable until a dedicated removal release.
- **Terminology:** “Deprecated” means supported legacy compatibility; “diagnostic-only” means it must not be treated as an authoritative gameplay path.


Planned responsibility: Relic definitions, ownership, and passive effects.

## Current state

**Planned.**

## Ownership

- Persistent passive modifiers
- Data-driven rarity and stacking rules
- Profile serialization and inventory presentation

## Maintenance note

No active relic gameplay implementation should be inferred from placeholder modules.

## Deprecation and compatibility policy

Project: Overflow currently favors compatibility over deletion. Legacy module paths, fallback hooks, reflection probes, and debug counters remain available when they are useful for old profiles, external scripts, alternate characters, or future RE Engine changes.

Authoritative systems are named explicitly in the relevant documentation. New code should call those paths first. Deprecated paths should receive bug fixes only when required to preserve compatibility; they should not gain new gameplay responsibilities.
