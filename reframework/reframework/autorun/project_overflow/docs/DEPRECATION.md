# Project: Overflow — Deprecation Registry

## Documentation status

- **Reviewed for:** Build 49.80
- **Scope:** Supported legacy modules, calls, hooks, and diagnostic probes
- **Status:** authoritative maintenance reference
- **Compatibility rule:** Entries remain available unless a future changelog explicitly announces removal.
- **Terminology:** Deprecation does not mean immediate removal.

## Authoritative runtime paths

| System | Authoritative path |
|---|---|
| Walk/run movement | `chainsaw.PlayerBodyUpdater.getNextMotionSpeed()` |
| Reload speed | `chainsaw.Gun.get_ReloadSpeedRate()` |
| Native RPG saves | Slot `0` autosave; slots `1..20` manual |
| Progression overlay | Verified native inventory/items classification |
| Enemy XP and rewards | Enemy pipeline, classifier/database, rewards, leveling, and profile modules |

## Deprecated compatibility shims

| Module | Replacement or ownership | Reason retained |
|---|---|---|
| `project_overflow.engine.compatibility` | Dedicated subsystem compatibility code | Stable reserved namespace |
| `project_overflow.engine.hooks` | Concrete subsystem hook installers | Stable reserved namespace |
| `project_overflow.engine.natives` | Shared context and subsystem captures | Stable reserved namespace |
| `project_overflow.engine.reflection` | Shared context and inspector helpers | Stable reserved namespace |
| `project_overflow.engine.resolution` | Shared context/UI conversion | Stable reserved namespace |
| `project_overflow.render.ring` | `project_overflow.ring` | Import compatibility adapter |

## Deprecated or diagnostic-only runtime paths

### Movement

- `PlayerCommonParamUserData.onLoad()` capture is a fallback because the object normally loads before autorun hooks.
- Movement-group getter hooks produced no calls in the validated runtime.
- Player-graph discovery remains a bounded fallback.
- These paths must not supersede `PlayerBodyUpdater.getNextMotionSpeed()` without new runtime evidence.

### Reload

- `PlayerCommonParamUserData.get_ReloadLerpTime()` is a legacy diagnostic path.
- Reload behavior-tree lifecycle hooks are counters/diagnostics only.
- Behavior-tree `_McReloadSpeedRate` and local-motion writes are deprecated and disabled.
- `Gun.get_ReloadSpeedRate()` is the sole reload-speed application path.

### Inventory visibility

- Shared `GmItemBox` state cannot distinguish inventory, typewriter, and storage by itself.
- Experimental item-window and screen probes remain diagnostic-only.
- Verified save/load, typewriter, armoury/storage, and Charms/Case Custom blockers are authoritative.

### Save-slot synchronization

- Cursor-direction and cyclic navigation inference are deprecated for slot identity.
- Native convention is fixed: `0` autosave and `1..20` manual.
- Completion-event fallback remains available when a native request object cannot be read.

## Removal requirements

A deprecated path may be removed only when all of the following are true:

1. A replacement is validated in the supported RE4R and REFramework runtime.
2. No current module imports or calls the deprecated path.
3. Existing profile/save compatibility is unaffected or migrated.
4. Removal is announced in the changelog as a compatibility-breaking change.
5. A rollback artifact exists for the previous working build.

## Deprecation and compatibility policy

Project: Overflow favors evidence-based replacement and compatibility over cleanup by deletion. Deprecated code can remain for a long time when it is harmless, useful for diagnostics, or protects external callers.
