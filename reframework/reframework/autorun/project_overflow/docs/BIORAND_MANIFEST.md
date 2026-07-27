# BioRand Seed Manifest Integration

## Documentation status

- **Reviewed for:** Build 49.81
- **Scope:** Project documentation
- **Status:** active reference
- **Compatibility rule:** Deprecated modules, calls, and probes remain documented and callable until a dedicated removal release.
- **Terminology:** “Deprecated” means supported legacy compatibility; “diagnostic-only” means it must not be treated as an authoritative gameplay path.


Build 48.25 parses BioRand's generated `output_leon.log`.

## Install the active seed log

Copy the active seed's log to:

```text
reframework/data/project_overflow/biorand/output_leon.log
```

Then open:

```text
Developer
└── Enemy Discovery
    └── BioRand Seed Manifest
        └── Load BioRand output_leon.log
```

## Resolution

The manifest supplies the actual generated family (`villager`, `brute`, `zealot`, `regenerador`, etc.).

Runtime deaths are matched by:

1. exact Stage ID
2. nearest world position
3. uniqueness within the configured ambiguity range

A unique nearby manifest entry applies its reusable family template automatically.

Ambiguous or distant records do not guess. They fall back to the learned runtime fingerprint classifier and then to manual review.

## Priority

```text
BioRand active-seed manifest
→ learned runtime fingerprint
→ appearance override
→ native CharacterKindID defaults
```

The included example manifests were generated from supplied seeds `414186` and `171364`.


## Direct reward resolution

Build 48.26 passes the resolved BioRand family directly into the reward calculation.

For a manifest record classified as `brute`, the same kill immediately uses the Brute template for XP, loot, and tier. It does not wait for the appearance database to save and reload.

The manifest is loaded automatically when the first enemy death is resolved.

## Deprecation and compatibility policy

Project: Overflow currently favors compatibility over deletion. Legacy module paths, fallback hooks, reflection probes, and debug counters remain available when they are useful for old profiles, external scripts, alternate characters, or future RE Engine changes.

Authoritative systems are named explicitly in the relevant documentation. New code should call those paths first. Deprecated paths should receive bug fixes only when required to preserve compatibility; they should not gain new gameplay responsibilities.
