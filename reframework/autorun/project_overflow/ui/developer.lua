------------------------------------------------------------
-- Maintenance classification — Build 49.39
-- Module: autorun/project_overflow/ui/developer.lua
-- Role: ImGui or native-overlay presentation and diagnostics.
-- Status: active UI.
--
-- Compatibility policy:
--   Existing functions, hooks, module paths, and diagnostics are
--   intentionally retained in this maintenance pass.
--   `DEPRECATED` marks a supported legacy path, not removed code.
------------------------------------------------------------

------------------------------------------------------------
-- Project: Overflow — ui/developer.lua
-- ImGui panels and attaché-case presentation.
------------------------------------------------------------

local developer = {}

function developer.enabled(ctx)
    return ctx ~= nil and ctx.state ~= nil and ctx.state.developer_mode == true
end

return developer
