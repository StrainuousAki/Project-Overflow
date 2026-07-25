------------------------------------------------------------
-- Maintenance classification — Build 49.39
-- Module: autorun/project_overflow/systems/enemies/registry.lua
-- Role: Enemy identity, classification, persistence, reward, or runtime pipeline.
-- Status: active subsystem.
--
-- Compatibility policy:
--   Existing functions, hooks, module paths, and diagnostics are
--   intentionally retained in this maintenance pass.
--   `DEPRECATED` marks a supported legacy path, not removed code.
------------------------------------------------------------

------------------------------------------------------------
-- Project: Overflow — Enemy Runtime Registry
--
-- The registry is the single owner of mutable enemy runtime state.
-- Engine probes submit immutable-style snapshots here; the registry
-- creates an event entry and emits enemy_killed for downstream systems.
------------------------------------------------------------

local dispatcher =
    require("project_overflow.core.event_dispatcher")

local pipeline =
    require("project_overflow.systems.enemies.pipeline")

local registry = {
    discovered = {},
    discovered_order = {},
    kill_history = {},
    runtime_entries = {},
    total_kills = 0,
    max_history = 10,
    max_discovered = 10,
    last_event_result = nil,
    last_event_error = ""
}

local function clean(value)
    local text = tostring(value or "unknown")

    if text == "" or text == "nil" then
        return "unknown"
    end

    return text
end

local function observation_key(kind_id, spawn_id, context_type)
    local kind = clean(kind_id)
    local spawn = clean(spawn_id)

    if kind ~= "unknown" and spawn ~= "unknown" then
        return kind .. "|" .. spawn
    end

    if kind ~= "unknown" then
        return kind .. "|unresolved"
    end

    local context = clean(context_type)

    if context ~= "unknown" and spawn ~= "unknown" then
        return context .. "|" .. spawn
    end

    return context
end

local function runtime_key(snapshot)
    local pointer = clean(snapshot.context_ptr)

    if pointer ~= "unknown" then
        return pointer
    end

    return table.concat(
        {
            clean(snapshot.kind_id),
            clean(snapshot.spawn_id),
            clean(snapshot.stage_id),
            clean(
                snapshot.spawn_segment_id ~= "unknown"
                and snapshot.spawn_segment_id
                or snapshot.segment_id
            ),
            tostring(os.clock())
        },
        "|"
    )
end

local function persistent_snapshot(source)
    local result = {}

    for key, value in pairs(source or {}) do
        -- Managed runtime references are intentionally kept only on the
        -- short-lived event entry. They are unsafe to retain after teardown.
        if key ~= "runtime" then
            result[key] = value
        end
    end

    return result
end

local function touch_discovered_record(key)
    -- Discovered Enemy Records is a rolling diagnostic cache. Repeated enemy
    -- types move to the newest position, and old snapshots are released once
    -- the cache reaches its limit.
    for index = #registry.discovered_order, 1, -1 do
        if registry.discovered_order[index] == key then
            table.remove(registry.discovered_order, index)
            break
        end
    end

    registry.discovered_order[#registry.discovered_order + 1] = key

    local limit = math.max(
        1,
        math.floor(tonumber(registry.max_discovered) or 10)
    )

    while #registry.discovered_order > limit do
        local oldest_key = table.remove(registry.discovered_order, 1)
        registry.discovered[oldest_key] = nil
    end
end

function registry.make_key(entry)
    entry = type(entry) == "table" and entry or {}

    return observation_key(
        entry.kind_id,
        entry.spawn_id,
        entry.context_type
    )
end

function registry.record_kill(snapshot)
    snapshot = type(snapshot) == "table" and snapshot or {}
    pipeline.ensure_subscribed()

    local key = registry.make_key(snapshot)
    local existing = registry.discovered[key]
    local now = os.clock()

    if existing == nil then
        existing = {
            key = key,
            kind_id = clean(snapshot.kind_id),
            kind_id_raw = clean(snapshot.kind_id_raw),
            spawn_id = clean(snapshot.spawn_id),
            context_type = clean(snapshot.context_type),
            first_seen = now,
            last_seen = now,
            encounters = 0,
            kills = 0,
            stage_ids = {},
            segment_ids = {},
            last_snapshot = {},
            last_event = nil,
            last_reward = nil,
            last_downstream_error = ""
        }

        registry.discovered[key] = existing
    end

    touch_discovered_record(key)

    existing.kills = existing.kills + 1
    existing.encounters = existing.encounters + 1
    existing.last_seen = now
    existing.kind_id = clean(snapshot.kind_id)
    existing.kind_id_raw = clean(snapshot.kind_id_raw)
    existing.spawn_id = clean(snapshot.spawn_id)
    existing.context_type = clean(snapshot.context_type)

    existing.stage_ids[clean(snapshot.stage_id)] = true
    existing.segment_ids[
        clean(
            snapshot.spawn_segment_id ~= "unknown"
            and snapshot.spawn_segment_id
            or snapshot.segment_id
        )
    ] = true

    local stored_snapshot = persistent_snapshot(snapshot)
    existing.last_snapshot = stored_snapshot

    registry.total_kills = registry.total_kills + 1

    local event_entry = {
        id = registry.total_kills,
        event_name = "enemy_killed",
        runtime_key = runtime_key(snapshot),
        observation_key = key,
        created_at = now,
        completed = false,

        snapshot = stored_snapshot,
        runtime = type(snapshot.runtime) == "table"
            and snapshot.runtime
            or {},

        classification = nil,
        manifest = nil,
        reward = nil,
        runtime_fingerprint = nil,
        errors = {}
    }

    registry.runtime_entries[event_entry.runtime_key] = event_entry
    existing.last_event = event_entry

    local event_result =
        dispatcher.emit(
            "enemy_killed",
            event_entry
        )

    registry.last_event_result = event_result
    registry.last_event_error = ""

    if event_result.error_count > 0 then
        local parts = {}

        for _, error_entry in ipairs(event_result.errors) do
            parts[#parts + 1] =
                tostring(error_entry.listener)
                .. ": "
                .. tostring(error_entry.error)
        end

        registry.last_event_error = table.concat(parts, " | ")
        existing.last_downstream_error = registry.last_event_error
        event_entry.errors = event_result.errors
    else
        existing.last_downstream_error = ""
    end

    existing.runtime_fingerprint =
        event_entry.runtime_fingerprint
        or stored_snapshot.runtime_fingerprint

    existing.runtime_classification =
        event_entry.classification
        or stored_snapshot.runtime_classification

    existing.last_reward = event_entry.reward
    existing.last_snapshot = stored_snapshot

    -- Keep only the ten most recent completed death events. The lifetime
    -- counters remain independent, while the oldest retained event is removed
    -- as soon as a new event would exceed the rolling-history limit.
    registry.kill_history[#registry.kill_history + 1] = event_entry

    local history_limit =
        math.max(
            1,
            math.floor(
                tonumber(registry.max_history) or 10
            )
        )

    while #registry.kill_history > history_limit do
        table.remove(registry.kill_history, 1)
    end

    -- Runtime references have served their purpose once synchronous
    -- listeners finish. Release them instead of retaining torn-down objects.
    event_entry.runtime = {}
    registry.runtime_entries[event_entry.runtime_key] = nil

    return existing, event_entry
end

function registry.clear()
    registry.discovered = {}
    registry.discovered_order = {}
    registry.kill_history = {}
    registry.runtime_entries = {}
    registry.total_kills = 0
    registry.last_event_result = nil
    registry.last_event_error = ""
end

return registry
