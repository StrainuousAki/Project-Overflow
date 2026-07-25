------------------------------------------------------------
-- Maintenance classification — Build 49.39
-- Module: autorun/project_overflow/systems/health/runtime.lua
-- Role: Player health, overflow vitality, HUD synchronization, and runtime controls.
-- Status: active subsystem.
--
-- Compatibility policy:
--   Existing functions, hooks, module paths, and diagnostics are
--   intentionally retained in this maintenance pass.
--   `DEPRECATED` marks a supported legacy path, not removed code.
------------------------------------------------------------

------------------------------------------------------------
-- Project: Overflow — Runtime Updates
--
-- Advances overflow math, damage and healing trails, previews,
-- timers, and cached health values once per frame. This module
-- changes data; it does not draw the HUD.
------------------------------------------------------------

local updater = {}

local stat_application =
    require("project_overflow.systems.player.stat_application")
local action_speed =
    require("project_overflow.systems.player.action_speed")
local critical =
    require("project_overflow.systems.player.critical")

local function clamp01(value)
    value = tonumber(value) or 0.0

    return math.max(
        0.0,
        math.min(value, 1.0)
    )
end

local function move_toward(current, target, max_delta)
    current = tonumber(current) or 0.0
    target = tonumber(target) or 0.0
    max_delta = math.max(0.0, tonumber(max_delta) or 0.0)

    if current < target then
        return math.min(current + max_delta, target)
    end

    if current > target then
        return math.max(current - max_delta, target)
    end

    return target
end

local function refresh_health(ctx, hp)
    if hp == nil then
        return false
    end

    if hp.refresh_timed ~= nil then
        return hp.refresh_timed(ctx) == true
    end

    if hp.refresh_if_needed ~= nil then
        return hp.refresh_if_needed(ctx) == true
    end

    return false
end

local function reset_damage_transition(
    ctx,
    live_ratio,
    active_ring_index
)
    live_ratio = clamp01(live_ratio)

    ctx.state.overlay_last_ring_index =
        active_ring_index

    ctx.state.overlay_last_ratio =
        live_ratio

    ctx.state.overlay_damage_ratio =
        live_ratio

    ctx.state.overlay_damage_start_ratio =
        live_ratio

    ctx.state.overlay_damage_target_ratio =
        live_ratio

    ctx.state.overlay_damage_transition_speed =
        0.0

    ctx.state.overlay_damage_elapsed =
        0.0

    ctx.state.overlay_damage_active =
        false

    ctx.state.overlay_damage_live_ratio =
        live_ratio

    ctx.state.overlay_damage_initial_gap =
        0.0

    ctx.state.overlay_damage_current_gap =
        0.0

    ctx.state.overlay_damage_initial_gap_hp =
        0.0

    ctx.state.overlay_damage_current_gap_hp =
        0.0

    ctx.state.overlay_damage_derived_speed =
        0.0

    ctx.state.overlay_damage_progress =
        0.0

    ctx.state.overlay_damage_previous_ratio =
        live_ratio

    ctx.state.overlay_damage_measured_velocity =
        0.0
end

local function update_damage_diagnostics(
    ctx,
    live_ratio,
    previous_damage_ratio,
    delta_time
)
    local ring_capacity =
        math.max(
            1.0,
            tonumber(ctx.state.overflow_ring_hp) or 2520.0
        )

    local start_ratio =
        clamp01(ctx.state.overlay_damage_start_ratio)

    local target_ratio =
        clamp01(ctx.state.overlay_damage_target_ratio)

    local current_damage_ratio =
        clamp01(ctx.state.overlay_damage_ratio)

    local duration =
        math.max(
            0.001,
            tonumber(ctx.state.overlay_damage_duration) or 1.98
        )

    local initial_gap =
        math.max(
            0.0,
            start_ratio - target_ratio
        )

    local current_gap =
        math.max(
            0.0,
            current_damage_ratio - live_ratio
        )

    local measured_velocity = 0.0

    if delta_time > 0.000001 then
        measured_velocity =
            math.max(
                0.0,
                (
                    (tonumber(previous_damage_ratio) or current_damage_ratio) -
                    current_damage_ratio
                ) / delta_time
            )
    end

    ctx.state.overlay_damage_live_ratio =
        live_ratio

    ctx.state.overlay_damage_initial_gap =
        initial_gap

    ctx.state.overlay_damage_current_gap =
        current_gap

    ctx.state.overlay_damage_initial_gap_hp =
        initial_gap * ring_capacity

    ctx.state.overlay_damage_current_gap_hp =
        current_gap * ring_capacity

    ctx.state.overlay_damage_derived_speed =
        initial_gap / duration

    ctx.state.overlay_damage_measured_velocity =
        measured_velocity

    ctx.state.overlay_damage_progress =
        clamp01(
            (tonumber(ctx.state.overlay_damage_elapsed) or 0.0) /
            duration
        )

    ctx.state.overlay_damage_previous_ratio =
        current_damage_ratio
end

local function update_damage_state(ctx, delta_time)
    local live_ratio =
        clamp01(ctx.state.overflow_ratio)

    local active_ring_index =
        tonumber(
            ctx.state.overflow_active_ring_index
        ) or 0

    local previous_ring_index =
        tonumber(
            ctx.state.overlay_last_ring_index
        )

    local epsilon = 0.0001

    if previous_ring_index == nil then
        reset_damage_transition(
            ctx,
            live_ratio,
            active_ring_index
        )
        return
    end

    -- Crossing a 2500-HP ring boundary is not damage.
    if active_ring_index ~= previous_ring_index then
        reset_damage_transition(
            ctx,
            live_ratio,
            active_ring_index
        )
        return
    end

    local previous_live_ratio =
        clamp01(ctx.state.overlay_last_ratio)

    local previous_damage_ratio =
        clamp01(
            tonumber(ctx.state.overlay_damage_ratio)
            or previous_live_ratio
        )

    if live_ratio < previous_live_ratio - epsilon then
        -- Preserve whichever delayed endpoint is currently farther ahead.
        local start_ratio =
            math.max(
                previous_damage_ratio,
                previous_live_ratio
            )

        ctx.state.overlay_damage_start_ratio =
            start_ratio

        ctx.state.overlay_damage_target_ratio =
            live_ratio

        ctx.state.overlay_damage_ratio =
            start_ratio

        local duration =
            math.max(
                0.001,
                tonumber(
                    ctx.state.overlay_damage_duration
                ) or 1.98
            )

        ctx.state.overlay_damage_transition_speed =
            math.max(
                0.0,
                (start_ratio - live_ratio) /
                duration
            )

        ctx.state.overlay_damage_elapsed =
            0.0

        ctx.state.overlay_damage_active =
            true

    elseif live_ratio > previous_live_ratio + epsilon then
        -- Healing immediately clears the damage trail.
        reset_damage_transition(
            ctx,
            live_ratio,
            active_ring_index
        )
        return
    end

    ctx.state.overlay_last_ratio =
        live_ratio

    if ctx.state.overlay_damage_active ~= true then
        ctx.state.overlay_damage_ratio =
            live_ratio

        update_damage_diagnostics(
            ctx,
            live_ratio,
            previous_damage_ratio,
            delta_time
        )
        return
    end

    local duration =
        math.max(
            0.001,
            tonumber(ctx.state.overlay_damage_duration)
            or 1.98
        )

    ctx.state.overlay_damage_elapsed =
        (
            tonumber(ctx.state.overlay_damage_elapsed)
            or 0.0
        ) + delta_time

    local transition_speed =
        math.max(
            0.0,
            tonumber(
                ctx.state.overlay_damage_transition_speed
            ) or 0.0
        )

    if transition_speed <= 0.0 then
        local start_ratio =
            clamp01(
                ctx.state.overlay_damage_start_ratio
            )

        local target_ratio =
            clamp01(
                ctx.state.overlay_damage_target_ratio
            )

        transition_speed =
            math.max(
                0.0,
                (start_ratio - target_ratio) /
                duration
            )

        ctx.state.overlay_damage_transition_speed =
            transition_speed
    end

    -- Vanilla model: capture one constant speed from the initial
    -- damage gap. Small and large hits both finish in about 1.98 sec.
    ctx.state.overlay_damage_ratio =
        move_toward(
            tonumber(ctx.state.overlay_damage_ratio)
            or live_ratio,
            live_ratio,
            transition_speed * delta_time
        )

    local progress =
        clamp01(
            ctx.state.overlay_damage_elapsed /
            duration
        )

    update_damage_diagnostics(
        ctx,
        live_ratio,
        previous_damage_ratio,
        delta_time
    )

    if
        progress >= 1.0 or
        math.abs(
            (tonumber(ctx.state.overlay_damage_ratio) or live_ratio) -
            live_ratio
        ) <= epsilon
    then
        ctx.state.overlay_damage_ratio =
            live_ratio

        ctx.state.overlay_damage_start_ratio =
            live_ratio

        ctx.state.overlay_damage_target_ratio =
            live_ratio

        ctx.state.overlay_damage_transition_speed =
            0.0

        ctx.state.overlay_damage_elapsed =
            duration

        ctx.state.overlay_damage_active =
            false

        update_damage_diagnostics(
            ctx,
            live_ratio,
            previous_damage_ratio,
            delta_time
        )
    end
end

local function reset_heal_transition(
    ctx,
    live_ratio
)
    live_ratio = clamp01(live_ratio)

    ctx.state.overlay_heal_active =
        false

    ctx.state.overlay_heal_elapsed =
        0.0

    ctx.state.overlay_heal_start_ratio =
        live_ratio

    ctx.state.overlay_heal_target_ratio =
        live_ratio

    ctx.state.overlay_heal_ratio =
        live_ratio

    ctx.state.overlay_heal_transition_speed =
        0.0

    ctx.state.overlay_heal_initial_gap =
        0.0

    ctx.state.overlay_heal_current_gap =
        0.0

    ctx.state.overlay_heal_initial_gap_hp =
        0.0

    ctx.state.overlay_heal_current_gap_hp =
        0.0

    ctx.state.overlay_heal_progress =
        0.0

    ctx.state.overlay_heal_measured_velocity =
        0.0

    ctx.state.overlay_heal_previous_ratio =
        live_ratio
end

local function update_heal_diagnostics(
    ctx,
    previous_heal_ratio,
    delta_time
)
    local ring_capacity =
        math.max(
            1.0,
            tonumber(ctx.state.overflow_ring_hp) or 2520.0
        )

    local start_ratio =
        clamp01(ctx.state.overlay_heal_start_ratio)

    local target_ratio =
        clamp01(ctx.state.overlay_heal_target_ratio)

    local current_ratio =
        clamp01(ctx.state.overlay_heal_ratio)

    local duration =
        math.max(
            0.001,
            tonumber(ctx.state.overlay_heal_duration) or 1.98
        )

    local initial_gap =
        math.max(
            0.0,
            target_ratio - start_ratio
        )

    local current_gap =
        math.max(
            0.0,
            target_ratio - current_ratio
        )

    local measured_velocity = 0.0

    if delta_time > 0.000001 then
        measured_velocity =
            math.max(
                0.0,
                (
                    current_ratio -
                    (
                        tonumber(previous_heal_ratio)
                        or current_ratio
                    )
                ) /
                delta_time
            )
    end

    ctx.state.overlay_heal_initial_gap =
        initial_gap

    ctx.state.overlay_heal_current_gap =
        current_gap

    ctx.state.overlay_heal_initial_gap_hp =
        initial_gap * ring_capacity

    ctx.state.overlay_heal_current_gap_hp =
        current_gap * ring_capacity

    ctx.state.overlay_heal_progress =
        clamp01(
            (tonumber(ctx.state.overlay_heal_elapsed) or 0.0) /
            duration
        )

    ctx.state.overlay_heal_measured_velocity =
        measured_velocity

    ctx.state.overlay_heal_previous_ratio =
        current_ratio
end

local function update_heal_state(ctx, delta_time)
    local raw_current_hp =
        tonumber(ctx.state.current_hp) or 0

    local current_max_hp =
        tonumber(ctx.state.max_hp) or 0

    local capped_current_hp =
        current_max_hp > 0
        and math.min(raw_current_hp, current_max_hp)
        or raw_current_hp

    local overflow_start =
        tonumber(
            ctx.state.overflow_start_hp
        ) or 2500.0

    local ring_capacity =
        math.max(
            1.0,
            tonumber(
                ctx.state.overflow_ring_hp
            ) or 2500.0
        )

    local overflow_hp =
        math.max(
            0.0,
            capped_current_hp -
            overflow_start
        )

    local active_ring_index =
        math.floor(
            overflow_hp /
            ring_capacity
        )

    local hp_inside_ring =
        overflow_hp -
        (
            active_ring_index *
            ring_capacity
        )

    -- Exact multiples belong to the completed previous ring rather than
    -- becoming ratio 0 on a new empty ring. Example: 5000 HP with a
    -- 2500 overflow start/capacity should display ring 0 at 100%.
    if
        overflow_hp > 0.0 and
        hp_inside_ring <= 0.0001
    then
        active_ring_index =
            math.max(
                0,
                active_ring_index - 1
            )

        hp_inside_ring =
            ring_capacity
    end

    local live_ratio =
        clamp01(
            hp_inside_ring /
            ring_capacity
        )

    local event_serial =
        tonumber(ctx.state.heal_event_serial) or 0

    local consumed_serial =
        tonumber(
            ctx.state.heal_event_consumed_serial
        ) or 0

    local epsilon = 0.0001

    ------------------------------------------------------------
    -- Process a newly passed recovery(value) event
    ------------------------------------------------------------

    if event_serial ~= consumed_serial then
        ctx.state.heal_event_consumed_serial =
            event_serial

        local heal_value =
            math.max(
                0,
                tonumber(ctx.state.heal_event_value) or 0
            )

        local event_ring_index =
            tonumber(
                ctx.state.heal_event_start_ring_index
            ) or active_ring_index

        local event_start_ratio =
            clamp01(
                ctx.state.heal_event_start_ratio
            )

        -- recovery() updates native HP before this updater consumes the
        -- event. Therefore current_hp may already equal max_hp even though
        -- the visual heal must still animate from event_start_ratio.
        --
        -- Only treat the heal as redundant when the PRE-HEAL endpoint was
        -- already full, not when the post-recovery native value is full.
        local was_full_before_heal =
            event_start_ratio >=
            1.0 - epsilon

        local active_target_is_full =
            ctx.state.overlay_heal_active == true and
            clamp01(
                ctx.state.overlay_heal_target_ratio
            ) >= 1.0 - epsilon

        -- Ignore healing that began at full HP, or additional healing
        -- while an existing visual transition already targets full HP.
        if
            heal_value <= 0 or
            was_full_before_heal or
            active_target_is_full
        then
            ctx.state.heal_event_value = 0

        else

            -- Cross-ring healing is still reset safely until stacked-ring
            -- healing transitions are implemented.
            if event_ring_index ~= active_ring_index then
                reset_heal_transition(
                    ctx,
                    live_ratio
                )

            else
                local start_ratio =
                    event_start_ratio

                if ctx.state.overlay_heal_active == true then
                    start_ratio =
                        clamp01(
                            ctx.state.overlay_heal_ratio
                        )
                end

                -- recovery() may briefly report HP above Max HP.
                -- live_ratio is already derived from min(current_hp, max_hp),
                -- so an oversized heal targets the cap without rolling into
                -- another ring or shortening the transition.
                local target_ratio =
                    clamp01(live_ratio)

                if target_ratio > start_ratio + epsilon then
                    local duration =
                        math.max(
                            0.001,
                            tonumber(
                                ctx.state.overlay_heal_duration
                            ) or 1.98
                        )

                    ctx.state.overlay_heal_start_ratio =
                        start_ratio

                    ctx.state.overlay_heal_target_ratio =
                        target_ratio

                    ctx.state.overlay_heal_ratio =
                        start_ratio

                    ctx.state.overlay_heal_transition_speed =
                        math.max(
                            0.0,
                            (
                                target_ratio -
                                start_ratio
                            ) /
                            duration
                        )

                    ctx.state.overlay_heal_elapsed =
                        0.0

                    ctx.state.overlay_heal_active =
                        true

                    -- A real heal supersedes any delayed damage trail.
                    reset_damage_transition(
                        ctx,
                        live_ratio,
                        active_ring_index
                    )
                else
                    reset_heal_transition(
                        ctx,
                        live_ratio
                    )
                end
            end
        end
    end

    ------------------------------------------------------------
    -- No active visual healing transition
    ------------------------------------------------------------

    if ctx.state.overlay_heal_active ~= true then
        ctx.state.overlay_heal_ratio =
            live_ratio
        return
    end

    ------------------------------------------------------------
    -- Damage during healing cancels the upward transition
    ------------------------------------------------------------

    if
        live_ratio <
        clamp01(ctx.state.overlay_heal_target_ratio) -
        epsilon
    then
        reset_heal_transition(
            ctx,
            live_ratio
        )
        return
    end

    ------------------------------------------------------------
    -- Vanilla-style constant-duration healing
    ------------------------------------------------------------

    local duration =
        math.max(
            0.001,
            tonumber(ctx.state.overlay_heal_duration) or 1.98
        )

    local previous_heal_ratio =
        clamp01(ctx.state.overlay_heal_ratio)

    ctx.state.overlay_heal_elapsed =
        (
            tonumber(ctx.state.overlay_heal_elapsed)
            or 0.0
        ) + delta_time

    local transition_speed =
        math.max(
            0.0,
            tonumber(
                ctx.state.overlay_heal_transition_speed
            ) or 0.0
        )

    if transition_speed <= 0.0 then
        transition_speed =
            math.max(
                0.0,
                (
                    clamp01(
                        ctx.state.overlay_heal_target_ratio
                    ) -
                    clamp01(
                        ctx.state.overlay_heal_start_ratio
                    )
                ) /
                duration
            )

        ctx.state.overlay_heal_transition_speed =
            transition_speed
    end

    ctx.state.overlay_heal_ratio =
        move_toward(
            previous_heal_ratio,
            clamp01(ctx.state.overlay_heal_target_ratio),
            transition_speed * delta_time
        )

    update_heal_diagnostics(
        ctx,
        previous_heal_ratio,
        delta_time
    )

    local progress =
        clamp01(
            ctx.state.overlay_heal_elapsed /
            duration
        )

    local reached_target =
        math.abs(
            clamp01(ctx.state.overlay_heal_ratio) -
            clamp01(ctx.state.overlay_heal_target_ratio)
        ) <= epsilon

    local reached_full_hp =
        clamp01(ctx.state.overlay_heal_ratio) >=
        1.0 - epsilon

    if
        progress >= 1.0 or
        reached_target or
        reached_full_hp
    then
        ctx.state.overlay_heal_ratio =
            clamp01(
                ctx.state.overlay_heal_target_ratio
            )

        ctx.state.overlay_heal_elapsed =
            duration

        ctx.state.overlay_heal_transition_speed =
            0.0

        ctx.state.overlay_heal_active =
            false

        ctx.state.heal_event_value =
            0

        update_heal_diagnostics(
            ctx,
            previous_heal_ratio,
            delta_time
        )
    end
end

local function update_preview_pulse(ctx, delta_time)
    if ctx.state.overlay_preview_active ~= true then
        ctx.state.overlay_preview_pulse_time = 0.0
        return
    end

    ctx.state.overlay_preview_pulse_time =
        (
            tonumber(ctx.state.overlay_preview_pulse_time)
            or 0.0
        ) + delta_time
end

local function overflow_position(ctx, total_hp)
    total_hp =
        math.max(
            0,
            tonumber(total_hp) or 0
        )

    local overflow_start =
        tonumber(ctx.state.overflow_start_hp) or 2520

    local ring_capacity =
        tonumber(ctx.state.overflow_ring_hp) or 2520

    if ring_capacity <= 0 then
        ring_capacity = 2520
    end

    local overflow_hp =
        math.max(
            0,
            total_hp - overflow_start
        )

    local ring_index =
        math.floor(
            overflow_hp / ring_capacity
        )

    local ring_hp =
        overflow_hp % ring_capacity

    local ratio =
        ring_hp / ring_capacity

    if
        overflow_hp > 0 and
        ring_hp == 0
    then
        ring_index =
            math.max(
                0,
                ring_index - 1
            )

        ratio = 1.0
    end

    return ring_index, clamp01(ratio)
end

local function update_preview_state(ctx)
    if ctx.state.overlay_preview_active ~= true then
        ctx.state.overlay_preview_heal_ratio = 0.0
        ctx.state.overlay_preview_max_ratio = 0.0
        ctx.state.overlay_preview_total_ratio = 0.0
        return
    end

    local current_hp =
        tonumber(ctx.state.preview_current_hp)
        or tonumber(ctx.state.current_hp)
        or 0

    local current_max_hp =
        tonumber(ctx.state.preview_current_max_hp)
        or tonumber(ctx.state.max_hp)
        or 0

    local heal_gain =
        math.max(
            0,
            tonumber(ctx.state.overlay_preview_heal_hp)
            or 0
        )

    local max_gain =
        math.max(
            0,
            tonumber(ctx.state.overlay_preview_max_hp)
            or 0
        )

    local projected_max_hp =
        math.min(
            current_max_hp + max_gain,
            ctx.active_total_cap()
        )

    local projected_current_hp =
        math.min(
            current_hp + heal_gain,
            projected_max_hp
        )

    local active_ring_index =
        tonumber(ctx.state.overflow_active_ring_index)
        or 0

    local current_max_ring,
          current_max_ratio =
        overflow_position(
            ctx,
            current_max_hp
        )

    local projected_max_ring,
          projected_max_ratio =
        overflow_position(
            ctx,
            projected_max_hp
        )

    local projected_current_ring,
          projected_current_ratio =
        overflow_position(
            ctx,
            projected_current_hp
        )

    ctx.state.overlay_preview_max_ratio =
        projected_max_ring == active_ring_index
        and projected_max_ratio
        or 0.0

    ctx.state.overlay_preview_heal_ratio =
        projected_current_ring == active_ring_index
        and projected_current_ratio
        or 0.0

    -- Kept as compatibility with the current overlay.
    ctx.state.overlay_preview_total_ratio =
        ctx.state.overlay_preview_heal_ratio

    ctx.state.overlay_current_max_ratio =
        current_max_ring == active_ring_index
        and current_max_ratio
        or 0.0
end

local function update_visibility_state(ctx, delta_time)
    local current_hp =
        ctx.current_hp_number ~= nil
        and ctx.current_hp_number()
        or nil

    local max_hp =
        ctx.max_hp_number ~= nil
        and ctx.max_hp_number()
        or nil

    local hp_changed =
        current_hp ~= ctx.state.overlay_last_current_hp
        or
        max_hp ~= ctx.state.overlay_last_max_hp

    if hp_changed then
        ctx.state.overlay_last_current_hp = current_hp
        ctx.state.overlay_last_max_hp = max_hp

        ctx.state.overlay_hold_timer =
            tonumber(ctx.state.overlay_hold_time) or 2.0
    end

    local hold_timer =
        tonumber(ctx.state.overlay_hold_timer) or 0.0

    if hold_timer > 0.0 then
        ctx.state.overlay_hold_timer =
            math.max(0.0, hold_timer - delta_time)
    end

    local overflow_max =
        tonumber(ctx.state.overflow_max) or 0.0

    local should_show =
        ctx.state.overlay_enabled == true
        and overflow_max > 0.0
        and ctx.state.overlay_hold_timer > 0.0

    ctx.state.overlay_target_alpha =
        should_show and 1.0 or 0.0

    local current_alpha =
        tonumber(ctx.state.overlay_alpha) or 0.0

    local target_alpha =
        tonumber(ctx.state.overlay_target_alpha) or 0.0

    local fade_speed

    if target_alpha > current_alpha then
        fade_speed =
            tonumber(ctx.state.overlay_fade_in_speed) or 5.0
    else
        fade_speed =
            tonumber(ctx.state.overlay_fade_out_speed) or 3.0
    end

    ctx.state.overlay_alpha = move_toward(
        current_alpha,
        target_alpha,
        fade_speed * delta_time
    )
end

function updater.update(ctx, hp, delta_time)
    delta_time =
        tonumber(delta_time) or (1.0 / 60.0)

    refresh_health(ctx, hp)

    action_speed.update(ctx)
    critical.update()

    stat_application.update(
        ctx,
        hp
    )

    local current_hp =
        tonumber(ctx.state.current_hp) or 0.0

    local current_max_hp =
        tonumber(ctx.state.max_hp) or 0.0

    local background_threshold =
        tonumber(
            ctx.state.overlay_bg_alpha_threshold_hp
        ) or 2500.0

    local active_ring_index =
        tonumber(
            ctx.state.overflow_active_ring_index
        ) or 0

    local hide_ring_one_over_vanilla =
        active_ring_index == 0 and
        current_hp <= background_threshold

    local hide_before_overflow_unlock =
        current_max_hp <= background_threshold

    local force_background_hidden =
        ctx.state.overlay_bg_auto_alpha == true and
        (
            hide_ring_one_over_vanilla or
            hide_before_overflow_unlock
        )

    ctx.state.overlay_bg_unlock_max_hp =
        current_max_hp

    ctx.state.overlay_bg_forced_hidden =
        force_background_hidden

    ctx.state.overlay_bg_effective_alpha =
        force_background_hidden
        and 0
        or (
            tonumber(ctx.ui.overlay_bg_a)
            or 0
        )

    -- Ensure the transition always reads the latest cached HP math.
    ctx.update_overflow_math()

    update_damage_state(ctx, delta_time)
    update_heal_state(ctx, delta_time)
    update_preview_state(ctx)
    update_preview_pulse(ctx, delta_time)
    update_visibility_state(ctx, delta_time)
end

return updater
