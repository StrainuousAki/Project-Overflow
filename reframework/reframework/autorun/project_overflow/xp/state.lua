------------------------------------------------------------
-- Maintenance classification — Build 49.39
-- Module: autorun/project_overflow/xp/state.lua
-- Role: HUD, XP, material, geometry, or rendering implementation.
-- Status: active renderer.
--
-- Compatibility policy:
--   Existing functions, hooks, module paths, and diagnostics are
--   intentionally retained in this maintenance pass.
--   `DEPRECATED` marks a supported legacy path, not removed code.
------------------------------------------------------------

------------------------------------------------------------
-- Project: Overflow — xp/state.lua
-- XP-ring state, geometry, visibility, material, and rendering.
------------------------------------------------------------

local state = {
    enabled = true,
    preview_enabled = false,
    follow_native_hp_visibility = true,

    max_sweep = 135.0,
    start_angle = 270.0,
    direction = 1.0,
    gap = 10.0,
    thickness_ratio = 0.75,
    background_thickness_ratio = 1.00,
    segments = 48,

    -- Native-style rectangular gold background track.
    background_r = 83,
    background_g = 62,
    background_b = 10,
    background_a = 255,

    -- Animated gold progression fill.
    fill_r = 238,
    fill_g = 190,
    fill_b = 45,
    fill_a = 255,
    shader_speed = 19.0,

    -- Solid-color delayed XP gain layer. It reaches the live XP
    -- value immediately, then the normal gold fill catches up after a pause.
    delay_fill_enabled = true,
    delay_fill_r = 255,
    delay_fill_g = 244,
    delay_fill_b = 188,
    delay_fill_a = 235,
    delay_fill_wait = 0.65,
    delay_fill_catchup_speed = 0.55,
    delay_fill_min_visible = 0.0025,
    delay_fill_ratio = 0.0,
    delay_fill_target_ratio = 0.0,
    delay_fill_last_live_ratio = nil,
    delay_fill_last_level = nil,
    delay_fill_change_time = 0.0,
    delay_fill_last_update_time = 0.0,

    -- One-pixel border around the complete XP track.
    border_enabled = true,
    border_r = 255,
    border_g = 255,
    border_b = 255,
    border_a = 100,
    border_width = 0.10,

    -- White foggy background falloff from both bordered edges toward the center.
    highlight_enabled = true,
    highlight_r = 255,
    highlight_g = 255,
    highlight_b = 255,
    highlight_a = 100,
    highlight_width = 1.0,
    highlight_blur_radius = 2.5,
    highlight_blur_samples = 12,
    highlight_end_fade_degrees = 0.0,
    highlight_blur_alpha = 0.18,

    -- Independent current-XP endpoint cap controls.
    cap_enabled = true,
    cap_r = 255,
    cap_g = 255,
    cap_b = 255,
    cap_a = 255,
    cap_width = 1.0,
    cap_extension = 0.0,
    cap_radial_offset = 0.0,

    -- Level-up threshold marker at the end of the full XP track.
    threshold_enabled = true,
    threshold_r = 255,
    threshold_g = 255,
    threshold_b = 255,
    threshold_a = 255,
    threshold_width = 1.0,
    threshold_extension = 2.0,
    threshold_radial_offset = 0.0,

    live_level = 1,
    live_current_xp = 0,
    live_required_xp = 100,
    live_levels_gained = 0,
    live_source_status = "Waiting for RPG profile.",

    last_ratio = 0.0,
    last_error = "",
    draw_calls = 0,
    status = "XP ring loaded; enabled by default."
}

return state
