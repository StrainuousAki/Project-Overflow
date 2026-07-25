# Inventory

## Documentation status

- **Reviewed for:** Build 49.80
- **Scope:** Subsystem status and ownership guide
- **Status:** active planning reference
- **Compatibility rule:** Deprecated modules, calls, and probes remain documented and callable until a dedicated removal release.
- **Terminology:** “Deprecated” means supported legacy compatibility; “diagnostic-only” means it must not be treated as an authoritative gameplay path.


Planned responsibility: Inventory extensions and custom item ownership.

## Current state

**Native UI integration in progress.**

## Ownership

- Progression overlay is rendered on the native items screen
- Save/load, typewriter, storage, and Charms/Case Custom are blocked
- Cursor input uses native inventory mouse coordinates

## Maintenance note

Old screen probes remain diagnostic-only. Verified armoury and save/typewriter state classification is authoritative.

## Deprecation and compatibility policy

Project: Overflow currently favors compatibility over deletion. Legacy module paths, fallback hooks, reflection probes, and debug counters remain available when they are useful for old profiles, external scripts, alternate characters, or future RE Engine changes.

Authoritative systems are named explicitly in the relevant documentation. New code should call those paths first. Deprecated paths should receive bug fixes only when required to preserve compatibility; they should not gain new gameplay responsibilities.
