------------------------------------------------------------
-- Maintenance classification — Build 49.39
-- Module: autorun/project_overflow/xp/geometry.lua
-- Role: HUD, XP, material, geometry, or rendering implementation.
-- Status: active renderer.
--
-- Compatibility policy:
--   Existing functions, hooks, module paths, and diagnostics are
--   intentionally retained in this maintenance pass.
--   `DEPRECATED` marks a supported legacy path, not removed code.
------------------------------------------------------------

------------------------------------------------------------
-- Project: Overflow — xp/geometry.lua
-- XP-ring state, geometry, visibility, material, and rendering.
------------------------------------------------------------

local geometry = {}

local function finite(value, fallback)
    value = tonumber(value)
    if value == nil or value ~= value then return fallback end
    if value > 1000000.0 or value < -1000000.0 then return fallback end
    return value
end

function geometry.resolve(ctx, state)
    local reference_width = finite(ctx.state.overlay_reference_width, 2560.0)
    local reference_height = finite(ctx.state.overlay_reference_height, 1440.0)
    local screen_width = finite(ctx.screen.width, reference_width)
    local screen_height = finite(ctx.screen.height, reference_height)
    local uniform_scale = math.min(screen_width / reference_width,
        screen_height / reference_height)

    local reference_x = finite(ctx.state.overlay_reference_x, 2283.3)
    local reference_y = finite(ctx.state.overlay_reference_y, 1164.6)
    local hp_radius = math.max(1.0,
        finite(ctx.state.overlay_reference_radius, 84.2) * uniform_scale)
    local hp_thickness = math.max(1.0,
        finite(ctx.state.overlay_thickness, 10.0) * uniform_scale)

    local center_x = screen_width - ((reference_width - reference_x) * uniform_scale)
    local center_y = screen_height - ((reference_height - reference_y) * uniform_scale)
    local xp_thickness = math.max(1.0,
        hp_thickness * math.max(0.05, finite(state.thickness_ratio, 0.50)))
    local gap = math.max(0.0, finite(state.gap, 2.0) * uniform_scale)

    return {
        center_x = center_x,
        center_y = center_y,
        radius = hp_radius + hp_thickness + gap,
        thickness = xp_thickness,
        start_angle = finite(state.start_angle,
            finite(ctx.state.overlay_start_angle, 135.0)),
        direction = finite(state.direction,
            finite(ctx.state.overlay_direction, 1.0)) < 0.0 and -1.0 or 1.0,
        max_sweep = math.max(1.0, math.min(270.0,
            math.abs(finite(state.max_sweep, 135.0)))),
        segments = math.max(8, math.min(96,
            math.floor(finite(state.segments, 48)))),
        scale = uniform_scale
    }
end

return geometry
