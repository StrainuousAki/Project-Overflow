------------------------------------------------------------
-- Maintenance classification — Build 49.39
-- Module: autorun/project_overflow/xp/visibility.lua
-- Role: HUD, XP, material, geometry, or rendering implementation.
-- Status: active renderer.
--
-- Compatibility policy:
--   Existing functions, hooks, module paths, and diagnostics are
--   intentionally retained in this maintenance pass.
--   `DEPRECATED` marks a supported legacy path, not removed code.
------------------------------------------------------------

------------------------------------------------------------
-- Project: Overflow — xp/visibility.lua
-- XP-ring state, geometry, visibility, material, and rendering.
------------------------------------------------------------

local visibility = {}

function visibility.resolve(ctx, state)
    if state.enabled ~= true and state.preview_enabled ~= true then
        return false, 0.0
    end

    if state.preview_enabled == true then
        return true, 1.0
    end

    if state.follow_native_hp_visibility == true then
        -- The XP ring is an extension of the native HP HUD, not a standalone
        -- loading or menu indicator. Unknown visibility is treated as hidden
        -- until VitalGuiBehavior confirms that the native HP bar is drawing.
        if ctx.state.native_hp_bar_visibility_known ~= true then
            return false, 0.0
        end

        if ctx.state.native_hp_bar_visible ~= true then
            return false, 0.0
        end
    end

    return true, 1.0
end

return visibility
