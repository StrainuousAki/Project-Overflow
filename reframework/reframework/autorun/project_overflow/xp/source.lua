------------------------------------------------------------
-- Maintenance classification — Build 49.39
-- Module: autorun/project_overflow/xp/source.lua
-- Role: HUD, XP, material, geometry, or rendering implementation.
-- Status: active renderer.
--
-- Compatibility policy:
--   Existing functions, hooks, module paths, and diagnostics are
--   intentionally retained in this maintenance pass.
--   `DEPRECATED` marks a supported legacy path, not removed code.
------------------------------------------------------------

------------------------------------------------------------
-- Project: Overflow — XP Ring Live Source
--
-- Adapts the standalone RPG progression modules to the HUD
-- renderer. It owns no XP and performs no leveling itself.
------------------------------------------------------------

local rpg =
    require("project_overflow.systems.player.rpg")

local source = {
    last_level = nil,
    last_experience = nil,
    last_required = nil,
    last_levels_gained = 0,
    status = "Waiting for RPG profile."
}

local function clamp01(value)
    return math.max(
        0.0,
        math.min(
            1.0,
            tonumber(value) or 0.0
        )
    )
end

function source.snapshot()
    local profile =
        rpg.profile()

    if type(profile) ~= "table" then
        source.status =
            "RPG profile unavailable."

        return {
            level = 1,
            current_xp = 0,
            required_xp = 100,
            ratio = 0.0,
            levels_gained = 0,
            status = source.status
        }
    end

    local level =
        math.max(
            1,
            math.floor(
                tonumber(profile.level) or 1
            )
        )

    local current_xp =
        math.max(
            0,
            math.floor(
                tonumber(profile.experience) or 0
            )
        )

    local required_xp =
        math.max(
            1,
            math.floor(
                tonumber(rpg.required_xp()) or 1
            )
        )

    local ratio =
        clamp01(
            current_xp / required_xp
        )

    local levels_gained =
        math.max(
            0,
            math.floor(
                tonumber(rpg.last_levels_gained) or 0
            )
        )

    source.last_level =
        level

    source.last_experience =
        current_xp

    source.last_required =
        required_xp

    source.last_levels_gained =
        levels_gained

    source.status =
        "Live RPG progression."

    return {
        level = level,
        current_xp = current_xp,
        required_xp = required_xp,
        ratio = ratio,
        levels_gained = levels_gained,
        status = source.status
    }
end

return source
