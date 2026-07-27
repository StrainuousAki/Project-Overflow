# Project: Overflow

## Documentation status

- **Reviewed for:** Build 49.81
- **Scope:** Canonical project overview
- **Status:** authoritative
- **Compatibility rule:** Deprecated modules, calls, and probes remain documented and callable until a dedicated removal release.
- **Terminology:** “Deprecated” means supported legacy compatibility; “diagnostic-only” means it must not be treated as an authoritative gameplay path.


**Current release:** Alpha 0.2.2 — Build 49.81

Project: Overflow adds an RPG layer to Resident Evil 4 Remake through REFramework. The current build tracks a save-slot-specific player profile, applies character stats to live gameplay, draws overflow health and XP presentation, and adds a progression panel beside the attaché case.


## Build 49.81 changes

- **Bounded discovered records:** the Discovered Enemy Records dropdown keeps
  only the 10 most recently recorded enemy entries. Repeated enemy types move
  to the newest position, and older cached snapshots are released.
- **Title-screen profile isolation:** after the title-screen no-player gap is
  confirmed, the active RPG profile is unloaded and remains unresolved until
  Continue, Load, or New Game establishes the next native session.
- **Validated load path preserved:** native load request capture, completion,
  delayed HitPoint recapture, slot selection, and profile reconciliation were
  not changed.
- **Startup profile authority:** `active_save.json` is retained only as
  transaction metadata. Existing progression loads only after native
  Continue/Load completion; an unresolved session's first autosave starts
  from fresh defaults.
- **Player-object authority:** an RPG profile remains active only while the
  health state owns a captured player object, except during the existing
  native-load recapture window. Refreshing `project_overflow.lua` during
  active gameplay reloads the current profile through that same path.
- **Synchronized state clearing:** when the player object is no longer
  active, the captured player, HitPoint, cached HP values, overflow and
  preview health state, and RPG profile are cleared together.





### Main-menu profile lifecycle

Project: Overflow now uses `chainsaw.GameStateMainMenu` as the authority for
campaign boundaries. Entering the main menu clears the previous RPG profile
once, and `_IsNewGameStart` identifies a fresh campaign. Player, HitPoint, and
health-hook captures remain gameplay references only; they cannot clear or
rebind progression.

The menu probe records the current `GameStateMainMenu.Phase` for diagnostics.
Native Continue and Load still use the existing save-request, completion,
delayed HitPoint recapture, slot-selection, and reconciliation pipeline.



### Runtime attribute balance testing

The RPG debugger includes a data-driven Attribute Balance Tuning panel. Every
per-point effect and maximum clamp edits the authoritative balance table used by
derived stats, with 0.001 control increments and a one-click default restore.

Extreme clamps are intended for playtesting and destructive experiments.
Sustained fire rate above x2.0 is known to crash the LE 5, TMP, and CQBR.



### Tested overflow ceiling

Overflow rings use exact 2,520-HP bands, ending at 20,160 HP:

`2520, 5040, 7560, 10080, 12600, 15120, 17640, 20160`

The Safe Total Cap is 20,160 HP. Current health testing and overlay rendering
are validated only through that ceiling; higher debug values are unvalidated.


Strength retains its shipped +0.005 damage multiplier per invested point.
Strength 250, representing 249 invested points above baseline, explicitly
reaches the default x2.500 damage cap.


Attribute tuning persists in
`reframework/data/project_overflow/attribute_balance.json`. Slider changes save
to this file automatically and are reloaded when the mod starts or refreshes.
The file is global debug configuration and is intentionally separate from
native-save RPG profiles.


## What currently works

- **Save-aware RPG profiles:** manual save and load calls are mapped to separate profile files. A guarded recovery tool is available when no native slot has been captured yet.
- **Progression:** XP, levels, attribute points, derived stats, and transactional attribute spending are active.
- **Save-slot profiles:** autosave and manual profiles are isolated; autosave-row detection runs before manual index conversion, and renamed files self-repair their embedded slot keys.
- **Recovery UI:** emergency profile recovery is always available and uses index `0` for Autosave and `1–20` for manual slots.
- **Attaché-case panel:** only concrete inventory-icon activity starts the opening fade. Every non-Items native case step immediately hides it, including save, storage, and typewriter workflows.
- **Vitality and max HP:** vitality contributes 20 max HP per point. The stat application layer tracks native base HP separately from the RPG bonus and repairs older stale-base profiles.
- **Combat stats:** weapon damage, action-speed experiments, movement, fire-rate channels, healing, critical chance, and critical damage have dedicated runtime modules and diagnostics.
- **Overflow health presentation:** health beyond the native ring can be drawn as additional layers without replacing the native HUD.
- **XP ring:** the XP ring uses the shared XP profile and draws only while the native health bar is confirmed visible. Loading screens and unknown HUD states remain hidden.
- **Attaché-case progression panel:** `AttacheCaseManager.get_IsAttacheCaseBusy()` provides the reliable open state. `requestExitAttacheCaseLight()` starts the fast close fade early so the panel does not linger after the menu.
- **Adaptive cursor mapping:** the custom panel cursor recalibrates native input coordinates against the live render surface after resolution or focus changes.
- **Enemy framework:** native death hooks and the enemy reward pipeline initialize with the mod. Each confirmed, non-duplicate kill resolves its enemy definition and grants the resulting XP to the active profile by default. Identity, elite data, BioRand manifests, and database diagnostics remain available under the developer tools. Recent-death diagnostics and Discovered Enemy Records each use a 10-entry rolling cache so old death snapshots do not accumulate during long sessions.

## ImGui layout

The Project: Overflow window is organized around how the mod is used:

1. **Player & Progression** — health state, RPG attributes, item/max-HP observations, and recovery controls.
2. **HUD & XP** — overflow-ring and XP-ring presentation settings.
3. **Diagnostics & Maintenance** — focused repair tools, hook status, enemy inspection, and development diagnostics.
4. **About** — version and project information.

Opening or closing an ImGui tree never enables or disables the gameplay systems. Runtime hooks are installed by `project_overflow.lua`.

## Entry point

`autorun/project_overflow.lua` is the live REFramework entry point. It imports canonical module paths directly. The old forwarding-only aliases were removed so there is one obvious implementation for each system.

## Important paths

- `systems/player/` — profile, save data, leveling, derived stats, and stat application.
- `systems/health/` — native health capture and overflow runtime state.
- `systems/enemies/` — enemy classification, persistence, rewards, and BioRand matching.
- `render/` — overflow HUD rendering.
- `xp/` — XP-ring implementation.
- `ui/` — ImGui panels and the attaché-case progression overlay.
- `shared/` — context, constants, utilities, logging, and math.
- `docs/` — technical notes, roadmap, changelog, and RE Engine references.

## Safety notes

Reflection-heavy experiments remain available only where they are still useful. Release-critical death, health, HUD, inventory, save-sync, and XP systems install from the main startup entry. Remaining reflection experiments stay opt-in. Direct mutation and recovery controls are grouped under Cheats or Diagnostics so they are harder to trigger accidentally.

## Data directory

Project: Overflow uses one data root:

```text
reframework/data/project_overflow/
```

Inside a release archive that path appears as `data/project_overflow/` because
the archive is extracted into the `reframework` directory. A nested
`data/reframework/data/project_overflow/` tree is invalid and is not included
in current builds.
- **Debug attribute tools:** additions are queued and require **Confirm Distribution**; pending changes can be canceled without affecting the profile.

- **Visibility rollback:** Build 48.41 menu filtering was reverted after it interfered with normal inventory opening.
- **Inventory-only progression panel:** visibility requires a live native Items step or concrete inventory-icon activity during opening; typewriter, save, storage, and generic case callbacks cannot display it.
- **Stable inventory visibility:** `Step.Move` starts a latched Items session, preventing flicker from intermittent step reads; every non-Items transition clears it immediately.
- **Inventory visibility cache:** confirmed `Step.Move` remains visible across brief unavailable step reads, while every confirmed non-Items step hides immediately.
- **Flicker-free inventory visibility:** concrete item-grid controls own visibility with a 0.50-second heartbeat; transient native case-step changes no longer toggle the panel.

- **Visibility rollback:** Build 48.46 item-grid-only detection was reverted because the required hook did not fire reliably.
- **Stable inventory-mode gate:** the panel uses an exact `CurrActiveInventory` match learned only from confirmed Items callbacks; generic save/storage/typewriter callbacks cannot redefine it.
- **Visibility diagnostics:** Build 48.49 restores the last visible implementation and records a bounded transition log instead of adding another unverified gate.
- **Diagnostic compatibility:** the visibility log falls back to `imgui.text` when `text_wrapped` is unavailable and reports native getter/field read failures explicitly.
- **Stable Items session:** concrete inventory operations latch progression visibility; the cycling `CurrStep` animation value is diagnostics-only.
- **Inventory setup session:** `CaseCustomMenuGuiBehavior.setup/onSetup` starts the stable progression session; cycling `CurrStep` remains diagnostics-only.
- **Exact inventory hooks:** runtime TDB signatures are used for `onSelectionChanged`, `updateTargetItem`, `recieveGuiParam(OpenParam)`, and getter calls.
- **Draw-owned visibility:** the reliable native inventory `draw()` callback refreshes a short heartbeat; generic updates and cycling `CurrStep` cannot toggle the panel.
- **Explicit blockers:** reliable attaché-case busy state shows progression, while `SaveLoadMenuGuiBehavior` and `GmItemBox` suppress save/typewriter and storage screens.
- **Reopen-safe exit latch:** native close requests expire after 0.45 seconds, and Force Visible fully overrides close/fade state.
- **Edge-triggered close latch:** repeated close calls are ignored until the latch expires or inventory successfully reopens.
- **Narrow native blockers:** save/typewriter suppression begins only on `onStartOpen`, storage suppression only on `openItemBox`, and stale blockers can be cleared from diagnostics.
- **Force Visible input:** direct ImGui mouse state is used every frame, preventing intermittent native-input handoff failures.
- **Windowed cursor source:** recently moving ImGui coordinates override stale native cursor coordinates everywhere in the game window.
- **Lifecycle-owned blockers:** save/storage suppression cannot be manually cleared; native attaché-case closure resets both blockers for the next inventory session.
- **Heartbeat blocker:** continuous `GmItemBox.openItemBox` calls suppress typewriter/storage; the blocker expires automatically after returning to normal inventory.
- **Stability gate:** progression appears only after 0.25 seconds of continuously unblocked attaché-case activity; blocker heartbeat now holds for 1.00 second.
- **Visibility timing rollback:** the 48.63 delayed-draw gate was removed; the original fade transition is restored while a real storage-screen discriminator is identified.
- **Save-slot correction:** zero-based native menu indices are translated before profile writes, and the captured displayed slot wins over raw completion values.
- **Deferred native save:** native completion queues a fresh live-profile write; save/storage visibility blockers now use screen-specific callbacks.
- **Validated slot numbering:** manual save/load selections are already 1-based on this runtime; visible slot 09 maps directly to `slot_09`. Build 48.67 visibility hooks are excluded.
- **Native autosave request:** `SaveDataManager.enqueueSaveRequest` slot `0` queues a delayed live-profile write to `player_profile_autosave.json`.
- **Autosave isolation:** `SaveDataManager.enqueueSaveRequest` only owns slot `0`; manual saves retain the validated menu-selection/completion path.
- **Active-slot save synchronization:** native save completion selects the resolved RPG slot before the delayed profile write and reasserts it afterward.
- **Request-slot capture:** native manual `SaveDataManager` slot IDs update the active RPG slot immediately; completion performs the delayed profile write.
- **Operation-specific slot mapping:** native save requests use `raw + 2`; native load requests use `raw - 1`, based on validated visible slot 09 captures.
- **Validated load rows:** native load raw `1` is autosave; raw `2..21` maps to manual slots `01..20`.
- **Load transaction latch:** the first valid native load request is authoritative until completion; later internal requests are ignored.
- **Direct native slots:** `0 = autosave`, `1..20 = manual slots`; save/load request hooks use name/parameter fallback resolution.
- **Native slot identity:** `0 = autosave`; `1..20 = manual saves 01..20`; save and load use the same direct mapping.
- **Transaction-owned slots:** save-menu scrolling only updates cursor diagnostics; native save/load requests exclusively select RPG profile slots.
- **Cursor hooks disabled:** cyclic save-menu navigation values no longer participate in RPG slot synchronization.
- **Completed-save resolution:** request capture, SaveDataManager fields, then completion-event fallback determine the RPG profile slot.
- **SaveDataManager ownership:** request hooks resolve by method name, and completion reads the real singleton/current request `SlotId`.
- **Sticky typewriter blocker:** save-menu draw gaps receive a 2.50-second grace latch, preventing progression flicker during native input transitions.
- **Permanent typewriter blocker:** save/typewriter activation latches suppression until an explicit native close, deactivate, or destroy callback.
- **Typewriter parent blocker:** the parent typewriter menu is suppressed independently from the Save Game submenu; storage remains unchanged.
- **Shared ItemBox blocker:** typewriter and storage sessions latch progression suppression through `GmItemBox` open/close lifecycle hooks.
- **Enemy death UI guard:** incomplete recent-death stage/segment metadata renders as `unknown` instead of crashing.
- **Enemy history event shape:** Recent Deaths reads event metadata from the wrapper and enemy fields from `event.snapshot`.
- **Complete ItemBox coverage:** all reflected `openItemBox`/`onOpenItemBox` and close variants are hooked, with last-fired diagnostics.
- **ItemBox diagnostic rollback:** shared `GmItemBox` callbacks no longer affect visibility; they remain instrumented to identify screen-specific behavior.
- **Inventory sentinel guard:** negative active-inventory values such as `-1` are rejected and cannot count as the Items screen.
- **Inventory guard scope repair:** `valid_inventory_value` is declared before every caller.
- **Concrete icon-grid proof:** only `CaseCustomMenuIconControl.lateUpdate` confirms the Items screen; Charms hover callbacks are excluded.
- **Visibility rollback and probes:** shared icon-grid signals are diagnostic-only; target managed type and selection arguments are recorded.
- **Case method probe:** per-method counters compare inventory, typewriter, storage, and Charms without affecting visibility.
- **Verified Charms blocker:** `CaseCustomMenuGuiBehavior.lateUpdateOnActive` suppresses progression continuously on Charms.
- **ItemBox method probe:** per-method counters compare typewriter and storage while the verified Charms blocker remains active.
- **ItemBox probe refinement:** ambient `openItemBox` calls are excluded from typewriter/storage lifecycle totals.
- **Direct typewriter blocker:** `GmTypeWriter.initInteractTrigger` latches suppression until the attaché workflow closes.
- **Typewriter behavior blocker:** the player behavior-tree action `onStart/onEnd` now owns the parent typewriter latch.
- **Armoury state probe:** captures concrete state runtime type, transition target, and hub step across inventory/typewriter/storage.
- **Armoury state ownership:** concrete state-class prefixes now drive typewriter/storage blocking and inventory restoration.
- **Verified state blockers:** exact `ArmouryGuiState_Close` and `ArmouryGuiState_ArmouryEnter` signals own typewriter and storage suppression.
- **State counter repair:** verified storage/typewriter blockers now use initialized transition counters without nil arithmetic.
- **Typewriter onInit ownership:** only `ArmouryGuiState_Close.onInit` latches the parent typewriter blocker.
- **Verified typewriter behavior ownership:** behavior-tree `onStart/onEnd` now exclusively control the typewriter blocker.
- **Latched typewriter blocker:** behavior `onStart` latches suppression; `onEnd` is diagnostic and release waits for the attaché workflow to close.
- **Typewriter status cleanup:** the behavior-tree hook is now the primary status; the obsolete parent resolver is labeled legacy-only.
- **Bidirectional typewriter resolution:** behavior `onEnd` now uses the current attaché-manager state to distinguish menu entry from exit.
- **Typewriter transition ownership:** `onStart` begins a blocked transition; only `onEnd` plus manager state resolves open or closed.
- **Typewriter onStart rollback:** `onStart` is diagnostic-only; `onEnd` plus manager state resolves open or closed.
- **Hub child probe:** records existence, type, and validity for typewriter, storage, Save Game, and case child behaviors.
- **Direct typewriter lifecycle:** `ArmourySelectGuiBehavior.onStartOpen/onStartClose` owns the parent typewriter blocker.
- **Agility/Dexterity repair:** movement getters use Agility, while melee/reload/weapon-transition native channels use Dexterity action speed.
- **Immediate blocker suppression:** menu lifecycle hooks now zero current and target fade alpha to remove one-frame flashes.
- **Direct storage lifecycle:** `ArmouryGuiBehavior.onStartOpen/onStartClose` now owns storage suppression.
- **Speed scope repair:** multiplier helpers are forward-declared, preventing nil-global crashes and exposing actual Agility walk/run application.
- **Agility live capture:** captures `PlayerCommonParamUserData` directly and applies preserved-baseline walk/run fields when native getters remain unused.
- **Agility graph capture:** bounded live-player traversal locates exact `PlayerCommonParamUserData` when neither getters nor singleton access expose it.
- **Action Speed player recovery:** captures `PlayerCharacterContext` through `updateContextDataOnUpdatePhase` before running movement graph discovery.
- **Direct movement userdata capture:** `PlayerCommonParamUserData.onLoad` captures the exact walk/run parameter object before Agility writes preserved-baseline values.
- **Live movement recovery:** exact-type `sdk.get_managed_objects` scanning captures already-loaded `PlayerCommonParamUserData` without requiring a fresh load callback.
- **Live movement accessor capture:** narrow `PlayerCommonParamUserData` getter hooks recover the active userdata through the callback `this` pointer.
- **Live body movement:** `PlayerBodyUpdater.getNextMotionSpeed()` applies the Agility multiplier to active walk/run motion speed.
- **Walk/run-only Agility:** `getNextMotionSpeed()` is multiplied only when live movement-direction fields indicate locomotion input.
- **Agility reload speed:** the first invested point gives +0.002 and later points give +0.001, capped at `x1.250`.
- **Exact fire-rate cap:** Dexterity Fire Rate now reaches `x1.250` at attribute 250 instead of stopping at `x1.249`.
- **Reload action rate:** MC reload behavior actions multiply `_McReloadSpeedRate` by Agility Reload Speed and restore the native value on action end.
- **Reload base dispatch:** hooks the base `ApplyReloadSpeed` lifecycle, deduplicates inherited methods, and applies `_McReloadSpeedRate` on the derived runtime instance.
- **Reload duration diagnostics:** shows applied rate, inverse normalized duration, duration ratio, and percentage reduction.
- **Reload-rate persistence:** applies before and after native reload lifecycle callbacks and verifies the post-original field value.
- **Reload argument capture:** scans hook arguments for the actual `ApplyReloadSpeed` runtime object instead of assuming `args[2]`.
- **Reload-local motion:** base reload actions use their own `_Motion` layers for Agility speed, with native layer restoration on action end.
- **Direct Gun reload rate:** `chainsaw.Gun.get_ReloadSpeedRate()` returns the active weapon rate multiplied by Agility Reload Speed.
- **Single reload path:** once `Gun.get_ReloadSpeedRate()` is active, behavior-tree rate and motion-layer writes are suppressed.
- **Direct-only reload speed:** behavior-tree hooks are observation-only; `Gun.get_ReloadSpeedRate()` is the sole mutating path.
- **Reload visual:** Agility displays the actual reload-duration reduction rather than the internal speed multiplier.
- **Luck sign formatting:** Critical Chance and Critical Damage both display an explicit leading `+`.

## Current authoritative runtime paths

| Feature | Authoritative path | Retained legacy/diagnostic paths |
|---|---|---|
| Walk/run speed | `PlayerBodyUpdater.getNextMotionSpeed()` with walk/run gating | `PlayerCommonParamUserData` capture and graph probes |
| Reload speed | `chainsaw.Gun.get_ReloadSpeedRate()` | Reload behavior-tree lifecycle and local-motion probes |
| Native save profiles | Slot `0` autosave; slots `1..20` manual | Cursor-direction inference and unresolved completion fallbacks |
| Progression visibility | Verified inventory/items classification with save, typewriter, storage, and Charms blockers | Shared `GmItemBox` and experimental screen probes |
| XP/reward flow | Enemy pipeline, rewards, leveling, and profile systems | Reflection discovery and developer probes |

These retained paths are not removed because they remain useful for alternate runtime conditions and research, but new gameplay behavior should use the authoritative path first.

## Deprecation and compatibility policy

Project: Overflow currently favors compatibility over deletion. Legacy module paths, fallback hooks, reflection probes, and debug counters remain available when they are useful for old profiles, external scripts, alternate characters, or future RE Engine changes.

Authoritative systems are named explicitly in the relevant documentation. New code should call those paths first. Deprecated paths should receive bug fixes only when required to preserve compatibility; they should not gain new gameplay responsibilities.
- **Inventory suppression fix:** early Charms hooks now resolve the local suppression helper through an explicit forward declaration.
- **Persistent storage blocker:** verified storage open/close lifecycle owns a session latch; temporary item-box heartbeats cannot release it.
- **Save-load movement fix:** multiplier locals are declared before movement userdata callbacks can run.
- **Per-save movement isolation:** native load completion restores old movement baselines, clears runtime caches, and recaptures the loaded player before applying Agility.
- **Movement transition normalization:** recognizes the previous profile’s retained applied speed, removes the old multiplier, and releases once a fresh engine value appears.
- **New-campaign isolation:** after an extended title-screen gap, a fresh player with no native load request receives a reset RPG profile and no inherited slot identity.
- **Campaign initialization gate:** title-screen confirmation resets defaults immediately; bonuses resume only after native save initialization.
- **Character-save binding:** the active RPG profile is tied to its live player instance; an un-loaded replacement player resets to defaults before first autosave.
- **Items-tab-only progression:** visibility requires the active inventory enum to match the concrete item-grid enum; Map, Treasures, Crafting, Files, and all other tabs are blocked.
- **Progression visual restoration:** reverted the Build 49.48 tab-gating experiment and restored the complete known-working Build 49.47 inventory progression module.
- **Treasures blocker:** `KeyTreasureInventoryGuiBehavior` independently suppresses progression while the Treasures screen is active, without touching the renderer/open path.
- **Map blocker:** `MapManager.onMapStartOpen`, `isMapGuiOpen`, and `onMapClosed` independently suppress progression while the map is active.
- **Files blocker:** `FileManager.changePhase` and `CurrPhase` independently suppress progression while the Files interface is active.
- **Crafting blocker:** `CraftWindowGuiBehavior` independently suppresses progression through its setup, step, draw, and close lifecycle.
- **Emergency blocker rollback:** removed the experimental Treasures, Map, Files, and Crafting blockers and restored the exact Build 49.49 progression module.
- **Safe Map poll:** progression checks `MapManager.isMapGuiOpen()` through a throttled, protected singleton poll with no native lifecycle hooks.
- **Safe Files poll:** progression checks `FileManager.CurrPhase` through a throttled, protected singleton poll with no native lifecycle hooks.
- **Files poll rollback:** removed `FileManager.CurrPhase` as a blocker because it remains active outside the Files screen and suppresses progression on Items.
- **Safe Keys & Treasures poll:** while the attaché case is open, a throttled managed-object scan checks `KeyTreasureInventoryGuiBehavior.CurrStep` without installing hooks.
- **Keys & Treasures poll rollback:** removed the persistent `KeyTreasureInventoryGuiBehavior.CurrStep` scan because it is not limited to the visible treasure screen.
- **Current Item Window state poll:** reads `ItemWindowGuiControlBehavior._CurrState` and blocks only Keys & Treasures runtime state classes.
- **Items-only visibility:** progression displays only for live `AttacheCase*` Items states, excluding Crafting and exit transitions.
- **Items whitelist rollback:** removed the strict `_CurrState` class-name whitelist because it hid the actual Items screen.
- **Root-state Items whitelist:** reads `ItemWindowGuiControlBehavior.CurrRootState`, dynamically resolves allowed `AttacheCase*` enum values, and bypasses the gate if resolution fails.
- **Item Window diagnostic probe:** logs raw root/state/start/step values on change without affecting progression visibility.
- **Visible Item Window probe:** raw root/state/start/step values appear inside the Attaché-Case Progression Panel diagnostics tree.
- **Items-only progression:** a separate HighwayGuiManager-backed menu-state module restricts the progression overlay to the stable Items tab.


Profile identity and session presence are separate signals. Stable
`PlayerCharacterContext` identifies the profile owner, while the broader shared
player pointer prevents the title-gap timer from firing during normal gameplay
when the context callback is temporarily unavailable.


Campaign presence is polled directly from
`chainsaw.CharacterManager:getPlayerContextRef()`. Hook-owned player references
do not control the title-gap timer, so normal health/stat operations and
temporary capture gaps cannot unload the RPG profile.

Alpha 0.2.2 | Build 49.81 performance and compatibility pass:
- Removed the duplicate health runtime update from re.on_draw_ui.
- Configuration rendering no longer performs gameplay-state updates.
- Progression cursor/input capture is skipped unless the progression panel is visible or fading.
- Expensive ItemWindowGuiControlBehavior managed-object enumeration is diagnostic-only and disabled by default.
- Diagnostic item-window scans are throttled to at most once per second when explicitly enabled.
- Added lightweight callback timing for UI, save sync, health runtime, overflow HUD, XP HUD, and progression UI.

Build 49.81 event-driven stat application test:
- Action-speed hooks are installed once instead of being rechecked every frame.
- Dexterity and Agility persistent movement fields are reapplied only when the
  player object changes, the profile values change, or movement data is freshly captured.
- Fire rate, reload speed, knife speed, melee speed, and weapon-transition
  modifiers remain native event/getter hooks and read the current profile multiplier when called.
- Removed the recurring one-second player-animation discovery scan.
- Vitality Max HP application is dirty/event-driven with a one-second external
  Max HP audit to preserve yellow-herb and native Max HP change detection.
- Native save/load and stat-tracking resets mark affected values dirty for one-time reapplication.

Build 49.81 event-driven hook retry fix:
- Retained the event-driven Dexterity/Agility and movement application experiment.
- Removed the one-shot runtime-installed latch.
- Unresolved native hooks now retry on later frames while successfully installed
  hooks remain guarded by their own installed flags.
- This specifically restores late resolution for fire-rate and reload hooks
  without restoring continuous movement/stat writes.
- Weapon-transition speed remains unvalidated and unchanged.

Build 49.81 direct fire-event restoration:
- Restored the previously working PlayerEquipment.execFire() application path.
- On a real fire event, the active PlayerEquipment Motion TreeLayer speeds are
  multiplied by the dedicated Dexterity Fire Rate multiplier.
- Dry-fire and PlayerEquipment reload callbacks remain diagnostic-only.
- Reload Speed remains on chainsaw.Gun.get_ReloadSpeedRate().
- Event-driven movement, knife/melee speed, and Vitality behavior remain intact.
- The shipped Fire Rate cap remains x1.250; historical destructive testing
  showed sustained values above x2.0 could crash the LE 5, TMP, and CQBR.
- Weapon-transition speed remains unvalidated and unchanged.

Alpha 0.2.2 | Build 49.81 — Separate Ways profile isolation:
- RPG profile identity is now campaign + native save slot.
- Leon and Separate Ways use separate autosave and manual-slot profile files.
- Native save/load request metadata is inspected before slot selection to
  resolve Leon versus Separate Ways.
- Existing un-namespaced profiles are treated as Leon profiles and migrated
  into the Leon campaign folder when loaded.
- active_save.json now records campaign, slot_key, and composite_key.
- Separate Ways never falls back to a Leon RPG profile.

Build 49.81 campaign-routing safety fix:
- active_save.json remains a single global routing marker; it is not moved into
  either campaign folder.
- Returning to the main menu clears in-memory campaign confidence.
- Save/load requests now perform a bounded reflection scan of request, manager,
  and player objects for Leon/Ada/Separate Ways campaign evidence.
- An unresolved campaign no longer defaults to Leon.
- RPG save/load is skipped when campaign identity is unresolved, preventing a
  Separate Ways slot from loading or overwriting the matching Leon slot.

Build 49.81 campaign-aware debug UI:
- RPG Save Slot Synchronization visibly shows the detected active campaign,
  campaign key, composite campaign/slot identity, detection source, and evidence.
- Pending and queued save/load transactions display their campaign binding.
- Emergency RPG Profile Tools expose only the active campaign's controls.
- Leon gameplay shows only Leon save/load and slot-binding tools.
- Separate Ways gameplay shows only Ada save/load and slot-binding tools.
- When campaign identity is unresolved, all profile save/load and slot-binding
  controls are hidden.

Build 49.81 definite campaign menu hooks:
- chainsaw.GameStateMainMenu is now the explicit Leon campaign authority.
- Separate Ways/bonus-game main-menu state candidates are hooked for enter,
  update, and leave lifecycle methods.
- A resolved bonus-game menu hook explicitly selects Separate Ways (Ada).
- Leaving the Separate Ways menu retains Ada authority into gameplay.
- Returning to the normal RE4R main menu explicitly selects Leon.
- Native request reflection is now fallback confirmation only.
- RPG diagnostics show which campaign menu hook/type actually resolved.

Build 49.81 GameStateMainMenu campaign-method discovery:
- Runtime evidence showed Separate Ways uses chainsaw.GameStateMainMenu on this
  game build; guessed bonus-menu state classes did not resolve.
- GameStateMainMenu methods are inspected once for explicit Separate Ways,
  Another Order, Ada, DLC, or bonus-game transition/selection callbacks.
- Resolved campaign-specific methods become authoritative Ada triggers.
- Generic GameStateMainMenu.update() can no longer overwrite active Ada
  authority with Leon.
- Debug UI lists every resolved Ada method and the last one that fired.

Build 49.81 exact Separate Ways menu hooks:
- Runtime inspection confirmed the Separate Ways main-menu state is
  chainsaw.GameStateAOMainMenu.
- Separate Ways campaign authority now uses the exact lifecycle hooks:
  enterInMainMenu(), update(), and leaveInMainMenu().
- The normal campaign continues to use chainsaw.GameStateMainMenu with the
  same lifecycle methods.
- Guessed bonus-menu state classes and GameStateMainMenu method-name discovery
  were removed.
- GameStateAOMainMenu explicitly selects Separate Ways (Ada) and cannot be
  overwritten by the normal GameStateMainMenu update hook.

Build 49.81 campaign-specific native slot limits:
- Leon uses one autosave plus manual slots 01-20.
- Separate Ways uses one autosave plus manual slots 01-10.
- Native request normalization now validates against the active campaign.
- Ada slot 11-20 values are rejected and cannot bind or create RPG profiles.
- Emergency profile recovery caps its slot selector at 10 during Separate Ways.
- Debug slot convention visibly changes with the active campaign.

Build 49.81 exact SaveDataManager slot hooks:
- Added direct hooks for requestSaveGameData(Int32, GameSaveRequestArgs) and
  requestLoadGameData(Int32, GameLoadRequestArgs).
- Slot identity is captured from the explicit slotId argument before completion.
- SaveDataUtil.getCampaignIdentifier(slotId) is used to resolve Leon versus
  Separate Ways directly from native save metadata.
- Completion fallback now reads SaveDataManager.TempPlayLoadData.CursorSaveData
  including IsAutoSaveData and Slot.
- Load fallback reads LastLoadSucceededGameSlot and LastLoadSlot.
- Existing enqueue and completion hooks remain as compatibility fallbacks.

Build 49.81 SaveDataManager completion-source correction:
- Save/load completion callbacks provide SaveLoadMenuGuiManager, not the native
  SaveDataManager that owns CurrentRequest, TempPlayLoadData, and last-slot data.
- Completion fallback now reads the share.SaveDataManager singleton directly.
- CurrentRequest is checked before cursor data and supports SlotId, SlotID,
  Slot, lowercase, backing-field, and underscore field variants.
- Debug UI reports the CurrentRequest source and raw slot that resolved.

Build 49.81 manual-slot resolution correction:
- The deprecated autosave-sentinel experiment has been removed.
- Native slot -1 is invalid/unresolved and is never treated as autosave.
- Negative CurrentRequest slots are ignored so later authoritative sources can
  resolve the real manual slot.
- Added requestStartSaveGameDataFlow(Int32, GameSaveRequestArgs) for direct
  manual-slot capture.
- Added setPlayLoadData(Boolean isAutoSave, Int32 slot), where autosave is
  accepted only when the native Boolean explicitly reports true.
- Native slot 0 remains the normal autosave slot.

Build 49.81 Separate Ways save-slot completion fix:
- Save/load completion now trusts the already authoritative AO campaign from
  GameStateAOMainMenu, pending transaction state, or the active RPG profile.
- Completion no longer re-detects and discards Separate Ways when campaign
  identity is already known.
- SaveDataManager hook installation now retries by simple method name when
  REFramework does not resolve the full reflected signature.
- Added simple-name fallbacks for requestSaveGameData, requestLoadGameData,
  requestStartSaveGameDataFlow, setPlayLoadData, enqueueSaveRequest, and
  enqueueLoadRequest.
- Debug UI reports whether save completion used authoritative campaign state.

Build 49.81 native integer/physical-slot correction:
- REFramework hook Int32 arguments are decoded with sdk.to_int64/to_int32
  before tonumber or enum fallback.
- Direct SaveDataManager hooks can now read their real native slotId values.
- Separate Ways physical slot mapping is normalized as:
  100=autosave and 101-110=manual slots 01-10.
- TempPlayLoadData is no longer used as a general save-completion fallback;
  it is accepted only after an explicit autosave transaction.
- Debug UI reports raw direct save/load request slot values.

Build 49.81 campaign truth diagnostics and Leon authority reset:
- GameStateMainMenu enter/update now explicitly reclaim Leon authority and clear
  stale Separate Ways menu state.
- Diagnostics distinguish live menu authority, active profile campaign, native
  load campaign/slot, and exact JSON profile identity loaded.
- Added campaign authority serial so menu transitions visibly update.

