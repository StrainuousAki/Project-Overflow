------------------------------------------------------------
-- Maintenance classification — Build 49.39
-- Module: autorun/project_overflow/init.lua
-- Role: Project: Overflow runtime support module.
-- Status: active support.
--
-- Compatibility policy:
--   Existing functions, hooks, module paths, and diagnostics are
--   intentionally retained in this maintenance pass.
--   `DEPRECATED` marks a supported legacy path, not removed code.
------------------------------------------------------------

------------------------------------------------------------
-- Project: Overflow — init.lua
-- Project: Overflow runtime module.
------------------------------------------------------------

local project = {
    metadata = require("project_overflow.version"),
    context = require("project_overflow.shared.context"),
    constants = require("project_overflow.shared.constants"),
    enums = require("project_overflow.shared.enums"),
    utils = require("project_overflow.shared.utils"),
    math = require("project_overflow.shared.math"),
    logger = require("project_overflow.shared.logger"),
    debug = require("project_overflow.shared.debug"),
    event_dispatcher =
        require("project_overflow.core.event_dispatcher"),
    health = require("project_overflow.systems.health.core"),
    runtime = require("project_overflow.systems.health.runtime"),
    rpg = require("project_overflow.systems.player.rpg"),
    stat_application =
        require("project_overflow.systems.player.stat_application"),
    action_speed =
        require("project_overflow.systems.player.action_speed"),
    critical =
        require("project_overflow.systems.player.critical"),
    renderer = require("project_overflow.render.renderer"),
    reflection_snapshot =
        require("project_overflow.engine.reflection_snapshot"),
    biorand_manifest =
        require("project_overflow.systems.enemies.biorand_manifest"),
    enemy_database =
        require("project_overflow.systems.enemies.database"),
    enemy_elites =
        require("project_overflow.systems.enemies.elites"),
    enemy_rewards =
        require("project_overflow.systems.enemies.rewards"),
    loot_tables =
        require("project_overflow.systems.loot.tables"),
    enemy_registry =
        require("project_overflow.systems.enemies.registry"),
    enemy_pipeline =
        require("project_overflow.systems.enemies.pipeline"),
    enemy_kill_probe =
        require("project_overflow.engine.enemy_kill_probe"),
    ui = require("project_overflow.ui.main")
}

return project
