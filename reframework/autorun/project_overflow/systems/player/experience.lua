------------------------------------------------------------
-- Maintenance classification — Build 49.39
-- Module: autorun/project_overflow/systems/player/experience.lua
-- Role: Player RPG profile, attributes, saves, experience, and stat application.
-- Status: active subsystem.
--
-- Compatibility policy:
--   Existing functions, hooks, module paths, and diagnostics are
--   intentionally retained in this maintenance pass.
--   `DEPRECATED` marks a supported legacy path, not removed code.
------------------------------------------------------------

------------------------------------------------------------
-- Project: Overflow — Experience
--
-- Defines the XP curve and small helpers used by leveling and UI.
------------------------------------------------------------

local experience = {}

local BASE_XP = 100
local GROWTH = 1.35

function experience.required_for_level(level)
    level = math.max(1, math.floor(tonumber(level) or 1))

    return math.floor(
        BASE_XP *
        (level ^ GROWTH)
    )
end

function experience.progress_ratio(profile)
    if type(profile) ~= "table" then
        return 0.0
    end

    local required =
        experience.required_for_level(profile.level)

    if required <= 0 then
        return 0.0
    end

    return math.max(
        0.0,
        math.min(
            (tonumber(profile.experience) or 0) / required,
            1.0
        )
    )
end

function experience.add(profile, amount)
    if type(profile) ~= "table" then
        return 0
    end

    amount = math.max(0, math.floor(tonumber(amount) or 0))
    profile.experience = (tonumber(profile.experience) or 0) + amount

    return amount
end

return experience
