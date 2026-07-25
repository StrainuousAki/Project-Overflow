------------------------------------------------------------
-- Maintenance classification — Build 49.39
-- Module: autorun/project_overflow/systems/enemies/classifier.lua
-- Role: Enemy identity, classification, persistence, reward, or runtime pipeline.
-- Status: active subsystem.
--
-- Compatibility policy:
--   Existing functions, hooks, module paths, and diagnostics are
--   intentionally retained in this maintenance pass.
--   `DEPRECATED` marks a supported legacy path, not removed code.
------------------------------------------------------------

------------------------------------------------------------
-- Project: Overflow — Runtime Enemy Classifier
--
-- The classifier does not trust CharacterKindID by itself. Instead it
-- builds a compact fingerprint from live context/model/configuration data.
-- Confirmed fingerprints are learned once and reused across randomizer seeds.
------------------------------------------------------------

local classifier = {
    save_path = "project_overflow/enemy_classifier.json",
    mappings = {},
    loaded = false,
    revision = 0,
    last_status = "Not loaded."
}

local TEMPLATES = {
    ganado = {
        display_name = "Ganado",
        family = "ganado",
        base_xp = 20,
        loot_table = "enemy_standard",
        elite_profile = "standard",
        forced_elite_tier = "inherit"
    },

    zealot = {
        display_name = "Zealot",
        family = "zealot",
        base_xp = 30,
        loot_table = "enemy_standard",
        elite_profile = "standard",
        forced_elite_tier = "inherit"
    },

    brute = {
        display_name = "Bull-Headed Brute",
        family = "brute",
        base_xp = 125,
        loot_table = "enemy_elite",
        elite_profile = "standard",
        forced_elite_tier = "elite"
    },

    chainsaw_boss = {
        display_name = "Chainsaw Enemy",
        family = "chainsaw_bosses",
        base_xp = 150,
        loot_table = "enemy_elite",
        elite_profile = "boss",
        forced_elite_tier = "boss"
    },

    plagas = {
        display_name = "Plaga",
        family = "plagas",
        base_xp = 10,
        loot_table = "enemy_standard",
        elite_profile = "no_elites",
        forced_elite_tier = "normal"
    },

    novistador = {
        display_name = "Novistador",
        family = "novistador",
        base_xp = 55,
        loot_table = "enemy_standard",
        elite_profile = "standard",
        forced_elite_tier = "inherit"
    },

    regenerator = {
        display_name = "Regenerator",
        family = "regenerator",
        base_xp = 175,
        loot_table = "enemy_elite",
        elite_profile = "standard",
        forced_elite_tier = "elite"
    },

    living_armor = {
        display_name = "Living Armor",
        family = "living_armor",
        base_xp = 100,
        loot_table = "enemy_elite",
        elite_profile = "standard",
        forced_elite_tier = "elite"
    },

    wolf = {
        display_name = "Infected Wolf",
        family = "wolf",
        base_xp = 35,
        loot_table = "enemy_standard",
        elite_profile = "standard",
        forced_elite_tier = "inherit"
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

local function clean(value)
    local text = tostring(value or "unknown")

    if text == "" or text == "nil" then
        return "unknown"
    end

    return text
end

local function useful(value)
    local text = clean(value)

    return
        text ~= "unknown" and
        text ~= "nil" and
        text ~= "type error" and
        text ~= "none"
end

function classifier.load()
    local ok, data =
        pcall(function()
            return json.load_file(classifier.save_path)
        end)

    if ok and type(data) == "table" then
        classifier.mappings = data
        classifier.last_status = "Loaded runtime classifier mappings."
    else
        classifier.mappings = {}
        classifier.last_status = "No classifier mappings found."
    end

    classifier.loaded = true
    classifier.revision = classifier.revision + 1

    return true
end

function classifier.ensure_loaded()
    if classifier.loaded ~= true then
        classifier.load()
    end
end

function classifier.save()
    local ok, error_text =
        pcall(function()
            json.dump_file(
                classifier.save_path,
                classifier.mappings
            )
        end)

    if ok then
        classifier.revision = classifier.revision + 1
        classifier.last_status = "Saved runtime classifier mappings."
        return true
    end

    classifier.last_status =
        "Classifier save failed: " ..
        tostring(error_text)

    return false
end

function classifier.template(family)
    return copy_table(TEMPLATES[tostring(family or "")])
end

function classifier.templates()
    return copy_table(TEMPLATES)
end

function classifier.build_fingerprint(snapshot)
    snapshot = type(snapshot) == "table" and snapshot or {}

    local parts = {}

    local function add(label, value)
        if useful(value) then
            parts[#parts + 1] =
                label ..
                "=" ..
                clean(value)
        end
    end

    -- Prefer model/configuration-related values. CharacterKindID and stage
    -- are intentionally omitted because BioRand can reuse them.
    add("context", snapshot.context_type)
    add("parameter", snapshot.character_parameter_type)
    add("body_updater", snapshot.body_updater_type)
    add("head_updater", snapshot.head_updater_type)
    add("body_object", snapshot.body_gameobject_name)
    add("head_object", snapshot.head_gameobject_name)
    add("spawn_object", snapshot.spawn_gameobject_name)
    add("costume", snapshot.costume_preset_id)
    add("body_mesh", snapshot.body_mesh_signature)
    add("head_mesh", snapshot.head_mesh_signature)
    add("parameter_signature", snapshot.character_parameter_signature)

    table.sort(parts)

    if #parts == 0 then
        return "unresolved"
    end

    return table.concat(parts, "|")
end

function classifier.resolve(snapshot)
    classifier.ensure_loaded()

    local fingerprint =
        clean(
            snapshot.runtime_fingerprint
            or classifier.build_fingerprint(snapshot)
        )

    local mapping =
        classifier.mappings[fingerprint]

    local mapping_source =
        type(mapping) == "table"
        and tostring(mapping.source or "")
        or ""

    local is_confirmed_mapping =
        mapping_source == "user_confirmed_runtime_fingerprint" or
        mapping_source == "manual"

    if
        type(mapping) ~= "table" or
        is_confirmed_mapping ~= true
    then
        return {
            matched = false,
            fingerprint = fingerprint,
            confidence = 0.0,
            source =
                type(mapping) == "table"
                and "ignored_unconfirmed_mapping"
                or "unresolved"
        }
    end

    local template =
        classifier.template(mapping.family)
        or {}

    for key, value in pairs(mapping) do
        template[key] = value
    end

    template.matched = true
    template.fingerprint = fingerprint
    template.confidence =
        tonumber(mapping.confidence) or 1.0
    template.source =
        tostring(mapping.source or "learned_fingerprint")

    return template
end

function classifier.learn(fingerprint, definition)
    classifier.ensure_loaded()

    local key = clean(fingerprint)

    if key == "unresolved" or key == "unknown" then
        return false, "No stable runtime fingerprint was captured."
    end

    definition =
        type(definition) == "table"
        and definition
        or {}

    local family =
        tostring(definition.family or "")

    if family == "" or family == "unknown" then
        return false, "Set the enemy family before learning."
    end

    classifier.mappings[key] = {
        family = family,
        display_name =
            tostring(
                definition.display_name
                or family
            ),
        description =
            tostring(
                definition.description
                or "Confirmed Appearance"
            ),
        base_xp =
            tonumber(definition.base_xp),
        loot_table =
            tostring(
                definition.loot_table
                or "enemy_standard"
            ),
        elite_profile =
            tostring(
                definition.elite_profile
                or "standard"
            ),
        forced_elite_tier =
            tostring(
                definition.forced_elite_tier
                or "inherit"
            ),
        fixed_xp =
            tonumber(definition.fixed_xp),
        confidence = 1.0,
        source = "user_confirmed_runtime_fingerprint"
    }

    classifier.save()

    return true, "Learned runtime fingerprint."
end

function classifier.forget(fingerprint)
    classifier.ensure_loaded()

    local key = clean(fingerprint)
    classifier.mappings[key] = nil
    classifier.save()

    return true
end

return classifier
