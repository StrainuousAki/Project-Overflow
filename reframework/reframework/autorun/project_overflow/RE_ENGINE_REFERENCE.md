# Project: Overflow — RE Engine Reference

## Documentation status

- **Reviewed for:** Build 49.81
- **Scope:** Compatibility mirror of docs/RE_ENGINE_REFERENCE.md
- **Status:** deprecated mirror
- **Compatibility rule:** Deprecated modules, calls, and probes remain documented and callable until a dedicated removal release.
- **Terminology:** “Deprecated” means supported legacy compatibility; “diagnostic-only” means it must not be treated as an authoritative gameplay path.


This file records RE4 Remake classes, fields, methods, enums, and behaviors observed while developing Project: Overflow.

It is a working reverse-engineering reference, not official Capcom documentation. Items marked **confirmed** were observed directly in-game. Items marked **probable** describe the most likely purpose based on behavior and naming.

## Native health objects

### `chainsaw.HitPointController`

**Target:** Player health storage and mutation.

Observed methods:

- `get_HitPoint()` — reads current HP.
- `get_MaxHitPoint()` — reads current Max HP.
- `set_HitPoint(value)` — writes current HP.
- `set_MaxHitPoint(value)` — writes Max HP.
- `get_IsDead()` — reads the controller's death state.

Project use:

- Captures current and maximum HP.
- Repairs Max HP upgrades after vanilla logic clamps them back to the normal cap.
- Supports manual damage, healing, and Max HP controls.

## Native health HUD

### `chainsaw.VitalGuiBehavior`

**Target:** Parent behavior/state machine for the native health HUD.

Observed fields/properties:

- `CurrStep`
- `RemainingDisplayTime`
- `_VitalConditionGuiOrg`
- `_VitalConditionGuiCol`

Observed methods:

- `lateUpdate()` — safe recurring capture point used by Project: Overflow.
- `changeStep(chainsaw.VitalGuiBehavior.Step next)` — changes the HUD behavior state.
- `onVitalChanged()` — probable response to HP changes.
- `update()` / `updateGauge()` — probable native HUD update pipeline.
- Lifecycle-like methods were present in reflection but were unsafe to hook directly in testing.

### `chainsaw.VitalGuiBehavior.Step`

**Confirmed enum values:**

| Value | Name | Observed meaning |
|---:|---|---|
| 0 | `Wait` | Idle/wait stage |
| 1 | `Move` | HUD moving or opening |
| 2 | `PreEnd` | Preparing to finish |
| 3 | `End` | End transition |
| 4 | `WaitEnd` | **Fully hidden** |

**Confirmed Project: Overflow gate:**

- Draw the overflow HUD for every valid step except `WaitEnd`.
- Hide the overflow HUD when `CurrStep == 4`.

## Condition and gauge GUI

### `chainsaw.VitalConditionGui`

**Target:** Native condition panel and health-gauge animation container.

Observed state enum:

| Value | Name |
|---:|---|
| -1 | `INVALID` |
| 0 | `FINE` |
| 1 | `FINE_TO_DANGER` |
| 2 | `FINE_TO_CAUTION` |
| 3 | `CAUTION` |
| 4 | `CAUTION_TO_FINE` |
| 5 | `CAUTION_TO_DANGER` |
| 6 | `DANGER` |
| 7 | `DANGER_TO_FINE` |
| 8 | `DANGER_TO_CAUTION` |

Observed methods/properties:

- `update(System.Single elapsedSec)`
- `preview(chainsaw.VitalGuiBehavior.HealPreviewParam)`
- `get_CurrState()`
- `setState(ConditionPanelState)`
- `set_CurrState(ConditionPanelState)` on some reflected builds/signatures
- `CurrFrame`
- `MemoryFrame`
- `VirtualMemoryFrame`
- `GradationFrame`
- `FrameDiff`

Observed child fields:

- `_VitalGaugeGui`
- `_VitalMaxGui`
- `_VitalDamageFlareGui`
- `_AmountGui`

Important behavior:

- Directly forcing condition state can interfere with the native damage/healing preview pipeline.
- Project: Overflow therefore keeps scaled condition math separate from native state writes.

### `chainsaw.VitalGaugeGui`

**Target:** Native current-health gauge animation.

Observed fields/properties:

- `CurrMaxFrame`
- `CurrTargetRate`
- `CurrRateDiff`
- `_RootPanel`
- `IsEnd` or equivalent reflected getter/field on the captured gauge path

Observed methods:

- `update(System.Single elapsedSec)`
- `updateGauge(System.Single frame)`

Observed runtime values used in diagnostics:

- `CurrRate`
- `CurrTargetRate`
- `CurrRateDiff`
- `CurrMaxFrame`
- `IsEnd`

Important behavior:

- These values drive native damage and healing interpolation.
- Per-frame writes to them should be avoided unless deliberately replacing Capcom's animation.

### `chainsaw.VitalDamageFlareGui`

**Target:** Native damage flare/trail presentation.

Observed methods:

- `setMaxFrame(...)`
- `setState(...)`

Project note:

- Hooks were useful for diagnostics but are disabled in the normal install because direct gauge/flare hooks can disturb native animations.

### `chainsaw.VitalMaxGui`

**Target:** Native Max HP display geometry.

Observed method:

- `setMaxFrame(...)`

### `chainsaw.VitalAmountGui.AmountStatusGui`

**Target:** Native amount/rate animation used by the circular gauge.

Observed methods/properties include:

- `set_CurrMaxFrame(float)`
- `set_CurrRate(float)`
- `set_CurrTargetRate(float)`
- `set_CurrRateDiff(float)`
- `set_CurrVirtualMinFrame(float)`
- `set_CurrVirtualMaxFrame(float)`
- `get_CurrState()`
- `get_FrameToAngleRate()`
- `get_CurrMaxAngle()`
- `get_CurrAngle()`
- `get_CurrTargetAngle()`
- `get_CurrRateDiff()`
- `get_CurrVirtualMinAngle()`
- `get_CurrVirtualMaxAngle()`
- `updateGauge()`

Measured values:

- Default `CurrRate` at 1260 Max HP: approximately `50.0`.
- Each additional 100 Max HP was observed to add approximately `3.968257904053` to `CurrRate`.
- `FrameToAngleRate` observed near `2.7000000476837`.

## Native GUI primitives

### `via.gui.Circle`

Observed methods:

- `set_ArcAngle(via.Float2)`
- `get_ArcAngle()`
- `set_Angle(via.Float2)`
- `set_ArcMinAngle(via.Float2)`
- `set_ArcMaxAngle(via.Float2)`
- `set_ArcMinMaxAngle(via.Float4)`

### `via.gui.Panel`

Observed inheritance chain:

- `via.gui.Panel`
- `via.gui.Capture`
- `via.gui.Control`
- `via.gui.TransformObject`
- `via.gui.PlayObject`
- `System.Object`

Reflection exposed few or no useful managed fields on the panel itself, suggesting much of its rendering state is native.

## Confirmed health limits and thresholds

Observed values during testing:

- Default new-save Max HP: `1260`.
- Vanilla herb-upgrade cap: `2500`.
- A small visual sliver suggested the display edge may be slightly above 2500.
- Highest observed forced Max HP accepted by native logic during early tests: `3360`.
- Project: Overflow custom safe cap is configurable and has been tested through `20000`.

Default modular condition ratios:

- Fine: above `50%`.
- Caution: above `25%` through `50%`.
- Danger: `25%` or below.

## Overlay renderer behavior

- Reference layout: `2560 x 1440`.
- Reference health-ring center and radius are stored in `context.lua`.
- `renderer.lua` queries the live ImGui/backbuffer resolution every draw.
- Positions are right/bottom anchored and scaled with `min(scaleX, scaleY)`.
- This live refresh fixed overlays that remained positioned for 2560x1440 after switching to 1920x1080.

## Safety notes

- Do not hook reflected `STUB` lifecycle methods without isolated testing; direct hooks caused a game crash.
- Do not use `RemainingDisplayTime` alone as a visibility flag; it remained at or below zero while the bar could still be active.
- Do not use `_RootPanel.Visible` alone; the panel can remain technically visible while the HUD is functionally hidden.
- Do not force native gauge rates every frame if preserving vanilla damage/healing previews.
- Keep experimental native condition writes disabled during normal play.

## Canonical location

This file is retained as a compatibility mirror. The canonical maintained copy is:

`project_overflow/docs/RE_ENGINE_REFERENCE.md`

New links and documentation references should target the canonical path.

## Deprecation and compatibility policy

Project: Overflow currently favors compatibility over deletion. Legacy module paths, fallback hooks, reflection probes, and debug counters remain available when they are useful for old profiles, external scripts, alternate characters, or future RE Engine changes.

Authoritative systems are named explicitly in the relevant documentation. New code should call those paths first. Deprecated paths should receive bug fixes only when required to preserve compatibility; they should not gain new gameplay responsibilities.
