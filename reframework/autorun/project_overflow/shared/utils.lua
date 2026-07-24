------------------------------------------------------------
-- Maintenance classification — Build 49.39
-- Module: autorun/project_overflow/shared/utils.lua
-- Role: Shared utility, context, constants, logging, or event infrastructure.
-- Status: active infrastructure.
--
-- Compatibility policy:
--   Existing functions, hooks, module paths, and diagnostics are
--   intentionally retained in this maintenance pass.
--   `DEPRECATED` marks a supported legacy path, not removed code.
------------------------------------------------------------

------------------------------------------------------------
-- Project: Overflow — Shared Utilities
--
-- Lightweight helpers that are safe for every module to use.
-- Existing modules can migrate to these gradually without changing
-- current behavior all at once.
------------------------------------------------------------

local utils = {}

function utils.clamp(value, minimum, maximum)
    value = tonumber(value) or minimum
    minimum = tonumber(minimum) or value
    maximum = tonumber(maximum) or value

    return math.max(minimum, math.min(value, maximum))
end

function utils.clamp01(value)
    return utils.clamp(value, 0.0, 1.0)
end

function utils.move_toward(current, target, max_delta)
    current = tonumber(current) or 0.0
    target = tonumber(target) or 0.0
    max_delta = math.max(0.0, tonumber(max_delta) or 0.0)

    if current < target then
        return math.min(current + max_delta, target)
    end

    if current > target then
        return math.max(current - max_delta, target)
    end

    return target
end

function utils.safe_tostring(value, fallback)
    local ok, text = pcall(tostring, value)

    if ok then
        return text
    end

    return fallback or "<unreadable>"
end

return utils
