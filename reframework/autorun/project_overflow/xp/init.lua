------------------------------------------------------------
-- Maintenance classification — Build 49.39
-- Module: autorun/project_overflow/xp/init.lua
-- Role: HUD, XP, material, geometry, or rendering implementation.
-- Status: active renderer.
--
-- Compatibility policy:
--   Existing functions, hooks, module paths, and diagnostics are
--   intentionally retained in this maintenance pass.
--   `DEPRECATED` marks a supported legacy path, not removed code.
------------------------------------------------------------

------------------------------------------------------------
-- Project: Overflow — xp/init.lua
-- XP-ring state, geometry, visibility, material, and rendering.
------------------------------------------------------------

local xp = {
    renderer = require("project_overflow.xp.renderer"),
    controls = require("project_overflow.xp.controls"),
    source = require("project_overflow.xp.source"),
    state = require("project_overflow.xp.state")
}

function xp.draw(ctx)
    xp.renderer.draw(ctx)
end

function xp.draw_controls()
    local ok, error_message = pcall(xp.controls.draw)
    if not ok then
        xp.state.last_error = tostring(error_message)
        xp.state.status = "XP controls error."
    end
end

return xp
