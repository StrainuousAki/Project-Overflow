PROJECT: OVERFLOW
Resident Evil 4 Remake RPG Framework
Alpha 0.2.2 — Build 49.81
=====================================

OVERVIEW
--------
Project: Overflow adds save-aware RPG progression to Resident Evil 4 Remake
through REFramework. The release build tracks XP, levels, attributes, derived
combat stats, overflow health, enemy rewards, and an attaché-case progression
panel.

INSTALL
-------
1. Install a compatible REFramework build for Resident Evil 4 Remake.
2. Copy the included autorun folder into the REFramework directory.
3. Launch the game.
4. Open REFramework's Script Generated UI and expand Project: Overflow.

CURRENT RELEASE FUNCTIONALITY
-----------------------------
- Native enemy death hooks install during Project: Overflow initialization.
- Enemy XP rewards are enabled by default.
- A confirmed, non-duplicate enemy death is resolved through the enemy
  database and reward pipeline, then grants the resulting XP to the active
  save-slot profile.
- Recent death diagnostics retain only the latest 10 events; new records
  automatically replace the oldest retained event.
- Discovered Enemy Records retains only the 10 newest cached enemy entries.
- The XP ring reads the same live profile used by leveling and attributes.
- The XP ring draws only after the native HP bar is confirmed visible; loading
  screens and unknown HUD states remain hidden.
- The delayed XP gain segment uses a solid configured color rather than an
  animated shader.
- Vitality applies reversible max-HP bonuses while preserving native and
  item-earned base max HP.
- The progression panel begins fading in from concrete native Items activity,
  then remains visible through the attaché-case Items step.
- Save, storage, and typewriter screens remain hidden because generic case
  activity and manager busy state cannot open the panel.
- Every native non-Items case step clears panel visibility immediately.
- Its close fade begins from requestExitAttacheCaseLight(), before the native
  menu fully exits.
- Player profiles are separated by observed native save slot.
- Autosave-row detection happens before zero-based manual-slot conversion, so
  autosave is not written as slot 01.
- Valid renamed profiles automatically repair their embedded slot key.
- Emergency profile recovery uses slot 0 for Autosave and slots 1-20 for manual saves.
- Debug attribute distribution requires confirmation before pending additions are committed.

XP AND DEATH HOOK STARTUP
-------------------------
The release entry point initializes the enemy pipeline before frame and ImGui
callbacks are registered. It subscribes the reward pipeline, enables enemy XP,
and installs both native death signals:

- chainsaw.EnemyManager.notifyDead()
- chainsaw.CharacterContext.set_IsProcessedCharacterOnDead(Boolean)

Hook installation is idempotent. If the required RE Engine types are not ready
during the first Lua load tick, Project: Overflow retries without stacking
duplicate hooks.

REWARD BEHAVIOR
---------------
XP is granted now. The final amount is resolved from the enemy definition,
appearance overrides, BioRand classification when available, and elite tier.
Duplicate death callbacks are suppressed so one confirmed kill produces one
reward transaction.

Logical loot can be resolved and displayed by the framework, but native
inventory injection is not part of this release.

TEST CHECKLIST
--------------
1. Launch the game and open Project: Overflow diagnostics.
2. Confirm the enemy event pipeline is subscribed.
3. Confirm at least one death hook is installed.
4. Kill an enemy.
5. Confirm one recent-death record and one committed reward transaction.
6. Confirm the active profile XP increases and the XP ring updates.
7. Save and load another slot to confirm profile separation.

IMPORTANT PATHS
---------------
Entry point:
  reframework/autorun/project_overflow.lua

Framework:
  reframework/autorun/project_overflow/

Persistent data:
  reframework/data/project_overflow/

The release archive contains this directory as:
  data/project_overflow/

Do not create or use:
  data/reframework/data/project_overflow/

Documentation:
  reframework/autorun/project_overflow/README.md
  reframework/autorun/project_overflow/docs/

KNOWN LIMITATIONS
-----------------
- Enemy definitions and XP values are still being balanced.
- Unknown or modded enemies may use fallback classification and XP.
- BioRand position matching can be less reliable when enemies move far from
  their original spawn before death.
- Logical loot does not yet add items directly to the native inventory.
- Some combat-stat channels remain experimental and expose diagnostics.

VERSION
-------
Alpha 0.2.2 — Build 49.81

Known visibility issue:
- Build 48.41 visibility filtering was rolled back because it prevented the
  progression panel from opening reliably in the real inventory.

Inventory-only panel rule:
- The progression panel renders only from a live native Items controller or
  concrete inventory-icon activity during the opening animation.
- Typewriter, save, storage, and generic case activity cannot open it.

Stable inventory visibility:
- The native Items transition latches visibility for the active inventory session.
- Intermittent CurrStep getter failures cannot flicker the progression panel.
- Any non-Items transition still clears it immediately.

Inventory visibility recovery:
- Live Step.Move confirmation now drives visibility with a short read-failure grace period.
- Confirmed save, storage, typewriter, and other non-Items steps still hide immediately.

Inventory visibility authority:
- The progression panel is visible only while concrete inventory item controls
  continue updating.
- Transient native case-step changes no longer cause flicker.

Known inventory visibility state:
- Build 48.46 was rolled back because the item-grid hook did not produce an
  opening signal on the tested game build.

Stable inventory mode:
- The panel compares the live native active-inventory enum with the enum learned
  from the confirmed Items screen.
- Generic case workflows cannot redefine the learned Items mode.

Visibility diagnostics:
- RPG Progression > Diagnostics > Attaché-Case Progression Panel now includes
  a Visibility Transition Log.
- Capture the log separately while opening inventory, typewriter, save, and storage.

Diagnostic compatibility:
- Visibility Transition Log now works on REFramework ImGui builds without
  text_wrapped.
- Read-status lines explain why native fields report unknown.

Inventory-only stable session:
- Concrete inventory operations start the progression panel.
- Native animation-step values no longer open, close, or flicker the panel.
- Lifecycle and manager closure clear the Items session.

Inventory session startup:
- The progression panel now starts from the inventory controller's setup/onSetup
  callbacks, which are firing on this runtime even though item-icon callbacks are not.

Exact runtime signatures:
- The type inspector showed that onSelectionChanged and updateTargetItem require
  parameters. Build 48.53 hooks those exact signatures instead of no-arg guesses.

Runtime-compatible inventory visibility:
- The visible inventory controller draw callback owns the panel heartbeat.
- Save/storage/typewriter cannot keep the panel alive through generic updates.

Inventory-only visibility:
- Progression shows when the attaché case is busy unless the native save/typewriter
  controller or storage item-box controller is active.

Reopen fix:
- Closing inventory can no longer permanently latch the progression panel off.
- Force Visible now overrides close, blocker, and fade state while enabled.

Inventory reopen lifecycle:
- Close requests are edge-triggered and cannot permanently extend the exit latch.
- The panel self-heals stale exit_requested state before rendering.

Native blocker recovery:
- Broad controller setup hooks were removed because they could mark blockers
  active during ordinary inventory initialization.
- Diagnostics now includes Clear Native Menu Blockers.

Force-visible input:
- Forced layout testing uses direct ImGui mouse position, button-down, and click state.
- Native attaché-case cursor availability is ignored while Force Visible is enabled.

Windowed cursor alignment:
- Live ImGui window coordinates control hit testing and the proxy while moving.
- Opening another window is no longer required to refresh the cursor transform.

Native menu blocker ownership:
- Blockers can no longer be manually cleared while save or storage is still open.
- They reset automatically only when the native attaché-case workflow closes.

Storage/typewriter suppression:
- The item-box blocker is heartbeat-based instead of manually or manager-close cleared.
- This prevents progression from appearing over the typewriter and storage screens.

Inventory-only timing:
- The panel no longer appears immediately on a busy transition.
- It must remain free of save/storage/typewriter blocker activity for 0.25 seconds.

Visibility timing rollback:
- Build 48.63's delayed draw gate was removed because it damaged fade-in
  without reliably distinguishing inventory from storage or save screens.

Save-slot mapping:
- Manual save completion values no longer override the translated GUI slot.
- Displayed save slot numbers and RPG profile filenames now match.

Native saves:
- RPG profiles are now written after the native save transaction settles rather
  than directly inside the completion callback.

Visibility:
- Save and storage blockers use screen-specific callbacks instead of generic
  item-box/controller activity.

Save/load slot identity:
- The runtime reports visible manual slot numbers directly as 1..20.
- No cursor offset is applied.
- Build 48.67 visibility hooks were rolled back after the reported crash.

Autosave profiles:
- The mod now listens to the native SaveDataManager request queue.
- Slot ID 0 updates player_profile_autosave.json after the native autosave settles.

Save-path isolation:
- Native request-queue synchronization is autosave-only.
- Manual save behavior is restored to the validated menu-selection path.

Active save slot:
- Saving natively now updates the active RPG slot before writing the profile.
- active_save.json and in-memory sync state follow the slot actually saved.

Manual native save capture:
- The native SaveDataManager request slot is now authoritative when save-menu
  selection hooks do not fire.
- Completion still controls the actual delayed RPG profile write.

Native save/load slot spaces:
- Save and load requests use different internal numbering on this runtime.
- They are normalized independently before selecting an RPG profile.

Load-slot mapping:
- Autosave occupies native load row 1.
- Manual slot number is native load row minus one.

Load transaction identity:
- Native loads emit multiple internal requests.
- The first valid selected row is now held until load completion.

Native slot identity:
- No slot offsets are applied.
- Slot 00 is autosave; slots 01..20 are manual saves.
- Request-hook lookup now has a runtime-safe fallback resolver.

Build 48.77 repairs the game_save_sync.lua module-load syntax error from 48.76.

Native save-slot identity:
- 0 = autosave
- 1..20 = manual saves 01..20
- Save and load share this exact mapping.

Save-menu scrolling:
- Highlighted rows are diagnostic only.
- Native save/load requests own profile identity.

Save-menu cursor callbacks are disabled because they report cyclic navigation
neighbors rather than the selected native save SlotId.

Native save completion now resolves its profile slot from request capture,
SaveDataManager completion state, or completion-event fallback.

Build 48.82 fixes request-hook discovery and reads save SlotId from the actual
SaveDataManager singleton/current request during completion.

The typewriter/save blocker now survives short native draw interruptions caused
by save-menu input and confirmation transitions.

The progression panel remains blocked for the complete save/typewriter session
and is released only by an explicit native close lifecycle event.

The typewriter parent screen now has its own lifecycle blocker, separate from
the Save Game list and storage screen.

Typewriter and storage now share a permanent GmItemBox lifecycle blocker with
method-name fallback resolution.

Recent enemy deaths no longer crash the developer panel when stage or segment
metadata has not been captured yet.

Recent Deaths now understands the registry event wrapper and reads captured
enemy details from event.snapshot.

The typewriter/storage blocker now installs every available GmItemBox open and
close lifecycle variant instead of stopping at the first reflected method.

GmItemBox callbacks are diagnostic-only because they are shared by inventory,
typewriter, and storage. They no longer suppress the progression panel.

Negative active-inventory values such as -1 are treated as non-Items sentinels
and cannot activate or train the progression overlay.

Build 48.94 repairs the Lua scope error introduced by the inventory sentinel
guard while retaining the same visibility behavior.

Progression visibility now requires the concrete attaché-case item-grid icon
controls. Shared Charms hover and selection callbacks no longer count.

Build 48.96 rolls back the failed shared icon-grid visibility gate and adds
screen-specific target/selection telemetry.

Build 48.98 adds per-method CaseCustomMenuGuiBehavior counters so inventory,
typewriter, storage, and charms can be compared without changing visibility.

The Charms screen is now blocked by its verified lateUpdateOnActive heartbeat,
without relying on hover events.

Build 49.00 adds per-method GmItemBox counters to distinguish typewriter and
storage without changing their visibility yet.

Build 49.01 separates the continuous gameplay openItemBox call from actual
menu lifecycle method counters.

The parent typewriter screen is now blocked directly through
chainsaw.GmTypeWriter.initInteractTrigger.

Build 49.04 uses the player's typewriter behavior-tree action for actual
typewriter menu lifecycle blocking.

Build 49.05 probes the actual Armoury GUI state machine that owns inventory,
typewriter, Save Game, and storage.

Build 49.06 uses the actual Armoury GUI state classes to distinguish inventory,
typewriter, storage, Save Game, and customization.

Build 49.07 narrows typewriter and storage visibility ownership to the exact
runtime states verified in-game.

Build 49.08 repairs the diagnostic counter crash without changing the verified
typewriter or storage state blockers.

Build 49.09 narrows the typewriter blocker to the verified
ArmouryGuiState_Close.onInit entry event.

Build 49.10 promotes the verified typewriter behavior-tree lifecycle to the
authoritative typewriter blocker.

Build 49.11 keeps the typewriter blocker latched after the player transition
ends and releases it only when the attaché workflow closes.

Build 49.12 separates the working typewriter behavior-hook status from the
obsolete legacy parent-menu resolver diagnostics.

Build 49.13 resolves typewriter behavior transitions in both directions instead
of retaining the latch after every onEnd callback.

Build 49.14 treats the typewriter behavior onStart callback as a blocked
transition state and waits for onEnd to resolve menu open versus closed.

Build 49.15 removes typewriter visibility ownership from behavior onStart and
retains only the onEnd manager-state resolution.

Build 49.16 inspects the Armoury hub child behaviors directly because CurrStep
only distinguishes Setup and Move.

Build 49.17 uses the real typewriter GUI lifecycle and repairs the native
Agility/Dexterity multiplier routing.

Build 49.18 removes one-frame progression flashes and adds direct storage GUI
lifecycle ownership.

Build 49.19 fixes Lua scope ordering in the speed system and adds direct
walk/run multiplier diagnostics for Agility.

Build 49.20 repairs the missing PlayerCommonParamUserData capture and provides
a direct-field Agility fallback when movement getters never execute.

Build 49.21 searches the live player object graph for movement userdata instead
of assuming it exists as a managed singleton.

Build 49.22 restores Action Speed's player source through the proven
PlayerCharacterContext update callback.

Build 49.23 captures movement userdata directly through
PlayerCommonParamUserData.onLoad.

Build 49.24 recovers already-loaded movement userdata with
sdk.get_managed_objects instead of waiting for onLoad to fire again.

Build 49.25 replaces the unavailable managed-object scan with direct live
PlayerCommonParamUserData accessor capture hooks.

Build 49.26 applies Agility through the live PlayerBodyUpdater motion-speed
getter used by active locomotion.

Build 49.27 restricts the live Agility multiplier to active walk/run movement.

Build 49.28 adds Agility Reload Speed and corrects the maximum Dexterity Fire
Rate from x1.249 to x1.250.

Build 49.29 applies Agility Reload Speed through the reload-specific behavior
tree action rate rather than shared animation motion.

Build 49.30 moves reload-speed application to the base behavior-tree lifecycle
that actually dispatches at runtime.

Build 49.31 adds applied reload-rate and normalized animation-duration
diagnostics.

Build 49.32 applies reload speed before and after native reload callbacks and
verifies the final field value.

Build 49.33 resolves the actual reload behavior-tree action object from the
hook argument list before applying reload speed.

Build 49.34 applies Agility Reload Speed to the reload behavior action's local
Motion layers when no MC reload-rate field exists.

Build 49.35 applies Agility Reload Speed through
chainsaw.Gun.get_ReloadSpeedRate(), the active weapon-facing scalar.

Build 49.36 prevents double application by making the direct Gun getter the
only active reload-speed path.

Build 49.37 permanently removes behavior-tree reload mutation and keeps only
the direct Gun reload-rate multiplier.

Build 49.38 displays Reload Time reduction and adds the missing Critical Chance
plus sign without changing gameplay behavior.


Build 49.65 maintenance audit:
- Reviewed every Lua and Markdown file.
- Added module classifications and compatibility/deprecation notes.
- Preserved all existing runtime functionality and import paths.

Build 49.65 fixes a Lua forward-reference error in the inventory progression
suppression helper.

Build 49.65 keeps the progression overlay blocked for the entire verified
storage session instead of allowing the short item-box heartbeat to expire.

Build 49.65 fixes the save-load movement multiplier forward-reference error.

Build 49.65 restores and clears movement state during native save loading so
Agility speed cannot leak between profiles.

Build 49.65 normalizes the previous save's retained PlayerBodyUpdater speed
during profile transitions and releases itself on a fresh native value.

Build 49.65 prevents a New Game started after quitting to the title screen from
inheriting the previous campaign's RPG progression.

Build 49.65 resets progression before New Game startup and delays all RPG
application until native character-save initialization.

Build 49.65 binds RPG progression to the actual live player instance and
resets a newly created character before its first autosave can capture stale
profile data.

Build 49.65 makes the progression panel Items-tab-only and blocks every other
attaché-case tab.

Build 49.65 restores the known-working Build 49.47 progression visuals and
removes the Build 49.48 tab-gating experiment.

Build 49.65 blocks progression on the Treasures screen through its own native
GUI lifecycle without changing the working progression visuals.

Build 49.65 blocks progression on the Map screen through MapManager's native
open, close, and GUI-open methods without changing the working visuals.

Build 49.65 blocks progression on the Files screen through FileManager phase
transitions without changing the working visuals.

Build 49.65 blocks progression on the Crafting screen through the dedicated
CraftWindowGuiBehavior lifecycle without changing the working visuals.

Build 49.65 rolls back all experimental post-49.49 menu blockers after they
caused launch crashes, restoring the known-working progression module.

Build 49.65 tests a low-risk Map blocker using a throttled singleton property
poll instead of native lifecycle hooks.

Build 49.65 adds a low-risk Files blocker using a throttled FileManager
CurrPhase poll, retaining the validated safe Map poll.

Build 49.65 removes the unsafe FileManager CurrPhase poll and restores the
validated Map-only blocker behavior from Build 49.55.

Build 49.65 tests a low-risk Keys & Treasures blocker using a throttled,
read-only managed-object scan while the attaché case is open.

Build 49.65 removes the unsafe Keys & Treasures object poll and restores the
validated Map-only blocker behavior from Build 49.57.

Build 49.65 tests Keys & Treasures suppression from the live Item Window
current-state object without native hooks.

Build 49.65 changes progression visibility to an Items-only whitelist based
on the live Item Window current-state class.

Build 49.65 removes the failed Items-state whitelist and restores Build 49.60
inventory progression behavior.

Build 49.65 uses the live numeric Item Window root-state enum for an
Items-only whitelist, with safe fallback when the value cannot be resolved.

Build 49.65 restores Map-only visibility and adds a diagnostic Item Window
state probe that does not control progression.

Build 49.65 displays the Item Window diagnostic values directly in the
REFramework UI instead of requiring a log file.

PATCH NOTES — ALPHA 0.2.1 | BUILD 49.81
========================================
- Added debugger sliders for every attribute's per-point effect at 0.001 steps.
- Added editable maximum clamps for derived stats and destructive testing.
- Fire rate above x2.0 is marked as crash-prone with the LE 5, TMP, and CQBR.
- Renamed One-time Recovery to RPG Profile Slot Recovery.
- Main-menu entry is detected through chainsaw.GameStateMainMenu lifecycle
  methods instead of player-reference heuristics.
- Entering the main menu clears the previous RPG profile once.
- _IsNewGameStart identifies a fresh campaign.
- Current main-menu phase and lifecycle state are exposed in diagnostics.
- Removed the player-absence frame counter and timer-driven profile resets.
- Continue, manual Load, autosave selection, delayed HitPoint recapture, and
  profile reconciliation retain their validated behavior.
- Refreshing project_overflow.lua reloads the active RPG profile through the
  normal delayed reconciliation path.
- Discovered Enemy Records is capped at the 10 most recent entries.
- One-time Recovery is always available for debugging and profile repair.

- Overflow bands now use exact 2,520-HP boundaries through 20,160 HP.
- Safe Total Cap is 20,160 HP.
- Health testing and overlay rendering are currently validated only through
  20,160 HP; higher debug values remain unvalidated.

- Strength keeps +0.005 damage per invested point.
- The default Strength damage cap is x2.500.
- Strength 250 (249 invested points) explicitly reaches the cap.

- Attribute per-point values and maximum clamps persist in
  data/project_overflow/attribute_balance.json.
- Slider edits save automatically and reload with the game or script.
- Restore Default Balance updates the JSON with shipped defaults.
- Reload Balance JSON applies manual file edits without restarting.

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

