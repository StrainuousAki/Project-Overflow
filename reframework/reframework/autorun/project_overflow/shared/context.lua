------------------------------------------------------------
-- Maintenance classification — Build 49.39
-- Module: autorun/project_overflow/shared/context.lua
-- Role: Shared utility, context, constants, logging, or event infrastructure.
-- Status: active infrastructure.
--
-- Compatibility policy:
--   Existing functions, hooks, module paths, and diagnostics are
--   intentionally retained in this maintenance pass.
--   `DEPRECATED` marks a supported legacy path, not removed code.
------------------------------------------------------------

------------------------------------------------------------
-- Project: Overflow — Shared Context
--
-- Holds the runtime state used by the health logic, HUD renderer,
-- probes, controls, and compatibility helpers. Keeping state here
-- lets the other modules stay focused on one responsibility.
------------------------------------------------------------

local ctx = {}

ctx.state = {
    error = "",
    status = "booted",

    -- Release UI / developer diagnostics.
    developer_mode = false,
    show_essential_diagnostics = true,

    -- Overlay placement is stored in a 2560x1440 reference space.
    -- overlay.lua converts it to the live backbuffer resolution.
    draw_overlay_debug = false,
    overlay_enabled = true,
    overlay_scale = 1.0,

    overlay_follow_native_hp_visibility = true,
    -- XP visibility treats "unknown" as hidden. The health overlay retains its
    -- own recovery behavior, but the XP ring must wait for a confirmed HUD draw.
    native_hp_bar_visibility_known = false,
    native_hp_bar_visible = true,
    native_hp_bar_visibility_source = "unknown",
    native_hp_bar_visibility_checks = 0,
    native_hp_bar_visibility_error = "",

    -- Confirmed from repeated visible/hidden snapshots:
    -- CurrStep 4 = hidden. Every other valid step is treated as active,
    -- including opening, shown, and closing transitions.
    native_hp_hidden_step = 4,
    native_hp_visibility_gate_safe_mode = false,
    native_hp_visibility_gate_reason =
        "Hide only when VitalGuiBehavior.CurrStep equals the confirmed hidden step.",
    native_hp_visibility_change_count = 0,
    native_hp_last_classified_step = -1,

    native_hp_visibility_change_count = 0,

    overlay_x = 1712.0,
    overlay_y = 873.0,

    overlay_reference_width = 2560.0,
    overlay_reference_height = 1440.0,
    overlay_reference_x = 2283.3,
    overlay_reference_y = 1164.6,
    -- Calibrated reference radius used directly by the resolution-aware
    -- overlay geometry.
    overlay_reference_radius = 84.2,

    overlay_geometry_radius = 0.0,

    overlay_anchor_right = true,
    overlay_anchor_bottom = true,

    overlay_radius = 62.0,
    overlay_thickness = 10,
    overlay_segments = 48,

    overlay_start_angle = 135.0,
    overlay_rotation = 135.0,
    overlay_direction = 1.0,
    overlay_max_sweep = 270.0,

    -- Legacy packed colors / references
    overlay_fg_color = 0xFFFFB695,
    overlay_bg_color = 0x64000000,

    -- Background ring alpha is forced to zero until Max HP unlocks the
    -- first overflow ring. Once Max HP exceeds the threshold, the slider
    -- controls the background even when current HP is still in vanilla HP.
    overlay_bg_auto_alpha = true,
    overlay_bg_alpha_threshold_hp = 2520.0,
    overlay_bg_effective_alpha = 100,
    overlay_bg_forced_hidden = true,
    overlay_bg_unlock_max_hp = 0,

    -- Overlay fade / visibility timing
    overlay_alpha = 1.0,
    overlay_target_alpha = 1.0,

    overlay_fade_in_speed = 5.0,
    overlay_fade_out_speed = 3.0,

    overlay_hold_time = 2.0,
    overlay_hold_timer = 2.0,

    -- Vanilla-style delayed damage trail
    overlay_damage_ratio = 0.0,
    overlay_damage_active = false,

    -- The trail crosses its entire captured damage gap in this duration.
    -- Larger hits therefore move faster while completing in the same time.
    -- Measured vanilla damage-trail duration.
    overlay_damage_vanilla_duration = 1.98,
    overlay_damage_duration = 1.98,

    overlay_damage_elapsed = 0.0,
    overlay_damage_start_ratio = 0.0,
    overlay_damage_target_ratio = 0.0,
    overlay_damage_transition_speed = 0.0,

    -- Per-frame diagnostics
    overlay_damage_live_ratio = 0.0,
    overlay_damage_initial_gap = 0.0,
    overlay_damage_current_gap = 0.0,
    overlay_damage_initial_gap_hp = 0.0,
    overlay_damage_current_gap_hp = 0.0,
    overlay_damage_derived_speed = 0.0,
    overlay_damage_progress = 0.0,
    overlay_damage_previous_ratio = 0.0,
    overlay_damage_measured_velocity = 0.0,

    overlay_last_ratio = nil,
    overlay_last_ring_index = nil,

    overlay_damage_r = 229,
    overlay_damage_g = 39,
    overlay_damage_b = 39,
    overlay_damage_a = 255,

    -- Vanilla-style actual healing transition.
    -- Triggered only by chainsaw.HitPoint.recovery(value), not by
    -- arbitrary HP edits, loading a save, or changing Max HP.
    overlay_heal_vanilla_duration = 1.98,
    overlay_heal_duration = 1.98,

    overlay_heal_active = false,
    overlay_heal_elapsed = 0.0,
    overlay_heal_start_ratio = 0.0,
    overlay_heal_target_ratio = 0.0,
    overlay_heal_ratio = 0.0,
    overlay_heal_transition_speed = 0.0,

    overlay_heal_initial_gap = 0.0,
    overlay_heal_current_gap = 0.0,
    overlay_heal_initial_gap_hp = 0.0,
    overlay_heal_current_gap_hp = 0.0,
    overlay_heal_progress = 0.0,
    overlay_heal_measured_velocity = 0.0,
    overlay_heal_previous_ratio = 0.0,

    -- Actual healing visual color.
    overlay_heal_r = 80,
    overlay_heal_g = 220,
    overlay_heal_b = 110,
    overlay_heal_a = 255,

    -- Recovery hook event data.
    heal_event_serial = 0,
    heal_event_consumed_serial = 0,
    heal_event_value = 0,
    heal_event_start_ratio = 0.0,
    heal_event_start_ring_index = 0,

    -- Heal / max-HP preview
    overlay_preview_active = false,

    overlay_preview_heal_hp = 0,
    overlay_preview_max_hp = 0,

    overlay_current_max_ratio = 0.0,
    overlay_preview_heal_ratio = 0.0,
    overlay_preview_max_ratio = 0.0,
    overlay_preview_total_ratio = 0.0,

    overlay_preview_r = 120,
    overlay_preview_g = 220,
    overlay_preview_b = 150,
    overlay_preview_a = 210,

    preview_heal = "unknown",
    preview_hp_up = "unknown",

    preview_current_hp = 0,
    preview_current_max_hp = 0,

    preview_native_previous_max_hp = 0,
    preview_native_current_hp = 0,
    preview_native_max_hp = 0,

    preview_behavior = nil,

    preview_condition_type = "unknown",
    preview_condition_ptr = "nil",

    preview_gui_prev_max_hp = 0,
    preview_gui_curr_max_hp = 0,

    preview_gui_curr_frame = 0.0,
    preview_gui_curr_max_frame = 0.0,
    preview_gui_memory_frame = 0.0,
    preview_gui_virtual_memory_frame = 0.0,

    -- Preview hook diagnostics
    preview_enter_calls = 0,
    preview_last_arg_types = {},
    preview_raw_this = "nil",
    preview_raw_param = "nil",
    preview_is_open = false,
    preview_is_open_raw = "unknown",
    preview_native_projected_max_hp = 0,

    preview_param = nil,
    preview_param_type = "unknown",
    preview_param_ptr = "nil",

    preview_item_id = "unknown",
    preview_item_name = "unknown",
    preview_item_type = "unknown",
    preview_custom_max_hp_gain = 0,
    preview_corrected_max_hp_gain = 0,
    preview_projected_max_hp = 0,
    preview_max_gain_source = "none",

    -- Explicit max-HP preview state.
    max_hp_preview_active = false,
    max_hp_preview_native_hp_up = 0,
    max_hp_preview_corrected_gain = 0,
    max_hp_preview_projected_max_hp = 0,
    max_hp_preview_repair_required = false,

    -- Actual item-use Max HP commit repair.
    max_hp_commit_repair_enabled = true,
    max_hp_commit_repair_pending = false,
    max_hp_commit_repair_active = false,

    max_hp_commit_before = 0,
    max_hp_commit_gain = 0,
    max_hp_commit_expected = 0,
    max_hp_commit_native_after = 0,
    max_hp_commit_corrected_after = 0,

    max_hp_commit_before_current = 0,
    max_hp_commit_expected_current = 0,
    max_hp_commit_native_current_after = 0,
    max_hp_commit_corrected_current_after = 0,

    max_hp_commit_apply_count = 0,
    max_hp_commit_skip_count = 0,
    max_hp_commit_last_source = "none",
    max_hp_commit_last_error = "",

    -- Condition math scales from actual Max HP. Native writes stay
    -- separate because forcing the native state can interrupt the
    -- game's damage and healing preview animations.
    -- These ratios work at vanilla Max HP and every custom Max HP value.
    condition_scaling_enabled = true,

    -- Native condition writes are separated from scaled-condition math.
    -- Disabled by default to preserve Capcom's damage/heal preview pipeline.
    condition_native_write_enabled = false,
    condition_native_write_skip_during_vital_animation = true,
    condition_native_write_block_reason = "disabled",

    condition_caution_ratio = 0.50,
    condition_danger_ratio = 0.25,

    condition_current_ratio = 1.0,
    condition_caution_hp = 0,
    condition_danger_hp = 0,

    condition_target_state = 0,
    condition_native_state = -1,
    condition_requested_state = -1,
    condition_last_stable_state = 0,
    condition_last_applied_target = -1,
    condition_direct_fallback_count = 0,
    condition_transition_count = 0,

    condition_apply_count = 0,
    condition_skip_count = 0,
    condition_gui_ptr = "nil",
    condition_gui_type = "unknown",
    condition_last_error = "",

    -- Read-only native condition visual probe.
    condition_visual_probe_enabled = true,
    condition_visual_probe_count = 0,
    condition_visual_probe_last_error = "",

    vital_gauge_type = "unknown",
    vital_gauge_ptr = "nil",
    vital_gauge_state = "unknown",
    vital_gauge_visible = "unknown",
    vital_gauge_color_scale = "unknown",
    vital_gauge_play_frame = "unknown",

    damage_flare_type = "unknown",
    damage_flare_ptr = "nil",
    damage_flare_state = "unknown",
    damage_flare_visible = "unknown",
    damage_flare_color_scale = "unknown",
    damage_flare_play_frame = "unknown",

    amount_gui_type = "unknown",
    amount_gui_ptr = "nil",

    -- Read-only VitalGaugeGui reflection explorer.
    vital_gauge_reflection_enabled = true,
    vital_gauge_reflection_capture_requested = false,
    vital_gauge_reflection_capture_count = 0,
    vital_gauge_reflection_max_fields = 64,
    vital_gauge_reflection_rows = {},
    vital_gauge_reflection_selected_index = 0,
    vital_gauge_reflection_selected_field = "",
    vital_gauge_reflection_selected_type = "unknown",
    vital_gauge_reflection_selected_ptr = "nil",
    vital_gauge_reflection_child_rows = {},
    vital_gauge_reflection_root_hierarchy = "",
    vital_gauge_reflection_child_hierarchy = "",
    vital_gauge_reflection_last_error = "",

    -- Read-only VitalGuiBehavior transition recorder.
    vital_behavior_probe_enabled = true,
    vital_behavior_probe_installed = false,
    vital_behavior_probe_error = "",

    vital_behavior_change_step_calls = 0,
    vital_behavior_late_update_calls = 0,
    vital_behavior_capture_count = 0,

    vital_behavior_type = "unknown",
    vital_behavior_ptr = "nil",

    vital_behavior_curr_step = -1,
    vital_behavior_requested_step = -1,
    vital_behavior_remaining_display_time = 0.0,

    vital_behavior_org_type = "unknown",
    vital_behavior_org_ptr = "nil",
    vital_behavior_org_prev_state = -1,
    vital_behavior_org_curr_state = -1,
    vital_behavior_org_curr_frame = 0.0,

    vital_behavior_col_type = "unknown",
    vital_behavior_col_ptr = "nil",
    vital_behavior_col_prev_state = -1,
    vital_behavior_col_curr_state = -1,
    vital_behavior_col_curr_frame = 0.0,

    vital_behavior_hp = 0,
    vital_behavior_max_hp = 0,
    vital_behavior_hp_ratio = 0.0,

    vital_behavior_last_event = "none",
    vital_behavior_history = {},

    -- Read-only native HUD visibility snapshots.
    native_visibility_visible_snapshot = nil,
    native_visibility_hidden_snapshot = nil,
    native_visibility_visible_capture_count = 0,
    native_visibility_hidden_capture_count = 0,
    native_visibility_last_capture = "none",

    -- Scoped preview-only override.
    preview_override_enabled = true,
    preview_override_gain = 100,
    preview_override_projected_max = 0,
    preview_override_projected_current = 0,

    preview_override_applied = false,
    preview_override_apply_count = 0,
    preview_override_restore_count = 0,
    preview_override_last_error = "",
    preview_override_fields = "",

    debug_curr_max = 0,
    debug_hp_up = 0,
    debug_projected = 0,

    vital_open_previous_max = 0,
    vital_open_current_max = 0,
    vital_open_current_hp = 0,

    -- Heal Preview Pulse Controls

    overlay_preview_pulse_enabled = true,

    overlay_preview_pulse_time = 0.0,
    overlay_preview_pulse_hold = 1.0,
    overlay_preview_pulse_fade = 1.0,

    overlay_preview_pulse_alpha = 1.0,
    overlay_preview_pulse_full_alpha = 1.0,
    overlay_preview_pulse_low_alpha = 0.30,

    overlay_preview_timeout = 0.0,
    overlay_preview_hold_time = 0.15,

    -- End cap
    overlay_cap_enabled = true,
    overlay_cap_length = 0.280,
    overlay_cap_width = 1.590,

    -- Last observed HP state
    overlay_last_current_hp = nil,
    overlay_last_max_hp = nil,

    -- Native objects
    player = nil,
    hitpoint = nil,

    player_ptr = "nil",
    player_type = "unknown",

    hitpoint_ptr = "nil",
    hitpoint_type = "unknown",

    -- HP limits / ring configuration
    default_max_hp = 1260,
    vanilla_max_hp_cap = 2500,
    native_full_max_hp = 2520.0,
    visual_gauge_cap = 2520,
    native_visual_full_hp = 2520,
    observed_vanilla_extended_hp = 3360,

    min_custom_max_hp = 100,
    safe_total_hp_cap = 20160,
    debug_total_hp_cap = 100000,
    clamp_to_safe_cap = true,

    overflow_start_hp = 2520,
    overflow_ring_hp = 2520,

    -- Hook installation flags
    player_hook_installed = false,
    hitpoint_hook_installed = false,
    preview_hook_installed = false,
    gauge_hook_installed = false,

    -- Hook counters
    player_hook_calls = 0,
    hitpoint_hook_calls = 0,
    preview_hook_calls = 0,
    preview_enter_hooks = 0,
    preview_exit_hooks = 0,
    gauge_hook_calls = 0,

    -- Last native deltas
    last_player_add = 0,
    last_hitpoint_add = 0,

    -- Current native HP values
    current_hp = "unknown",
    max_hp = "unknown",
    hp_ratio = "unknown",

    -- Overflow compatibility values
    overflow_current = 0,
    overflow_max = 2520,
    overflow_ratio = 0.0,
    overflow_frame = 0.0,
    overflow_angle = 0.0,

    -- Multi-ring overflow values
    overflow_total_hp = 0,
    overflow_completed_rings = 0,
    overflow_active_ring_hp = 0,
    overflow_active_ring_index = 0,
    overflow_active_ratio = 0.0,

    -- Cross-ring Max-HP preview diagnostics.
    overlay_preview_current_ring_index = 0,
    overlay_preview_projected_ring_index = 0,
    overlay_preview_projected_ring_ratio = 0.0,
    overlay_preview_crosses_ring = false,

    overlay_visible_ring_count = 0,
    overlay_projected_visible_ring_count = 0,
    overlay_next_ring_threshold_hp = 5040,

    -- Safe one-ring boundary preview.
    overlay_next_ring_preview_enabled = true,
    overlay_next_ring_preview_radial_offset = -2.5,
    overlay_next_ring_preview_radius = 0.0,
    overlay_next_ring_preview_sweep = 0.0,
    overlay_next_ring_preview_drawn = false,

    -- Native gauge debug values
    gauge_type = "unknown",
    gauge_max_frame = "unknown",
    gauge_rate = "unknown",
    gauge_target_rate = "unknown"
}






ctx.ring_styles = {
    {
        name = "Ring 1",
        start_hp = 2520,
        end_hp = 5040,
        enabled = true,

        fg_r = 149, fg_g = 182, fg_b = 255, fg_a = 255,
        bg_r = 0, bg_g = 101, bg_b = 0, bg_a = 100,
        damage_r = 229, damage_g = 39, damage_b = 39, damage_a = 255,
        heal_r = 80, heal_g = 220, heal_b = 110, heal_a = 255,
        preview_r = 120, preview_g = 220, preview_b = 150, preview_a = 210,
        cap_r = 255, cap_g = 255, cap_b = 255, cap_a = 255
    },
    {
        name = "Ring 2",
        start_hp = 5040,
        end_hp = 7560,
        enabled = true,

        fg_r = 184, fg_g = 112, fg_b = 255, fg_a = 255,
        bg_r = 149, bg_g = 182, bg_b = 255, bg_a = 100,
        damage_r = 235, damage_g = 55, damage_b = 75, damage_a = 255,
        heal_r = 126, heal_g = 235, heal_b = 155, heal_a = 255,
        preview_r = 218, preview_g = 150, preview_b = 255, preview_a = 220,
        cap_r = 255, cap_g = 255, cap_b = 255, cap_a = 255
    },
    {
        name = "Ring 3",
        start_hp = 7560,
        end_hp = 10080,
        enabled = true,

        fg_r = 255, fg_g = 196, fg_b = 74, fg_a = 255,
        bg_r = 184, bg_g = 112, bg_b = 255, bg_a = 100,
        damage_r = 240, damage_g = 72, damage_b = 54, damage_a = 255,
        heal_r = 130, heal_g = 235, heal_b = 130, heal_a = 255,
        preview_r = 255, preview_g = 228, preview_b = 118, preview_a = 220,
        cap_r = 255, cap_g = 255, cap_b = 255, cap_a = 255
    },
    {
        name = "Ring 4",
        start_hp = 10080,
        end_hp = 12600,
        enabled = true,

        fg_r = 255, fg_g = 112, fg_b = 170, fg_a = 255,
        bg_r = 255, bg_g = 196, bg_b = 74, bg_a = 100,
        damage_r = 245, damage_g = 48, damage_b = 68, damage_a = 255,
        heal_r = 105, heal_g = 235, heal_b = 155, heal_a = 255,
        preview_r = 255, preview_g = 160, preview_b = 205, preview_a = 220,
        cap_r = 255, cap_g = 255, cap_b = 255, cap_a = 255
    },
    {
        name = "Ring 5",
        start_hp = 12600,
        end_hp = 15120,
        enabled = true,

        fg_r = 95, fg_g = 230, fg_b = 230, fg_a = 255,
        bg_r = 255, bg_g = 112, bg_b = 170, bg_a = 100,
        damage_r = 235, damage_g = 58, damage_b = 58, damage_a = 255,
        heal_r = 105, heal_g = 245, heal_b = 175, heal_a = 255,
        preview_r = 145, preview_g = 255, preview_b = 255, preview_a = 220,
        cap_r = 255, cap_g = 255, cap_b = 255, cap_a = 255
    },
    {
        name = "Ring 6",
        start_hp = 15120,
        end_hp = 17640,
        enabled = true,

        fg_r = 0, fg_g = 166, fg_b = 255, fg_a = 255,
        bg_r = 95, bg_g = 230, bg_b = 230, bg_a = 100,
        damage_r = 245, damage_g = 40, damage_b = 40, damage_a = 255,
        heal_r = 125, heal_g = 235, heal_b = 135, heal_a = 255,
        preview_r = 255, preview_g = 180, preview_b = 110, preview_a = 220,
        cap_r = 255, cap_g = 255, cap_b = 255, cap_a = 255
    },
    {
        name = "Ring 7",
        start_hp = 17640,
        end_hp = 20160,
        enabled = true,

        fg_r = 255, fg_g = 255, fg_b = 255, fg_a = 255,
        bg_r = 0, bg_g = 166, bg_b = 255, bg_a = 100,
        damage_r = 255, damage_g = 55, damage_b = 55, damage_a = 255,
        heal_r = 140, heal_g = 255, heal_b = 165, heal_a = 255,
        preview_r = 255, preview_g = 255, preview_b = 180, preview_a = 220,
        cap_r = 255, cap_g = 255, cap_b = 255, cap_a = 255
    }
}

ctx.preview_call_check = {
    enabled = true,
    installed = false,
    error = "",

    target_type =
        "chainsaw.VitalConditionGui",

    target_method =
        "preview(chainsaw.VitalGuiBehavior.HealPreviewParam)",

    enter_calls = 0,
    exit_calls = 0,

    last_this_type = "unknown",
    last_this_ptr = "nil",

    last_param_type = "unknown",
    last_param_ptr = "nil",

    before_curr_hp = 0,
    before_curr_max_hp = 0,
    before_heal_value = 0,
    before_hp_up_value = 0,

    after_curr_hp = 0,
    after_curr_max_hp = 0,
    after_heal_value = 0,
    after_hp_up_value = 0,

    delta_curr_hp = 0,
    delta_curr_max_hp = 0,
    delta_heal_value = 0,
    delta_hp_up_value = 0,

    history_limit = 48,
    history = {}
}


ctx.preview_gui_backing = {
    read_ok = false,
    error = "",
    read_count = 0,

    gui_type = "unknown",
    gui_ptr = "nil",
    param_type = "unknown",
    param_ptr = "nil",

    before = {
        gui_prev_max_hp = 0,
        gui_curr_max_hp = 0,
        gui_prev_state = "nil",
        gui_curr_state = "nil",

        param_curr_hp = 0,
        param_curr_max_hp = 0,
        param_heal_value = 0,
        param_hp_up_value = 0,

        derived_projected_max_hp = 0,
        derived_projected_current_hp = 0
    },

    after_override = {
        gui_prev_max_hp = 0,
        gui_curr_max_hp = 0,
        gui_prev_state = "nil",
        gui_curr_state = "nil",

        param_curr_hp = 0,
        param_curr_max_hp = 0,
        param_heal_value = 0,
        param_hp_up_value = 0,

        derived_projected_max_hp = 0,
        derived_projected_current_hp = 0
    },

    delta = {
        gui_prev_max_hp = 0,
        gui_curr_max_hp = 0,

        param_curr_hp = 0,
        param_curr_max_hp = 0,
        param_heal_value = 0,
        param_hp_up_value = 0,

        derived_projected_max_hp = 0,
        derived_projected_current_hp = 0
    }
}



ctx.vitalmax_panel_snapshot = {
    enabled = true,
    error = "",
    capture_count = 0,
    before = {},
    after = {},
    delta = {}
}

ctx.native_damage = {
    installed = false,
    calls = 0,
    last_error = "",

    object = nil,
    object_type = "unknown",
    object_ptr = "nil",

    elapsed_sec = 0.0,

    curr_frame = 0.0,
    curr_gradation_frame = 0.0,
    curr_gradation_gauge_frame_diff = 0.0,
    curr_memory_max_frame = 0.0,
    curr_memory_max_frame_diff = 0.0,
    curr_memory_frame = 0.0,
    curr_virtual_memory_frame = 0.0,
    curr_max_frame = 0.0,
    curr_frame_diff = 0.0,

    live_ratio = 0.0,
    memory_ratio = 0.0,
    virtual_memory_ratio = 0.0,
    gradation_ratio = 0.0,

    -- CurrGradationFrame is the vanilla delayed-damage endpoint.
    damage_ratio = 0.0,
    damage_gap = 0.0,
    damage_gap_hp = 0.0,

    active = false,
    transition_elapsed = 0.0,
    transition_start_gap = 0.0,
    transition_start_damage_ratio = 0.0,
    transition_target_ratio = 0.0,

    previous_damage_ratio = nil,
    measured_velocity = 0.0,

    -- Passive timing measurements derived only from VitalConditionGui.
    transition_current_gap = 0.0,
    transition_progress = 0.0,
    transition_average_velocity = 0.0,
    transition_inferred_duration = 0.0,
    transition_remaining_time = 0.0,

    transition_last_duration = 0.0,
    transition_last_start_gap = 0.0,
    transition_last_average_velocity = 0.0,

    transition_sample_count = 0,
    transition_ratio_change_count = 0,
    transition_last_ratio_change = 0.0,

    -- Nested chainsaw.VitalGaugeGui object.
    gauge_object = nil,
    gauge_object_type = "unknown",
    gauge_object_ptr = "nil",

    gauge_curr_max_frame = 0.0,
    gauge_curr_rate = 0.0,
    gauge_curr_target_rate = 0.0,
    gauge_curr_rate_diff = 0.0,
    gauge_is_end = false,

    gauge_curr_max_frame_read_ok = false,
    gauge_curr_rate_read_ok = false,
    gauge_curr_target_rate_read_ok = false,
    gauge_curr_rate_diff_read_ok = false,
    gauge_is_end_read_ok = false,

    gauge_curr_max_frame_source = "not read",
    gauge_curr_rate_source = "not read",
    gauge_curr_target_rate_source = "not read",
    gauge_curr_rate_diff_source = "not read",
    gauge_is_end_source = "not read",

    gauge_damage_ratio = 0.0,
    gauge_live_ratio = 0.0,
    gauge_damage_gap = 0.0,
    gauge_damage_gap_hp = 0.0,

    gauge_previous_rate = nil,
    gauge_measured_velocity = 0.0,

    gauge_transition_active = false,
    gauge_transition_elapsed = 0.0,
    gauge_transition_start_gap = 0.0,
    gauge_transition_start_rate = 0.0,
    gauge_transition_target_rate = 0.0,
    gauge_transition_end_rate = 0.0,
    gauge_transition_duration = 0.0,

    gauge_last_nonzero_diff = 0.0,
    gauge_peak_velocity = 0.0,
    gauge_min_rate = 0.0,
    gauge_max_rate = 0.0,

    gauge_history_limit = 48,
    gauge_history = {},

    -- Direct VitalGaugeGui update/updateGauge hook diagnostics.
    gauge_update_hook_installed = false,
    gauge_update_hook_calls = 0,
    gauge_update_gauge_hook_calls = 0,

    gauge_last_hook = "none",
    gauge_last_phase = "none",
    gauge_last_input = 0.0,

    gauge_pre_rate = 0.0,
    gauge_pre_target_rate = 0.0,
    gauge_pre_rate_diff = 0.0,
    gauge_pre_is_end = false,

    gauge_post_rate = 0.0,
    gauge_post_target_rate = 0.0,
    gauge_post_rate_diff = 0.0,
    gauge_post_is_end = false,

    gauge_tick_delta_rate = 0.0,
    gauge_tick_velocity = 0.0,

    -- chainsaw.VitalDamageFlareGui diagnostics.
    flare_hook_installed = false,
    flare_set_max_frame_calls = 0,
    flare_set_state_calls = 0,

    flare_object = nil,
    flare_object_type = "unknown",
    flare_object_ptr = "nil",

    flare_last_hook = "none",
    flare_last_phase = "none",

    flare_curr_state = -1,
    flare_curr_state_name = "UNKNOWN",

    flare_pre_state = -1,
    flare_pre_state_name = "UNKNOWN",
    flare_post_state = -1,
    flare_post_state_name = "UNKNOWN",

    flare_last_max_frame_input = 0.0,
    flare_pre_max_frame_input = 0.0,
    flare_post_max_frame_input = 0.0,

    flare_damage_active = false,
    flare_damage_elapsed = 0.0,
    flare_last_damage_duration = 0.0,

    flare_history_limit = 48,
    flare_history = {},

    read_success_count = 0,
    read_failure_count = 0,
    last_read_name = "none",
    last_read_source = "none",

    curr_frame_read_ok = false,
    curr_frame_source = "not read",

    curr_memory_frame_read_ok = false,
    curr_memory_frame_source = "not read",

    curr_virtual_memory_frame_read_ok = false,
    curr_virtual_memory_frame_source = "not read",

    curr_gradation_frame_read_ok = false,
    curr_gradation_frame_source = "not read",

    curr_max_frame_read_ok = false,
    curr_max_frame_source = "not read",

    curr_frame_diff_read_ok = false,
    curr_frame_diff_source = "not read",

    curr_memory_max_frame_read_ok = false,
    curr_memory_max_frame_source = "not read",

    curr_memory_max_frame_diff_read_ok = false,
    curr_memory_max_frame_diff_source = "not read",

    curr_gradation_gauge_frame_diff_read_ok = false,
    curr_gradation_gauge_frame_diff_source = "not read"
}

ctx.shader_probe = {
    installed = false,
    capture_count = 0,
    last_hook = "none",
    last_error = "",

    behavior = nil,
    behavior_type = "unknown",
    behavior_ptr = "nil",

    gui_path = "unknown",

    folder = nil,
    folder_type = "unknown",
    folder_ptr = "nil",

    reflect_mat = nil,
    reflect_type = "unknown",

    overlay_mat = nil,
    overlay_type = "unknown",

    overlay_float_values = {
    0.3,
    5.0
    },

    overlay_float_originals = {
        0.3,
        5.0
    },

    reflect_float_values = {
        2.0,
        -0.25,
        -0.25,
        1.2
    },

    reflect_float_originals = {
        2.0,
        -0.25,
        -0.25,
        1.2
    },

    overlay_param_count = 0,
    reflect_param_count = 0,

    last_applied_material = "none",
    last_applied_index = -1,
    last_applied_value = 0.0,

    material_lines = {}
}

ctx.screen = {
    width = 2560.0,
    height = 1440.0,
    previous_width = 2560.0,
    previous_height = 1440.0,
    resolution_changed = false,
    resolution_change_count = 0,
    last_resolution_source = "default",
    last_resolution_error = "",
    scale_x = 1.0,
    scale_y = 1.0,
    uniform_scale = 1.0,
    computed_center_x = 0.0,
    computed_center_y = 0.0,
    computed_radius = 0.0,
    computed_thickness = 0.0
}

ctx.ui = {
    overlay_fg_r = 149,
    overlay_fg_g = 182,
    overlay_fg_b = 255,
    overlay_fg_a = 255,

    overlay_bg_r = 0,
    overlay_bg_g = 0,
    overlay_bg_b = 0,
    overlay_bg_a = 100,

    overlay_cap_r = 149,
    overlay_cap_g = 182,
    overlay_cap_b = 255,
    overlay_cap_a = 255,

    hp_amount = 100,
    max_hp_amount = 100,
    set_current_hp = 1260,
    set_max_hp = 1260,
}

ctx.gui_inspector = {
    max_depth = 4,
    selected = nil,
    selected_label = "none",
    selected_type = "unknown",
    parent = nil,
    next = nil,
    prev = nil,
    child = nil,
    lines = {},
    field_lines = {},
    methods = {},
    properties = {},
    test_float = 0.0,
    test_u32 = 0,
    invoke_result = "not called",
    invoke_error = "",
    last_error = ""
}

ctx.state.overlay_fg = {
    r = 255,
    g = 255,
    b = 0,
    a = 255
}

ctx.state.overlay_bg = {
    r = 0,
    g = 0,
    b = 0,
    a = 68
}

ctx.flags = {
    hp_dirty = true,
    --hud_dirty = true,
    --overlay_dirty = true
}

ctx.timing = {
    last_hp_refresh = 0.0,
    hp_refresh_interval = 0.10
}

ctx.health_refresh = {
    dirty = true,

    fallback_interval = 0.25,
    fallback_timer = 0.0,

    last_current = nil,
    last_max = nil,

    refresh_count = 0
}

ctx.methods = {
    player_add_max_hp = nil,
    hp_get_default = nil,
    hp_get_max = nil,
    hp_get_current = nil,
    hp_get_ratio = nil,
    hp_recovery = nil,
    hp_add_damage = nil,
    hp_add_max = nil,
    hp_set_max = nil
}

ctx.hud_native = {
    installed = false,
    calls = 0,
    type = "unknown",

    curr_state = "unknown",
    frame_to_angle_rate = "unknown",
    curr_max_frame = "unknown",
    curr_max_angle = "unknown",
    curr_rate = "unknown",
    curr_angle = "unknown",
    curr_target_rate = "unknown",
    curr_target_angle = "unknown",
    curr_rate_diff = "unknown",
    curr_virtual_min_frame = "unknown",
    curr_virtual_min_angle = "unknown",
    curr_virtual_max_frame = "unknown",
    curr_virtual_max_angle = "unknown"
}

ctx.amount_setter = {
    installed = false,
    calls = 0,

    last_method = "",
    last_value = "",

    curr_rate_calls = 0,
    curr_target_calls = 0,
    curr_diff_calls = 0,
    curr_max_calls = 0,
    virt_min_calls = 0,
    virt_max_calls = 0,

    curr_rate_value = "",
    curr_target_value = "",
    curr_diff_value = "",
    curr_max_value = "",
    virt_min_value = "",
    virt_max_value = "",

    force_enabled = false,
    force_rate = 50.0
}

ctx.amount_status_gui = nil

ctx.gui_duplicate = {
    clone = nil,
    clone_label = "none",
    clone_type = "unknown",
    clone_ptr = "nil",
    source_type = "unknown",
    result = "not tested",
    last_error = ""
}

ctx.circle_probe = {
    circle = nil,
    type = "unknown",
    visible = "unknown",
    play_frame = "unknown",
    color_scale = "unknown"
}

ctx.circle_test = {
    last_error = "",
    arc_y = 135.0,
    force_arc = false
}

ctx.circle_explorer = {
    installed = false,
    calls = 0,
    last_hook = "none",
    max_samples = 12,
    samples = {}
}

ctx.circle_setter = {
    installed = false,
    calls = 0,
    last_method = "none",
    last_type = "unknown",
    last_value = "unknown"
}

function ctx.clear_error()
    ctx.state.error = ""
end

function ctx.set_error(message)
    ctx.state.error = tostring(message)
end

function ctx.clamp(value, min_value, max_value)
    if value < min_value then return min_value end
    if value > max_value then return max_value end
    return value
end

function ctx.active_total_cap()
    if ctx.state.clamp_to_safe_cap then
        return tonumber(ctx.state.safe_total_hp_cap) or 20160
    end

    return tonumber(ctx.state.debug_total_hp_cap) or 100000
end

function ctx.signed_int32(value)
    local n = sdk.to_int64(value)

    if n > 2147483647 then
        n = n - 4294967296
    end

    return n
end

function ctx.ptr_from_obj(obj)
    if obj == nil then return "nil" end

    local ok, result = pcall(function()
        return string.format("0x%X", sdk.to_ptr(obj))
    end)

    if ok then return result end
    return "managed"
end

function ctx.type_name_from_obj(obj)
    if obj == nil then return "nil" end

    local ok, result = pcall(function()
        local td = obj:get_type_definition()
        if td == nil then return "unknown managed" end
        return td:get_full_name()
    end)

    if ok then return result end
    return "type error"
end

function ctx.managed_from_arg(args, index)
    local ok, obj = pcall(function()
        return sdk.to_managed_object(args[index])
    end)

    if ok and obj ~= nil then return obj end
    return nil
end

function ctx.current_hp_number()
    return tonumber(ctx.state.current_hp)
end

function ctx.max_hp_number()
    return tonumber(ctx.state.max_hp)
end

function ctx.is_player_type(obj)
    local t = ctx.type_name_from_obj(obj)

    return
        string.find(t, "Ch0a0z0HeadUpdater") ~= nil or
        string.find(t, "PlayerHeadUpdater") ~= nil
end

function ctx.is_hitpoint_type(obj)
    return ctx.type_name_from_obj(obj) == "chainsaw.HitPoint"
end

function ctx.update_overflow_math()
    local raw_current_hp =
        tonumber(ctx.state.current_hp) or 0

    local max_hp =
        tonumber(ctx.state.max_hp) or 0

    -- The HUD should never render current HP beyond the current Max HP.
    -- Some recovery paths can briefly report an over-cap value before
    -- the game settles it, which otherwise rolls the overlay to a new ring.
    local current_hp =
        max_hp > 0
        and math.min(raw_current_hp, max_hp)
        or raw_current_hp

    local overflow_start =
        tonumber(ctx.state.overflow_start_hp) or 2520

    local ring_capacity =
        tonumber(ctx.state.overflow_ring_hp) or 2520

    if ring_capacity <= 0 then
        ring_capacity = 2520
    end

    local current_overflow =
        math.max(0, current_hp - overflow_start)

    local max_overflow =
        math.max(0, max_hp - overflow_start)

    local completed_rings =
        math.floor(current_overflow / ring_capacity)

    local active_ring_hp =
        current_overflow % ring_capacity

    local active_ring_index =
        completed_rings

    local active_ratio =
        active_ring_hp / ring_capacity

    -- Exact multiples should display a completed full ring rather
    -- than an empty new ring unless additional HP exists beyond it.
    if
        current_overflow > 0 and
        active_ring_hp == 0
    then
        active_ratio = 1.0
        active_ring_index =
            math.max(0, completed_rings - 1)
    end

    ctx.state.overflow_total_hp =
        current_overflow

    ctx.state.overflow_completed_rings =
        completed_rings

    ctx.state.overflow_active_ring_hp =
        active_ring_hp

    ctx.state.overflow_active_ring_index =
        active_ring_index

    ctx.state.overflow_active_ratio =
        ctx.clamp(active_ratio, 0.0, 1.0)

    -- Compatibility fields used by the current single-ring renderer.
    ctx.state.overflow_current =
        current_overflow

    ctx.state.overflow_max =
        ring_capacity

    ctx.state.overflow_ratio =
        ctx.state.overflow_active_ratio

    ctx.state.overflow_frame =
        ctx.state.overflow_active_ratio * 50.0

    ctx.state.overflow_angle =
        ctx.state.overflow_active_ratio *
        (tonumber(ctx.state.overlay_max_sweep) or 270.0)
end

function ctx.rgba_to_u32(r, g, b, a)
    a = math.floor(ctx.clamp(tonumber(a) or 255, 0, 255))
    r = math.floor(ctx.clamp(tonumber(r) or 255, 0, 255))
    g = math.floor(ctx.clamp(tonumber(g) or 255, 0, 255))
    b = math.floor(ctx.clamp(tonumber(b) or 0, 0, 255))

    -- REFramework draw API appears to consume 0xAABBGGRR.
    return
        (a * 0x1000000) +
        (b * 0x10000) +
        (g * 0x100) +
        r
end

return ctx
