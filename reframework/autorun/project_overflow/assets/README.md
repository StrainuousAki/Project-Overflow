# Assets

## Documentation status

- **Reviewed for:** Build 49.39
- **Scope:** Asset directory conventions
- **Status:** active support reference
- **Compatibility rule:** Existing asset names and relative paths should remain stable once referenced by a profile, shader, or renderer.

## Directory policy

Place project-owned textures, material definitions, icons, and generated lookup data below this directory. Runtime scripts should reference assets through stable project-relative paths rather than absolute installation paths.

Generated diagnostics and user profiles do not belong here. They remain under `reframework/data/project_overflow/`.

## Deprecation and compatibility policy

Renaming an asset is a compatibility change. Retain an alias or migration path when an existing release may reference the old name.
