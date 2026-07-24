------------------------------------------------------------
-- Maintenance classification — Build 49.39
-- Module: autorun/project_overflow/ui/main.lua
-- Role: ImGui or native-overlay presentation and diagnostics.
-- Status: active UI.
--
-- Compatibility policy:
--   Existing functions, hooks, module paths, and diagnostics are
--   intentionally retained in this maintenance pass.
--   `DEPRECATED` marks a supported legacy path, not removed code.
------------------------------------------------------------

------------------------------------------------------------
-- Project: Overflow — Configuration UI
--
-- Provides the release-facing controls, About and credits page,
-- and an optional Developer Mode for the reverse-engineering tools.
------------------------------------------------------------

local ui_mod = {}
local project = require("project_overflow.version")
local about_ui = require("project_overflow.ui.about")
local rpg_ui = require("project_overflow.ui.rpg")
local enemies_ui = require("project_overflow.ui.enemies")
local cheats_ui = require("project_overflow.ui.cheats")
local xp_controls =
    require("project_overflow.xp.controls")

local function ui_value(label, value)
    imgui.text(label .. " : " .. tostring(value))
end

local function ui_text_wrapped(text)
    -- Some REFramework ImGui builds do not expose text_wrapped().
    -- Fall back to normal text instead of breaking the entire UI.
    if imgui.text_wrapped ~= nil then
        imgui.text_wrapped(tostring(text))
        return
    end

    imgui.text(tostring(text))
end

local function ui_button_row(a, b, c)
    local pressed = nil

    if imgui.button(a) then pressed = a end

    if b ~= nil then
        imgui.same_line()
        if imgui.button(b) then pressed = b end
    end

    if c ~= nil then
        imgui.same_line()
        if imgui.button(c) then pressed = c end
    end

    return pressed
end

local function draw_overflow_debug_bar(ctx)
    if not ctx.state.draw_overlay_debug then return end

    local current_hp = ctx.current_hp_number()
    local max_hp = ctx.max_hp_number()
    if current_hp == nil or max_hp == nil then return end

    local vanilla_ratio =
        ctx.clamp(math.min(current_hp, ctx.state.overflow_start_hp) / ctx.state.overflow_start_hp, 0, 1)

    imgui.separator()
    imgui.text("Bonus HP Ring")

    imgui.text("Vanilla Layer")
    imgui.text(
        tostring(
            math.floor(
                math.min(
                    current_hp,
                    ctx.state.visual_gauge_cap
                )
            )
        ) ..
        " / " ..
        tostring(ctx.state.visual_gauge_cap)
    )

    imgui.progress_bar(
        vanilla_ratio,
        260
    )

    imgui.text("Overflow Layer")
    imgui.text(
        tostring(
            math.floor(
                ctx.state.overflow_current
            )
        ) ..
        " / " ..
        tostring(
            math.floor(
                ctx.state.overflow_max
            )
        )
    )

    imgui.progress_bar(
        ctx.state.overflow_ratio,
        260
    )
end

local function condition_state_name(value)
    local names = {
        [-1] = "INVALID",
        [0] = "FINE",
        [1] = "FINE_TO_DANGER",
        [2] = "FINE_TO_CAUTION",
        [3] = "CAUTION",
        [4] = "CAUTION_TO_FINE",
        [5] = "CAUTION_TO_DANGER",
        [6] = "DANGER",
        [7] = "DANGER_TO_FINE",
        [8] = "DANGER_TO_CAUTION"
    }

    return
        names[
            tonumber(value) or -1
        ]
        or tostring(value)
end


local function draw_reflection_rows(rows)
    for _, row in ipairs(rows or {}) do
        imgui.separator()
        ui_value("Index", row.index or 0)
        ui_value("Field", row.name or "unknown")
        ui_value("Owner Type", row.owner_type or "unknown")
        ui_value("Declared Type", row.declared_type or "unknown")
        ui_value("Runtime Type", row.runtime_type or "unknown")
        ui_value("Ptr", row.ptr or "nil")
        ui_value("Value", row.value or "")

        if
            row.read_error ~= nil and
            row.read_error ~= ""
        then
            ui_value("Read Error", row.read_error)
        end
    end
end

local function draw_vital_gauge_reflection_explorer(ctx)
    if not imgui.tree_node(
        "VitalGaugeGui Reflection Explorer"
    ) then
        return
    end

    local state = ctx.state
    local changed

    changed,
    state.vital_gauge_reflection_enabled =
        imgui.checkbox(
            "Enable Reflection Explorer",
            state.vital_gauge_reflection_enabled == true
        )

    changed,
    state.vital_gauge_reflection_max_fields =
        imgui.drag_int(
            "Max Fields",
            tonumber(state.vital_gauge_reflection_max_fields) or 64,
            1,
            1,
            128
        )

    changed,
    state.vital_gauge_reflection_selected_index =
        imgui.drag_int(
            "Selected Field Index",
            tonumber(state.vital_gauge_reflection_selected_index) or 0,
            1,
            0,
            128
        )

    if imgui.button("Capture / Refresh Fields") then
        state.vital_gauge_reflection_capture_requested = true

        if
            tonumber(
                state.vital_gauge_reflection_capture_count
            ) == 0
        then
            state.vital_gauge_reflection_selected_index = 0
        end
    end

    ui_value(
        "Capture Count",
        state.vital_gauge_reflection_capture_count
    )

    ui_value(
        "Capture Requested",
        state.vital_gauge_reflection_capture_requested
    )

    ui_value(
        "VitalGauge Object Cached",
        ctx.vital_gauge_reflection_object ~= nil
    )

    ui_value(
        "Selected Field",
        state.vital_gauge_reflection_selected_field
    )

    ui_value(
        "Selected Runtime Type",
        state.vital_gauge_reflection_selected_type
    )

    ui_value(
        "Selected Ptr",
        state.vital_gauge_reflection_selected_ptr
    )

    ui_value(
        "Selected Has Child Object",
        (
            state.vital_gauge_reflection_selected_ptr ~= "nil" and
            state.vital_gauge_reflection_selected_ptr ~= "n/a"
        )
    )

    ui_value(
        "Root Type Hierarchy",
        state.vital_gauge_reflection_root_hierarchy
    )

    ui_value(
        "Selected Child Hierarchy",
        state.vital_gauge_reflection_child_hierarchy
    )

    ui_value(
        "Explorer Error",
        state.vital_gauge_reflection_last_error
    )

    if imgui.tree_node("VitalGaugeGui Fields") then
        draw_reflection_rows(
            state.vital_gauge_reflection_rows
        )

        imgui.tree_pop()
    end

    if imgui.tree_node("Selected Child Fields") then
        draw_reflection_rows(
            state.vital_gauge_reflection_child_rows
        )

        imgui.tree_pop()
    end

    imgui.text(
        "Read-only: inherited fields are included. Select a managed field and refresh to inspect its full type hierarchy."
    )

    imgui.tree_pop()
end


local function vital_behavior_step_name(value)
    return tostring(tonumber(value) or -1)
end

local NATIVE_VISIBILITY_FIELDS = {
    {
        key = "curr_step",
        label = "VitalGuiBehavior CurrStep"
    },
    {
        key = "remaining_display_time",
        label = "RemainingDisplayTime"
    },
    {
        key = "org_prev_state",
        label = "Org PrevState"
    },
    {
        key = "org_curr_state",
        label = "Org CurrState"
    },
    {
        key = "org_curr_frame",
        label = "Org CurrFrame"
    },
    {
        key = "col_prev_state",
        label = "Col PrevState"
    },
    {
        key = "col_curr_state",
        label = "Col CurrState"
    },
    {
        key = "col_curr_frame",
        label = "Col CurrFrame"
    },
    {
        key = "gauge_curr_max_frame",
        label = "Gauge CurrMaxFrame"
    },
    {
        key = "gauge_curr_rate",
        label = "Gauge CurrRate"
    },
    {
        key = "gauge_curr_target_rate",
        label = "Gauge CurrTargetRate"
    },
    {
        key = "gauge_curr_rate_diff",
        label = "Gauge CurrRateDiff"
    },
    {
        key = "gauge_is_end",
        label = "Gauge IsEnd"
    },
    {
        key = "condition_curr_frame",
        label = "Condition CurrFrame"
    },
    {
        key = "condition_memory_frame",
        label = "Condition MemoryFrame"
    },
    {
        key = "condition_virtual_memory_frame",
        label = "Condition VirtualMemoryFrame"
    },
    {
        key = "condition_gradation_frame",
        label = "Condition GradationFrame"
    },
    {
        key = "condition_frame_diff",
        label = "Condition FrameDiff"
    }
}

local function native_visibility_snapshot(ctx)
    local state =
        ctx.state

    local native_damage =
        ctx.native_damage or {}

    return {
        curr_step =
            tonumber(
                state.vital_behavior_curr_step
            ) or -1,

        remaining_display_time =
            tonumber(
                state.vital_behavior_remaining_display_time
            ) or 0.0,

        org_prev_state =
            tonumber(
                state.vital_behavior_org_prev_state
            ) or -1,

        org_curr_state =
            tonumber(
                state.vital_behavior_org_curr_state
            ) or -1,

        org_curr_frame =
            tonumber(
                state.vital_behavior_org_curr_frame
            ) or 0.0,

        col_prev_state =
            tonumber(
                state.vital_behavior_col_prev_state
            ) or -1,

        col_curr_state =
            tonumber(
                state.vital_behavior_col_curr_state
            ) or -1,

        col_curr_frame =
            tonumber(
                state.vital_behavior_col_curr_frame
            ) or 0.0,

        gauge_curr_max_frame =
            tonumber(
                native_damage.gauge_curr_max_frame
            ) or 0.0,

        gauge_curr_rate =
            tonumber(
                native_damage.gauge_curr_rate
            ) or 0.0,

        gauge_curr_target_rate =
            tonumber(
                native_damage.gauge_curr_target_rate
            ) or 0.0,

        gauge_curr_rate_diff =
            tonumber(
                native_damage.gauge_curr_rate_diff
            ) or 0.0,

        gauge_is_end =
            native_damage.gauge_is_end == true,

        condition_curr_frame =
            tonumber(
                native_damage.curr_frame
            ) or 0.0,

        condition_memory_frame =
            tonumber(
                native_damage.curr_memory_frame
            ) or 0.0,

        condition_virtual_memory_frame =
            tonumber(
                native_damage.curr_virtual_memory_frame
            ) or 0.0,

        condition_gradation_frame =
            tonumber(
                native_damage.curr_gradation_frame
            ) or 0.0,

        condition_frame_diff =
            tonumber(
                native_damage.curr_frame_diff
            ) or 0.0
    }
end

local function snapshot_value_text(value)
    if type(value) == "number" then
        return string.format(
            "%.6f",
            value
        )
    end

    return tostring(value)
end

local function snapshot_values_differ(a, b)
    if
        type(a) == "number" and
        type(b) == "number"
    then
        return math.abs(a - b) > 0.0001
    end

    return a ~= b
end

local function draw_native_visibility_snapshot(
    title,
    snapshot
)
    if not imgui.tree_node(title) then
        return
    end

    if snapshot == nil then
        imgui.text("Not captured.")
        imgui.tree_pop()
        return
    end

    for _, field in ipairs(
        NATIVE_VISIBILITY_FIELDS
    ) do
        ui_value(
            field.label,
            snapshot_value_text(
                snapshot[field.key]
            )
        )
    end

    imgui.tree_pop()
end

local function draw_native_visibility_recorder(ctx)
    if not imgui.tree_node(
        "Native HUD Visibility Recorder"
    ) then
        return
    end

    local state =
        ctx.state

    imgui.text(
        "Use a stable frame: capture once with the vanilla bar visible, then once after it fully hides."
    )

    if imgui.button(
        "Capture Visible Snapshot"
    ) then
        state.native_visibility_visible_snapshot =
            native_visibility_snapshot(
                ctx
            )

        state.native_visibility_visible_capture_count =
            (
                tonumber(
                    state.native_visibility_visible_capture_count
                ) or 0
            ) + 1

        state.native_visibility_last_capture =
            "visible"
    end

    imgui.same_line()

    if imgui.button(
        "Capture Hidden Snapshot"
    ) then
        state.native_visibility_hidden_snapshot =
            native_visibility_snapshot(
                ctx
            )

        state.native_visibility_hidden_capture_count =
            (
                tonumber(
                    state.native_visibility_hidden_capture_count
                ) or 0
            ) + 1

        state.native_visibility_last_capture =
            "hidden"
    end

    ui_value(
        "Visible Captures",
        state.native_visibility_visible_capture_count
    )

    ui_value(
        "Hidden Captures",
        state.native_visibility_hidden_capture_count
    )

    ui_value(
        "Last Capture",
        state.native_visibility_last_capture
    )

    draw_native_visibility_snapshot(
        "Visible Snapshot",
        state.native_visibility_visible_snapshot
    )

    draw_native_visibility_snapshot(
        "Hidden Snapshot",
        state.native_visibility_hidden_snapshot
    )

    if imgui.tree_node("Difference View") then
        local visible =
            state.native_visibility_visible_snapshot

        local hidden =
            state.native_visibility_hidden_snapshot

        if visible == nil or hidden == nil then
            imgui.text(
                "Capture both snapshots first."
            )
        else
            local difference_count = 0

            for _, field in ipairs(
                NATIVE_VISIBILITY_FIELDS
            ) do
                local visible_value =
                    visible[field.key]

                local hidden_value =
                    hidden[field.key]

                if snapshot_values_differ(
                    visible_value,
                    hidden_value
                ) then
                    difference_count =
                        difference_count + 1

                    imgui.separator()

                    ui_value(
                        "Field",
                        field.label
                    )

                    ui_value(
                        "Visible",
                        snapshot_value_text(
                            visible_value
                        )
                    )

                    ui_value(
                        "Hidden",
                        snapshot_value_text(
                            hidden_value
                        )
                    )
                end
            end

            if difference_count == 0 then
                imgui.text(
                    "No sampled values changed."
                )
            end

            ui_value(
                "Difference Count",
                difference_count
            )
        end

        imgui.tree_pop()
    end

    imgui.text(
        "Read-only. This recorder does not control overlay visibility."
    )

    imgui.tree_pop()
end

local function draw_vital_behavior_probe(ctx)
    if not imgui.tree_node(
        "VitalGuiBehavior Transition Probe"
    ) then
        return
    end

    local state = ctx.state
    local changed

    changed,
    state.vital_behavior_probe_enabled =
        imgui.checkbox(
            "Enable Read-Only Behavior Probe",
            state.vital_behavior_probe_enabled == true
        )

    ui_value(
        "Installed",
        state.vital_behavior_probe_installed
    )

    ui_value(
        "Behavior Type",
        state.vital_behavior_type
    )

    ui_value(
        "Behavior Ptr",
        state.vital_behavior_ptr
    )

    ui_value(
        "changeStep Calls",
        state.vital_behavior_change_step_calls
    )

    ui_value(
        "lateUpdate Calls",
        state.vital_behavior_late_update_calls
    )

    ui_value(
        "Capture Count",
        state.vital_behavior_capture_count
    )

    ui_value(
        "Last Event",
        state.vital_behavior_last_event
    )

    imgui.separator()
    imgui.text("Parent State")

    ui_value(
        "CurrStep",
        vital_behavior_step_name(
            state.vital_behavior_curr_step
        )
    )

    ui_value(
        "Requested Step",
        vital_behavior_step_name(
            state.vital_behavior_requested_step
        )
    )

    ui_value(
        "Remaining Display Time",
        string.format(
            "%.6f",
            tonumber(
                state.vital_behavior_remaining_display_time
            ) or 0.0
        )
    )

    imgui.separator()
    imgui.text("Original Condition GUI")

    ui_value("Type", state.vital_behavior_org_type)
    ui_value("Ptr", state.vital_behavior_org_ptr)
    ui_value(
        "Prev State",
        condition_state_name(
            state.vital_behavior_org_prev_state
        )
    )
    ui_value(
        "Curr State",
        condition_state_name(
            state.vital_behavior_org_curr_state
        )
    )
    ui_value(
        "Curr Frame",
        string.format(
            "%.6f",
            tonumber(
                state.vital_behavior_org_curr_frame
            ) or 0.0
        )
    )

    imgui.separator()
    imgui.text("Color / Transition Condition GUI")

    ui_value("Type", state.vital_behavior_col_type)
    ui_value("Ptr", state.vital_behavior_col_ptr)
    ui_value(
        "Prev State",
        condition_state_name(
            state.vital_behavior_col_prev_state
        )
    )
    ui_value(
        "Curr State",
        condition_state_name(
            state.vital_behavior_col_curr_state
        )
    )
    ui_value(
        "Curr Frame",
        string.format(
            "%.6f",
            tonumber(
                state.vital_behavior_col_curr_frame
            ) or 0.0
        )
    )

    imgui.separator()
    imgui.text("HP Snapshot")

    ui_value("Current HP", state.vital_behavior_hp)
    ui_value("Actual Max HP", state.vital_behavior_max_hp)
    ui_value(
        "HP Ratio",
        string.format(
            "%.6f",
            tonumber(
                state.vital_behavior_hp_ratio
            ) or 0.0
        )
    )

    if imgui.tree_node("Transition History") then
        for index, line in ipairs(
            state.vital_behavior_history or {}
        ) do
            imgui.text(
                string.format(
                    "%02d %s",
                    index,
                    tostring(line)
                )
            )
        end

        imgui.tree_pop()
    end

    ui_value(
        "Probe Error",
        state.vital_behavior_probe_error
    )

    imgui.text(
        "Read-only: records changeStep() and lateUpdate() without forcing native state."
    )

    imgui.tree_pop()
end

local function draw_condition_visual_probe(ctx)
    if not imgui.tree_node(
        "Condition Visual Child Probe"
    ) then
        return
    end

    local state =
        ctx.state

    local changed

    changed,
    state.condition_visual_probe_enabled =
        imgui.checkbox(
            "Enable Read-Only Visual Probe",
            state.condition_visual_probe_enabled == true
        )

    ui_value(
        "Capture Count",
        state.condition_visual_probe_count
    )

    imgui.separator()
    imgui.text("VitalGaugeGui")

    ui_value(
        "Type",
        state.vital_gauge_type
    )

    ui_value(
        "Ptr",
        state.vital_gauge_ptr
    )

    ui_value(
        "State",
        state.vital_gauge_state
    )

    ui_value(
        "Visible",
        state.vital_gauge_visible
    )

    ui_value(
        "Color Scale",
        state.vital_gauge_color_scale
    )

    ui_value(
        "Play Frame",
        state.vital_gauge_play_frame
    )

    imgui.separator()
    imgui.text("DamageFlareGui")

    ui_value(
        "Type",
        state.damage_flare_type
    )

    ui_value(
        "Ptr",
        state.damage_flare_ptr
    )

    ui_value(
        "State",
        state.damage_flare_state
    )

    ui_value(
        "Visible",
        state.damage_flare_visible
    )

    ui_value(
        "Color Scale",
        state.damage_flare_color_scale
    )

    ui_value(
        "Play Frame",
        state.damage_flare_play_frame
    )

    imgui.separator()
    imgui.text("AmountGui")

    ui_value(
        "Type",
        state.amount_gui_type
    )

    ui_value(
        "Ptr",
        state.amount_gui_ptr
    )

    ui_value(
        "Probe Error",
        state.condition_visual_probe_last_error
    )

    imgui.text(
        "Read-only: samples child renderers from the confirmed VitalConditionGui instance."
    )

    imgui.tree_pop()
end

local function draw_scaled_condition_states(ctx)
    if not imgui.tree_node(
        "Scaled Fine / Caution / Danger"
    ) then
        return
    end

    local state = ctx.state
    local changed

    changed,
    state.condition_scaling_enabled =
        imgui.checkbox(
            "Enable Scaled Condition Math",
            state.condition_scaling_enabled == true
        )

    changed,
    state.condition_native_write_enabled =
        imgui.checkbox(
            "Experimental: Write Native Condition State",
            state.condition_native_write_enabled == true
        )

    ui_value(
        "Native Write Block Reason",
        state.condition_native_write_block_reason
    )

    imgui.text(
        "Keep native writes disabled while validating vanilla damage/heal previews."
    )

    changed,
    state.condition_caution_ratio =
        imgui.drag_float(
            "Caution Ratio",
            tonumber(
                state.condition_caution_ratio
            ) or 0.50,
            0.01,
            0.01,
            1.00
        )

    changed,
    state.condition_danger_ratio =
        imgui.drag_float(
            "Danger Ratio",
            tonumber(
                state.condition_danger_ratio
            ) or 0.25,
            0.01,
            0.00,
            tonumber(
                state.condition_caution_ratio
            ) or 0.50
        )

    imgui.separator()

    ui_value(
        "Current HP Ratio",
        string.format(
            "%.4f",
            tonumber(
                state.condition_current_ratio
            ) or 0.0
        )
    )

    ui_value(
        "Caution HP Threshold",
        state.condition_caution_hp
    )

    ui_value(
        "Danger HP Threshold",
        state.condition_danger_hp
    )

    ui_value(
        "Native State",
        condition_state_name(
            state.condition_native_state
        )
    )

    ui_value(
        "Target State",
        condition_state_name(
            state.condition_target_state
        )
    )

    ui_value(
        "Requested State",
        condition_state_name(
            state.condition_requested_state
        )
    )

    ui_value(
        "Last Stable State",
        condition_state_name(
            state.condition_last_stable_state
        )
    )

    ui_value(
        "Apply Count",
        state.condition_apply_count
    )

    ui_value(
        "Direct Fallback Count",
        state.condition_direct_fallback_count
    )

    ui_value(
        "Transition Count",
        state.condition_transition_count
    )

    ui_value(
        "Last Applied Target",
        condition_state_name(
            state.condition_last_applied_target
        )
    )

    ui_value(
        "Skip Count",
        state.condition_skip_count
    )

    ui_value(
        "Condition GUI Type",
        state.condition_gui_type
    )

    ui_value(
        "Condition GUI Ptr",
        state.condition_gui_ptr
    )

    ui_value(
        "Last Error",
        state.condition_last_error
    )

    imgui.text(
        "Thresholds always scale from the current actual Max HP."
    )

    imgui.tree_pop()
end

local function draw_health_state(ctx, hp)
    imgui.text("[PLAYER HEALTH]")
    imgui.separator()

    -- Always-visible cached state. Runtime refreshes these values independently
    -- of the UI, including a one-shot refresh at native save completion.
    ui_value("Current HP", ctx.state.current_hp)
    ui_value("Max HP", ctx.state.max_hp)
    ui_value("HP Ratio", ctx.state.hp_ratio)

    if imgui.tree_node("Health State") then
        if imgui.button("Refresh HitPoint Values") then hp.refresh(ctx) end

        if imgui.button("Recapture Player HP") then
            hp.clear_capture(ctx)
        end

        ui_value("Default Max HP", ctx.state.default_max_hp)
        ui_value("Vanilla Cap", ctx.state.vanilla_max_hp_cap)
        ui_value("Visual Gauge Cap", ctx.state.visual_gauge_cap)
        ui_value("Overflow Starts At", ctx.state.overflow_start_hp)
        ui_value("Overflow Ring HP", ctx.state.overflow_ring_hp)
        ui_value("Native Visual Full HP", ctx.state.native_visual_full_hp)
        ui_value("Minimum Custom Max HP", ctx.state.min_custom_max_hp)
        ui_value("Safe Total Cap", ctx.state.safe_total_hp_cap)

        imgui.separator()
        draw_scaled_condition_states(ctx)

        if ctx.state.developer_mode == true then
            imgui.separator()
            draw_condition_visual_probe(ctx)

            imgui.separator()
            draw_vital_behavior_probe(ctx)

            imgui.separator()
            draw_native_visibility_recorder(ctx)

            imgui.separator()
            draw_vital_gauge_reflection_explorer(ctx)
        elseif ctx.state.show_essential_diagnostics == true then
            imgui.separator()
            ui_value(
                "Native HUD Step",
                ctx.state.vital_behavior_curr_step
            )
            ui_value(
                "Native HUD Visible",
                ctx.state.native_hp_bar_visible
            )
            ui_value(
                "Native HUD Visibility Source",
                ctx.state.native_hp_bar_visibility_source
            )
            ui_value(
                "Condition Target",
                condition_state_name(
                    ctx.state.condition_target_state
                )
            )
        end

        changed, ctx.state.clamp_to_safe_cap =
            imgui.checkbox("Clamp to Safe Cap", ctx.state.clamp_to_safe_cap)

        imgui.tree_pop()
    end
end

local function draw_overflow(ctx)
    if imgui.tree_node("Overflow") then
        local active_ratio =
            tonumber(ctx.state.overflow_active_ratio) or 0.0

        local ring_capacity =
            tonumber(ctx.state.overflow_ring_hp) or 2500

        local active_ring_hp =
            tonumber(ctx.state.overflow_active_ring_hp) or 0

        local active_ring_index =
            tonumber(ctx.state.overflow_active_ring_index) or 0

        local completed_rings =
            tonumber(ctx.state.overflow_completed_rings) or 0

        local overflow_total_hp =
            tonumber(ctx.state.overflow_total_hp) or 0

        local visible_ring_hp =
            active_ratio >= 1.0
            and ring_capacity
            or active_ring_hp

        ui_value(
            "Overflow Total HP",
            overflow_total_hp
        )

        ui_value(
            "Completed Rings",
            completed_rings
        )

        ui_value(
            "Active Ring",
            active_ring_index + 1
        )

        ui_value(
            "Active Ring HP",
            string.format(
                "%d / %d",
                visible_ring_hp,
                ring_capacity
            )
        )

        ui_value(
            "Active Ratio",
            active_ratio
        )

        draw_overflow_debug_bar(ctx)

        imgui.tree_pop()
    end
end

local function draw_hp_controls(ctx, hp)
    imgui.text("[CONTROLS]")
    imgui.separator()

    if imgui.tree_node("HP Controls") then
        changed, ctx.ui.hp_amount =
            imgui.drag_int("HP Amount", ctx.ui.hp_amount, 1, 1, 5000)

        ctx.ui.hp_amount = ctx.clamp(ctx.ui.hp_amount, 1, 5000)

        local pressed = ui_button_row("Heal", "Damage", "Full Heal")

        if pressed == "Heal" then hp.heal(ctx, ctx.ui.hp_amount) end
        if pressed == "Damage" then hp.damage(ctx, ctx.ui.hp_amount) end
        if pressed == "Full Heal" then hp.full_heal(ctx) end

        changed, ctx.ui.set_current_hp =
            imgui.drag_int("Set Current HP", ctx.ui.set_current_hp, 1, 1, ctx.active_total_cap())

        if imgui.button("Apply Current HP") then
            hp.set_current(ctx, ctx.ui.set_current_hp)
        end

        imgui.tree_pop()
    end
end

local function draw_max_hp_controls(ctx, hp)
    if imgui.tree_node("Max HP Controls") then
        changed, ctx.ui.max_hp_amount =
            imgui.drag_int("Max HP Amount", ctx.ui.max_hp_amount, 1, 1, 5000)

        ctx.ui.max_hp_amount = ctx.clamp(ctx.ui.max_hp_amount, 1, 5000)

        local pressed = ui_button_row("Add Max HP", "Remove Max HP", nil)

        if pressed == "Add Max HP" then hp.add_max(ctx, ctx.ui.max_hp_amount) end
        if pressed == "Remove Max HP" then hp.add_max(ctx, -ctx.ui.max_hp_amount) end

        changed, ctx.ui.set_max_hp =
            imgui.drag_int("Set Max HP", ctx.ui.set_max_hp, 1, ctx.state.min_custom_max_hp, ctx.active_total_cap())

        if imgui.button("Apply Max HP") then
            hp.set_max(ctx, ctx.ui.set_max_hp)
        end

        local reset = ui_button_row("Reset Default", "Reset Vanilla Cap", nil)

        if reset == "Reset Default" then hp.reset_default(ctx) end
        if reset == "Reset Vanilla Cap" then hp.reset_vanilla(ctx) end

        imgui.tree_pop()
    end
end

local function draw_safe_ring_diagnostics(ctx)
    if not imgui.tree_node(
        "Ring Threshold Diagnostics — Read Only"
    ) then
        return
    end

    ui_value(
        "Current Ring",
        (
            tonumber(
                ctx.state.overlay_preview_current_ring_index
            ) or 0
        ) + 1
    )

    ui_value(
        "Current Ring Ratio",
        string.format(
            "%.6f",
            tonumber(
                ctx.state.overlay_preview_current_ring_ratio
            ) or 0.0
        )
    )

    ui_value(
        "Projected Ring",
        (
            tonumber(
                ctx.state.overlay_preview_projected_ring_index
            ) or 0
        ) + 1
    )

    ui_value(
        "Projected Ring Ratio",
        string.format(
            "%.6f",
            tonumber(
                ctx.state.overlay_preview_projected_ring_ratio
            ) or 0.0
        )
    )

    ui_value(
        "Crosses Ring Boundary",
        ctx.state.overlay_preview_crosses_ring
    )

    ui_value(
        "Currently Eligible Rings",
        ctx.state.overlay_visible_ring_count
    )

    ui_value(
        "Projected Eligible Rings",
        ctx.state.overlay_projected_visible_ring_count
    )

    ui_value(
        "Next Ring Threshold HP",
        ctx.state.overlay_next_ring_threshold_hp
    )

    changed,
    ctx.state.overlay_next_ring_preview_enabled =
        imgui.checkbox(
            "Enable Next-Ring Preview",
            ctx.state.overlay_next_ring_preview_enabled == true
        )

    ui_value(
        "Resolution-Scaled Reference Radius",
        string.format(
            "%.4f",
            tonumber(
                ctx.state.overlay_geometry_radius
            ) or 0.0
        )
    )

    ui_value("Live Screen Width", ctx.screen.width)
    ui_value("Live Screen Height", ctx.screen.height)
    ui_value("Previous Screen Width", ctx.screen.previous_width)
    ui_value("Previous Screen Height", ctx.screen.previous_height)
    ui_value("Resolution Changed This Frame", ctx.screen.resolution_changed)
    ui_value("Resolution Change Count", ctx.screen.resolution_change_count)
    ui_value("Resolution Source", ctx.screen.last_resolution_source)

    ui_value(
        "Scale X",
        string.format("%.6f", tonumber(ctx.screen.scale_x) or 0.0)
    )

    ui_value(
        "Scale Y",
        string.format("%.6f", tonumber(ctx.screen.scale_y) or 0.0)
    )

    ui_value(
        "Uniform Scale",
        string.format("%.6f", tonumber(ctx.screen.uniform_scale) or 0.0)
    )

    ui_value(
        "Computed Center X",
        string.format("%.4f", tonumber(ctx.screen.computed_center_x) or 0.0)
    )

    ui_value(
        "Computed Center Y",
        string.format("%.4f", tonumber(ctx.screen.computed_center_y) or 0.0)
    )

    ui_value(
        "Computed Thickness",
        string.format("%.4f", tonumber(ctx.screen.computed_thickness) or 0.0)
    )

    ui_value("Resolution Error", ctx.screen.last_resolution_error)

    ui_value(
        "Next-Ring Preview Radius",
        string.format(
            "%.4f",
            tonumber(
                ctx.state.overlay_next_ring_preview_radius
            ) or 0.0
        )
    )

    ui_value(
        "Next-Ring Preview Sweep",
        string.format(
            "%.4f",
            tonumber(
                ctx.state.overlay_next_ring_preview_sweep
            ) or 0.0
        )
    )

    ui_value(
        "Next-Ring Preview Drawn",
        ctx.state.overlay_next_ring_preview_drawn
    )

    imgui.text(
        "All custom layers use the original resolution-scaled reference geometry."
    )

    imgui.tree_pop()
end

local function draw_ring_rgba(style, label, prefix, suffix)
    imgui.text(label)
    local changed
    changed, style[prefix .. "_r"] = imgui.drag_int(label .. " R##" .. suffix, tonumber(style[prefix .. "_r"]) or 0, 1, 0, 255)
    changed, style[prefix .. "_g"] = imgui.drag_int(label .. " G##" .. suffix, tonumber(style[prefix .. "_g"]) or 0, 1, 0, 255)
    changed, style[prefix .. "_b"] = imgui.drag_int(label .. " B##" .. suffix, tonumber(style[prefix .. "_b"]) or 0, 1, 0, 255)
    changed, style[prefix .. "_a"] = imgui.drag_int(label .. " A##" .. suffix, tonumber(style[prefix .. "_a"]) or 255, 1, 0, 255)
end

local function draw_per_ring_color_controls(ctx)
    if not imgui.tree_node("Per-Ring Colors — Safe Test") then return end

    imgui.text("Colors only; geometry and draw count are unchanged.")

    for index, style in ipairs(ctx.ring_styles or {}) do
        local title = string.format(
            "%s — %d to %d HP",
            tostring(style.name or ("Ring " .. index)),
            tonumber(style.start_hp) or 0,
            tonumber(style.end_hp) or 0
        )

        if imgui.tree_node(title) then
            local changed
            changed, style.enabled = imgui.checkbox("Enable Style##ring" .. index, style.enabled ~= false)
            draw_ring_rgba(style, "Foreground", "fg", "r" .. index .. "fg")
            draw_ring_rgba(style, "Background", "bg", "r" .. index .. "bg")
            draw_ring_rgba(style, "Damage", "damage", "r" .. index .. "damage")
            draw_ring_rgba(style, "Heal", "heal", "r" .. index .. "heal")
            draw_ring_rgba(style, "Max Preview", "preview", "r" .. index .. "preview")
            draw_ring_rgba(style, "End Cap", "cap", "r" .. index .. "cap")
            imgui.tree_pop()
        end
    end

    imgui.tree_pop()
end

local function draw_overlay_panel(ctx)
    imgui.text("[HUD]")
    imgui.separator()

    if imgui.tree_node("HUD Overlay") then
        local changed

        changed,
        ctx.state.overlay_follow_native_hp_visibility =
            imgui.checkbox(
                "Only Draw With Native HP Bar",
                ctx.state.overlay_follow_native_hp_visibility == true
            )

        ui_value("Native HP Visibility Known", ctx.state.native_hp_bar_visibility_known)
        ui_value("Native HP Bar Visible", ctx.state.native_hp_bar_visible)
        ui_value("Native Visibility Source", ctx.state.native_hp_bar_visibility_source)
        ui_value("Native Visibility Checks", ctx.state.native_hp_bar_visibility_checks)

        changed,
        ctx.state.native_hp_hidden_step =
            imgui.drag_int(
                "Confirmed Hidden Step",
                tonumber(ctx.state.native_hp_hidden_step) or 4,
                1,
                -1,
                16
            )

        ui_value(
            "Last Classified Step",
            ctx.state.native_hp_last_classified_step
        )

        ui_value(
            "Visibility Change Count",
            ctx.state.native_hp_visibility_change_count
        )

        ui_value("Native Visibility Error", ctx.state.native_hp_bar_visibility_error)
        ui_value("Visibility Gate Safe Mode", ctx.state.native_hp_visibility_gate_safe_mode)
        ui_value("Visibility Gate Reason", ctx.state.native_hp_visibility_gate_reason)

        imgui.separator()
        changed, ctx.state.overlay_enabled =
            imgui.checkbox("Enable Overlay", ctx.state.overlay_enabled)

        changed, ctx.state.overlay_x =
            imgui.drag_float("Overlay X", ctx.state.overlay_x, 0.1, 0, 4000)

        changed, ctx.state.overlay_y =
            imgui.drag_float("Overlay Y", ctx.state.overlay_y, 0.1, 0, 4000)

        changed, ctx.state.overlay_rotation =
            imgui.drag_float("Overlay Rotation", ctx.state.overlay_rotation, 0.1, -360, 360)

        ctx.state.overlay_rotation =
            ctx.clamp(ctx.state.overlay_rotation, -360, 360)

        changed, ctx.state.overlay_radius =
            imgui.drag_float("Overlay Radius", ctx.state.overlay_radius, 0.1, 20, 400)

        changed, ctx.state.overlay_thickness =
            imgui.drag_int("Overlay Thickness", ctx.state.overlay_thickness, 1, 1, 32)

        ctx.state.overlay_thickness =
            ctx.clamp(ctx.state.overlay_thickness, 1, 32)

        changed, ctx.state.overlay_segments =
            imgui.drag_int("Overlay Segments", ctx.state.overlay_segments, 1, 4, 128)

        ctx.state.overlay_segments =
            ctx.clamp(ctx.state.overlay_segments, 4, 128)

        imgui.separator()
        draw_safe_ring_diagnostics(ctx)

        imgui.separator()
        draw_per_ring_color_controls(ctx)

        imgui.separator()
        imgui.text("Legacy / Fallback Ring Color")

        changed, ctx.ui.overlay_fg_r =
            imgui.drag_int("Ring R", ctx.ui.overlay_fg_r, 1, 0, 255)

        changed, ctx.ui.overlay_fg_g =
            imgui.drag_int("Ring G", ctx.ui.overlay_fg_g, 1, 0, 255)

        changed, ctx.ui.overlay_fg_b =
            imgui.drag_int("Ring B", ctx.ui.overlay_fg_b, 1, 0, 255)

        changed, ctx.ui.overlay_fg_a =
            imgui.drag_int("Ring A", ctx.ui.overlay_fg_a, 1, 0, 255)

        imgui.separator()
        imgui.text("Background Color")

        changed, ctx.ui.overlay_bg_r =
            imgui.drag_int("Back R", ctx.ui.overlay_bg_r, 1, 0, 255)

        changed, ctx.ui.overlay_bg_g =
            imgui.drag_int("Back G", ctx.ui.overlay_bg_g, 1, 0, 255)

        changed, ctx.ui.overlay_bg_b =
            imgui.drag_int("Back B", ctx.ui.overlay_bg_b, 1, 0, 255)

        changed, ctx.ui.overlay_bg_a =
            imgui.drag_int("Back A", ctx.ui.overlay_bg_a or 100,
            1,
            0,
            255
            )

        changed, ctx.state.overlay_bg_auto_alpha =
            imgui.checkbox(
                "Hide Ring 1 Background Within Vanilla HP",
                ctx.state.overlay_bg_auto_alpha == true
            )

        changed, ctx.state.overlay_bg_alpha_threshold_hp =
            imgui.drag_float(
                "Vanilla HP Background Threshold",
                tonumber(
                    ctx.state.overlay_bg_alpha_threshold_hp
                ) or 2500.0,
                10.0,
                0.0,
                20000.0
            )

        ui_value(
            "Configured Background Alpha",
            ctx.ui.overlay_bg_a
        )

        ui_value(
            "Effective Background Alpha",
            ctx.state.overlay_bg_effective_alpha
        )

        ui_value(
            "Background Forced Hidden",
            ctx.state.overlay_bg_forced_hidden
        )

        ui_value(
            "Current Max HP Used for Unlock",
            ctx.state.overlay_bg_unlock_max_hp
        )

        if imgui.button("Reset Colors") then
            ctx.ui.overlay_fg_r = 149
            ctx.ui.overlay_fg_g = 182
            ctx.ui.overlay_fg_b = 255
            ctx.ui.overlay_fg_a = 255

            ctx.ui.overlay_bg_r = 0
            ctx.ui.overlay_bg_g = 0
            ctx.ui.overlay_bg_b = 0
            ctx.ui.overlay_bg_a = 100
        end

        local packed_fg = ctx.rgba_to_u32(
            ctx.ui.overlay_fg_r,
            ctx.ui.overlay_fg_g,
            ctx.ui.overlay_fg_b,
            ctx.ui.overlay_fg_a
        )

        local packed_bg = ctx.rgba_to_u32(
            ctx.ui.overlay_bg_r,
            ctx.ui.overlay_bg_g,
            ctx.ui.overlay_bg_b,
            ctx.ui.overlay_bg_a
        )

        changed, ctx.state.overlay_fade_in_speed =
            imgui.drag_float(
                "Fade In Speed",
                ctx.state.overlay_fade_in_speed,
                0.1,
                0.1,
                20.0
            )

        changed, ctx.state.overlay_fade_out_speed =
            imgui.drag_float(
                "Fade Out Speed",
                ctx.state.overlay_fade_out_speed,
                0.1,
                0.1,
                20.0
            )

        changed, ctx.state.overlay_hold_time =
            imgui.drag_float(
                "Visible Hold Time",
                ctx.state.overlay_hold_time,
                0.1,
                0.0,
                10.0
            )
        
        imgui.separator()

        if imgui.tree_node("End Cap") then
            changed, ctx.state.overlay_cap_enabled =
                imgui.checkbox(
                    "Enable Cap",
                    ctx.state.overlay_cap_enabled
                )

            imgui.separator()
            imgui.text("Cap Color")

            changed, ctx.ui.overlay_cap_r =
                imgui.drag_int(
                    "Cap R",
                    ctx.ui.overlay_cap_r or 149,
                    1,
                    0,
                    255
                )

            changed, ctx.ui.overlay_cap_g =
                imgui.drag_int(
                    "Cap G",
                    ctx.ui.overlay_cap_g or 182,
                    1,
                    0,
                    255
                )

            changed, ctx.ui.overlay_cap_b =
                imgui.drag_int(
                    "Cap B",
                    ctx.ui.overlay_cap_b or 255,
                    1,
                    0,
                    255
                )

            changed, ctx.ui.overlay_cap_a =
                imgui.drag_int(
                    "Cap A",
                    ctx.ui.overlay_cap_a or 255,
                    1,
                    0,
                    255
                )

            if imgui.button("Reset Cap Color") then
                ctx.ui.overlay_cap_r = 149
                ctx.ui.overlay_cap_g = 182
                ctx.ui.overlay_cap_b = 255
                ctx.ui.overlay_cap_a = 255
            end

            local packed_cap = ctx.rgba_to_u32(
                ctx.ui.overlay_cap_r,
                ctx.ui.overlay_cap_g,
                ctx.ui.overlay_cap_b,
                ctx.ui.overlay_cap_a
            )

            ui_value(
                "Cap Packed",
                string.format("0x%08X", packed_cap or 0)
            )

            changed, ctx.state.overlay_cap_length =
                imgui.drag_float(
                    "Cap Length",
                    ctx.state.overlay_cap_length,
                    0.01,
                    0.05,
                    3.0
                )

            changed, ctx.state.overlay_cap_width =
                imgui.drag_float(
                    "Cap Width",
                    ctx.state.overlay_cap_width,
                    0.01,
                    0.25,
                    3.0
                )

            imgui.tree_pop()
        end

        imgui.separator()

        if imgui.tree_node("Damage Trail") then
            changed, ctx.state.overlay_damage_duration =
                imgui.drag_float(
                    "Vanilla Sweep Duration",
                    tonumber(ctx.state.overlay_damage_duration) or 1.98,
                    0.01,
                    0.05,
                    5.0
                )

            ui_value(
                "Measured Vanilla Reference",
                string.format(
                    "%.3f sec",
                    tonumber(
                        ctx.state.overlay_damage_vanilla_duration
                    ) or 1.98
                )
            )

            if imgui.button("Reset Duration to Vanilla") then
                ctx.state.overlay_damage_duration =
                    tonumber(
                        ctx.state.overlay_damage_vanilla_duration
                    ) or 1.98
            end

            imgui.separator()
            imgui.text("Transition State")

            ui_value(
                "Damage Active",
                ctx.state.overlay_damage_active
            )

            ui_value(
                "Live Ratio",
                string.format(
                    "%.6f",
                    tonumber(ctx.state.overlay_damage_live_ratio) or 0.0
                )
            )

            ui_value(
                "Start Ratio",
                string.format(
                    "%.6f",
                    tonumber(ctx.state.overlay_damage_start_ratio) or 0.0
                )
            )

            ui_value(
                "Target Ratio",
                string.format(
                    "%.6f",
                    tonumber(ctx.state.overlay_damage_target_ratio) or 0.0
                )
            )

            ui_value(
                "Current Damage Ratio",
                string.format(
                    "%.6f",
                    tonumber(ctx.state.overlay_damage_ratio) or 0.0
                )
            )

            ui_value(
                "Initial Gap",
                string.format(
                    "%.6f",
                    tonumber(ctx.state.overlay_damage_initial_gap) or 0.0
                )
            )

            ui_value(
                "Current Gap",
                string.format(
                    "%.6f",
                    tonumber(ctx.state.overlay_damage_current_gap) or 0.0
                )
            )

            ui_value(
                "Initial Gap HP",
                string.format(
                    "%.1f",
                    tonumber(ctx.state.overlay_damage_initial_gap_hp) or 0.0
                )
            )

            ui_value(
                "Current Gap HP",
                string.format(
                    "%.1f",
                    tonumber(ctx.state.overlay_damage_current_gap_hp) or 0.0
                )
            )

            ui_value(
                "Derived Ratio Speed",
                string.format(
                    "%.6f / sec",
                    tonumber(ctx.state.overlay_damage_derived_speed) or 0.0
                )
            )

            ui_value(
                "Captured Transition Speed",
                string.format(
                    "%.6f / sec",
                    tonumber(
                        ctx.state.overlay_damage_transition_speed
                    ) or 0.0
                )
            )

            ui_value(
                "Measured Ratio Velocity",
                string.format(
                    "%.6f / sec",
                    tonumber(ctx.state.overlay_damage_measured_velocity) or 0.0
                )
            )

            ui_value(
                "Elapsed",
                string.format(
                    "%.3f sec",
                    tonumber(ctx.state.overlay_damage_elapsed) or 0.0
                )
            )

            ui_value(
                "Progress",
                string.format(
                    "%.1f%%",
                    (tonumber(ctx.state.overlay_damage_progress) or 0.0) *
                    100.0
                )
            )

            imgui.separator()
            imgui.text("Native Vanilla Damage Probe")

            ui_value(
                "Probe Installed",
                ctx.native_damage.installed
            )

            ui_value(
                "Probe Calls",
                ctx.native_damage.calls
            )

            ui_value(
                "Condition GUI Type",
                ctx.native_damage.object_type
            )

            ui_value(
                "Condition GUI Ptr",
                ctx.native_damage.object_ptr
            )

            ui_value(
                "Native Elapsed Sec",
                string.format(
                    "%.6f",
                    tonumber(ctx.native_damage.elapsed_sec) or 0.0
                )
            )

            ui_value(
                "Native Curr Frame",
                string.format(
                    "%.6f",
                    tonumber(ctx.native_damage.curr_frame) or 0.0
                )
            )

            ui_value(
                "Native Memory Frame",
                string.format(
                    "%.6f",
                    tonumber(ctx.native_damage.curr_memory_frame) or 0.0
                )
            )

            ui_value(
                "Native Virtual Memory Frame",
                string.format(
                    "%.6f",
                    tonumber(ctx.native_damage.curr_virtual_memory_frame) or 0.0
                )
            )

            ui_value(
                "Native Gradation Frame",
                string.format(
                    "%.6f",
                    tonumber(ctx.native_damage.curr_gradation_frame) or 0.0
                )
            )

            ui_value(
                "Native Max Frame",
                string.format(
                    "%.6f",
                    tonumber(ctx.native_damage.curr_max_frame) or 0.0
                )
            )

            ui_value(
                "Native Frame Diff",
                string.format(
                    "%.6f",
                    tonumber(ctx.native_damage.curr_frame_diff) or 0.0
                )
            )

            ui_value(
                "Native Memory Max Frame",
                string.format(
                    "%.6f",
                    tonumber(ctx.native_damage.curr_memory_max_frame) or 0.0
                )
            )

            ui_value(
                "Native Memory Max Diff",
                string.format(
                    "%.6f",
                    tonumber(ctx.native_damage.curr_memory_max_frame_diff) or 0.0
                )
            )

            ui_value(
                "Native Gradation Diff",
                string.format(
                    "%.6f",
                    tonumber(ctx.native_damage.curr_gradation_gauge_frame_diff) or 0.0
                )
            )

            imgui.separator()
            imgui.text("Native Read Diagnostics")

            ui_value(
                "Successful Reads",
                ctx.native_damage.read_success_count or 0
            )

            ui_value(
                "Failed Reads",
                ctx.native_damage.read_failure_count or 0
            )

            ui_value(
                "Last Read Name",
                ctx.native_damage.last_read_name or "none"
            )

            ui_value(
                "Last Read Source",
                ctx.native_damage.last_read_source or "none"
            )

            ui_value(
                "Curr Frame Read OK",
                ctx.native_damage.curr_frame_read_ok or false
            )

            ui_value(
                "Curr Frame Source",
                ctx.native_damage.curr_frame_source or "not read"
            )

            ui_value(
                "Memory Frame Read OK",
                ctx.native_damage.curr_memory_frame_read_ok or false
            )

            ui_value(
                "Memory Frame Source",
                ctx.native_damage.curr_memory_frame_source or "not read"
            )

            ui_value(
                "Virtual Memory Read OK",
                ctx.native_damage.curr_virtual_memory_frame_read_ok or false
            )

            ui_value(
                "Virtual Memory Source",
                ctx.native_damage.curr_virtual_memory_frame_source or "not read"
            )

            ui_value(
                "Gradation Frame Read OK",
                ctx.native_damage.curr_gradation_frame_read_ok or false
            )

            ui_value(
                "Gradation Frame Source",
                ctx.native_damage.curr_gradation_frame_source or "not read"
            )

            ui_value(
                "Max Frame Read OK",
                ctx.native_damage.curr_max_frame_read_ok or false
            )

            ui_value(
                "Max Frame Source",
                ctx.native_damage.curr_max_frame_source or "not read"
            )

            ui_value(
                "Frame Diff Read OK",
                ctx.native_damage.curr_frame_diff_read_ok or false
            )

            ui_value(
                "Frame Diff Source",
                ctx.native_damage.curr_frame_diff_source or "not read"
            )

            imgui.separator()
            imgui.text("Native Ratios")

            ui_value(
                "Native Live Ratio",
                string.format(
                    "%.6f",
                    tonumber(ctx.native_damage.live_ratio) or 0.0
                )
            )

            ui_value(
                "Native Memory Ratio",
                string.format(
                    "%.6f",
                    tonumber(ctx.native_damage.memory_ratio) or 0.0
                )
            )

            ui_value(
                "Native Virtual Ratio",
                string.format(
                    "%.6f",
                    tonumber(ctx.native_damage.virtual_memory_ratio) or 0.0
                )
            )

            ui_value(
                "Native Gradation Ratio",
                string.format(
                    "%.6f",
                    tonumber(ctx.native_damage.gradation_ratio) or 0.0
                )
            )

            ui_value(
                "Native Damage Ratio",
                string.format(
                    "%.6f",
                    tonumber(ctx.native_damage.damage_ratio) or 0.0
                )
            )

            ui_value(
                "Native Damage Gap",
                string.format(
                    "%.6f",
                    tonumber(ctx.native_damage.damage_gap) or 0.0
                )
            )

            ui_value(
                "Native Damage Gap HP",
                string.format(
                    "%.1f",
                    tonumber(ctx.native_damage.damage_gap_hp) or 0.0
                )
            )

            ui_value(
                "Native Decay Active",
                ctx.native_damage.active
            )

            ui_value(
                "Native Transition Elapsed",
                string.format(
                    "%.3f sec",
                    tonumber(ctx.native_damage.transition_elapsed) or 0.0
                )
            )

            ui_value(
                "Native Start Gap",
                string.format(
                    "%.6f",
                    tonumber(ctx.native_damage.transition_start_gap) or 0.0
                )
            )

            ui_value(
                "Native Start Damage Ratio",
                string.format(
                    "%.6f",
                    tonumber(
                        ctx.native_damage.transition_start_damage_ratio
                    ) or 0.0
                )
            )

            ui_value(
                "Native Instant Velocity",
                string.format(
                    "%.6f / sec",
                    tonumber(ctx.native_damage.measured_velocity) or 0.0
                )
            )

            ui_value(
                "Native Current Gap",
                string.format(
                    "%.6f",
                    tonumber(
                        ctx.native_damage.transition_current_gap
                    ) or 0.0
                )
            )

            ui_value(
                "Native Progress",
                string.format(
                    "%.1f%%",
                    (
                        tonumber(
                            ctx.native_damage.transition_progress
                        ) or 0.0
                    ) * 100.0
                )
            )

            ui_value(
                "Native Average Velocity",
                string.format(
                    "%.6f / sec",
                    tonumber(
                        ctx.native_damage.transition_average_velocity
                    ) or 0.0
                )
            )

            ui_value(
                "Native Inferred Duration",
                string.format(
                    "%.3f sec",
                    tonumber(
                        ctx.native_damage.transition_inferred_duration
                    ) or 0.0
                )
            )

            ui_value(
                "Native Remaining Time",
                string.format(
                    "%.3f sec",
                    tonumber(
                        ctx.native_damage.transition_remaining_time
                    ) or 0.0
                )
            )

            ui_value(
                "Last Completed Duration",
                string.format(
                    "%.3f sec",
                    tonumber(
                        ctx.native_damage.transition_last_duration
                    ) or 0.0
                )
            )

            ui_value(
                "Last Completed Start Gap",
                string.format(
                    "%.6f",
                    tonumber(
                        ctx.native_damage.transition_last_start_gap
                    ) or 0.0
                )
            )

            ui_value(
                "Last Average Velocity",
                string.format(
                    "%.6f / sec",
                    tonumber(
                        ctx.native_damage.transition_last_average_velocity
                    ) or 0.0
                )
            )

            ui_value(
                "Passive Samples",
                ctx.native_damage.transition_sample_count
            )

            ui_value(
                "Ratio Changes Seen",
                ctx.native_damage.transition_ratio_change_count
            )

            ui_value(
                "Last Ratio Change",
                string.format(
                    "%.8f",
                    tonumber(
                        ctx.native_damage.transition_last_ratio_change
                    ) or 0.0
                )
            )

            imgui.separator()
            imgui.text("VitalGaugeGui Damage State")

            ui_value(
                "Gauge Object Type",
                ctx.native_damage.gauge_object_type or "unknown"
            )

            ui_value(
                "Gauge Object Ptr",
                ctx.native_damage.gauge_object_ptr or "nil"
            )

            ui_value(
                "Gauge Max Frame",
                string.format(
                    "%.6f",
                    tonumber(
                        ctx.native_damage.gauge_curr_max_frame
                    ) or 0.0
                )
            )

            ui_value(
                "Gauge Current Rate",
                string.format(
                    "%.6f",
                    tonumber(
                        ctx.native_damage.gauge_curr_rate
                    ) or 0.0
                )
            )

            ui_value(
                "Gauge Target Rate",
                string.format(
                    "%.6f",
                    tonumber(
                        ctx.native_damage.gauge_curr_target_rate
                    ) or 0.0
                )
            )

            ui_value(
                "Gauge Rate Difference",
                string.format(
                    "%.6f",
                    tonumber(
                        ctx.native_damage.gauge_curr_rate_diff
                    ) or 0.0
                )
            )

            ui_value(
                "Gauge Is End",
                ctx.native_damage.gauge_is_end
            )

            ui_value(
                "Gauge Damage Ratio",
                string.format(
                    "%.6f",
                    tonumber(
                        ctx.native_damage.gauge_damage_ratio
                    ) or 0.0
                )
            )

            ui_value(
                "Gauge Live Ratio",
                string.format(
                    "%.6f",
                    tonumber(
                        ctx.native_damage.gauge_live_ratio
                    ) or 0.0
                )
            )

            ui_value(
                "Gauge Damage Gap",
                string.format(
                    "%.6f",
                    tonumber(
                        ctx.native_damage.gauge_damage_gap
                    ) or 0.0
                )
            )

            ui_value(
                "Gauge Damage Gap HP",
                string.format(
                    "%.1f",
                    tonumber(
                        ctx.native_damage.gauge_damage_gap_hp
                    ) or 0.0
                )
            )

            ui_value(
                "Gauge Transition Active",
                ctx.native_damage.gauge_transition_active
            )

            ui_value(
                "Gauge Transition Elapsed",
                string.format(
                    "%.3f sec",
                    tonumber(
                        ctx.native_damage.gauge_transition_elapsed
                    ) or 0.0
                )
            )

            ui_value(
                "Gauge Start Gap",
                string.format(
                    "%.6f",
                    tonumber(
                        ctx.native_damage.gauge_transition_start_gap
                    ) or 0.0
                )
            )

            ui_value(
                "Gauge Start Rate",
                string.format(
                    "%.6f",
                    tonumber(
                        ctx.native_damage.gauge_transition_start_rate
                    ) or 0.0
                )
            )

            ui_value(
                "Gauge Target Rate Snapshot",
                string.format(
                    "%.6f",
                    tonumber(
                        ctx.native_damage.gauge_transition_target_rate
                    ) or 0.0
                )
            )

            ui_value(
                "Gauge Measured Velocity",
                string.format(
                    "%.6f / sec",
                    tonumber(
                        ctx.native_damage.gauge_measured_velocity
                    ) or 0.0
                )
            )

            imgui.separator()
            imgui.text("Direct Update Hook (DISABLED)")

            ui_value(
                "Update Hook Installed",
                ctx.native_damage.gauge_update_hook_installed
            )

            ui_value(
                "update() Calls",
                ctx.native_damage.gauge_update_hook_calls
            )

            ui_value(
                "updateGauge() Calls",
                ctx.native_damage.gauge_update_gauge_hook_calls
            )

            ui_value(
                "Last Hook",
                ctx.native_damage.gauge_last_hook
            )

            ui_value(
                "Last Phase",
                ctx.native_damage.gauge_last_phase
            )

            ui_value(
                "Last Input",
                string.format(
                    "%.6f",
                    tonumber(
                        ctx.native_damage.gauge_last_input
                    ) or 0.0
                )
            )

            ui_value(
                "Pre Rate",
                string.format(
                    "%.6f",
                    tonumber(
                        ctx.native_damage.gauge_pre_rate
                    ) or 0.0
                )
            )

            ui_value(
                "Post Rate",
                string.format(
                    "%.6f",
                    tonumber(
                        ctx.native_damage.gauge_post_rate
                    ) or 0.0
                )
            )

            ui_value(
                "Pre Target",
                string.format(
                    "%.6f",
                    tonumber(
                        ctx.native_damage.gauge_pre_target_rate
                    ) or 0.0
                )
            )

            ui_value(
                "Post Target",
                string.format(
                    "%.6f",
                    tonumber(
                        ctx.native_damage.gauge_post_target_rate
                    ) or 0.0
                )
            )

            ui_value(
                "Pre Diff",
                string.format(
                    "%.6f",
                    tonumber(
                        ctx.native_damage.gauge_pre_rate_diff
                    ) or 0.0
                )
            )

            ui_value(
                "Post Diff",
                string.format(
                    "%.6f",
                    tonumber(
                        ctx.native_damage.gauge_post_rate_diff
                    ) or 0.0
                )
            )

            ui_value(
                "Pre Is End",
                ctx.native_damage.gauge_pre_is_end
            )

            ui_value(
                "Post Is End",
                ctx.native_damage.gauge_post_is_end
            )

            ui_value(
                "Tick Rate Delta",
                string.format(
                    "%.6f",
                    tonumber(
                        ctx.native_damage.gauge_tick_delta_rate
                    ) or 0.0
                )
            )

            ui_value(
                "Tick Velocity",
                string.format(
                    "%.6f / sec",
                    tonumber(
                        ctx.native_damage.gauge_tick_velocity
                    ) or 0.0
                )
            )

            ui_value(
                "Gauge Transition Duration",
                string.format(
                    "%.3f sec",
                    tonumber(
                        ctx.native_damage.gauge_transition_duration
                    ) or 0.0
                )
            )

            ui_value(
                "Gauge End Rate",
                string.format(
                    "%.6f",
                    tonumber(
                        ctx.native_damage.gauge_transition_end_rate
                    ) or 0.0
                )
            )

            ui_value(
                "Gauge Last Nonzero Diff",
                string.format(
                    "%.6f",
                    tonumber(
                        ctx.native_damage.gauge_last_nonzero_diff
                    ) or 0.0
                )
            )

            ui_value(
                "Gauge Peak Velocity",
                string.format(
                    "%.6f / sec",
                    tonumber(
                        ctx.native_damage.gauge_peak_velocity
                    ) or 0.0
                )
            )

            ui_value(
                "Gauge Minimum Rate",
                string.format(
                    "%.6f",
                    tonumber(
                        ctx.native_damage.gauge_min_rate
                    ) or 0.0
                )
            )

            ui_value(
                "Gauge Maximum Rate",
                string.format(
                    "%.6f",
                    tonumber(
                        ctx.native_damage.gauge_max_rate
                    ) or 0.0
                )
            )

            if imgui.tree_node("Gauge Sample History") then
                local history =
                    ctx.native_damage.gauge_history or {}

                for index, sample in ipairs(history) do
                    imgui.text(
                        string.format(
                            "%02d  %s/%s  in=%.4f  t=%.3f  rate=%.4f  target=%.4f  diff=%.4f  vel=%.4f  end=%s",
                            index,
                            tostring(sample.hook or "poll"),
                            tostring(sample.phase or "after"),
                            tonumber(sample.input) or 0.0,
                            tonumber(sample.elapsed) or 0.0,
                            tonumber(sample.rate) or 0.0,
                            tonumber(sample.target) or 0.0,
                            tonumber(sample.diff) or 0.0,
                            tonumber(sample.velocity) or 0.0,
                            tostring(sample.is_end == true)
                        )
                    )
                end

                imgui.tree_pop()
            end

            imgui.separator()
            imgui.text("VitalDamageFlareGui State (DISABLED)")

            ui_value(
                "Flare Hook Installed",
                ctx.native_damage.flare_hook_installed
            )

            ui_value(
                "setMaxFrame Calls",
                ctx.native_damage.flare_set_max_frame_calls
            )

            ui_value(
                "setState Calls",
                ctx.native_damage.flare_set_state_calls
            )

            ui_value(
                "Flare Object Type",
                ctx.native_damage.flare_object_type or "unknown"
            )

            ui_value(
                "Flare Object Ptr",
                ctx.native_damage.flare_object_ptr or "nil"
            )

            ui_value(
                "Flare Last Hook",
                ctx.native_damage.flare_last_hook or "none"
            )

            ui_value(
                "Flare Last Phase",
                ctx.native_damage.flare_last_phase or "none"
            )

            ui_value(
                "Flare Current State",
                string.format(
                    "%s (%d)",
                    tostring(
                        ctx.native_damage.flare_curr_state_name or "UNKNOWN"
                    ),
                    tonumber(
                        ctx.native_damage.flare_curr_state
                    ) or -1
                )
            )

            ui_value(
                "Flare Pre State",
                tostring(
                    ctx.native_damage.flare_pre_state_name or "UNKNOWN"
                )
            )

            ui_value(
                "Flare Post State",
                tostring(
                    ctx.native_damage.flare_post_state_name or "UNKNOWN"
                )
            )

            ui_value(
                "Last setMaxFrame Input",
                string.format(
                    "%.6f",
                    tonumber(
                        ctx.native_damage.flare_last_max_frame_input
                    ) or 0.0
                )
            )

            ui_value(
                "Flare Damage Active",
                ctx.native_damage.flare_damage_active
            )

            ui_value(
                "Flare Damage Elapsed",
                string.format(
                    "%.3f sec",
                    tonumber(
                        ctx.native_damage.flare_damage_elapsed
                    ) or 0.0
                )
            )

            ui_value(
                "Last Flare Duration",
                string.format(
                    "%.3f sec",
                    tonumber(
                        ctx.native_damage.flare_last_damage_duration
                    ) or 0.0
                )
            )

            if imgui.tree_node("Flare Sample History") then
                local history =
                    ctx.native_damage.flare_history or {}

                for index, sample in ipairs(history) do
                    imgui.text(
                        string.format(
                            "%02d  %s/%s  in=%.4f  state=%s(%d)  active=%s  t=%.3f",
                            index,
                            tostring(sample.hook or "unknown"),
                            tostring(sample.phase or "unknown"),
                            tonumber(sample.input) or 0.0,
                            tostring(sample.state_name or "UNKNOWN"),
                            tonumber(sample.state) or -1,
                            tostring(sample.active == true),
                            tonumber(sample.elapsed) or 0.0
                        )
                    )
                end

                imgui.tree_pop()
            end

            imgui.separator()
            imgui.text("VitalGaugeGui Read Sources")

            ui_value(
                "Gauge Max Frame Source",
                ctx.native_damage.gauge_curr_max_frame_source or "not read"
            )

            ui_value(
                "Gauge Current Rate Source",
                ctx.native_damage.gauge_curr_rate_source or "not read"
            )

            ui_value(
                "Gauge Target Rate Source",
                ctx.native_damage.gauge_curr_target_rate_source or "not read"
            )

            ui_value(
                "Gauge Rate Diff Source",
                ctx.native_damage.gauge_curr_rate_diff_source or "not read"
            )

            ui_value(
                "Gauge Is End Source",
                ctx.native_damage.gauge_is_end_source or "not read"
            )

            ui_value(
                "Native Probe Error",
                ctx.native_damage.last_error
            )

            imgui.separator()
            imgui.text("Damage Color")

            changed, ctx.state.overlay_damage_r =
                imgui.drag_int(
                    "Damage R",
                    ctx.state.overlay_damage_r or 229,
                    1,
                    0,
                    255
                )

            changed, ctx.state.overlay_damage_g =
                imgui.drag_int(
                    "Damage G",
                    ctx.state.overlay_damage_g or 39,
                    1,
                    0,
                    255
                )

            changed, ctx.state.overlay_damage_b =
                imgui.drag_int(
                    "Damage B",
                    ctx.state.overlay_damage_b or 39,
                    1,
                    0,
                    255
                )

            changed, ctx.state.overlay_damage_a =
                imgui.drag_int(
                    "Damage A",
                    ctx.state.overlay_damage_a or 255,
                    1,
                    0,
                    255
                )

            if imgui.button("Reset Damage Color") then
                ctx.state.overlay_damage_r = 229
                ctx.state.overlay_damage_g = 39
                ctx.state.overlay_damage_b = 39
                ctx.state.overlay_damage_a = 255
            end

            local packed_damage =
                ctx.rgba_to_u32(
                    ctx.state.overlay_damage_r,
                    ctx.state.overlay_damage_g,
                    ctx.state.overlay_damage_b,
                    ctx.state.overlay_damage_a
                )

            ui_value(
                "Damage Color Packed",
                string.format(
                    "0x%08X",
                    packed_damage or 0
                )
            )

            imgui.tree_pop()
        end

        if imgui.tree_node("Healing Trail") then
            changed, ctx.state.overlay_heal_duration =
                imgui.drag_float(
                    "Vanilla Heal Duration",
                    tonumber(ctx.state.overlay_heal_duration) or 1.98,
                    0.01,
                    0.05,
                    5.0
                )

            ui_value(
                "Measured Vanilla Reference",
                string.format(
                    "%.3f sec",
                    tonumber(
                        ctx.state.overlay_heal_vanilla_duration
                    ) or 1.98
                )
            )

            if imgui.button("Reset Heal Duration to Vanilla") then
                ctx.state.overlay_heal_duration =
                    tonumber(
                        ctx.state.overlay_heal_vanilla_duration
                    ) or 1.98
            end

            imgui.separator()

            ui_value(
                "Heal Active",
                ctx.state.overlay_heal_active
            )

            ui_value(
                "Last Recovery Value",
                ctx.state.heal_event_value
            )

            ui_value(
                "Recovery Event Serial",
                ctx.state.heal_event_serial
            )

            ui_value(
                "Consumed Recovery Serial",
                ctx.state.heal_event_consumed_serial
            )

            ui_value(
                "Current HP / Max HP",
                tostring(ctx.state.current_hp) ..
                " / " ..
                tostring(ctx.state.max_hp)
            )

            local debug_current_hp =
                tonumber(ctx.state.current_hp) or 0

            local debug_max_hp =
                tonumber(ctx.state.max_hp) or 0

            local debug_capped_hp =
                debug_max_hp > 0
                and math.min(debug_current_hp, debug_max_hp)
                or debug_current_hp

            ui_value(
                "Capped Visual HP",
                string.format(
                    "%.0f",
                    debug_capped_hp
                )
            )

            ui_value(
                "Over-Cap HP",
                string.format(
                    "%.0f",
                    math.max(
                        0,
                        debug_current_hp - debug_max_hp
                    )
                )
            )

            ui_value(
                "Heal Ring Index",
                ctx.state.overflow_active_ring_index
            )

            ui_value(
                "Capped Live Ratio",
                string.format(
                    "%.6f",
                    tonumber(ctx.state.overflow_ratio) or 0.0
                )
            )

            ui_value(
                "Target Is Full",
                (
                    tonumber(
                        ctx.state.overlay_heal_target_ratio
                    ) or 0.0
                ) >= 0.9999
            )

            ui_value(
                "Pre-Heal Ratio Was Full",
                (
                    tonumber(
                        ctx.state.heal_event_start_ratio
                    ) or 0.0
                ) >= 0.9999
            )

            ui_value(
                "Start Ratio",
                string.format(
                    "%.6f",
                    tonumber(ctx.state.overlay_heal_start_ratio) or 0.0
                )
            )

            ui_value(
                "Target Ratio",
                string.format(
                    "%.6f",
                    tonumber(ctx.state.overlay_heal_target_ratio) or 0.0
                )
            )

            ui_value(
                "Current Heal Ratio",
                string.format(
                    "%.6f",
                    tonumber(ctx.state.overlay_heal_ratio) or 0.0
                )
            )

            ui_value(
                "Initial Gap",
                string.format(
                    "%.6f",
                    tonumber(ctx.state.overlay_heal_initial_gap) or 0.0
                )
            )

            ui_value(
                "Current Gap",
                string.format(
                    "%.6f",
                    tonumber(ctx.state.overlay_heal_current_gap) or 0.0
                )
            )

            ui_value(
                "Initial Gap HP",
                string.format(
                    "%.1f",
                    tonumber(ctx.state.overlay_heal_initial_gap_hp) or 0.0
                )
            )

            ui_value(
                "Current Gap HP",
                string.format(
                    "%.1f",
                    tonumber(ctx.state.overlay_heal_current_gap_hp) or 0.0
                )
            )

            ui_value(
                "Captured Transition Speed",
                string.format(
                    "%.6f / sec",
                    tonumber(
                        ctx.state.overlay_heal_transition_speed
                    ) or 0.0
                )
            )

            ui_value(
                "Measured Ratio Velocity",
                string.format(
                    "%.6f / sec",
                    tonumber(
                        ctx.state.overlay_heal_measured_velocity
                    ) or 0.0
                )
            )

            ui_value(
                "Elapsed",
                string.format(
                    "%.3f sec",
                    tonumber(ctx.state.overlay_heal_elapsed) or 0.0
                )
            )

            ui_value(
                "Progress",
                string.format(
                    "%.1f%%",
                    (tonumber(ctx.state.overlay_heal_progress) or 0.0) *
                    100.0
                )
            )

            imgui.separator()
            imgui.text("Healing Color")

            changed, ctx.state.overlay_heal_r =
                imgui.drag_int(
                    "Heal R",
                    ctx.state.overlay_heal_r or 80,
                    1,
                    0,
                    255
                )

            changed, ctx.state.overlay_heal_g =
                imgui.drag_int(
                    "Heal G",
                    ctx.state.overlay_heal_g or 220,
                    1,
                    0,
                    255
                )

            changed, ctx.state.overlay_heal_b =
                imgui.drag_int(
                    "Heal B",
                    ctx.state.overlay_heal_b or 110,
                    1,
                    0,
                    255
                )

            changed, ctx.state.overlay_heal_a =
                imgui.drag_int(
                    "Heal A",
                    ctx.state.overlay_heal_a or 255,
                    1,
                    0,
                    255
                )

            if imgui.button("Reset Healing Color") then
                ctx.state.overlay_heal_r = 80
                ctx.state.overlay_heal_g = 220
                ctx.state.overlay_heal_b = 110
                ctx.state.overlay_heal_a = 255
            end

            imgui.tree_pop()
        end

        if imgui.tree_node("Preview Color") then
            changed, ctx.state.overlay_preview_pulse_enabled =
                imgui.checkbox(
                    "Enable Preview Pulse",
                    ctx.state.overlay_preview_pulse_enabled
                )

            changed, ctx.state.overlay_preview_pulse_hold =
                imgui.drag_float(
                    "Preview Full Hold",
                    ctx.state.overlay_preview_pulse_hold,
                    0.01,
                    0.0,
                    2.0
                )

            changed, ctx.state.overlay_preview_pulse_fade =
                imgui.drag_float(
                    "Preview Fade Time",
                    ctx.state.overlay_preview_pulse_fade,
                    0.01,
                    0.05,
                    2.0
                )

            changed, ctx.state.overlay_preview_pulse_full_alpha =
                imgui.drag_float(
                    "Preview Full Alpha",
                    ctx.state.overlay_preview_pulse_full_alpha,
                    0.01,
                    0.0,
                    1.0
                )

            changed, ctx.state.overlay_preview_pulse_low_alpha =
                imgui.drag_float(
                    "Preview Low Alpha",
                    ctx.state.overlay_preview_pulse_low_alpha,
                    0.01,
                    0.0,
                    1.0
                )

            changed, ctx.state.overlay_preview_r =
                imgui.drag_int(
                    "Preview R",
                    ctx.state.overlay_preview_r or 120,
                    1,
                    0,
                    255
                )

            changed, ctx.state.overlay_preview_g =
                imgui.drag_int(
                    "Preview G",
                    ctx.state.overlay_preview_g or 220,
                    1,
                    0,
                    255
                )

            changed, ctx.state.overlay_preview_b =
                imgui.drag_int(
                    "Preview B",
                    ctx.state.overlay_preview_b or 150,
                    1,
                    0,
                    255
                )

            changed, ctx.state.overlay_preview_a =
                imgui.drag_int(
                    "Preview A",
                    ctx.state.overlay_preview_a or 210,
                    1,
                    0,
                    255
                )

            if imgui.button("Reset Preview Color") then
                ctx.state.overlay_preview_r = 120
                ctx.state.overlay_preview_g = 220
                ctx.state.overlay_preview_b = 150
                ctx.state.overlay_preview_a = 210
            end

            local packed_preview =
                ctx.rgba_to_u32(
                    ctx.state.overlay_preview_r,
                    ctx.state.overlay_preview_g,
                    ctx.state.overlay_preview_b,
                    ctx.state.overlay_preview_a
                )

            ui_value(
                "Preview Color Packed",
                string.format(
                    "0x%08X",
                    packed_preview or 0
                )
            )

            imgui.tree_pop()
        end

        ui_value(
            "Ring Packed",
            string.format("0x%08X", packed_fg)
        )

        ui_value(
            "Back Packed",
            string.format("0x%08X", packed_bg)
        )

        ui_value(
            "Damage Active",
            ctx.state.overlay_damage_active
        )

        ui_value(
            "Live Ratio",
            ctx.state.overflow_ratio
        )

        ui_value(
            "Last Ratio",
            ctx.state.overlay_last_ratio
        )

        ui_value(
            "Damage Ratio",
            ctx.state.overlay_damage_ratio
        )

ui_value(
    "Damage Timer",
    ctx.state.overlay_damage_timer
)

        imgui.tree_pop()
    end
end

local function draw_material_float_editor(
    ctx,
    shader_probe,
    title,
    id_prefix,
    count_key,
    values_key,
    read_function,
    apply_all_function,
    restore_function,
    apply_one_function
)
    if not imgui.tree_node(title) then
        return
    end

    if imgui.button("Read Floats##" .. id_prefix) then
        read_function(ctx)
    end

    imgui.same_line()

    if imgui.button("Apply All##" .. id_prefix) then
        apply_all_function(ctx)
    end

    imgui.same_line()

    if imgui.button("Restore##" .. id_prefix) then
        restore_function(ctx)
    end

    local count = tonumber(ctx.shader_probe[count_key]) or 0
    local values = ctx.shader_probe[values_key] or {}

    for index = 0, count - 1 do
        local array_index = index + 1
        local current_value = tonumber(values[array_index]) or 0.0

        changed, values[array_index] = imgui.drag_float(
            title .. " Float" .. tostring(index) .. "##" .. id_prefix,
            current_value,
            0.01,
            -20.0,
            20.0
        )

        imgui.same_line()

        if imgui.button("Apply##" .. id_prefix .. tostring(index)) then
            apply_one_function(ctx, index)
        end
    end

    ctx.shader_probe[values_key] = values
    imgui.tree_pop()
end

local function draw_shader_probe(ctx, gui, shader_probe)
    if shader_probe == nil then
        imgui.text("HUD Shader Probe module was not passed to ui.draw().")
        return
    end

    if not imgui.tree_node("HUD Shader Probe") then
        return
    end

    ui_value("Installed", ctx.shader_probe.installed)
    ui_value("Hook", ctx.shader_probe.last_hook)
    ui_value("Captures", ctx.shader_probe.capture_count)
    ui_value("Behavior Type", ctx.shader_probe.behavior_type)
    ui_value("Behavior Ptr", ctx.shader_probe.behavior_ptr)

    if imgui.button("Refresh Shader Data") then
        shader_probe.refresh(ctx)
    end

    ui_value("GUI Path", ctx.shader_probe.gui_path)
    ui_value("Folder Type", ctx.shader_probe.folder_type)
    ui_value("Folder Ptr", ctx.shader_probe.folder_ptr)
    ui_value("OverlayMat", ctx.shader_probe.overlay_type)
    ui_value("RefrectMat", ctx.shader_probe.reflect_type)

    if imgui.button("Select GUI Folder") then
        shader_probe.select_folder(ctx, gui)
    end

    if imgui.button("Select OverlayMat") then
        shader_probe.select_overlay_material(ctx, gui)
    end

    imgui.same_line()

    if imgui.button("Select RefrectMat") then
        shader_probe.select_reflect_material(ctx, gui)
    end

    imgui.separator()

    if imgui.button("Inspect Overlay Variables") then
        shader_probe.inspect_overlay_material(ctx)
    end

    imgui.same_line()

    if imgui.button("Inspect Refrect Variables") then
        shader_probe.inspect_reflect_material(ctx)
    end

    if imgui.button("List Overlay Methods") then
        shader_probe.inspect_overlay_methods(ctx)
    end

    imgui.same_line()

    if imgui.button("List Refrect Methods") then
        shader_probe.inspect_reflect_methods(ctx)
    end

    local material_lines = ctx.shader_probe.material_lines or {}
    if #material_lines > 0 then
        imgui.separator()
        imgui.text("Material Variables")

        for _, material_line in ipairs(material_lines) do
            imgui.text(material_line)
        end
    end

    local method_lines = ctx.shader_probe.method_lines or {}
    if #method_lines > 0 then
        imgui.separator()
        imgui.text("Material Methods")

        for _, method_line in ipairs(method_lines) do
            imgui.text(method_line)
        end
    end

    imgui.separator()

    draw_material_float_editor(
        ctx,
        shader_probe,
        "Overlay Material Float Editor",
        "OverlayFloat",
        "overlay_param_count",
        "overlay_float_values",
        shader_probe.read_overlay_values,
        shader_probe.apply_all_overlay_floats,
        shader_probe.restore_overlay_floats,
        shader_probe.apply_overlay_float
    )

    draw_material_float_editor(
        ctx,
        shader_probe,
        "Refrect Material Float Editor",
        "RefrectFloat",
        "reflect_param_count",
        "reflect_float_values",
        shader_probe.read_reflect_values,
        shader_probe.apply_all_reflect_floats,
        shader_probe.restore_reflect_floats,
        shader_probe.apply_reflect_float
    )

    imgui.separator()
    ui_value("Last Applied Material", ctx.shader_probe.last_applied_material)
    ui_value("Last Applied Index", ctx.shader_probe.last_applied_index)
    ui_value("Last Applied Value", ctx.shader_probe.last_applied_value)
    ui_value("Probe Error", ctx.shader_probe.last_error)

    imgui.tree_pop()
end


local function draw_vitalmax_panel_snapshot(ctx)
    if not imgui.tree_node("VitalMaxGui Panel Snapshot") then
        return
    end

    local debug = ctx.vitalmax_panel_snapshot or {}
    local before = debug.before or {}
    local after = debug.after or {}
    local delta = debug.delta or {}

    ui_value("Capture Count", debug.capture_count or 0)

    imgui.separator()
    imgui.text("Before Native preview()")
    ui_value("VitalMax Type", before.vitalmax_type or "unknown")
    ui_value("VitalMax Ptr", before.vitalmax_ptr or "nil")
    ui_value("Curr Max Frame", string.format("%.6f", tonumber(before.curr_max_frame) or 0))
    ui_value("Max Panel Type", before.max_panel_type or "unknown")
    ui_value("Max Panel Ptr", before.max_panel_ptr or "nil")
    ui_value("Max Panel Visible", before.max_panel_visible or "unknown")
    ui_value("Max Panel Enabled", before.max_panel_enabled or "unknown")
    ui_value("Max Panel Child Count", before.max_panel_child_count or -1)
    ui_value("Flare Panel Type", before.flare_panel_type or "unknown")
    ui_value("Flare Panel Ptr", before.flare_panel_ptr or "nil")
    ui_value("Flare Panel Visible", before.flare_panel_visible or "unknown")
    ui_value("Flare Panel Enabled", before.flare_panel_enabled or "unknown")
    ui_value("Flare Panel Child Count", before.flare_panel_child_count or -1)

    imgui.separator()
    imgui.text("After Native preview()")
    ui_value("VitalMax Type", after.vitalmax_type or "unknown")
    ui_value("VitalMax Ptr", after.vitalmax_ptr or "nil")
    ui_value("Curr Max Frame", string.format("%.6f", tonumber(after.curr_max_frame) or 0))
    ui_value("Max Panel Type", after.max_panel_type or "unknown")
    ui_value("Max Panel Ptr", after.max_panel_ptr or "nil")
    ui_value("Max Panel Visible", after.max_panel_visible or "unknown")
    ui_value("Max Panel Enabled", after.max_panel_enabled or "unknown")
    ui_value("Max Panel Child Count", after.max_panel_child_count or -1)
    ui_value("Flare Panel Type", after.flare_panel_type or "unknown")
    ui_value("Flare Panel Ptr", after.flare_panel_ptr or "nil")
    ui_value("Flare Panel Visible", after.flare_panel_visible or "unknown")
    ui_value("Flare Panel Enabled", after.flare_panel_enabled or "unknown")
    ui_value("Flare Panel Child Count", after.flare_panel_child_count or -1)

    imgui.separator()
    imgui.text("Delta")
    ui_value("Curr Max Frame Delta", string.format("%.6f", tonumber(delta.curr_max_frame) or 0))
    ui_value("Max Panel Child Delta", delta.max_panel_child_count or 0)
    ui_value("Flare Panel Child Delta", delta.flare_panel_child_count or 0)

    imgui.separator()
    ui_value("Snapshot Error", debug.error or "")
    imgui.text("Read-only: captured from the confirmed preview hook.")
    imgui.tree_pop()
end

local function draw_preview_gui_backing(ctx)
    if not imgui.tree_node(
        "VitalConditionGui Preview Backing Fields"
    ) then
        return
    end

    local debug =
        ctx.preview_gui_backing or {}

    local before =
        debug.before or {}

    local after_override =
        debug.after_override or {}

    local delta =
        debug.delta or {}

    ui_value(
        "Read OK",
        debug.read_ok == true
    )

    ui_value(
        "Read Count",
        debug.read_count or 0
    )

    ui_value(
        "GUI Type",
        debug.gui_type or "unknown"
    )

    ui_value(
        "GUI Ptr",
        debug.gui_ptr or "nil"
    )

    ui_value(
        "Param Type",
        debug.param_type or "unknown"
    )

    ui_value(
        "Param Ptr",
        debug.param_ptr or "nil"
    )

    imgui.separator()
    imgui.text("Before Scoped Override")

    ui_value(
        "GUI Prev Max HP",
        before.gui_prev_max_hp or 0
    )

    ui_value(
        "GUI Curr Max HP",
        before.gui_curr_max_hp or 0
    )

    ui_value(
        "GUI Prev State",
        before.gui_prev_state or "nil"
    )

    ui_value(
        "GUI Curr State",
        before.gui_curr_state or "nil"
    )

    ui_value(
        "Param Curr HP",
        before.param_curr_hp or 0
    )

    ui_value(
        "Param Curr Max HP",
        before.param_curr_max_hp or 0
    )

    ui_value(
        "Param Heal Value",
        before.param_heal_value or 0
    )

    ui_value(
        "Param HP Up Value",
        before.param_hp_up_value or 0
    )

    ui_value(
        "Derived Projected Max HP",
        before.derived_projected_max_hp or 0
    )

    ui_value(
        "Derived Projected Current HP",
        before.derived_projected_current_hp or 0
    )

    imgui.separator()
    imgui.text("After Scoped Override")

    ui_value(
        "GUI Prev Max HP",
        after_override.gui_prev_max_hp or 0
    )

    ui_value(
        "GUI Curr Max HP",
        after_override.gui_curr_max_hp or 0
    )

    ui_value(
        "GUI Prev State",
        after_override.gui_prev_state or "nil"
    )

    ui_value(
        "GUI Curr State",
        after_override.gui_curr_state or "nil"
    )

    ui_value(
        "Param Curr HP",
        after_override.param_curr_hp or 0
    )

    ui_value(
        "Param Curr Max HP",
        after_override.param_curr_max_hp or 0
    )

    ui_value(
        "Param Heal Value",
        after_override.param_heal_value or 0
    )

    ui_value(
        "Param HP Up Value",
        after_override.param_hp_up_value or 0
    )

    ui_value(
        "Derived Projected Max HP",
        after_override.derived_projected_max_hp or 0
    )

    ui_value(
        "Derived Projected Current HP",
        after_override.derived_projected_current_hp or 0
    )

    imgui.separator()
    imgui.text("Override Delta")

    ui_value(
        "GUI Prev Max HP Delta",
        delta.gui_prev_max_hp or 0
    )

    ui_value(
        "GUI Curr Max HP Delta",
        delta.gui_curr_max_hp or 0
    )

    ui_value(
        "Param Curr HP Delta",
        delta.param_curr_hp or 0
    )

    ui_value(
        "Param Curr Max HP Delta",
        delta.param_curr_max_hp or 0
    )

    ui_value(
        "Param Heal Value Delta",
        delta.param_heal_value or 0
    )

    ui_value(
        "Param HP Up Value Delta",
        delta.param_hp_up_value or 0
    )

    ui_value(
        "Projected Max HP Delta",
        delta.derived_projected_max_hp or 0
    )

    ui_value(
        "Projected Current HP Delta",
        delta.derived_projected_current_hp or 0
    )

    imgui.separator()

    ui_value(
        "Read Error",
        debug.error or ""
    )

    imgui.text(
        "Read-only comparison around the scoped preview correction."
    )

    imgui.tree_pop()
end

local function draw_preview_call_check(ctx)
    if not imgui.tree_node(
        "VitalConditionGui Preview Call Check (Integrated)"
    ) then
        return
    end

    local probe =
        ctx.preview_call_check or {}

    ui_value(
        "Enabled",
        probe.enabled == true
    )

    ui_value(
        "Installed",
        probe.installed == true
    )

    ui_value(
        "Target Type",
        probe.target_type or "unknown"
    )

    ui_value(
        "Target Method",
        probe.target_method or "unknown"
    )

    ui_value(
        "Enter Calls",
        probe.enter_calls or 0
    )

    ui_value(
        "Exit Calls",
        probe.exit_calls or 0
    )

    ui_value(
        "Condition GUI Type",
        probe.last_this_type or "unknown"
    )

    ui_value(
        "Condition GUI Ptr",
        probe.last_this_ptr or "nil"
    )

    ui_value(
        "Preview Param Type",
        probe.last_param_type or "unknown"
    )

    ui_value(
        "Preview Param Ptr",
        probe.last_param_ptr or "nil"
    )

    imgui.separator()
    imgui.text("Before preview()")

    ui_value(
        "Curr HP",
        probe.before_curr_hp or 0
    )

    ui_value(
        "Curr Max HP",
        probe.before_curr_max_hp or 0
    )

    ui_value(
        "Heal Value",
        probe.before_heal_value or 0
    )

    ui_value(
        "HP Up Value",
        probe.before_hp_up_value or 0
    )

    imgui.separator()
    imgui.text("After preview()")

    ui_value(
        "Curr HP",
        probe.after_curr_hp or 0
    )

    ui_value(
        "Curr Max HP",
        probe.after_curr_max_hp or 0
    )

    ui_value(
        "Heal Value",
        probe.after_heal_value or 0
    )

    ui_value(
        "HP Up Value",
        probe.after_hp_up_value or 0
    )

    imgui.separator()
    imgui.text("Delta")

    ui_value(
        "Curr HP Delta",
        probe.delta_curr_hp or 0
    )

    ui_value(
        "Curr Max HP Delta",
        probe.delta_curr_max_hp or 0
    )

    ui_value(
        "Heal Value Delta",
        probe.delta_heal_value or 0
    )

    ui_value(
        "HP Up Value Delta",
        probe.delta_hp_up_value or 0
    )

    if imgui.tree_node("Preview Call History") then
        for index, entry in ipairs(
            probe.history or {}
        ) do
            imgui.text(
                string.format(
                    "%02d before=(%d,%d,%d,%d) after=(%d,%d,%d,%d)",
                    index,
                    tonumber(entry.before_curr_hp) or 0,
                    tonumber(entry.before_curr_max_hp) or 0,
                    tonumber(entry.before_heal_value) or 0,
                    tonumber(entry.before_hp_up_value) or 0,
                    tonumber(entry.after_curr_hp) or 0,
                    tonumber(entry.after_curr_max_hp) or 0,
                    tonumber(entry.after_heal_value) or 0,
                    tonumber(entry.after_hp_up_value) or 0
                )
            )
        end

        imgui.tree_pop()
    end

    imgui.separator()

    ui_value(
        "Probe Error",
        probe.error or ""
    )

    imgui.text(
        "Integrated into the main preview hook; read-only before/after snapshots."
    )

    imgui.tree_pop()
end

local function draw_max_hp_commit_repair(ctx)
    if not imgui.tree_node("Max HP Commit Repair") then
        return
    end

    local state = ctx.state

    changed,
    state.max_hp_commit_repair_enabled =
        imgui.checkbox(
            "Enable Actual Max HP Repair",
            state.max_hp_commit_repair_enabled == true
        )

    ui_value("Pending", state.max_hp_commit_repair_pending)
    ui_value("Active", state.max_hp_commit_repair_active)
    ui_value("Source", state.max_hp_commit_last_source)

    imgui.separator()
    imgui.text("Max HP")
    ui_value("Before", state.max_hp_commit_before)
    ui_value("Gain", state.max_hp_commit_gain)
    ui_value("Expected", state.max_hp_commit_expected)
    ui_value("Native After", state.max_hp_commit_native_after)
    ui_value("Corrected After", state.max_hp_commit_corrected_after)

    imgui.separator()
    imgui.text("Current HP")
    ui_value("Before", state.max_hp_commit_before_current)
    ui_value("Expected", state.max_hp_commit_expected_current)
    ui_value("Native After", state.max_hp_commit_native_current_after)
    ui_value("Corrected After", state.max_hp_commit_corrected_current_after)

    imgui.separator()
    ui_value("Repair Count", state.max_hp_commit_apply_count)
    ui_value("Skip Count", state.max_hp_commit_skip_count)
    ui_value("Last Error", state.max_hp_commit_last_error)

    imgui.text(
        "Runs after committed item-use logic, not during hover preview."
    )

    imgui.tree_pop()
end

local function draw_item_panel(ctx)
    if imgui.tree_node("Item / Herb Max HP Gain") then
        
        ui_value(
            "Last Max HP Item Gain",
            ctx.state.last_player_add
        )
        
        ui_value(
            "Last HitPoint Max Gain",
            ctx.state.last_hitpoint_add
        )
        
        ui_value(
            "Preview Active",
            ctx.state.overlay_preview_active
        )
        
        ui_value(
            "Preview Current HP",
            ctx.state.preview_current_hp
        )
        
        ui_value(
            "Preview Current Max",
            ctx.state.preview_current_max_hp
        )
        
        ui_value(
            "Preview Heal",
            ctx.state.preview_heal
        )
        
        ui_value(
            "Preview HP Up",
            ctx.state.preview_hp_up
        )

        ui_value(
            "Actual Current HP",
            ctx.state.current_hp
        )
        
        ui_value(
            "Actual Max HP",
            ctx.state.max_hp
        )

        ui_value(
            "Preview Hook Calls",
            ctx.state.preview_hook_calls
        )

        ui_value(
            "Native Preview Current",
            ctx.state.preview_native_current_hp
        )

        ui_value(
            "Native Preview Max",
            ctx.state.preview_native_max_hp
        )

        ui_value(
            "Effective Preview Current",
            ctx.state.preview_current_hp
        )

        ui_value(
            "Effective Preview Max",
            ctx.state.preview_current_max_hp
        )

        ui_value(
            "Computed Heal Gain",
            ctx.state.overlay_preview_heal_hp
        )

        ui_value(
            "Computed Max Gain",
            ctx.state.overlay_preview_max_hp
        )

        ui_value(
            "Native FullMaxHp",
            ctx.state.native_full_max_hp
        )

        imgui.separator()
        imgui.text("Max HP Preview")

        ui_value(
            "Active",
            ctx.state.max_hp_preview_active
        )

        ui_value(
            "Native HP Up",
            ctx.state.max_hp_preview_native_hp_up
        )

        ui_value(
            "Corrected Gain",
            ctx.state.max_hp_preview_corrected_gain
        )

        ui_value(
            "Projected Max HP",
            ctx.state.max_hp_preview_projected_max_hp
        )

        ui_value(
            "Repair Required",
            ctx.state.max_hp_preview_repair_required
        )

        ui_value(
            "Configured Repair Gain",
            ctx.state.preview_custom_max_hp_gain
        )

        ui_value(
            "Corrected Max Gain",
            ctx.state.preview_corrected_max_hp_gain
        )

        ui_value(
            "Corrected Projected Max HP",
            ctx.state.preview_projected_max_hp
        )

        ui_value(
            "Max Gain Source",
            ctx.state.preview_max_gain_source
        )

        imgui.separator()
        imgui.text("Scoped Preview Override")

        changed, ctx.state.preview_override_enabled =
            imgui.checkbox(
                "Enable Scoped Override",
                ctx.state.preview_override_enabled == true
            )

        changed, ctx.state.preview_override_gain =
            imgui.drag_int(
                "Preview Max HP Gain",
                tonumber(
                    ctx.state.preview_override_gain
                ) or 100,
                1,
                0,
                1000
            )

        if imgui.button("GGY +80") then
            ctx.state.preview_override_gain = 80
        end

        imgui.same_line()

        if imgui.button("RY +90") then
            ctx.state.preview_override_gain = 90
        end

        imgui.same_line()

        if imgui.button("GRY / Beetle +100") then
            ctx.state.preview_override_gain = 100
        end

        ui_value(
            "Override Applied",
            ctx.state.preview_override_applied
        )

        ui_value(
            "Apply Count",
            ctx.state.preview_override_apply_count
        )

        ui_value(
            "Restore Count",
            ctx.state.preview_override_restore_count
        )

        ui_value(
            "Projected Max HP",
            ctx.state.preview_override_projected_max
        )

        ui_value(
            "Projected Current HP",
            ctx.state.preview_override_projected_current
        )

        ui_value(
            "Overridden Fields",
            ctx.state.preview_override_fields
        )

        ui_value(
            "Override Error",
            ctx.state.preview_override_last_error
        )

        ui_value(
            "Preview Behavior",
            ctx.state.preview_behavior
        )

        ui_value(
            "Native Previous Max",
            ctx.state.preview_native_previous_max_hp
        )

        ui_value(
            "Preview Enter Hooks",
            ctx.state.preview_enter_hooks
        )

        ui_value(
            "Preview Exit Hooks",
            ctx.state.preview_exit_hooks
        )

        ui_value(
            "Preview Raw This",
            ctx.state.preview_raw_this
        )

        ui_value(
            "Preview Raw Param",
            ctx.state.preview_raw_param
        )

        ui_value(
            "Preview Param Type",
            ctx.state.preview_param_type
        )

        ui_value(
            "Preview Param Ptr",
            ctx.state.preview_param_ptr
        )

        ui_value(
            "Preview Native Current HP",
            ctx.state.preview_native_current_hp
        )

        ui_value(
            "Preview Native Max HP",
            ctx.state.preview_native_max_hp
        )

        ui_value(
            "Native Projected Max HP",
            ctx.state.preview_native_projected_max_hp
        )

        ui_value(
            "Preview Heal Value",
            ctx.state.preview_heal
        )

        ui_value(
            "Preview HP Up Value",
            ctx.state.preview_hp_up
        )

        ui_value(
            "Preview Is Open",
            ctx.state.preview_is_open
        )

        ui_value(
            "Debug Curr Max",
            ctx.state.debug_curr_max
        )

        ui_value(
            "Debug HP Up",
            ctx.state.debug_hp_up
        )

        ui_value(
            "Debug Projected",
            ctx.state.debug_projected
        )

        ui_value(
            "Preview Is Open Raw",
            ctx.state.preview_is_open_raw
        )

        ui_value(
            "Preview Is Open",
            ctx.state.preview_is_open
        )

        imgui.tree_pop()
    end
end

local function draw_hook_status(ctx)
    imgui.text("[DEBUG]")
    imgui.separator()

    if imgui.tree_node("Hook Status") then
        ui_value("Status", ctx.state.status)
        ui_value("Player hook installed", ctx.state.player_hook_installed)
        ui_value("Player hook calls", ctx.state.player_hook_calls)
        ui_value("HitPoint hook installed", ctx.state.hitpoint_hook_installed)
        ui_value("HitPoint hook calls", ctx.state.hitpoint_hook_calls)
        ui_value("Preview hook installed", ctx.state.preview_hook_installed)
        ui_value("Preview hook calls", ctx.state.preview_hook_calls)
        ui_value("Gauge hook installed", ctx.state.gauge_hook_installed)
        ui_value("Gauge hook calls", ctx.state.gauge_hook_calls)
        imgui.tree_pop()
    end
end

local function draw_objects(ctx)
    if imgui.tree_node("Objects") then
        ui_value("Player object", ctx.state.player_ptr)
        ui_value("Player type", ctx.state.player_type)
        ui_value("HitPoint object", ctx.state.hitpoint_ptr)
        ui_value("HitPoint type", ctx.state.hitpoint_type)
        imgui.tree_pop()
    end
end

local function draw_native_hud(ctx, hud)
    if imgui.tree_node("Native HUD Values") then
        ui_value("Installed", ctx.hud_native.installed)
        ui_value("Calls", ctx.hud_native.calls)
        ui_value("Captured Type", ctx.hud_native.type)

        if imgui.button("Refresh Native HUD") then
            hud.refresh(ctx)
        end

        imgui.separator()

        ui_value("CurrState", ctx.hud_native.curr_state)
        ui_value("FrameToAngleRate", ctx.hud_native.frame_to_angle_rate)
        ui_value("CurrMaxFrame", ctx.hud_native.curr_max_frame)
        ui_value("CurrMaxAngle", ctx.hud_native.curr_max_angle)
        ui_value("CurrRate", ctx.hud_native.curr_rate)
        ui_value("CurrAngle", ctx.hud_native.curr_angle)
        ui_value("CurrTargetRate", ctx.hud_native.curr_target_rate)
        ui_value("CurrTargetAngle", ctx.hud_native.curr_target_angle)
        ui_value("CurrRateDiff", ctx.hud_native.curr_rate_diff)
        ui_value("CurrVirtualMinFrame", ctx.hud_native.curr_virtual_min_frame)
        ui_value("CurrVirtualMinAngle", ctx.hud_native.curr_virtual_min_angle)
        ui_value("CurrVirtualMaxFrame", ctx.hud_native.curr_virtual_max_frame)
        ui_value("CurrVirtualMaxAngle", ctx.hud_native.curr_virtual_max_angle)

        imgui.separator()

        if imgui.button("Normalize Native Gauge") then hud.normalize(ctx) end
        if imgui.button("Clear Virtual Gauge") then hud.clear_virtual(ctx) end

        imgui.separator()

        ui_value("draw", tostring(draw))
        ui_value("direct2d", tostring(direct2d))
        ui_value("d2d", tostring(d2d))
        ui_value("renderer", tostring(renderer))

        imgui.tree_pop()
    end
end

local function draw_amount_setter(ctx)
    if imgui.tree_node("AmountStatus Setter Interceptor") then
        ui_value("Installed", ctx.amount_setter.installed)
        ui_value("Calls", ctx.amount_setter.calls)
        ui_value("Last Method", ctx.amount_setter.last_method)
        ui_value("Last Value", ctx.amount_setter.last_value)

        imgui.separator()

        ui_value("CurrRate", ctx.amount_setter.curr_rate_calls .. " (" .. ctx.amount_setter.curr_rate_value .. ")")
        ui_value("TargetRate", ctx.amount_setter.curr_target_calls .. " (" .. ctx.amount_setter.curr_target_value .. ")")
        ui_value("RateDiff", ctx.amount_setter.curr_diff_calls .. " (" .. ctx.amount_setter.curr_diff_value .. ")")
        ui_value("CurrMax", ctx.amount_setter.curr_max_calls .. " (" .. ctx.amount_setter.curr_max_value .. ")")
        ui_value("VirtMin", ctx.amount_setter.virt_min_calls .. " (" .. ctx.amount_setter.virt_min_value .. ")")
        ui_value("VirtMax", ctx.amount_setter.virt_max_calls .. " (" .. ctx.amount_setter.virt_max_value .. ")")

        changed, ctx.amount_setter.force_enabled =
            imgui.checkbox("Force Amount Rate", ctx.amount_setter.force_enabled)

        changed, ctx.amount_setter.force_rate =
            imgui.drag_float("Forced Rate", ctx.amount_setter.force_rate, 1.0, 0.0, 100.0)

        imgui.tree_pop()
    end
end

local function draw_method_invoker(ctx, methods)
    if imgui.tree_node("Selected Method Invoker") then
        if imgui.button("Call editUpdate()") then
            methods.call_selected_void(ctx, "editUpdate")
        end

        if imgui.button("Call update(0.016)") then
            methods.call_selected_float(ctx, "update", 0.016)
        end

        changed, ctx.gui_inspector.test_float =
            imgui.drag_float("Test Float", ctx.gui_inspector.test_float or 0.0, 1.0, 0.0, 300.0)

        if imgui.button("setPlayFrame(Test Float)") then
            methods.call_selected_float(ctx, "setPlayFrame", ctx.gui_inspector.test_float)
        end

        changed, ctx.gui_inspector.test_u32 =
            imgui.drag_int("Test UInt", ctx.gui_inspector.test_u32 or 0, 1, 0, 9999)

        if imgui.button("setStatePattern(Test UInt)") then
            methods.call_selected_u32(ctx, "setStatePattern", ctx.gui_inspector.test_u32)
        end

        ui_value("Invoke Result", ctx.gui_inspector.invoke_result)
        ui_value("Invoke Error", ctx.gui_inspector.invoke_error)

        imgui.tree_pop()
    end
end

local function draw_gui_inspector(ctx, circle, gui, methods)
    if imgui.tree_node("GUI Inspector") then
        if imgui.button("Capture Circle") then
            circle.capture(ctx)
        end

        if imgui.button("Select Captured Circle") then
            gui.select(ctx, ctx.circle_probe.circle, "Captured Circle")
        end

        imgui.same_line()
        if imgui.button("Select Parent") then
            gui.select_related(ctx, "get_Parent()", "Parent")
        end

        imgui.same_line()
        if imgui.button("Select Child") then
            gui.select_related(ctx, "get_Child()", "Child")
        end

        if imgui.button("Select First Child Array") then
            gui.select_first_child_array(ctx)
        end

        if imgui.button("Select Next") then
            gui.select_related(ctx, "get_Next()", "Next")
        end

        imgui.same_line()
        if imgui.button("Select Prev") then
            gui.select_related(ctx, "get_Prev()", "Prev")
        end

        imgui.same_line()
        if imgui.button("Inspect Selected") then
            gui.inspect_selected(ctx)
        end

        imgui.same_line()
        if imgui.button("Inspect Fields") then
            gui.inspect_fields(ctx)
        end

        ui_value("Selected", ctx.gui_inspector.selected_label)
        ui_value("Type", ctx.gui_inspector.selected_type)
        ui_value("Error", ctx.gui_inspector.last_error)

        imgui.separator()

        if imgui.button("Duplicate Selected") then
            gui.duplicate_selected(ctx)
        end

        imgui.same_line()
        if imgui.button("Select Duplicate") then
            gui.select_duplicate(ctx)
        end

        ui_value("Duplicate Result", ctx.gui_duplicate.result)
        ui_value("Duplicate Source", ctx.gui_duplicate.source_type)
        ui_value("Duplicate Type", ctx.gui_duplicate.clone_type)
        ui_value("Duplicate Ptr", ctx.gui_duplicate.clone_ptr)
        ui_value("Duplicate Error", ctx.gui_duplicate.last_error)

        draw_method_invoker(ctx, methods)

        if #ctx.gui_inspector.field_lines > 0 then
            imgui.separator()
            imgui.text("Fields")

            for _, field_line in ipairs(ctx.gui_inspector.field_lines) do
                imgui.text(field_line)
            end
        end

        imgui.tree_pop()
    end
end

local function draw_circle_native(ctx, circle)
    if imgui.tree_node("Circle Native Test") then
        ui_value("Circle Type", ctx.circle_probe.type)

        if imgui.button("Set Circle Half Arc") then circle.set_arc_half(ctx) end
        if imgui.button("Set Circle Full Arc") then circle.set_arc_full(ctx) end
        if imgui.button("Set Circle To Overflow Arc") then circle.set_arc_overflow(ctx) end

        changed, ctx.circle_test.arc_y =
            imgui.drag_float("Test Arc Y", ctx.circle_test.arc_y, 1.0, 0.0, 270.0)

        if imgui.button("Apply Test Arc Y") then
            circle.set_arc_custom(ctx)
        end

        changed, ctx.circle_test.force_arc =
            imgui.checkbox("Force Arc During Native Setter", ctx.circle_test.force_arc)

        ui_value("Overflow Frame", ctx.state.overflow_frame)
        ui_value("Overflow Angle", ctx.state.overflow_angle)
        ui_value("Circle Test Error", ctx.circle_test.last_error)

        imgui.tree_pop()
    end
end

local function draw_circle_explorer(ctx)
    if imgui.tree_node("Circle Explorer") then
        ui_value("Installed", ctx.circle_explorer.installed)
        ui_value("Draw Calls", ctx.circle_explorer.calls)
        ui_value("Last Hook", ctx.circle_explorer.last_hook)

        if imgui.button("Clear Circle Samples") then
            ctx.circle_explorer.samples = {}
        end

        for ptr, sample in pairs(ctx.circle_explorer.samples) do
            if imgui.tree_node(ptr) then
                ui_value("Type", sample.type)
                ui_value("Visible", sample.visible)
                ui_value("ArcAngle", sample.arc_angle)
                ui_value("ArcStart", sample.arc_start)
                ui_value("InnerRatio", sample.inner_ratio)
                ui_value("Size", sample.size)
                ui_value("Position", sample.position)
                ui_value("GlobalPosition", sample.global_position)
                ui_value("Color", sample.color)
                ui_value("OuterColor", sample.outer_color)
                ui_value("InnerColor", sample.inner_color)
                imgui.tree_pop()
            end
        end

        imgui.tree_pop()
    end
end

local function draw_circle_setters(ctx)
    if imgui.tree_node("Circle Setter Explorer") then
        ui_value("Installed", ctx.circle_setter.installed)
        ui_value("Calls", ctx.circle_setter.calls)
        ui_value("Last Method", ctx.circle_setter.last_method)
        ui_value("Last Type", ctx.circle_setter.last_type)
        ui_value("Last Value", ctx.circle_setter.last_value)
        imgui.tree_pop()
    end
end

local function draw_project_header()
    imgui.text(project.name)
    imgui.text("by " .. project.author)
    imgui.text(
        project.version_string() ..
        "  |  " ..
        project.build_string()
    )
    imgui.separator()
end

local function draw_about_panel()
    about_ui.draw(project)
end

local function draw_rpg_panel(ctx)
    rpg_ui.draw(ctx)
end

local function draw_xp_ring_panel()
    local ok,
          error_message =
        pcall(
            xp_controls.draw
        )

    if not ok then
        imgui.text(
            "XP Ring UI Error: "
                .. tostring(error_message)
        )
    end
end

local function draw_developer_panel(ctx)
    if not imgui.tree_node("Developer") then
        return
    end

    local changed

    ctx.state.developer_mode = false
    imgui.text("Essential Project: Overflow hooks are active.")
    imgui.text("High-risk reflection tools stay disabled unless a focused test needs them.")

    changed,
    ctx.state.show_essential_diagnostics =
        imgui.checkbox(
            "Show Essential Diagnostics",
            ctx.state.show_essential_diagnostics == true
        )

    changed,
    ctx.state.draw_overlay_debug =
        imgui.checkbox(
            "Show Overlay Debug Bars",
            ctx.state.draw_overlay_debug == true
        )

    if ctx.state.developer_mode ~= true then
        imgui.text(
            "Advanced probes remain available internally, but stay out of the normal interface."
        )
    else
        imgui.text(
            "Developer Mode exposes reflection, hook, renderer, and snapshot tools."
        )
    end

    imgui.separator()
    enemies_ui.draw(ctx)

    imgui.tree_pop()
end

local function draw_errors(ctx)
    if ctx.state.error ~= "" then
        imgui.separator()
        imgui.text("ERROR:")
        imgui.text(ctx.state.error)
    end
end

function ui_mod.draw(ctx, hp, hud, circle, gui, methods, shader_probe)
    imgui.begin_window(project.name)

    draw_project_header()

    -- Everyday progression and recovery controls belong together. None of
    -- these trees are required for the runtime systems to keep working.
    if imgui.tree_node("Player & Progression") then
        draw_health_state(ctx, hp)
        draw_overflow(ctx)
        draw_rpg_panel(ctx)
        draw_item_panel(ctx)
        cheats_ui.draw(ctx, hp)
        imgui.tree_pop()
    end

    -- Visual presentation is kept separate from gameplay and save tools so
    -- adjusting the HUD does not require digging through unrelated controls.
    if imgui.tree_node("HUD & XP") then
        draw_xp_ring_panel()
        draw_overlay_panel(ctx)
        imgui.tree_pop()
    end

    -- Repair tools and detailed probes are intentionally grouped away from
    -- the normal player-facing controls.
    if imgui.tree_node("Diagnostics & Maintenance") then
        draw_max_hp_commit_repair(ctx)
        draw_developer_panel(ctx)
        imgui.tree_pop()
    end

    draw_about_panel()
    draw_errors(ctx)

    imgui.end_window()
end

return ui_mod
