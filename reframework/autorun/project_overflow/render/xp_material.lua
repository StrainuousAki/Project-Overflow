------------------------------------------------------------
-- Maintenance classification — Build 49.39
-- Module: autorun/project_overflow/render/xp_material.lua
-- Role: HUD, XP, material, geometry, or rendering implementation.
-- Status: active renderer.
--
-- Compatibility policy:
--   Existing functions, hooks, module paths, and diagnostics are
--   intentionally retained in this maintenance pass.
--   `DEPRECATED` marks a supported legacy path, not removed code.
------------------------------------------------------------

------------------------------------------------------------
-- Project: Overflow — XP Material
--
-- Shared procedural timing and color sampling for the inventory
-- progression bar and the in-game XP ring. REFramework's software
-- draw API cannot bind the native GUI material directly, so both
-- surfaces use the same animated fog clock and palette.
------------------------------------------------------------

local material = {}

local function clamp01(value)
    value = tonumber(value) or 0.0
    return math.max(0.0, math.min(value, 1.0))
end

local function byte(value)
    return math.max(0, math.min(math.floor((tonumber(value) or 0) + 0.5), 255))
end

local function pack_abgr(r, g, b, a)
    return byte(a) * 0x1000000 + byte(b) * 0x10000 + byte(g) * 0x100 + byte(r)
end

function material.phase()
    -- Keep the exact clock used by the progression-menu XP bar.
    return os.clock() * 19.0
end

function material.sample(progress, phase, alpha)
    progress = clamp01(progress)
    phase = tonumber(phase) or material.phase()
    alpha = clamp01(alpha == nil and 1.0 or alpha)

    -- Several non-integer frequencies prevent a short, obvious loop and
    -- reproduce the drifting layered-fog character of the menu XP fill.
    local broad = 0.5 + 0.5 * math.sin(phase * 0.071 + progress * 9.7)
    local medium = 0.5 + 0.5 * math.sin(phase * 0.113 - progress * 17.3 + 1.8)
    local fine = 0.5 + 0.5 * math.sin(phase * 0.173 + progress * 31.1 + 4.2)
    local fog = clamp01(broad * 0.48 + medium * 0.34 + fine * 0.18)

    -- ABGR palette matching the purple progression bar.
    local r = 118 + 92 * fog
    local g = 36 + 48 * fog
    local b = 188 + 67 * fog
    local a = 215 + 40 * fog

    return pack_abgr(r, g, b, a * alpha)
end

function material.base_color(alpha)
    alpha = clamp01(alpha == nil and 1.0 or alpha)
    return pack_abgr(126, 43, 213, 235 * alpha)
end

function material.edge_color(alpha)
    alpha = clamp01(alpha == nil and 1.0 or alpha)
    return pack_abgr(207, 133, 255, 255 * alpha)
end

return material
