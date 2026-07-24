------------------------------------------------------------
-- Maintenance classification — Build 49.39
-- Module: autorun/project_overflow/ring.lua
-- Role: HUD, XP, material, geometry, or rendering implementation.
-- Status: active renderer.
--
-- Compatibility policy:
--   Existing functions, hooks, module paths, and diagnostics are
--   intentionally retained in this maintenance pass.
--   `DEPRECATED` marks a supported legacy path, not removed code.
------------------------------------------------------------

------------------------------------------------------------
-- Project: Overflow — ring.lua
-- Project: Overflow runtime module.
------------------------------------------------------------

local ring = {}

local function clamp_signed_sweep(sweep_deg)
    sweep_deg = tonumber(sweep_deg) or 0.0

    if sweep_deg < -360.0 then
        return -360.0
    end

    if sweep_deg > 360.0 then
        return 360.0
    end

    return sweep_deg
end

local function arc_point(cx, cy, radius, angle_deg)
    local angle_rad = math.rad(angle_deg)

    return
        cx + math.cos(angle_rad) * radius,
        cy + math.sin(angle_rad) * radius
end

local function draw_arc_line(
    cx,
    cy,
    radius,
    start_deg,
    sweep_deg,
    color,
    segments
)
    segments = math.max(4, math.floor(tonumber(segments) or 32))

    local start_rad = math.rad(start_deg)
    local sweep_rad = math.rad(sweep_deg)

    local last_x = nil
    local last_y = nil

    for index = 0, segments do
        local progress = index / segments
        local angle = start_rad + (sweep_rad * progress)

        local x = cx + math.cos(angle) * radius
        local y = cy + math.sin(angle) * radius

        if last_x ~= nil then
            draw.line(
                last_x,
                last_y,
                x,
                y,
                color
            )
        end

        last_x = x
        last_y = y
    end
end

local function arc_frame(cx, cy, radius, angle_deg)
    local angle = math.rad(angle_deg)

    local center_x = cx + math.cos(angle) * radius
    local center_y = cy + math.sin(angle) * radius

    -- Radial direction: outward from ring center.
    local radial_x = math.cos(angle)
    local radial_y = math.sin(angle)

    -- Tangent direction: follows the arc.
    local tangent_x = -math.sin(angle)
    local tangent_y = math.cos(angle)

    return center_x, center_y, radial_x, radial_y, tangent_x, tangent_y
end

function ring.draw_flat_cap(
    cx,
    cy,
    radius,
    thickness,
    angle_deg,
    color,
    length_scale,
    width_scale
)
    if draw == nil then return end

    length_scale = tonumber(length_scale) or 1.0
    width_scale = tonumber(width_scale) or 1.0

    local center_x,
          center_y,
          radial_x,
          radial_y,
          tangent_x,
          tangent_y =
        arc_frame(cx, cy, radius, angle_deg)

    local half_width =
        thickness * 0.5 * width_scale

    local half_length =
        thickness * 0.5 * length_scale

    local x1 =
        center_x - radial_x * half_width - tangent_x * half_length
    local y1 =
        center_y - radial_y * half_width - tangent_y * half_length

    local x2 =
        center_x + radial_x * half_width - tangent_x * half_length
    local y2 =
        center_y + radial_y * half_width - tangent_y * half_length

    local x3 =
        center_x + radial_x * half_width + tangent_x * half_length
    local y3 =
        center_y + radial_y * half_width + tangent_y * half_length

    local x4 =
        center_x - radial_x * half_width + tangent_x * half_length
    local y4 =
        center_y - radial_y * half_width + tangent_y * half_length

    draw.filled_quad(
        x1, y1,
        x2, y2,
        x3, y3,
        x4, y4,
        color
    )
end

function ring.draw_arc(
    cx,
    cy,
    radius,
    thickness,
    start_deg,
    sweep_deg,
    color,
    segments
)
    if draw == nil then return end

    radius = math.max(1.0, tonumber(radius) or 1.0)
    thickness = math.max(1, math.floor(tonumber(thickness) or 1))
    segments = math.max(4, math.floor(tonumber(segments) or 32))
    sweep_deg = clamp_signed_sweep(sweep_deg)

    if math.abs(sweep_deg) <= 0.001 then
        return
    end

    for offset = 0, thickness - 1 do
        draw_arc_line(
            cx,
            cy,
            radius + offset,
            start_deg,
            sweep_deg,
            color,
            segments
        )
    end
end

function ring.draw_cap(
    cx,
    cy,
    radius,
    thickness,
    angle_deg,
    color,
    scale
)
    if draw == nil then return end

    scale = tonumber(scale) or 1.0

    local x, y = arc_point(
        cx,
        cy,
        radius,
        angle_deg
    )

    local cap_radius = math.max(
        1.0,
        thickness * 0.5 * scale
    )

    draw.filled_circle(
        x,
        y,
        cap_radius,
        color,
        20
    )
end

function ring.draw_ring(
    ctx,
    cx,
    cy,
    radius,
    thickness,
    segments,
    start_deg,
    sweep_deg,
    bg_color,
    fg_color,
    draw_cap,
    cap_length,
    cap_width,
    cap_color
)
    radius = ctx.clamp(
        tonumber(radius) or 10.0,
        10.0,
        300.0
    )

    thickness = ctx.clamp(
        math.floor(tonumber(thickness) or 1),
        1,
        32
    )

    segments = ctx.clamp(
        math.floor(tonumber(segments) or 32),
        4,
        128
    )

    sweep_deg = clamp_signed_sweep(sweep_deg)
    cap_scale = tonumber(cap_scale) or 1.0

    local background_sweep =
        sweep_deg < 0.0 and -270.0 or 270.0

    -- Background track
    ring.draw_arc(
        cx,
        cy,
        radius,
        thickness,
        start_deg,
        background_sweep,
        bg_color,
        segments
    )

    -- Foreground health fill
    ring.draw_arc(
        cx,
        cy,
        radius,
        thickness,
        start_deg,
        sweep_deg,
        fg_color,
        segments
    )

    -- Foreground cap
        if draw_cap and math.abs(sweep_deg) > 0.001 then
        local centered_radius =
            radius + ((thickness - 1) * 0.5)

        ring.draw_flat_cap(
            cx,
            cy,
            centered_radius,
            thickness,
            start_deg + sweep_deg,
            cap_color,
            cap_length,
            cap_width
        )
    end
end

return ring