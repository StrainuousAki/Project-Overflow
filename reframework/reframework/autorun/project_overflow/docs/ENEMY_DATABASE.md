# Project: Overflow — Enemy Database

## Documentation status

- **Reviewed for:** Build 49.80
- **Scope:** Project documentation
- **Status:** active reference
- **Compatibility rule:** Deprecated modules, calls, and probes remain documented and callable until a dedicated removal release.
- **Terminology:** “Deprecated” means supported legacy compatibility; “diagnostic-only” means it must not be treated as an authoritative gameplay path.


## Identity

Enemy definitions are keyed by the runtime `CharacterKindID` captured from `EnemyManager.notifyDead`.

Unknown, BioRand, and modded IDs use a fallback definition until mapped.

## Definition schema

```lua
["verified_kind_id"] = {
    display_name = "Enemy Name",
    family = "family_name",
    tier = "standard",
    base_xp = 25,
    loot_table = "enemy_standard",
    elite_profile = "standard",

    attributes = {
        health_multiplier = 1.0,
        damage_multiplier = 1.0,
        stagger_resistance = 1.0,
        status_resistance = 1.0,
        movement_multiplier = 1.0,
        critical_resistance = 0.0
    }
}
```

## Default elite profile

| Tier | Chance | XP multiplier | Logical loot rolls |
|---|---:|---:|---:|
| Normal | 85% | 1.0x | 1 |
| Champion | 10% | 1.75x | 2 |
| Elite | 4% | 3.0x | 3 |
| Legendary | 1% | 6.0x | 5 |

These values are initial balancing placeholders.

## Current release behavior

- XP awarding defaults to **on**.
- Native death hooks and the reward pipeline initialize with the framework.
- One confirmed, non-duplicate death produces one XP reward transaction.
- The resolved XP value can come from the family definition, appearance
  overrides, BioRand classification, fixed-XP overrides, and elite multipliers.
- Logical loot rolling defaults to **on**, but it does not modify the native
  inventory in this release.
- Elite tiers currently roll when the enemy is first resolved at death.
- A future spawn hook can move elite rolling and enemy-stat application to
  spawn time.


## CharacterParameter loadout probe

Build 48.12 records the live `CharacterParameter` object supplied through the dead enemy context.

The probe reports:

- concrete CharacterParameter runtime type
- managed pointer
- a compact parameter signature
- whitelisted weapon, equipment, costume, model, body, sex, and variant members when available

The probe deliberately avoids enumerating every field. It reads only known candidate members to reduce teardown-time reflection risk.

### Current observed Zealot archetype

| CharacterKindID | Context | Spawner ID | Observed appearance/loadout |
|---:|---|---:|---|
| 200001 | `chainsaw.Ch1c0z1Context` | `00000000` | Hooded female, crossbow |
| 200001 | `chainsaw.Ch1c0z1Context` | `00000001` | Hooded male, axe and shield |
| 200001 | `chainsaw.Ch1c0z1Context` | `00000007` | Black-robed/vest variant; crossbow or shield observed |
| 200001 | `chainsaw.Ch1c0z1Context` | `0000000B` | Heavier vest/body variant; shield observed |

Spawner ID is currently treated as a candidate appearance/body preset, not as a weapon identifier.


## Live bestiary editor

Build 48.14 pre-registers the native CharacterKindID catalog and retains each Capcom `ch*` identifier.

After an enemy is killed:

```text
Developer
└── Enemy Discovery
    └── Discovered CharacterKindIDs
        └── Edit Enemy Definition
```

Editable values:

- friendly name
- family
- base XP
- loot table
- elite profile
- identified status
- names for observed SpawnerID/model variants

Edits persist in:

```text
reframework/data/project_overflow/enemy_database.json
```

The internal `ch*` ID remains visible and is never replaced by the friendly name.


## Separate discovered records

Build 48.16 stops merging every observation under one CharacterKindID.

The runtime registry now uses:

```text
CharacterKindID|SpawnerID
```

Examples:

```text
200002|0018020E
200002|0018020F
200002|001800C5
```

Each record has its own:

- observed name
- family override
- base XP
- loot table
- elite profile
- identified status
- kill count and latest snapshot

Native `CharacterKindID` and Capcom `ch*` references remain visible as the underlying archetype.

Existing `variants` names are used as initial observed names, so the current JSON database remains compatible.


## Independent enemy records inside each CharacterKindID

Build 48.17 stores every observed enemy as a complete record rather than one shared definition plus a variant name.

The saved JSON shape is:

```json
{
  "200000": {
    "enemies": [
      {
        "enemy_id": "0000000D",
        "display_name": "Middle-aged Villager",
        "family": "ganado",
        "base_xp": 10,
        "loot_table": "enemy_standard",
        "elite_profile": "standard",
        "identified": true
      },
      {
        "enemy_id": "001800C9",
        "display_name": "White Haired Old Male Villager",
        "family": "ganado",
        "base_xp": 10,
        "loot_table": "enemy_standard",
        "elite_profile": "standard",
        "identified": true
      }
    ]
  }
}
```

Each list item is independent. Changing one enemy's XP, name, family, loot table, or elite profile does not modify another enemy sharing the same CharacterKindID.

Older `variants` and Build 48.16 `observations` data migrate automatically when the database loads.


## Family definition with per-enemy descriptions

Build 48.18 uses one RPG definition per CharacterKindID/family:

```json
{
  "200000": {
    "display_name": "Ganado",
    "family": "ganado",
    "base_xp": 10,
    "loot_table": "enemy_standard",
    "elite_profile": "standard",
    "identified": true,
    "enemies": [
      {
        "enemy_id": "0000000D",
        "description": "Middle-aged Villager"
      },
      {
        "enemy_id": "001800C9",
        "description": "White Haired Old Male Villager"
      }
    ]
  }
}
```

`display_name` is the readable family/archetype name and stays aligned with `family`.

Each `enemy_id` stores only its corresponding visual/model description. XP, loot, and elite settings remain on the family definition unless a later system intentionally adds explicit per-enemy overrides.


## Appearance schema

Build 48.19 renames the visual-model list from `enemies` to `appearances`.

```json
{
  "200000": {
    "internal_id": "ch1_c0z0",
    "display_name": "Ganado",
    "family": "ganado",
    "base_xp": 20,
    "loot_table": "enemy_standard",
    "elite_profile": "standard",
    "identified": true,
    "appearances": [
      {
        "enemy_id": "0000000D",
        "description": "Middle-aged Villager"
      },
      {
        "enemy_id": "001800C9",
        "description": "White Haired Old Male Villager"
      }
    ]
  }
}
```

The `enemy_id` field is retained because that is the runtime value exposed by the game. The list name `appearances` makes its purpose clear: these are visual/model observations, not separate RPG archetypes.

Older `variants`, `observations`, and `enemies` formats migrate automatically.


## Grouped appearances and automatic enemy_id registration

Build 48.20 groups multiple runtime `enemy_id` values under one visual appearance:

```json
{
  "200009": {
    "display_name": "Plaga",
    "family": "plagas",
    "base_xp": 10,
    "appearances": [
      {
        "description": "Spider Plaga",
        "enemy_ids": [
          "000001A6",
          "000001D5",
          "000001D7",
          "000001DB",
          "000001DC",
          "000001DD"
        ]
      }
    ]
  }
}
```

Every killed enemy_id is registered automatically.

Automatic grouping rules:

1. Already known ID: keep its current appearance group.
2. No appearance groups: create `Unidentified Appearance`.
3. Exactly one appearance group: append the new ID to that group.
4. Multiple appearance groups: place the ID under `Unsorted Appearance IDs` until manually identified.

Renaming an appearance group updates the description for all IDs inside that group.


## Appearance-level RPG overrides

Build 48.21 keeps family values as defaults, but appearance groups may override them:

```json
{
  "200001": {
    "display_name": "Zealot",
    "family": "zealot",
    "base_xp": 30,
    "loot_table": "enemy_standard",
    "elite_profile": "standard",
    "appearances": [
      {
        "description": "Red Zealot | Leader Zealot",
        "enemy_ids": ["001801AF"],
        "base_xp_override": 30,
        "fixed_xp": 250,
        "loot_table_override": "enemy_elite",
        "elite_profile_override": "standard",
        "forced_elite_tier": "elite"
      }
    ]
  }
}
```

`fixed_xp` bypasses the elite XP multiplier. This allows an appearance to be forced to Elite while awarding exactly 250 XP.

Supported forced tiers:

- `inherit`
- `normal`
- `champion`
- `elite`
- `legendary`
- `boss`

Disabling **Override Family RPG Settings** removes all appearance overrides and returns the group to inherited family defaults.


## Safe provisional appearance records

Build 48.22 removes automatic appearance inference.

Every newly discovered runtime `enemy_id` now begins in its own appearance record:

```json
{
  "description": "Unidentified Appearance [001801DC]",
  "enemy_ids": ["001801DC"]
}
```

This prevents visually unrelated enemies sharing one CharacterKindID from being merged into an `Unsorted Appearance IDs` group.

Existing shared placeholder groups named `Unidentified Appearance` or `Unsorted Appearance IDs` are automatically split into one record per ID when the database loads.

IDs should only be merged after the player confirms that they use the same model.


## Appearance-level archetype overrides

Build 48.23 treats CharacterKindID as a native runtime pool rather than a guaranteed enemy family.

An appearance can independently override:

- display name
- family
- identified state
- base XP
- fixed final XP
- loot table
- elite profile
- forced elite tier

Example:

```json
{
  "200000": {
    "display_name": "Ganado",
    "family": "ganado",
    "base_xp": 20,
    "appearances": [
      {
        "description": "White Male Black Bull-Headed Brute",
        "enemy_ids": ["001801F6"],
        "display_name_override": "Bull-Headed Brute",
        "family_override": "brute",
        "identified_override": true,
        "fixed_xp": 250,
        "loot_table_override": "enemy_elite",
        "forced_elite_tier": "elite"
      }
    ]
  }
}
```

The CharacterKindID-level values remain native-pool defaults. They no longer need to describe every model BioRand places in that pool.


## Seed-independent runtime classification

Build 48.24 introduces a learned runtime fingerprint classifier.

The fingerprint intentionally favors live model/configuration signals:

- concrete context type
- character parameter type/signature
- body updater type
- head updater type
- body/head/spawn GameObject names
- costume preset
- mesh signature

CharacterKindID and stage are not part of the fingerprint because randomizers may reuse them for unrelated models.

Workflow:

1. Kill an unknown enemy.
2. Correct its Appearance Description, Display Name, Family, XP, loot, and tier.
3. Save the appearance.
4. Press **Learn Classifier From This Enemy**.
5. The fingerprint and confirmed template are saved to:

```text
reframework/data/project_overflow/enemy_classifier.json
```

When the same runtime fingerprint appears in another randomizer seed, Project: Overflow automatically assigns the learned family template and appearance overrides.

Unknown fingerprints remain isolated and are never guessed.

## Deprecation and compatibility policy

Project: Overflow currently favors compatibility over deletion. Legacy module paths, fallback hooks, reflection probes, and debug counters remain available when they are useful for old profiles, external scripts, alternate characters, or future RE Engine changes.

Authoritative systems are named explicitly in the relevant documentation. New code should call those paths first. Deprecated paths should receive bug fixes only when required to preserve compatibility; they should not gain new gameplay responsibilities.
