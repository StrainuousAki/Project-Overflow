------------------------------------------------------------
-- Maintenance classification — Build 49.39
-- Module: autorun/project_overflow/systems/enemies/pipeline.lua
-- Role: Enemy identity, classification, persistence, reward, or runtime pipeline.
-- Status: active subsystem.
--
-- Compatibility policy:
--   Existing functions, hooks, module paths, and diagnostics are
--   intentionally retained in this maintenance pass.
--   `DEPRECATED` marks a supported legacy path, not removed code.
------------------------------------------------------------

------------------------------------------------------------
-- Project: Overflow — Enemy Event Pipeline
--
-- Identity is resolved only from confirmed local data. BioRand is
-- diagnostic spawn metadata and can never name, group, tier, or reward
-- an enemy.
------------------------------------------------------------

local dispatcher =
    require("project_overflow.core.event_dispatcher")

local rewards =
    require("project_overflow.systems.enemies.rewards")

local database =
    require("project_overflow.systems.enemies.database")

local classifier =
    require("project_overflow.systems.enemies.classifier")

local biorand_manifest =
    require("project_overflow.systems.enemies.biorand_manifest")

local pipeline = {
    subscribed = false,
    processed_count = 0,
    classification_count = 0,
    reward_count = 0,
    last_error = ""
}

local function snapshot_from(event_entry)
    if type(event_entry) ~= "table" then
        return {}
    end

    return type(event_entry.snapshot) == "table"
        and event_entry.snapshot
        or {}
end

local function observe_database(event_entry)
    local snapshot = snapshot_from(event_entry)

    local ok, status =
        database.observe_enemy_id(
            snapshot.kind_id,
            snapshot.spawn_id,
            false
        )

    event_entry.database_observed = ok == true
    event_entry.database_observer_status = status

    if ok == true and status == "Registered new enemy_id." then
        database.save()
    end
end

local function resolve_classification(event_entry)
    local snapshot = snapshot_from(event_entry)

    local manifest_candidate =
        biorand_manifest.resolve(snapshot)

    local runtime_fingerprint =
        snapshot.runtime_fingerprint
        or classifier.build_fingerprint(snapshot)

    snapshot.runtime_fingerprint =
        runtime_fingerprint

    local classification =
        classifier.resolve(snapshot)

    local appearance =
        database.get_appearance(
            snapshot.kind_id,
            snapshot.spawn_id
        )

    if
        appearance ~= nil and
        appearance.user_confirmed == true
    then
        classification = {
            matched = true,
            authoritative = true,
            source = "user_confirmed_appearance",
            confidence = 1.0,
            fingerprint = runtime_fingerprint,
            display_name = appearance.display_name,
            description = appearance.description,
            family = appearance.family,
            base_xp = appearance.base_xp,
            fixed_xp = appearance.fixed_xp,
            loot_table = appearance.loot_table,
            elite_profile = appearance.elite_profile,
            forced_elite_tier =
                appearance.forced_elite_tier
                or "inherit"
        }
    end

    snapshot.biorand_manifest_result =
        manifest_candidate

    snapshot.runtime_classification =
        classification

    event_entry.manifest = manifest_candidate
    event_entry.classification = classification
    event_entry.runtime_fingerprint = runtime_fingerprint

    -- Never write appearance identity from a runtime or BioRand guess.
    pipeline.classification_count =
        pipeline.classification_count + 1
end

local function resolve_rewards(event_entry)
    local snapshot = snapshot_from(event_entry)

    event_entry.reward = rewards.resolve(snapshot)
    pipeline.reward_count = pipeline.reward_count + 1
end

local function finalize_entry(event_entry)
    event_entry.completed_at = os.clock()
    event_entry.completed = true
    pipeline.processed_count = pipeline.processed_count + 1
end

function pipeline.ensure_subscribed()
    if pipeline.subscribed then
        return true
    end

    dispatcher.subscribe(
        "enemy_killed",
        "enemy_database_observer",
        observe_database,
        300
    )

    dispatcher.subscribe(
        "enemy_killed",
        "enemy_classifier",
        resolve_classification,
        200
    )

    dispatcher.subscribe(
        "enemy_killed",
        "enemy_rewards",
        resolve_rewards,
        100
    )

    dispatcher.subscribe(
        "enemy_killed",
        "enemy_pipeline_finalizer",
        finalize_entry,
        -100
    )

    pipeline.subscribed = true
    return true
end

pipeline.ensure_subscribed()

return pipeline
