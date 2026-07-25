# Credits

## Documentation status

- **Reviewed for:** Build 49.80
- **Scope:** Project documentation
- **Status:** active reference
- **Compatibility rule:** Deprecated modules, calls, and probes remain documented and callable until a dedicated removal release.
- **Terminology:** “Deprecated” means supported legacy compatibility; “diagnostic-only” means it must not be treated as an authoritative gameplay path.


Created by **StrainuousAki**.

Special thanks: praydog, cursey, The Hitchhiker, alphaZomega, Bawkbasoup, GreenComfyTea, re_duke, and the Resident Evil Modding Community.

## Project maintenance

Project design, integration, reverse-engineering notes, and release maintenance are led by **StrainuousAki**.

Third-party names acknowledge tools, research, inspiration, or community support. Inclusion does not imply endorsement of every Project: Overflow implementation or release.

## Deprecation and compatibility policy

Project: Overflow currently favors compatibility over deletion. Legacy module paths, fallback hooks, reflection probes, and debug counters remain available when they are useful for old profiles, external scripts, alternate characters, or future RE Engine changes.

Authoritative systems are named explicitly in the relevant documentation. New code should call those paths first. Deprecated paths should receive bug fixes only when required to preserve compatibility; they should not gain new gameplay responsibilities.
