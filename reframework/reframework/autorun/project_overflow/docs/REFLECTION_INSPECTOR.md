# Project: Overflow — Reflection Inspector

## Documentation status

- **Reviewed for:** Build 49.80
- **Scope:** Project documentation
- **Status:** active reference
- **Compatibility rule:** Deprecated modules, calls, and probes remain documented and callable until a dedicated removal release.
- **Terminology:** “Deprecated” means supported legacy compatibility; “diagnostic-only” means it must not be treated as an authoritative gameplay path.


Build 48.13 adds bounded reflection snapshots for the exact objects already supplied by the native enemy death event.

## Current targets

- `CharacterParameter`
- `CharacterSpawnParam`

## Safety model

The inspector does **not**:

- enumerate world GameObjects
- scan by distance
- recursively walk managed references
- invoke arbitrary getters or methods
- retain a live object inspector across gameplay transitions

It captures one fixed snapshot during `EnemyManager.notifyDead`.

Simple primitive, enum, string, vector, range, quaternion, and hash fields are read. Managed references are shown as:

```text
<reference not traversed>
```

Method names are metadata only and are never invoked.

## Location

```text
Developer
└── Enemy Discovery
    └── Discovered CharacterKindIDs
        └── Last Native Snapshot
            └── Reflection Inspector
                ├── CharacterParameter
                └── CharacterSpawnParam
```

The most useful results will be fields that change between enemies sharing the same CharacterKindID and SpawnerID but carrying different equipment.

## Deprecation and compatibility policy

Project: Overflow currently favors compatibility over deletion. Legacy module paths, fallback hooks, reflection probes, and debug counters remain available when they are useful for old profiles, external scripts, alternate characters, or future RE Engine changes.

Authoritative systems are named explicitly in the relevant documentation. New code should call those paths first. Deprecated paths should receive bug fixes only when required to preserve compatibility; they should not gain new gameplay responsibilities.
