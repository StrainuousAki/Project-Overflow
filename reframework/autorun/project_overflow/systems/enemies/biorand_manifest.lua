------------------------------------------------------------
-- Maintenance classification — Build 49.39
-- Module: autorun/project_overflow/systems/enemies/biorand_manifest.lua
-- Role: Enemy identity, classification, persistence, reward, or runtime pipeline.
-- Status: active subsystem.
--
-- Compatibility policy:
--   Existing functions, hooks, module paths, and diagnostics are
--   intentionally retained in this maintenance pass.
--   `DEPRECATED` marks a supported legacy path, not removed code.
------------------------------------------------------------

------------------------------------------------------------
-- Project: Overflow — BioRand Seed Manifest
--
-- Parses BioRand's output_leon.log and finds the nearest spawn record
-- using stage + world position. Results are diagnostic metadata only:
-- they never identify, group, tier, or reward an enemy.
------------------------------------------------------------

local manifest = {
    source_path =
        "reframework/data/project_overflow/manifests/output_leon.log",

    source_candidates = {
        "reframework/data/project_overflow/manifests/output_leon.log",
        "./reframework/data/project_overflow/manifests/output_leon.log",
        "data/project_overflow/manifests/output_leon.log",
        "./data/project_overflow/manifests/output_leon.log",
        "project_overflow/manifests/output_leon.log"
    },

    seed = "unknown",
    campaign = "unknown",
    generated_at = "unknown",

    records = {},
    by_stage = {},

    loaded = false,
    load_attempted = false,
    revision = 0,
    last_status = "Not loaded.",
    last_error = "",

    max_match_distance = 4.0,
    ambiguity_distance = 0.75
}

local FAMILY_TEMPLATES = {
    villager = {
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

    soldier = {
        display_name = "Islander",
        family = "islander",
        base_xp = 50,
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

    chainsaw = {
        display_name = "Chainsaw Enemy",
        family = "chainsaw_bosses",
        base_xp = 250,
        loot_table = "enemy_elite",
        elite_profile = "boss",
        forced_elite_tier = "boss"
    },

    chainsaw_mad = {
        display_name = "Mad Chainsaw Enemy",
        family = "chainsaw_bosses",
        base_xp = 300,
        loot_table = "enemy_elite",
        elite_profile = "boss",
        forced_elite_tier = "boss"
    },

    novistador = {
        display_name = "Novistador",
        family = "novistador",
        base_xp = 50,
        loot_table = "enemy_standard",
        elite_profile = "standard",
        forced_elite_tier = "inherit"
    },

    colmillos = {
        display_name = "Colmillos",
        family = "wolf",
        base_xp = 50,
        loot_table = "enemy_standard",
        elite_profile = "standard",
        forced_elite_tier = "inherit"
    },

    armadura = {
        display_name = "Living Armor",
        family = "living_armor",
        base_xp = 250,
        loot_table = "enemy_elite",
        elite_profile = "standard",
        forced_elite_tier = "elite"
    },

    arana = {
        display_name = "Spider Plaga",
        family = "plagas",
        base_xp = 10,
        loot_table = "enemy_standard",
        elite_profile = "no_elites",
        forced_elite_tier = "normal"
    },

    regenerador = {
        display_name = "Regenerator",
        family = "regenerator",
        base_xp = 500,
        loot_table = "enemy_elite",
        elite_profile = "legendary",
        forced_elite_tier = "elite"
    },

    garrador = {
        display_name = "Garrador",
        family = "garrador",
        base_xp = 350,
        loot_table = "enemy_elite",
        elite_profile = "boss",
        forced_elite_tier = "boss"
    },

    el_gigante = {
        display_name = "El Gigante",
        family = "bosses",
        base_xp = 1000,
        loot_table = "boss",
        elite_profile = "boss",
        forced_elite_tier = "boss"
    },

    verdugo = {
        display_name = "Verdugo",
        family = "bosses",
        base_xp = 1250,
        loot_table = "boss",
        elite_profile = "boss",
        forced_elite_tier = "boss"
    },

    u3 = {
        display_name = "U-3",
        family = "bosses",
        base_xp = 1000,
        loot_table = "boss",
        elite_profile = "boss",
        forced_elite_tier = "boss"
    },

    pesanta = {
        display_name = "Pesanta",
        family = "bosses",
        base_xp = 1000,
        loot_table = "boss",
        elite_profile = "boss",
        forced_elite_tier = "boss"
    },

    cow = {
        display_name = "Cow",
        family = "wildlife",
        base_xp = 5,
        loot_table = "enemy_standard",
        elite_profile = "no_elites",
        forced_elite_tier = "normal"
    },

    wolf = {
        display_name = "Wolf",
        family = "wolf",
        base_xp = 20,
        loot_table = "enemy_standard",
        elite_profile = "no_elites",
        forced_elite_tier = "normal"
    },

    viper = {
        display_name = "Viper",
        family = "wildlife",
        base_xp = 5,
        loot_table = "enemy_standard",
        elite_profile = "no_elites",
        forced_elite_tier = "normal"
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

local function trim(value)
    return tostring(value or "")
        :gsub("^%s+", "")
        :gsub("%s+$", "")
end

local function parse_enemy_line(line, scene)
    local uuid,
          ctxid,
          spawn_name,
          stage_id,
          x,
          y,
          z,
          family,
          model_hash,
          remainder =
        line:match(
            "^%s*([%x%-]+)%s+" ..
            "CTXID%(([^%)]+)%)%s+" ..
            "(.+)%s+" ..
            "(%d+)%s+" ..
            "([%-%.%d]+)%s+" ..
            "([%-%.%d]+)%s+" ..
            "([%-%.%d]+)%s+" ..
            "([%w_]+)%s+" ..
            "([%d%*]+)%s+" ..
            "(.*)$"
        )

    if uuid == nil then
        return nil
    end

    remainder = trim(remainder)

    local generated_id =
        remainder:match("%s([%d]+)%s")

    if generated_id == nil then
        generated_id =
            remainder:match("^([%d]+)")
    end

    return {
        uuid = uuid,
        ctxid = ctxid,
        scene = tostring(scene or "unknown"),
        spawn_name = trim(spawn_name),
        stage_id = tostring(stage_id),
        x = tonumber(x),
        y = tonumber(y),
        z = tonumber(z),
        family = tostring(family),
        model_hash = tostring(model_hash),
        generated_id = tostring(generated_id or "unknown"),
        raw_tail = remainder
    }
end

local function add_record(record)
    manifest.records[#manifest.records + 1] = record

    local stage_key =
        tostring(record.stage_id or "unknown")

    manifest.by_stage[stage_key] =
        manifest.by_stage[stage_key]
        or {}

    manifest.by_stage[stage_key][
        #manifest.by_stage[stage_key] + 1
    ] = record
end

function manifest.load(path)
    manifest.load_attempted = true

    local source_path =
        tostring(path or manifest.source_path)

    manifest.records = {}
    manifest.by_stage = {}
    manifest.last_error = ""
    manifest.seed = "unknown"
    manifest.campaign = "unknown"
    manifest.generated_at = "unknown"

    local file = nil
    local open_error = nil
    local opened_path = nil

    local candidates = {}

    if path ~= nil then
        candidates[#candidates + 1] = source_path
    else
        for _, candidate in ipairs(manifest.source_candidates) do
            candidates[#candidates + 1] = candidate
        end
    end

    for _, candidate in ipairs(candidates) do
        file, open_error = io.open(candidate, "r")

        if file ~= nil then
            opened_path = candidate
            break
        end
    end

    if file == nil then
        manifest.loaded = false
        manifest.last_error =
            tostring(open_error or "Unable to open file.")
        manifest.last_status =
            "BioRand log not found in any supported relative path."
        return false
    end

    source_path = opened_path

    local in_enemy_section = false
    local current_scene = "unknown"

    for line in file:lines() do
        local seed =
            line:match("^Seed%s*=%s*(.+)$")

        if seed ~= nil then
            manifest.seed = trim(seed)
        end

        local campaign =
            line:match("^Campaign%s*=%s*(.+)$")

        if campaign ~= nil then
            manifest.campaign = trim(campaign)
        end

        local generated =
            line:match("^Generated at%s+(.+)$")

        if generated ~= nil then
            manifest.generated_at = trim(generated)
        end

        if trim(line) == "Enemy" then
            in_enemy_section = true
        elseif in_enemy_section then
            if line:match("^%-%-%-%-%-") ~= nil then
                -- Ignore section separators.
            elseif line:match("^%s+[%w_]+%.scn%.%d+%s*$") ~= nil then
                current_scene = trim(line)
            elseif line:match("^%s*[%x%-]+%s+CTXID") ~= nil then
                local record =
                    parse_enemy_line(
                        line,
                        current_scene
                    )

                if record ~= nil then
                    add_record(record)
                end
            elseif line:match("^%S") ~= nil and #manifest.records > 0 then
                -- A new top-level section begins after Enemy.
                break
            end
        end
    end

    file:close()

    manifest.loaded = #manifest.records > 0
    manifest.revision = manifest.revision + 1

    if manifest.loaded then
        manifest.source_path = source_path
        manifest.last_status =
            string.format(
                "Loaded BioRand seed %s (%d enemy records).",
                manifest.seed,
                #manifest.records
            )
        return true
    end

    manifest.last_status =
        "BioRand log opened, but no enemy records were parsed."

    return false
end

local function distance_squared(record, position)
    local dx = (tonumber(record.x) or 0) - (tonumber(position.x) or 0)
    local dy = (tonumber(record.y) or 0) - (tonumber(position.y) or 0)
    local dz = (tonumber(record.z) or 0) - (tonumber(position.z) or 0)

    return dx * dx + dy * dy + dz * dz
end

function manifest.resolve(snapshot)
    if
        manifest.loaded ~= true and
        manifest.load_attempted ~= true
    then
        manifest.load()
    end

    if manifest.loaded ~= true then
        return {
            matched = false,
            source = "biorand_manifest_not_loaded",
            confidence = 0.0,
            error = manifest.last_error
        }
    end

    snapshot = type(snapshot) == "table" and snapshot or {}

    local stage_key =
        tostring(snapshot.stage_id or "unknown")

    local position =
        snapshot.world_position

    if
        type(position) ~= "table" or
        tonumber(position.x) == nil or
        tonumber(position.y) == nil or
        tonumber(position.z) == nil
    then
        return {
            matched = false,
            source = "runtime_position_unavailable",
            confidence = 0.0
        }
    end

    local candidates =
        manifest.by_stage[stage_key]
        or {}

    local ranked = {}

    for _, record in ipairs(candidates) do
        ranked[#ranked + 1] = {
            record = record,
            distance_squared =
                distance_squared(
                    record,
                    position
                )
        }
    end

    table.sort(
        ranked,
        function(left, right)
            return
                left.distance_squared <
                right.distance_squared
        end
    )

    if #ranked == 0 then
        return {
            matched = false,
            source = "no_stage_candidates",
            confidence = 0.0
        }
    end

    local nearest = ranked[1]
    local distance =
        math.sqrt(
            nearest.distance_squared
        )

    if distance > manifest.max_match_distance then
        return {
            matched = false,
            source = "nearest_record_too_far",
            confidence = 0.0,
            nearest_distance = distance,
            candidate_count = #ranked
        }
    end

    if #ranked > 1 then
        local second_distance =
            math.sqrt(
                ranked[2].distance_squared
            )

        if
            math.abs(second_distance - distance) <
            manifest.ambiguity_distance
        then
            return {
                matched = false,
                source = "ambiguous_nearby_records",
                confidence = 0.0,
                nearest_distance = distance,
                second_distance = second_distance,
                candidate_count = #ranked
            }
        end
    end

    local record = nearest.record
    local template =
        copy_table(
            FAMILY_TEMPLATES[record.family]
            or {
                display_name = record.family,
                family = record.family,
                base_xp = 10,
                loot_table = "enemy_standard",
                elite_profile = "standard",
                forced_elite_tier = "inherit"
            }
        )

    template.matched = false
    template.candidate = true
    template.authoritative = false
    template.source = "biorand_spawn_candidate"
    template.confidence = 0.0
    template.seed = manifest.seed
    template.manifest_record = record
    template.nearest_distance = distance
    template.match_distance = distance
    template.candidate_count = #ranked
    template.candidate_family =
        tostring(record.family or "unknown")
    template.candidate_display_name =
        tostring(template.display_name or "Unknown Candidate")
    template.description =
        "Nearest BioRand spawn candidate; identity not accepted."

    return template
end

function manifest.templates()
    return copy_table(FAMILY_TEMPLATES)
end

return manifest
