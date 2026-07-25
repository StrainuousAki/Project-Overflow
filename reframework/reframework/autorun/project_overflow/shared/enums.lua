------------------------------------------------------------
-- Maintenance classification — Build 49.39
-- Module: autorun/project_overflow/shared/enums.lua
-- Role: Shared utility, context, constants, logging, or event infrastructure.
-- Status: active infrastructure.
--
-- Compatibility policy:
--   Existing functions, hooks, module paths, and diagnostics are
--   intentionally retained in this maintenance pass.
--   `DEPRECATED` marks a supported legacy path, not removed code.
------------------------------------------------------------

------------------------------------------------------------
-- Project: Overflow — Shared Enums
--
-- Names important engine and project states in one place. New RPG
-- systems should add stable shared enums here instead of scattering
-- numeric values across modules.
------------------------------------------------------------

local enums = {}

enums.native_hud_step = {
    WAIT = 0,
    MOVE = 1,
    PRE_END = 2,
    END_STEP = 3,
    WAIT_END = 4
}

enums.condition_state = {
    INVALID = -1,
    FINE = 0,
    FINE_TO_DANGER = 1,
    FINE_TO_CAUTION = 2,
    CAUTION = 3,
    CAUTION_TO_FINE = 4,
    CAUTION_TO_DANGER = 5,
    DANGER = 6,
    DANGER_TO_FINE = 7,
    DANGER_TO_CAUTION = 8
}

function enums.name_of(enum_table, value, fallback)
    for name, enum_value in pairs(enum_table) do
        if enum_value == value then
            return name
        end
    end

    return fallback or tostring(value)
end

return enums
