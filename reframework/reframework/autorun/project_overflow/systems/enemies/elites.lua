------------------------------------------------------------
-- Maintenance classification — Build 49.39
-- Module: autorun/project_overflow/systems/enemies/elites.lua
-- Role: Enemy identity, classification, persistence, reward, or runtime pipeline.
-- Status: active subsystem.
--
-- Compatibility policy:
--   Existing functions, hooks, module paths, and diagnostics are
--   intentionally retained in this maintenance pass.
--   `DEPRECATED` marks a supported legacy path, not removed code.
------------------------------------------------------------

------------------------------------------------------------
-- Project: Overflow — Elite Tiers
--
-- Rolls a persistent elite tier per runtime enemy pointer. A future
-- spawn hook will call this when enemies appear; the death hook uses
-- the same function as a fallback so reward testing can begin now.
------------------------------------------------------------

local elites = {
    instances = {}
}

local PROFILES = {
    standard = {
        { id = "normal", chance = 0.85 },
        { id = "champion", chance = 0.10 },
        { id = "elite", chance = 0.04 },
        { id = "legendary", chance = 0.01 }
    },

    boss = {
        { id = "boss", chance = 1.0 }
    },

    no_elites = {
        { id = "normal", chance = 1.0 }
    }
}

local TIERS = {
    normal = {
        display_name = "Normal",
        xp_multiplier = 1.0,
        loot_rolls = 1,
        attributes = {
            health_multiplier = 1.0,
            damage_multiplier = 1.0,
            stagger_resistance = 1.0,
            status_resistance = 1.0,
            movement_multiplier = 1.0
        }
    },

    champion = {
        display_name = "Champion",
        xp_multiplier = 1.75,
        loot_rolls = 2,
        attributes = {
            health_multiplier = 1.35,
            damage_multiplier = 1.15,
            stagger_resistance = 1.20,
            status_resistance = 1.15,
            movement_multiplier = 1.03
        }
    },

    elite = {
        display_name = "Elite",
        xp_multiplier = 3.0,
        loot_rolls = 3,
        attributes = {
            health_multiplier = 1.75,
            damage_multiplier = 1.35,
            stagger_resistance = 1.45,
            status_resistance = 1.35,
            movement_multiplier = 1.07
        }
    },

    legendary = {
        display_name = "Legendary",
        xp_multiplier = 6.0,
        loot_rolls = 5,
        attributes = {
            health_multiplier = 2.50,
            damage_multiplier = 1.70,
            stagger_resistance = 1.90,
            status_resistance = 1.75,
            movement_multiplier = 1.12
        }
    },

    boss = {
        display_name = "Boss",
        xp_multiplier = 5.0,
        loot_rolls = 4,
        attributes = {
            health_multiplier = 1.0,
            damage_multiplier = 1.0,
            stagger_resistance = 1.0,
            status_resistance = 1.0,
            movement_multiplier = 1.0
        }
    }
}

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

local function roll_profile(profile_name)
    local profile =
        PROFILES[profile_name]
        or PROFILES.standard

    local roll = math.random()
    local cumulative = 0.0

    for _, option in ipairs(profile) do
        cumulative = cumulative + option.chance

        if roll <= cumulative then
            local tier =
                copy_table(
                    TIERS[option.id]
                    or TIERS.normal
                )

            tier.id = option.id
            tier.roll = roll
            tier.profile = profile_name

            return tier
        end
    end

    local fallback = copy_table(TIERS.normal)
    fallback.id = "normal"
    fallback.roll = roll
    fallback.profile = profile_name

    return fallback
end

function elites.get_tier(tier_id)
    local id = tostring(tier_id or "normal")
    local tier =
        copy_table(
            TIERS[id]
            or TIERS.normal
        )

    tier.id =
        TIERS[id] ~= nil
        and id
        or "normal"

    tier.roll = 0.0
    tier.profile = "forced"

    return tier
end

function elites.get_or_roll(instance_key, profile_name)
    local key = tostring(instance_key or "unknown")

    if elites.instances[key] ~= nil then
        return elites.instances[key]
    end

    local tier = roll_profile(profile_name)
    elites.instances[key] = tier

    return tier
end

function elites.clear_instance(instance_key)
    elites.instances[tostring(instance_key or "unknown")] = nil
end

function elites.clear_all()
    elites.instances = {}
end

function elites.tiers()
    return TIERS
end

function elites.profiles()
    return PROFILES
end

return elites
