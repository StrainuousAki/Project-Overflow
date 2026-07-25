# Project: Overflow — Enemy Runtime Reference

## Documentation status

- **Reviewed for:** Build 49.80
- **Scope:** Project documentation
- **Status:** active reference
- **Compatibility rule:** Deprecated modules, calls, and probes remain documented and callable until a dedicated removal release.
- **Terminology:** “Deprecated” means supported legacy compatibility; “diagnostic-only” means it must not be treated as an authoritative gameplay path.


## Confirmed native architecture

The native death event is exposed by:

```text
chainsaw.EnemyManager.notifyDead(
    chainsaw.HitController.DamageInfo,
    chainsaw.EnemyBaseContext
)
```

`EnemyBaseContext` inherits from `CharacterContext`, which exposes:

- `CharacterKindID KindID`
- `ContextID SpawnerID`
- `CharacterSpawnParam CharacterSpawnParam`
- `HitPoint HitPoint`
- `character.Vital HitPointVital`
- `bool IsProcessedCharacterOnDead`
- `bool IsEliminated`
- position, stage, space, segment, and action data

Concrete enemy contexts add enemy-specific systems. Example:

```text
chainsaw.Ch1d4z0Context
```

adds weak-point state and enemy-specific lifecycle values.

## Database key strategy

Primary key:

```text
CharacterKindID.ToString()
```

Secondary metadata:

```text
Concrete context type
SpawnerID
StageID
SegmentID
CharacterSpawnParam
StrongIndividual
GameRankAdd
```

This should remain compatible with BioRand because the hook receives the actual live enemy context that the game declares dead.

## EnemyDefine

`chainsaw.EnemyDefine` appears to primarily map weapon IDs to enemy motion-bank categories. It is not currently treated as the enemy identity source.

## Runtime mapping table

| CharacterKindID | Context type | Friendly name | Variant | Base XP | Notes |
|---|---|---|---|---:|---|
| _Pending native captures_ |  |  |  |  |  |

## Deprecation and compatibility policy

Project: Overflow currently favors compatibility over deletion. Legacy module paths, fallback hooks, reflection probes, and debug counters remain available when they are useful for old profiles, external scripts, alternate characters, or future RE Engine changes.

Authoritative systems are named explicitly in the relevant documentation. New code should call those paths first. Deprecated paths should receive bug fixes only when required to preserve compatibility; they should not gain new gameplay responsibilities.
