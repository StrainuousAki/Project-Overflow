------------------------------------------------------------
-- Maintenance classification — Build 49.39
-- Module: autorun/project_overflow/systems/enemies/rewards.lua
-- Role: Enemy identity, classification, persistence, reward, or runtime pipeline.
-- Status: active subsystem.
--
-- Compatibility policy:
--   Existing functions, hooks, module paths, and diagnostics are
--   intentionally retained in this maintenance pass.
--   `DEPRECATED` marks a supported legacy path, not removed code.
------------------------------------------------------------

------------------------------------------------------------
-- Project: Overflow — Enemy Rewards
--
-- Resolves database stats, elite tier, XP, and logical loot for a
-- dead runtime enemy. Enemy XP is enabled for the release runtime.
------------------------------------------------------------

local database =
    require("project_overflow.systems.enemies.database")
local elites =
    require("project_overflow.systems.enemies.elites")
local loot_tables =
    require("project_overflow.systems.loot.tables")
local rpg =
    require("project_overflow.systems.player.rpg")

local rewards = {
    award_xp_enabled = true,
    roll_loot_enabled = true,

    resolved_count = 0,
    awarded_xp_total = 0,

    last = nil
}


function rewards.initialize()
    -- Release behavior: native enemy deaths award the resolved XP amount.
    -- Keeping this as an explicit startup call documents ownership and lets
    -- future save/config migration happen here without changing the pipeline.
    rewards.award_xp_enabled = true
    rewards.roll_loot_enabled = true
    return true
end

local function choose_loot_table(enemy, elite)
    if enemy.tier == "boss" or elite.id == "boss" then
        return "boss"
    end

    if elite.id ~= "normal" then
        return "enemy_elite"
    end

    return enemy.loot_table or "enemy_standard"
end

function rewards.resolve(snapshot)
    snapshot = type(snapshot) == "table" and snapshot or {}

    local enemy =
        database.get_appearance(
            snapshot.kind_id,
            snapshot.spawn_id
        )

    local classification =
        snapshot.runtime_classification

    if
        type(classification) == "table" and
        classification.matched == true
    then
        enemy.display_name =
            classification.display_name
            or enemy.display_name

        enemy.description =
            classification.description
            or classification.display_name
            or enemy.description

        enemy.family =
            classification.family
            or enemy.family

        enemy.base_xp =
            tonumber(classification.base_xp)
            or enemy.base_xp

        enemy.fixed_xp =
            tonumber(classification.fixed_xp)
            or enemy.fixed_xp

        enemy.loot_table =
            classification.loot_table
            or enemy.loot_table

        enemy.elite_profile =
            classification.elite_profile
            or enemy.elite_profile

        enemy.forced_elite_tier =
            classification.forced_elite_tier
            or enemy.forced_elite_tier

        enemy.classification_source =
            classification.source

        enemy.classification_confidence =
            classification.confidence

        enemy.biorand_seed =
            classification.seed
    end

    local forced_tier =
        tostring(enemy.forced_elite_tier or "inherit")

    local elite

    if forced_tier ~= "inherit" and forced_tier ~= "" then
        elite =
            elites.get_tier(
                forced_tier
            )
    else
        elite =
            elites.get_or_roll(
                snapshot.context_ptr,
                enemy.elite_profile
            )
    end

    local xp

    if tonumber(enemy.fixed_xp) ~= nil then
        xp =
            math.max(
                0,
                math.floor(
                    tonumber(enemy.fixed_xp)
                )
            )
    else
        xp =
            math.max(
                0,
                math.floor(
                    (tonumber(enemy.base_xp) or 0) *
                    (tonumber(elite.xp_multiplier) or 1.0)
                )
            )
    end

    local loot_table =
        choose_loot_table(
            enemy,
            elite
        )

    local extra_rolls =
        math.max(
            0,
            (tonumber(elite.loot_rolls) or 1) - 1
        )

    local loot = {}

    if rewards.roll_loot_enabled == true then
        loot =
            loot_tables.roll(
                loot_table,
                extra_rolls
            )
    end

    local awarded = false

    if rewards.award_xp_enabled == true and xp > 0 then
        rpg.add_experience(xp)
        rewards.awarded_xp_total =
            rewards.awarded_xp_total + xp
        awarded = true
    end

    rewards.resolved_count =
        rewards.resolved_count + 1

    rewards.last = {
        kind_id = tostring(snapshot.kind_id or "unknown"),
        spawn_id = tostring(snapshot.spawn_id or "unknown"),
        observation_key = enemy.observation_key,
        native_display_name = enemy.native_display_name,
        context_type = tostring(snapshot.context_type or "unknown"),
        context_ptr = tostring(snapshot.context_ptr or "nil"),

        display_name = enemy.display_name,
        description = enemy.description,
        appearance_group_size = enemy.appearance_group_size,
        appearance_enemy_ids = enemy.appearance_enemy_ids,
        family = enemy.family,
        classification_source = enemy.classification_source,
        classification_confidence = enemy.classification_confidence,
        biorand_seed = enemy.biorand_seed,
        enemy_tier = enemy.tier,
        used_fallback = enemy.is_fallback == true,

        elite_id = elite.id,
        elite_name = elite.display_name,
        elite_roll = elite.roll,

        base_xp = enemy.base_xp,
        fixed_xp = enemy.fixed_xp,
        appearance_rpg_overrides = enemy.has_rpg_overrides,
        forced_elite_tier = enemy.forced_elite_tier,
        xp_multiplier = elite.xp_multiplier,
        final_xp = xp,
        xp_awarded = awarded,

        loot_table = loot_table,
        loot = loot,

        base_attributes = enemy.attributes,
        elite_attributes = elite.attributes
    }

    return rewards.last
end

return rewards
