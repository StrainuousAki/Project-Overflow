------------------------------------------------------------
-- Maintenance classification — Build 49.39
-- Module: autorun/project_overflow/systems/enemies/database.lua
-- Role: Enemy identity, classification, persistence, reward, or runtime pipeline.
-- Status: active subsystem.
--
-- Compatibility policy:
--   Existing functions, hooks, module paths, and diagnostics are
--   intentionally retained in this maintenance pass.
--   `DEPRECATED` marks a supported legacy path, not removed code.
------------------------------------------------------------

------------------------------------------------------------
-- Project: Overflow — Enemy Database and Live Bestiary Editor
--
-- The native CharacterKindID catalog keeps Capcom's internal ch*
-- identifiers for reference. Friendly names and RPG settings can be
-- edited during play and saved to reframework/data/project_overflow.
------------------------------------------------------------

local database = {
    save_path = "project_overflow/enemy_database.json",
    overrides = {},
    loaded = false,
    revision = 0,
    last_load_clock = 0.0,
    last_status = "Not loaded.",

    appearance_schema_version = 3,
    migration_changed_data = false
}

local FALLBACK = {
    display_name = "Unknown Enemy",
    family = "unknown",
    tier = "standard",
    identified = false,

    base_xp = 10,
    loot_table = "enemy_standard",
    elite_profile = "standard",

    attributes = {
        health_multiplier = 1.0,
        damage_multiplier = 1.0,
        stagger_resistance = 1.0,
        status_resistance = 1.0,
        movement_multiplier = 1.0,
        critical_resistance = 0.0
    },

    variants = {}
}

local CATALOG = {
    ["100000"] = { internal_id = "ch0_a0z0" },
    ["110000"] = { internal_id = "ch0_a1z0" },
    ["199999"] = { internal_id = "ch0_zzzz" },
    ["200000"] = { internal_id = "ch1_c0z0" },
    ["200001"] = { internal_id = "ch1_c0z1" },
    ["200002"] = { internal_id = "ch1_c0z2" },
    ["200003"] = { internal_id = "ch1_d1z1" },
    ["200004"] = { internal_id = "ch1_d2z0" },
    ["200005"] = { internal_id = "ch1_d3z0" },
    ["200006"] = { internal_id = "ch1_f0z0" },
    ["200007"] = { internal_id = "ch1_f1z0" },
    ["200008"] = { internal_id = "ch1_d0z0" },
    ["200009"] = { internal_id = "ch1_e0z0" },
    ["200010"] = { internal_id = "ch1_c8z0" },
    ["200011"] = { internal_id = "ch1_b7z0" },
    ["200012"] = { internal_id = "ch1_d4z0" },
    ["200013"] = { internal_id = "ch1_f7z0" },
    ["200014"] = { internal_id = "ch1_d5z0" },
    ["200015"] = { internal_id = "ch1_f2z0" },
    ["200016"] = { internal_id = "ch1_d6z0" },
    ["200017"] = { internal_id = "ch1_f6z0" },
    ["200018"] = { internal_id = "ch1_f8z0" },
    ["200019"] = { internal_id = "ch1_b5z1" },
    ["200020"] = { internal_id = "ch1_f4z1" },
    ["200021"] = { internal_id = "ch1_f5z1" },
    ["200022"] = { internal_id = "ch4_d7z0" },
    ["200023"] = { internal_id = "ch4_f9z0" },
    ["200024"] = { internal_id = "ch4_faz0" },
    ["200025"] = { internal_id = "ch4_faz1" },
    ["200026"] = { internal_id = "ch1_fcz0" },
    ["200027"] = { internal_id = "ch1_fdz0" },
    ["200028"] = { internal_id = "ch4_fez0" },
    ["200029"] = { internal_id = "ch4_fbz0" },
    ["200030"] = { internal_id = "ch2_a1z0" },
    ["200031"] = { internal_id = "ch2_a200" },
    ["200032"] = { internal_id = "ch2_a3z0" },
    ["200033"] = { internal_id = "ch2_a3z1" },
    ["200034"] = { internal_id = "ch2_a600" },
    ["200035"] = { internal_id = "ch2_a7z0" },
    ["200036"] = { internal_id = "ch2_b0z0" },
    ["200037"] = { internal_id = "ch2_b1z0" },
    ["200038"] = { internal_id = "ch2_b200" },
    ["200039"] = { internal_id = "ch2_b300" },
    ["200040"] = { internal_id = "ch2_b400" },
    ["200041"] = { internal_id = "ch2_b600" },
    ["200042"] = { internal_id = "ch2_b8z0" },
    ["200043"] = { internal_id = "ch2_b900" },
    ["200044"] = { internal_id = "ch2_ba00" },
    ["200045"] = { internal_id = "ch2_bbz0" },
    ["200046"] = { internal_id = "ch2_bc00" },
    ["200047"] = { internal_id = "ch2_bd00" },
    ["380000"] = { internal_id = "ch3_a8z0" },
    ["600000"] = { internal_id = "ch6_i0z0" },
    ["600001"] = { internal_id = "ch6_i1z0" },
    ["600002"] = { internal_id = "ch6_i2z0" },
    ["600003"] = { internal_id = "ch6_i3z0" },
    ["600004"] = { internal_id = "ch6_i4z0" },
    ["600005"] = { internal_id = "ch6_i5z0" },
    ["80000"] = { internal_id = "ch8_0000" },
    ["81000"] = { internal_id = "ch8_1000" },
    ["81100"] = { internal_id = "ch8_1100" },
    ["81101"] = { internal_id = "ch8_g1z0" },
    ["81102"] = { internal_id = "ch8_g5z0" },
    ["81103"] = { internal_id = "ch8_g9z0" },
    ["81104"] = { internal_id = "ch8_gaz0" },
    ["81105"] = { internal_id = "ch8_g3z0" },
    ["81106"] = { internal_id = "ch8_g0z0" },
    ["81107"] = { internal_id = "ch8_g2z0" },
    ["81108"] = { internal_id = "ch8_g4z0" },
    ["81109"] = { internal_id = "ch7_k0z0" },
    ["500000"] = { internal_id = "ch5_j1z0" },
}

-- Confirmed mappings from runtime captures.
CATALOG["200001"].display_name = "Zealot"
CATALOG["200001"].family = "zealot"
CATALOG["200001"].identified = true
CATALOG["200001"].base_xp = 10
CATALOG["200001"].variants = {
    ["00000000"] = "Hooded Female",
    ["00000001"] = "Hooded Male",
    ["00000007"] = "Observed Zealot Model",
    ["0000000A"] = "Observed Zealot Model",
    ["0000000B"] = "Heavy Vest Model",
    ["0000000E"] = "Face-Veil Model"
}

CATALOG["200005"].display_name = "Novistador"
CATALOG["200005"].family = "novistador"
CATALOG["200005"].identified = true
CATALOG["200005"].base_xp = 55

CATALOG["200010"].display_name = "Bull-Head Brute"
CATALOG["200010"].family = "brute"
CATALOG["200010"].identified = true
CATALOG["200010"].base_xp = 125
CATALOG["200010"].loot_table = "enemy_elite"

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

local function merge(target, defaults)
    target = type(target) == "table" and target or {}

    for key, default_value in pairs(defaults or {}) do
        if type(default_value) == "table" then
            target[key] = merge(target[key], default_value)
        elseif target[key] == nil then
            target[key] = default_value
        end
    end

    return target
end

local function overlay(target, source)
    for key, value in pairs(source or {}) do
        if type(value) == "table" then
            target[key] = overlay(
                type(target[key]) == "table" and target[key] or {},
                value
            )
        else
            target[key] = value
        end
    end

    return target
end

function database.load()
    local ok, result =
        pcall(function()
            return json.load_file(database.save_path)
        end)

    if ok and type(result) == "table" then
        database.overrides = result
        database.last_status = "Loaded enemy database overrides."
    else
        database.overrides = {}
        database.last_status = "No saved overrides found; using catalog defaults."
    end

    database.loaded = true
    database.migrate_loaded_data()

    if database.migration_changed_data == true then
        database.save()
        database.last_status =
            "Migrated enemy database to isolated, provenance-safe appearance records."
    end

    database.revision = database.revision + 1
    database.last_load_clock = os.clock()

    return true
end

function database.reload()
    -- Force every cached definition/editor to be rebuilt from disk.
    database.loaded = false
    database.overrides = {}

    local ok = database.load()

    if ok then
        database.last_status =
            "Reloaded enemy database overrides."
    end

    return ok
end

function database.save()
    local ok, error_text =
        pcall(function()
            json.dump_file(
                database.save_path,
                database.overrides
            )
        end)

    if ok then
        database.revision = database.revision + 1
        database.last_status = "Enemy database saved."
        return true
    end

    database.last_status =
        "Save failed: " .. tostring(error_text)

    return false
end

function database.ensure_loaded()
    if database.loaded ~= true then
        database.load()
    end
end

function database.get(kind_id)
    database.ensure_loaded()

    local key = tostring(kind_id or "unknown")
    local result = copy_table(FALLBACK)
    local catalog_entry = CATALOG[key]

    if catalog_entry ~= nil then
        result = overlay(result, copy_table(catalog_entry))
        result.registered = true
    else
        result.registered = false
    end

    local override = database.overrides[key]

    if override ~= nil then
        result = overlay(result, copy_table(override))
        result.has_override = true
    else
        result.has_override = false
    end

    result.kind_id = key
    result.is_fallback = result.identified ~= true

    return result
end

function database.update(kind_id, values, save_now)
    database.ensure_loaded()

    local key = tostring(kind_id or "")

    if key == "" or key == "unknown" then
        return false, "A valid CharacterKindID is required."
    end

    local current =
        type(database.overrides[key]) == "table"
        and database.overrides[key]
        or {}

    database.overrides[key] =
        overlay(current, copy_table(values or {}))

    if save_now ~= false then
        database.save()
    end

    return true
end

function database.set_variant(kind_id, spawner_id, name, save_now)
    local key = tostring(kind_id or "")
    local spawn_key = tostring(spawner_id or "")

    if key == "" or spawn_key == "" then
        return false
    end

    database.ensure_loaded()

    database.overrides[key] =
        database.overrides[key] or {}

    database.overrides[key].variants =
        database.overrides[key].variants or {}

    database.overrides[key].variants[spawn_key] =
        tostring(name or "")

    if save_now ~= false then
        database.save()
    end

    return true
end


function database.observation_key(kind_id, spawn_id)
    return tostring(kind_id or "unknown") ..
        "|" ..
        tostring(spawn_id or "unknown")
end

local function normalize_enemy_id(value)
    return tostring(value or "unknown")
end

local function contains_enemy_id(group, enemy_id)
    if type(group) ~= "table" or type(group.enemy_ids) ~= "table" then
        return false
    end

    local target = normalize_enemy_id(enemy_id)

    for _, value in ipairs(group.enemy_ids) do
        if normalize_enemy_id(value) == target then
            return true
        end
    end

    return false
end

local function find_appearance_group(container, enemy_id)
    if type(container) ~= "table" then
        return nil, nil
    end

    local appearances = container.appearances

    if type(appearances) ~= "table" then
        return nil, nil
    end

    for index, group in ipairs(appearances) do
        if contains_enemy_id(group, enemy_id) then
            return group, index
        end
    end

    return nil, nil
end

local function add_id_once(group, enemy_id)
    group.enemy_ids =
        type(group.enemy_ids) == "table"
        and group.enemy_ids
        or {}

    local normalized = normalize_enemy_id(enemy_id)

    if not contains_enemy_id(group, normalized) then
        group.enemy_ids[#group.enemy_ids + 1] = normalized
        table.sort(group.enemy_ids)
    end
end

local function add_to_description_group(entry, description, enemy_id)
    entry.appearances =
        type(entry.appearances) == "table"
        and entry.appearances
        or {}

    local target_description =
        tostring(description or "Unidentified Appearance")

    for _, group in ipairs(entry.appearances) do
        if tostring(group.description or "") == target_description then
            add_id_once(group, enemy_id)
            return group
        end
    end

    local group = {
        description = target_description,
        enemy_ids = {}
    }

    add_id_once(group, enemy_id)
    entry.appearances[#entry.appearances + 1] = group

    return group
end

local function provisional_group(enemy_id)
    local normalized = normalize_enemy_id(enemy_id)

    return {
        description =
            "Unidentified Appearance [" ..
            normalized ..
            "]",
        enemy_ids = {
            normalized
        },
        identity_source = "provisional_observation",
        user_confirmed = false
    }
end

local function copy_confirmed_group(group)
    local result = copy_table(group or {})

    result.enemy_ids = {}
    for _, enemy_id in ipairs(group.enemy_ids or {}) do
        add_id_once(result, enemy_id)
    end

    result.identity_source = "manual"
    result.user_confirmed = true

    return result
end

local function migrate_kind_entry(kind_id, entry)
    if type(entry) ~= "table" then
        return {
            appearance_schema_version =
                database.appearance_schema_version,
            appearances = {}
        }
    end

    local previous_version =
        tonumber(entry.appearance_schema_version)
        or 0

    local migrated_groups = {}
    local seen_ids = {}

    local function add_provisional(enemy_id)
        local normalized = normalize_enemy_id(enemy_id)

        if
            normalized == "" or
            normalized == "unknown" or
            seen_ids[normalized] == true
        then
            return
        end

        seen_ids[normalized] = true
        migrated_groups[#migrated_groups + 1] =
            provisional_group(normalized)
    end

    local function add_confirmed(group)
        local copied = copy_confirmed_group(group)

        for _, enemy_id in ipairs(copied.enemy_ids or {}) do
            seen_ids[normalize_enemy_id(enemy_id)] = true
        end

        migrated_groups[#migrated_groups + 1] = copied
    end

    if type(entry.appearances) == "table" then
        for _, group in ipairs(entry.appearances) do
            local explicitly_confirmed =
                group.user_confirmed == true or
                tostring(group.identity_source or "") == "manual"

            if
                explicitly_confirmed and
                type(group.enemy_ids) == "table" and
                #(group.enemy_ids or {}) > 0
            then
                add_confirmed(group)
            elseif type(group.enemy_ids) == "table" then
                for _, enemy_id in ipairs(group.enemy_ids) do
                    add_provisional(enemy_id)
                end
            elseif group.enemy_id ~= nil then
                add_provisional(group.enemy_id)
            end
        end
    end

    if type(entry.enemies) == "table" then
        for _, record in ipairs(entry.enemies) do
            add_provisional(record.enemy_id)
        end
    end

    if type(entry.variants) == "table" then
        for enemy_id, _ in pairs(entry.variants) do
            add_provisional(enemy_id)
        end
    end

    if type(entry.observations) == "table" then
        for enemy_id, _ in pairs(entry.observations) do
            add_provisional(enemy_id)
        end
    end

    entry.appearances = migrated_groups
    entry.enemies = nil
    entry.variants = nil
    entry.observations = nil
    entry.appearance_schema_version =
        database.appearance_schema_version

    if previous_version < database.appearance_schema_version then
        database.migration_changed_data = true
    end

    return entry
end

function database.migrate_loaded_data()
    database.migration_changed_data = false

    for kind_id, entry in pairs(database.overrides or {}) do
        database.overrides[kind_id] =
            migrate_kind_entry(kind_id, entry)
    end
end

function database.get_appearance(kind_id, enemy_id)
    database.ensure_loaded()

    local kind_key = tostring(kind_id or "unknown")
    local enemy_key = normalize_enemy_id(enemy_id)
    local family_definition = database.get(kind_key)

    local result = copy_table(family_definition)
    result.native_display_name = family_definition.display_name
    result.native_family = family_definition.family
    result.enemy_id = enemy_key
    result.spawn_id = enemy_key
    result.observation_key =
        database.observation_key(kind_key, enemy_key)

    local kind_override = database.overrides[kind_key]
    local group, group_index =
        find_appearance_group(kind_override, enemy_key)

    if group ~= nil then
        result.description =
            tostring(group.description or "Unidentified Appearance")
        result.appearance_group_index = group_index
        result.appearance_group_size =
            type(group.enemy_ids) == "table"
            and #group.enemy_ids
            or 0
        result.appearance_enemy_ids =
            copy_table(group.enemy_ids or {})
        result.has_observation_override = true
        result.identity_source =
            tostring(group.identity_source or "legacy")
        result.user_confirmed =
            group.user_confirmed == true
    else
        result.description = "Unidentified Appearance"
        result.appearance_group_index = 0
        result.appearance_group_size = 0
        result.appearance_enemy_ids = {}
        result.has_observation_override = false
        result.identity_source = "none"
        result.user_confirmed = false
    end

    result.display_name = family_definition.display_name
    result.family = family_definition.family
    result.base_xp = family_definition.base_xp
    result.loot_table = family_definition.loot_table
    result.elite_profile = family_definition.elite_profile
    result.identified = family_definition.identified

    -- A CharacterKindID is only the native runtime pool/default. BioRand
    -- can place unrelated enemy archetypes inside that pool, so each
    -- appearance group may override its readable archetype and family.
    if group ~= nil then
        if
            group.display_name_override ~= nil and
            tostring(group.display_name_override) ~= ""
        then
            result.display_name =
                tostring(group.display_name_override)
        end

        if
            group.family_override ~= nil and
            tostring(group.family_override) ~= ""
        then
            result.family =
                tostring(group.family_override)
        end

        if group.identified_override ~= nil then
            result.identified =
                group.identified_override == true
        end
    end

    -- Appearance-group RPG overrides are optional. Missing values inherit
    -- the CharacterKindID family definition.
    if group ~= nil then
        if group.base_xp_override ~= nil then
            result.base_xp =
                tonumber(group.base_xp_override)
                or result.base_xp
        end

        if
            group.loot_table_override ~= nil and
            tostring(group.loot_table_override) ~= ""
        then
            result.loot_table =
                tostring(group.loot_table_override)
        end

        if
            group.elite_profile_override ~= nil and
            tostring(group.elite_profile_override) ~= ""
        then
            result.elite_profile =
                tostring(group.elite_profile_override)
        end

        result.forced_elite_tier =
            tostring(group.forced_elite_tier or "inherit")

        result.fixed_xp =
            tonumber(group.fixed_xp)

        result.has_rpg_overrides =
            (
                group.display_name_override ~= nil and
                tostring(group.display_name_override) ~= ""
            ) or
            (
                group.family_override ~= nil and
                tostring(group.family_override) ~= ""
            ) or
            group.identified_override ~= nil or
            group.base_xp_override ~= nil or
            group.fixed_xp ~= nil or
            (
                group.loot_table_override ~= nil and
                tostring(group.loot_table_override) ~= ""
            ) or
            (
                group.elite_profile_override ~= nil and
                tostring(group.elite_profile_override) ~= ""
            ) or
            (
                group.forced_elite_tier ~= nil and
                tostring(group.forced_elite_tier) ~= "" and
                tostring(group.forced_elite_tier) ~= "inherit"
            )
    else
        result.forced_elite_tier = "inherit"
        result.fixed_xp = nil
        result.has_rpg_overrides = false
    end

    result.is_fallback = family_definition.identified ~= true

    return result
end

function database.observe_enemy_id(kind_id, enemy_id, save_now)
    database.ensure_loaded()

    local kind_key = tostring(kind_id or "")
    local enemy_key = normalize_enemy_id(enemy_id)

    if kind_key == "" or kind_key == "unknown" then
        return false, "A valid CharacterKindID is required."
    end

    if enemy_key == "" or enemy_key == "unknown" then
        return false, "A valid enemy_id is required."
    end

    database.overrides[kind_key] =
        migrate_kind_entry(
            kind_key,
            database.overrides[kind_key] or {}
        )

    local entry = database.overrides[kind_key]
    local existing = find_appearance_group(entry, enemy_key)

    if existing ~= nil then
        return true, "Already registered."
    end

    -- Never infer that two runtime IDs use the same model solely because
    -- their CharacterKindID matches. Every new ID starts independently.
    -- Matching models can be merged deliberately after visual confirmation.
    entry.appearances[#entry.appearances + 1] = {
        description =
            "Unidentified Appearance [" ..
            enemy_key ..
            "]",
        enemy_ids = {
            enemy_key
        },
        identity_source = "provisional_observation",
        user_confirmed = false
    }

    if save_now ~= false then
        database.save()
    end

    return true, "Registered new enemy_id."
end

function database.update_appearance(kind_id, enemy_id, values, save_now)
    database.ensure_loaded()

    local kind_key = tostring(kind_id or "")
    local enemy_key = normalize_enemy_id(enemy_id)

    if kind_key == "" or kind_key == "unknown" then
        return false, "A valid CharacterKindID is required."
    end

    if enemy_key == "" or enemy_key == "unknown" then
        return false, "A valid enemy_id is required."
    end

    database.overrides[kind_key] =
        migrate_kind_entry(
            kind_key,
            database.overrides[kind_key] or {}
        )

    local entry = database.overrides[kind_key]
    local group =
        find_appearance_group(entry, enemy_key)

    if group == nil then
        database.observe_enemy_id(kind_key, enemy_key, false)
        group = find_appearance_group(entry, enemy_key)
    end

    local new_description =
        tostring(
            type(values) == "table"
            and values.description
            or group.description
            or "Unidentified Appearance"
        )

    if new_description ~= tostring(group.description or "") then
        -- Renaming an appearance renames the whole visual group and keeps
        -- every known instance/template ID attached to it.
        group.description = new_description
    end

    if type(values) == "table" then
        if values.user_confirmed ~= false then
            group.identity_source = "manual"
            group.user_confirmed = true
        end

        if values.clear_rpg_overrides == true then
            group.display_name_override = nil
            group.family_override = nil
            group.identified_override = nil
            group.base_xp_override = nil
            group.fixed_xp = nil
            group.loot_table_override = nil
            group.elite_profile_override = nil
            group.forced_elite_tier = nil
        else
            if values.display_name_override ~= nil then
                local text =
                    tostring(values.display_name_override)

                group.display_name_override =
                    text ~= "" and text or nil
            end

            if values.family_override ~= nil then
                local text =
                    tostring(values.family_override)

                group.family_override =
                    text ~= "" and text or nil
            end

            if values.identified_override ~= nil then
                group.identified_override =
                    values.identified_override == true
            end

            if values.base_xp_override ~= nil then
                group.base_xp_override =
                    tonumber(values.base_xp_override)
            end

            if values.fixed_xp ~= nil then
                local fixed_xp = tonumber(values.fixed_xp)

                if fixed_xp ~= nil and fixed_xp >= 0 then
                    group.fixed_xp = fixed_xp
                else
                    group.fixed_xp = nil
                end
            end

            if values.loot_table_override ~= nil then
                local text =
                    tostring(values.loot_table_override)

                group.loot_table_override =
                    text ~= "" and text or nil
            end

            if values.elite_profile_override ~= nil then
                local text =
                    tostring(values.elite_profile_override)

                group.elite_profile_override =
                    text ~= "" and text or nil
            end

            if values.forced_elite_tier ~= nil then
                local text =
                    tostring(values.forced_elite_tier)

                group.forced_elite_tier =
                    (
                        text ~= "" and
                        text ~= "inherit"
                    )
                    and text
                    or nil
            end
        end
    end

    if save_now ~= false then
        database.save()
    end

    return true
end

function database.move_enemy_id(
    kind_id,
    enemy_id,
    target_description,
    save_now
)
    database.ensure_loaded()

    local kind_key = tostring(kind_id or "")
    local enemy_key = normalize_enemy_id(enemy_id)

    database.overrides[kind_key] =
        migrate_kind_entry(
            kind_key,
            database.overrides[kind_key] or {}
        )

    local entry = database.overrides[kind_key]
    local current_group, current_index =
        find_appearance_group(entry, enemy_key)

    if current_group ~= nil then
        for index, value in ipairs(current_group.enemy_ids or {}) do
            if normalize_enemy_id(value) == enemy_key then
                table.remove(current_group.enemy_ids, index)
                break
            end
        end

        if #(current_group.enemy_ids or {}) == 0 then
            table.remove(entry.appearances, current_index)
        end
    end

    local target_group =
        add_to_description_group(
            entry,
            target_description,
            enemy_key
        )

    target_group.identity_source = "manual"
    target_group.user_confirmed = true

    if save_now ~= false then
        database.save()
    end

    return true
end

function database.appearances(kind_id)
    database.ensure_loaded()

    local key = tostring(kind_id or "unknown")
    local entry = database.overrides[key]

    if type(entry) ~= "table" then
        return {}
    end

    migrate_kind_entry(key, entry)

    return entry.appearances or {}
end

-- Compatibility aliases for older modules and saves.
database.get_observation = database.get_appearance
database.update_observation = database.update_appearance


function database.register(kind_id, definition)
    return database.update(kind_id, definition, true)
end

function database.catalog()
    return CATALOG
end

function database.all()
    return CATALOG
end

function database.fallback()
    return copy_table(FALLBACK)
end

function database.stats()
    database.ensure_loaded()

    local total = 0
    local identified = 0

    for kind_id, _ in pairs(CATALOG) do
        total = total + 1

        if database.get(kind_id).identified == true then
            identified = identified + 1
        end
    end

    return {
        total = total,
        identified = identified,
        unidentified = total - identified,
        percent = total > 0 and (identified / total) * 100.0 or 0.0
    }
end

return database
