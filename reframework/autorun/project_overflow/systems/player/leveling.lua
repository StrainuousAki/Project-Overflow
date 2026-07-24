------------------------------------------------------------
-- Maintenance classification — Build 49.39
-- Module: autorun/project_overflow/systems/player/leveling.lua
-- Role: Player RPG profile, attributes, saves, experience, and stat application.
-- Status: active subsystem.
--
-- Compatibility policy:
--   Existing functions, hooks, module paths, and diagnostics are
--   intentionally retained in this maintenance pass.
--   `DEPRECATED` marks a supported legacy path, not removed code.
------------------------------------------------------------

------------------------------------------------------------
-- Project: Overflow — Leveling
--
-- Converts accumulated XP into levels and grants the rewards for
-- each level. A loop allows one large XP reward to grant several.
------------------------------------------------------------

local experience = require("project_overflow.systems.player.experience")

local leveling = {}

local ATTRIBUTE_POINTS_PER_LEVEL = 3
local SKILL_POINTS_PER_LEVEL = 1

function leveling.process(profile)
    if type(profile) ~= "table" then
        return 0
    end

    local levels_gained = 0

    while true do
        local required =
            experience.required_for_level(profile.level)

        if (tonumber(profile.experience) or 0) < required then
            break
        end

        profile.experience = profile.experience - required
        profile.level = (tonumber(profile.level) or 1) + 1
        profile.attribute_points =
            (tonumber(profile.attribute_points) or 0) +
            ATTRIBUTE_POINTS_PER_LEVEL
        profile.skill_points =
            (tonumber(profile.skill_points) or 0) +
            SKILL_POINTS_PER_LEVEL

        levels_gained = levels_gained + 1
    end

    return levels_gained
end

function leveling.force_level(profile)
    if type(profile) ~= "table" then
        return 0
    end

    local required =
        experience.required_for_level(profile.level)

    profile.experience = required

    return leveling.process(profile)
end

return leveling
