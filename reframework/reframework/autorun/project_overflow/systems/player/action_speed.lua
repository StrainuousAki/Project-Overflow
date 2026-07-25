------------------------------------------------------------
-- Maintenance classification — Build 49.39
-- Module: autorun/project_overflow/systems/player/action_speed.lua
-- Role: Player RPG profile, attributes, saves, experience, and stat application.
-- Status: active subsystem with retained legacy probes.
--
-- Compatibility policy:
--   Existing functions, hooks, module paths, and diagnostics are
--   intentionally retained in this maintenance pass.
--   `DEPRECATED` marks a supported legacy path, not removed code.
------------------------------------------------------------

------------------------------------------------------------
-- Project: Overflow — Player Action Speed Discovery
--
-- Captures the live PlayerCharacterContext and performs a bounded,
-- read-only metadata scan for player-owned speed members.  The game
-- exposes several global motion-speed APIs; those are deliberately not
-- written here because they also affect locomotion, enemies, and events.
------------------------------------------------------------

local rpg =
    require("project_overflow.systems.player.rpg")
local critical =
    require("project_overflow.systems.player.critical")

local action_speed = {
    hook_installed = false,
    hook_calls = 0,
    player_context = nil,
    player_context_ptr = "nil",
    player_context_type = "unknown",
    player_capture_hook_installed = false,
    player_capture_hook_calls = 0,
    player_capture_status = "Waiting for player-context hook.",
    scan_count = 0,
    candidates = {},
    last_status = "Waiting to install player action-speed probe.",
    last_error = "",
    application_hook_installed = false,
    player_animation_targets = {},
    player_animation_target_count = 0,
    last_target_scan_clock = 0,
    apply_count = 0,
    last_base_speed = 0.0,
    last_applied_speed = 0.0,
    last_multiplier = 1.0,
    application_status = "Waiting for player animation targets."
}

action_speed.native = {
    installed = false,
    installed_hooks = 0,
    failed_hooks = {},
    channels = {
        knife = { count = 0, base = 0.0, applied = 0.0 },
        melee = { count = 0, base = 0.0, applied = 0.0 },
        movement = { count = 0, base = 0.0, applied = 0.0 },
        reload = { count = 0, base = 0.0, applied = 0.0 },
        weapon_transition = { count = 0, base = 0.0, applied = 0.0 }
    },
    status = "Native player speed hooks not installed."
}

action_speed.weapon_probe = {
    installed = false,
    installed_hooks = 0,
    calls = 0,
    object = nil,
    pointer = "nil",
    type_name = "unknown",
    members = {},
    status = "Weapon behavior parameter probe not installed.",
    error = ""
}

action_speed.equipment_actions = {
    installed = false,
    installed_hooks = 0,
    fire_calls = 0,
    dry_fire_calls = 0,
    reload_start_calls = 0,
    reload_calls = 0,
    motion_type = "unknown",
    motion_pointer = "nil",
    layer_count = 0,
    layers_applied = 0,
    last_layer_base_speed = 0.0,
    last_layer_applied_speed = 0.0,
    layer_apply_count = 0,
    layer_speeds = {},
    layer_error = "",
    status = "Player equipment action hooks not installed.",
    error = ""
}

action_speed.reload_action = {
    installed = false,
    installed_hooks = 0,
    start_calls = 0,
    update_calls = 0,
    end_calls = 0,
    active_objects = {},
    last_type = "unknown",
    last_pointer = "nil",
    last_base_rate = 0.0,
    last_applied_rate = 0.0,
    last_multiplier = 1.0,
    last_native_duration_scale = 0.0,
    last_applied_duration_scale = 0.0,
    last_duration_ratio = 1.0,
    last_duration_reduction_percent = 0.0,
    pre_apply_calls = 0,
    post_apply_calls = 0,
    post_readback_rate = 0.0,
    write_confirmed = false,
    original_overwrite_count = 0,
    captured_arg_index = 0,
    captured_arg_type = "unknown",
    argument_scan_status = "not scanned",
    motion_pointer = "nil",
    motion_type = "unknown",
    motion_layer_count = 0,
    motion_layers_applied = 0,
    motion_layers_restored = 0,
    last_layer_base_speed = 0.0,
    last_layer_applied_speed = 0.0,
    application_mode = "none",
    direct_gun_path_active = false,
    behavior_tree_application_suppressed = true,
    cleanup_runs = 0,
    cleanup_values_restored = 0,
    last_method = "none",
    status = "Reload action-rate hooks not installed.",
    error = ""
}

action_speed.body_movement = {
    installed = false,
    installed_hooks = 0,
    update_calls = 0,
    getter_calls = 0,
    setter_calls = 0,
    pointer = "nil",
    type_name = "unknown",
    last_method = "none",
    last_base_speed = 0.0,
    last_applied_speed = 0.0,
    last_multiplier = 1.0,
    load_normalization_active = false,
    load_normalization_old_base = 0.0,
    load_normalization_old_applied = 0.0,
    load_normalization_old_multiplier = 1.0,
    load_normalization_hits = 0,
    load_normalization_clears = 0,
    last_raw_speed = 0.0,
    last_normalized_speed = 0.0,
    load_normalization_status = "inactive",
    locomotion_gate = false,
    locomotion_gate_reason = "not evaluated",
    last_move_dir = 0.0,
    last_target_move_dir = 0.0,
    last_objective_move_dir = 0.0,
    status = "PlayerBodyUpdater movement hooks not installed."
}

action_speed.movement = {
    object = nil,
    pointer = "nil",
    fields = {},
    needs_apply = false,
    last_multiplier = nil,
    apply_count = 0,
    capture_attempts = 0,
    capture_source = "none",
    graph_scans = 0,
    graph_objects_inspected = 0,
    last_graph_scan_clock = 0,
    userdata_hook_installed = false,
    userdata_hook_calls = 0,
    live_capture_hooks_installed = 0,
    live_capture_calls = 0,
    live_capture_last_method = "none",
    live_capture_status = "not installed",
    field_write_mode = false,
    load_resets = 0,
    load_restore_count = 0,
    last_load_reset_status = "none",
    status = "Waiting for PlayerCommonParamUserData capture."
}

local MOVEMENT_FIELDS = {
    "_FrontWalkSpeedRate", "_OtherWalkSpeedRate",
    "_NarrowFrontWalkSpeedRate", "_NarrowOtherWalkSpeedRate",
    "_WalkSpeedRate", "_NarrowWalkSpeedRate", "_HoldWalkSpeedRate",
    "_BattleWalkSpeedRate", "_WirelessCallWalkSpeedRate",
    "_RunSpeedRate", "_NarrowRunSpeedRate", "_BattleRunSpeedRate",
    "_WalkStartSpeedRate"
}

local NATIVE_GETTER_HOOKS = {
    {
        type_name = "chainsaw.KnifeCombatSpeedParam",
        methods = {"get_KnifeCombatSpeed()", "get_KnifeCombatSpeed"},
        channel = "knife",
        mode = "speed"
    },
    {
        type_name = "chainsaw.Melee",
        methods = {"get_CombatSpeed()", "get_CombatSpeed"},
        channel = "melee",
        mode = "speed"
    },
    {
        type_name = "chainsaw.PlayerCommonParamUserData",
        methods = {
            "get_FrontWalkSpeedRate()", "get_OtherWalkSpeedRate()",
            "get_NarrowFrontWalkSpeedRate()", "get_NarrowOtherWalkSpeedRate()",
            "get_WalkSpeedRate()", "get_NarrowWalkSpeedRate()",
            "get_HoldWalkSpeedRate()", "get_BattleWalkSpeedRate()",
            "get_RunSpeedRate()", "get_NarrowRunSpeedRate()",
            "get_BattleRunSpeedRate()", "get_WalkStartSpeedRate()"
        },
        channel = "movement",
        mode = "speed",
        install_all = true
    },
    {
        -- Live equipped-weapon reload scalar. Gun delegates to its active
        -- WeaponStructureParam and this return value is consumed by gameplay.
        type_name = "chainsaw.Gun",
        methods = {
            "get_ReloadSpeedRate()",
            "get_ReloadSpeedRate"
        },
        channel = "reload",
        mode = "speed"
    },
    {
        -- Legacy diagnostic path. This getter has remained unused in the
        -- current runtime, but keeping it installed is harmless.
        type_name = "chainsaw.PlayerCommonParamUserData",
        methods = {"get_ReloadLerpTime()", "get_ReloadLerpTime"},
        -- DEPRECATED: PlayerCommonParamUserData ReloadLerpTime path did not fire in the
        -- validated runtime; retained for compatibility diagnostics.
        channel = "reload_legacy",
        mode = "duration"
    },
    {
        type_name = "chainsaw.PlayerCommonParamUserData",
        methods = {"get_WeaponLerpTime()", "get_WeaponLerpTime"},
        channel = "weapon_transition",
        mode = "duration"
    }
}

local STATIC_TYPE_CANDIDATES = {
    "chainsaw.PlayerHeadUpdater",
    "chainsaw.PlayerCharacterContextComponent",
    "chainsaw.PlayerContext",
    "chainsaw.CharacterContext",
    "chainsaw.Weapon",
    "chainsaw.WeaponContext",
    "chainsaw.Arms",
    "chainsaw.WeaponThinkPlayerParam",
    "via.motion.Motion",
    "via.motion.MotionLayer"
}

local function lower(value)
    return string.lower(tostring(value or ""))
end

local function is_candidate(name)
    local text = lower(name)
    if
        string.find(text, "fireinterval", 1, true) ~= nil or
        string.find(text, "shotinterval", 1, true) ~= nil or
        string.find(text, "attackinterval", 1, true) ~= nil or
        string.find(text, "reload", 1, true) ~= nil
    then
        return true
    end
    local has_speed =
        string.find(text, "speed", 1, true) ~= nil or
        string.find(text, "rate", 1, true) ~= nil or
        string.find(text, "timescale", 1, true) ~= nil or
        string.find(text, "time_scale", 1, true) ~= nil
    local has_action =
        string.find(text, "attack", 1, true) ~= nil or
        string.find(text, "action", 1, true) ~= nil or
        string.find(text, "motion", 1, true) ~= nil or
        string.find(text, "melee", 1, true) ~= nil or
        string.find(text, "reload", 1, true) ~= nil

    return has_speed and (
        has_action or
        string.find(text, "play", 1, true) ~= nil or
        string.find(text, "animation", 1, true) ~= nil
    )
end

local function safe_name(member)
    local ok, result = pcall(function()
        return member:get_name()
    end)
    return ok and tostring(result or "unknown") or "unknown"
end

local function safe_type_name(type_definition)
    local ok, result = pcall(function()
        return type_definition:get_full_name()
    end)
    return ok and tostring(result or "unknown") or "unknown"
end

local function object_type_name(object)
    local ok, result = pcall(function()
        return object:get_type_definition():get_full_name()
    end)
    return ok and tostring(result or "unknown") or "unknown"
end

local function object_pointer(ctx, object)
    local ok, result = pcall(function()
        return ctx.ptr_from_obj(object)
    end)
    return ok and tostring(result or "nil") or "nil"
end

local function raw_object_pointer(object)
    local ok, result = pcall(function()
        return string.format("0x%X", sdk.to_ptr(object))
    end)
    return ok and result or tostring(object)
end

local function capture_movement_object(object, source)
    if object == nil then return false end
    local pointer = raw_object_pointer(object)
    local previous_object = action_speed.movement.object
    action_speed.movement.object = object
    if pointer == action_speed.movement.pointer then
        if previous_object ~= object then
            action_speed.movement.needs_apply = true
        end
        return true
    end

    local baselines = {}
    for _, field_name in ipairs(MOVEMENT_FIELDS) do
        local value = nil
        pcall(function() value = object:get_field(field_name) end)
        if tonumber(value) ~= nil then
            baselines[field_name] = tonumber(value)
        end
    end
    action_speed.movement.pointer = pointer
    action_speed.movement.fields = baselines
    action_speed.movement.needs_apply = true
    action_speed.movement.capture_source =
        tostring(source or "unknown")
    action_speed.movement.status = string.format(
        "Captured %d native movement-rate field(s).",
        (function()
            local count = 0
            for _ in pairs(baselines) do count = count + 1 end
            return count
        end)()
    )
    return true
end

local function capture_action_speed_player(
    ctx,
    object,
    source
)
    if object == nil then
        return false
    end

    local type_name =
        object_type_name(
            object
        )

    if type_name ~= "chainsaw.PlayerCharacterContext"
        and type_name ~= "chainsaw.PlayerCharacterContextComponent"
    then
        return false
    end

    local pointer =
        object_pointer(
            ctx,
            object
        )

    action_speed.player_context =
        object

    action_speed.player_context_ptr =
        pointer

    action_speed.player_context_type =
        type_name

    action_speed.player_capture_status =
        tostring(source or "captured player context")

    if ctx ~= nil
        and ctx.state ~= nil
        and ctx.state.player == nil
    then
        ctx.state.player =
            object

        ctx.state.player_ptr =
            pointer

        ctx.state.player_type =
            type_name
    end

    return true
end

local function install_player_capture_hook(ctx)
    if action_speed.player_capture_hook_installed then
        return true
    end

    local definition =
        sdk.find_type_definition(
            "chainsaw.PlayerCharacterContext"
        )

    if definition == nil then
        action_speed.player_capture_status =
            "PlayerCharacterContext type not found."

        return false
    end

    local method = nil

    for _, candidate in ipairs({
        "updateContextDataOnUpdatePhase()",
        "updateContextDataOnUpdatePhase"
    }) do
        pcall(function()
            method =
                definition:get_method(
                    candidate
                )
        end)

        if method ~= nil then
            break
        end
    end

    if method == nil then
        action_speed.player_capture_status =
            "PlayerCharacterContext update hook not found."

        return false
    end

    local ok, error_text =
        pcall(function()
            sdk.hook(
                method,
                function(args)
                    local object = nil

                    pcall(function()
                        object =
                            sdk.to_managed_object(
                                args[2]
                            )
                    end)

                    if capture_action_speed_player(
                        ctx,
                        object,
                        "PlayerCharacterContext.updateContextDataOnUpdatePhase"
                    ) then
                        action_speed.player_capture_hook_calls =
                            action_speed.player_capture_hook_calls + 1
                    end

                    return sdk.PreHookResult.CALL_ORIGINAL
                end,
                function(retval)
                    return retval
                end
            )
        end)

    if not ok then
        action_speed.player_capture_status =
            "Player-context hook failed: "
            .. tostring(error_text)

        return false
    end

    action_speed.player_capture_hook_installed = true
    action_speed.player_capture_status =
        "Player-context hook installed."

    return true
end

-- DEPRECATED FALLBACK: onLoad normally fires before autorun scripts are installed.
-- Retained for save/reload scenarios and future REFramework lifecycle changes.
local function install_movement_userdata_hook()
    if action_speed.movement.userdata_hook_installed then
        return true
    end

    local definition =
        sdk.find_type_definition(
            "chainsaw.PlayerCommonParamUserData"
        )

    if definition == nil then
        action_speed.movement.status =
            "PlayerCommonParamUserData type not found."

        return false
    end

    local method = nil

    for _, candidate in ipairs({
        "onLoad()",
        "onLoad"
    }) do
        pcall(function()
            method =
                definition:get_method(
                    candidate
                )
        end)

        if method ~= nil then
            break
        end
    end

    if method == nil then
        action_speed.movement.status =
            "PlayerCommonParamUserData.onLoad not found."

        return false
    end

    local ok, error_text =
        pcall(function()
            sdk.hook(
                method,
                function(args)
                    local object = nil

                    pcall(function()
                        object =
                            sdk.to_managed_object(
                                args[2]
                            )
                    end)

                    if object ~= nil then
                        action_speed.movement.userdata_hook_calls =
                            action_speed.movement.userdata_hook_calls + 1

                        capture_movement_object(
                            object,
                            "PlayerCommonParamUserData.onLoad"
                        )
                    end

                    return sdk.PreHookResult.CALL_ORIGINAL
                end,
                function(retval)
                    return retval
                end
            )
        end)

    if not ok then
        action_speed.movement.status =
            "Movement userdata hook failed: "
            .. tostring(error_text)

        return false
    end

    action_speed.movement.userdata_hook_installed = true
    action_speed.movement.status =
        "PlayerCommonParamUserData.onLoad hook installed."

    return true
end

-- DEPRECATED DIAGNOSTIC: these PlayerCommonParamUserData getters produced no calls
-- in the validated runtime. Retained as a non-authoritative compatibility probe.
local function install_movement_live_capture_hooks()
    if action_speed.movement.live_capture_hooks_installed > 0 then
        return true
    end

    local definition =
        sdk.find_type_definition(
            "chainsaw.PlayerCommonParamUserData"
        )

    if definition == nil then
        action_speed.movement.live_capture_status =
            "PlayerCommonParamUserData type not found."

        return false
    end

    local candidates = {
        "get_Group_MoveSpeed()",
        "get_Group_Motion()",
        "get_Group_Battle()",
        "get_Group_Hold()",
        "get_Group_Wall()",
        "get_Group_Interaction()",
        "get_StepInfos()",
        "get_LandInfo()",
        "get_JumpLowInfo()",
        "get_AddRunJumpStepInfo()"
    }

    local installed = 0
    local installed_methods = {}

    for _, signature in ipairs(candidates) do
        local method = nil

        pcall(function()
            method =
                definition:get_method(
                    signature
                )
        end)

        if method ~= nil
            and installed_methods[tostring(method)] ~= true
        then
            local method_label =
                tostring(signature)

            local ok =
                pcall(function()
                    sdk.hook(
                        method,
                        function(args)
                            local object = nil

                            pcall(function()
                                object =
                                    sdk.to_managed_object(
                                        args[2]
                                    )
                            end)

                            action_speed.movement.live_capture_calls =
                                action_speed.movement.live_capture_calls + 1

                            action_speed.movement.live_capture_last_method =
                                method_label

                            if object ~= nil then
                                capture_movement_object(
                                    object,
                                    "live getter: " .. method_label
                                )
                            end

                            return sdk.PreHookResult.CALL_ORIGINAL
                        end,
                        function(retval)
                            return retval
                        end
                    )
                end)

            if ok then
                installed_methods[tostring(method)] = true
                installed = installed + 1
            end
        end
    end

    action_speed.movement.live_capture_hooks_installed =
        installed

    action_speed.movement.live_capture_status =
        installed > 0
        and (
            "Installed "
            .. tostring(installed)
            .. " live movement userdata capture hook(s)."
        )
        or "No live movement userdata capture hooks resolved."

    return installed > 0
end

-- DEPRECATED FALLBACK: bounded graph discovery remains available only when direct
-- PlayerBodyUpdater locomotion hooks cannot provide the required behavior.
local function capture_movement_from_player_graph(ctx)
    if action_speed.movement.object ~= nil then
        return true
    end

    local root =
        (
            ctx ~= nil
            and ctx.state ~= nil
            and ctx.state.player
        )
        or action_speed.player_context

    if root == nil then
        action_speed.movement.status =
            "Waiting for live player context before movement graph scan."

        return false
    end

    local now =
        os.clock()

    if now - action_speed.movement.last_graph_scan_clock < 1.0 then
        return false
    end

    action_speed.movement.last_graph_scan_clock =
        now

    action_speed.movement.capture_attempts =
        action_speed.movement.capture_attempts + 1

    action_speed.movement.graph_scans =
        action_speed.movement.graph_scans + 1

    local queue = {
        {
            object = root,
            depth = 0
        }
    }

    local visited = {}
    local cursor = 1
    local inspected = 0
    local found = nil

    while cursor <= #queue
        and inspected < 600
        and found == nil
    do
        local entry =
            queue[cursor]

        cursor =
            cursor + 1

        local object =
            entry.object

        local pointer =
            object_pointer(
                ctx,
                object
            )

        if pointer ~= "nil"
            and visited[pointer] ~= true
        then
            visited[pointer] = true
            inspected = inspected + 1

            local type_name =
                object_type_name(
                    object
                )

            if type_name ==
                "chainsaw.PlayerCommonParamUserData"
            then
                found = object
                break
            end

            if entry.depth < 5 then
                local fields = {}

                pcall(function()
                    fields =
                        object:get_type_definition():get_fields()
                        or {}
                end)

                for index, field in ipairs(fields) do
                    if index > 256 then
                        break
                    end

                    local child = nil
                    local field_name =
                        safe_name(
                            field
                        )

                    pcall(function()
                        child =
                            object:get_field(
                                field_name
                            )
                    end)

                    if child ~= nil then
                        local child_type = nil

                        pcall(function()
                            child_type =
                                child:get_type_definition()
                        end)

                        if child_type ~= nil then
                            queue[#queue + 1] = {
                                object = child,
                                depth = entry.depth + 1
                            }
                        end
                    end
                end
            end
        end
    end

    action_speed.movement.graph_objects_inspected =
        inspected

    if found == nil then
        action_speed.movement.status =
            string.format(
                "Player graph scan %d inspected %d object(s); PlayerCommonParamUserData not found.",
                action_speed.movement.graph_scans,
                inspected
            )

        return false
    end

    return capture_movement_object(
        found,
        "player object graph"
    )
end

-- Forward declarations: save loading can capture movement userdata before
-- the multiplier implementations are assigned later in this module.
local active_multiplier
local movement_multiplier
local fire_rate_multiplier
local reload_speed_multiplier
local channel_multiplier

local function update_movement_fields()
    local movement =
        action_speed.movement

    if movement.object == nil then
        return false
    end

    local multiplier =
        movement_multiplier()

    local movement_channel =
        action_speed.native.channels.movement

    local getter_calls =
        tonumber(movement_channel.count) or 0

    if getter_calls > 0 then
        movement.field_write_mode = false
        movement.needs_apply = false
        movement.last_multiplier = multiplier
        movement.status =
            string.format(
                "Native walk/run getters active at %.3fx; last %.4f -> %.4f.",
                multiplier,
                tonumber(movement_channel.base) or 0.0,
                tonumber(movement_channel.applied) or 0.0
            )

        return true
    end

    if movement.needs_apply ~= true
        and movement.last_multiplier == multiplier
    then
        return false
    end

    local applied = 0

    for field_name, base_value in pairs(
        movement.fields
    ) do
        local desired =
            base_value * multiplier

        local ok =
            pcall(function()
                movement.object:set_field(
                    field_name,
                    desired
                )
            end)

        if ok then
            applied = applied + 1
        end
    end

    movement.needs_apply = false
    movement.last_multiplier = multiplier
    movement.field_write_mode = true
    movement.apply_count =
        movement.apply_count + applied

    movement.status =
        string.format(
            "Getter calls are zero; applied %.3fx directly to %d walk/run field(s).",
            multiplier,
            applied
        )

    return applied > 0
end

local function is_weapon_timing_name(name)
    local text = lower(name)
    local keywords = {
        "fire", "shot", "shoot", "reload", "interval",
        "cycle", "rate", "speed", "rapid", "burst", "wait"
    }
    for _, keyword in ipairs(keywords) do
        if string.find(text, keyword, 1, true) ~= nil then
            return true
        end
    end
    return false
end

local function capture_weapon_param(ctx, object)
    if object == nil then return false end
    local captured_type = object_type_name(object)
    if captured_type ~= "chainsaw.WeaponThinkPlayerParam" then
        return false
    end
    local captured_pointer = object_pointer(ctx, object)
    if
        captured_pointer ~= "nil" and
        captured_pointer == action_speed.weapon_probe.pointer
    then
        return true
    end
    local members = {}
    local ok, error_text = pcall(function()
        local type_definition = object:get_type_definition()
        action_speed.weapon_probe.object = object
        action_speed.weapon_probe.pointer = captured_pointer
        action_speed.weapon_probe.type_name = safe_type_name(type_definition)

        local fields = type_definition:get_fields() or {}
        for index, field in ipairs(fields) do
            if index > 256 then break end
            local name = safe_name(field)
            if is_weapon_timing_name(name) then
                local type_name = "unknown"
                local value_text = "<reference>"
                pcall(function()
                    type_name = safe_type_name(field:get_type())
                end)
                if
                    type_name == "System.Single" or
                    type_name == "System.Int32" or
                    type_name == "System.UInt32" or
                    type_name == "System.Boolean"
                then
                    pcall(function()
                        value_text = tostring(object:get_field(name))
                    end)
                end
                members[#members + 1] = {
                    kind = "field",
                    name = name,
                    type_name = type_name,
                    value = value_text
                }
            end
        end

        local methods = type_definition:get_methods() or {}
        for index, method in ipairs(methods) do
            if index > 512 then break end
            local name = safe_name(method)
            if is_weapon_timing_name(name) then
                members[#members + 1] = {
                    kind = "method",
                    name = name,
                    type_name = "",
                    value = ""
                }
            end
        end
    end)

    if not ok then
        action_speed.weapon_probe.error = tostring(error_text)
        action_speed.weapon_probe.status = "Weapon parameter capture failed."
        return false
    end

    table.sort(members, function(a, b)
        return a.name < b.name
    end)
    action_speed.weapon_probe.members = members
    action_speed.weapon_probe.error = ""
    action_speed.weapon_probe.status = string.format(
        "Captured %d weapon timing member(s).",
        #members
    )
    return true
end

local function install_weapon_param_probe(ctx)
    if action_speed.weapon_probe.installed then return true end
    local ok, error_text = pcall(function()
        local installed = 0

        local equipment_type =
            sdk.find_type_definition("chainsaw.EquipmentManager")
        if equipment_type ~= nil then
            local catalog_getter =
                equipment_type:get_method(
                    "getWeaponThinkPlayerParam(chainsaw.WeaponID)"
                ) or equipment_type:get_method("getWeaponThinkPlayerParam")
            if catalog_getter ~= nil then
                sdk.hook(catalog_getter, function(args) end, function(retval)
                    local object = nil
                    pcall(function() object = sdk.to_managed_object(retval) end)
                    if object ~= nil then
                        action_speed.weapon_probe.calls =
                            action_speed.weapon_probe.calls + 1
                        capture_weapon_param(ctx, object)
                    end
                    return retval
                end)
                installed = installed + 1
            end
        end

        local arms_type = sdk.find_type_definition("chainsaw.Arms")
        if arms_type ~= nil then
            local arms_getter =
                arms_type:get_method("get_ThinkPlayerParam()") or
                arms_type:get_method("get_ThinkPlayerParam")
            if arms_getter ~= nil then
                sdk.hook(arms_getter, function(args)
                    local arms = ctx.managed_from_arg(args, 2)
                    if arms == nil then return end

                    local object = nil
                    pcall(function()
                        object = arms:get_field(
                            "<ThinkPlayerParam>k__BackingField"
                        )
                    end)

                    if object ~= nil then
                        action_speed.weapon_probe.calls =
                            action_speed.weapon_probe.calls + 1
                        capture_weapon_param(ctx, object)
                    end
                end, function(retval)
                    return retval
                end)
                installed = installed + 1
            end

            local arms_setter =
                arms_type:get_method(
                    "set_ThinkPlayerParam(chainsaw.WeaponThinkPlayerParam)"
                ) or arms_type:get_method("set_ThinkPlayerParam")
            if arms_setter ~= nil then
                sdk.hook(arms_setter, function(args)
                    for index = 2, 6 do
                        local object = ctx.managed_from_arg(args, index)
                        if
                            object ~= nil and
                            object_type_name(object) ==
                                "chainsaw.WeaponThinkPlayerParam"
                        then
                            action_speed.weapon_probe.calls =
                                action_speed.weapon_probe.calls + 1
                            capture_weapon_param(ctx, object)
                            break
                        end
                    end
                end, function(retval)
                    return retval
                end)
                installed = installed + 1
            end
        end

        if installed == 0 then
            error("No weapon behavior parameter capture methods resolved")
        end

        action_speed.weapon_probe.installed_hooks = installed
        action_speed.weapon_probe.installed = true
        action_speed.weapon_probe.status = string.format(
            "Installed %d weapon parameter capture hook(s).",
            installed
        )
    end)

    if not ok then
        action_speed.weapon_probe.error = tostring(error_text)
        action_speed.weapon_probe.status = "Weapon parameter probe failed."
        return false
    end
    return true
end

local function discover_player_animations(ctx, root)
    root = root or ctx.state.player
    if root == nil then return false end

    local queue = {{ object = root, depth = 0 }}
    local visited = {}
    local targets = {}
    local cursor = 1
    local inspected = 0

    while cursor <= #queue and inspected < 160 do
        local entry = queue[cursor]
        cursor = cursor + 1
        local object = entry.object
        local pointer = object_pointer(ctx, object)

        if pointer ~= "nil" and not visited[pointer] then
            visited[pointer] = true
            inspected = inspected + 1

            local type_name = object_type_name(object)
            if type_name == "via.motion.Animation" then
                targets[pointer] = true
            elseif entry.depth < 3 then
                local type_definition = nil
                local fields = {}
                pcall(function()
                    type_definition = object:get_type_definition()
                    fields = type_definition:get_fields() or {}
                end)

                for index, field in ipairs(fields) do
                    if index > 192 then break end
                    local child = nil
                    local name = safe_name(field)
                    pcall(function() child = object:get_field(name) end)
                    if child ~= nil then
                        local child_type = nil
                        pcall(function()
                            child_type = child:get_type_definition()
                        end)
                        if child_type ~= nil then
                            queue[#queue + 1] = {
                                object = child,
                                depth = entry.depth + 1
                            }
                        end
                    end
                end
            end
        end
    end

    local count = 0
    for _ in pairs(targets) do count = count + 1 end
    action_speed.player_animation_targets = targets
    action_speed.player_animation_target_count = count
    action_speed.last_target_scan_clock = os.clock()
    action_speed.application_status = count > 0
        and string.format("Tracking %d player animation object(s).", count)
        or "Captured player, but no animation objects were reachable."
    return count > 0
end


local function capture_equipment_motion(ctx, equipment, source)
    if equipment == nil then return false end
    local motion = nil
    pcall(function()
        motion = equipment:get_field("<Motion>k__BackingField")
    end)
    if motion == nil then
        action_speed.equipment_actions.status =
            source .. ": PlayerEquipment Motion field was nil."
        return false
    end

    action_speed.equipment_actions.motion_type = object_type_name(motion)
    action_speed.equipment_actions.motion_pointer = object_pointer(ctx, motion)
    local multiplier = active_multiplier()
    local layer_count = 0
    local applied_count = 0
    local apply_ok, apply_error = pcall(function()
        layer_count = tonumber(motion:call("getLayerCount")) or 0
        for index = 0, math.max(0, layer_count - 1) do
            local layer = motion:call("getLayer", index)
            if layer ~= nil then
                local current_speed = tonumber(layer:call("get_Speed")) or 0.0
                local layer_pointer = object_pointer(ctx, layer)
                if layer_pointer == "nil" then
                    layer_pointer =
                        action_speed.equipment_actions.motion_pointer ..
                        ":layer:" .. tostring(index)
                end
                local tracked =
                    action_speed.equipment_actions.layer_speeds[layer_pointer]
                local base_speed = current_speed
                if
                    tracked ~= nil and
                    math.abs(current_speed - tracked.applied) < 0.0001
                then
                    base_speed = tracked.base
                end
                if base_speed > 0.0 then
                    local applied_speed = base_speed * multiplier
                    layer:call("set_Speed", applied_speed)
                    action_speed.equipment_actions.layer_speeds[layer_pointer] = {
                        base = base_speed,
                        applied = applied_speed
                    }
                    action_speed.equipment_actions.last_layer_base_speed =
                        base_speed
                    action_speed.equipment_actions.last_layer_applied_speed =
                        applied_speed
                    applied_count = applied_count + 1
                end
            end
        end
    end)

    action_speed.equipment_actions.layer_count = layer_count
    action_speed.equipment_actions.layers_applied = applied_count
    action_speed.equipment_actions.layer_apply_count =
        action_speed.equipment_actions.layer_apply_count + applied_count
    action_speed.equipment_actions.layer_error =
        apply_ok and "" or tostring(apply_error)
    action_speed.equipment_actions.status = string.format(
        "%s: captured %s; applied %.3fx to %d/%d layer(s).",
        source,
        action_speed.equipment_actions.motion_type,
        multiplier,
        applied_count,
        layer_count
    )
    return apply_ok and applied_count > 0
end

local function observe_equipment_motion(ctx, equipment, source)
    if equipment == nil then return false end
    local motion = nil
    pcall(function()
        motion = equipment:get_field("<Motion>k__BackingField")
    end)
    action_speed.equipment_actions.motion_type =
        motion ~= nil and object_type_name(motion) or "unknown"
    action_speed.equipment_actions.motion_pointer =
        motion ~= nil and object_pointer(ctx, motion) or "nil"
    action_speed.equipment_actions.layers_applied = 0
    local fire_multiplier =
        fire_rate_multiplier()

    action_speed.equipment_actions.status =
        string.format(
            "%s: observed only; shared motion unchanged; Dex fire-rate target %.3fx.",
            source,
            fire_multiplier
        )
    return motion ~= nil
end

local function install_equipment_action_hooks(ctx)
    if action_speed.equipment_actions.installed then return true end
    local ok, error_text = pcall(function()
        local type_definition =
            sdk.find_type_definition("chainsaw.PlayerEquipment")
        if type_definition == nil then error("No chainsaw.PlayerEquipment") end

        local definitions = {
            -- PlayerEquipment exposes one shared Motion tree. Writing its
            -- layer speed from any weapon action can also accelerate walk/run,
            -- so these hooks are diagnostic-only. Action-specific native
            -- parameters remain the only safe speed path.
            { names = {"execFire()", "execFire"}, counter = "fire_calls", label = "Fire", apply_layers = false },
            { names = {"execDryFire()", "execDryFire"}, counter = "dry_fire_calls", label = "Dry fire", apply_layers = false },
            -- Reload uses the same Motion/TreeLayer collection as locomotion.
            -- Multiplying those layers leaks the reload multiplier into run
            -- speed until another action rebuilds the tree, so reload hooks
            -- remain diagnostic-only until a reload-specific layer is found.
            { names = {"execReloadStart()", "execReloadStart"}, counter = "reload_start_calls", label = "Reload start", apply_layers = false },
            { names = {"execReload()", "execReload"}, counter = "reload_calls", label = "Reload", apply_layers = false }
        }
        local installed = 0
        for _, definition in ipairs(definitions) do
            local hook_definition = definition
            local method = nil
            local equipment_stack = {}
            for _, name in ipairs(hook_definition.names) do
                method = type_definition:get_method(name)
                if method ~= nil then break end
            end
            if method ~= nil then
                sdk.hook(method, function(args)
                    action_speed.equipment_actions[hook_definition.counter] =
                        action_speed.equipment_actions[hook_definition.counter] + 1
                    equipment_stack[#equipment_stack + 1] =
                        ctx.managed_from_arg(args, 2)
                end, function(retval)
                    local equipment = equipment_stack[#equipment_stack]
                    equipment_stack[#equipment_stack] = nil
                    if hook_definition.apply_layers == true then
                        capture_equipment_motion(
                            ctx,
                            equipment,
                            hook_definition.label
                        )
                    else
                        observe_equipment_motion(
                            ctx,
                            equipment,
                            hook_definition.label
                        )
                    end
                    return retval
                end)
                installed = installed + 1
            end
        end
        if installed == 0 then
            error("No PlayerEquipment action methods resolved")
        end
        action_speed.equipment_actions.installed_hooks = installed
        action_speed.equipment_actions.installed = true
        action_speed.equipment_actions.status = string.format(
            "Installed %d player equipment action hook(s).",
            installed
        )
    end)

    if not ok then
        action_speed.equipment_actions.error = tostring(error_text)
        action_speed.equipment_actions.status =
            "Player equipment action hook install failed."
        return false
    end
    return true
end

local function install_application_hook(ctx)
    if action_speed.application_hook_installed then return true end

    local ok, error_text = pcall(function()
        local type_definition =
            sdk.find_type_definition("via.motion.Animation")
        if type_definition == nil then
            error("No via.motion.Animation")
        end

        local method =
            type_definition:get_method("set_PlaySpeed(System.Single)") or
            type_definition:get_method("set_PlaySpeed")
        if method == nil then
            error("No via.motion.Animation.set_PlaySpeed")
        end

        sdk.hook(method, function(args)
            local object = ctx.managed_from_arg(args, 2)
            if object == nil or args[3] == nil then return end
            local pointer = object_pointer(ctx, object)
            if action_speed.player_animation_targets[pointer] ~= true then
                return
            end

            local base_speed = sdk.to_float(args[3])
            local multiplier =
                math.max(
                    0.75,
                    tonumber(
                        rpg.derived_stats().action_speed_multiplier
                    ) or 1.0
                )
            local applied_speed = base_speed * multiplier
            args[3] = sdk.float_to_ptr(applied_speed)

            action_speed.apply_count = action_speed.apply_count + 1
            action_speed.last_base_speed = base_speed
            action_speed.last_applied_speed = applied_speed
            action_speed.last_multiplier = multiplier
            action_speed.application_status = string.format(
                "Applied %.3fx to player animation speed.",
                multiplier
            )
        end, function(retval)
            return retval
        end)

        action_speed.application_hook_installed = true
    end)

    if not ok then
        action_speed.last_error = tostring(error_text)
        action_speed.application_status = "Animation speed hook failed."
        return false
    end
    return true
end

active_multiplier = function()
    return math.max(
        0.75,
        tonumber(
            rpg.derived_stats().action_speed_multiplier
        ) or 1.0
    )
end

movement_multiplier = function()
    return math.max(
        1.0,
        tonumber(
            rpg.derived_stats().movement_speed_multiplier
        ) or 1.0
    )
end

fire_rate_multiplier = function()
    return math.max(
        1.0,
        tonumber(
            rpg.derived_stats().fire_rate_multiplier
        ) or 1.0
    )
end

reload_speed_multiplier = function()
    return math.max(
        1.0,
        tonumber(
            rpg.derived_stats().reload_speed_multiplier
        ) or 1.0
    )
end

channel_multiplier = function(channel)
    if channel == "movement" then
        return movement_multiplier()
    end

    if channel == "reload"
        or channel == "reload_legacy"
    then
        return reload_speed_multiplier()
    end

    if channel == "knife"
        or channel == "melee"
        or channel == "weapon_transition"
    then
        return active_multiplier()
    end

    return 1.0
end

local function read_body_float(object, names)
    if object == nil then
        return 0.0
    end

    for _, name in ipairs(names) do
        local value = nil

        pcall(function()
            value =
                object:call(
                    "get_" .. name
                )
        end)

        if value == nil then
            pcall(function()
                value =
                    object:get_field(
                        "<" .. name .. ">k__BackingField"
                    )
            end)
        end

        if value == nil then
            pcall(function()
                value =
                    object:get_field(
                        name
                    )
            end)
        end

        value =
            tonumber(
                value
            )

        if value ~= nil then
            return value
        end
    end

    return 0.0
end

local function evaluate_walk_run_gate(object)
    local move_dir =
        read_body_float(
            object,
            {
                "MoveDir",
                "_MoveDir"
            }
        )

    local target_move_dir =
        read_body_float(
            object,
            {
                "TargetMoveDir",
                "_TargetMoveDir"
            }
        )

    local objective_move_dir =
        read_body_float(
            object,
            {
                "ObjectiveMoveDir",
                "_ObjectiveMoveDir"
            }
        )

    action_speed.body_movement.last_move_dir =
        move_dir

    action_speed.body_movement.last_target_move_dir =
        target_move_dir

    action_speed.body_movement.last_objective_move_dir =
        objective_move_dir

    local epsilon =
        0.001

    local moving =
        math.abs(move_dir) > epsilon
        or math.abs(target_move_dir) > epsilon
        or math.abs(objective_move_dir) > epsilon

    action_speed.body_movement.locomotion_gate =
        moving

    action_speed.body_movement.locomotion_gate_reason =
        moving
        and "walk/run movement direction active"
        or "no walk/run movement direction"

    return moving
end

local function resolve_reload_action_arg(args)
    local fallback_object = nil
    local fallback_index = 0
    local seen = {}

    for index = 1, 8 do
        local object = nil

        pcall(function()
            object =
                sdk.to_managed_object(
                    args[index]
                )
        end)

        if object ~= nil then
            local type_name =
                object_type_name(
                    object
                )

            seen[#seen + 1] =
                tostring(index)
                .. "="
                .. tostring(type_name)

            if fallback_object == nil then
                fallback_object = object
                fallback_index = index
            end

            if string.find(
                tostring(type_name),
                "ApplyReloadSpeed",
                1,
                true
            ) ~= nil
            then
                action_speed.reload_action.captured_arg_index =
                    index

                action_speed.reload_action.captured_arg_type =
                    tostring(type_name)

                action_speed.reload_action.argument_scan_status =
                    table.concat(
                        seen,
                        " | "
                    )

                return object, index
            end
        end
    end

    action_speed.reload_action.captured_arg_index =
        fallback_index

    action_speed.reload_action.captured_arg_type =
        fallback_object ~= nil
        and object_type_name(fallback_object)
        or "unknown"

    action_speed.reload_action.argument_scan_status =
        #seen > 0
        and table.concat(seen, " | ")
        or "No managed hook arguments resolved."

    return fallback_object, fallback_index
end

-- DEPRECATED DIAGNOSTIC: behavior-tree reload callbacks are observation-only.
-- Authoritative reload application: chainsaw.Gun.get_ReloadSpeedRate().
local function install_reload_action_rate_hooks(ctx)
    if action_speed.reload_action.installed then
        return true
    end

    local target_types = {
        "chainsaw.WeaponBehaviorTreeAction_ApplyReloadSpeed",
        "chainsaw.WeaponBehaviorTreeAction_ApplyReloadSpeedAddBlend",
        "chainsaw.WeaponBehaviorTreeAction_McApplyReloadSpeed",
        "chainsaw.WeaponBehaviorTreeAction_McApplyReloadSpeedAddBlend"
    }

    local installed = 0
    local installed_methods = {}

    local function object_key(object)
        return object_pointer(
            ctx,
            object
        )
    end

    local function read_reload_motion(object)
        if object == nil then
            return nil
        end

        local motion = nil

        pcall(function()
            motion =
                object:get_field(
                    "_Motion"
                )
        end)

        if motion == nil then
            pcall(function()
                motion =
                    object:get_field(
                        "<Motion>k__BackingField"
                    )
            end)
        end

        return motion
    end

    local function apply_local_motion(
        object,
        pointer,
        multiplier,
        method_name
    )
        local motion =
            read_reload_motion(
                object
            )

        if motion == nil then
            action_speed.reload_action.status =
                "Reload action has no local Motion object."

            return false
        end

        local motion_pointer =
            object_pointer(
                ctx,
                motion
            )

        local layer_count = 0
        local applied_count = 0
        local tracked_layers = {}

        local ok, error_text =
            pcall(function()
                layer_count =
                    tonumber(
                        motion:call(
                            "getLayerCount"
                        )
                    ) or 0

                for index = 0, math.max(0, layer_count - 1) do
                    local layer =
                        motion:call(
                            "getLayer",
                            index
                        )

                    if layer ~= nil then
                        local current_speed =
                            tonumber(
                                layer:call(
                                    "get_Speed"
                                )
                            ) or 0.0

                        local layer_pointer =
                            object_pointer(
                                ctx,
                                layer
                            )

                        if layer_pointer == "nil" then
                            layer_pointer =
                                motion_pointer
                                .. ":layer:"
                                .. tostring(index)
                        end

                        local existing =
                            action_speed.reload_action.active_objects[
                                pointer
                            ]

                        local previous =
                            existing ~= nil
                            and existing.layers ~= nil
                            and existing.layers[layer_pointer]
                            or nil

                        local base_speed =
                            previous ~= nil
                            and previous.base
                            or current_speed

                        if base_speed > 0.0 then
                            local applied_speed =
                                base_speed * multiplier

                            layer:call(
                                "set_Speed",
                                applied_speed
                            )

                            tracked_layers[layer_pointer] = {
                                object = layer,
                                base = base_speed,
                                applied = applied_speed
                            }

                            action_speed.reload_action.last_layer_base_speed =
                                base_speed

                            action_speed.reload_action.last_layer_applied_speed =
                                applied_speed

                            applied_count =
                                applied_count + 1
                        end
                    end
                end
            end)

        if not ok then
            action_speed.reload_action.error =
                tostring(error_text)

            action_speed.reload_action.status =
                "Failed to apply reload-local motion speed."

            return false
        end

        action_speed.reload_action.active_objects[
            pointer
        ] = {
            object = object,
            mode = "motion",
            motion = motion,
            layers = tracked_layers
        }

        action_speed.reload_action.motion_pointer =
            motion_pointer

        action_speed.reload_action.motion_type =
            object_type_name(
                motion
            )

        action_speed.reload_action.motion_layer_count =
            layer_count

        action_speed.reload_action.motion_layers_applied =
            applied_count

        action_speed.reload_action.application_mode =
            "reload-local motion layers"

        action_speed.reload_action.last_multiplier =
            multiplier

        action_speed.reload_action.last_method =
            tostring(method_name)

        action_speed.reload_action.status =
            string.format(
                "Applied %.3fx to %d/%d reload-local motion layer(s).",
                multiplier,
                applied_count,
                layer_count
            )

        return applied_count > 0
    end

    local function apply_rate(object, method_name)
        action_speed.reload_action.behavior_tree_application_suppressed =
            true

        action_speed.reload_action.last_method =
            tostring(method_name)

        if object ~= nil then
            action_speed.reload_action.last_type =
                object_type_name(
                    object
                )

            action_speed.reload_action.last_pointer =
                object_key(
                    object
                )
        end

        action_speed.reload_action.application_mode =
            action_speed.reload_action.direct_gun_path_active
            and "chainsaw.Gun.get_ReloadSpeedRate"
            or "behavior-tree diagnostic only"

        action_speed.reload_action.status =
            action_speed.reload_action.direct_gun_path_active
            and string.format(
                "Direct Gun reload rate active; behavior-tree callback observed only. %.4f -> %.4f at %.3fx.",
                action_speed.reload_action.last_base_rate,
                action_speed.reload_action.last_applied_rate,
                action_speed.reload_action.last_multiplier
            )
            or "Behavior-tree reload callback observed only; no rate or motion value modified."

        return true
    end

    local function restore_rate(object, method_name)
        action_speed.reload_action.behavior_tree_application_suppressed =
            true

        action_speed.reload_action.last_method =
            tostring(method_name)

        if object ~= nil then
            action_speed.reload_action.last_type =
                object_type_name(
                    object
                )

            action_speed.reload_action.last_pointer =
                object_key(
                    object
                )
        end

        action_speed.reload_action.status =
            action_speed.reload_action.direct_gun_path_active
            and "Reload action ended; direct Gun getter was the only applied path."
            or "Reload action ended; behavior-tree path was diagnostic-only."

        return true
    end

    for _, type_name in ipairs(target_types) do
        local definition =
            sdk.find_type_definition(
                type_name
            )

        if definition ~= nil then
            for _, hook_info in ipairs({
                {
                    signature = "start(via.behaviortree.ActionArg)",
                    counter = "start_calls",
                    mode = "apply"
                },
                {
                    signature = "update(via.behaviortree.ActionArg)",
                    counter = "update_calls",
                    mode = "apply"
                },
                {
                    signature = "end(via.behaviortree.ActionArg)",
                    counter = "end_calls",
                    mode = "restore"
                }
            }) do
                local method = nil

                pcall(function()
                    method =
                        definition:get_method(
                            hook_info.signature
                        )
                end)

                local method_key =
                    method ~= nil
                    and tostring(method)
                    or nil

                if method ~= nil
                    and installed_methods[method_key] ~= true
                then
                    local info =
                        hook_info

                    local declared_type =
                        type_name

                    local current_object = nil
                    local current_label = "unknown"

                    local ok =
                        pcall(function()
                            sdk.hook(
                                method,
                                function(args)
                                    local object =
                                        resolve_reload_action_arg(
                                            args
                                        )

                                    current_object =
                                        object

                                    action_speed.reload_action[
                                        info.counter
                                    ] =
                                        action_speed.reload_action[
                                            info.counter
                                        ] + 1

                                    local runtime_type =
                                        object ~= nil
                                        and object_type_name(object)
                                        or "unknown"

                                    current_label =
                                        runtime_type
                                        .. "."
                                        .. info.signature
                                        .. " via "
                                        .. declared_type

                                    if info.mode == "apply" then
                                        action_speed.reload_action.post_apply_calls =
                                            action_speed.reload_action.post_apply_calls + 1

                                        apply_rate(
                                            current_object,
                                            current_label .. " [post]"
                                        )
                                    else
                                        restore_rate(
                                            current_object,
                                            current_label .. " [post]"
                                        )
                                    end

                                    current_object = nil
                                    current_label = "unknown"

                                    return retval
                                end
                            )
                        end)

                    if ok then
                        installed_methods[method_key] = true
                        installed = installed + 1
                    end
                end
            end
        end
    end

    action_speed.reload_action.installed_hooks =
        installed

    action_speed.reload_action.installed =
        installed > 0

    action_speed.reload_action.status =
        installed > 0
        and (
            "Installed "
            .. tostring(installed)
            .. " unique base/derived reload lifecycle hook(s)."
        )
        or "No reload action-rate hooks resolved."

    return installed > 0
end

local function normalize_load_transition_speed(raw_speed)
    local body =
        action_speed.body_movement

    raw_speed =
        tonumber(raw_speed) or 0.0

    body.last_raw_speed =
        raw_speed

    if body.load_normalization_active ~= true then
        body.last_normalized_speed =
            raw_speed

        return raw_speed
    end

    local old_base =
        tonumber(
            body.load_normalization_old_base
        ) or 0.0

    local old_applied =
        tonumber(
            body.load_normalization_old_applied
        ) or 0.0

    local old_multiplier =
        tonumber(
            body.load_normalization_old_multiplier
        ) or 1.0

    local tolerance =
        math.max(
            0.001,
            math.abs(old_applied) * 0.01
        )

    if old_multiplier > 1.0001
        and old_applied > 0.0
        and math.abs(
            raw_speed - old_applied
        ) <= tolerance
    then
        local normalized =
            old_base > 0.0
            and old_base
            or (
                raw_speed
                / old_multiplier
            )

        body.load_normalization_hits =
            body.load_normalization_hits + 1

        body.last_normalized_speed =
            normalized

        body.load_normalization_status =
            string.format(
                "Normalized stale loaded speed %.4f -> %.4f by removing prior %.3fx multiplier.",
                raw_speed,
                normalized,
                old_multiplier
            )

        return normalized
    end

    body.load_normalization_active =
        false

    body.load_normalization_clears =
        body.load_normalization_clears + 1

    body.last_normalized_speed =
        raw_speed

    body.load_normalization_status =
        string.format(
            "Fresh native movement value %.4f observed; load normalization released.",
            raw_speed
        )

    return raw_speed
end

local function install_body_movement_hooks(ctx)
    if action_speed.body_movement.installed then
        return true
    end

    local definition =
        sdk.find_type_definition(
            "chainsaw.PlayerBodyUpdater"
        )

    if definition == nil then
        action_speed.body_movement.status =
            "PlayerBodyUpdater type not found."

        return false
    end

    local installed = 0

    local update_method = nil
    pcall(function()
        update_method =
            definition:get_method(
                "updateMotionSpeed()"
            )
    end)

    if update_method ~= nil then
        local ok =
            pcall(function()
                sdk.hook(
                    update_method,
                    function(args)
                        local object = nil

                        pcall(function()
                            object =
                                sdk.to_managed_object(
                                    args[2]
                                )
                        end)

                        action_speed.body_movement.update_calls =
                            action_speed.body_movement.update_calls + 1

                        action_speed.body_movement.last_method =
                            "updateMotionSpeed"

                        if object ~= nil then
                            action_speed.body_movement.pointer =
                                object_pointer(
                                    ctx,
                                    object
                                )

                            action_speed.body_movement.type_name =
                                object_type_name(
                                    object
                                )
                        end

                        return sdk.PreHookResult.CALL_ORIGINAL
                    end,
                    function(retval)
                        return retval
                    end
                )
            end)

        if ok then
            installed = installed + 1
        end
    end

    local getter_method = nil
    pcall(function()
        getter_method =
            definition:get_method(
                "getNextMotionSpeed()"
            )
    end)

    if getter_method ~= nil then
        local current_body_object = nil

        local ok =
            pcall(function()
                sdk.hook(
                    getter_method,
                    function(args)
                        local object = nil

                        pcall(function()
                            object =
                                sdk.to_managed_object(
                                    args[2]
                                )
                        end)

                        current_body_object =
                            object

                        action_speed.body_movement.last_method =
                            "getNextMotionSpeed"

                        if object ~= nil then
                            action_speed.body_movement.pointer =
                                object_pointer(
                                    ctx,
                                    object
                                )

                            action_speed.body_movement.type_name =
                                object_type_name(
                                    object
                                )
                        end
                    end,
                    function(retval)
                        local raw_speed =
                            sdk.to_float(
                                retval
                            )

                        local base_speed =
                            normalize_load_transition_speed(
                                raw_speed
                            )

                        local walk_run_active =
                            evaluate_walk_run_gate(
                                current_body_object
                            )

                        local multiplier =
                            walk_run_active
                            and movement_multiplier()
                            or 1.0

                        local applied_speed =
                            base_speed

                        if walk_run_active
                            and base_speed > 0.0
                        then
                            applied_speed =
                                base_speed * multiplier
                        end

                        action_speed.body_movement.getter_calls =
                            action_speed.body_movement.getter_calls + 1

                        action_speed.body_movement.last_base_speed =
                            base_speed

                        action_speed.body_movement.last_applied_speed =
                            applied_speed

                        action_speed.body_movement.last_multiplier =
                            multiplier

                        action_speed.body_movement.status =
                            walk_run_active
                            and (
                                action_speed.body_movement.load_normalization_active
                                and string.format(
                                    "Walk/run raw %.4f, normalized %.4f -> %.4f at %.3fx.",
                                    raw_speed,
                                    base_speed,
                                    applied_speed,
                                    multiplier
                                )
                                or string.format(
                                    "Walk/run speed %.4f -> %.4f at %.3fx.",
                                    base_speed,
                                    applied_speed,
                                    multiplier
                                )
                            )
                            or string.format(
                                "Non-locomotion motion preserved at %.4f.",
                                base_speed
                            )

                        action_speed.movement.status =
                            action_speed.body_movement.status

                        action_speed.movement.last_multiplier =
                            multiplier

                        return sdk.float_to_ptr(
                            applied_speed
                        )
                    end
                )
            end)

        if ok then
            installed = installed + 1
        end
    end

    local setter_method = nil
    pcall(function()
        setter_method =
            definition:get_method(
                "setMotionSpeedFromAction(System.Single)"
            )
    end)

    if setter_method ~= nil then
        local ok =
            pcall(function()
                sdk.hook(
                    setter_method,
                    function(_args)
                        action_speed.body_movement.setter_calls =
                            action_speed.body_movement.setter_calls + 1

                        action_speed.body_movement.last_method =
                            "setMotionSpeedFromAction"

                        -- Diagnostic-only. Modifying this argument could
                        -- overlap with getNextMotionSpeed and double-apply.
                        return sdk.PreHookResult.CALL_ORIGINAL
                    end,
                    function(retval)
                        return retval
                    end
                )
            end)

        if ok then
            installed = installed + 1
        end
    end

    action_speed.body_movement.installed_hooks =
        installed

    action_speed.body_movement.installed =
        installed > 0

    action_speed.body_movement.status =
        installed > 0
        and (
            "Installed "
            .. tostring(installed)
            .. " PlayerBodyUpdater movement hook(s)."
        )
        or "No PlayerBodyUpdater movement hooks resolved."

    return installed > 0
end

local function clear_reload_behavior_mutations()
    local restored = 0

    for pointer, tracked in pairs(
        action_speed.reload_action.active_objects
    ) do
        if tracked ~= nil then
            if tracked.mode == "rate"
                and tracked.object ~= nil
                and tracked.base_rate ~= nil
            then
                local ok =
                    pcall(function()
                        tracked.object:set_field(
                            "_McReloadSpeedRate",
                            tracked.base_rate
                        )
                    end)

                if ok then
                    restored = restored + 1
                end
            elseif tracked.mode == "motion" then
                for _, layer_info in pairs(
                    tracked.layers or {}
                ) do
                    local ok =
                        pcall(function()
                            layer_info.object:call(
                                "set_Speed",
                                layer_info.base
                            )
                        end)

                    if ok then
                        restored = restored + 1
                    end
                end
            end
        end

        action_speed.reload_action.active_objects[
            pointer
        ] = nil
    end

    action_speed.reload_action.cleanup_runs =
        action_speed.reload_action.cleanup_runs + 1

    action_speed.reload_action.cleanup_values_restored =
        action_speed.reload_action.cleanup_values_restored
        + restored

    action_speed.reload_action.motion_layers_applied = 0
    action_speed.reload_action.motion_layers_restored =
        action_speed.reload_action.motion_layers_restored
        + restored

    return restored
end

local function hook_native_getter(type_definition, method, definition)
    sdk.hook(method, function(args)
        if definition.channel == "movement" then
            local object = nil
            pcall(function() object = sdk.to_managed_object(args[2]) end)
            capture_movement_object(object, "native movement getter")
        end
    end, function(retval)
        local base_value = sdk.to_float(retval)
        local multiplier =
            channel_multiplier(
                definition.channel
            )
        local applied_value = base_value

        if definition.mode == "duration" then
            if multiplier > 0.0 then
                applied_value = base_value / multiplier
            end
        else
            applied_value = base_value * multiplier
        end

        local channel =
            action_speed.native.channels[definition.channel]
        channel.count = channel.count + 1
        channel.base = base_value
        channel.applied = applied_value
        channel.multiplier = multiplier
        action_speed.last_multiplier = multiplier

        if definition.channel == "movement" then
            action_speed.movement.last_multiplier =
                multiplier

            action_speed.movement.status =
                string.format(
                    "Native walk/run getter applied %.3fx: %.4f -> %.4f.",
                    multiplier,
                    base_value,
                    applied_value
                )
        elseif definition.channel == "reload" then
            action_speed.reload_action.last_base_rate =
                base_value

            action_speed.reload_action.last_applied_rate =
                applied_value

            action_speed.reload_action.last_multiplier =
                multiplier

            local restored =
                clear_reload_behavior_mutations()

            action_speed.reload_action.application_mode =
                "chainsaw.Gun.get_ReloadSpeedRate"

            action_speed.reload_action.direct_gun_path_active =
                true

            action_speed.reload_action.behavior_tree_application_suppressed =
                true

            action_speed.reload_action.write_confirmed =
                true

            action_speed.reload_action.last_type =
                "chainsaw.Gun"

            action_speed.reload_action.last_method =
                definition.method_name or "get_ReloadSpeedRate"

            action_speed.reload_action.last_native_duration_scale =
                base_value > 0.0
                and (1.0 / base_value)
                or 0.0

            action_speed.reload_action.last_applied_duration_scale =
                applied_value > 0.0
                and (1.0 / applied_value)
                or 0.0

            action_speed.reload_action.last_duration_ratio =
                multiplier > 0.0
                and (1.0 / multiplier)
                or 1.0

            action_speed.reload_action.last_duration_reduction_percent =
                math.max(
                    0.0,
                    (
                        1.0
                        - action_speed.reload_action.last_duration_ratio
                    ) * 100.0
                )

            action_speed.reload_action.status =
                string.format(
                    "Gun reload rate %.4f -> %.4f at %.3fx; restored %d legacy behavior-tree value(s).",
                    base_value,
                    applied_value,
                    multiplier,
                    restored
                )
        end

        return sdk.float_to_ptr(applied_value)
    end)
end

local function install_native_hooks()
    if action_speed.native.installed then return true end

    action_speed.native.failed_hooks = {}
    local installed = 0

    for _, definition in ipairs(NATIVE_GETTER_HOOKS) do
        local type_definition =
            sdk.find_type_definition(definition.type_name)

        if type_definition == nil then
            action_speed.native.failed_hooks[#action_speed.native.failed_hooks + 1] =
                definition.type_name .. " (type missing)"
        else
            local found_for_definition = 0
            for _, method_name in ipairs(definition.methods) do
                local method = nil
                pcall(function()
                    method = type_definition:get_method(method_name)
                end)

                if method ~= nil then
                    local ok, error_text = pcall(function()
                        hook_native_getter(type_definition, method, definition)
                    end)
                    if ok then
                        installed = installed + 1
                        found_for_definition = found_for_definition + 1
                    else
                        action_speed.native.failed_hooks[#action_speed.native.failed_hooks + 1] =
                            definition.type_name .. "." .. method_name ..
                            ": " .. tostring(error_text)
                    end

                    if definition.install_all ~= true then break end
                end
            end

            if found_for_definition == 0 then
                action_speed.native.failed_hooks[#action_speed.native.failed_hooks + 1] =
                    definition.type_name .. "." .. definition.methods[1] ..
                    " (method missing)"
            end
        end
    end

    action_speed.native.installed_hooks = installed
    action_speed.native.installed = installed > 0
    action_speed.native.status = string.format(
        "Installed %d native player speed hook(s); %d unresolved.",
        installed,
        #action_speed.native.failed_hooks
    )
    return action_speed.native.installed
end

local function add_candidate(results, seen, owner, kind, name, type_name)
    local key = owner .. "|" .. kind .. "|" .. name
    if seen[key] then return end
    seen[key] = true
    results[#results + 1] = {
        owner = owner,
        kind = kind,
        name = name,
        type_name = type_name or "unknown"
    }
end

local function scan_type(results, seen, type_definition)
    if type_definition == nil then return end
    local owner = safe_type_name(type_definition)
    local fields = {}
    local methods = {}

    pcall(function() fields = type_definition:get_fields() or {} end)
    pcall(function() methods = type_definition:get_methods() or {} end)

    for index, field in ipairs(fields) do
        if index > 256 then break end
        local name = safe_name(field)
        if is_candidate(name) then
            local field_type = "unknown"
            pcall(function()
                field_type = safe_type_name(field:get_type())
            end)
            add_candidate(results, seen, owner, "field", name, field_type)
        end
    end

    for index, method in ipairs(methods) do
        if index > 512 then break end
        local name = safe_name(method)
        if is_candidate(name) then
            add_candidate(results, seen, owner, "method", name, "")
        end
    end
end

local function restore_tracked_movement_baselines()
    local movement =
        action_speed.movement

    local restored = 0

    if movement.object ~= nil then
        for field_name, base_value in pairs(
            movement.fields or {}
        ) do
            local ok =
                pcall(function()
                    movement.object:set_field(
                        field_name,
                        base_value
                    )
                end)

            if ok then
                restored = restored + 1
            end
        end
    end

    return restored
end

function action_speed.begin_native_load()
    local movement =
        action_speed.movement

    local body =
        action_speed.body_movement

    local previous_base =
        tonumber(
            body.last_base_speed
        ) or 0.0

    local previous_applied =
        tonumber(
            body.last_applied_speed
        ) or 0.0

    local previous_multiplier =
        tonumber(
            body.last_multiplier
        ) or 1.0

    body.load_normalization_old_base =
        previous_base

    body.load_normalization_old_applied =
        previous_applied

    body.load_normalization_old_multiplier =
        previous_multiplier

    body.load_normalization_active =
        previous_base > 0.0
        and previous_applied > 0.0
        and previous_multiplier > 1.0001

    body.load_normalization_status =
        body.load_normalization_active
        and string.format(
            "Armed for prior movement signature %.4f -> %.4f at %.3fx.",
            previous_base,
            previous_applied,
            previous_multiplier
        )
        or "Not armed; previous save had no amplified movement signature."

    local restored =
        restore_tracked_movement_baselines()

    movement.load_resets =
        movement.load_resets + 1

    movement.load_restore_count =
        movement.load_restore_count + restored

    movement.object = nil
    movement.pointer = "nil"
    movement.fields = {}
    movement.needs_apply = false
    movement.last_multiplier = nil
    movement.field_write_mode = false
    movement.capture_source = "none"
    movement.capture_attempts = 0
    movement.graph_scans = 0
    movement.graph_objects_inspected = 0
    movement.last_graph_scan_clock = 0

    action_speed.player_context = nil
    action_speed.player_context_ptr = "nil"
    action_speed.player_context_type = "unknown"
    action_speed.player_capture_status =
        "Native load reset; waiting for fresh player context."

    if action_speed.body_movement ~= nil then
        action_speed.body_movement.object = nil
        action_speed.body_movement.pointer = "nil"
        action_speed.body_movement.last_raw_speed = 0.0
        action_speed.body_movement.last_normalized_speed = 0.0
        action_speed.body_movement.status =
            "Native load reset; waiting for fresh PlayerBodyUpdater."
    end

    movement.last_load_reset_status =
        string.format(
            "Restored %d tracked movement field(s); caches cleared for native load.",
            restored
        )

    movement.status =
        movement.last_load_reset_status

    return restored
end

function action_speed.scan()
    local object = action_speed.player_context
    local results = {}
    local seen = {}
    local ok, error_text = pcall(function()
        for _, type_name in ipairs(STATIC_TYPE_CANDIDATES) do
            local static_type = sdk.find_type_definition(type_name)
            if static_type ~= nil then
                local depth = 0
                local current_type = static_type
                while current_type ~= nil and depth < 6 do
                    scan_type(results, seen, current_type)
                    current_type = current_type:get_parent_type()
                    depth = depth + 1
                end

                -- The declared field types reveal the updater's direct
                -- controller/component relationships without a live object.
                local fields = static_type:get_fields() or {}
                for index, field in ipairs(fields) do
                    if index > 256 then break end
                    local field_type = nil
                    pcall(function() field_type = field:get_type() end)
                    if field_type ~= nil then
                        scan_type(results, seen, field_type)
                    end
                end
            end
        end

        if object ~= nil then
            local type_definition = object:get_type_definition()
            local depth = 0
            while type_definition ~= nil and depth < 8 do
                scan_type(results, seen, type_definition)
                type_definition = type_definition:get_parent_type()
                depth = depth + 1
            end

            local root_type = object:get_type_definition()
            local fields = root_type:get_fields() or {}
            for index, field in ipairs(fields) do
                if index > 192 then break end
                local field_name = safe_name(field)
                local value = nil
                pcall(function() value = object:get_field(field_name) end)
                if value ~= nil then
                    local referenced_type = nil
                    pcall(function()
                        referenced_type = value:get_type_definition()
                    end)
                    if referenced_type ~= nil then
                        local reference_depth = 0
                        while referenced_type ~= nil and reference_depth < 4 do
                            scan_type(results, seen, referenced_type)
                            referenced_type = referenced_type:get_parent_type()
                            reference_depth = reference_depth + 1
                        end
                    end
                end
            end
        end
    end)

    if not ok then
        action_speed.last_error = tostring(error_text)
        action_speed.last_status = "Action-speed scan failed."
        return false
    end

    table.sort(results, function(a, b)
        local left = a.owner .. a.name
        local right = b.owner .. b.name
        return left < right
    end)

    action_speed.candidates = results
    action_speed.scan_count = action_speed.scan_count + 1
    action_speed.last_error = ""
    action_speed.last_status = string.format(
        "Scanned native player/action types; found %d candidate(s).",
        #results
    )
    return true
end

function action_speed.update(ctx)
    action_speed.hook_installed = true
    install_movement_userdata_hook()
    install_movement_live_capture_hooks()
    install_player_capture_hook(ctx)
    install_reload_action_rate_hooks(ctx)
    install_body_movement_hooks(ctx)
    install_native_hooks()
    install_weapon_param_probe(ctx)
    install_equipment_action_hooks(ctx)
    update_movement_fields()
    if action_speed.scan_count == 0 then
        action_speed.scan()
    end
    update_movement_fields()

    local object =
        ctx.state.player
        or action_speed.player_context

    if object == nil then
        action_speed.player_capture_status =
            "Waiting for PlayerCharacterContext callback; movement capture hooks remain active."

        return true
    end

    capture_action_speed_player(
        ctx,
        object,
        "shared player state"
    )

    if action_speed.movement.object == nil then
        capture_movement_from_player_graph(ctx)
    end

    update_movement_fields()

    local pointer = ctx.ptr_from_obj(object)
    if pointer ~= action_speed.player_context_ptr then
        action_speed.player_context = object
        action_speed.player_context_ptr = pointer
        action_speed.player_context_type = ctx.type_name_from_obj(object)
        action_speed.hook_calls = action_speed.hook_calls + 1
        action_speed.scan()
        discover_player_animations(ctx)
        return true
    end

    if os.clock() - action_speed.last_target_scan_clock >= 1.0 then
        discover_player_animations(ctx)
    end
    return true
end

return action_speed
