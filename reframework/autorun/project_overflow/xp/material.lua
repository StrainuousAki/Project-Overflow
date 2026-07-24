------------------------------------------------------------
-- Maintenance classification — Build 49.39
-- Module: autorun/project_overflow/xp/material.lua
-- Role: HUD, XP, material, geometry, or rendering implementation.
-- Status: active renderer.
--
-- Compatibility policy:
--   Existing functions, hooks, module paths, and diagnostics are
--   intentionally retained in this maintenance pass.
--   `DEPRECATED` marks a supported legacy path, not removed code.
------------------------------------------------------------

------------------------------------------------------------
-- Project: Overflow — xp/material.lua
-- XP-ring state, geometry, visibility, material, and rendering.
------------------------------------------------------------

local material = {}

local function clamp_byte(value)
    return math.max(
        0,
        math.min(
            255,
            math.floor(
                tonumber(value) or 0
            )
        )
    )
end

local function clamp01(value)
    return math.max(
        0.0,
        math.min(
            1.0,
            tonumber(value) or 0.0
        )
    )
end

function material.pack(r, g, b, a)
    return clamp_byte(a) * 0x1000000
        + clamp_byte(b) * 0x10000
        + clamp_byte(g) * 0x100
        + clamp_byte(r)
end

local function fog_sample(
    progress,
    phase
)
    local wave_a =
        0.5
        + 0.5
        * math.sin(
            phase * 0.31
            + progress * 18.0
        )

    local wave_b =
        0.5
        + 0.5
        * math.sin(
            phase * 0.17
            - progress * 29.0
            + 1.7
        )

    local wave_c =
        0.5
        + 0.5
        * math.sin(
            phase * 0.09
            + progress * 47.0
            + 4.1
        )

    return clamp01(
        wave_a * 0.45
        + wave_b * 0.35
        + wave_c * 0.20
    )
end

function material.background_color(
    state,
    progress,
    phase,
    alpha
)
    local fog =
        fog_sample(
            progress,
            phase * 0.22
        )

    local brightness =
        0.72
        + fog * 0.12

    return material.pack(
        (tonumber(state.background_r) or 83)
            * brightness,
        (tonumber(state.background_g) or 62)
            * brightness,
        (tonumber(state.background_b) or 10)
            * brightness,
        (tonumber(state.background_a) or 165)
            * (tonumber(alpha) or 1.0)
    )
end

function material.fill_color(
    state,
    progress,
    phase,
    alpha
)
    local fog =
        fog_sample(
            progress,
            phase
        )

    local brightness =
        0.62
        + fog * 0.52

    return material.pack(
        (tonumber(state.fill_r) or 238)
            * brightness,
        (tonumber(state.fill_g) or 190)
            * brightness,
        (tonumber(state.fill_b) or 45)
            * brightness,
        (tonumber(state.fill_a) or 235)
            * (tonumber(alpha) or 1.0)
    )
end

function material.delay_fill_color(
    state,
    progress,
    phase,
    alpha
)
    -- The delayed XP segment intentionally uses a raw color. Progress and
    -- phase remain in the signature so the renderer can share one material
    -- callback shape without special-case draw code.
    return material.pack(
        tonumber(state.delay_fill_r) or 255,
        tonumber(state.delay_fill_g) or 244,
        tonumber(state.delay_fill_b) or 188,
        (tonumber(state.delay_fill_a) or 235)
            * (tonumber(alpha) or 1.0)
    )
end

function material.highlight_color(
    state,
    progress,
    phase,
    alpha,
    opacity_scale,
    edge_kind
)
    local fog =
        fog_sample(
            progress,
            phase * 1.18
        )

    opacity_scale =
        tonumber(opacity_scale) or 1.0

    local edge_scale = 1.0

    local opacity =
        (0.42 + fog * 0.58)
        * (tonumber(state.highlight_a) or 220)
        * (tonumber(alpha) or 1.0)
        * opacity_scale
        * edge_scale

    local brightness =
        0.84 + fog * 0.16

    return material.pack(
        (tonumber(state.highlight_r) or 255)
            * brightness,
        (tonumber(state.highlight_g) or 255)
            * brightness,
        (tonumber(state.highlight_b) or 255)
            * brightness,
        opacity
    )
end

function material.border_color(state, alpha)
    return material.pack(
        state.border_r,
        state.border_g,
        state.border_b,
        (tonumber(state.border_a) or 245)
            * (tonumber(alpha) or 1.0)
    )
end

function material.threshold_color(state, alpha)
    return material.pack(
        state.threshold_r,
        state.threshold_g,
        state.threshold_b,
        (tonumber(state.threshold_a) or 245)
            * (tonumber(alpha) or 1.0)
    )
end

function material.cap_color(
    state,
    alpha
)
    return material.pack(
        state.cap_r,
        state.cap_g,
        state.cap_b,
        (tonumber(state.cap_a) or 240)
            * (tonumber(alpha) or 1.0)
    )
end

return material
