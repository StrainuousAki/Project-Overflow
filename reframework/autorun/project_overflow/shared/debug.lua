------------------------------------------------------------
-- Maintenance classification — Build 49.39
-- Module: autorun/project_overflow/shared/debug.lua
-- Role: Shared utility, context, constants, logging, or event infrastructure.
-- Status: active infrastructure.
--
-- Compatibility policy:
--   Existing functions, hooks, module paths, and diagnostics are
--   intentionally retained in this maintenance pass.
--   `DEPRECATED` marks a supported legacy path, not removed code.
------------------------------------------------------------

------------------------------------------------------------
-- Project: Overflow — Developer Support
--
-- Keeps release and developer behavior easy to distinguish. The
-- diagnostic code remains available, while release builds leave it
-- disabled unless the user explicitly enables Developer Mode.
------------------------------------------------------------

local debug_tools = {
    enabled_by_default = false,
    verbose_logging = false
}

function debug_tools.is_enabled(ctx)
    return
        ctx ~= nil and
        ctx.state ~= nil and
        ctx.state.developer_mode == true
end

function debug_tools.log(message)
    if debug_tools.verbose_logging ~= true then
        return
    end

    log.info(
        "[Project: Overflow] " ..
        tostring(message)
    )
end

return debug_tools
