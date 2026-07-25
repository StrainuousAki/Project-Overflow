# Project: Overflow Changelog

## Alpha 0.2.1 — Build 49.80 — Main-menu profile lifecycle

- Added explicit `chainsaw.GameStateMainMenu` lifecycle hooks.
- Entering the main menu clears the previous RPG campaign state once.
- `_IsNewGameStart` identifies a fresh campaign without relying on player or
  HitPoint capture state.
- `get_CurrPhase()` and `<CurrPhase>k__BackingField` provide live main-menu
  diagnostics for testing native load and menu transitions.
- Removed the player-absence frame counter and every timer-driven profile reset.
- Healing, Max HP changes, stat application, inventory, cutscenes, and temporary
  player-reference gaps cannot clear or rebind the active RPG profile.
- Native Continue, manual Load, autosave selection, delayed HitPoint recapture,
  and profile reconciliation remain unchanged.
- Refreshing `project_overflow.lua` queues the active profile through the normal
  delayed load path.
- Discovered Enemy Records remains a rolling 10-entry cache.
- Added runtime attribute-balance controls with 0.001 increments for every
  per-point effect.
- Added editable maximum clamps for derived attribute effects, including
  intentionally extreme ranges for destructive testing.
- Added a warning that fire rate above x2.0 is known to crash with the LE 5,
  TMP, and CQBR.
- Renamed the permanent slot-recovery controls to RPG Profile Slot Recovery.
- RPG Profile Slot Recovery remains permanently available under Emergency RPG
  Profile Tools.
- Set the shipped Strength damage cap to x2.500.
- Preserved the default +0.005 damage per invested Strength point.
- Strength 250 (249 invested points) explicitly reaches the x2.500 cap; lower
  values retain the existing linear scaling curve.
- Added persistent attribute tuning in
  `data/project_overflow/attribute_balance.json`.
- Per-point values and maximum clamps now survive game restarts and
  `project_overflow.lua` refreshes.
- Restore Default Balance writes the shipped defaults back to the JSON, and
  Reload Balance JSON reapplies manual file edits without restarting the game.
- Standardized all overflow bands to exact 2,520-HP intervals:
  2,520, 5,040, 7,560, 10,080, 12,600, 15,120, 17,640, and 20,160 HP.
- Updated the Safe Total Cap to 20,160 HP.
- Marked 20,160 HP as the current tested health and overlay-rendering ceiling
  for Vitality clamp experiments.

## Alpha 0.2.0 — Build 49.78 — Native preview duplicate-start repair

- Fixed the second preview path that wrote projected HP into `CurrHitPoint`.
- Native preview now always starts at actual current HP and advances only by
  `HealValue`.
- Preserved every unrelated current subsystem.

## Alpha 0.2.0 — Build 49.77a — Syntax hotfix

- Fixed the malformed `restore_stack` declaration in `health/core.lua`.
- No behavior or unrelated systems were changed.

## Alpha 0.2.0 — Build 49.77 — Native heal-preview start fix

- Restored scoped Intelligence preview inputs.
- Kept `CurrHitPoint` at actual current HP so the preview starts in the
  correct place.
- Applied only the effective clamped heal to `HealValue`.
- Restored all native fields immediately after `preview()` returns.
- Preserved every unrelated current subsystem.

## Alpha 0.2.0 — Build 49.76 — Ring background defaults

- Set the global overflow background alpha default to 100.
- Set every ring-style background alpha default to 100.
- Moved the automatic background threshold to 2520 HP.
- Left the Build 49.75 heal-preview transplant untouched.

## Alpha 0.2.0 — Build 49.75 — Working heal-preview transplant

- Transplanted only the supplied working heal-preview reader, updater state,
  and overlay geometry into the current build.
- Removed the later preview-parameter rewrite helper.
- Preserved every unrelated current subsystem.

## Alpha 0.2.0 — Build 49.74 — Simplified heal preview

- Reduced preview calculation to current HP plus one effective heal.
- Left the native `HealPreviewParam` completely untouched.
- Native preview owns projected HP through 2520.
- Overflow preview draws only projected HP above 2520.
- Preserved all unrelated gameplay systems.


## Alpha 0.2.0 — Build 49.73 — Heal-preview regression rollback

- Restored the complete pre-49.70 heal-preview implementation.
- Removed the 49.70 clamp, 49.71 destination-band suppression, and 49.72
  read-only preview experiment.
- Applied only the requested 2520-HP visual ring thresholds.
- Preserved current enemy-death, inventory, save/profile, and RPG systems.

## Alpha 0.2.0 — Build 49.72 — Native-safe heal preview

- Stopped rewriting Capcom's live `HealPreviewParam.HealValue`.
- Removed the blank gap that displaced the native heal preview.
- Moved all visual ring thresholds to 2520 HP per band.
- Clipped overflow heal previews to the active band so the native portion
  cannot be duplicated on an overflow ring.
- Actual healing and unrelated gameplay systems were not modified.

## Alpha 0.2.0 — Build 49.71 — Exclusive heal-preview bands

- Stopped heal previews from appearing simultaneously on the native HP ring
  and an overflow ring.
- Preview ownership is now selected by projected HP:
  native at or below 2500, overflow above 2500.
- Cached the full effective heal before suppressing native `HealValue`, so
  overlay math and actual healing remain unchanged.
- Enemy death, save/profile, inventory, and stat systems were not modified.

## Alpha 0.2.0 — Build 49.70 — Heal-preview overflow clamp

- Clamped the inventory heal preview to the amount of HP actually missing.
- Prevented excess healing from wrapping visually onto the next overflow bar.
- Kept the real heal amount and Intelligence scaling unchanged.
- Preserved the Build 49.69 enemy-death repair.

## Alpha 0.2.0 — Build 49.69 — Enemy death callback repair

- Replaced the single guessed `EnemyManager.notifyDead` hook with hooks for
  every exposed overload.
- Expanded enemy-context argument discovery and Boolean decoding.
- Added protected processed-death fallbacks for both `CharacterContext` and
  `EnemyBaseContext`.
- All death pre-hooks explicitly call the original game method.
- Save/profile, inventory, HUD, health, and stat systems were not modified.

## Alpha 0.2.0 — Build 49.68 — Save-menu profile preservation

- Fixed native save/typewriter screens being mistaken for a title-screen gap.
- Player absence now arms New Game detection without clearing the RPG slot.
- A completed native save disarms the pending gap, including completion events
  that do not expose a SlotId.
- Genuine New Game isolation remains tied to the first autosave of a changed
  player identity.
- Items-only and equipped-charms visibility fixes are unchanged.

## Alpha 0.2.0 — Build 49.67 — Equipped-charms Items whitelist

- Fixed progression disappearing on the Items screen when equipped charms
  left the CaseCustom heartbeat active.
- The validated Items signature now takes precedence over the Charms blocker.
- Charms remain blocked on every non-Items screen and during unknown states.
- RPG save/load and stat application were not modified.

## Alpha 0.2.0 — Build 49.66 — Items-only progression gate

- Added a separate read-only `item_window_menu_state.lua` module.
- Resolves `ItemWindowGuiControlBehavior` through the stable
  `HighwayGuiManager` AppSingleton.
- Whitelists only the validated stable Items signature:
  `CurrStep=8`, `CurrRootState=17`, `CurrFocusTabElement=1`.
- Crafting (`2`), Keys & Treasures (`3`), Files (`4`), Map (`0`),
  unknown values, and transitions hide progression immediately.
- RPG save/load and stat application were not modified.

## Alpha 0.2.0 — Build 49.65 — Visible Item Window probe

- Added an `Item Window State Probe` tree to the visible REFramework UI.
- Shows `CurrRootState`, `CurrStateType`, `CurrStartType`, `CurrStep`, and
  `BehaviorHub.CurrStep`.
- Also shows probe calls, failures, and current status.
- Removed the need to locate a REFramework log file.
- Probe data remains diagnostic-only and does not control progression.

## Alpha 0.2.0 — Build 49.64 — Non-controlling Item Window probe

- Removed the ineffective Build 49.63 root-state whitelist.
- Restored the exact Build 49.59 Map-only progression visibility behavior.
- Added a hook-free diagnostic poll for
  `ItemWindowGuiControlBehavior`.
- Logs `CurrRootState`, `CurrStateType`, `CurrStartType`, `CurrStep`, and
  `BehaviorHub.CurrStep` whenever their combined signature changes.
- Diagnostic values do not hide or show progression.

## Alpha 0.2.0 — Build 49.63 — Numeric Item Window root-state whitelist

- Replaced runtime state-class matching with
  `ItemWindowGuiControlBehavior.CurrRootState`.
- Dynamically resolves allowed `chainsaw.ItemWindowGuiState.AttacheCase*`
  numeric constants from the enum definition.
- Allows normal Items and item-management states while excluding Craft,
  Files, Map, Keys & Treasures, and exit states.
- Uses no additional native hooks.
- If enum resolution or live root-state reading fails, the new gate bypasses
  rather than hiding the actual Items screen.

## Alpha 0.2.0 — Build 49.62 — Items whitelist rollback

- Removed the Build 49.61 positive Items-state whitelist.
- Runtime testing showed that `_CurrState` runtime type names did not resolve
  to the expected `ItemWindowGuiState_AttacheCase*` family.
- Restored the exact Build 49.60 `inventory_progression.lua`.
- The validated safe Map poll remains enabled.

## Alpha 0.2.0 — Build 49.61 — Items-only progression whitelist

- Replaced menu-by-menu blocking with a positive Items-state requirement.
- Allows live `ItemWindowGuiState_AttacheCase*` states.
- Excludes `AttacheCaseCraft*` and `AttacheCaseExit`.
- Map, Files, Crafting, Keys & Treasures, and unknown states hide progression.
- Uses no additional native hooks.

## Alpha 0.2.0 — Build 49.60 — Live Item Window state polling

- Added a hook-free Keys & Treasures test using
  `ItemWindowGuiControlBehavior._CurrState`.
- Classifies the live state object's runtime type name.
- Blocks only `ItemWindowGuiState_KeyTreasure*`, `..._KeyItem*`, and
  `..._Treasure*` states.
- Retains the validated safe Map poll and leaves rendering untouched.

## Alpha 0.2.0 — Build 49.59 — Keys & Treasures polling rollback

- Removed the Build 49.58 managed-object scan for
  `KeyTreasureInventoryGuiBehavior`.
- Runtime testing showed that the object and its nonzero `CurrStep` persist
  after leaving Keys & Treasures, so it suppressed progression on Items,
  Crafting, and Files.
- Restored the exact validated Build 49.57 Map-only progression module.
- The safe throttled `MapManager.isMapGuiOpen()` poll remains enabled.
- No renderer, fade, cursor, mouse, profile, or gameplay logic changed.

## Alpha 0.2.0 — Build 49.58 — Safe Keys & Treasures polling blocker

- Added only the Keys & Treasures blocker on top of the validated Map-only
  baseline.
- Uses no `sdk.hook` calls for `KeyTreasureInventoryGuiBehavior`.
- Scans managed treasure GUI objects only while the attaché case is open.
- Limits scans to once every 0.30 seconds.
- Reads only `CurrStep`; a discovered nonzero step blocks progression.
- Leaves rendering, fading, cursor, mouse, and attaché-case opening unchanged.

## Alpha 0.2.0 — Build 49.57 — Files polling rollback

- Removed the Build 49.56 `FileManager.CurrPhase` blocker.
- Runtime testing showed that `CurrPhase` remains nonzero outside the Files
  screen and therefore suppressed progression on the Items screen.
- Restored the exact validated Build 49.55 Map-only progression module.
- The safe throttled `MapManager.isMapGuiOpen()` poll remains enabled.
- No renderer, fade, cursor, mouse, profile, or gameplay logic changed.

## Alpha 0.2.0 — Build 49.56 — Safe Files polling blocker

- Added only the Files blocker on top of the validated safe Map poll.
- Uses no `sdk.hook` calls for `FileManager`.
- Polls `FileManager.get_CurrPhase()` at most once every 0.15 seconds.
- Any nonzero phase blocks progression; zero leaves normal visibility intact.
- Wraps singleton lookup and phase access in `pcall`.
- Does not modify the renderer, fade, cursor, mouse, or attaché-case open path.

## Alpha 0.2.0 — Build 49.55 — Safe Map polling blocker

- Reintroduced only the Map blocker.
- Uses no `sdk.hook` calls for `MapManager`.
- Polls `MapManager.isMapGuiOpen()` at most once every 0.15 seconds.
- Wraps singleton lookup and method access in `pcall`.
- A failed poll clears the cached manager and leaves progression behavior
  unchanged until a later retry.
- Does not modify the renderer, fade, cursor, mouse, or attaché-case open path.

## Alpha 0.2.0 — Build 49.54 — Emergency menu-blocker rollback

- Removed the experimental `KeyTreasureInventoryGuiBehavior` blocker that
  began the launch-crash chain.
- Removed the subsequent `MapManager`, `FileManager`, and
  `CraftWindowGuiBehavior` blockers.
- Restored the exact known-working Build 49.49
  `inventory_progression.lua`.
- Preserved the newer save/profile isolation fixes and all unrelated systems.
- Menu blockers will need to be reintroduced one at a time only after a
  non-hooking runtime probe confirms which lifecycle methods are safe.

## Alpha 0.2.0 — Build 49.53 — Native Crafting-screen blocker

- Added a separate blocker for `chainsaw.CraftWindowGuiBehavior`.
- Setup/open callbacks immediately hide progression.
- `changeStep(...)` synchronizes the native Crafting step.
- `draw()` keeps suppression active while the Crafting GUI renders.
- Deactivate, finalize, clear, and destroy callbacks release the blocker.
- Leaves the restored renderer, fade, cursor, mouse, and attaché-case open path
  unchanged.

## Alpha 0.2.0 — Build 49.52 — Native Files-screen blocker

- Added a separate blocker for `chainsaw.FileManager`.
- `changePhase(...)` applies the incoming Files phase immediately.
- A nonzero `CurrPhase` blocks progression; phase zero releases it.
- `onLateUpdate()` keeps the blocker synchronized with the live phase.
- `onDestroy()` clears the blocker.
- Leaves the restored renderer, fade, cursor, mouse, and attaché-case open path
  unchanged.

## Alpha 0.2.0 — Build 49.51 — Native Map-screen blocker

- Added a separate blocker for `chainsaw.MapManager`.
- `onMapStartOpen()` immediately hides progression.
- `isMapGuiOpen()` keeps blocker state synchronized with the native map GUI.
- `onMapClosed()` releases the blocker.
- Leaves the restored progression renderer, fade, cursor, mouse, and open path
  unchanged.

## Alpha 0.2.0 — Build 49.50 — Native Treasures-screen blocker

- Added a separate blocker for `chainsaw.KeyTreasureInventoryGuiBehavior`.
- Hooks setup/open callbacks for immediate suppression.
- Uses `lateUpdate`/`draw` as a heartbeat while Treasures remains visible.
- Releases through closing, deactivate, finalize, clear, and destroy callbacks.
- Leaves the restored Build 49.47 drawing, fading, cursor, and mouse behavior
  unchanged.

## Alpha 0.2.0 — Build 49.49 — Progression visual restoration

- Reverted the Build 49.48 Items-tab gating experiment after it disrupted the
  working progression visuals.
- Restored the complete Build 49.47 `inventory_progression.lua`.
- Restores the prior draw, fade, cursor, mouse, and open-state behavior.
- Leaves Build 49.47 character-save binding and all unrelated systems intact.
- Tab-specific blocking will be revisited through separate native tab lifecycle
  hooks rather than modifying the renderer/open path.

## Alpha 0.2.0 — Build 49.48 — Items-tab-only progression visibility

- Fixed the progression panel appearing on Map, Treasures, Crafting, Files,
  and other attaché-case tabs.
- Removed generic setup/update callbacks as Items-tab classifiers.
- Learns the Items inventory enum only from the concrete item-grid control.
- Requires the live `CurrActiveInventory` value to match that learned value.
- Removed mouse-movement callbacks as a visibility source.
- Unknown or unreadable tab values fail closed and keep progression hidden.

## Alpha 0.2.0 — Build 49.47 — Character-save ownership binding

- Fixed stale profile data still reaching New Game when title-screen player
  references remained alive.
- Tracks the player instance that owns the currently selected RPG profile.
- A replacement player with a newer native load serial is handled as
  Continue/Load Game.
- A replacement player without a native load transaction is handled as a new
  campaign character.
- Resets the profile and all application caches before selecting or queuing the
  new character's first autosave.
- Binds and enables the fresh default profile only after autosave initialization.

## Alpha 0.2.0 — Build 49.46 — Campaign initialization gate

- Resets the previous RPG profile as soon as the title-screen gap is confirmed.
- Suspends health/stat application before a new campaign player is created.
- Clears active slot, queued save/load, movement, health, and tracking state.
- New Game remains on defaults until its first native autosave request.
- Continue and Load Game resume only after their RPG profile has actually been
  selected and loaded.

## Alpha 0.2.0 — Build 49.45 — New-campaign RPG isolation

- Fixed New Game inheriting the previously active campaign's RPG profile after
  quitting to the title screen.
- Tracks an extended no-player/title gap.
- Continue and Load Game remain protected by their native load-request serial.
- A fresh player appearing after the title gap without a load request is
  classified as a new campaign.
- Clears active slot identity and resets the RPG profile before the first
  autosave establishes the new campaign.
- Clears queued load, health, stat-application, and movement transition state.

## Alpha 0.2.0 — Build 49.44 — Movement load-transition normalization

- Runtime diagnostics showed a previous `1.0000 × 1.200 = 1.2000` result
  returning as the next save's raw `PlayerBodyUpdater` value.
- Added a bounded transition-normalization latch.
- Remembers the previous base, applied result, and multiplier during native
  load.
- If the loaded player returns the previous applied result, removes the old
  multiplier before applying the new profile.
- Automatically releases when a genuinely fresh native movement value appears.
- Avoids hardcoding `1.0000` and preserves legitimate engine modifiers.

## Alpha 0.2.0 — Build 49.43 — Per-save movement isolation

- Fixed Agility movement speed carrying into another native save.
- Restores all tracked fallback movement fields to their captured baselines
  when native loading completes.
- Clears stale player context, movement userdata, body updater, field cache,
  multiplier cache, and graph-capture state.
- Waits for the loaded player instance to be recaptured before applying the
  selected RPG profile.
- Adds movement load-reset and restored-value diagnostics.

## Alpha 0.2.0 — Build 49.42 — Movement multiplier forward declaration

- Fixed `update_movement_fields()` resolving `movement_multiplier` as a nil
  global while loading a save.
- Moved the multiplier local declarations before movement userdata callbacks.
- Left all multiplier implementations and applied movement behavior unchanged.

## Alpha 0.2.0 — Build 49.41 — Persistent storage blocker

- Fixed the visibility poll replacing verified storage state with a short
  `storage_blocker_until` heartbeat.
- Added `storage_session_latched`, owned by verified storage lifecycle.
- Latches on `ArmouryGuiState_ArmouryEnter` and
  `ArmouryGuiBehavior.onStartOpen`.
- Releases on verified storage close or return to the inventory branch.
- Prevents transient `AttacheCaseManager` close edges and item-box heartbeat
  expiry from reopening the progression overlay during storage.

## Alpha 0.2.0 — Build 49.40 — Inventory suppression forward declaration

- Fixed `suppress_progression_immediately` resolving as a nil global when the
  Charms blocker callback fired.
- Added a local forward declaration before early visibility hooks.
- Converted the later helper declaration into an assignment to that local.
- No blocker timing, screen classification, or gameplay behavior changed.

## Alpha 0.2.0 — Build 49.39 — Documentation and deprecation audit

- Reviewed all 69 Lua scripts and 20 Markdown files.
- Added a maintenance classification header to every Lua script.
- Documented module role and active/deprecated/diagnostic status.
- Marked empty engine namespaces and the render-ring adapter as deprecated
  compatibility shims without removing their import paths.
- Marked legacy movement userdata, player-graph, reload-lerp, and reload
  behavior-tree paths as retained fallbacks or diagnostic-only code.
- Documented authoritative runtime paths:
  - walk/run: `PlayerBodyUpdater.getNextMotionSpeed()`,
  - reload: `chainsaw.Gun.get_ReloadSpeedRate()`,
  - saves: native slot `0` autosave and `1..20` manual,
  - progression visibility: verified inventory state with explicit blockers.
- Expanded subsystem README files and standardized documentation status and
  compatibility policy sections.
- No gameplay functionality was intentionally removed or changed.

## Documentation status

- **Reviewed for:** Build 49.39
- **Scope:** Historical release record
- **Status:** append-only; newest entries first
- **Compatibility rule:** Deprecated modules, calls, and probes remain documented and callable until a dedicated removal release.
- **Terminology:** “Deprecated” means supported legacy compatibility; “diagnostic-only” means it must not be treated as an authoritative gameplay path.


## Alpha 0.2.0 — Build 49.38 — Derived-stat display cleanup

- Changed the Agility visual from `Reload Speed: xN` to the actual
  `Reload Time: -N%` duration reduction.
- Duration reduction uses `1 - (1 / reload speed multiplier)`.
- Added the missing `+` before Critical Chance.
- No derived-stat formulas or gameplay hooks were changed.

## Alpha 0.2.0 — Build 49.37 — Direct-only reload speed

- Diagnostics showed behavior-tree motion layers could be modified before the
  direct Gun getter became active.
- Removed all behavior-tree reload rate and motion-layer writes.
- Behavior-tree hooks now collect lifecycle diagnostics only.
- `Gun.get_ReloadSpeedRate()` is the sole Reload Speed application path.
- The first direct Gun callback restores any legacy tracked mutations.
- Added cleanup-run and restored-value diagnostics.

## Alpha 0.2.0 — Build 49.36 — Single reload-speed path

- Runtime diagnostics confirmed both the direct Gun getter and reload-local
  motion fallback were applying the Agility multiplier.
- Makes `Gun.get_ReloadSpeedRate()` the authoritative application path.
- Suppresses behavior-tree rate and motion-layer mutation whenever the direct
  getter is active.
- Keeps behavior-tree hooks for diagnostics only.
- Prevents double application of Reload Speed.

## Alpha 0.2.0 — Build 49.35 — Direct Gun reload-speed application

- Identified the live equipped-weapon getter:
  `chainsaw.Gun.get_ReloadSpeedRate()`.
- Applies Agility Reload Speed directly to its returned scalar.
- Avoids permanent edits to:
  - `WeaponStructureParam`,
  - weapon customization userdata,
  - behavior-tree animation layers.
- Separates the unused legacy `ReloadLerpTime` diagnostics from the active Gun
  reload-rate channel.
- Adds direct Gun getter call/base/applied diagnostics.

## Alpha 0.2.0 — Build 49.34 — Reload-local motion application

- Runtime capture confirmed the active object is base
  `ApplyReloadSpeedAddBlend`, which has no `_McReloadSpeedRate`.
- Uses that action's own `_Motion` object as the fallback application target.
- Applies Agility Reload Speed only to local reload motion layers.
- Preserves and restores native layer speeds on action end.
- Leaves shared `PlayerEquipment.Motion` untouched.

## Alpha 0.2.0 — Build 49.33 — Reload action argument capture

- Diagnostics proved reload lifecycle callbacks fired while `args[2]` did not
  resolve to the reload action object.
- Added bounded hook-argument scanning across indices 1–8.
- Selects the managed runtime type containing `ApplyReloadSpeed`.
- Rejects unrelated managed arguments before reading `_McReloadSpeedRate`.
- Added captured index, runtime type, and argument-scan diagnostics.

## Alpha 0.2.0 — Build 49.32 — Reload-rate persistence

- Applies `_McReloadSpeedRate` before native `start()` and `update()`.
- Reapplies the rate after native execution to prevent internal overwrites.
- Reads the field back after the original callback.
- Adds diagnostics for:
  - pre/post application calls,
  - post-original readback,
  - write confirmation,
  - overwrite count.
- Restores the native rate after `end()`.

## Alpha 0.2.0 — Build 49.31 — Reload duration diagnostics

- Added explicit native and applied reload-rate diagnostics.
- Added normalized duration calculations:
  - native duration scale = `1 / native rate`,
  - applied duration scale = `1 / applied rate`,
  - applied duration as a percentage of native,
  - duration reduction percentage.
- Marks duration values as normalized estimates because the reload behavior
  action does not expose an absolute animation clip/frame duration.

## Alpha 0.2.0 — Build 49.30 — Reload base-dispatch correction

- Runtime diagnostics showed derived MC `start()` and `update()` calls remained
  zero while inherited `end()` fired repeatedly.
- Added hooks for:
  - `WeaponBehaviorTreeAction_ApplyReloadSpeed`
  - `WeaponBehaviorTreeAction_ApplyReloadSpeedAddBlend`
- Retained derived classes for runtime field access.
- Deduplicates inherited method handles before hooking.
- Applies `_McReloadSpeedRate` from the actual derived runtime object.
- Prevents duplicate inherited `end()` hooks.

## Alpha 0.2.0 — Build 49.29 — Reload action-rate application

- Identified the player reload-specific behavior-tree actions:
  - `WeaponBehaviorTreeAction_McApplyReloadSpeed`
  - `WeaponBehaviorTreeAction_McApplyReloadSpeedAddBlend`
- Applies Agility Reload Speed to `_McReloadSpeedRate`.
- Preserves native rates per action instance.
- Reapplies during `update()` and restores native values during `end()`.
- Leaves shared `via.motion.Motion` objects unchanged to prevent locomotion or
  unrelated animation leakage.

## Alpha 0.2.0 — Build 49.28 — Fire-rate and reload-speed progression

- Added Reload Speed as an Agility-derived stat.
- Reload timing now uses the Agility reload-speed multiplier.
- Fire Rate and Reload Speed use the same progression:
  - no invested points: `x1.000`,
  - first invested point: `+0.002`,
  - each later point: `+0.001`,
  - maximum: `x1.250`.
- Corrected Dexterity 250 from `x1.249` to exactly `x1.250`.
- Added Reload Speed to the inventory panel and developer diagnostics.

## Alpha 0.2.0 — Build 49.27 — Walk/run-only Agility gate

- Restricted `PlayerBodyUpdater.getNextMotionSpeed()` multiplication to active
  walk/run movement.
- Uses live `MoveDir`, `TargetMoveDir`, and `ObjectiveMoveDir` values.
- Idle and zero-input motion states return the original native speed.
- Added gate state, reason, and direction diagnostics.

## Alpha 0.2.0 — Build 49.26 — Live PlayerBodyUpdater movement speed

- Identified `PlayerBodyUpdater` as the live locomotion owner.
- Added `updateMotionSpeed()` capture diagnostics.
- Applies Agility to `getNextMotionSpeed()` return values.
- Leaves `setMotionSpeedFromAction(float)` diagnostic-only to avoid applying
  the multiplier twice.
- Retains older userdata capture paths as fallback diagnostics.

## Alpha 0.2.0 — Build 49.25 — Live movement accessor capture

- Runtime diagnostics confirmed `sdk.get_managed_objects` is unavailable.
- Removed the repeated unavailable managed-object scan.
- Added narrow capture hooks for movement-related
  `PlayerCommonParamUserData` accessors.
- Any accessor call captures the live userdata from the callback's `this`
  pointer.
- Retained `onLoad` for future loads and player-graph discovery as fallback.

## Alpha 0.2.0 — Build 49.24 — Live movement userdata recovery

- Confirmed `onLoad` installed after the current userdata had already loaded.
- Added exact-type recovery using `sdk.get_managed_objects`.
- Scans once per second until a live `PlayerCommonParamUserData` is captured.
- Recovery runs even while Action Speed's player pointer remains nil.
- Retains `onLoad` for future loads and player-graph search as final fallback.

## Alpha 0.2.0 — Build 49.23 — Direct movement userdata capture

- Identified `PlayerCommonParamUserData.onLoad()` as the direct lifecycle for
  the userdata object containing all walk/run speed fields.
- Added a narrow hook that captures the actual userdata instance.
- Preserves native movement baselines before applying Agility.
- Retains bounded player-graph discovery only as a fallback.
- Added direct hook installation and callback diagnostics.

## Alpha 0.2.0 — Build 49.22 — Action Speed player-context recovery

- Diagnosed movement graph scans remaining at zero because Action Speed's player
  pointer stayed nil.
- Added a narrow hook for
  `PlayerCharacterContext.updateContextDataOnUpdatePhase`.
- Action Speed now maintains its own live player-context capture.
- Movement graph scanning falls back to this captured object.
- Added player capture installation, calls, and status diagnostics.

## Alpha 0.2.0 — Build 49.21 — Agility player-graph capture

- Confirmed `PlayerCommonParamUserData` is not exposed as a managed singleton.
- Replaced singleton capture with a bounded search from the live player context.
- Searches exact managed runtime type with:
  - depth limit 5,
  - object limit 600,
  - one scan per second.
- Captured movement userdata continues using preserved native walk/run baselines.
- Added graph scan and inspected-object diagnostics.

## Alpha 0.2.0 — Build 49.20 — Agility live userdata capture

- Confirmed all movement getter hooks were installed but remained at zero calls.
- Removed the obsolete `critical.object` fallback, which cannot work with the
  current critical-hit module.
- Added direct managed-singleton capture for
  `chainsaw.PlayerCommonParamUserData`.
- Uses native getter multiplication when getters run.
- Otherwise applies Agility directly to preserved-baseline walk/run fields.
- Added detailed capture and application-mode diagnostics.

## Alpha 0.2.0 — Build 49.19 — Agility/Dexterity scope repair

- Fixed `fire_rate_multiplier is not callable` caused by Lua local-function
  declaration order.
- Forward-declared movement, fire-rate, and channel multiplier helpers.
- Fixed the same latent scope problem in the Agility movement updater.
- Native movement getter diagnostics now show:
  - applied multiplier,
  - last base value,
  - last returned value,
  - whether any walk/run getter has fired.

## Alpha 0.2.0 — Build 49.18 — Menu visibility edge fix

- Fixed one-frame progression flashes on typewriter, Save Game, and Charms
  entry by clearing current fade alpha immediately.
- Kept progression hidden through the typewriter close transition.
- Added direct `ArmouryGuiBehavior.onStartOpen/onStartClose` storage ownership.
- Storage now suppresses progression on entry and throughout its close
  transition.

## Alpha 0.2.0 — Build 49.17 — Direct typewriter lifecycle and stat repair

- Added direct `ArmourySelectGuiBehavior.onStartOpen/onStartClose` ownership.
- Captures the typewriter selector's `CurrStep`.
- Fixed a native multiplier routing bug where only the knife channel received
  Dexterity action speed.
- Melee, reload timing, and weapon-transition timing now receive Dexterity.
- Agility now applies through native movement getters.
- Removed duplicate movement backing-field multiplication.
- Fire-rate target remains separately reported while shared weapon motion is
  kept read-only to avoid locomotion leakage.

## Alpha 0.2.0 — Build 49.16 — Armoury hub child-behavior probe

- Confirmed `ArmouryGuiBehaviorHub.CurrStep` only contains `Setup` and `Move`.
- Added direct polling of the hub's child behavior getters.
- Records existence, managed type, and `get_Valid` when available for:
  - typewriter selection,
  - storage,
  - Save Game,
  - case/customization.
- No visibility behavior changed.

## Alpha 0.2.0 — Build 49.15 — Typewriter onStart ownership rollback

- Runtime testing showed behavior `onStart` does not correspond to a visible
  typewriter transition.
- Removed `onStart` from visibility ownership.
- `onStart` remains diagnostic-only.
- `onEnd` plus current `AttacheCaseManager` busy state remains the authoritative
  open/closed resolution.

## Alpha 0.2.0 — Build 49.14 — Typewriter transition ownership

- Renamed `onStart` diagnostics from verified entry to transition start.
- Added `typewriter_transition_pending` to the actual visibility blocker.
- Progression remains suppressed between `onStart` and `onEnd`.
- `onEnd` plus current `AttacheCaseManager` busy state remains authoritative
  for resolving open versus closed.

## Alpha 0.2.0 — Build 49.13 — Bidirectional typewriter transition resolution

- Fixed the typewriter screen classification remaining `typewriter` after the
  menu closed.
- `onStart` now marks a transition pending.
- `onEnd` resolves the direction using current `AttacheCaseManager` busy state:
  - busy = menu opened,
  - not busy = menu closed.
- Updated screen class/source and blocker state from the resolved direction.

## Alpha 0.2.0 — Build 49.12 — Typewriter diagnostic status cleanup

- Fixed the misleading `No known typewriter parent-menu type resolved` status.
- The working behavior-tree lifecycle hook now owns the primary Typewriter Hook
  Status.
- The obsolete guessed parent-menu resolver is shown separately as legacy
  diagnostic information.
- Typewriter blocker behavior is unchanged.

## Alpha 0.2.0 — Build 49.11 — Latched typewriter behavior blocker

- Runtime diagnostics showed `onEnd` fires while the typewriter menu is still
  open.
- `onStart` now latches the typewriter blocker.
- `onEnd` records transition completion but does not release the blocker.
- The blocker releases only when `AttacheCaseManager` reports the workflow
  closed.
- Save Game transitions preserve the parent typewriter latch.

## Alpha 0.2.0 — Build 49.10 — Verified typewriter behavior ownership

- Runtime diagnostics showed repeated, balanced typewriter behavior calls:
  - `onStart` when entering,
  - `onEnd` when leaving.
- Promoted the behavior-tree lifecycle to authoritative typewriter ownership.
- Removed `ArmouryGuiState_Close.onInit` from visibility control.
- `ArmouryGuiState_Close` remains diagnostic-only.
- Storage remains owned by exact `ArmouryGuiState_ArmouryEnter`.

## Alpha 0.2.0 — Build 49.09 — Verified typewriter onInit entry

- Refined the typewriter discriminator from the broad
  `ArmouryGuiState_Close` class to the exact
  `ArmouryGuiState_Close.onInit` lifecycle event.
- Other `Close` callbacks no longer latch the typewriter blocker.
- Storage remains owned by exact `ArmouryGuiState_ArmouryEnter`.
- Existing Save Game, Charms, and inventory restoration logic is unchanged.

## Alpha 0.2.0 — Build 49.08 — Verified state counter repair

- Fixed a crash caused by incrementing the nonexistent
  `storage_blocker_open_calls` field.
- Uses the existing initialized `storage_open_calls` counter.
- Storage and typewriter counters now increment only when their blocker changes
  from inactive to active.
- State classification and visibility ownership remain unchanged.

## Alpha 0.2.0 — Build 49.07 — Verified Armoury state blockers

- Narrowed typewriter blocking to exact
  `chainsaw.gui.armoury.ArmouryGuiState_Close`.
- Narrowed storage blocking to exact
  `chainsaw.gui.armoury.ArmouryGuiState_ArmouryEnter`.
- Removed broad `Armoury*` and `Select*` ownership.
- Save Game preserves the parent typewriter latch.
- `AttacheCase*` restores normal inventory.
- `CaseCustom*` remains owned by the verified Charms blocker.

## Alpha 0.2.0 — Build 49.06 — Armoury state-owned visibility

- Promoted the verified Armoury GUI state machine from diagnostics to
  visibility ownership.
- `ArmouryGuiState_Armoury*` blocks storage.
- `ArmouryGuiState_Select*`, `SaveLoadExit`, and the observed parent `Close`
  transition block the typewriter parent.
- `ArmouryGuiState_AttacheCase*` restores normal inventory visibility.
- `CaseCustom*` continues using the verified Charms blocker.
- Existing Save Game blocking remains authoritative.

## Alpha 0.2.0 — Build 49.05 — Armoury GUI state probe

- Identified `ArmouryGuiBehaviorHub` as the shared owner of:
  - typewriter selection,
  - Save Game,
  - storage,
  - case customization.
- Added diagnostic hooks for `ArmouryGuiStateBase` lifecycle and transitions.
- Captures concrete state runtime type, next state enum, and hub step.
- Added a reset button for clean per-screen snapshots.
- No visibility behavior changed.

## Alpha 0.2.0 — Build 49.04 — Typewriter behavior-state blocker

- Confirmed both `GmTypeWriter.initInteractTrigger` and GmFlag hooks remain at
  zero during typewriter use.
- Added hooks for
  `PlayerBehaviorTreeAction_MFSM_SetTypeWriterNoInterpolation`.
- `onStart` enables the typewriter blocker.
- `onEnd` releases the blocker.
- Storage remains unchanged.

## Alpha 0.2.0 — Build 49.03 — Runtime-filtered GmTypeWriter flag hook

- Confirmed `initInteractTrigger` installs but does not fire during menu use.
- Added inherited `GmBase.setGmFlag` and `onChangeGmFlag` hooks.
- Runtime object type must be exactly `chainsaw.GmTypeWriter`.
- `true` enables the blocker; `false` releases it.
- Storage remains unchanged.

## Alpha 0.2.0 — Build 49.02 — Direct GmTypeWriter blocker

- ItemBox callback probes remained zero during typewriter use.
- Runtime class inspection identified `chainsaw.GmTypeWriter`.
- Added direct hooks for `initInteractTrigger`.
- The callback latches typewriter progression blocking.
- The latch clears only when the overall attaché workflow closes.
- Storage remains unchanged for a separate direct-class pass.

## Alpha 0.2.0 — Build 49.01 — ItemBox probe refinement

- Confirmed `openItemBox(ContextID)` runs continuously during gameplay and
  pauses while menus are open.
- Excluded it from menu lifecycle totals and last-method reporting.
- Retained it as a separate ambient gameplay counter.
- Typewriter/storage comparison now focuses on the actual callback methods.

## Alpha 0.2.0 — Build 49.00 — GmItemBox method probe

- Kept the verified Charms blocker unchanged.
- Added diagnostic-only counters for each shared ItemBox lifecycle method.
- Added a reset button for clean typewriter and storage comparisons.
- No typewriter/storage visibility behavior changed.

## Alpha 0.2.0 — Build 48.99 — Verified Charms blocker

- Runtime method comparison showed `lateUpdateOnActive` only on Charms.
- Added a dedicated heartbeat blocker from that method.
- Charms no longer depends on item hover to hide progression.
- `updateItemIcon` remains diagnostic-only.
- Existing inventory and Save Game behavior remains unchanged.

## Alpha 0.2.0 — Build 48.98 — CaseCustomMenu method probe

- Added diagnostic-only method counters for
  `CaseCustomMenuGuiBehavior`.
- Tracks draw/update/lateUpdate/active/render/item/selection/step callbacks.
- Added a reset button for clean per-screen comparisons.
- No visibility behavior changed.

## Alpha 0.2.0 — Build 48.97 — GmBase user-context probe

- Added a fallback discriminator for `onOpenItemBox(GameObject user)` callbacks.
- Resolves the user's `chainsaw.GmBase` component.
- Captures:
  - `GmBase.get_ID()` ContextID,
  - `GmBase.get_Context()` managed type,
  - user GameObject managed type.
- No visibility behavior changes in this build.

## Alpha 0.2.0 — Build 48.96 — Visibility rollback and screen probes

- Rolled back the failed icon-grid visibility gate.
- Restored progression on the normal inventory screen.
- Removed Charms-hover control callbacks from visibility ownership, preventing
  hover-driven flicker.
- Strong heartbeat and ContextID systems remain diagnostic-only.
- Added probes for:
  - hovered target managed type,
  - selection inventory enum,
  - previous/current selection indices.
- Existing Save Game submenu blocking remains unchanged.

## Alpha 0.2.0 — Build 48.95 — Concrete icon-grid Items proof

- Fixed progression disappearing from the normal inventory after the strong
  heartbeat change.
- Fixed progression flickering on Charms only while hovering an item.
- Removed shared case draw, target, hover, and selection callbacks from strong
  Items proof.
- The real Items screen is now confirmed only by
  `CaseCustomMenuIconControl.lateUpdate`.
- Hooks every reflected `lateUpdate` overload and includes exact lookup
  fallbacks.
- Increased heartbeat tolerance to prevent frame-level flicker.

## Alpha 0.2.0 — Build 48.94 — Inventory guard scope repair

- Fixed `valid_inventory_value is not callable`.
- The helper was declared after `apply_attache_case_visibility`, causing the
  earlier function to resolve a nonexistent global.
- Moved the helper above the visibility code.
- Build 48.93 inventory sentinel behavior remains unchanged.

## Alpha 0.2.0 — Build 48.93 — Inventory-value sentinel guard

- Runtime evidence showed the Charms page reports active inventory `-1`.
- Fixed the Items learner accepting `-1` as the learned Items inventory.
- Negative inventory values are now treated as invalid/non-Items sentinels.
- Strong Items heartbeats require a valid nonnegative active inventory.
- Visibility also requires the live inventory value to match the learned Items
  value when available.

## Alpha 0.2.0 — Build 48.92 — GmItemBox ContextID probe

- Added a diagnostic-only hook for `openItemBox(chainsaw.ContextID)`.
- Captures the raw ContextID for inventory, typewriter, and storage.
- Added `recvGmParam(param_type, arg, user)` telemetry.
- No visibility behavior changes in this build.

## Alpha 0.2.0 — Build 48.91 — Strong Items-screen proof

- Progression now requires a recent inventory-specific heartbeat instead of
  treating every busy attaché workflow as the Items screen.
- Strong sources include case-grid icon updates, case draw, item updates, target
  updates, and inventory selection changes.
- Shared `GmItemBox` activity remains diagnostic-only.
- Added strong Items confirmation diagnostics.

## Alpha 0.2.0 — Build 48.90 — GmItemBox blocker rollback

- Confirmed `chainsaw.GmItemBox` is shared by the normal attaché-case inventory.
- Removed `GmItemBox` session state from the visibility blocker.
- Removed legacy storage heartbeat hooks that could also suppress inventory.
- Restored progression visibility on the normal Items screen.
- Retained all ItemBox open/close hooks as diagnostic-only telemetry.
- Save Game submenu blocking remains intact.

## Alpha 0.2.0 — Build 48.89 — Complete GmItemBox lifecycle coverage

- Used the user-provided Build 48.88 ZIP as the patch baseline.
- Fixed `install_itembox_session_hooks` stopping after one matching open method
  and one matching close method.
- Hooks every available:
  - `openItemBox`,
  - `onOpenItemBox`,
  - `onOpenItemBoxSub`,
  - matching close variants.
- Added exact-signature fallback passes for methods omitted from reflection.
- Added hook counts and last-fired method diagnostics.
- Existing Save Game submenu blocking is unchanged.

## Alpha 0.2.0 — Build 48.88 — Enemy history event-shape fix

- Fixed Recent Deaths displaying every field as `nil`.
- The enemy registry stores:
  - event metadata on the event wrapper,
  - captured enemy fields inside `event.snapshot`,
  - downstream reward data inside `event.reward`.
- The UI now reads the current event shape while retaining compatibility with
  older flattened entries.
- Missing metadata displays as `unknown`.

## Alpha 0.2.0 — Build 48.87 — Recent enemy death nil guard

- Fixed `ui/enemies.lua` crashing after a death when `segment_id` was `nil`.
- The Recent Deaths panel no longer concatenates unvalidated stage/segment
  values.
- Missing stage or segment metadata now displays as `unknown`.
- Incomplete death records remain visible for debugging instead of being
  discarded.

## Alpha 0.2.0 — Build 48.86 — Shared GmItemBox session blocker

- Parent typewriter class guesses did not resolve, and storage open counters
  remained zero.
- Added one permanent blocker for the shared `chainsaw.GmItemBox` session.
- Hook discovery now tries exact signatures and then reflected method names.
- Item-box open callbacks block progression for typewriter and storage.
- Item-box close callbacks release the shared blocker.
- Added hook-resolution and session open/close diagnostics.

## Alpha 0.2.0 — Build 48.85 — Typewriter parent-menu blocker

- Save Game submenu blocking remains unchanged and working.
- Added a separate permanent blocker for the parent typewriter menu.
- The parent blocker activates from setup, activation, draw, or open callbacks.
- It releases only from close, deactivate, or destroy callbacks.
- Storage blocking was intentionally left unchanged for the next isolated test.
- Added typewriter hook-resolution and open/close diagnostics.

## Alpha 0.2.0 — Build 48.84 — Permanent typewriter blocker

- Replaced the save/typewriter blocker grace timer with a permanent session
  latch.
- Save-menu `draw`, setup, and activation callbacks latch progression blocking.
- Native input, confirmation, and submenu transitions cannot release it.
- The latch clears only from explicit close, deactivate, or destroy lifecycle
  callbacks.
- Storage blocking remains independently managed.

## Alpha 0.2.0 — Build 48.83 — Sticky typewriter blocker

- Fixed the progression panel briefly reappearing after input in the native
  save/typewriter menu.
- `SaveLoadMenuGuiBehavior.draw` can pause during save confirmation and input
  processing without the menu actually closing.
- Increased the save-menu heartbeat grace from `0.20` to `2.50` seconds.
- Native save-menu draw calls continuously refresh the blocker latch.
- Added blocker-active and remaining-grace diagnostics.

## Alpha 0.2.0 — Build 48.82 — SaveDataManager request ownership

- Fixed both request hooks remaining uninstalled (`Installed Hooks: 3`).
- Fallback discovery for `enqueueSaveRequest` and `enqueueLoadRequest` now
  matches method name without relying on reflection parameter-array length.
- Fixed save completion reading fields from `SaveLoadMenuGuiManager` instead of
  the actual `share.SaveDataManager` singleton.
- Save completion now probes current request/process objects for `SlotId`.
- Added individual installation diagnostics for every save/load hook.

## Alpha 0.2.0 — Build 48.81 — Completed-save slot resolution

- Fixed native save completion skipping the RPG write when the completion event
  did not include a slot.
- Save completion now resolves slot identity in this order:
  1. captured `enqueueSaveRequest` SlotId,
  2. `SaveDataManager` completed-save fields,
  3. completion-event fallback.
- Added diagnostics for the completed save SlotId and its source.
- The RPG write is skipped only when every authoritative/fallback source is
  unavailable.

## Alpha 0.2.0 — Build 48.80 — Remove cyclic cursor hooks

- Confirmed menu callback values are cyclic navigation destinations:
  - autosave reports `01` when moving down and `20` when moving up,
  - manual slots report the neighboring row,
  - moving below `00` wraps to `20`.
- Removed 2 menu callback hook block(s) from slot synchronization.
- `capture_menu_slot` is now an intentional no-op.
- Only native save/load request and completion hooks may update transaction or
  active RPG slot state.
- Updated diagnostics to mark menu cursor hooks as disabled.

## Alpha 0.2.0 — Build 48.79 — Transaction-owned slot identity

- Fixed save-menu scrolling changing the pending RPG slot:
  - scrolling down from visible slot 09 could report slot 10,
  - scrolling up could report slot 08.
- `selectionChanged` and `updateScrollList` now update diagnostic cursor state
  only.
- Cursor callbacks can no longer modify:
  - `pending_slot`,
  - `active_slot`,
  - queued save/load profiles.
- `enqueueSaveRequest` exclusively owns save transaction identity.
- `enqueueLoadRequest` exclusively owns load transaction identity.
- Renamed diagnostics to distinguish cursor rows from real transaction slots.

## Alpha 0.2.0 — Build 48.78 — Single native slot convention

- Locked save/load synchronization to one direct native convention:
  - `SlotId 0` = autosave,
  - `SlotId 1..20` = manual saves `01..20`.
- Removed all conceptual support for offsets or alternate slot ordering.
- Save and load requests use the same normalizer.
- Diagnostics now separate native raw `SlotId` values from resolved RPG slots.

## Alpha 0.2.0 — Build 48.77 — Lua syntax repair

- Fixed module-load failure in `game_save_sync.lua`.
- Removed a stale load-offset code fragment left behind during the Build 48.76
  normalizer replacement.
- Removed the resulting unmatched `end` near line 190.
- Direct native SlotId mapping remains:
  - `0` = autosave,
  - `1..20` = manual slots.

## Alpha 0.2.0 — Build 48.76 — Direct native SlotId mapping

- Removed the incorrect operation-specific save/load offsets.
- Native `SlotId` is now interpreted directly:
  - `0` = autosave,
  - `1..20` = manual slots `01..20`.
- Fixed `SaveDataManager.enqueueSaveRequest` and `enqueueLoadRequest` hook
  discovery:
  - exact signature lookup remains first,
  - fallback lookup matches method name and two parameters.
- Request-captured native `SlotId` remains authoritative over completion-event
  fallback values.
- Added the expected hook count to diagnostics.

## Alpha 0.2.0 — Build 48.75 — Native load transaction latch

- Fixed later internal load requests replacing the selected profile:
  - autosave was eventually overwritten as manual slot 20,
  - visible manual slot 09 was eventually overwritten as slot 10.
- Save and load now have separate pending-slot state.
- The first valid `enqueueLoadRequest` row is locked until
  `onGameLoadCompleted`.
- Later requests in the same transaction are counted and ignored.
- Load completion consumes the dedicated locked slot directly.
- Added locked-load-slot and ignored-request diagnostics.

## Alpha 0.2.0 — Build 48.74 — Correct native load-row mapping

- Corrected the load mapping from runtime evidence:
  - native load raw `1` is autosave,
  - native load raw `10` is visible manual slot `09`.
- Native load rows `2..21` now map to manual slots `01..20`.
- Save request mapping was left unchanged.
- Load request status now displays both the raw row and resolved RPG slot.

## Alpha 0.2.0 — Build 48.73 — Operation-specific native slot mapping

- Runtime evidence confirmed separate native slot-number spaces:
  - saving visible slot 09 used request slot 7,
  - loading visible slot 09 used request slot 10.
- Added independent normalization:
  - save request: `displayed = raw + 2`,
  - load request: `displayed = raw - 1`.
- Hooked `share.SaveDataManager.enqueueLoadRequest` directly.
- Save/load completion now prefers the request-captured slot over completion
  event values.
- Added separate raw save-request and load-request diagnostics.

## Alpha 0.2.0 — Build 48.72 — Authoritative request-slot capture

- Runtime diagnostics showed:
  - save completion fired,
  - menu slot captures remained at zero,
  - completion exposed no usable slot,
  - the RPG write was skipped and the active slot remained autosave.
- `SaveDataManager.enqueueSaveRequest` now captures manual slot IDs as the
  authoritative pending and active RPG slot.
- Manual request capture updates `active_save.json` but does not write the
  profile early.
- The native completion callback still owns the delayed profile write.
- Completion falls back to the captured request slot when its event contains no
  slot information.

## Alpha 0.2.0 — Build 48.71 — Active-slot synchronization on save

- Fixed native saves writing while the in-memory RPG active slot remained stale.
- Manual menu selection now updates `sync.active_slot` immediately.
- Native save completion selects and persists the resolved slot before queueing
  the delayed RPG profile write.
- Successful deferred writes reassert `sync.active_slot` from
  `rpg.active_save_slot()`.
- Save status now includes the resulting active slot.

## Alpha 0.2.0 — Build 48.70 — Autosave/manual save isolation

- Fixed the new `SaveDataManager.enqueueSaveRequest` hook breaking manual
  profile saves.
- The request hook now handles native slot `0` only.
- Manual request IDs no longer modify `pending_slot` or `pending_raw_slot`.
- Manual saves remain controlled by the validated save-menu selection and
  completion-callback path.
- Autosave completions cannot consume a stale manual menu selection.

## Alpha 0.2.0 — Build 48.69 — Native SaveDataManager autosave request

- Replaced early autosave serialization with the actual native request path:
  `share.SaveDataManager.enqueueSaveRequest(System.Int32,
  share.SaveLoadRequestArgs)`.
- Native slot ID `0` is treated as autosave and queues a fresh live RPG profile
  write after 120 frames.
- `AutoSaveSetting.onHitAutoSave` is retained only as a diagnostic fallback and
  no longer writes the profile before the native transaction begins.
- Added native-save request counters and last-request-slot state.

## Alpha 0.2.0 — Build 48.68 — Validated 1-based slot mapping

- Rolled back the Build 48.67 ItemWindow visibility hooks after the reported
  game crash; visibility remains on the Build 48.66 implementation.
- Runtime validation showed that visible manual slot 09 reports menu index 9.
- Removed the incorrect `+1` translation from save and load slot capture.
- Captured manual values are now accepted only as displayed 1..20 slots.
- Completion-event fallbacks can no longer translate slot 09 into slot 10 or
  slot 11.

## Alpha 0.2.0 — Build 48.66 — Deferred native save and screen callbacks

- Native game-save completion now queues the RPG profile write for five frames
  later instead of serializing inside the completion callback.
- The deferred write captures the complete live RPG profile after the native
  transaction settles.
- Replaced generic visibility blockers with screen-specific callbacks:
  - `SaveLoadMenuGuiBehavior.draw()` refreshes the save-menu blocker,
  - `GmItemBox.onOpenItemBox` and `onOpenItemBoxSub` activate storage,
  - exact close methods clear storage.
- Removed generic `GmItemBox.openItemBox` from visibility decisions.

## Alpha 0.2.0 — Build 48.65 — Diagnostics and manual-slot correction

- Fixed `ui/rpg.lua` runtime error caused by comparing a missing
  `unblocked_since` value against `0.0`.
- Corrected manual save-slot mapping:
  - `CurrSelectedIndex` and `CurrTargetSlotID` are treated as zero-based GUI
    indices in this runtime path,
  - the captured displayed manual slot now takes precedence over the raw
    completion-event value,
  - completion-event manual values are translated as zero-based only when no
    menu capture exists.
- Saving to displayed slot 09 now writes `player_profile_slot_09.json` rather
  than `player_profile_slot_08.json`.

## Alpha 0.2.0 — Build 48.64 — Visibility timing rollback

- Reverted Build 48.63's 0.25-second unblocked stability gate.
- Restored the Build 48.62 fade-in and immediate inventory draw timing.
- Runtime testing showed `GmItemBox.openItemBox` is not storage-exclusive and
  therefore cannot serve as the final screen discriminator.
- Added no replacement visibility heuristic in this rollback.

## Alpha 0.2.0 — Build 48.63 — Inventory-only stability gate

- Fixed progression briefly or persistently appearing before the native
  storage/typewriter blocker callback arrived.
- Increased the item-box blocker heartbeat from 0.15 to 1.00 second.
- Added a 0.25-second continuously-unblocked requirement before progression
  can become visible.
- Any save/storage/typewriter blocker activity resets that stability timer.
- Added unblocked-stability remaining diagnostics.

## Alpha 0.2.0 — Build 48.62 — Storage/typewriter blocker heartbeat

- Runtime screenshots showed `GmItemBox.openItemBox` firing continuously in
  both the typewriter menu and storage.
- Replaced the permanent storage boolean with a 0.15-second heartbeat:
  - each open callback refreshes the blocker,
  - continuous calls keep progression hidden,
  - returning to normal inventory lets the blocker expire automatically.
- Removed immediate blocker clearing from transient
  `AttacheCaseManager` close edges.
- Added blocker-remaining diagnostics.

## Alpha 0.2.0 — Build 48.61 — Lifecycle-owned native blockers

- Removed **Clear Native Menu Blockers**, which could expose the progression
  panel while storage or the save menu was still active.
- Force Visible no longer mutates native save/storage blocker state.
- Made blocker callbacks edge-triggered:
  - repeated per-frame open callbacks do not increase counters,
  - close counters increment only on real active-to-inactive transitions.
- A definitive `AttacheCaseManager` close now clears both blockers
  automatically before the next inventory session.
- Added diagnostics indicating that blocker ownership is native-lifecycle-only.

## Alpha 0.2.0 — Build 48.60 — Windowed cursor source correction

- Fixed large progression-cursor desynchronization when the game runs in
  windowed mode or the window changes position.
- Removed the requirement that ImGui coordinates must already land inside the
  panel before they can become authoritative.
- Recently moving, in-window ImGui coordinates now drive hover testing, click
  testing, and painted cursor position.
- Scaled native cursor coordinates remain a fallback only when ImGui stops
  updating or becomes unavailable.
- Added cursor-pair error and cursor-source switch diagnostics.

## Alpha 0.2.0 — Build 48.59 — Force-visible input isolation

- Fixed occasional inability to interact with the progression panel while
  **Force Visible for Layout Testing** was enabled.
- Forced mode now reads direct ImGui mouse position, held state, and click state
  every frame.
- Native inventory cursor samples and native click forwarding are ignored while
  forced mode is active.
- Forced cursor rendering no longer depends on native inventory input state.

## Alpha 0.2.0 — Build 48.58 — Native blocker false-positive fix

- Fixed progression visibility being suppressed by a falsely latched native
  non-inventory blocker.
- Removed broad `SaveLoadMenuGuiBehavior.setup/onSetup` blocker hooks because
  controller initialization can occur outside an active save menu.
- Save/typewriter suppression now starts only from `onStartOpen`.
- Storage suppression now starts only from `GmItemBox.openItemBox`.
- Narrowed matching close hooks to `onStartClose`, `onDeactivateEvent`,
  `onDestroy`, and `onCloseItemBox`.
- Force Visible now clears both blocker states.
- Added **Clear Native Menu Blockers** to diagnostics for immediate recovery.

## Alpha 0.2.0 — Build 48.57 — Edge-triggered close latch

- Fixed `Early Exit Requested` remaining true after `Exit Latch Remaining`
  reached `0.000`.
- Made `requestExitAttacheCaseLight` edge-triggered:
  - only the first request starts the close timer,
  - repeated requests are ignored,
  - the latch re-arms after expiry, successful reopen, Force Visible, or
    definitive manager closure.
- Added a second expiry guard immediately before the draw transition.
- Added latch armed-state and generation diagnostics.

## Alpha 0.2.0 — Build 48.56 — Reopen-safe exit latch

- Fixed `exit_requested` remaining latched after the inventory closed.
- The native close hook now creates a bounded 0.45-second close-animation
  suppression instead of a permanent state.
- The latch expires automatically when `AttacheCaseManager` does not expose a
  clean false-to-true transition between sessions.
- Force Visible now:
  - clears stale exit state,
  - forces alpha and target to `1.0`,
  - enables panel input,
  - bypasses transition suppression.
- Definitive manager closure clears all exit timing state.
- Added exit-latch duration and remaining-time diagnostics.

## Alpha 0.2.0 — Build 48.55 — Explicit non-inventory blockers

- Replaced dead inventory-controller callbacks with the only reliable positive
  signal: `AttacheCaseManager.get_IsAttacheCaseBusy()`.
- Added native save/typewriter suppression using
  `chainsaw.SaveLoadMenuGuiBehavior` open/close lifecycle hooks.
- Added native storage suppression using `chainsaw.GmItemBox`:
  - `openItemBox`
  - `onOpenItemBox`
  - `onOpenItemBoxSub`
  - `onCloseItemBox`
  - `onCloseItemBoxSub`
- Save/typewriter or storage activation hides the panel and clears interaction
  immediately.
- Added blocker state and hook-call diagnostics.
- `CurrStep`, `CurrActiveInventory`, and case-menu draw/setup callbacks no
  longer participate in visibility.

## Alpha 0.2.0 — Build 48.54 — Draw-owned inventory visibility

- Runtime diagnostics confirmed setup, item-icon, selection, and open-parameter
  hooks still did not start an Items session.
- Promoted `CaseCustomMenuGuiBehavior.draw()` to the sole continuously refreshed
  visibility signal.
- Added a 0.20-second draw heartbeat to bridge normal frame timing.
- Kept generic update, late-update, and render callbacks excluded from Items
  visibility so adjacent save/storage/typewriter workflows cannot sustain it.
- Kept `CurrStep` completely disconnected from visibility.

## Alpha 0.2.0 — Build 48.53 — Exact inventory hook signatures

- Runtime type inspection revealed the previous concrete inventory hooks used
  incomplete no-argument signatures.
- Added exact signatures for:
  - `onSelectionChanged(chainsaw.InventoryType, System.Int32, System.Int32)`
  - `updateTargetItem(chainsaw.gui.casecustom.CaseCustomSelectType,
    chainsaw.gui.casecustom.CaseCustomInfoBase)`
  - `recieveGuiParam(chainsaw.gui.CaseCustomMenuGuiBehavior.OpenParam)`
- `get_CurrActiveInventory()` and `get_CurrStep()` now try their exact method
  signatures before fallback names.
- Kept `CurrStep` diagnostics-only; it cannot affect visibility.

## Alpha 0.2.0 — Build 48.52 — Inventory controller setup session

- Runtime diagnostics showed all concrete item heartbeat callbacks remained at
  `0.000`, so Build 48.51 had no usable session-start signal.
- Promoted `CaseCustomMenuGuiBehavior.setup` and `onSetup` to authoritative
  inventory-session start callbacks.
- Kept concrete item operations as additional supported signals.
- Kept cycling `CurrStep` completely disconnected from visibility.
- Added `Items Session Active` and `Items Session Source` diagnostics.
- Lifecycle close and `AttacheCaseManager` closure still clear the session.

## Alpha 0.2.0 — Build 48.51 — Concrete Items session

- Confirmed from runtime diagnostics that `CurrStep` continuously cycles through
  `0`, `1`, `2`, and `4` while one screen remains open.
- Removed `CurrStep` completely from progression-panel visibility.
- Promoted concrete inventory operations to Items-session signals:
  - `updateItemIcon`
  - `updateTargetItem`
  - `onSelectionChanged`
  - `CaseCustomMenuIconControl.lateUpdate`
- The first concrete Items signal starts a latched session that remains visible
  without per-frame state checks.
- Lifecycle close and `AttacheCaseManager` closure clear the session.
- `changeStep` remains diagnostic-only and cannot toggle the panel.

## Alpha 0.2.0 — Build 48.50 — Visibility log compatibility

- Fixed the Visibility Transition Log crashing on REFramework ImGui builds
  without `imgui.text_wrapped`.
- Added an `imgui.text` fallback.
- Added explicit read-status diagnostics for `CurrStep` and
  `CurrActiveInventory`, including getter, backing-field, and raw-value state.
- Left Build 48.49 visibility behavior unchanged while diagnostics are
  collected.

## Alpha 0.2.0 — Build 48.49 — Visibility diagnostics

- Reverted the Build 48.48 mode-match implementation because it prevented the
  progression panel from appearing on the tested runtime.
- Restored the Build 48.47 visibility behavior.
- Added a bounded 20-entry visibility transition log containing:
  - attaché manager busy state,
  - current case step,
  - current active-inventory value,
  - learned Items value,
  - panel visible/open state,
  - remaining heartbeat time.
- Added diagnostics UI and a Clear Visibility Log button.
- Added no new visibility heuristic in this build.

## Alpha 0.2.0 — Build 48.48 — Stable inventory-mode gate

- Fixed generic case callbacks incorrectly learning `items_inventory_value`.
- The Items enum is now learned only from confirmed Items-specific callbacks
  and `Step.Move`.
- Replaced fluctuating per-frame `CurrStep` visibility with an exact
  `CurrActiveInventory` mode match.
- Unknown mode reads receive a short 0.50-second grace period; confirmed mode
  mismatches hide immediately.
- Save, storage, and typewriter workflows cannot overwrite or match the Items
  mode accidentally.

## Alpha 0.2.0 — Build 48.47 — Item-grid detection rollback

- Reverted the Build 48.46 item-grid-only visibility implementation.
- Restored the Build 48.45 inventory visibility code because
  `CaseCustomMenuIconControl` updates did not provide a reliable opening
  signal on the tested runtime.
- Preserved all attribute-confirmation, autosave, profile-recovery, XP, and
  death-history changes.
- Added no replacement visibility heuristic in this rollback.

## Alpha 0.2.0 — Build 48.46 — Item-grid visibility authority

- Removed `CurrStep` from the per-frame progression-panel render decision.
- Concrete `CaseCustomMenuIconControl` updates now exclusively refresh panel
  visibility.
- Increased the item-grid heartbeat hold to 0.50 seconds to bridge update gaps
  without flicker.
- Transient non-Items case steps no longer clear the render heartbeat.
- Definitive close step `0` and lifecycle/manager close still clear immediately.
- Save, storage, and typewriter screens remain hidden once concrete item-grid
  updates stop.

## Alpha 0.2.0 — Build 48.45 — Inventory visibility cache

- Restored progression-panel visibility when `changeStep` does not reliably
  activate the Build 48.44 latch.
- A live `CurrStep == Step.Move` read now refreshes the Items session cache.
- Brief unavailable/nil step reads retain the confirmed Items state for
  0.35 seconds to prevent flicker.
- Any confirmed non-Items step clears the cache and hides immediately.
- Concrete inventory-icon heartbeats continue to cover the opening animation.
- Save, storage, and typewriter isolation remains unchanged.

## Alpha 0.2.0 — Build 48.44 — Inventory visibility latch

- Fixed progression-panel flicker while the real inventory remained open.
- Replaced per-frame `CurrStep` dependency with a latched Items session started
  by `CaseCustomMenuGuiBehavior.Step.Move`.
- Concrete inventory-icon heartbeats still cover the opening animation before
  the Move transition arrives.
- Every non-Items step, lifecycle close, and manager close clears the latch
  immediately.
- Preserved the Build 48.43 fix that keeps save, storage, and typewriter screens
  from displaying the progression panel.

## Alpha 0.2.0 — Build 48.43 — Inventory-only visibility proof

- Replaced the retained `items_screen_visible` gate with live native proof.
- The progression panel now requires either:
  - `CaseCustomMenuGuiBehavior.CurrStep == Step.Move`, or
  - a fresh heartbeat from `CaseCustomMenuIconControl` during inventory opening.
- Generic case draw/update callbacks no longer produce Items heartbeats.
- Any non-Move case transition clears retained panel visibility and interaction.
- Typewriter, save, storage, and other non-Items screens cannot open the panel.

## Alpha 0.2.0 — Build 48.42 — Visibility rollback

- Reverted the Build 48.41 inventory/typewriter visibility filter.
- Restored the Build 48.40 progression-panel lifecycle because the stricter
  step filtering prevented reliable opening in the normal inventory.
- Preserved the Build 48.40 debug attribute confirmation controls and all
  autosave/profile fixes.
- No new visibility heuristic was added in this rollback.

## Alpha 0.2.0 — Build 48.41 — Typewriter visibility isolation

- Removed Items-heartbeat status from generic
  `CaseCustomMenuGuiBehavior` draw/update callbacks.
- Concrete `CaseCustomMenuIconControl` updates are now the only early-opening
  heartbeat source.
- Every `CaseCustomMenuGuiBehavior` step other than `Step.Move` immediately
  clears progression-panel visibility and interaction bounds.
- Typewriter, save, storage, key-item, and other non-Items workflows no longer
  retain or recreate the progression panel.
- Genuine inventory opening still fades in before `Step.Move` once its concrete
  item icons begin updating.

## Alpha 0.2.0 — Build 48.40 — Debug attribute confirmation

- Reworked the ImGui RPG attribute panel into a transactional debug allocator.
- Attribute additions now enter a pending queue instead of spending points
  immediately.
- Added **Confirm Distribution** to commit the entire pending allocation.
- Added **Cancel Pending** and per-attribute pending decrement controls.
- Kept committed-attribute refunds as explicit immediate recovery actions.

## Alpha 0.2.0 — Build 48.39 — Inventory opening visibility

- Restored progression-panel fade-in during the attaché-case opening animation.
- Added a short-lived visibility heartbeat from concrete Items controls and
  `CaseCustomMenuGuiBehavior` draw/update callbacks.
- Visibility accepts either the confirmed Items step or a fresh Items heartbeat
  while `AttacheCaseManager` is busy.
- Save and storage screens remain hidden because manager busy state without an
  Items heartbeat is insufficient.
- Definitive close callbacks clear the heartbeat immediately.

## Alpha 0.2.0 — Build 48.38 — Autosave recovery UI

- Expanded emergency profile recovery from manual slots `1–20` to indices
  `0–20`.
- Recovery index `0` maps to the backend key `"autosave"`.
- Indices `1–20` continue to map to their corresponding manual profiles.
- Added a visible resolved-target label before the recovery action runs.

## Alpha 0.2.0 — Build 48.37 — Autosave slot correction

- Fixed save-menu cursor index `0` being treated as manual `slot_01` when the
  native target slot ID was unavailable.
- The selected row is now compared with `CurrAutoSaveSlotIndex` before any
  zero-based manual-slot conversion.
- Profile loading now treats the filename/native event as authoritative and
  repairs stale embedded `slot_key` values after a manual rename.
- Invalid or missing profiles referenced by `active_save.json` no longer become
  the active RPG profile during startup.
- Existing valid autosave progression can be restored by renaming the file to
  `player_profile_autosave.json`; the envelope is repaired on load.

## Alpha 0.2.0 — Build 48.36 — Save-menu visibility fix

- Progression-panel visibility now requires both `AttacheCaseManager` busy state
  and `CaseCustomMenuGuiBehavior.Step.Move`.
- Opening the native save menu no longer displays the progression panel.
- Storage and other adjacent attaché-case workflows cannot leave a stale panel
  visible when the Items step is inactive.
- Preserved the existing early-close hook and fast fade transition.

## Alpha 0.2.0 — Build 48.35 — Strict XP HUD visibility

- Changed the XP ring from fail-open to fail-closed native HUD visibility.
- The ring now requires both a known native HP visibility state and a visible
  `VitalGuiBehavior` state before drawing.
- Loading screens, title transitions, and other unknown HUD states no longer
  display the XP ring.
- Manual XP preview remains an explicit developer override.

## Alpha 0.2.0 — Build 48.34 — Bounded death history

- Reduced retained enemy-death event history from 75 records to 10.
- New confirmed deaths automatically discard the oldest retained event.
- Lifetime kill, native-hook, duplicate-suppression, and reward counters remain
  cumulative and are not reset with the rolling history.
- Updated Enemy Discovery to label the list as `Recent Deaths (Last 10)`.

## Alpha 0.2.0 — Build 48.33 — Data path consolidation

- Consolidated all packaged runtime data under `data/project_overflow/`.
- Moved the bundled BioRand manifest into `data/project_overflow/manifests/`.
- Removed the invalid nested `data/reframework/data/project_overflow/` tree.
- Preserved the populated canonical enemy database, classifier, and profiles
  instead of replacing them with empty nested defaults.
- Documented the archive path and installed REFramework path separately.

## Alpha 0.2.0 — Build 48.32 — First release candidate

- Updated every release-facing README and version file to describe the current
  framework rather than the retired BioRand diagnostic patch.
- Native enemy death hooks install during framework initialization.
- Enemy event subscriptions initialize before frame and ImGui callbacks.
- Confirmed, non-duplicate enemy deaths grant resolved XP by default.
- Added guarded retry behavior for death-hook types that become available after
  the first Lua load tick.
- Documented that logical loot is resolved but native inventory injection is
  not included in this release.
- Replaced the animated delayed-XP shader with a solid configured gain color.

# Changelog

## Release initialization hardening

- Native `EnemyManager.notifyDead` and processed-death fallback hooks now install during Project: Overflow initialization.
- Added a guarded one-second retry when RE Engine death-hook types are not ready on the first Lua load tick.
- Enemy event-pipeline subscriptions now initialize explicitly before frame callbacks.
- Enemy XP rewards are enabled by default for the first release build.
- Updated Enemy Discovery controls and status text to reflect automatic startup installation.

## Framework organization and observed-state update

- Reorganized the root ImGui window into Player & Progression, HUD & XP, and Diagnostics & Maintenance.
- Replaced stale inventory lifecycle diagnostics with the observed `AttacheCaseManager` busy poll, early-exit hook, fade state, and adaptive cursor status.
- Kept the fast attaché-case fade while preventing the close latch from reopening the panel during the native closing animation.
- Updated the REFramework entry point to import canonical modules directly.
- Removed forwarding-only compatibility files and the accidental `core_event_dispatcher.tmp` file.
- Added readable module headers where scripts previously opened without any purpose or ownership comment.
- Updated the primary README, directory layout, API notes, and roadmap to match the framework that is actually running.

## Alpha 0.2.0 — Build 48.31
- Preserved the working EnemyManager.notifyDead hook.
- Added CharacterContext.set_IsProcessedCharacterOnDead(true) as a fallback death signal.
- Added shared context recording and 1.5-second pointer deduplication.
- Added notifyDead vs fallback diagnostics.
- Enemies skipped by notifyDead can now still enter discovery and BioRand resolution.


## Alpha 0.2.0 — Build 48.30
- Restored the entire last-known-working notifyDead probe implementation from Build 48.23.
- Kept BioRand parsing completely outside the native hook callback.
- Added only lightweight world-position capture required for manifest matching.
- BioRand log now auto-loads when the manifest panel is opened.
- Removed misleading Force Rehook control.


## Alpha 0.2.0 — Build 48.29
- Restored the exact notifyDead method lookup used by the last known-working build.
- Removed duplicate-method enumeration that could hook a non-executing TDB entry.
- Kept BioRand manifest and reward logic downstream of the original hook path.


## Alpha 0.2.0 — Build 48.28
- Resolves notifyDead by enumerating the exact overload signature.
- Added Raw Hook Calls and Force Rehook diagnostics.
- Wrapped the native pre-hook so callback errors remain visible.
- BioRand loader now probes multiple REFramework-relative data paths.


## Alpha 0.2.0 — Build 48.27
- Restored immediate onKill display updates before manifest/reward processing.
- Isolated registry, manifest, database, and reward errors with protected calls.
- Enemy Discovery now keeps valid death records even if downstream resolution fails.
- Added Last Record Error and per-enemy Downstream Error diagnostics.


## Alpha 0.2.0 — Build 48.26
- BioRand output_leon.log now loads automatically on first resolution.
- Reward calculation now consumes the matched BioRand family directly.
- Removed reliance on a database write/read round trip before XP calculation.
- Added reward classification source and active seed diagnostics.


## Alpha 0.2.0 — Build 48.25
- Added dynamic parsing of BioRand output_leon.log.
- Added seed, campaign, scene, spawn, family, and position manifests.
- Added runtime world-position capture for dead enemies.
- Added stage + nearest-position manifest resolution.
- BioRand manifest classification now takes priority over runtime fingerprints.
- Added ambiguity safeguards and two supplied seed example manifests.


## Alpha 0.2.0 — Build 48.24
- Added seed-independent runtime fingerprint classification.
- Captures lightweight body/head/updater/GameObject/configuration metadata.
- Added persistent learned classifier mappings.
- Added Learn Classifier From This Enemy workflow.
- Exact fingerprint matches automatically apply family RPG templates.
- Unknown signatures remain isolated and are never guessed.


## Alpha 0.2.0 — Build 48.23
- Added Display Name, Family, and Identified overrides per appearance group.
- Reframed CharacterKindID definitions as native pool defaults.
- Appearance records can now represent unrelated BioRand enemies correctly.
- Updated UI labels to distinguish native pool defaults from effective enemy data.


## Alpha 0.2.0 — Build 48.22
- Removed automatic model grouping based only on CharacterKindID.
- Every newly discovered enemy_id now receives an isolated provisional appearance.
- Automatically splits old Unsorted/Unidentified placeholder groups on load.
- Prevents unrelated models from sharing descriptions and RPG overrides.


## Alpha 0.2.0 — Build 48.21
- Added independent RPG overrides per appearance group.
- Added Base XP, Fixed Final XP, loot, and elite-profile overrides.
- Added forced Normal, Champion, Elite, Legendary, and Boss tiers.
- Family definitions now act as inherited defaults.
- Disabling appearance overrides restores family defaults.


## Alpha 0.2.0 — Build 48.20
- Added appearance groups containing multiple runtime enemy_ids.
- Added automatic enemy_id registration on native death capture.
- Auto-groups new IDs when only one appearance is known.
- Sends ambiguous IDs to an Unsorted Appearance IDs group.
- Renaming an appearance updates every ID in its group.
- Added migration from all prior enemy database schemas.


## Alpha 0.2.0 — Build 48.19
- Renamed per-model records from `enemies` to `appearances`.
- Kept runtime `enemy_id` values with model descriptions.
- Preserved CharacterKindID-level RPG settings as the family definition.
- Added migration from variants, observations, and prior enemies arrays.
- Updated the in-game editor wording to Appearance Description.


## Alpha 0.2.0 — Build 48.18
- Aligned Display Name with the CharacterKindID family definition.
- Changed per-enemy records to enemy_id plus description.
- Kept XP, loot, elite profile, and identification on the family definition.
- Split the UI into Family Definition and Enemy Description editors.
- Added migration from prior variants, observations, and full-record formats.


## Alpha 0.2.0 — Build 48.17
- Replaced shared variant names with full independent enemy records.
- Added an `enemies` array beneath each CharacterKindID.
- Each enemy_id now owns its own name, XP, family, loot, and elite profile.
- Added automatic migration from old `variants` and `observations` data.
- Updated Enemy Discovery wording from Spawner ID to Enemy ID.


## Alpha 0.2.0 — Build 48.16
- Stopped grouping all discoveries solely by CharacterKindID.
- Added CharacterKindID|SpawnerID composite discovery records.
- Added independent names, XP, loot, family, and elite settings per observed record.
- Kept native CharacterKindID and internal ch* archetype references visible.
- Preserved compatibility with existing variants in enemy_database.json.


## Alpha 0.2.0 — Build 48.15
- Fixed the enemy database reload button not refreshing cached UI data.
- Added a forced database.reload() path.
- Added database revision and last reload clock diagnostics.
- Enemy editors now rebuild automatically whenever the database revision changes.


## Alpha 0.2.0 — Build 48.14
- Added the complete supplied CharacterKindID/internal ch* catalog.
- Added a live discovered-enemy definition editor.
- Added persistent friendly names, families, XP, loot, and elite profiles.
- Added editable names for observed SpawnerID/model variants.
- Added enemy database progress statistics and JSON persistence.


## Alpha 0.2.0 — Build 48.13
- Added a bounded, non-recursive reflection snapshot utility.
- Added CharacterParameter and CharacterSpawnParam reflection inspectors.
- Captures simple field values and method names without arbitrary invocation.
- Managed references are listed but not traversed.
- Added strict field and method limits for runtime safety.


## Alpha 0.2.0 — Build 48.12
- Added live CharacterParameter capture to native enemy death discovery.
- Added cautious weapon, equipment, costume, model, body, sex, and variant probes.
- Added compact parameter signatures for comparing enemy loadouts.
- Documented the observed 200001 Zealot body/spawner variants.


## Alpha 0.2.0 — Build 48.11
- Added a data-driven CharacterKindID enemy database.
- Added Normal, Champion, Elite, Legendary, and Boss tiers.
- Added per-tier stat, XP, and loot multipliers.
- Added logical loot tables and reward previews.
- Added experimental opt-in enemy XP awarding.
- Unknown and BioRand/modded enemies use safe fallback rewards.


## Alpha 0.2.0 — Build 48.10
- Restored the proven player, HitPoint, and preview hooks.
- Kept reflection-heavy HUD and gauge probes disabled.
- Kept Enemy Discovery directly visible under Developer.
- EnemyManager.notifyDead remains a manual discovery hook.


## Alpha 0.2.0 — Build 48.08-safe
- Added Safe Compatibility Mode.
- Disabled automatic native-damage, VitalGuiBehavior, and gauge recorder hooks.
- Hid legacy advanced reflection and mutation tools.
- Preserved essential health, overflow, preview, RPG, and resolution functionality.
- Enemy death discovery remains manual.


## Alpha 0.2.0 — Build 48.07
- Moved Enemy Discovery directly into the visible Developer tree.
- The panel no longer requires Developer Mode or navigating past the advanced tools.


## Alpha 0.2.0 — Build 48.06
- Replaced generic HP-setter discovery with EnemyManager.notifyDead.
- Added direct EnemyBaseContext and CharacterContext inspection.
- CharacterKindID is now the primary enemy registry key.
- Added concrete context, spawn, stage, segment, rank, drop, and weak-point metadata.
- XP remains disabled during identity validation.


## Alpha 0.2.0 — Build 48.05
- Added a manually installed enemy death discovery probe.
- Added a runtime enemy type registry and recent kill history.
- Added BioRand-oriented enemy identity documentation.
- Enemy XP rewards remain disabled until IDs are verified.


## Alpha 0.2.0 — Build 48.04
- Added reversible Vitality Max HP application.
- Set Vitality to 50 Max HP per point above 1.
- Kept earned/item Max HP separate as Base Max HP.


## Alpha 0.2.0 — Build 48.03
- Corrected the REFramework progress-bar signature.
- Removed the literal `18` that was being interpreted as overlay text.
- Moved all progress labels above their bars.


## Alpha 0.2.0 — Build 48.02
- Moved XP text above the progression bar.
- Simplified the progress-bar call for REFramework ImGui compatibility.


## Alpha 0.2.0 — Build 48.01
- Restored the missing `draw_rpg_panel` wrapper after the UI module split.


## Alpha 0.2.0 — Build 48.00
- Reorganized systems, engine, render, UI, shared, docs, and assets.
- Moved player progression into systems/player.
- Moved health into systems/health.
- Moved rendering into render.
- Split About and RPG UI into focused modules.
- Added compatibility aliases for old require paths.

## Deprecation and compatibility policy

Project: Overflow currently favors compatibility over deletion. Legacy module paths, fallback hooks, reflection probes, and debug counters remain available when they are useful for old profiles, external scripts, alternate characters, or future RE Engine changes.

Authoritative systems are named explicitly in the relevant documentation. New code should call those paths first. Deprecated paths should receive bug fixes only when required to preserve compatibility; they should not gain new gameplay responsibilities.
