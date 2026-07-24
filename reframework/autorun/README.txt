PROJECT: OVERFLOW
Resident Evil 4 Remake RPG Framework
Alpha 0.2.0 — Build 49.79
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

BIORAND COMPATIBILITY
---------------------
BioRand is optional. When using it, copy the active seed's generated
output_leon.log to:

reframework/data/project_overflow/manifests/output_leon.log

Replace this file whenever you generate or switch to a different BioRand seed.
Using a manifest from another seed can produce incorrect enemy names, families,
XP values, or reward data.

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

CREDITS
-------
Project: Overflow was created by StrainuousAki.

Special thanks to:
- praydog and the REFramework contributors
- IntelOrca for his programming and continued work on BioRand, including the
  Resident Evil 4 Remake randomizer
- re_duke for Resident Evil research, RDT documentation, and foundational work
  across the classic games, Resident Evil 4, and Resident Evil 2 Remake
- cursey, The Hitchhiker, alphaZomega, Bawkbasoup, GreenComfyTea, and the
  Resident Evil modding community
- friends and testers who contributed saves, logs, screenshots, bug reports,
  and playtesting

Project: Overflow is a fan-made modification and is not affiliated with or
endorsed by Capcom. All trademarks, characters, and original game assets belong
to their respective owners.

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
Alpha 0.2.0 — Build 48.38

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
