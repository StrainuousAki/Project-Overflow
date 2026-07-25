------------------------------------------------------------
-- Maintenance classification — Build 49.39
-- Module: autorun/project_overflow/shared/math.lua
-- Role: Shared utility, context, constants, logging, or event infrastructure.
-- Status: active infrastructure.
--
-- Compatibility policy:
--   Existing functions, hooks, module paths, and diagnostics are
--   intentionally retained in this maintenance pass.
--   `DEPRECATED` marks a supported legacy path, not removed code.
------------------------------------------------------------

------------------------------------------------------------
-- Project: Overflow — shared/math.lua
-- Shared state, constants, logging, math, and small utilities.
------------------------------------------------------------

local math_helpers = {}

function math_helpers.clamp(value, minimum, maximum)
    value = tonumber(value) or minimum
    return math.max(minimum, math.min(value, maximum))
end

function math_helpers.clamp01(value)
    return math_helpers.clamp(value, 0.0, 1.0)
end

function math_helpers.move_toward(current, target, maximum_delta)
    current = tonumber(current) or 0.0
    target = tonumber(target) or 0.0
    maximum_delta = math.max(0.0, tonumber(maximum_delta) or 0.0)

    if current < target then return math.min(current + maximum_delta, target) end
    if current > target then return math.max(current - maximum_delta, target) end
    return target
end

return math_helpers
