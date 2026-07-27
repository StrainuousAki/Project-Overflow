------------------------------------------------------------
-- Maintenance classification — Build 49.39
-- Module: autorun/project_overflow.lua
-- Role: Primary REFramework bootstrap and callback coordinator.
-- Status: active entry point.
--
-- Compatibility policy:
--   Existing functions, hooks, module paths, and diagnostics are
--   intentionally retained in this maintenance pass.
--   `DEPRECATED` marks a supported legacy path, not removed code.
------------------------------------------------------------

-- This marker survives REFramework's script refresh within the current Lua
-- runtime. It distinguishes refreshing project_overflow.lua from a fresh game
-- or mod startup.
local refresh_marker = "__project_overflow_runtime_loaded"
local script_refresh =
    rawget(_G, refresh_marker) == true
_G[refresh_marker] = true

local ctx = require("project_overflow.shared.context")
local hp = require("project_overflow.systems.health.core")
local hud = require("project_overflow.hud")
local circle = require("project_overflow.circle")
local gui = require("project_overflow.gui_inspector")
local ui = require("project_overflow.ui.main")
local overlay = require("project_overflow.render.renderer")
local methods = require("project_overflow.methods")
local updater = require("project_overflow.systems.health.runtime")
local shader_probe = require("project_overflow.shader_probe")
local inventory_progression =
    require("project_overflow.ui.inventory_progression")
local game_save_sync =
    require("project_overflow.systems.player.game_save_sync")
local xp = require("project_overflow.xp.init")
local enemy_pipeline =
    require("project_overflow.systems.enemies.pipeline")
local enemy_rewards =
    require("project_overflow.systems.enemies.rewards")
local enemy_kill_probe =
    require("project_overflow.engine.enemy_kill_probe")

-- Install release-critical systems before frame and UI callbacks begin.
-- Every installer is idempotent, so script reloads cannot stack duplicate hooks.
enemy_pipeline.ensure_subscribed()
enemy_rewards.initialize()
enemy_kill_probe.install(ctx)
hp.install(ctx)
hud.install(ctx)
shader_probe.install(ctx)
inventory_progression.install()
game_save_sync.install(ctx, hp, { script_refresh = script_refresh })

-- RE Engine type definitions can occasionally become available one or two
-- frames after Lua initialization. Retry only failed death-hook installation;
-- successful hooks are never installed twice.
local next_death_hook_retry = 0.0

-- Intentionally disabled while the Circle hooks remain experimental.
-- circle.install(ctx)

local last_update_time = os.clock()

-- Draw the configuration window and its invisible input-capture surface.
re.on_draw_ui(function()
    local ui_started = os.clock()

    ui.draw(
        ctx,
        hp,
        hud,
        circle,
        gui,
        methods,
        shader_probe
    )
    -- Keep an ImGui-owned surface over the painted panel while the game menu
    -- owns the native cursor. This makes ImGui request mouse capture even when
    -- Project: Overflow's configuration window is collapsed.
    if
        inventory_progression.draw_input_layer ~= nil
        and inventory_progression.is_input_layer_needed ~= nil
        and inventory_progression.is_input_layer_needed()
    then
        inventory_progression.draw_input_layer()
    end

    if ctx.performance ~= nil then
        ctx.performance.ui_ms =
            (os.clock() - ui_started) * 1000.0
    end
end)

-- Keep gameplay state, overlays, XP, and the attaché-case panel in sync each frame.
re.on_frame(function()
    local now = os.clock()

    if
        enemy_kill_probe.installed ~= true and
        now >= next_death_hook_retry
    then
        enemy_kill_probe.install(ctx)
        next_death_hook_retry = now + 1.0
    end

    local save_started = os.clock()
    game_save_sync.update()
    if ctx.performance ~= nil then
        ctx.performance.save_sync_ms =
            (os.clock() - save_started) * 1000.0
    end

    local delta_time = now - last_update_time
    last_update_time = now

    delta_time =
        math.max(
            0.0,
            math.min(delta_time, 0.1)
        )

    local health_started = os.clock()
    updater.update(
        ctx,
        hp,
        delta_time
    )
    if ctx.performance ~= nil then
        ctx.performance.health_runtime_ms =
            (os.clock() - health_started) * 1000.0
    end

    local overlay_started = os.clock()
    overlay.draw(ctx)
    if ctx.performance ~= nil then
        ctx.performance.overlay_ms =
            (os.clock() - overlay_started) * 1000.0
    end

    local xp_started = os.clock()
    xp.draw(ctx)
    if ctx.performance ~= nil then
        ctx.performance.xp_ms =
            (os.clock() - xp_started) * 1000.0
    end

    local progression_started = os.clock()
    inventory_progression.draw()
    if ctx.performance ~= nil then
        ctx.performance.progression_ms =
            (os.clock() - progression_started) * 1000.0
    end
end)
