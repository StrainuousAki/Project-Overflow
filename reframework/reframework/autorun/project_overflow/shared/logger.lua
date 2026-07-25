------------------------------------------------------------
-- Maintenance classification — Build 49.39
-- Module: autorun/project_overflow/shared/logger.lua
-- Role: Shared utility, context, constants, logging, or event infrastructure.
-- Status: active infrastructure.
--
-- Compatibility policy:
--   Existing functions, hooks, module paths, and diagnostics are
--   intentionally retained in this maintenance pass.
--   `DEPRECATED` marks a supported legacy path, not removed code.
------------------------------------------------------------

------------------------------------------------------------
-- Project: Overflow — shared/logger.lua
-- Shared state, constants, logging, math, and small utilities.
------------------------------------------------------------

local logger = {
    verbose = false,
    prefix = "[Project: Overflow] "
}

function logger.info(message) log.info(logger.prefix .. tostring(message)) end
function logger.warn(message) log.warn(logger.prefix .. tostring(message)) end
function logger.error(message) log.error(logger.prefix .. tostring(message)) end

function logger.debug(message)
    if logger.verbose == true then logger.info(message) end
end

return logger
