# Identity Refactor V3

## Documentation status

- **Reviewed for:** Build 49.39
- **Scope:** Project documentation
- **Status:** active reference
- **Compatibility rule:** Deprecated modules, calls, and probes remain documented and callable until a dedicated removal release.
- **Terminology:** “Deprecated” means supported legacy compatibility; “diagnostic-only” means it must not be treated as an authoritative gameplay path.


BioRand is spawn metadata only. It cannot set enemy identity, grouping, XP,
loot, elite tier, or display names.

Appearance records now include provenance:

- `provisional_observation`: automatically discovered, one ID only.
- `manual`: explicitly edited or grouped by the user.

On first load, legacy and unconfirmed groups are split into isolated
provisional records. Their identity/RPG overrides are discarded. Only explicit
V3 manual groups are preserved.

Runtime classifier mappings are accepted only when their source is
`user_confirmed_runtime_fingerprint` or `manual`.

The targeted costume snapshot remains diagnostic-only.

## Deprecation and compatibility policy

Project: Overflow currently favors compatibility over deletion. Legacy module paths, fallback hooks, reflection probes, and debug counters remain available when they are useful for old profiles, external scripts, alternate characters, or future RE Engine changes.

Authoritative systems are named explicitly in the relevant documentation. New code should call those paths first. Deprecated paths should receive bug fixes only when required to preserve compatibility; they should not gain new gameplay responsibilities.
