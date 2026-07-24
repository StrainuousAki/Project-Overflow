------------------------------------------------------------
-- Maintenance classification — Build 49.39
-- Module: autorun/project_overflow/render/xp_ring.lua
-- Role: HUD, XP, material, geometry, or rendering implementation.
-- Status: active renderer.
--
-- Compatibility policy:
--   Existing functions, hooks, module paths, and diagnostics are
--   intentionally retained in this maintenance pass.
--   `DEPRECATED` marks a supported legacy path, not removed code.
------------------------------------------------------------

------------------------------------------------------------
-- Project: Overflow — Native HUD XP Ring
--
-- Independent outer-radius XP render pass. Geometry is derived from
-- the resolved HP ring so resolution scaling and orientation remain
-- identical without sharing mutable health-render state.
------------------------------------------------------------

local xp_ring = {}
local ring = require("project_overflow.render.ring")
local rpg = require("project_overflow.systems.player.rpg")
local material = require("project_overflow.render.xp_material")

local function clamp01(value)
    value = tonumber(value) or 0.0
    return math.max(0.0, math.min(value, 1.0))
end

local function clamp(value, minimum, maximum)
    value = tonumber(value) or minimum
    return math.max(minimum, math.min(value, maximum))
end

local function pack_abgr(r, g, b, a)
    local function byte(value)
        return math.max(0, math.min(math.floor((tonumber(value) or 0) + 0.5), 255))
    end
    return byte(a) * 0x1000000 + byte(b) * 0x10000 + byte(g) * 0x100 + byte(r)
end

function xp_ring.draw(ctx, geometry)
    if ctx.state.xp_ring_enabled ~= true then return end
    if draw == nil or type(geometry) ~= "table" then return end

    local ratio = clamp01(rpg.progress_ratio())
    if ctx.state.xp_ring_hide_at_zero == true and ratio <= 0.0 then
        ctx.state.xp_ring_last_drawn = false
        return
    end

    local hp_radius = math.max(1.0, tonumber(geometry.radius) or 1.0)
    local hp_thickness = math.max(1.0, tonumber(geometry.thickness) or 1.0)
    local scale = math.max(0.001, tonumber(geometry.scale) or 1.0)
    local thickness_ratio = clamp(ctx.state.xp_ring_thickness_ratio, 0.10, 1.0)
    local thickness = math.max(1.0, hp_thickness * thickness_ratio)
    local gap = math.max(0.0, (tonumber(ctx.state.xp_ring_gap) or 2.0) * scale)

    -- ring.draw_arc treats radius as the inner edge and grows outward.
    local radius = hp_radius + hp_thickness + gap
    local start_angle = (tonumber(geometry.start_angle) or 135.0) +
        (tonumber(ctx.state.xp_ring_start_offset) or 0.0)
    local direction = tonumber(geometry.direction) or 1.0
    direction = direction < 0.0 and -1.0 or 1.0
    local max_sweep = clamp(ctx.state.xp_ring_max_sweep, 1.0, 270.0)
    local background_sweep = max_sweep * direction
    local foreground_sweep = max_sweep * ratio * direction
    local segments = math.max(8, math.floor(tonumber(ctx.state.xp_ring_segments) or
        tonumber(geometry.segments) or 48))
    local alpha = clamp01(ctx.state.xp_ring_alpha == nil and 1.0 or
        ctx.state.xp_ring_alpha)

    local background_color = pack_abgr(
        ctx.state.xp_ring_bg_r or 18,
        ctx.state.xp_ring_bg_g or 18,
        ctx.state.xp_ring_bg_b or 20,
        (ctx.state.xp_ring_bg_a or 132) * alpha
    )
    local inner_glow_color = pack_abgr(
        ctx.state.xp_ring_inner_glow_r or 170,
        ctx.state.xp_ring_inner_glow_g or 154,
        ctx.state.xp_ring_inner_glow_b or 196,
        (ctx.state.xp_ring_inner_glow_a or 92) * alpha
    )

    -- Native-style track: dark body plus a restrained glow on the inner edge.
    ring.draw_arc(
        geometry.cx, geometry.cy, radius, thickness,
        start_angle, background_sweep, background_color, segments
    )
    ring.draw_arc(
        geometry.cx, geometry.cy, radius, math.max(1.0, thickness * 0.24),
        start_angle, background_sweep, inner_glow_color, segments
    )

    if math.abs(foreground_sweep) > 0.001 then
        local phase = material.phase()
        ring.draw_arc_material(
            geometry.cx, geometry.cy, radius, thickness,
            start_angle, foreground_sweep, segments,
            function(progress, radial_progress)
                -- Brighter inner rim, with the same animated fog field used by
                -- the progression-menu XP material.
                local radial_light = 1.0 - radial_progress
                local sampled_alpha = alpha * (0.84 + radial_light * 0.16)
                return material.sample(progress, phase, sampled_alpha)
            end
        )

        -- Fine highlight on the inner edge keeps the fill readable against
        -- the native-style dark track.
        ring.draw_arc(
            geometry.cx, geometry.cy, radius, 1.0,
            start_angle, foreground_sweep,
            material.edge_color(alpha * 0.92), segments
        )

        if ctx.state.xp_ring_cap_enabled ~= false then
            local centered_radius = radius + ((thickness - 1.0) * 0.5)
            -- Existing cap width_scale controls radial height. length_scale
            -- controls tangent width, so 1 / thickness produces exactly 1 px.
            ring.draw_flat_cap(
                geometry.cx,
                geometry.cy,
                centered_radius,
                thickness,
                start_angle + foreground_sweep,
                0xFFFFFFFF,
                1.0 / math.max(1.0, thickness),
                1.0
            )
        end
    end

    ctx.state.xp_ring_ratio = ratio
    ctx.state.xp_ring_radius = radius
    ctx.state.xp_ring_thickness = thickness
    ctx.state.xp_ring_foreground_sweep = foreground_sweep
    ctx.state.xp_ring_last_drawn = true
end

return xp_ring
