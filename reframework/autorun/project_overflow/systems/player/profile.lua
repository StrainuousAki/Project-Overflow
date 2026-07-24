------------------------------------------------------------
-- Maintenance classification — Build 49.39
-- Module: autorun/project_overflow/systems/player/profile.lua
-- Role: Player RPG profile, attributes, saves, experience, and stat application.
-- Status: active subsystem.
--
-- Compatibility policy:
--   Existing functions, hooks, module paths, and diagnostics are
--   intentionally retained in this maintenance pass.
--   `DEPRECATED` marks a supported legacy path, not removed code.
------------------------------------------------------------

------------------------------------------------------------
-- Project: Overflow — Player Profile
--
-- Owns the persistent RPG values. Other systems should ask this
-- module for the profile instead of keeping separate copies.
------------------------------------------------------------

local profile = {}

local ATTRIBUTE_MIN = 1
local ATTRIBUTE_MAX = 250

local DEFAULTS = {
    schema_version = 2,

    level = 1,
    experience = 0,

    attribute_points = 0,
    skill_points = 0,

    attributes = {
        strength = 1,
        vitality = 1,
        dexterity = 1,
        agility = 1,
        intelligence = 1,
        luck = 1
    },

    health = {
        base_max_hp = 0,
        applied_vitality_bonus = 0,
        last_effective_max_hp = 0
    }
}

local current = nil

local function copy_table(source)
    local result = {}

    for key, value in pairs(source or {}) do
        if type(value) == "table" then
            result[key] = copy_table(value)
        else
            result[key] = value
        end
    end

    return result
end

local function merge_defaults(target, defaults)
    target = type(target) == "table" and target or {}

    for key, default_value in pairs(defaults) do
        local value = target[key]

        if type(default_value) == "table" then
            target[key] = merge_defaults(value, default_value)
        elseif value == nil then
            target[key] = default_value
        end
    end

    return target
end

local function normalize_attributes(data)
    data.attributes = type(data.attributes) == "table" and data.attributes or {}
    for attribute_name, default_value in pairs(DEFAULTS.attributes) do
        data.attributes[attribute_name] = math.max(
            ATTRIBUTE_MIN,
            math.min(
                ATTRIBUTE_MAX,
                math.floor(tonumber(data.attributes[attribute_name]) or default_value)
            )
        )
    end
    return data
end

function profile.reset()
    current = copy_table(DEFAULTS)
    return current
end

function profile.get()
    if current == nil then
        profile.reset()
    end

    return current
end

function profile.replace(data)
    current = merge_defaults(
        type(data) == "table" and data or {},
        copy_table(DEFAULTS)
    )

    normalize_attributes(current)
    -- Profiles from schema 1 predate Agility. merge_defaults supplies the
    -- baseline value and the normalized in-memory profile is upgraded so the
    -- next native save writes the complete schema.
    current.schema_version = DEFAULTS.schema_version

    return current
end

function profile.defaults()
    return copy_table(DEFAULTS)
end

function profile.add_attribute_point(attribute_name, amount)
    local data = profile.get()
    local attributes = data.attributes
    local current_value = attributes[attribute_name]

    if current_value == nil then
        return false, "Unknown attribute: " .. tostring(attribute_name)
    end

    amount = math.max(1, math.floor(tonumber(amount) or 1))

    if data.attribute_points < amount then
        return false, "Not enough attribute points."
    end


    if current_value >= ATTRIBUTE_MAX then
        return false, "Attribute is already at the cap of " .. tostring(ATTRIBUTE_MAX) .. "."
    end

    amount = math.min(amount, ATTRIBUTE_MAX - current_value)

    attributes[attribute_name] = current_value + amount
    data.attribute_points = data.attribute_points - amount

    return true
end

return profile
