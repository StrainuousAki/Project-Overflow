------------------------------------------------------------
-- Maintenance classification — Build 49.39
-- Module: autorun/project_overflow/systems/player/stats.lua
-- Role: Player RPG profile, attributes, saves, experience, and stat application.
-- Status: active subsystem.
--
-- Compatibility policy:
--   Existing functions, hooks, module paths, and diagnostics are
--   intentionally retained in this maintenance pass.
--   `DEPRECATED` marks a supported legacy path, not removed code.
------------------------------------------------------------

------------------------------------------------------------
-- Project: Overflow — Derived Stats
--
-- Converts player attributes into gameplay values. The formulas
-- live here so balancing changes do not require editing save data.
------------------------------------------------------------

local stats = {}

local ATTRIBUTE_MIN = 1
local ATTRIBUTE_MAX = 250

local BALANCE = {
    vitality_hp_per_point = 20,
    strength_damage_per_point = 0.005,
    dexterity_speed_per_point = 0.005,
    dexterity_fire_rate_first_point = 0.002,
    dexterity_fire_rate_per_later_point = 0.001,
    agility_movement_per_point = 0.001,
    agility_reload_first_point = 0.002,
    agility_reload_per_later_point = 0.001,
    intelligence_healing_per_point = 0.005,
    luck_critical_per_point = 0.005,
    luck_critical_damage_per_point = 0.001
}

local function attribute_value(value)
    return math.max(
        ATTRIBUTE_MIN,
        math.min(ATTRIBUTE_MAX, math.floor(tonumber(value) or ATTRIBUTE_MIN))
    )
end

local function invested_points(value)
    -- Attribute value 1 is the unmodified baseline.
    return math.max(0, attribute_value(value) - ATTRIBUTE_MIN)
end

local function first_point_bonus(
    points,
    first_point,
    later_point
)
    if points <= 0 then
        return 0.0
    end

    return first_point
        + math.max(0, points - 1) * later_point
end

function stats.calculate(profile)
    local attributes =
        type(profile) == "table" and profile.attributes or {}

    local strength = attribute_value(attributes.strength)
    local vitality = attribute_value(attributes.vitality)
    local dexterity = attribute_value(attributes.dexterity)
    local agility = attribute_value(attributes.agility)
    local intelligence = attribute_value(attributes.intelligence)
    local luck = attribute_value(attributes.luck)

    local strength_points = invested_points(strength)
    local vitality_points = invested_points(vitality)
    local dexterity_points = invested_points(dexterity)
    local agility_points = invested_points(agility)
    local intelligence_points = invested_points(intelligence)
    local luck_points = invested_points(luck)

    return {
        max_hp_bonus =
            vitality_points *
            BALANCE.vitality_hp_per_point,

        weapon_damage_multiplier =
            1.0 +
            strength_points *
            BALANCE.strength_damage_per_point,

        action_speed_multiplier =
            math.min(
                1.50,
                1.0 +
                dexterity_points *
                BALANCE.dexterity_speed_per_point
            ),

        movement_speed_multiplier =
            math.min(
                1.20,
                1.0 +
                agility_points *
                BALANCE.agility_movement_per_point
            ),

        fire_rate_multiplier =
            math.min(
                1.25,
                1.0 +
                first_point_bonus(
                    dexterity_points,
                    BALANCE.dexterity_fire_rate_first_point,
                    BALANCE.dexterity_fire_rate_per_later_point
                )
            ),

        reload_speed_multiplier =
            math.min(
                1.25,
                1.0 +
                first_point_bonus(
                    agility_points,
                    BALANCE.agility_reload_first_point,
                    BALANCE.agility_reload_per_later_point
                )
            ),

        healing_multiplier =
            math.min(
                1.50,
                1.0 +
                intelligence_points *
                BALANCE.intelligence_healing_per_point
            ),

        critical_chance =
            math.min(
                0.50,
                luck_points *
                BALANCE.luck_critical_per_point
            ),

        critical_damage_bonus =
            luck >= ATTRIBUTE_MAX and 0.25 or
            math.min(
                0.25,
                luck_points * BALANCE.luck_critical_damage_per_point
            )
    }
end

function stats.balance()
    return BALANCE
end

function stats.attribute_min()
    return ATTRIBUTE_MIN
end

function stats.attribute_max()
    return ATTRIBUTE_MAX
end

return stats
