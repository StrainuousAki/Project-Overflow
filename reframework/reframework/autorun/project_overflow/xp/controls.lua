------------------------------------------------------------
-- Maintenance classification — Build 49.39
-- Module: autorun/project_overflow/xp/controls.lua
-- Role: HUD, XP, material, geometry, or rendering implementation.
-- Status: active renderer.
--
-- Compatibility policy:
--   Existing functions, hooks, module paths, and diagnostics are
--   intentionally retained in this maintenance pass.
--   `DEPRECATED` marks a supported legacy path, not removed code.
------------------------------------------------------------

------------------------------------------------------------
-- Project: Overflow — xp/controls.lua
-- XP-ring state, geometry, visibility, material, and rendering.
------------------------------------------------------------

local controls = {}
local state = require("project_overflow.xp.state")

local function value(label, current)
    imgui.text(
        label
            .. " : "
            .. tostring(current)
    )
end

function controls.draw()
    if imgui == nil
        or imgui.tree_node == nil
    then
        return
    end

    if not imgui.tree_node(
        "XP Ring"
    )
    then
        return
    end

    local changed

    changed,
    state.enabled =
        imgui.checkbox(
            "Enable XP Ring",
            state.enabled == true
        )

    changed,
    state.preview_enabled =
        imgui.checkbox(
            "Preview XP Ring (65% Test Override)",
            state.preview_enabled == true
        )

    changed,
    state.follow_native_hp_visibility =
        imgui.checkbox(
            "Follow Native HP Visibility",
            state.follow_native_hp_visibility == true
        )

    imgui.separator()
    imgui.text("Geometry")

    changed,
    state.max_sweep =
        imgui.drag_float(
            "Maximum Sweep",
            state.max_sweep,
            1.0,
            45.0,
            270.0
        )

    changed,
    state.start_angle =
        imgui.drag_float(
            "Start Angle",
            state.start_angle,
            1.0,
            -360.0,
            360.0
        )

    changed,
    state.gap =
        imgui.drag_float(
            "Outer Gap",
            state.gap,
            0.1,
            0.0,
            30.0
        )

    changed,
    state.thickness_ratio =
        imgui.drag_float(
            "HP Thickness Ratio",
            state.thickness_ratio,
            0.01,
            0.1,
            1.0
        )

    changed,
    state.segments =
        imgui.drag_int(
            "Segments",
            state.segments,
            1,
            8,
            96
        )

    imgui.separator()
    imgui.text("Gold Track and Fill")

    changed,
    state.background_a =
        imgui.drag_int(
            "Background Alpha",
            state.background_a,
            1,
            0,
            255
        )

    changed,
    state.fill_a =
        imgui.drag_int(
            "Fill Alpha",
            state.fill_a,
            1,
            0,
            255
        )

    changed,
    state.shader_speed =
        imgui.drag_float(
            "Gold Fog Speed",
            state.shader_speed,
            0.25,
            0.0,
            60.0
        )

    imgui.separator()
    imgui.text("Solid XP Gain Fill")

    changed,
    state.delay_fill_enabled =
        imgui.checkbox(
            "Enable XP Delay Fill",
            state.delay_fill_enabled == true
        )

    changed,
    state.delay_fill_wait =
        imgui.drag_float(
            "Delay Before Catch-Up",
            state.delay_fill_wait,
            0.05,
            0.0,
            5.0
        )

    changed,
    state.delay_fill_catchup_speed =
        imgui.drag_float(
            "Catch-Up Speed (Ratio/sec)",
            state.delay_fill_catchup_speed,
            0.05,
            0.05,
            5.0
        )

    changed,
    state.delay_fill_min_visible =
        imgui.drag_float(
            "Minimum Visible Ratio",
            state.delay_fill_min_visible,
            0.0005,
            0.0,
            0.05
        )

    changed,
    state.delay_fill_a =
        imgui.drag_int(
            "Delay Fill Alpha",
            state.delay_fill_a,
            1,
            0,
            255
        )

    changed,
    state.delay_fill_r =
        imgui.drag_int(
            "Delay Fill Red",
            state.delay_fill_r,
            1,
            0,
            255
        )

    changed,
    state.delay_fill_g =
        imgui.drag_int(
            "Delay Fill Green",
            state.delay_fill_g,
            1,
            0,
            255
        )

    changed,
    state.delay_fill_b =
        imgui.drag_int(
            "Delay Fill Blue",
            state.delay_fill_b,
            1,
            0,
            255
        )

    imgui.separator()
    imgui.text("Track Border")

    changed,
    state.border_enabled =
        imgui.checkbox(
            "Enable 1px Border",
            state.border_enabled == true
        )

    changed,
    state.border_width =
        imgui.drag_float(
            "Border Width",
            state.border_width,
            0.1,
            0.5,
            4.0
        )

    changed,
    state.border_a =
        imgui.drag_int(
            "Border Alpha",
            state.border_a,
            1,
            0,
            255
        )

    changed,
    state.border_r =
        imgui.drag_int(
            "Border Red",
            state.border_r,
            1,
            0,
            255
        )

    changed,
    state.border_g =
        imgui.drag_int(
            "Border Green",
            state.border_g,
            1,
            0,
            255
        )

    changed,
    state.border_b =
        imgui.drag_int(
            "Border Blue",
            state.border_b,
            1,
            0,
            255
        )

    imgui.separator()
    imgui.text("Background Two-Sided Edge Blur")

    changed,
    state.highlight_enabled =
        imgui.checkbox(
            "Enable Background Edge Blur",
            state.highlight_enabled == true
        )

    changed,
    state.highlight_width =
        imgui.drag_float(
            "Edge Source Width",
            state.highlight_width,
            0.1,
            0.5,
            6.0
        )

    changed,
    state.highlight_blur_radius =
        imgui.drag_float(
            "Inward Blur Depth",
            state.highlight_blur_radius,
            0.1,
            0.0,
            8.0
        )

    changed,
    state.highlight_blur_samples =
        imgui.drag_int(
            "Inward Blur Samples",
            state.highlight_blur_samples,
            1,
            1,
            12
        )

    changed,
    state.highlight_blur_alpha =
        imgui.drag_float(
            "Edge Blur Strength",
            state.highlight_blur_alpha,
            0.01,
            0.0,
            1.0
        )

    changed,
    state.highlight_end_fade_degrees =
        imgui.drag_float(
            "Blur End Fade Degrees",
            state.highlight_end_fade_degrees,
            0.25,
            0.0,
            20.0
        )

    changed,
    state.highlight_a =
        imgui.drag_int(
            "Edge Highlight Alpha",
            state.highlight_a,
            1,
            0,
            255
        )

    imgui.separator()
    imgui.text("Current XP End Cap")

    changed,
    state.cap_enabled =
        imgui.checkbox(
            "Enable End Cap",
            state.cap_enabled == true
        )

    changed,
    state.cap_width =
        imgui.drag_float(
            "End Cap Tangent Width",
            state.cap_width,
            0.1,
            0.5,
            12.0
        )

    changed,
    state.cap_extension =
        imgui.drag_float(
            "End Cap Radial Extension",
            state.cap_extension,
            0.1,
            0.0,
            12.0
        )

    changed,
    state.cap_radial_offset =
        imgui.drag_float(
            "End Cap Radial Offset",
            state.cap_radial_offset,
            0.1,
            -12.0,
            12.0
        )

    changed,
    state.cap_r =
        imgui.drag_int(
            "End Cap Red",
            state.cap_r,
            1,
            0,
            255
        )

    changed,
    state.cap_g =
        imgui.drag_int(
            "End Cap Green",
            state.cap_g,
            1,
            0,
            255
        )

    changed,
    state.cap_b =
        imgui.drag_int(
            "End Cap Blue",
            state.cap_b,
            1,
            0,
            255
        )

    changed,
    state.cap_a =
        imgui.drag_int(
            "End Cap Alpha",
            state.cap_a,
            1,
            0,
            255
        )

    imgui.separator()
    imgui.text("Level-Up Threshold")

    changed,
    state.threshold_enabled =
        imgui.checkbox(
            "Enable Level-Up Threshold",
            state.threshold_enabled == true
        )

    changed,
    state.threshold_width =
        imgui.drag_float(
            "Threshold Tangent Width",
            state.threshold_width,
            0.1,
            0.5,
            8.0
        )

    changed,
    state.threshold_extension =
        imgui.drag_float(
            "Threshold Radial Extension",
            state.threshold_extension,
            0.1,
            0.0,
            12.0
        )

    changed,
    state.threshold_radial_offset =
        imgui.drag_float(
            "Threshold Radial Offset",
            state.threshold_radial_offset,
            0.1,
            -12.0,
            12.0
        )

    changed,
    state.threshold_a =
        imgui.drag_int(
            "Threshold Alpha",
            state.threshold_a,
            1,
            0,
            255
        )

    imgui.separator()

    value(
        "Data Source",
        state.preview_enabled == true
            and "Preview override"
            or state.live_source_status
    )

    value(
        "Live Level",
        state.live_level
    )

    value(
        "Live XP",
        tostring(state.live_current_xp)
            .. " / "
            .. tostring(state.live_required_xp)
    )

    value(
        "Last Levels Gained",
        state.live_levels_gained
    )

    value(
        "XP Ratio",
        string.format(
            "%.4f",
            tonumber(state.last_ratio) or 0.0
        )
    )

    value(
        "Displayed Gold Ratio",
        string.format(
            "%.4f",
            tonumber(state.delay_fill_ratio) or 0.0
        )
    )

    value(
        "Delayed Fill Ratio",
        string.format(
            "%.4f",
            math.max(
                0.0,
                (tonumber(state.last_ratio) or 0.0)
                    - (tonumber(state.delay_fill_ratio) or 0.0)
            )
        )
    )

    value(
        "Draw Frames",
        state.draw_calls
    )

    value(
        "Status",
        state.status
    )

    value(
        "Last Error",
        state.last_error ~= ""
            and state.last_error
            or "none"
    )

    imgui.tree_pop()
end

return controls
