------------------------------------------------------------
-- Maintenance classification — Build 49.39
-- Module: autorun/project_overflow/systems/loot/tables.lua
-- Role: Loot configuration and reward tables.
-- Status: active subsystem.
--
-- Compatibility policy:
--   Existing functions, hooks, module paths, and diagnostics are
--   intentionally retained in this maintenance pass.
--   `DEPRECATED` marks a supported legacy path, not removed code.
------------------------------------------------------------

------------------------------------------------------------
-- Project: Overflow — Loot Tables
--
-- Logical RPG rewards are separated from native RE4 item drops.
-- Entries can later map to custom relics, materials, currency, or
-- native inventory items once those systems are implemented.
------------------------------------------------------------

local loot_tables = {}

local TABLES = {
    enemy_standard = {
        rolls = 1,
        entries = {
            { id = "nothing", weight = 55 },
            { id = "overflow_shard", weight = 25, min = 1, max = 1 },
            { id = "overflow_essence", weight = 15, min = 1, max = 1 },
            { id = "relic_fragment", weight = 5, min = 1, max = 1 }
        }
    },

    enemy_elite = {
        rolls = 2,
        entries = {
            { id = "overflow_shard", weight = 40, min = 1, max = 3 },
            { id = "overflow_essence", weight = 30, min = 1, max = 2 },
            { id = "relic_fragment", weight = 20, min = 1, max = 2 },
            { id = "rare_relic_roll", weight = 10, min = 1, max = 1 }
        }
    },

    boss = {
        rolls = 3,
        entries = {
            { id = "overflow_essence", weight = 45, min = 2, max = 5 },
            { id = "relic_fragment", weight = 35, min = 2, max = 4 },
            { id = "rare_relic_roll", weight = 15, min = 1, max = 1 },
            { id = "unique_reward_roll", weight = 5, min = 1, max = 1 }
        }
    }
}

local function weighted_pick(entries)
    local total = 0

    for _, entry in ipairs(entries or {}) do
        total = total + math.max(0, tonumber(entry.weight) or 0)
    end

    if total <= 0 then
        return nil
    end

    local roll = math.random() * total
    local cumulative = 0

    for _, entry in ipairs(entries) do
        cumulative =
            cumulative +
            math.max(0, tonumber(entry.weight) or 0)

        if roll <= cumulative then
            return entry
        end
    end

    return entries[#entries]
end

function loot_tables.roll(table_id, additional_rolls)
    local definition =
        TABLES[table_id]
        or TABLES.enemy_standard

    local roll_count =
        math.max(
            0,
            math.floor(
                (tonumber(definition.rolls) or 1) +
                (tonumber(additional_rolls) or 0)
            )
        )

    local results = {}

    for _ = 1, roll_count do
        local entry =
            weighted_pick(
                definition.entries
            )

        if entry ~= nil and entry.id ~= "nothing" then
            local minimum = math.floor(tonumber(entry.min) or 1)
            local maximum = math.floor(tonumber(entry.max) or minimum)

            results[#results + 1] = {
                id = entry.id,
                count = math.random(minimum, math.max(minimum, maximum))
            }
        end
    end

    return results
end

function loot_tables.get(table_id)
    return TABLES[table_id]
end

function loot_tables.all()
    return TABLES
end

return loot_tables
