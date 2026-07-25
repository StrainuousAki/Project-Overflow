------------------------------------------------------------
-- Maintenance classification — Build 49.39
-- Module: autorun/project_overflow/systems/enemies/database_reset.lua
-- Role: Enemy identity, classification, persistence, reward, or runtime pipeline.
-- Status: active subsystem.
--
-- Compatibility policy:
--   Existing functions, hooks, module paths, and diagnostics are
--   intentionally retained in this maintenance pass.
--   `DEPRECATED` marks a supported legacy path, not removed code.
------------------------------------------------------------

------------------------------------------------------------
-- Project: Overflow — Appearance Database Reset Utility
------------------------------------------------------------

local database =
    require("project_overflow.systems.enemies.database")

local reset = {}

function reset.run(save_now)
    database.ensure_loaded()

    for _, entry in pairs(database.overrides or {}) do
        if type(entry) == "table" then
            entry.appearances = {}
            entry.enemies = nil
            entry.variants = nil
            entry.observations = nil
            entry.appearance_schema_version =
                database.appearance_schema_version
        end
    end

    if save_now ~= false then
        return database.save()
    end

    return true
end

return reset
