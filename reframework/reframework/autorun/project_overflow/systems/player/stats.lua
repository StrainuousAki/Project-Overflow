------------------------------------------------------------
-- Project: Overflow — Derived attribute balance
--
-- This module is the single source of truth for attribute scaling and its
-- runtime clamps. Debug controls may edit BALANCE during a session, while
-- DEFAULT_BALANCE preserves the shipped values for an immediate reset.
------------------------------------------------------------


local stats = {
    balance_path =
        "project_overflow/attribute_balance.json",
    balance_loaded = false,
    balance_status =
        "Attribute balance defaults active.",
    balance_save_count = 0,
    balance_load_count = 0
}

local ATTRIBUTE_MIN = 1
local ATTRIBUTE_MAX = 250

local DEFAULT_BALANCE = {
    vitality_hp_per_point = 20.000,
    strength_damage_per_point = 0.005,
    dexterity_speed_per_point = 0.005,
    dexterity_fire_rate_first_point = 0.002,
    dexterity_fire_rate_per_later_point = 0.001,
    agility_movement_per_point = 0.001,
    agility_reload_first_point = 0.002,
    agility_reload_per_later_point = 0.001,
    intelligence_healing_per_point = 0.005,
    luck_critical_per_point = 0.005,
    luck_critical_damage_per_point = 0.001,

    vitality_max_hp_bonus = 20160.000,
    strength_damage_max_multiplier = 2.500,
    dexterity_speed_max_multiplier = 1.500,
    agility_movement_max_multiplier = 1.200,
    dexterity_fire_rate_max_multiplier = 1.250,
    agility_reload_max_multiplier = 1.250,
    intelligence_healing_max_multiplier = 1.500,
    luck_critical_chance_max = 0.500,
    luck_critical_damage_max = 0.250
}

local BALANCE = {}

local function restore_default_balance()
    for key in pairs(BALANCE) do
        BALANCE[key] = nil
    end

    for key, value in pairs(DEFAULT_BALANCE) do
        BALANCE[key] = value
    end
end

local function balance_payload()
    local values = {}

    for key in pairs(DEFAULT_BALANCE) do
        values[key] =
            tonumber(BALANCE[key])
            or DEFAULT_BALANCE[key]
    end

    return {
        schema_version = 1,
        values = values
    }
end

local function load_balance()
    if json == nil
        or json.load_file == nil
    then
        stats.balance_status =
            "JSON API unavailable; attribute balance defaults active."

        return false
    end

    local ok, payload =
        pcall(function()
            return json.load_file(
                stats.balance_path
            )
        end)

    if not ok
        or type(payload) ~= "table"
    then
        stats.balance_status =
            "No attribute balance JSON found; defaults active."

        return false
    end

    local values =
        type(payload.values) == "table"
        and payload.values
        or payload

    local loaded_values = 0

    for key, default_value in pairs(DEFAULT_BALANCE) do
        local value =
            tonumber(values[key])

        if value ~= nil then
            BALANCE[key] = value
            loaded_values =
                loaded_values + 1
        else
            BALANCE[key] = default_value
        end
    end

    stats.balance_loaded = true
    stats.balance_load_count =
        stats.balance_load_count + 1
    stats.balance_status =
        string.format(
            "Loaded %d attribute balance values from %s.",
            loaded_values,
            stats.balance_path
        )

    return true
end

function stats.save_balance()
    if json == nil
        or json.dump_file == nil
    then
        stats.balance_status =
            "JSON API unavailable; attribute balance was not saved."

        return false
    end

    local ok, result =
        pcall(function()
            return json.dump_file(
                stats.balance_path,
                balance_payload()
            )
        end)

    if not ok
        or result == false
    then
        stats.balance_status =
            "Failed to save attribute balance JSON."

        return false
    end

    stats.balance_loaded = true
    stats.balance_save_count =
        stats.balance_save_count + 1
    stats.balance_status =
        "Saved attribute balance to "
        .. stats.balance_path
        .. "."

    return true
end

function stats.reload_balance()
    restore_default_balance()
    stats.balance_loaded = false

    return load_balance()
end

restore_default_balance()
load_balance()

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
            math.min(
                BALANCE.vitality_max_hp_bonus,
                vitality_points *
                BALANCE.vitality_hp_per_point
            ),

        weapon_damage_multiplier =
            strength >= ATTRIBUTE_MAX
            and BALANCE.strength_damage_max_multiplier
            or math.min(
                BALANCE.strength_damage_max_multiplier,
                1.0 +
                strength_points *
                BALANCE.strength_damage_per_point
            ),

        action_speed_multiplier =
            math.min(
                BALANCE.dexterity_speed_max_multiplier,
                1.0 +
                dexterity_points *
                BALANCE.dexterity_speed_per_point
            ),

        movement_speed_multiplier =
            math.min(
                BALANCE.agility_movement_max_multiplier,
                1.0 +
                agility_points *
                BALANCE.agility_movement_per_point
            ),

        fire_rate_multiplier =
            math.min(
                BALANCE.dexterity_fire_rate_max_multiplier,
                1.0 +
                first_point_bonus(
                    dexterity_points,
                    BALANCE.dexterity_fire_rate_first_point,
                    BALANCE.dexterity_fire_rate_per_later_point
                )
            ),

        reload_speed_multiplier =
            math.min(
                BALANCE.agility_reload_max_multiplier,
                1.0 +
                first_point_bonus(
                    agility_points,
                    BALANCE.agility_reload_first_point,
                    BALANCE.agility_reload_per_later_point
                )
            ),

        healing_multiplier =
            math.min(
                BALANCE.intelligence_healing_max_multiplier,
                1.0 +
                intelligence_points *
                BALANCE.intelligence_healing_per_point
            ),

        critical_chance =
            math.min(
                BALANCE.luck_critical_chance_max,
                luck_points *
                BALANCE.luck_critical_per_point
            ),

        critical_damage_bonus =
            luck >= ATTRIBUTE_MAX
            and BALANCE.luck_critical_damage_max
            or math.min(
                BALANCE.luck_critical_damage_max,
                luck_points * BALANCE.luck_critical_damage_per_point
            )
    }
end

function stats.balance()
    return BALANCE
end

function stats.default_balance()
    return DEFAULT_BALANCE
end

function stats.restore_default_balance(save_changes)
    restore_default_balance()
    stats.balance_loaded = false
    stats.balance_status =
        "Attribute balance restored to shipped defaults."

    if save_changes == true then
        return stats.save_balance()
    end

    return true
end

function stats.attribute_min()
    return ATTRIBUTE_MIN
end

function stats.attribute_max()
    return ATTRIBUTE_MAX
end

return stats
