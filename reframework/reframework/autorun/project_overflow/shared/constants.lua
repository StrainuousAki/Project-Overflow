------------------------------------------------------------
-- Maintenance classification — Build 49.39
-- Module: autorun/project_overflow/shared/constants.lua
-- Role: Shared utility, context, constants, logging, or event infrastructure.
-- Status: active infrastructure.
--
-- Compatibility policy:
--   Existing functions, hooks, module paths, and diagnostics are
--   intentionally retained in this maintenance pass.
--   `DEPRECATED` marks a supported legacy path, not removed code.
------------------------------------------------------------

------------------------------------------------------------
-- Project: Overflow — shared/constants.lua
-- Shared state, constants, logging, math, and small utilities.
------------------------------------------------------------

local constants = {
    native = {
        default_max_hp = 1260,
        vanilla_max_hp_cap = 2500,
        hidden_hud_step = 4
    },
    overlay = {
        reference_width = 2560.0,
        reference_height = 1440.0
    },
    rpg = {
        starting_level = 1,
        attributes_per_level = 3,
        skill_points_per_level = 1
    }
}

return constants
