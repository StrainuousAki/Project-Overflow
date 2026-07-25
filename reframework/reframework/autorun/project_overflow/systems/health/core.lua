------------------------------------------------------------
-- Maintenance classification — Build 49.39
-- Module: autorun/project_overflow/systems/health/core.lua
-- Role: Player health, overflow vitality, HUD synchronization, and runtime controls.
-- Status: active subsystem.
--
-- Compatibility policy:
--   Existing functions, hooks, module paths, and diagnostics are
--   intentionally retained in this maintenance pass.
--   `DEPRECATED` marks a supported legacy path, not removed code.
------------------------------------------------------------

------------------------------------------------------------
-- Project: Overflow — Health Integration
--
-- Captures the player and native HitPoint objects, repairs Max HP
-- changes above the vanilla cap, reads native HUD state, and keeps
-- experimental RE Engine hooks isolated from the renderer.
------------------------------------------------------------

local rpg = require("project_overflow.systems.player.rpg")
local hp = {}
local push_scoped_field_override
local intelligence_preview_cache = {}

local function expected_heal_value(native_heal)
    local multiplier =
        tonumber(rpg.derived_stats().healing_multiplier) or 1.0
    local expected = math.max(
        0,
        math.floor((tonumber(native_heal) or 0) * multiplier + 0.5)
    )
    return expected, multiplier
end

local function ensure_refresh_state(ctx)
    ctx.health_refresh = ctx.health_refresh or {}

    if ctx.health_refresh.dirty == nil then
        ctx.health_refresh.dirty = true
    end

    ctx.health_refresh.last_refresh =
        tonumber(ctx.health_refresh.last_refresh) or 0.0

    ctx.health_refresh.fallback_interval =
        tonumber(ctx.health_refresh.fallback_interval) or 1.0

    ctx.health_refresh.refresh_count =
        tonumber(ctx.health_refresh.refresh_count) or 0
end

local function mark_hp_dirty(ctx)
    ensure_refresh_state(ctx)
    ctx.health_refresh.dirty = true
end

function hp.mark_dirty(ctx)
    mark_hp_dirty(ctx)
end

-- A native load replaces the live player/HitPoint instances. Keeping the
-- previous managed object here makes refresh() successfully read stale HP
-- forever, even though the newly loaded player is already active. Invalidate
-- both sides of the binding at the load event, then let the existing player
-- and HitPoint hooks capture the new instances before RPG stat reconciliation.
function hp.clear_player_state(ctx, reason)
    ctx.state.player = nil
    ctx.state.player_ptr = "nil"
    ctx.state.player_type = "unknown"

    hp.clear_capture(
        ctx,
        reason or "no active player; health state cleared"
    )
end

function hp.begin_native_load(ctx)
    hp.clear_player_state(
        ctx,
        "native load completed; waiting for fresh player HitPoint"
    )
end

local function capture_player(ctx, obj, source)
    if obj == nil or not ctx.is_player_type(obj) then
        return false
    end

    local new_ptr =
        ctx.ptr_from_obj(obj)

    local old_ptr =
        ctx.state.player_ptr

    local player_changed =
        old_ptr ~= nil and
        old_ptr ~= "nil" and
        new_ptr ~= old_ptr

    ctx.state.player = obj
    ctx.state.player_ptr = new_ptr
    ctx.state.player_type =
        ctx.type_name_from_obj(obj)

    ctx.state.status =
        source or "captured player"

    if player_changed then
        hp.clear_capture(
            ctx,
            "player changed; recapturing HitPoint"
        )
    end

    ctx.clear_error()
    return true
end

local function reset_overlay_health_state(ctx)
    local live_ratio =
        tonumber(ctx.state.overflow_ratio) or 0.0

    ctx.state.overlay_last_ratio = nil
    ctx.state.overlay_last_ring_index = nil

    ctx.state.overlay_damage_ratio = live_ratio
    ctx.state.overlay_damage_active = false

    ctx.state.overlay_damage_elapsed = 0.0
    ctx.state.overlay_damage_start_ratio = live_ratio
    ctx.state.overlay_damage_target_ratio = live_ratio
    ctx.state.overlay_damage_transition_speed = 0.0

    ctx.state.overlay_damage_live_ratio = live_ratio
    ctx.state.overlay_damage_initial_gap = 0.0
    ctx.state.overlay_damage_current_gap = 0.0
    ctx.state.overlay_damage_initial_gap_hp = 0.0
    ctx.state.overlay_damage_current_gap_hp = 0.0
    ctx.state.overlay_damage_derived_speed = 0.0
    ctx.state.overlay_damage_progress = 0.0
    ctx.state.overlay_damage_previous_ratio = live_ratio
    ctx.state.overlay_damage_measured_velocity = 0.0

    ctx.state.overlay_heal_active = false
    ctx.state.overlay_heal_elapsed = 0.0
    ctx.state.overlay_heal_start_ratio = live_ratio
    ctx.state.overlay_heal_target_ratio = live_ratio
    ctx.state.overlay_heal_ratio = live_ratio
    ctx.state.overlay_heal_transition_speed = 0.0

    ctx.state.overlay_heal_initial_gap = 0.0
    ctx.state.overlay_heal_current_gap = 0.0
    ctx.state.overlay_heal_initial_gap_hp = 0.0
    ctx.state.overlay_heal_current_gap_hp = 0.0
    ctx.state.overlay_heal_progress = 0.0
    ctx.state.overlay_heal_measured_velocity = 0.0
    ctx.state.overlay_heal_previous_ratio = live_ratio

    ctx.state.heal_event_consumed_serial =
        tonumber(ctx.state.heal_event_serial) or 0

    ctx.state.overlay_last_current_hp = nil
    ctx.state.overlay_last_max_hp = nil
end

local function clear_preview_state(ctx)
    ctx.state.preview_heal = "unknown"
    ctx.state.preview_hp_up = "unknown"

    ctx.state.preview_current_hp = 0
    ctx.state.preview_current_max_hp = 0

    ctx.state.preview_native_previous_max_hp = 0
    ctx.state.preview_native_current_hp = 0
    ctx.state.preview_native_max_hp = 0
    ctx.state.preview_native_projected_max_hp = 0

    ctx.state.preview_last_arg_types =
        ctx.state.preview_last_arg_types or {}

    ctx.state.preview_condition_type = "unknown"
    ctx.state.preview_condition_ptr = "nil"

    ctx.state.preview_gui_prev_max_hp = 0
    ctx.state.preview_gui_curr_max_hp = 0
    ctx.state.preview_gui_curr_frame = 0.0
    ctx.state.preview_gui_curr_max_frame = 0.0
    ctx.state.preview_gui_memory_frame = 0.0
    ctx.state.preview_gui_virtual_memory_frame = 0.0

    ctx.state.overlay_preview_heal_hp = 0
    ctx.state.overlay_preview_max_hp = 0
    ctx.state.overlay_preview_overflow_start_hp = 0
    ctx.state.overlay_preview_overflow_end_hp = 0
    ctx.state.overlay_preview_overflow_heal_hp = 0

    ctx.state.overlay_preview_heal_ratio = 0.0
    ctx.state.overlay_preview_max_ratio = 0.0
    ctx.state.overlay_preview_total_ratio = 0.0

    ctx.state.preview_custom_max_hp_gain = 0
    ctx.state.preview_corrected_max_hp_gain = 0
    ctx.state.preview_projected_max_hp = 0
    ctx.state.preview_max_gain_source = "none"

    ctx.state.max_hp_preview_active = false
    ctx.state.max_hp_preview_native_hp_up = 0
    ctx.state.max_hp_preview_corrected_gain = 0
    ctx.state.max_hp_preview_projected_max_hp = 0
    ctx.state.max_hp_preview_repair_required = false

    ctx.state.overlay_preview_active = false
end

function hp.clear_capture(ctx, reason)
    ctx.state.hitpoint = nil
    ctx.state.hitpoint_ptr = "nil"
    ctx.state.hitpoint_type = "unknown"

    ctx.state.current_hp = "unknown"
    ctx.state.max_hp = "unknown"
    ctx.state.hp_ratio = "unknown"

    reset_overlay_health_state(ctx)
    clear_preview_state(ctx)

    ctx.health_refresh = ctx.health_refresh or {}
    ctx.health_refresh.dirty = true
    ctx.health_refresh.last_refresh = 0.0

    ctx.state.status =
        reason or "waiting to recapture player HitPoint"
end

local function capture_hitpoint(ctx, obj, source)
    if obj == nil or not ctx.is_hitpoint_type(obj) then
        return false
    end

    local new_ptr =
        ctx.ptr_from_obj(obj)

    local old_ptr =
        ctx.state.hitpoint_ptr

    if
        ctx.state.hitpoint ~= nil and
        old_ptr ~= nil and
        old_ptr ~= "nil" and
        new_ptr ~= old_ptr
    then
        -- Never let an enemy HitPoint replace the established
        -- player HitPoint.
        return false
    end

    local first_capture =
        ctx.state.hitpoint == nil

    ctx.state.hitpoint = obj
    ctx.state.hitpoint_ptr = new_ptr
    ctx.state.hitpoint_type =
        ctx.type_name_from_obj(obj)

    ctx.state.status =
        source or "captured player HitPoint"

    if first_capture then
        reset_overlay_health_state(ctx)
        mark_hp_dirty(ctx)
    end

    ctx.clear_error()
    return true
end

local function capture_hitpoint_from_args(
    ctx,
    args,
    allow_replace
)
    allow_replace = allow_replace == true

    -- Mutation hooks must never replace an established player HitPoint
    -- with an enemy HitPoint.
    if
        ctx.state.hitpoint ~= nil and
        not allow_replace
    then
        return false
    end

    for index = 1, 5 do
        local obj =
            ctx.managed_from_arg(args, index)

        if
            obj ~= nil and
            ctx.is_hitpoint_type(obj)
        then
            return capture_hitpoint(
                ctx,
                obj,
                "captured HitPoint safely"
            )
        end
    end

    return false
end

function hp.refresh(ctx)
    if ctx.state.hitpoint == nil then
        return false
    end

    local ok, err = pcall(function()
        if ctx.methods.hp_get_current ~= nil then
            ctx.state.current_hp =
                tostring(
                    ctx.methods.hp_get_current:call(
                        ctx.state.hitpoint
                    )
                )
        end

        local max_getter =
            ctx.methods.hp_get_max or
            ctx.methods.hp_get_default

        if max_getter ~= nil then
            ctx.state.max_hp =
                tostring(
                    max_getter:call(
                        ctx.state.hitpoint
                    )
                )
        end

        if ctx.methods.hp_get_ratio ~= nil then
            ctx.state.hp_ratio =
                tostring(
                    ctx.methods.hp_get_ratio:call(
                        ctx.state.hitpoint
                    )
                )
        end

        -- HitPointRatio can remain based on DefaultHitPoint after a native
        -- load. The authoritative ratio is the live current value divided by
        -- the live MaxHitPoint value read above.
        local live_current = tonumber(ctx.state.current_hp)
        local live_max = tonumber(ctx.state.max_hp)
        if live_current ~= nil and live_max ~= nil and live_max > 0 then
            ctx.state.hp_ratio = tostring(
                math.max(0.0, math.min(live_current / live_max, 1.0))
            )
        end

        ctx.update_overflow_math()
    end)

    if not ok then
        ctx.set_error(err)
        return false
    end

    return true
end

function hp.refresh_if_needed(ctx)
    ensure_refresh_state(ctx)

    local refresh_state = ctx.health_refresh
    local now = os.clock()

    local fallback_due =
        now - refresh_state.last_refresh >=
        refresh_state.fallback_interval

    if not refresh_state.dirty and not fallback_due then
        return false
    end

    local refreshed = hp.refresh(ctx)

    if refreshed then
        refresh_state.dirty = false
        refresh_state.last_refresh = now
        refresh_state.refresh_count =
            refresh_state.refresh_count + 1

        if ctx.timing ~= nil then
            ctx.timing.last_hp_refresh = now
        end
    end

    return refreshed
end

function hp.add_max(ctx, amount)
    ctx.clear_error()

    local current_max = ctx.max_hp_number()

    if current_max ~= nil then
        local target = ctx.clamp(
            current_max + amount,
            ctx.state.min_custom_max_hp,
            ctx.active_total_cap()
        )

        amount = target - current_max
    end

    if amount == 0 then
        mark_hp_dirty(ctx)
        hp.refresh(ctx)
        return true
    end

    if ctx.state.hitpoint ~= nil and ctx.methods.hp_add_max ~= nil then
        local ok, err = pcall(function()
            ctx.methods.hp_add_max:call(
                ctx.state.hitpoint,
                amount
            )
        end)

        if not ok then
            ctx.set_error(err)
            return false
        end

        mark_hp_dirty(ctx)
        hp.refresh(ctx)
        return true
    end

    if ctx.state.player ~= nil and ctx.methods.player_add_max_hp ~= nil then
        local ok, err = pcall(function()
            ctx.methods.player_add_max_hp:call(
                ctx.state.player,
                amount
            )
        end)

        if not ok then
            ctx.set_error(err)
            return false
        end

        mark_hp_dirty(ctx)
        hp.refresh(ctx)
        return true
    end

    ctx.set_error(
        "No valid HitPoint or Player max HP method captured yet."
    )

    return false
end

function hp.heal(ctx, amount)
    ctx.clear_error()

    if ctx.state.hitpoint == nil or ctx.methods.hp_recovery == nil then
        ctx.set_error("No chainsaw.HitPoint captured yet.")
        return
    end

    local ok, err = pcall(function()
        ctx.methods.hp_recovery:call(
            ctx.state.hitpoint,
            amount
        )
    end)

    if not ok then
        ctx.set_error(err)
        return
    end

    mark_hp_dirty(ctx)
end

function hp.damage(ctx, amount)
    ctx.clear_error()

    if ctx.state.hitpoint == nil or ctx.methods.hp_add_damage == nil then
        ctx.set_error("No chainsaw.HitPoint captured yet.")
        return
    end

    local ok, err = pcall(function()
        ctx.methods.hp_add_damage:call(
            ctx.state.hitpoint,
            amount
        )
    end)

    if not ok then
        ctx.set_error(err)
        return
    end

    mark_hp_dirty(ctx)
end

function hp.set_current(ctx, value)
    ctx.clear_error()

    local current = ctx.current_hp_number()
    local max_hp = ctx.max_hp_number()

    if current == nil or max_hp == nil then
        ctx.set_error("Current or max HP unknown.")
        return
    end

    value = ctx.clamp(value, 1, max_hp)

    local delta = value - current

    if delta > 0 then
        hp.heal(ctx, delta)
    elseif delta < 0 then
        hp.damage(ctx, -delta)
    else
        mark_hp_dirty(ctx)
    end
end

function hp.set_max(ctx, value)
    ctx.clear_error()

    local current_max = ctx.max_hp_number()

    if current_max == nil then
        ctx.set_error("Max HP unknown.")
        return false
    end

    value = math.floor(
        ctx.clamp(
            value,
            ctx.state.min_custom_max_hp,
            ctx.active_total_cap()
        ) + 0.5
    )

    current_max = math.floor(current_max + 0.5)

    if current_max == value then
        mark_hp_dirty(ctx)
        hp.refresh(ctx)
        return true
    end

    -- Prefer the absolute native setter for derived RPG stats. Using only
    -- addMaxHitPoint made failed writes indistinguishable from successful
    -- writes, allowing stat_application to persist values that never reached
    -- gameplay.
    if
        ctx.state.hitpoint ~= nil and
        ctx.methods.hp_set_max ~= nil
    then
        local ok, err = pcall(function()
            ctx.methods.hp_set_max:call(
                ctx.state.hitpoint,
                value
            )
        end)

        if not ok then
            ctx.set_error(err)
        else
            mark_hp_dirty(ctx)
            hp.refresh(ctx)

            local applied =
                math.floor(
                    (ctx.max_hp_number() or 0) + 0.5
                )

            if applied == value then
                return true
            end
        end
    end

    local changed =
        hp.add_max(
            ctx,
            value - current_max
        )

    if changed ~= true then
        return false
    end

    hp.refresh(ctx)

    local applied =
        math.floor(
            (ctx.max_hp_number() or 0) + 0.5
        )

    if applied ~= value then
        ctx.set_error(
            string.format(
                "Max HP write failed verification: expected %d, got %d.",
                value,
                applied
            )
        )

        return false
    end

    return true
end

function hp.full_heal(ctx)
    local max_hp = ctx.max_hp_number()

    if max_hp == nil then
        ctx.set_error("Max HP unknown.")
        return
    end

    hp.set_current(ctx, max_hp)
end

function hp.reset_default(ctx)
    hp.set_max(ctx, ctx.state.default_max_hp)
end

function hp.reset_vanilla(ctx)
    hp.set_max(ctx, ctx.state.vanilla_max_hp_cap)
end

local function begin_max_hp_commit_repair(ctx, gain)
    local state = ctx.state

    state.max_hp_commit_pending = false
    state.max_hp_commit_active = false
    state.max_hp_commit_last_error = ""

    if
        state.max_hp_commit_repair_enabled ~= true or
        gain <= 0
    then
        state.max_hp_commit_skip_count =
            (tonumber(state.max_hp_commit_skip_count) or 0) + 1

        return nil
    end

    hp.refresh(ctx)

    local before_current =
        tonumber(ctx.current_hp_number()) or 0

    local before_max =
        tonumber(ctx.max_hp_number()) or 0

    local expected_max =
        math.min(
            before_max + gain,
            ctx.active_total_cap()
        )

    local preview_heal =
        tonumber(ctx.state.preview_heal) or 0

    local expected_current =
        before_current

    if ctx.state.max_hp_preview_active == true then
        expected_current =
            math.min(
                before_current + math.max(0, preview_heal),
                expected_max
            )
    end

    state.max_hp_commit_before = before_max
    state.max_hp_commit_gain = gain
    state.max_hp_commit_expected = expected_max
    state.max_hp_commit_before_current = before_current
    state.max_hp_commit_expected_current = expected_current
    state.max_hp_commit_last_source =
        "PlayerHeadUpdater.addMaxHitPoint"

    state.max_hp_commit_pending = true
    state.max_hp_commit_active = true

    return {
        before_current = before_current,
        before_max = before_max,
        gain = gain,
        expected_max = expected_max,
        expected_current = expected_current
    }
end

local function finish_max_hp_commit_repair(ctx, pending)
    local state = ctx.state

    if pending == nil then
        state.max_hp_commit_active = false
        return
    end

    mark_hp_dirty(ctx)
    hp.refresh(ctx)

    local native_current =
        tonumber(ctx.current_hp_number()) or 0

    local native_max =
        tonumber(ctx.max_hp_number()) or 0

    state.max_hp_commit_native_after = native_max
    state.max_hp_commit_native_current_after = native_current

    if native_max < pending.expected_max then
        local missing_max =
            pending.expected_max - native_max

        hp.add_max(
            ctx,
            missing_max
        )

        mark_hp_dirty(ctx)
        hp.refresh(ctx)

        local repaired_max =
            tonumber(ctx.max_hp_number()) or native_max

        if repaired_max < pending.expected_max then
            state.max_hp_commit_last_error =
                string.format(
                    "Max HP repair incomplete: expected %d, got %d",
                    pending.expected_max,
                    repaired_max
                )
        else
            hp.set_current(
                ctx,
                math.min(
                    pending.expected_current,
                    repaired_max
                )
            )

            mark_hp_dirty(ctx)
            hp.refresh(ctx)

            state.max_hp_commit_apply_count =
                (tonumber(state.max_hp_commit_apply_count) or 0) + 1
        end
    else
        state.max_hp_commit_skip_count =
            (tonumber(state.max_hp_commit_skip_count) or 0) + 1
    end

    state.max_hp_commit_corrected_after =
        tonumber(ctx.max_hp_number()) or 0

    state.max_hp_commit_corrected_current_after =
        tonumber(ctx.current_hp_number()) or 0

    state.max_hp_commit_pending = false
    state.max_hp_commit_active = false
end

local function install_player_hook(ctx)
    if ctx.state.player_hook_installed then
        return
    end

    local ok, err = pcall(function()
        local td =
            sdk.find_type_definition(
                "chainsaw.PlayerHeadUpdater"
            )

        if td == nil then
            error("No chainsaw.PlayerHeadUpdater")
        end

        local method =
            td:get_method(
                "addMaxHitPoint(System.Int32)"
            )

        if method == nil then
            error("No PlayerHeadUpdater.addMaxHitPoint")
        end

        ctx.methods.player_add_max_hp = method

        local commit_stack = {}

        sdk.hook(
            method,
            function(args)
                ctx.state.player_hook_calls =
                    ctx.state.player_hook_calls + 1

                capture_player(
                    ctx,
                    ctx.managed_from_arg(args, 2),
                    "captured player from PlayerHeadUpdater.addMaxHitPoint"
                )

                local gain = 0

                if args[3] ~= nil then
                    gain =
                        math.max(
                            0,
                            ctx.signed_int32(args[3])
                        )

                    ctx.state.last_player_add =
                        gain
                end

                commit_stack[
                    #commit_stack + 1
                ] =
                    begin_max_hp_commit_repair(
                        ctx,
                        gain
                    )
            end,
            function(retval)
                local pending =
                    commit_stack[
                        #commit_stack
                    ]

                commit_stack[
                    #commit_stack
                ] = nil

                finish_max_hp_commit_repair(
                    ctx,
                    pending
                )

                mark_hp_dirty(ctx)
                return retval
            end
        )

        ctx.state.player_hook_installed = true
    end)

    if not ok then
        ctx.set_error(err)
    end
end

local function install_hitpoint_capture_hook(
    ctx,
    method
)
    if method == nil then
        return
    end

    sdk.hook(
        method,
        function(args)
            if ctx.state.hitpoint ~= nil then
                return
            end

            for index = 1, 5 do
                local obj =
                    ctx.managed_from_arg(
                        args,
                        index
                    )

                if
                    obj ~= nil and
                    ctx.is_hitpoint_type(obj)
                then
                    if capture_hitpoint(
                        ctx,
                        obj,
                        "captured HitPoint from getter"
                    ) then
                        break
                    end
                end
            end
        end,
        function(retval)
            return retval
        end
    )
end

local function install_mutation_hook(
    ctx,
    method,
    capture_heal_delta,
    capture_max_delta
)
    if method == nil then
        return
    end

    local affected_player = false

    sdk.hook(
        method,
        function(args)
            ctx.state.hitpoint_hook_calls =
                ctx.state.hitpoint_hook_calls + 1

            affected_player = false

            local target =
                ctx.managed_from_arg(args, 2)

            if
                target == nil or
                not ctx.is_hitpoint_type(target)
            then
                return
            end

            local target_ptr =
                ctx.ptr_from_obj(target)

            affected_player =
                ctx.state.hitpoint ~= nil and
                target_ptr ==
                    ctx.state.hitpoint_ptr

            if affected_player and args[3] ~= nil then
                local delta =
                    ctx.signed_int32(args[3])

                if capture_heal_delta then
                    local native_heal = delta
                    local multiplier
                    delta, multiplier = expected_heal_value(delta)
                    ctx.state.intelligence_heal_multiplier = multiplier
                    ctx.state.intelligence_commit_native_heal = native_heal
                    ctx.state.intelligence_commit_expected_heal = delta
                    args[3] = sdk.to_ptr(delta)
                    ctx.state.heal_event_value =
                        math.max(
                            0,
                            tonumber(delta) or 0
                        )

                    ctx.state.heal_event_start_ratio =
                        tonumber(
                            ctx.state.overflow_ratio
                        ) or 0.0

                    ctx.state.heal_event_start_ring_index =
                        tonumber(
                            ctx.state.overflow_active_ring_index
                        ) or 0

                    ctx.state.heal_event_serial =
                        (
                            tonumber(
                                ctx.state.heal_event_serial
                            ) or 0
                        ) + 1
                end

                if capture_max_delta then
                    ctx.state.last_hitpoint_add =
                        delta
                end
            end
        end,
        function(retval)
            if affected_player then
                mark_hp_dirty(ctx)
            end

            affected_player = false
            return retval
        end
    )
end

local function apply_native_heal_preview_inputs(
    ctx,
    preview_param
)
    local restore_stack = {}

    if preview_param == nil then
        return restore_stack
    end

    local ok, error_text =
        pcall(function()
            local native_heal =
                tonumber(
                    preview_param:get_field(
                        "HealValue"
                    )
                ) or 0

            if native_heal <= 0 then
                return
            end

            local effective_heal,
                  multiplier =
                expected_heal_value(
                    native_heal
                )

            local current_hp =
                math.max(
                    0,
                    tonumber(
                        ctx.current_hp_number()
                    ) or 0
                )

            local current_max_hp =
                math.max(
                    current_hp,
                    tonumber(
                        ctx.max_hp_number()
                    ) or current_hp
                )

            local applied_heal =
                math.min(
                    math.max(
                        0,
                        effective_heal
                    ),
                    math.max(
                        0,
                        current_max_hp - current_hp
                    )
                )

            local projected_hp =
                math.min(
                    current_hp + applied_heal,
                    current_max_hp
                )

            local function push_field(
                field_name,
                new_value
            )
                local old_value =
                    preview_param:get_field(
                        field_name
                    )

                restore_stack[
                    #restore_stack + 1
                ] = {
                    object = preview_param,
                    field_name = field_name,
                    old_value = old_value
                }

                preview_param:set_field(
                    field_name,
                    new_value
                )
            end

            -- Capcom must receive the real current position as the preview
            -- start. Writing projected_hp here shifts the preview forward by
            -- the heal amount and creates the blank gap/duplicated segment.
            push_field(
                "CurrHitPoint",
                current_hp
            )

            push_field(
                "CurrMaxHitPoint",
                current_max_hp
            )

            push_field(
                "HealValue",
                applied_heal
            )

            ctx.state.intelligence_heal_multiplier =
                multiplier

            ctx.state.intelligence_preview_native_heal =
                native_heal

            ctx.state.intelligence_preview_modified_heal =
                effective_heal

            ctx.state.intelligence_preview_applied_heal =
                applied_heal

            ctx.state.intelligence_preview_projected_hp =
                projected_hp

            ctx.state.intelligence_preview_param_ptr =
                ctx.ptr_from_obj(
                    preview_param
                )
        end)

    if not ok then
        ctx.set_error(
            "Native heal preview input failed: "
            .. tostring(error_text)
        )
    end

    return restore_stack
end

local function restore_native_heal_preview_inputs(
    restore_stack
)
    if restore_stack == nil then
        return
    end

    for index = #restore_stack, 1, -1 do
        local entry =
            restore_stack[index]

        pcall(function()
            entry.object:set_field(
                entry.field_name,
                entry.old_value
            )
        end)
    end
end

local function install_hitpoint_hooks(ctx)
    if ctx.state.hitpoint_hook_installed then
        return
    end

    local ok, err = pcall(function()
        local td =
            sdk.find_type_definition("chainsaw.HitPoint")

        if td == nil then
            error("No chainsaw.HitPoint")
        end

        ctx.methods.hp_get_default =
            td:get_method("get_DefaultHitPoint()")

        ctx.methods.hp_get_max =
            td:get_method("get_MaxHitPoint()")
            or td:get_method("get_MaxHitPoint")

        ctx.methods.hp_get_current =
            td:get_method("get_CurrentHitPoint()")

        ctx.methods.hp_get_ratio =
            td:get_method("get_HitPointRatio()")

        ctx.methods.hp_recovery =
            td:get_method("recovery(System.Int32)")

        ctx.methods.hp_add_damage =
            td:get_method("addDamage(System.Int32)")

        ctx.methods.hp_add_max =
            td:get_method("addMaxHitPoint(System.Int32)")

        -- The additive path is useful for native item events, but RPG
        -- attributes need a deterministic absolute write. This setter was
        -- used by the earlier working Max HP probes.
        ctx.methods.hp_set_max =
            td:get_method("set_MaxHitPoint(System.Int32)")
            or td:get_method("set_MaxHitPoint(System.UInt32)")
            or td:get_method("set_MaxHitPoint")

        install_hitpoint_capture_hook(
            ctx,
            ctx.methods.hp_get_default
        )

        install_hitpoint_capture_hook(
            ctx,
            ctx.methods.hp_get_max
        )

        install_hitpoint_capture_hook(
            ctx,
            ctx.methods.hp_get_current
        )

        install_hitpoint_capture_hook(
            ctx,
            ctx.methods.hp_get_ratio
        )

        install_mutation_hook(
            ctx,
            ctx.methods.hp_recovery,
            true,
            false
        )

        install_mutation_hook(
            ctx,
            ctx.methods.hp_add_damage,
            false,
            false
        )

        install_mutation_hook(
            ctx,
            ctx.methods.hp_add_max,
            false,
            true
        )

        ctx.state.hitpoint_hook_installed = true
    end)

    if not ok then
        ctx.set_error(err)
    end
end

local function find_method_by_name(type_definition, target_name)
    local methods = type_definition:get_methods()

    for _, method in ipairs(methods) do
        local ok, method_name = pcall(function()
            return method:get_name()
        end)

        if ok and method_name == target_name then
            return method
        end
    end

    return nil
end

local function read_heal_preview_param(ctx, param)
    if param == nil then
        clear_preview_state(ctx)
        return
    end

    local ok, err = pcall(function()
        local raw_is_open =
        param:get_field("IsOpen")

    local is_open =
        raw_is_open == true or
        tonumber(raw_is_open) == 1

        local native_current_max =
            tonumber(
                param:get_field("CurrMaxHitPoint")
            ) or 0

        local native_current_hp =
            tonumber(
                param:get_field("CurrHitPoint")
            ) or 0

        local heal_value =
            tonumber(
                param:get_field("HealValue")
            ) or 0

        local hp_up_value =
            tonumber(
                param:get_field("HpUpValue")
            ) or 0

        local actual_current_hp =
            ctx.current_hp_number()
            or native_current_hp

        local actual_max_hp =
            ctx.max_hp_number()
            or native_current_max

        local vanilla_cap =
            tonumber(ctx.state.vanilla_max_hp_cap)
            or 2500

        local native_full_max_hp =
            tonumber(ctx.state.native_full_max_hp)
            or 2520.0

        --------------------------------------------------------
        -- Raw native values
        --------------------------------------------------------

        ctx.state.preview_native_current_hp =
            native_current_hp

        ctx.state.preview_native_max_hp =
            native_current_max

        ctx.state.preview_heal =
            tostring(heal_value)

        ctx.state.preview_hp_up =
            tostring(hp_up_value)

        ctx.state.preview_is_open_raw =
            tostring(raw_is_open)

        ctx.state.preview_is_open =
            is_open

        --------------------------------------------------------
        -- Native projected max
        --------------------------------------------------------

        local native_projected_max =
            native_current_max +
            hp_up_value

        ctx.state.preview_native_projected_max_hp =
            native_projected_max

        ctx.state.debug_curr_max =
            native_current_max

        ctx.state.debug_hp_up =
            hp_up_value

        ctx.state.debug_projected =
            native_projected_max

        --------------------------------------------------------
        -- Explicit Max-HP preview state
        --------------------------------------------------------

        local requested_gain =
            math.max(
                0,
                tonumber(
                    ctx.state.preview_override_gain
                ) or 0
            )

        local native_positive_gain =
            math.max(
                0,
                hp_up_value
            )

        -- Heal-only previews keep HpUpValue at zero. A nonzero native
        -- HpUpValue therefore reliably distinguishes the Max-HP-up path.
        local max_hp_preview_active =
            is_open and
            hp_up_value ~= 0

        local repair_required =
            max_hp_preview_active and
            hp_up_value < 0 and
            requested_gain > 0

        local corrected_max_gain = 0
        local max_gain_source = "none"

        if repair_required then
            corrected_max_gain =
                requested_gain

            max_gain_source =
                "Scoped Preview Gain"
        elseif max_hp_preview_active then
            corrected_max_gain =
                native_positive_gain

            if corrected_max_gain > 0 then
                max_gain_source =
                    "HealPreviewParam.HpUpValue"
            end
        end

        local projected_max_hp =
            math.min(
                actual_max_hp +
                corrected_max_gain,
                ctx.active_total_cap()
            )

        ctx.state.preview_custom_max_hp_gain =
            requested_gain

        ctx.state.preview_corrected_max_hp_gain =
            corrected_max_gain

        ctx.state.preview_projected_max_hp =
            projected_max_hp

        ctx.state.preview_max_gain_source =
            max_gain_source

        ctx.state.max_hp_preview_active =
            max_hp_preview_active

        ctx.state.max_hp_preview_native_hp_up =
            hp_up_value

        ctx.state.max_hp_preview_corrected_gain =
            corrected_max_gain

        ctx.state.max_hp_preview_projected_max_hp =
            projected_max_hp

        ctx.state.max_hp_preview_repair_required =
            repair_required

        local projected_current_hp =
            math.min(
                actual_current_hp +
                math.max(0, heal_value),
                projected_max_hp
            )

        local effective_heal =
            math.max(
                0,
                projected_current_hp -
                actual_current_hp
            )

        --------------------------------------------------------
        -- Effective extended-health preview
        --------------------------------------------------------

        ctx.state.preview_current_hp =
            actual_current_hp

        ctx.state.preview_current_max_hp =
            actual_max_hp

        ctx.state.overlay_preview_heal_hp =
            effective_heal

        ctx.state.overlay_preview_max_hp =
            corrected_max_gain

        ctx.state.overlay_preview_active =
            effective_heal > 0 or
            corrected_max_gain > 0
    end)

    if not ok then
        clear_preview_state(ctx)

        ctx.set_error(
            "Heal preview read failed: " ..
            tostring(err)
        )
    end
end

local function try_get_field(
    object,
    field_name
)
    if object == nil then
        return nil, false
    end

    local ok, value =
        pcall(function()
            return object:get_field(
                field_name
            )
        end)

    if ok then
        return value, true
    end

    return nil, false
end

local function try_set_field(
    object,
    field_name,
    value
)
    if object == nil then
        return false
    end

    local ok =
        pcall(function()
            object:set_field(
                field_name,
                value
            )
        end)

    return ok
end

push_scoped_field_override = function(
    restore_stack,
    object,
    field_name,
    new_value,
    label
)
    local old_value,
          field_exists =
        try_get_field(
            object,
            field_name
        )

    if not field_exists then
        return false
    end

    local write_ok =
        try_set_field(
            object,
            field_name,
            new_value
        )

    if not write_ok then
        return false
    end

    restore_stack[
        #restore_stack + 1
    ] = {
        object = object,
        field_name = field_name,
        old_value = old_value,
        label = label or field_name
    }

    return true
end

local function restore_scoped_preview_fields(
    ctx,
    restore_stack
)
    if restore_stack == nil then
        return
    end

    local safe_restore_fields = {
        CurrMaxHitPoint = true,
        HpUpValue = true,
        CurrHitPoint = true
    }

    for index = #restore_stack, 1, -1 do
        local entry =
            restore_stack[index]

        if safe_restore_fields[entry.field_name] == true then
            pcall(function()
                entry.object:set_field(
                    entry.field_name,
                    entry.old_value
                )
            end)
        end
    end

    if #restore_stack > 0 then
        ctx.state.preview_override_restore_count =
            (
                tonumber(
                    ctx.state.preview_override_restore_count
                ) or 0
            ) + 1
    end
end

local function apply_scoped_preview_override(
    ctx,
    condition_gui,
    preview_param
)
    local restore_stack = {}

    ctx.state.preview_override_applied =
        false

    ctx.state.preview_override_fields =
        ""

    ctx.state.preview_override_last_error =
        ""

    if
        ctx.state.preview_override_enabled ~= true or
        preview_param == nil
    then
        return restore_stack
    end

    local ok, err = pcall(function()
        local actual_current_hp =
            tonumber(
                ctx.current_hp_number()
            ) or 0

        local actual_max_hp =
            tonumber(
                ctx.max_hp_number()
            ) or 0

        local native_current_max =
            tonumber(
                preview_param:get_field(
                    "CurrMaxHitPoint"
                )
            ) or 0

        local native_hp_up =
            tonumber(
                preview_param:get_field(
                    "HpUpValue"
                )
            ) or 0

        local native_heal =
            tonumber(
                preview_param:get_field(
                    "HealValue"
                )
            ) or 0

        local raw_is_open =
            preview_param:get_field(
                "IsOpen"
            )

        local is_open =
            raw_is_open == true or
            tonumber(raw_is_open) == 1

        local requested_gain =
            math.max(
                0,
                tonumber(
                    ctx.state.preview_override_gain
                ) or 0
            )

        local max_hp_preview_active =
            is_open and
            native_hp_up ~= 0

        local repair_required =
            max_hp_preview_active and
            native_hp_up < 0 and
            requested_gain > 0

        if not repair_required then
            return
        end

        local projected_max_hp =
            math.min(
                actual_max_hp +
                requested_gain,
                ctx.active_total_cap()
            )

        local effective_gain =
            math.max(
                0,
                projected_max_hp -
                actual_max_hp
            )

        local projected_current_hp =
            math.min(
                actual_current_hp +
                math.max(0, native_heal),
                projected_max_hp
            )

        local changed_fields = {}

        local function write(
            object,
            field_name,
            value,
            label
        )
            local changed =
                push_scoped_field_override(
                    restore_stack,
                    object,
                    field_name,
                    value,
                    label
                )

            if changed then
                changed_fields[
                    #changed_fields + 1
                ] =
                    label or field_name
            end

            return changed
        end

        -- These are the values VitalConditionGui.preview() actually consumes.
        write(
            preview_param,
            "CurrMaxHitPoint",
            actual_max_hp,
            "HealPreviewParam.CurrMaxHitPoint"
        )

        write(
            preview_param,
            "HpUpValue",
            effective_gain,
            "HealPreviewParam.HpUpValue"
        )

        -- CurrHitPoint is the preview segment's starting position.
        -- Writing the projected endpoint here makes native preview() add
        -- HealValue a second time, creating the visible blank gap and
        -- duplicated green segment.
        write(
            preview_param,
            "CurrHitPoint",
            actual_current_hp,
            "HealPreviewParam.CurrHitPoint"
        )

        ctx.state.preview_override_projected_max =
            projected_max_hp

        ctx.state.preview_override_projected_current =
            projected_current_hp

        ctx.state.preview_override_applied =
            #restore_stack > 0

        ctx.state.preview_override_fields =
            table.concat(
                changed_fields,
                ", "
            )

        if ctx.state.preview_override_applied then
            ctx.state.preview_override_apply_count =
                (
                    tonumber(
                        ctx.state.preview_override_apply_count
                    ) or 0
                ) + 1
        end
    end)

    if not ok then
        ctx.state.preview_override_last_error =
            tostring(err)

        ctx.set_error(
            "Scoped preview override: " ..
            tostring(err)
        )
    end

    return restore_stack
end

local function read_preview_param_snapshot(param)
    local snapshot = {
        curr_hp = 0,
        curr_max_hp = 0,
        heal_value = 0,
        hp_up_value = 0
    }

    if param == nil then
        return snapshot
    end

    local function read_number(field_name)
        local ok, value =
            pcall(function()
                return param:get_field(
                    field_name
                )
            end)

        if ok then
            return tonumber(value) or 0
        end

        return 0
    end

    snapshot.curr_hp =
        read_number("CurrHitPoint")

    snapshot.curr_max_hp =
        read_number("CurrMaxHitPoint")

    snapshot.heal_value =
        read_number("HealValue")

    snapshot.hp_up_value =
        read_number("HpUpValue")

    return snapshot
end

local function push_preview_call_history(
    probe,
    entry
)
    local history =
        probe.history or {}

    history[#history + 1] =
        entry

    local limit =
        math.max(
            8,
            tonumber(probe.history_limit) or 48
        )

    while #history > limit do
        table.remove(history, 1)
    end

    probe.history =
        history
end

local function read_gui_backing_value(
    object,
    field_name
)
    if object == nil then
        return nil, false
    end

    local ok, value =
        pcall(function()
            return object:get_field(
                field_name
            )
        end)

    if not ok then
        return nil, false
    end

    return value, true
end

local function capture_preview_gui_snapshot(
    ctx,
    condition_gui,
    preview_param
)
    local snapshot = {
        gui_prev_max_hp = 0,
        gui_curr_max_hp = 0,
        gui_prev_state = "nil",
        gui_curr_state = "nil",

        param_curr_hp = 0,
        param_curr_max_hp = 0,
        param_heal_value = 0,
        param_hp_up_value = 0,

        derived_projected_max_hp = 0,
        derived_projected_current_hp = 0,

        read_ok = false
    }

    local prev_max,
          prev_ok =
        read_gui_backing_value(
            condition_gui,
            "<PrevMaxHp>k__BackingField"
        )

    local curr_max,
          curr_ok =
        read_gui_backing_value(
            condition_gui,
            "<CurrMaxHp>k__BackingField"
        )

    local prev_state =
        select(
            1,
            read_gui_backing_value(
                condition_gui,
                "<PrevState>k__BackingField"
            )
        )

    local curr_state =
        select(
            1,
            read_gui_backing_value(
                condition_gui,
                "<CurrState>k__BackingField"
            )
        )

    snapshot.gui_prev_max_hp =
        tonumber(prev_max) or 0

    snapshot.gui_curr_max_hp =
        tonumber(curr_max) or 0

    snapshot.gui_prev_state =
        tostring(prev_state)

    snapshot.gui_curr_state =
        tostring(curr_state)

    local function read_param_number(field_name)
        if preview_param == nil then
            return 0
        end

        local ok, value =
            pcall(function()
                return preview_param:get_field(
                    field_name
                )
            end)

        if not ok then
            return 0
        end

        return tonumber(value) or 0
    end

    snapshot.param_curr_hp =
        read_param_number(
            "CurrHitPoint"
        )

    snapshot.param_curr_max_hp =
        read_param_number(
            "CurrMaxHitPoint"
        )

    snapshot.param_heal_value =
        read_param_number(
            "HealValue"
        )

    snapshot.param_hp_up_value =
        read_param_number(
            "HpUpValue"
        )

    snapshot.derived_projected_max_hp =
        snapshot.param_curr_max_hp +
        snapshot.param_hp_up_value

    snapshot.derived_projected_current_hp =
        math.min(
            snapshot.param_curr_hp +
            math.max(
                0,
                snapshot.param_heal_value
            ),
            snapshot.derived_projected_max_hp
        )

    snapshot.read_ok =
        condition_gui ~= nil and
        preview_param ~= nil and
        (prev_ok or curr_ok)

    return snapshot
end

local function refresh_preview_gui_backing_pair(
    ctx,
    condition_gui,
    preview_param,
    before_snapshot
)
    local debug =
        ctx.preview_gui_backing

    if debug == nil then
        return
    end

    local ok, err = pcall(function()
        local after_snapshot =
            capture_preview_gui_snapshot(
                ctx,
                condition_gui,
                preview_param
            )

        debug.gui_type =
            ctx.type_name_from_obj(
                condition_gui
            )

        debug.gui_ptr =
            ctx.ptr_from_obj(
                condition_gui
            )

        debug.param_type =
            ctx.type_name_from_obj(
                preview_param
            )

        debug.param_ptr =
            ctx.ptr_from_obj(
                preview_param
            )

        debug.before =
            before_snapshot

        debug.after_override =
            after_snapshot

        debug.delta = {
            gui_prev_max_hp =
                after_snapshot.gui_prev_max_hp -
                before_snapshot.gui_prev_max_hp,

            gui_curr_max_hp =
                after_snapshot.gui_curr_max_hp -
                before_snapshot.gui_curr_max_hp,

            param_curr_hp =
                after_snapshot.param_curr_hp -
                before_snapshot.param_curr_hp,

            param_curr_max_hp =
                after_snapshot.param_curr_max_hp -
                before_snapshot.param_curr_max_hp,

            param_heal_value =
                after_snapshot.param_heal_value -
                before_snapshot.param_heal_value,

            param_hp_up_value =
                after_snapshot.param_hp_up_value -
                before_snapshot.param_hp_up_value,

            derived_projected_max_hp =
                after_snapshot.derived_projected_max_hp -
                before_snapshot.derived_projected_max_hp,

            derived_projected_current_hp =
                after_snapshot.derived_projected_current_hp -
                before_snapshot.derived_projected_current_hp
        }

        debug.read_ok =
            before_snapshot.read_ok or
            after_snapshot.read_ok

        debug.read_count =
            (
                tonumber(debug.read_count)
                or 0
            ) + 1

        debug.error = ""
    end)

    if not ok then
        debug.read_ok = false
        debug.error = tostring(err)

        ctx.set_error(
            "Preview GUI backing pair: " ..
            tostring(err)
        )
    end
end

local function safe_panel_call(object, method_names)
    if object == nil then
        return nil
    end

    for _, method_name in ipairs(method_names) do
        local ok, value =
            pcall(function()
                return object:call(method_name)
            end)

        if ok and value ~= nil then
            return value
        end
    end

    return nil
end

local function bool_text(value)
    if value == nil then
        return "unknown"
    end

    if value == true then
        return "true"
    end

    if value == false then
        return "false"
    end

    local numeric = tonumber(value)

    if numeric ~= nil then
        return numeric ~= 0 and "true" or "false"
    end

    return tostring(value)
end

local function capture_vitalmax_panel_snapshot(ctx, condition_gui)
    local result = {
        vitalmax_type = "unknown",
        vitalmax_ptr = "nil",
        curr_max_frame = 0.0,

        max_panel_type = "unknown",
        max_panel_ptr = "nil",
        max_panel_visible = "unknown",
        max_panel_enabled = "unknown",
        max_panel_child_count = -1,

        flare_panel_type = "unknown",
        flare_panel_ptr = "nil",
        flare_panel_visible = "unknown",
        flare_panel_enabled = "unknown",
        flare_panel_child_count = -1
    }

    if condition_gui == nil then
        return result
    end

    local vitalmax = nil
    pcall(function()
        vitalmax = condition_gui:get_field("_VitalMaxGui")
    end)

    if vitalmax == nil then
        return result
    end

    result.vitalmax_type = ctx.type_name_from_obj(vitalmax)
    result.vitalmax_ptr = ctx.ptr_from_obj(vitalmax)
    result.curr_max_frame =
        tonumber(
            safe_panel_call(
                vitalmax,
                {"get_CurrMaxFrame", "getCurrMaxFrame"}
            )
        ) or 0.0

    local max_panel = nil
    local flare_panel = nil

    pcall(function()
        max_panel = vitalmax:get_field("_MaxPanel")
    end)

    pcall(function()
        flare_panel = vitalmax:get_field("_MaxFlarePanel")
    end)

    if max_panel ~= nil then
        result.max_panel_type = ctx.type_name_from_obj(max_panel)
        result.max_panel_ptr = ctx.ptr_from_obj(max_panel)
        result.max_panel_visible =
            bool_text(
                safe_panel_call(
                    max_panel,
                    {"get_Visible","getVisible","get_IsVisible","getIsVisible"}
                )
            )
        result.max_panel_enabled =
            bool_text(
                safe_panel_call(
                    max_panel,
                    {"get_Enabled","getEnabled","get_IsEnable","getIsEnable"}
                )
            )
        result.max_panel_child_count =
            tonumber(
                safe_panel_call(
                    max_panel,
                    {"get_ChildCount","getChildCount","get_NumChildren","getNumChildren"}
                )
            ) or -1
    end

    if flare_panel ~= nil then
        result.flare_panel_type = ctx.type_name_from_obj(flare_panel)
        result.flare_panel_ptr = ctx.ptr_from_obj(flare_panel)
        result.flare_panel_visible =
            bool_text(
                safe_panel_call(
                    flare_panel,
                    {"get_Visible","getVisible","get_IsVisible","getIsVisible"}
                )
            )
        result.flare_panel_enabled =
            bool_text(
                safe_panel_call(
                    flare_panel,
                    {"get_Enabled","getEnabled","get_IsEnable","getIsEnable"}
                )
            )
        result.flare_panel_child_count =
            tonumber(
                safe_panel_call(
                    flare_panel,
                    {"get_ChildCount","getChildCount","get_NumChildren","getNumChildren"}
                )
            ) or -1
    end

    return result
end

local function commit_vitalmax_panel_snapshot(ctx, before, after)
    local debug = ctx.vitalmax_panel_snapshot

    debug.before = before
    debug.after = after
    debug.delta = {
        curr_max_frame =
            (tonumber(after.curr_max_frame) or 0.0) -
            (tonumber(before.curr_max_frame) or 0.0),

        max_panel_child_count =
            (tonumber(after.max_panel_child_count) or -1) -
            (tonumber(before.max_panel_child_count) or -1),

        flare_panel_child_count =
            (tonumber(after.flare_panel_child_count) or -1) -
            (tonumber(before.flare_panel_child_count) or -1)
    }

    debug.capture_count =
        (tonumber(debug.capture_count) or 0) + 1

    debug.error = ""
end

local function install_preview_hook(ctx)
    if ctx.state.preview_hook_installed then
        return
    end

    local ok, err = pcall(function()
        local td =
            sdk.find_type_definition(
                "chainsaw.VitalConditionGui"
            )

        if td == nil then
            error("No chainsaw.VitalConditionGui")
        end

        local preview_method =
            td:get_method(
                "preview(chainsaw.VitalGuiBehavior.HealPreviewParam)"
            )


        if preview_method == nil then
            error(
                "No VitalConditionGui.preview(HealPreviewParam)"
            )
        end

        local preview_restore_stack = {}
        local native_heal_restore_stack = {}
        local preview_check_stack = {}
        local vitalmax_snapshot_stack = {}

        sdk.hook(
            preview_method,

            function(args)
                ctx.state.preview_hook_calls =
                    (
                        tonumber(
                            ctx.state.preview_hook_calls
                        ) or 0
                    ) + 1

                ctx.state.preview_raw_this =
                    tostring(args[2])

                ctx.state.preview_raw_param =
                    tostring(args[3])


                ------------------------------------------------
                -- Convert VitalConditionGui
                ------------------------------------------------

                local gui_ok, condition_gui =
                    pcall(function()
                        return sdk.to_managed_object(
                            args[2]
                        )
                    end)

                if gui_ok and condition_gui ~= nil then
                    ctx.state.preview_behavior =
                        condition_gui

                    ctx.state.preview_condition_type =
                        ctx.type_name_from_obj(
                            condition_gui
                        )

                    ctx.state.preview_condition_ptr =
                        ctx.ptr_from_obj(
                            condition_gui
                        )
                end

                ------------------------------------------------
                -- Convert HealPreviewParam
                ------------------------------------------------

                local param_ok, preview_param =
                    pcall(function()
                        return sdk.to_managed_object(
                            args[3]
                        )
                    end)

                if not param_ok or preview_param == nil then
                    ctx.state.preview_param = nil
                    ctx.state.preview_param_type =
                        "conversion failed"
                    ctx.state.preview_param_ptr = "nil"
                    return
                end

                ctx.state.preview_param =
                    preview_param

                ctx.state.preview_param_type =
                    ctx.type_name_from_obj(
                        preview_param
                    )

                ctx.state.preview_param_ptr =
                    ctx.ptr_from_obj(
                        preview_param
                    )

                ------------------------------------------------
                -- Capture preview input before native preview()
                ------------------------------------------------

                local before_snapshot =
                    read_preview_param_snapshot(
                        preview_param
                    )

                ctx.preview_call_check.enter_calls =
                    (
                        tonumber(
                            ctx.preview_call_check.enter_calls
                        ) or 0
                    ) + 1

                ctx.preview_call_check.before_curr_hp =
                    before_snapshot.curr_hp

                ctx.preview_call_check.before_curr_max_hp =
                    before_snapshot.curr_max_hp

                ctx.preview_call_check.before_heal_value =
                    before_snapshot.heal_value

                ctx.preview_call_check.before_hp_up_value =
                    before_snapshot.hp_up_value

                preview_check_stack[
                    #preview_check_stack + 1
                ] = {
                    preview_param = preview_param,
                    before = before_snapshot
                }

                ------------------------------------------------
                -- Capture confirmed GUI/param state before correction
                ------------------------------------------------

                local gui_before_snapshot =
                    capture_preview_gui_snapshot(
                        ctx,
                        condition_gui,
                        preview_param
                    )

                ------------------------------------------------
                -- Correct native heal-preview inputs
                ------------------------------------------------

                native_heal_restore_stack[
                    #native_heal_restore_stack + 1
                ] =
                    apply_native_heal_preview_inputs(
                        ctx,
                        preview_param
                    )

                ------------------------------------------------
                -- Repair only broken Max-HP-up previews
                ------------------------------------------------

                local restore_stack = {}

                local max_restore_stack =
                    apply_scoped_preview_override(
                        ctx,
                        condition_gui,
                        preview_param
                    )

                for _, entry in ipairs(max_restore_stack) do
                    restore_stack[#restore_stack + 1] = entry
                end

                preview_restore_stack[
                    #preview_restore_stack + 1
                ] =
                    restore_stack

                ------------------------------------------------
                -- Capture state after our scoped correction
                ------------------------------------------------

                refresh_preview_gui_backing_pair(
                    ctx,
                    condition_gui,
                    preview_param,
                    gui_before_snapshot
                )

                ------------------------------------------------
                -- Capture live VitalMaxGui before native preview()
                ------------------------------------------------

                vitalmax_snapshot_stack[
                    #vitalmax_snapshot_stack + 1
                ] =
                    capture_vitalmax_panel_snapshot(
                        ctx,
                        condition_gui
                    )

                ------------------------------------------------
                -- Run the corrected preview reader
                ------------------------------------------------

                read_heal_preview_param(
                    ctx,
                    preview_param
                )

            end,

            function(retval)
                ------------------------------------------------
                -- Capture live VitalMaxGui after native preview()
                ------------------------------------------------

                local vitalmax_before =
                    vitalmax_snapshot_stack[
                        #vitalmax_snapshot_stack
                    ]

                vitalmax_snapshot_stack[
                    #vitalmax_snapshot_stack
                ] = nil

                local vitalmax_after =
                    capture_vitalmax_panel_snapshot(
                        ctx,
                        ctx.state.preview_behavior
                    )

                if vitalmax_before ~= nil then
                    commit_vitalmax_panel_snapshot(
                        ctx,
                        vitalmax_before,
                        vitalmax_after
                    )
                end

                ------------------------------------------------
                -- Capture preview values after native preview()
                ------------------------------------------------

                local check_entry =
                    preview_check_stack[
                        #preview_check_stack
                    ]

                preview_check_stack[
                    #preview_check_stack
                ] = nil

                if check_entry ~= nil then
                    local after_snapshot =
                        read_preview_param_snapshot(
                            check_entry.preview_param
                        )

                    local probe =
                        ctx.preview_call_check

                    probe.exit_calls =
                        (
                            tonumber(probe.exit_calls)
                            or 0
                        ) + 1

                    probe.after_curr_hp =
                        after_snapshot.curr_hp

                    probe.after_curr_max_hp =
                        after_snapshot.curr_max_hp

                    probe.after_heal_value =
                        after_snapshot.heal_value

                    probe.after_hp_up_value =
                        after_snapshot.hp_up_value

                    probe.delta_curr_hp =
                        after_snapshot.curr_hp -
                        check_entry.before.curr_hp

                    probe.delta_curr_max_hp =
                        after_snapshot.curr_max_hp -
                        check_entry.before.curr_max_hp

                    probe.delta_heal_value =
                        after_snapshot.heal_value -
                        check_entry.before.heal_value

                    probe.delta_hp_up_value =
                        after_snapshot.hp_up_value -
                        check_entry.before.hp_up_value

                    push_preview_call_history(
                        probe,
                        {
                            before_curr_hp =
                                check_entry.before.curr_hp,

                            before_curr_max_hp =
                                check_entry.before.curr_max_hp,

                            before_heal_value =
                                check_entry.before.heal_value,

                            before_hp_up_value =
                                check_entry.before.hp_up_value,

                            after_curr_hp =
                                after_snapshot.curr_hp,

                            after_curr_max_hp =
                                after_snapshot.curr_max_hp,

                            after_heal_value =
                                after_snapshot.heal_value,

                            after_hp_up_value =
                                after_snapshot.hp_up_value
                        }
                    )
                end

                ------------------------------------------------
                -- Restore native heal-preview inputs
                ------------------------------------------------

                local native_heal_restore =
                    native_heal_restore_stack[
                        #native_heal_restore_stack
                    ]

                native_heal_restore_stack[
                    #native_heal_restore_stack
                ] = nil

                restore_native_heal_preview_inputs(
                    native_heal_restore
                )

                ------------------------------------------------
                -- Restore fallback preview fields
                ------------------------------------------------

                local restore_stack =
                    preview_restore_stack[
                        #preview_restore_stack
                    ]

                preview_restore_stack[
                    #preview_restore_stack
                ] = nil

                restore_scoped_preview_fields(
                    ctx,
                    restore_stack
                )

                return retval
            end
        )

        ctx.state.preview_enter_hooks = 1
        ctx.state.preview_exit_hooks = 0
        ctx.state.preview_hook_installed = true

        if ctx.preview_call_check ~= nil then
            ctx.preview_call_check.installed =
                true

            ctx.preview_call_check.error =
                ""
        end
    end)

    if not ok then
        ctx.set_error(
            "Preview install: " ..
            tostring(err)
        )
    end
end

local function clamp01_native(value)
    value = tonumber(value) or 0.0

    return math.max(
        0.0,
        math.min(value, 1.0)
    )
end

local function read_native_property(
    object,
    property_name
)
    if object == nil then
        return nil, false, "object nil"
    end

    local getter_name =
        "get_" .. property_name

    local getter_ok, getter_value =
        pcall(function()
            return object:call(
                getter_name
            )
        end)

    if getter_ok and getter_value ~= nil then
        return
            getter_value,
            true,
            getter_name
    end

    local backing_field =
        "<" ..
        property_name ..
        ">k__BackingField"

    local field_ok, field_value =
        pcall(function()
            return object:get_field(
                backing_field
            )
        end)

    if field_ok and field_value ~= nil then
        return
            field_value,
            true,
            backing_field
    end

    return
        nil,
        false,
        getter_name ..
        " / " ..
        backing_field
end

local function read_native_damage_value(
    object,
    property_name
)
    local value,
          read_ok,
          source =
        read_native_property(
            object,
            property_name
        )

    return
        tonumber(value) or 0.0,
        read_ok,
        source
end

local function assign_native_damage_value(
    probe,
    condition_gui,
    property_name,
    value_key,
    ok_key,
    source_key
)
    local value,
          read_ok,
          source =
        read_native_damage_value(
            condition_gui,
            property_name
        )

    probe[value_key] = value
    probe[ok_key] = read_ok
    probe[source_key] = source

    probe.last_read_name = property_name
    probe.last_read_source = source

    if read_ok then
        probe.read_success_count =
            (tonumber(probe.read_success_count) or 0) + 1
    else
        probe.read_failure_count =
            (tonumber(probe.read_failure_count) or 0) + 1
    end
end

local function assign_native_boolean_value(
    probe,
    object,
    property_name,
    value_key,
    ok_key,
    source_key
)
    local value,
          read_ok,
          source =
        read_native_property(
            object,
            property_name
        )

    probe[value_key] =
        value == true or
        tonumber(value) == 1

    probe[ok_key] =
        read_ok

    probe[source_key] =
        source

    probe.last_read_name =
        property_name

    probe.last_read_source =
        source

    if read_ok then
        probe.read_success_count =
            (
                tonumber(
                    probe.read_success_count
                ) or 0
            ) + 1
    else
        probe.read_failure_count =
            (
                tonumber(
                    probe.read_failure_count
                ) or 0
            ) + 1
    end
end

local function push_gauge_history_sample(
    probe,
    elapsed_sec,
    hook_name,
    phase_name,
    input_value
)
    local history =
        probe.gauge_history or {}

    history[#history + 1] = {
        elapsed =
            tonumber(elapsed_sec) or 0.0,

        hook =
            hook_name or "poll",

        phase =
            phase_name or "after",

        input =
            tonumber(input_value) or 0.0,

        rate =
            tonumber(probe.gauge_curr_rate) or 0.0,

        target =
            tonumber(probe.gauge_curr_target_rate) or 0.0,

        diff =
            tonumber(probe.gauge_curr_rate_diff) or 0.0,

        is_end =
            probe.gauge_is_end == true,

        velocity =
            tonumber(probe.gauge_measured_velocity) or 0.0
    }

    local limit =
        math.max(
            8,
            tonumber(probe.gauge_history_limit) or 48
        )

    while #history > limit do
        table.remove(history, 1)
    end

    probe.gauge_history =
        history
end

local function read_vital_gauge_snapshot(
    ctx,
    gauge,
    hook_name,
    phase_name,
    input_value
)
    if gauge == nil then
        return
    end

    local probe =
        ctx.native_damage

    local ok, err = pcall(function()
        probe.gauge_object =
            gauge

        probe.gauge_object_type =
            ctx.type_name_from_obj(
                gauge
            )

        probe.gauge_object_ptr =
            ctx.ptr_from_obj(
                gauge
            )

        local max_frame =
            select(
                1,
                read_native_damage_value(
                    gauge,
                    "CurrMaxFrame"
                )
            )

        local rate =
            select(
                1,
                read_native_damage_value(
                    gauge,
                    "CurrRate"
                )
            )

        local target =
            select(
                1,
                read_native_damage_value(
                    gauge,
                    "CurrTargetRate"
                )
            )

        local rate_diff =
            select(
                1,
                read_native_damage_value(
                    gauge,
                    "CurrRateDiff"
                )
            )

        local raw_is_end =
            select(
                1,
                read_native_property(
                    gauge,
                    "IsEnd"
                )
            )

        local is_end =
            raw_is_end == true or
            tonumber(raw_is_end) == 1

        probe.gauge_curr_max_frame =
            tonumber(max_frame) or 0.0

        probe.gauge_curr_rate =
            tonumber(rate) or 0.0

        probe.gauge_curr_target_rate =
            tonumber(target) or 0.0

        probe.gauge_curr_rate_diff =
            tonumber(rate_diff) or 0.0

        probe.gauge_is_end =
            is_end

        probe.gauge_last_hook =
            hook_name or "unknown"

        probe.gauge_last_phase =
            phase_name or "unknown"

        probe.gauge_last_input =
            tonumber(input_value) or 0.0

        if phase_name == "before" then
            probe.gauge_pre_rate =
                probe.gauge_curr_rate

            probe.gauge_pre_target_rate =
                probe.gauge_curr_target_rate

            probe.gauge_pre_rate_diff =
                probe.gauge_curr_rate_diff

            probe.gauge_pre_is_end =
                probe.gauge_is_end
        else
            probe.gauge_post_rate =
                probe.gauge_curr_rate

            probe.gauge_post_target_rate =
                probe.gauge_curr_target_rate

            probe.gauge_post_rate_diff =
                probe.gauge_curr_rate_diff

            probe.gauge_post_is_end =
                probe.gauge_is_end

            probe.gauge_tick_delta_rate =
                probe.gauge_pre_rate -
                probe.gauge_post_rate

            local dt =
                0.0

            if hook_name == "update" then
                dt =
                    math.max(
                        0.0,
                        tonumber(input_value) or 0.0
                    )
            end

            if dt > 0.000001 then
                probe.gauge_tick_velocity =
                    probe.gauge_tick_delta_rate /
                    dt
            else
                probe.gauge_tick_velocity =
                    0.0
            end
        end

        local denominator =
            math.max(
                math.abs(
                    probe.gauge_curr_max_frame
                ),
                0.0001
            )

        probe.gauge_damage_ratio =
            clamp01_native(
                probe.gauge_curr_rate /
                denominator
            )

        probe.gauge_live_ratio =
            clamp01_native(
                probe.gauge_curr_target_rate /
                denominator
            )

        probe.gauge_damage_gap =
            math.max(
                0.0,
                probe.gauge_damage_ratio -
                probe.gauge_live_ratio
            )

        probe.gauge_damage_gap_hp =
            probe.gauge_damage_gap *
            (
                tonumber(
                    ctx.state.visual_gauge_cap
                ) or 2500
            )

        if
            math.abs(
                probe.gauge_curr_rate_diff
            ) > 0.0001
        then
            probe.gauge_last_nonzero_diff =
                probe.gauge_curr_rate_diff
        end

        push_gauge_history_sample(
            probe,
            probe.gauge_transition_elapsed,
            hook_name,
            phase_name,
            input_value
        )
    end)

    if not ok then
        probe.last_error =
            "Gauge snapshot: " ..
            tostring(err)
    end
end

local function refresh_native_damage_probe(
    ctx,
    condition_gui,
    elapsed_sec
)
    if condition_gui == nil then
        return
    end

    local probe = ctx.native_damage

    local ok, err = pcall(function()
        probe.object = condition_gui
        probe.object_type =
            ctx.type_name_from_obj(condition_gui)
        probe.object_ptr =
            ctx.ptr_from_obj(condition_gui)

        local vital_gauge_gui =
            condition_gui:get_field(
                "_VitalGaugeGui"
            )

        if vital_gauge_gui == nil then
            probe.gauge_object = nil
            probe.gauge_object_type = "unknown"
            probe.gauge_object_ptr = "nil"
            probe.last_error =
                "_VitalGaugeGui was nil"
        else
            probe.gauge_object =
                vital_gauge_gui

            probe.gauge_object_type =
                ctx.type_name_from_obj(
                    vital_gauge_gui
                )

            probe.gauge_object_ptr =
                ctx.ptr_from_obj(
                    vital_gauge_gui
                )
        end

        probe.elapsed_sec =
            math.max(
                0.0,
                tonumber(elapsed_sec) or 0.0
            )

        assign_native_damage_value(
            probe,
            condition_gui,
            "CurrFrame",
            "curr_frame",
            "curr_frame_read_ok",
            "curr_frame_source"
        )

        assign_native_damage_value(
            probe,
            condition_gui,
            "CurrGradationFrame",
            "curr_gradation_frame",
            "curr_gradation_frame_read_ok",
            "curr_gradation_frame_source"
        )

        assign_native_damage_value(
            probe,
            condition_gui,
            "CurrGradationGaugeFrameDiff",
            "curr_gradation_gauge_frame_diff",
            "curr_gradation_gauge_frame_diff_read_ok",
            "curr_gradation_gauge_frame_diff_source"
        )

        assign_native_damage_value(
            probe,
            condition_gui,
            "CurrMemoryMaxFrame",
            "curr_memory_max_frame",
            "curr_memory_max_frame_read_ok",
            "curr_memory_max_frame_source"
        )

        assign_native_damage_value(
            probe,
            condition_gui,
            "CurrMemoryMaxFrameDiff",
            "curr_memory_max_frame_diff",
            "curr_memory_max_frame_diff_read_ok",
            "curr_memory_max_frame_diff_source"
        )

        assign_native_damage_value(
            probe,
            condition_gui,
            "CurrMemoryFrame",
            "curr_memory_frame",
            "curr_memory_frame_read_ok",
            "curr_memory_frame_source"
        )

        assign_native_damage_value(
            probe,
            condition_gui,
            "CurrVirtualMemoryFrame",
            "curr_virtual_memory_frame",
            "curr_virtual_memory_frame_read_ok",
            "curr_virtual_memory_frame_source"
        )

        assign_native_damage_value(
            probe,
            condition_gui,
            "CurrMaxFrame",
            "curr_max_frame",
            "curr_max_frame_read_ok",
            "curr_max_frame_source"
        )

        assign_native_damage_value(
            probe,
            condition_gui,
            "CurrFrameDiff",
            "curr_frame_diff",
            "curr_frame_diff_read_ok",
            "curr_frame_diff_source"
        )

        if vital_gauge_gui ~= nil then
            assign_native_damage_value(
                probe,
                vital_gauge_gui,
                "CurrMaxFrame",
                "gauge_curr_max_frame",
                "gauge_curr_max_frame_read_ok",
                "gauge_curr_max_frame_source"
            )

            assign_native_damage_value(
                probe,
                vital_gauge_gui,
                "CurrRate",
                "gauge_curr_rate",
                "gauge_curr_rate_read_ok",
                "gauge_curr_rate_source"
            )

            assign_native_damage_value(
                probe,
                vital_gauge_gui,
                "CurrTargetRate",
                "gauge_curr_target_rate",
                "gauge_curr_target_rate_read_ok",
                "gauge_curr_target_rate_source"
            )

            assign_native_damage_value(
                probe,
                vital_gauge_gui,
                "CurrRateDiff",
                "gauge_curr_rate_diff",
                "gauge_curr_rate_diff_read_ok",
                "gauge_curr_rate_diff_source"
            )

            assign_native_boolean_value(
                probe,
                vital_gauge_gui,
                "IsEnd",
                "gauge_is_end",
                "gauge_is_end_read_ok",
                "gauge_is_end_source"
            )
        end

        local denominator =
            math.max(
                math.abs(probe.curr_max_frame),
                0.0001
            )

        local live_ratio =
            clamp01_native(
                probe.curr_frame /
                denominator
            )

        local memory_ratio =
            clamp01_native(
                probe.curr_memory_frame /
                denominator
            )

        local virtual_memory_ratio =
            clamp01_native(
                probe.curr_virtual_memory_frame /
                denominator
            )

        local gradation_ratio =
            clamp01_native(
                probe.curr_gradation_frame /
                denominator
            )

        -- CurrGradationFrame is the active vanilla delayed-damage
        -- endpoint. It stays ahead of CurrFrame after damage and
        -- retracts toward it.
        local damage_ratio =
            math.max(
                live_ratio,
                gradation_ratio
            )

        local damage_gap =
            math.max(
                0.0,
                damage_ratio - live_ratio
            )

        local previous_damage_ratio =
            tonumber(
                probe.previous_damage_ratio
            )

        local frame_delta =
            math.max(
                0.0,
                tonumber(probe.elapsed_sec) or 0.0
            )

        local measured_velocity = 0.0
        local ratio_change = 0.0

        if previous_damage_ratio ~= nil then
            ratio_change =
                previous_damage_ratio -
                damage_ratio

            if
                frame_delta > 0.000001 and
                math.abs(ratio_change) > 0.0000001
            then
                measured_velocity =
                    ratio_change /
                    frame_delta
            end
        end

        local was_active =
            probe.active == true

        local is_active =
            damage_gap > 0.0001

        if is_active and not was_active then
            probe.transition_elapsed =
                0.0

            probe.transition_start_gap =
                damage_gap

            probe.transition_start_damage_ratio =
                damage_ratio

            probe.transition_target_ratio =
                live_ratio

            probe.transition_current_gap =
                damage_gap

            probe.transition_progress =
                0.0

            probe.transition_average_velocity =
                0.0

            probe.transition_inferred_duration =
                0.0

            probe.transition_remaining_time =
                0.0

            probe.transition_sample_count =
                1

            probe.transition_ratio_change_count =
                0

            probe.transition_last_ratio_change =
                0.0

        elseif is_active then
            probe.transition_elapsed =
                (
                    tonumber(
                        probe.transition_elapsed
                    ) or 0.0
                ) + frame_delta

            probe.transition_target_ratio =
                live_ratio

            probe.transition_current_gap =
                damage_gap

            probe.transition_sample_count =
                (
                    tonumber(
                        probe.transition_sample_count
                    ) or 0
                ) + 1

            if math.abs(ratio_change) > 0.0000001 then
                probe.transition_ratio_change_count =
                    (
                        tonumber(
                            probe.transition_ratio_change_count
                        ) or 0
                    ) + 1

                probe.transition_last_ratio_change =
                    ratio_change
            end

            local start_gap =
                math.max(
                    tonumber(
                        probe.transition_start_gap
                    ) or 0.0,
                    0.000001
                )

            local completed_gap =
                math.max(
                    0.0,
                    start_gap - damage_gap
                )

            local progress =
                clamp01_native(
                    completed_gap /
                    start_gap
                )

            local elapsed =
                math.max(
                    tonumber(
                        probe.transition_elapsed
                    ) or 0.0,
                    0.0
                )

            local average_velocity = 0.0

            if elapsed > 0.000001 then
                average_velocity =
                    completed_gap /
                    elapsed
            end

            local inferred_duration = 0.0

            if progress > 0.0001 then
                inferred_duration =
                    elapsed /
                    progress
            end

            probe.transition_progress =
                progress

            probe.transition_average_velocity =
                average_velocity

            probe.transition_inferred_duration =
                inferred_duration

            probe.transition_remaining_time =
                math.max(
                    0.0,
                    inferred_duration - elapsed
                )

        elseif was_active then
            probe.transition_elapsed =
                (
                    tonumber(
                        probe.transition_elapsed
                    ) or 0.0
                ) + frame_delta

            local completed_duration =
                tonumber(
                    probe.transition_elapsed
                ) or 0.0

            local completed_gap =
                tonumber(
                    probe.transition_start_gap
                ) or 0.0

            probe.transition_current_gap =
                0.0

            probe.transition_progress =
                1.0

            probe.transition_remaining_time =
                0.0

            probe.transition_inferred_duration =
                completed_duration

            probe.transition_last_duration =
                completed_duration

            probe.transition_last_start_gap =
                completed_gap

            if completed_duration > 0.000001 then
                probe.transition_last_average_velocity =
                    completed_gap /
                    completed_duration
            else
                probe.transition_last_average_velocity =
                    0.0
            end
        end

        probe.live_ratio =
            live_ratio

        probe.memory_ratio =
            memory_ratio

        probe.virtual_memory_ratio =
            virtual_memory_ratio

        probe.gradation_ratio =
            gradation_ratio

        probe.damage_ratio =
            damage_ratio

        probe.damage_gap =
            damage_gap

        probe.damage_gap_hp =
            damage_gap *
            (
                tonumber(
                    ctx.state.visual_gauge_cap
                ) or 2500
            )

        -- Instantaneous velocity is retained when the sampled ratio
        -- actually changes. Average/inferred metrics remain useful even
        -- when multiple GUI instances produce duplicate samples.
        if math.abs(measured_velocity) > 0.0000001 then
            probe.measured_velocity =
                measured_velocity
        end

        probe.previous_damage_ratio =
            damage_ratio

        probe.active =
            is_active
        if vital_gauge_gui ~= nil then
            local gauge_max_frame =
                math.max(
                    math.abs(
                        tonumber(
                            probe.gauge_curr_max_frame
                        ) or 0.0
                    ),
                    0.0001
                )

            local gauge_rate =
                tonumber(
                    probe.gauge_curr_rate
                ) or 0.0

            local gauge_target_rate =
                tonumber(
                    probe.gauge_curr_target_rate
                ) or 0.0

            local gauge_rate_diff =
                tonumber(
                    probe.gauge_curr_rate_diff
                ) or 0.0

            local gauge_damage_ratio =
                clamp01_native(
                    gauge_rate /
                    gauge_max_frame
                )

            local gauge_live_ratio =
                clamp01_native(
                    gauge_target_rate /
                    gauge_max_frame
                )

            local gauge_damage_gap =
                math.max(
                    0.0,
                    gauge_damage_ratio -
                    gauge_live_ratio
                )

            local previous_rate =
                tonumber(
                    probe.gauge_previous_rate
                )

            local gauge_measured_velocity =
                0.0

            if
                previous_rate ~= nil and
                probe.elapsed_sec > 0.000001
            then
                gauge_measured_velocity =
                    (
                        previous_rate -
                        gauge_rate
                    ) /
                    probe.elapsed_sec
            end

            local epsilon = 0.0001

            local rate_delta =
                math.abs(
                    gauge_rate -
                    gauge_target_rate
                )

            local was_gauge_active =
                probe.gauge_transition_active == true

            local is_gauge_active =
                probe.gauge_is_end ~= true or
                rate_delta > epsilon

            if math.abs(gauge_rate_diff) > epsilon then
                probe.gauge_last_nonzero_diff =
                    gauge_rate_diff
            end

            if is_gauge_active and not was_gauge_active then
                probe.gauge_transition_elapsed =
                    0.0

                probe.gauge_transition_duration =
                    0.0

                probe.gauge_transition_start_gap =
                    rate_delta /
                    gauge_max_frame

                probe.gauge_transition_start_rate =
                    gauge_rate

                probe.gauge_transition_target_rate =
                    gauge_target_rate

                probe.gauge_transition_end_rate =
                    gauge_rate

                probe.gauge_peak_velocity =
                    math.abs(
                        gauge_measured_velocity
                    )

                probe.gauge_min_rate =
                    gauge_rate

                probe.gauge_max_rate =
                    gauge_rate

                probe.gauge_history = {}

            elseif is_gauge_active then
                probe.gauge_transition_elapsed =
                    (
                        tonumber(
                            probe.gauge_transition_elapsed
                        ) or 0.0
                    ) + probe.elapsed_sec

                probe.gauge_transition_target_rate =
                    gauge_target_rate

                probe.gauge_transition_end_rate =
                    gauge_rate

                probe.gauge_peak_velocity =
                    math.max(
                        tonumber(
                            probe.gauge_peak_velocity
                        ) or 0.0,
                        math.abs(
                            gauge_measured_velocity
                        )
                    )

                probe.gauge_min_rate =
                    math.min(
                        tonumber(
                            probe.gauge_min_rate
                        ) or gauge_rate,
                        gauge_rate
                    )

                probe.gauge_max_rate =
                    math.max(
                        tonumber(
                            probe.gauge_max_rate
                        ) or gauge_rate,
                        gauge_rate
                    )

            elseif was_gauge_active then
                probe.gauge_transition_elapsed =
                    (
                        tonumber(
                            probe.gauge_transition_elapsed
                        ) or 0.0
                    ) + probe.elapsed_sec

                probe.gauge_transition_duration =
                    probe.gauge_transition_elapsed

                probe.gauge_transition_end_rate =
                    gauge_rate
            end

            probe.gauge_damage_ratio =
                gauge_damage_ratio

            probe.gauge_live_ratio =
                gauge_live_ratio

            probe.gauge_damage_gap =
                gauge_damage_gap

            probe.gauge_damage_gap_hp =
                gauge_damage_gap *
                (
                    tonumber(
                        ctx.state.visual_gauge_cap
                    ) or 2500
                )

            probe.gauge_measured_velocity =
                gauge_measured_velocity

            probe.gauge_previous_rate =
                gauge_rate

            probe.gauge_transition_active =
                is_gauge_active

            push_gauge_history_sample(
                probe,
                probe.gauge_transition_elapsed,
                "condition_update",
                "after",
                probe.elapsed_sec
            )
        end

        probe.calls =
            (tonumber(probe.calls) or 0) + 1
    end)

    if not ok then
        probe.last_error = tostring(err)
    else
        probe.last_error = ""
    end
end

local function flare_state_name(value)
    value =
        tonumber(value) or -1

    if value == 0 then
        return "INVALID"
    end

    if value == 1 then
        return "DAMAGE"
    end

    if value == 2 then
        return "DISABLE"
    end

    return "UNKNOWN(" .. tostring(value) .. ")"
end

local function read_flare_state(flare)
    local raw_state,
          read_ok,
          source =
        read_native_property(
            flare,
            "CurrState"
        )

    local numeric_state =
        tonumber(raw_state)

    if numeric_state == nil and raw_state ~= nil then
        local enum_ok, enum_value =
            pcall(function()
                return raw_state:get_field("value__")
            end)

        if enum_ok then
            numeric_state =
                tonumber(enum_value)
        end
    end

    return
        numeric_state or -1,
        read_ok,
        source
end

local function push_flare_history_sample(
    probe,
    hook_name,
    phase_name,
    input_value
)
    local history =
        probe.flare_history or {}

    history[#history + 1] = {
        hook =
            hook_name or "unknown",

        phase =
            phase_name or "unknown",

        input =
            tonumber(input_value) or 0.0,

        state =
            tonumber(probe.flare_curr_state) or -1,

        state_name =
            probe.flare_curr_state_name or "UNKNOWN",

        active =
            probe.flare_damage_active == true,

        elapsed =
            tonumber(probe.flare_damage_elapsed) or 0.0
    }

    local limit =
        math.max(
            8,
            tonumber(probe.flare_history_limit) or 48
        )

    while #history > limit do
        table.remove(history, 1)
    end

    probe.flare_history =
        history
end

local function capture_flare_snapshot(
    ctx,
    flare,
    hook_name,
    phase_name,
    input_value
)
    if flare == nil then
        return
    end

    local probe =
        ctx.native_damage

    local ok, err = pcall(function()
        probe.flare_object =
            flare

        probe.flare_object_type =
            ctx.type_name_from_obj(
                flare
            )

        probe.flare_object_ptr =
            ctx.ptr_from_obj(
                flare
            )

        probe.flare_last_hook =
            hook_name or "unknown"

        probe.flare_last_phase =
            phase_name or "unknown"

        local state =
            select(
                1,
                read_flare_state(
                    flare
                )
            )

        local state_name =
            flare_state_name(
                state
            )

        probe.flare_curr_state =
            state

        probe.flare_curr_state_name =
            state_name

        if phase_name == "before" then
            probe.flare_pre_state =
                state

            probe.flare_pre_state_name =
                state_name

            if hook_name == "setMaxFrame" then
                probe.flare_pre_max_frame_input =
                    tonumber(input_value) or 0.0
            end
        else
            probe.flare_post_state =
                state

            probe.flare_post_state_name =
                state_name

            if hook_name == "setMaxFrame" then
                probe.flare_post_max_frame_input =
                    tonumber(input_value) or 0.0
            end
        end

        local was_active =
            probe.flare_damage_active == true

        local is_active =
            state_name == "DAMAGE"

        if is_active and not was_active then
            probe.flare_damage_elapsed =
                0.0

            probe.flare_history = {}

        elseif is_active then
            probe.flare_damage_elapsed =
                (
                    tonumber(
                        probe.flare_damage_elapsed
                    ) or 0.0
                ) +
                (
                    tonumber(
                        probe.elapsed_sec
                    ) or 0.0
                )

        elseif was_active then
            probe.flare_last_damage_duration =
                tonumber(
                    probe.flare_damage_elapsed
                ) or 0.0
        end

        probe.flare_damage_active =
            is_active

        push_flare_history_sample(
            probe,
            hook_name,
            phase_name,
            input_value
        )
    end)

    if not ok then
        probe.last_error =
            "Damage flare snapshot: " ..
            tostring(err)
    end
end

local function install_damage_flare_hooks(ctx)
    if ctx.native_damage.flare_hook_installed then
        return
    end

    local ok, err = pcall(function()
        local td =
            sdk.find_type_definition(
                "chainsaw.VitalDamageFlareGui"
            )

        if td == nil then
            error(
                "No chainsaw.VitalDamageFlareGui"
            )
        end

        local set_max_frame_method =
            td:get_method(
                "setMaxFrame(System.Single frame)"
            )
            or td:get_method(
                "setMaxFrame(System.Single)"
            )

        local set_state_method =
            td:get_method(
                "setState(chainsaw.VitalDamageFlareGui.RootState state)"
            )
            or td:get_method(
                "setState(chainsaw.VitalDamageFlareGui.RootState)"
            )

        local function managed_this(args)
            local ok_this, obj =
                pcall(function()
                    return sdk.to_managed_object(
                        args[2]
                    )
                end)

            if ok_this then
                return obj
            end

            return nil
        end

        if set_max_frame_method ~= nil then
            local pending_stack = {}

            sdk.hook(
                set_max_frame_method,
                function(args)
                    local flare =
                        managed_this(args)

                    local input_value = 0.0

                    if args[3] ~= nil then
                        local value_ok, value =
                            pcall(function()
                                return sdk.to_float(
                                    args[3]
                                )
                            end)

                        if value_ok then
                            input_value =
                                tonumber(value) or 0.0
                        end
                    end

                    pending_stack[
                        #pending_stack + 1
                    ] = {
                        flare = flare,
                        input = input_value
                    }

                    ctx.native_damage.flare_set_max_frame_calls =
                        (
                            tonumber(
                                ctx.native_damage.flare_set_max_frame_calls
                            ) or 0
                        ) + 1

                    ctx.native_damage.flare_last_max_frame_input =
                        input_value

                    capture_flare_snapshot(
                        ctx,
                        flare,
                        "setMaxFrame",
                        "before",
                        input_value
                    )
                end,
                function(retval)
                    local pending =
                        pending_stack[
                            #pending_stack
                        ]

                    pending_stack[
                        #pending_stack
                    ] = nil

                    if pending ~= nil then
                        capture_flare_snapshot(
                            ctx,
                            pending.flare,
                            "setMaxFrame",
                            "after",
                            pending.input
                        )
                    end

                    return retval
                end
            )
        end

        if set_state_method ~= nil then
            local pending_stack = {}

            sdk.hook(
                set_state_method,
                function(args)
                    local flare =
                        managed_this(args)

                    local state_value = -1

                    if args[3] ~= nil then
                        local state_ok, value =
                            pcall(function()
                                return ctx.signed_int32(
                                    args[3]
                                )
                            end)

                        if state_ok then
                            state_value =
                                tonumber(value) or -1
                        end
                    end

                    pending_stack[
                        #pending_stack + 1
                    ] = {
                        flare = flare,
                        input = state_value
                    }

                    ctx.native_damage.flare_set_state_calls =
                        (
                            tonumber(
                                ctx.native_damage.flare_set_state_calls
                            ) or 0
                        ) + 1

                    capture_flare_snapshot(
                        ctx,
                        flare,
                        "setState",
                        "before",
                        state_value
                    )
                end,
                function(retval)
                    local pending =
                        pending_stack[
                            #pending_stack
                        ]

                    pending_stack[
                        #pending_stack
                    ] = nil

                    if pending ~= nil then
                        capture_flare_snapshot(
                            ctx,
                            pending.flare,
                            "setState",
                            "after",
                            pending.input
                        )
                    end

                    return retval
                end
            )
        end

        if
            set_max_frame_method == nil and
            set_state_method == nil
        then
            error(
                "No VitalDamageFlareGui methods found"
            )
        end

        ctx.native_damage.flare_hook_installed =
            true
    end)

    if not ok then
        ctx.native_damage.last_error =
            "Damage flare hook install: " ..
            tostring(err)

        ctx.set_error(
            ctx.native_damage.last_error
        )
    end
end

local function install_vital_gauge_update_hooks(ctx)
    if ctx.native_damage.gauge_update_hook_installed then
        return
    end

    local ok, err = pcall(function()
        local td =
            sdk.find_type_definition(
                "chainsaw.VitalGaugeGui"
            )

        if td == nil then
            error(
                "No chainsaw.VitalGaugeGui"
            )
        end

        local update_method =
            td:get_method(
                "update(System.Single elapsedSec)"
            )
            or td:get_method(
                "update(System.Single)"
            )

        local update_gauge_method =
            td:get_method(
                "updateGauge(System.Single frame)"
            )
            or td:get_method(
                "updateGauge(System.Single)"
            )

        local function install_method_hook(
            method,
            hook_name,
            count_key
        )
            if method == nil then
                return false
            end

            local pending_stack = {}

            sdk.hook(
                method,
                function(args)
                    local gauge = nil
                    local input_value = 0.0

                    local gauge_ok, gauge_obj =
                        pcall(function()
                            return sdk.to_managed_object(
                                args[2]
                            )
                        end)

                    if gauge_ok then
                        gauge =
                            gauge_obj
                    end

                    if args[3] ~= nil then
                        local value_ok, value =
                            pcall(function()
                                return sdk.to_float(
                                    args[3]
                                )
                            end)

                        if value_ok then
                            input_value =
                                tonumber(value) or 0.0
                        end
                    end

                    pending_stack[
                        #pending_stack + 1
                    ] = {
                        gauge = gauge,
                        input = input_value
                    }

                    ctx.native_damage[count_key] =
                        (
                            tonumber(
                                ctx.native_damage[count_key]
                            ) or 0
                        ) + 1

                    read_vital_gauge_snapshot(
                        ctx,
                        gauge,
                        hook_name,
                        "before",
                        input_value
                    )
                end,
                function(retval)
                    local pending =
                        pending_stack[
                            #pending_stack
                        ]

                    pending_stack[
                        #pending_stack
                    ] = nil

                    if pending ~= nil then
                        read_vital_gauge_snapshot(
                            ctx,
                            pending.gauge,
                            hook_name,
                            "after",
                            pending.input
                        )
                    end

                    return retval
                end
            )

            return true
        end

        local installed_update =
            install_method_hook(
                update_method,
                "update",
                "gauge_update_hook_calls"
            )

        local installed_update_gauge =
            install_method_hook(
                update_gauge_method,
                "updateGauge",
                "gauge_update_gauge_hook_calls"
            )

        if
            not installed_update and
            not installed_update_gauge
        then
            error(
                "No VitalGaugeGui update methods found"
            )
        end

        ctx.native_damage.gauge_update_hook_installed =
            true
    end)

    if not ok then
        ctx.native_damage.last_error =
            "Gauge update hook install: " ..
            tostring(err)

        ctx.set_error(
            ctx.native_damage.last_error
        )
    end
end

local CONDITION_STATE = {
    INVALID = -1,

    FINE = 0,
    FINE_TO_DANGER = 1,
    FINE_TO_CAUTION = 2,

    CAUTION = 3,
    CAUTION_TO_FINE = 4,
    CAUTION_TO_DANGER = 5,

    DANGER = 6,
    DANGER_TO_FINE = 7,
    DANGER_TO_CAUTION = 8
}

local function condition_transition_target(state)
    if state == CONDITION_STATE.FINE_TO_DANGER then
        return CONDITION_STATE.DANGER
    end

    if state == CONDITION_STATE.FINE_TO_CAUTION then
        return CONDITION_STATE.CAUTION
    end

    if state == CONDITION_STATE.CAUTION_TO_FINE then
        return CONDITION_STATE.FINE
    end

    if state == CONDITION_STATE.CAUTION_TO_DANGER then
        return CONDITION_STATE.DANGER
    end

    if state == CONDITION_STATE.DANGER_TO_FINE then
        return CONDITION_STATE.FINE
    end

    if state == CONDITION_STATE.DANGER_TO_CAUTION then
        return CONDITION_STATE.CAUTION
    end

    return state
end

local function is_stable_condition_state(state)
    return
        state == CONDITION_STATE.FINE or
        state == CONDITION_STATE.CAUTION or
        state == CONDITION_STATE.DANGER
end

local function choose_condition_target(ctx, current_hp, max_hp)
    local caution_ratio =
        math.max(
            0.0,
            math.min(
                tonumber(
                    ctx.state.condition_caution_ratio
                ) or 0.50,
                1.0
            )
        )

    local danger_ratio =
        math.max(
            0.0,
            math.min(
                tonumber(
                    ctx.state.condition_danger_ratio
                ) or 0.25,
                caution_ratio
            )
        )

    ctx.state.condition_caution_ratio =
        caution_ratio

    ctx.state.condition_danger_ratio =
        danger_ratio

    local ratio = 0.0

    if max_hp > 0 then
        ratio =
            math.max(
                0.0,
                math.min(
                    current_hp / max_hp,
                    1.0
                )
            )
    end

    ctx.state.condition_current_ratio =
        ratio

    ctx.state.condition_caution_hp =
        math.floor(
            max_hp *
            caution_ratio
        )

    ctx.state.condition_danger_hp =
        math.floor(
            max_hp *
            danger_ratio
        )

    if ratio <= danger_ratio then
        return CONDITION_STATE.DANGER
    end

    if ratio <= caution_ratio then
        return CONDITION_STATE.CAUTION
    end

    return CONDITION_STATE.FINE
end

local function choose_condition_transition(
    native_state,
    last_stable_state,
    target_state
)
    local effective_state =
        native_state

    if not is_stable_condition_state(effective_state) then
        effective_state =
            tonumber(last_stable_state)
            or CONDITION_STATE.FINE
    end

    if target_state == CONDITION_STATE.FINE then
        if effective_state == CONDITION_STATE.CAUTION then
            return CONDITION_STATE.CAUTION_TO_FINE
        end

        if effective_state == CONDITION_STATE.DANGER then
            return CONDITION_STATE.DANGER_TO_FINE
        end

        return CONDITION_STATE.FINE
    end

    if target_state == CONDITION_STATE.CAUTION then
        if effective_state == CONDITION_STATE.FINE then
            return CONDITION_STATE.FINE_TO_CAUTION
        end

        if effective_state == CONDITION_STATE.DANGER then
            return CONDITION_STATE.DANGER_TO_CAUTION
        end

        return CONDITION_STATE.CAUTION
    end

    if target_state == CONDITION_STATE.DANGER then
        if effective_state == CONDITION_STATE.FINE then
            return CONDITION_STATE.FINE_TO_DANGER
        end

        if effective_state == CONDITION_STATE.CAUTION then
            return CONDITION_STATE.CAUTION_TO_DANGER
        end

        return CONDITION_STATE.DANGER
    end

    return target_state
end

local function read_condition_state(
    condition_gui,
    get_state_method
)
    if condition_gui == nil then
        return CONDITION_STATE.INVALID
    end

    if get_state_method ~= nil then
        local ok, value =
            pcall(function()
                return get_state_method:call(
                    condition_gui
                )
            end)

        if ok and value ~= nil then
            return tonumber(value) or CONDITION_STATE.INVALID
        end
    end

    local ok, value =
        pcall(function()
            return condition_gui:get_field(
                "<CurrState>k__BackingField"
            )
        end)

    if ok and value ~= nil then
        return tonumber(value) or CONDITION_STATE.INVALID
    end

    return CONDITION_STATE.INVALID
end

local function refresh_scaled_condition_diagnostics(ctx)
    local current_hp =
        tonumber(
            ctx.current_hp_number()
        )

    local max_hp =
        tonumber(
            ctx.max_hp_number()
        )

    if
        current_hp == nil or
        max_hp == nil or
        max_hp <= 0
    then
        return
    end

    ctx.state.condition_target_state =
        choose_condition_target(
            ctx,
            current_hp,
            max_hp
        )
end

-- Calculates the modular condition target every update. The native
-- write path is intentionally optional so Capcom's animations remain intact.
local function apply_scaled_condition_state(
    ctx,
    condition_gui,
    get_state_method,
    set_state_method,
    set_curr_state_method
)
    local state = ctx.state

    refresh_scaled_condition_diagnostics(
        ctx
    )

    if state.condition_native_write_enabled ~= true then
        state.condition_native_write_block_reason =
            "disabled to preserve native damage/heal animation"

        state.condition_skip_count =
            (
                tonumber(
                    state.condition_skip_count
                ) or 0
            ) + 1

        return
    end

    state.condition_native_write_block_reason =
        ""

    if
        state.condition_scaling_enabled ~= true or
        condition_gui == nil or
        set_state_method == nil
    then
        state.condition_skip_count =
            (
                tonumber(
                    state.condition_skip_count
                ) or 0
            ) + 1

        return
    end

    local current_hp =
        tonumber(
            ctx.current_hp_number()
        )

    local max_hp =
        tonumber(
            ctx.max_hp_number()
        )

    if
        current_hp == nil or
        max_hp == nil or
        max_hp <= 0
    then
        state.condition_skip_count =
            (
                tonumber(
                    state.condition_skip_count
                ) or 0
            ) + 1

        return
    end

    state.condition_gui_ptr =
        ctx.ptr_from_obj(
            condition_gui
        )

    state.condition_gui_type =
        ctx.type_name_from_obj(
            condition_gui
        )

    local native_state =
        read_condition_state(
            condition_gui,
            get_state_method
        )

    state.condition_native_state =
        native_state

    if is_stable_condition_state(native_state) then
        state.condition_last_stable_state =
            native_state
    end

    local target_state =
        tonumber(
            state.condition_target_state
        ) or CONDITION_STATE.FINE

    -- A native transition already heading toward our desired state should
    -- be allowed to finish without being restarted every frame.
    if
        condition_transition_target(
            native_state
        ) == target_state
    then
        state.condition_requested_state =
            native_state

        state.condition_skip_count =
            (
                tonumber(
                    state.condition_skip_count
                ) or 0
            ) + 1

        return
    end

    if native_state == target_state then
        state.condition_requested_state =
            target_state

        state.condition_skip_count =
            (
                tonumber(
                    state.condition_skip_count
                ) or 0
            ) + 1

        return
    end

    -- Duplicate getter metadata can resolve to INVALID even though the live
    -- VitalConditionGui is valid. In that case, do not restart a transition
    -- every frame. Write the stable target directly once.
    if native_state == CONDITION_STATE.INVALID then
        if
            tonumber(
                state.condition_last_applied_target
            ) == target_state
        then
            state.condition_requested_state =
                target_state

            state.condition_skip_count =
                (
                    tonumber(
                        state.condition_skip_count
                    ) or 0
                ) + 1

            return
        end

        local applied = false
        local last_error = ""

        if set_curr_state_method ~= nil then
            local ok, err =
                pcall(function()
                    set_curr_state_method:call(
                        condition_gui,
                        target_state
                    )
                end)

            if ok then
                applied = true
            else
                last_error =
                    tostring(err)
            end
        end

        if not applied then
            local ok, err =
                pcall(function()
                    set_state_method:call(
                        condition_gui,
                        target_state
                    )
                end)

            if ok then
                applied = true
            else
                last_error =
                    tostring(err)
            end
        end

        if not applied then
            state.condition_last_error =
                last_error ~= ""
                and last_error
                or "No direct condition-state setter succeeded."

            return
        end

        state.condition_requested_state =
            target_state

        state.condition_last_applied_target =
            target_state

        state.condition_last_stable_state =
            target_state

        state.condition_direct_fallback_count =
            (
                tonumber(
                    state.condition_direct_fallback_count
                ) or 0
            ) + 1

        state.condition_apply_count =
            (
                tonumber(
                    state.condition_apply_count
                ) or 0
            ) + 1

        state.condition_last_error =
            ""

        return
    end

    local requested_state =
        choose_condition_transition(
            native_state,
            state.condition_last_stable_state,
            target_state
        )

    -- Avoid restarting the same transition continuously.
    if
        tonumber(
            state.condition_requested_state
        ) == requested_state
    then
        state.condition_skip_count =
            (
                tonumber(
                    state.condition_skip_count
                ) or 0
            ) + 1

        return
    end

    local ok, err =
        pcall(function()
            set_state_method:call(
                condition_gui,
                requested_state
            )
        end)

    if not ok then
        state.condition_last_error =
            tostring(err)

        return
    end

    state.condition_requested_state =
        requested_state

    state.condition_last_applied_target =
        target_state

    state.condition_transition_count =
        (
            tonumber(
                state.condition_transition_count
            ) or 0
        ) + 1

    state.condition_apply_count =
        (
            tonumber(
                state.condition_apply_count
            ) or 0
        ) + 1

    state.condition_last_error =
        ""
end

local function safe_visual_field(object, field_name)
    if object == nil then
        return nil
    end

    local ok, value =
        pcall(function()
            return object:get_field(
                field_name
            )
        end)

    if ok then
        return value
    end

    return nil
end

local function safe_visual_call(object, method_names)
    if object == nil then
        return nil
    end

    for _, method_name in ipairs(method_names) do
        local ok, value =
            pcall(function()
                local td =
                    object:get_type_definition()

                local method =
                    td:get_method(
                        method_name
                    )

                if method == nil then
                    return nil
                end

                return method:call(
                    object
                )
            end)

        if ok and value ~= nil then
            return value
        end
    end

    return nil
end

local function visual_value_text(value)
    if value == nil then
        return "unknown"
    end

    local ok, text =
        pcall(function()
            return tostring(value)
        end)

    if ok then
        return text
    end

    return "<unreadable>"
end

local function capture_condition_visual_object(
    ctx,
    object,
    prefix
)
    local state =
        ctx.state

    if object == nil then
        state[prefix .. "_type"] =
            "nil"

        state[prefix .. "_ptr"] =
            "nil"

        state[prefix .. "_state"] =
            "unknown"

        state[prefix .. "_visible"] =
            "unknown"

        state[prefix .. "_color_scale"] =
            "unknown"

        state[prefix .. "_play_frame"] =
            "unknown"

        return
    end

    state[prefix .. "_type"] =
        ctx.type_name_from_obj(
            object
        )

    state[prefix .. "_ptr"] =
        ctx.ptr_from_obj(
            object
        )

    state[prefix .. "_state"] =
        visual_value_text(
            safe_visual_call(
                object,
                {
                    "get_CurrState",
                    "get_CurrState()",
                    "get_State",
                    "get_State()"
                }
            )
        )

    state[prefix .. "_visible"] =
        visual_value_text(
            safe_visual_call(
                object,
                {
                    "get_Visible",
                    "get_Visible()",
                    "get_IsVisible",
                    "get_IsVisible()"
                }
            )
        )

    state[prefix .. "_color_scale"] =
        visual_value_text(
            safe_visual_call(
                object,
                {
                    "get_ColorScale",
                    "get_ColorScale()",
                    "get_Color",
                    "get_Color()"
                }
            )
        )

    state[prefix .. "_play_frame"] =
        visual_value_text(
            safe_visual_call(
                object,
                {
                    "get_PlayFrame",
                    "get_PlayFrame()",
                    "get_CurrFrame",
                    "get_CurrFrame()"
                }
            )
        )
end

local function reflection_type_name(ctx, value)
    if value == nil then
        return "nil"
    end

    local lua_type =
        type(value)

    if lua_type ~= "userdata" then
        return lua_type
    end

    local ok, result =
        pcall(function()
            return ctx.type_name_from_obj(value)
        end)

    if ok and result ~= nil then
        return tostring(result)
    end

    return "userdata"
end

local function reflection_ptr(ctx, value)
    if value == nil then
        return "nil"
    end

    if type(value) ~= "userdata" then
        return "n/a"
    end

    local ok, result =
        pcall(function()
            return ctx.ptr_from_obj(value)
        end)

    if ok and result ~= nil then
        return tostring(result)
    end

    return "managed"
end

local function reflection_value_text(value)
    local value_type = type(value)

    if value == nil then return "nil" end

    if
        value_type == "number" or
        value_type == "boolean" or
        value_type == "string"
    then
        return tostring(value)
    end

    return "<object>"
end

local function reflection_type_full_name(type_definition)
    if type_definition == nil then
        return "unknown"
    end

    local ok, name =
        pcall(function()
            return type_definition:get_full_name()
        end)

    if ok and name ~= nil then
        return tostring(name)
    end

    return "unknown"
end

local function reflection_parent_type(type_definition)
    if type_definition == nil then
        return nil
    end

    local candidates = {
        "get_parent_type",
        "get_parent_type_definition",
        "get_base_type",
        "get_base_type_definition"
    }

    for _, method_name in ipairs(candidates) do
        local ok, parent =
            pcall(function()
                local method =
                    type_definition[method_name]

                if method == nil then
                    return nil
                end

                return method(
                    type_definition
                )
            end)

        if ok and parent ~= nil then
            return parent
        end
    end

    return nil
end

local function capture_object_fields(ctx, object, max_fields)
    local rows = {}
    local hierarchy = {}

    if object == nil then
        return rows, "Object is nil.", ""
    end

    local ok, err =
        pcall(function()
            local root_td =
                object:get_type_definition()

            if root_td == nil then
                error("Type definition is nil.")
            end

            local limit =
                math.max(
                    1,
                    math.floor(
                        tonumber(max_fields) or 64
                    )
                )

            local seen_fields = {}
            local current_td = root_td
            local depth = 0

            while
                current_td ~= nil and
                depth < 12 and
                #rows < limit
            do
                depth = depth + 1

                local owner_type =
                    reflection_type_full_name(
                        current_td
                    )

                hierarchy[#hierarchy + 1] =
                    owner_type

                local fields = {}

                local fields_ok, reflected_fields =
                    pcall(function()
                        return current_td:get_fields()
                    end)

                if fields_ok and reflected_fields ~= nil then
                    fields = reflected_fields
                end

                for _, field in ipairs(fields) do
                    if #rows >= limit then
                        break
                    end

                    local field_name =
                        tostring(
                            field:get_name()
                        )

                    local unique_key =
                        owner_type ..
                        "::" ..
                        field_name

                    if not seen_fields[unique_key] then
                        seen_fields[unique_key] = true

                        local declared_type = "unknown"

                        pcall(function()
                            local field_type =
                                field:get_type()

                            if field_type ~= nil then
                                declared_type =
                                    tostring(
                                        field_type:get_full_name()
                                    )
                            end
                        end)

                        local value = nil
                        local read_error = ""

                        local read_ok, read_result =
                            pcall(function()
                                return object:get_field(
                                    field_name
                                )
                            end)

                        if read_ok then
                            value = read_result
                        else
                            read_error =
                                tostring(read_result)
                        end

                        rows[#rows + 1] = {
                            index = #rows + 1,
                            name = field_name,
                            owner_type = owner_type,
                            declared_type = declared_type,
                            runtime_type =
                                reflection_type_name(
                                    ctx,
                                    value
                                ),
                            ptr =
                                reflection_ptr(
                                    ctx,
                                    value
                                ),
                            value =
                                reflection_value_text(
                                    value
                                ),
                            read_error = read_error,
                            object =
                                type(value) == "userdata"
                                and value
                                or nil
                        }
                    end
                end

                current_td =
                    reflection_parent_type(
                        current_td
                    )
            end
        end)

    if not ok then
        return rows, tostring(err), table.concat(hierarchy, " -> ")
    end

    return
        rows,
        "",
        table.concat(
            hierarchy,
            " -> "
        )
end


local function capture_vital_gauge_reflection(ctx, vital_gauge)
    local state = ctx.state

    if
        state.vital_gauge_reflection_enabled ~= true or
        vital_gauge == nil
    then
        return
    end

    if
        state.vital_gauge_reflection_capture_requested ~= true and
        (tonumber(state.vital_gauge_reflection_capture_count) or 0) > 0
    then
        return
    end

    local rows,
          error_text,
          root_hierarchy =
        capture_object_fields(
            ctx,
            vital_gauge,
            state.vital_gauge_reflection_max_fields
        )

    state.vital_gauge_reflection_rows = rows

    state.vital_gauge_reflection_root_hierarchy =
        root_hierarchy
    state.vital_gauge_reflection_capture_count =
        (tonumber(state.vital_gauge_reflection_capture_count) or 0) + 1
    state.vital_gauge_reflection_capture_requested = false
    state.vital_gauge_reflection_last_error = error_text

    local selected_index =
        math.floor(
            tonumber(state.vital_gauge_reflection_selected_index) or 0
        )

    local selected = rows[selected_index]

    if selected ~= nil then
        state.vital_gauge_reflection_selected_field =
            selected.name or ""

        state.vital_gauge_reflection_selected_type =
            selected.runtime_type or "unknown"

        state.vital_gauge_reflection_selected_ptr =
            selected.ptr or "nil"

        if selected.object ~= nil then
            local child_rows,
                  child_error,
                  child_hierarchy =
                capture_object_fields(
                    ctx,
                    selected.object,
                    96
                )

            state.vital_gauge_reflection_child_rows =
                child_rows

            state.vital_gauge_reflection_child_hierarchy =
                child_hierarchy

            if child_error ~= "" then
                state.vital_gauge_reflection_last_error =
                    child_error
            end
        else
            state.vital_gauge_reflection_child_rows = {}

            state.vital_gauge_reflection_child_hierarchy =
                ""

            -- Primitive fields are valid selections, but they do not have
            -- reflected child fields.
            if error_text == "" then
                state.vital_gauge_reflection_last_error = ""
            end
        end
    else
        state.vital_gauge_reflection_selected_field = ""
        state.vital_gauge_reflection_selected_type = "unknown"
        state.vital_gauge_reflection_selected_ptr = "nil"
        state.vital_gauge_reflection_child_rows = {}
    end
end


local function capture_condition_visual_probe(
    ctx,
    condition_gui
)
    local state =
        ctx.state

    if
        state.condition_visual_probe_enabled ~= true or
        condition_gui == nil
    then
        return
    end

    local ok, err =
        pcall(function()
            local vital_gauge =
                safe_visual_field(
                    condition_gui,
                    "_VitalGaugeGui"
                )

            ctx.vital_gauge_reflection_object =
                vital_gauge

            local damage_flare =
                safe_visual_field(
                    condition_gui,
                    "_DamageFlareGui"
                )

            local amount_gui =
                safe_visual_field(
                    condition_gui,
                    "_AmountGui"
                )

            capture_condition_visual_object(
                ctx,
                vital_gauge,
                "vital_gauge"
            )

            capture_vital_gauge_reflection(
                ctx,
                vital_gauge
            )

            capture_condition_visual_object(
                ctx,
                damage_flare,
                "damage_flare"
            )

            if amount_gui ~= nil then
                state.amount_gui_type =
                    ctx.type_name_from_obj(
                        amount_gui
                    )

                state.amount_gui_ptr =
                    ctx.ptr_from_obj(
                        amount_gui
                    )
            else
                state.amount_gui_type =
                    "nil"

                state.amount_gui_ptr =
                    "nil"
            end

            state.condition_visual_probe_count =
                (
                    tonumber(
                        state.condition_visual_probe_count
                    ) or 0
                ) + 1

            state.condition_visual_probe_last_error =
                ""
        end)

    if not ok then
        state.condition_visual_probe_last_error =
            tostring(err)
    end
end



local function behavior_safe_field(object, field_name, fallback)
    if object == nil then
        return fallback
    end

    local ok, value =
        pcall(function()
            return object:get_field(field_name)
        end)

    if ok and value ~= nil then
        return value
    end

    return fallback
end

local function behavior_safe_call(object, method, fallback)
    if object == nil or method == nil then
        return fallback
    end

    local ok, value =
        pcall(function()
            return method:call(object)
        end)

    if ok and value ~= nil then
        return value
    end

    return fallback
end

local function behavior_read_condition_state(
    condition_gui,
    getter_name,
    field_name
)
    if condition_gui == nil then
        return -1
    end

    local ok, value =
        pcall(function()
            local td =
                condition_gui:get_type_definition()

            local getter =
                td:get_method(getter_name)
                or td:get_method(getter_name .. "()")

            if getter ~= nil then
                return getter:call(condition_gui)
            end

            return condition_gui:get_field(field_name)
        end)

    if ok and value ~= nil then
        return tonumber(value) or -1
    end

    return -1
end

local function behavior_read_float(
    object,
    getter_name,
    field_name
)
    if object == nil then
        return 0.0
    end

    local ok, value =
        pcall(function()
            local td =
                object:get_type_definition()

            local getter =
                td:get_method(getter_name)
                or td:get_method(getter_name .. "()")

            if getter ~= nil then
                return getter:call(object)
            end

            return object:get_field(field_name)
        end)

    if ok and value ~= nil then
        return tonumber(value) or 0.0
    end

    return 0.0
end

local function append_vital_behavior_history(ctx, event_name)
    local state = ctx.state
    local history = state.vital_behavior_history or {}

    history[#history + 1] = string.format(
        "%s step=%d requested=%d org=%d col=%d hp=%d/%d ratio=%.4f time=%.4f",
        tostring(event_name),
        tonumber(state.vital_behavior_curr_step) or -1,
        tonumber(state.vital_behavior_requested_step) or -1,
        tonumber(state.vital_behavior_org_curr_state) or -1,
        tonumber(state.vital_behavior_col_curr_state) or -1,
        tonumber(state.vital_behavior_hp) or 0,
        tonumber(state.vital_behavior_max_hp) or 0,
        tonumber(state.vital_behavior_hp_ratio) or 0.0,
        tonumber(state.vital_behavior_remaining_display_time) or 0.0
    )

    while #history > 32 do
        table.remove(history, 1)
    end

    state.vital_behavior_history = history
end

-- VitalGuiBehavior.Step is the reliable native HUD state machine.
-- WaitEnd (4) is fully hidden; every other valid step may render.
local function update_native_hp_visibility_from_curr_step(ctx)
    local state = ctx.state

    local curr_step =
        tonumber(
            state.vital_behavior_curr_step
        ) or -1

    local hidden_step =
        tonumber(
            state.native_hp_hidden_step
        ) or 4

    local was_known =
        state.native_hp_bar_visibility_known == true

    local was_visible =
        state.native_hp_bar_visible == true

    local known =
        curr_step >= 0

    -- Only the confirmed hidden state suppresses the overlay.
    -- Opening, shown, closing, and any other valid transition state draw.
    local visible =
        known and
        curr_step ~= hidden_step

    state.native_hp_bar_visibility_known =
        known

    if known then
        state.native_hp_bar_visible =
            visible

        state.native_hp_last_classified_step =
            curr_step

        state.native_hp_bar_visibility_source =
            string.format(
                "VitalGuiBehavior.CurrStep=%d (hidden=%d)",
                curr_step,
                hidden_step
            )

        state.native_hp_bar_visibility_checks =
            (
                tonumber(
                    state.native_hp_bar_visibility_checks
                ) or 0
            ) + 1

        if
            not was_known or
            was_visible ~= visible
        then
            state.native_hp_visibility_change_count =
                (
                    tonumber(
                        state.native_hp_visibility_change_count
                    ) or 0
                ) + 1
        end

        state.native_hp_bar_visibility_error =
            ""
    else
        -- Fail open until the first valid CurrStep arrives.
        state.native_hp_bar_visible =
            true

        state.native_hp_bar_visibility_source =
            "CurrStep unavailable (fail-open)"
    end
end

local function capture_vital_behavior(
    ctx,
    behavior,
    event_name,
    requested_step,
    curr_step_method,
    remaining_time_method
)
    local state = ctx.state

    if
        state.vital_behavior_probe_enabled ~= true or
        behavior == nil
    then
        return
    end

    local ok, err =
        pcall(function()
            state.vital_behavior_type =
                ctx.type_name_from_obj(behavior)

            state.vital_behavior_ptr =
                ctx.ptr_from_obj(behavior)

            local curr_step =
                behavior_safe_call(
                    behavior,
                    curr_step_method,
                    nil
                )

            if curr_step == nil then
                curr_step =
                    behavior_safe_field(
                        behavior,
                        "<CurrStep>k__BackingField",
                        -1
                    )
            end

            state.vital_behavior_curr_step =
                tonumber(curr_step) or -1

            update_native_hp_visibility_from_curr_step(
                ctx
            )

            if requested_step ~= nil then
                state.vital_behavior_requested_step =
                    tonumber(requested_step) or -1
            end

            local remaining_time =
                behavior_safe_call(
                    behavior,
                    remaining_time_method,
                    nil
                )

            if remaining_time == nil then
                remaining_time =
                    behavior_safe_field(
                        behavior,
                        "<RemainingDisplayTime>k__BackingField",
                        0.0
                    )
            end

            state.vital_behavior_remaining_display_time =
                tonumber(remaining_time) or 0.0

            local org_gui =
                behavior_safe_field(
                    behavior,
                    "_VitalConditionGuiOrg",
                    nil
                )

            local col_gui =
                behavior_safe_field(
                    behavior,
                    "_VitalConditionGuiCol",
                    nil
                )

            if org_gui ~= nil then
                state.vital_behavior_org_type =
                    ctx.type_name_from_obj(org_gui)

                state.vital_behavior_org_ptr =
                    ctx.ptr_from_obj(org_gui)

                state.vital_behavior_org_prev_state =
                    behavior_read_condition_state(
                        org_gui,
                        "get_PrevState",
                        "<PrevState>k__BackingField"
                    )

                state.vital_behavior_org_curr_state =
                    behavior_read_condition_state(
                        org_gui,
                        "get_CurrState",
                        "<CurrState>k__BackingField"
                    )

                state.vital_behavior_org_curr_frame =
                    behavior_read_float(
                        org_gui,
                        "get_CurrFrame",
                        "<CurrFrame>k__BackingField"
                    )
            else
                state.vital_behavior_org_type = "nil"
                state.vital_behavior_org_ptr = "nil"
                state.vital_behavior_org_prev_state = -1
                state.vital_behavior_org_curr_state = -1
                state.vital_behavior_org_curr_frame = 0.0
            end

            if col_gui ~= nil then
                state.vital_behavior_col_type =
                    ctx.type_name_from_obj(col_gui)

                state.vital_behavior_col_ptr =
                    ctx.ptr_from_obj(col_gui)

                state.vital_behavior_col_prev_state =
                    behavior_read_condition_state(
                        col_gui,
                        "get_PrevState",
                        "<PrevState>k__BackingField"
                    )

                state.vital_behavior_col_curr_state =
                    behavior_read_condition_state(
                        col_gui,
                        "get_CurrState",
                        "<CurrState>k__BackingField"
                    )

                state.vital_behavior_col_curr_frame =
                    behavior_read_float(
                        col_gui,
                        "get_CurrFrame",
                        "<CurrFrame>k__BackingField"
                    )
            else
                state.vital_behavior_col_type = "nil"
                state.vital_behavior_col_ptr = "nil"
                state.vital_behavior_col_prev_state = -1
                state.vital_behavior_col_curr_state = -1
                state.vital_behavior_col_curr_frame = 0.0
            end

            local current_hp =
                tonumber(ctx.current_hp_number()) or 0

            local max_hp =
                tonumber(ctx.max_hp_number()) or 0

            state.vital_behavior_hp =
                current_hp

            state.vital_behavior_max_hp =
                max_hp

            state.vital_behavior_hp_ratio =
                max_hp > 0
                and math.max(
                    0.0,
                    math.min(current_hp / max_hp, 1.0)
                )
                or 0.0

            state.vital_behavior_capture_count =
                (tonumber(state.vital_behavior_capture_count) or 0) + 1

            state.vital_behavior_last_event =
                tostring(event_name)

            append_vital_behavior_history(
                ctx,
                event_name
            )

            state.vital_behavior_probe_error = ""
        end)

    if not ok then
        state.vital_behavior_probe_error =
            tostring(err)
    end
end

local function install_vital_behavior_probe(ctx)
    if ctx.state.vital_behavior_probe_installed == true then
        return
    end

    local ok, err =
        pcall(function()
            local td =
                sdk.find_type_definition(
                    "chainsaw.VitalGuiBehavior"
                )

            if td == nil then
                error("No chainsaw.VitalGuiBehavior")
            end

            local change_step =
                td:get_method(
                    "changeStep(chainsaw.VitalGuiBehavior.Step)"
                )
                or td:get_method("changeStep")

            local late_update =
                td:get_method("lateUpdate()")
                or td:get_method("lateUpdate")

            local get_curr_step =
                td:get_method("get_CurrStep")
                or td:get_method("get_CurrStep()")

            local get_remaining_time =
                td:get_method("get_RemainingDisplayTime")
                or td:get_method("get_RemainingDisplayTime()")

            if change_step == nil then
                error("No VitalGuiBehavior.changeStep")
            end

            if late_update == nil then
                error("No VitalGuiBehavior.lateUpdate")
            end

            local change_stack = {}

            sdk.hook(
                change_step,
                function(args)
                    local behavior =
                        ctx.managed_from_arg(args, 2)

                    local requested_step = -1

                    if args[3] ~= nil then
                        requested_step =
                            ctx.signed_int32(args[3])
                    end

                    change_stack[#change_stack + 1] = {
                        behavior = behavior,
                        requested_step = requested_step
                    }

                    ctx.state.vital_behavior_change_step_calls =
                        (tonumber(
                            ctx.state.vital_behavior_change_step_calls
                        ) or 0) + 1

                    capture_vital_behavior(
                        ctx,
                        behavior,
                        "changeStep:enter",
                        requested_step,
                        get_curr_step,
                        get_remaining_time
                    )
                end,
                function(retval)
                    local pending =
                        change_stack[#change_stack]

                    change_stack[#change_stack] = nil

                    if pending ~= nil then
                        capture_vital_behavior(
                            ctx,
                            pending.behavior,
                            "changeStep:exit",
                            pending.requested_step,
                            get_curr_step,
                            get_remaining_time
                        )
                    end

                    return retval
                end
            )

            local late_stack = {}

            sdk.hook(
                late_update,
                function(args)
                    local behavior =
                        ctx.managed_from_arg(args, 2)

                    late_stack[#late_stack + 1] =
                        behavior

                    ctx.state.vital_behavior_late_update_calls =
                        (tonumber(
                            ctx.state.vital_behavior_late_update_calls
                        ) or 0) + 1
                end,
                function(retval)
                    local behavior =
                        late_stack[#late_stack]

                    late_stack[#late_stack] = nil

                    capture_vital_behavior(
                        ctx,
                        behavior,
                        "lateUpdate:exit",
                        nil,
                        get_curr_step,
                        get_remaining_time
                    )

                    return retval
                end
            )

            ctx.state.vital_behavior_probe_installed =
                true
        end)

    if not ok then
        ctx.state.vital_behavior_probe_error =
            tostring(err)

        ctx.set_error(
            "VitalGuiBehavior probe install: " ..
            tostring(err)
        )
    end
end

local function install_native_damage_probe(ctx)
    if ctx.native_damage.installed then
        return
    end

    local ok, err = pcall(function()
        local td =
            sdk.find_type_definition(
                "chainsaw.VitalConditionGui"
            )

        if td == nil then
            error(
                "No chainsaw.VitalConditionGui"
            )
        end

        local update_method =
            td:get_method(
                "update(System.Single elapsedSec)"
            )
            or td:get_method(
                "update(System.Single)"
            )

        local get_state_method =
            td:get_method(
                "get_CurrState"
            )
            or td:get_method(
                "get_CurrState()"
            )

        local set_state_method =
            td:get_method(
                "setState"
            )
            or td:get_method(
                "setState(chainsaw.VitalConditionGui.ConditionPanelState)"
            )

        local set_curr_state_method =
            td:get_method(
                "set_CurrState"
            )
            or td:get_method(
                "set_CurrState(chainsaw.VitalConditionGui.ConditionPanelState)"
            )
            or td:get_method(
                "set_CurrState(chainsaw.VitalConditionGui.ConditionPanelState value)"
            )

        if update_method == nil then
            error(
                "No VitalConditionGui.update(System.Single)"
            )
        end

        local pending_gui = nil
        local pending_elapsed = 0.0

        sdk.hook(
            update_method,
            function(args)
                pending_gui = nil
                pending_elapsed = 0.0

                local gui_ok, condition_gui =
                    pcall(function()
                        return sdk.to_managed_object(
                            args[2]
                        )
                    end)

                if gui_ok then
                    pending_gui =
                        condition_gui
                end

                if args[3] ~= nil then
                    local elapsed_ok, elapsed =
                        pcall(function()
                            return sdk.to_float(
                                args[3]
                            )
                        end)

                    if elapsed_ok then
                        pending_elapsed =
                            tonumber(elapsed) or 0.0
                    end
                end
            end,
            function(retval)
                refresh_native_damage_probe(
                    ctx,
                    pending_gui,
                    pending_elapsed
                )

                apply_scaled_condition_state(
                    ctx,
                    pending_gui,
                    get_state_method,
                    set_state_method,
                    set_curr_state_method
                )

                capture_condition_visual_probe(
                    ctx,
                    pending_gui
                )

                pending_gui = nil
                pending_elapsed = 0.0

                return retval
            end
        )

        ctx.native_damage.installed = true
    end)

    if not ok then
        ctx.native_damage.last_error =
            tostring(err)

        ctx.set_error(
            "Native damage probe install: " ..
            tostring(err)
        )
    end
end

local function install_gauge_hooks(ctx)
    if ctx.state.gauge_hook_installed then
        return
    end

    local ok, err = pcall(function()
        local td =
            sdk.find_type_definition(
                "chainsaw.VitalGaugeGui"
            )

        if td == nil then
            error("No chainsaw.VitalGaugeGui")
        end

        local set_max =
            td:get_method("setMaxFrame(System.Single)")

        local set_rate =
            td:get_method("setCurrRate(System.Single)")

        local set_target =
            td:get_method(
                "setCurrTargetRate(System.Single)"
            )

        if set_max ~= nil then
            sdk.hook(
                set_max,
                function(args)
                    ctx.state.gauge_hook_calls =
                        ctx.state.gauge_hook_calls + 1

                    ctx.state.gauge_type =
                        ctx.type_name_from_obj(
                            ctx.managed_from_arg(args, 2)
                        )

                    ctx.state.gauge_max_frame =
                        tostring(sdk.to_float(args[3]))
                end,
                function(retval)
                    return retval
                end
            )
        end

        if set_rate ~= nil then
            sdk.hook(
                set_rate,
                function(args)
                    ctx.state.gauge_rate =
                        tostring(sdk.to_float(args[3]))
                end,
                function(retval)
                    return retval
                end
            )
        end

        if set_target ~= nil then
            sdk.hook(
                set_target,
                function(args)
                    ctx.state.gauge_target_rate =
                        tostring(sdk.to_float(args[3]))
                end,
                function(retval)
                    return retval
                end
            )
        end

        ctx.state.gauge_hook_installed = true
    end)

    if not ok then
        ctx.set_error(err)
    end
end

function hp.install(ctx)
    ensure_refresh_state(ctx)

    install_player_hook(ctx)
    install_hitpoint_hooks(ctx)
    install_preview_hook(ctx)

    -- Passive condition-level sampling only.
    install_native_damage_probe(ctx)

    -- Proven native visibility source. CurrStep == 4 is fully hidden.
    install_vital_behavior_probe(ctx)

    -- Direct VitalGaugeGui setters are diagnostic-only and do not drive the
    -- custom renderer, but the known-working HUD build installed these hooks.
    install_gauge_hooks(ctx)

    ctx.state.safe_compatibility_mode = true
    ctx.state.object_explorer_isolation_mode = false

    ctx.state.status =
        "Health, Vitality, and native HUD visibility hooks active."
end

return hp
