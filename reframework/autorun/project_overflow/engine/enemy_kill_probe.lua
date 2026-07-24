------------------------------------------------------------
-- Maintenance classification — Build 49.39
-- Module: autorun/project_overflow/engine/enemy_kill_probe.lua
-- Role: RE Engine reflection, capture, inspection, or runtime integration.
-- Status: active diagnostic/runtime support.
--
-- Compatibility policy:
--   Existing functions, hooks, module paths, and diagnostics are
--   intentionally retained in this maintenance pass.
--   `DEPRECATED` marks a supported legacy path, not removed code.
------------------------------------------------------------

------------------------------------------------------------
-- Project: Overflow — Native Enemy Death Probe
--
-- Hooks EnemyManager.notifyDead(), which directly supplies the dead
-- EnemyBaseContext. This avoids guessing ownership from HitPoint and
-- gives us the live CharacterKindID, concrete context type, spawn
-- parameters, health objects, and enemy-specific context properties.
--
-- The release startup installs this probe automatically. Confirmed death
-- snapshots flow through the enemy pipeline and award resolved XP.
------------------------------------------------------------

local registry =
    require("project_overflow.systems.enemies.registry")

local reflection_snapshot =
    require("project_overflow.engine.reflection_snapshot")

local probe = {
    installed = false,
    install_attempted = false,
    enabled = true,

    resolved_method = "none",
    resolved_methods = {},
    installed_method_count = 0,
    install_error = "",

    raw_hook_calls = 0,
    notify_calls = 0,
    processed_dead_calls = 0,
    fallback_recorded_calls = 0,
    recorded_calls = 0,
    duplicate_calls = 0,
    context_scan_failures = 0,

    last_event = "none",
    last_context_type = "unknown",
    last_kind_id = "unknown",
    last_spawn_id = "unknown",
    last_segment_id = "unknown",
    last_stage_id = "unknown",
    last_game_rank_add = "unknown",
    last_item_drop_count = "unknown",
    last_strong_individual = "unknown",
    last_is_true_dead = "unknown",
    last_is_eliminated = "unknown",
    last_is_processed_on_dead = "unknown",
    last_character_parameter_type = "unknown",
    last_character_parameter_ptr = "nil",
    last_parameter_signature = "unknown",
    last_source_method = "none",

    recent_contexts = {}
}

local MANAGER_TYPE =
    "chainsaw.EnemyManager"

local CHARACTER_CONTEXT_TYPE =
    "chainsaw.CharacterContext"

local METHOD_NAMES = {
    "notifyDead(chainsaw.HitController.DamageInfo, chainsaw.EnemyBaseContext)",
    "notifyDead"
}

local function safe_call(object, method_name, ...)
    if object == nil then
        return nil
    end

    local args = { ... }

    local ok, result =
        pcall(function()
            return object:call(
                method_name,
                table.unpack(args)
            )
        end)

    if ok then
        return result
    end

    return nil
end

local function safe_field(object, field_name)
    if object == nil then
        return nil
    end

    local ok, result =
        pcall(function()
            return object:get_field(field_name)
        end)

    if ok then
        return result
    end

    return nil
end

local function pointer_text(ctx, object)
    if object == nil then
        return "nil"
    end

    local ok, result =
        pcall(function()
            return ctx.ptr_string(object)
        end)

    if ok and result ~= nil then
        return tostring(result)
    end

    return tostring(object)
end

local function enum_text(value)
    if value == nil then
        return "unknown"
    end

    local ok, text =
        pcall(function()
            return value:call("ToString")
        end)

    if ok and text ~= nil then
        return tostring(text)
    end

    return tostring(value)
end

local function value_text(value)
    if value == nil then
        return "unknown"
    end

    return tostring(value)
end

local function looks_like_enemy_context(ctx, object)
    if object == nil then
        return false
    end

    local type_name =
        tostring(
            ctx.type_name_from_obj(object) or ""
        )

    return
        type_name == "chainsaw.EnemyBaseContext" or
        string.find(type_name, "Context", 1, true) ~= nil and
        (
            safe_call(object, "get_KindID") ~= nil or
            safe_call(object, "get_IsEliminated") ~= nil or
            safe_call(object, "get_HitPoint") ~= nil
        )
end

local function find_enemy_context(ctx, args)
    -- REFramework normally exposes:
    -- args[2] = EnemyManager instance
    -- args[3] = DamageInfo
    -- args[4] = EnemyBaseContext
    --
    -- Scan a small range so the probe survives minor signature/binding
    -- differences across REFramework builds.
    for index = 2, 9 do
        local object =
            ctx.managed_from_arg(
                args,
                index
            )

        if looks_like_enemy_context(ctx, object) then
            return object, index
        end
    end

    return nil, nil
end

local function read_spawn_values(context)
    local spawn_param =
        safe_call(
            context,
            "get_CharacterSpawnParam"
        )

    if spawn_param == nil then
        spawn_param =
            safe_field(
                context,
                "<CharacterSpawnParam>k__BackingField"
            )
    end

    local segment_id = nil
    local game_rank_add = nil
    local drop_item_id = nil
    local drop_item_count = nil

    if spawn_param ~= nil then
        segment_id =
            safe_call(
                spawn_param,
                "get_SegmentID"
            )

        game_rank_add =
            safe_call(
                spawn_param,
                "get_GameRankAdd"
            )

        drop_item_id =
            safe_call(
                spawn_param,
                "get_DropItemID"
            )

        drop_item_count =
            safe_call(
                spawn_param,
                "get_DropItemCount"
            )
    end

    return {
        object = spawn_param,
        type_name = spawn_param ~= nil
            and value_text(
                spawn_param:get_type_definition():get_full_name()
            )
            or "unknown",
        segment_id = value_text(segment_id),
        game_rank_add = value_text(game_rank_add),
        drop_item_id = enum_text(drop_item_id),
        drop_item_count = value_text(drop_item_count)
    }
end

local PARAMETER_METHODS = {
    "get_WeaponID",
    "get_WeaponType",
    "get_EquipWeaponID",
    "get_EquipmentID",
    "get_CostumeID",
    "get_CostumePresetID",
    "get_CharacterKindID",
    "get_KindID",
    "get_VariantID",
    "get_ModelID",
    "get_BodyType",
    "get_SexType"
}

local PARAMETER_FIELDS = {
    "_WeaponID",
    "<WeaponID>k__BackingField",
    "_WeaponType",
    "<WeaponType>k__BackingField",
    "_EquipWeaponID",
    "<EquipWeaponID>k__BackingField",
    "_EquipmentID",
    "<EquipmentID>k__BackingField",
    "_CostumeID",
    "<CostumeID>k__BackingField",
    "_CostumePresetID",
    "<CostumePresetID>k__BackingField",
    "_VariantID",
    "<VariantID>k__BackingField",
    "_ModelID",
    "<ModelID>k__BackingField",
    "_BodyType",
    "<BodyType>k__BackingField",
    "_SexType",
    "<SexType>k__BackingField"
}

local function safe_type_name(ctx, object)
    if object == nil then
        return "unknown"
    end

    local ok, result =
        pcall(function()
            return ctx.type_name_from_obj(object)
        end)

    if ok and result ~= nil then
        return tostring(result)
    end

    return "type error"
end

local function read_character_parameter(ctx, context)
    local parameter =
        safe_call(
            context,
            "get_CharacterParameter"
        )

    if parameter == nil then
        parameter =
            safe_field(
                context,
                "<CharacterParameter>k__BackingField"
            )
    end

    local result = {
        object = parameter,
        type_name = safe_type_name(ctx, parameter),
        ptr = pointer_text(ctx, parameter),
        values = {},
        signature = "none"
    }

    if parameter == nil then
        return result
    end

    -- Probe only a small whitelist of likely identity/loadout members.
    -- This avoids broad reflection walks while the enemy is being torn down.
    for _, method_name in ipairs(PARAMETER_METHODS) do
        local value =
            safe_call(
                parameter,
                method_name
            )

        if value ~= nil then
            result.values[#result.values + 1] = {
                source = method_name .. "()",
                value = enum_text(value)
            }
        end
    end

    for _, field_name in ipairs(PARAMETER_FIELDS) do
        local value =
            safe_field(
                parameter,
                field_name
            )

        if value ~= nil then
            result.values[#result.values + 1] = {
                source = field_name,
                value = enum_text(value)
            }
        end
    end

    if #result.values == 0 then
        result.signature =
            result.type_name ..
            " | no whitelisted loadout members resolved"
    else
        local parts = {}

        for _, entry in ipairs(result.values) do
            parts[#parts + 1] =
                entry.source ..
                "=" ..
                entry.value
        end

        result.signature =
            result.type_name ..
            " | " ..
            table.concat(parts, "; ")
    end

    return result
end

local function vector_component(vector, name)
    if vector == nil then return nil end

    local ok, result = pcall(function()
        return vector[name]
    end)

    if ok and result ~= nil then
        return tonumber(result)
    end

    ok, result = pcall(function()
        return vector:get_field(name)
    end)

    if ok and result ~= nil then
        return tonumber(result)
    end

    return nil
end

local function read_world_position(context)
    local position = safe_call(context, "get_Position")

    if position == nil then
        local game_object = safe_call(context, "get_BodyGameObject")
        local transform = safe_call(game_object, "get_Transform")
        position = safe_call(transform, "get_Position")
    end

    return {
        x = vector_component(position, "x"),
        y = vector_component(position, "y"),
        z = vector_component(position, "z")
    }
end


------------------------------------------------------------
-- Targeted Ganado costume snapshot
--
-- Reads only known BodyUpdater / CostumeDriver references and the
-- eight trivial costume-slot getters. It does not recurse through
-- referenced objects, enumerate inherited fields, or retain managed
-- objects after notifyDead returns.
------------------------------------------------------------

local BODY_UPDATER_METHODS = {
    "get_BodyUpdater",
    "get_BodyUpdaterCommon",
    "get_CharacterBodyUpdater"
}

local BODY_UPDATER_FIELDS = {
    "<BodyUpdater>k__BackingField",
    "_BodyUpdater",
    "BodyUpdater"
}

local COSTUME_DRIVER_METHODS = {
    "get_CostumeDriver",
    "get_BodyCostumeDriver"
}

local COSTUME_DRIVER_FIELDS = {
    "<CostumeDriver>k__BackingField",
    "_CostumeDriver",
    "CostumeDriver"
}

local COSTUME_SLOTS = {
    {
        name = "Body",
        methods = { "get_BodyUnit" },
        fields = { "_BodyUnit" }
    },
    {
        name = "Head",
        methods = { "get_Head_HumanUnit", "get_HeadUnit" },
        fields = { "_HeadUnit" }
    },
    {
        name = "Jacket",
        methods = { "get_JacketUnit" },
        fields = { "_JacketUnit" }
    },
    {
        name = "Jacket2",
        methods = { "get_Jacket2Unit" },
        fields = { "_Jacket2Unit" }
    },
    {
        name = "Pants",
        methods = { "get_PantsUnit" },
        fields = { "_PantsUnit" }
    },
    {
        name = "Props1",
        methods = { "get_Props1Unit" },
        fields = { "_Props1Unit" }
    },
    {
        name = "Props2",
        methods = { "get_Props2Unit" },
        fields = { "_Props2Unit" }
    },
    {
        name = "Props3",
        methods = { "get_Props3Unit" },
        fields = { "_Props3Unit" }
    }
}

local SAFE_SCALAR_TYPES = {
    ["System.Boolean"] = true,
    ["System.Byte"] = true,
    ["System.SByte"] = true,
    ["System.Int16"] = true,
    ["System.UInt16"] = true,
    ["System.Int32"] = true,
    ["System.UInt32"] = true,
    ["System.Int64"] = true,
    ["System.UInt64"] = true,
    ["System.Single"] = true,
    ["System.Double"] = true,
    ["System.String"] = true
}

local function first_method_value(object, method_names)
    for _, method_name in ipairs(method_names or {}) do
        local value = safe_call(object, method_name)

        if value ~= nil then
            return value, method_name .. "()"
        end
    end

    return nil, "none"
end

local function first_field_value(object, field_names)
    for _, field_name in ipairs(field_names or {}) do
        local value = safe_field(object, field_name)

        if value ~= nil then
            return value, field_name
        end
    end

    return nil, "none"
end

local function first_member_value(
    object,
    method_names,
    field_names
)
    local value, source =
        first_method_value(
            object,
            method_names
        )

    if value ~= nil then
        return value, source
    end

    return
        first_field_value(
            object,
            field_names
        )
end

local function field_declared_type(field)
    local ok, result =
        pcall(function()
            local field_type = field:get_type()

            if field_type == nil then
                return "unknown"
            end

            return field_type:get_full_name()
        end)

    if ok and result ~= nil then
        return tostring(result)
    end

    return "unknown"
end

local function is_safe_scalar_type(type_name)
    if SAFE_SCALAR_TYPES[type_name] == true then
        return true
    end

    -- Enum/value-type names are retained as text only when the field can
    -- be read directly. Reference types are represented by runtime type
    -- and pointer without traversing them.
    return
        string.find(type_name, "System.Nullable", 1, true) ~= nil or
        string.find(type_name, "chainsaw.", 1, true) ~= nil and
        string.find(type_name, "Enum", 1, true) ~= nil
end

local function capture_unit_fields(ctx, unit)
    local rows = {}

    if unit == nil then
        return rows, ""
    end

    local ok, error_text =
        pcall(function()
            local type_definition =
                unit:get_type_definition()

            if type_definition == nil then
                return
            end

            local fields =
                type_definition:get_fields()
                or {}

            for index, field in ipairs(fields) do
                if index > 32 then
                    break
                end

                local field_name = "unknown"

                pcall(function()
                    field_name =
                        tostring(
                            field:get_name()
                        )
                end)

                local declared_type =
                    field_declared_type(field)

                local read_ok, value =
                    pcall(function()
                        return field:get_data(unit)
                    end)

                if read_ok then
                    local runtime_type =
                        safe_type_name(
                            ctx,
                            value
                        )

                    rows[#rows + 1] = {
                        name = field_name,
                        declared_type = declared_type,
                        value =
                            is_safe_scalar_type(declared_type)
                            and enum_text(value)
                            or "<reference>",
                        runtime_type = runtime_type,
                        ptr = pointer_text(ctx, value)
                    }
                else
                    rows[#rows + 1] = {
                        name = field_name,
                        declared_type = declared_type,
                        value = "<read failed>",
                        runtime_type = "unknown",
                        ptr = "nil"
                    }
                end
            end
        end)

    if ok then
        return rows, ""
    end

    return rows, tostring(error_text)
end

local function capture_costume_slot(
    ctx,
    costume_driver,
    slot
)
    local unit, source =
        first_member_value(
            costume_driver,
            slot.methods,
            slot.fields
        )

    local fields, field_error =
        capture_unit_fields(
            ctx,
            unit
        )

    return {
        name = slot.name,
        source = source,
        is_null = unit == nil,
        type_name = safe_type_name(ctx, unit),
        ptr = pointer_text(ctx, unit),
        fields = fields,
        field_error = field_error
    }
end

local function read_costume_snapshot(ctx, context)
    local body_updater, body_source =
        first_member_value(
            context,
            BODY_UPDATER_METHODS,
            BODY_UPDATER_FIELDS
        )

    -- Some contexts expose a body driver first. Keep the lookup shallow:
    -- one context member, then one updater member.
    local costume_driver = nil
    local costume_source = "none"

    if body_updater ~= nil then
        costume_driver, costume_source =
            first_member_value(
                body_updater,
                COSTUME_DRIVER_METHODS,
                COSTUME_DRIVER_FIELDS
            )
    end

    if costume_driver == nil then
        costume_driver, costume_source =
            first_member_value(
                context,
                COSTUME_DRIVER_METHODS,
                COSTUME_DRIVER_FIELDS
            )
    end

    local result = {
        body_updater_type =
            safe_type_name(
                ctx,
                body_updater
            ),
        body_updater_ptr =
            pointer_text(
                ctx,
                body_updater
            ),
        body_updater_source =
            body_source,

        costume_driver_type =
            safe_type_name(
                ctx,
                costume_driver
            ),
        costume_driver_ptr =
            pointer_text(
                ctx,
                costume_driver
            ),
        costume_driver_source =
            costume_source,

        slots = {},
        signature = "unresolved"
    }

    if costume_driver == nil then
        result.signature =
            "costume_driver=unresolved"

        return result
    end

    local signature_parts = {
        "driver=" ..
        result.costume_driver_type
    }

    for _, slot in ipairs(COSTUME_SLOTS) do
        local captured =
            capture_costume_slot(
                ctx,
                costume_driver,
                slot
            )

        result.slots[#result.slots + 1] =
            captured

        signature_parts[#signature_parts + 1] =
            string.lower(slot.name) ..
            "=" ..
            (
                captured.is_null
                and "nil"
                or captured.type_name ..
                "@" ..
                captured.ptr
            )
    end

    result.signature =
        table.concat(
            signature_parts,
            "|"
        )

    return result
end


local function read_context_snapshot(ctx, context)
    local context_type =
        ctx.type_name_from_obj(context)

    local kind_id =
        safe_call(
            context,
            "get_KindID"
        )

    local spawn_id =
        safe_call(
            context,
            "get_SpawnerID"
        )

    local stage_id =
        safe_call(
            context,
            "get_CurrentStageID"
        )

    local segment_id =
        safe_call(
            context,
            "get_SegmentID"
        )

    local is_eliminated =
        safe_call(
            context,
            "get_IsEliminated"
        )

    local is_processed =
        safe_call(
            context,
            "get_IsProcessedCharacterOnDead"
        )

    local is_true_dead =
        safe_call(
            context,
            "get_IsTrueDead"
        )

    local is_strong =
        safe_call(
            context,
            "get_IsStrongIndividual"
        )

    local game_rank_add =
        safe_call(
            context,
            "get_GameRankAdd"
        )

    local item_drop_count =
        safe_call(
            context,
            "get_ItemDropCount"
        )

    local hitpoint =
        safe_call(
            context,
            "get_HitPoint"
        )

    local vital =
        safe_call(
            context,
            "get_HitPointVital"
        )

    local spawn =
        read_spawn_values(context)

    local character_parameter =
        read_character_parameter(
            ctx,
            context
        )

    local weak_point_count =
        safe_call(
            context,
            "get_LiveWeakPointCount"
        )

    local body_game_object =
        safe_call(context, "get_BodyGameObject")

    local body_transform =
        safe_call(body_game_object, "get_Transform")

    local world_position = read_world_position(context)

    return {
        runtime = {
            context = context,
            body_game_object = body_game_object,
            body_transform = body_transform,
            hitpoint = hitpoint,
            vital = vital,
            character_parameter = character_parameter.object,
            spawn_parameter = spawn.object
        },
        context_type = value_text(context_type),
        context_ptr = pointer_text(ctx, context),
        world_position = world_position,

        kind_id = enum_text(kind_id),
        kind_id_raw = value_text(kind_id),
        spawn_id = enum_text(spawn_id),
        stage_id = enum_text(stage_id),
        segment_id = value_text(segment_id),

        is_eliminated = value_text(is_eliminated),
        is_processed_on_dead = value_text(is_processed),
        is_true_dead = value_text(is_true_dead),
        is_strong_individual = value_text(is_strong),

        game_rank_add = value_text(game_rank_add),
        item_drop_count = value_text(item_drop_count),

        hitpoint_type = hitpoint ~= nil
            and value_text(ctx.type_name_from_obj(hitpoint))
            or "unknown",

        vital_type = vital ~= nil
            and value_text(ctx.type_name_from_obj(vital))
            or "unknown",

        weak_point_count = value_text(weak_point_count),

        spawn_param_type = spawn.type_name,
        spawn_segment_id = spawn.segment_id,
        spawn_game_rank_add = spawn.game_rank_add,
        drop_item_id = spawn.drop_item_id,
        drop_item_count = spawn.drop_item_count,

        character_parameter_type =
            character_parameter.type_name,
        character_parameter_ptr =
            character_parameter.ptr,
        character_parameter_signature =
            character_parameter.signature,
        character_parameter_values =
            character_parameter.values,

        costume_snapshot =
            read_costume_snapshot(
                ctx,
                context
            ),

        character_parameter_reflection =
            reflection_snapshot.capture(
                ctx,
                character_parameter.object,
                "CharacterParameter"
            ),

        spawn_parameter_reflection =
            reflection_snapshot.capture(
                ctx,
                spawn.object,
                "CharacterSpawnParam"
            )
    }
end

local function update_last_snapshot(snapshot)
    probe.last_context_type =
        snapshot.context_type

    probe.last_kind_id =
        snapshot.kind_id

    probe.last_spawn_id =
        snapshot.spawn_id

    probe.last_segment_id =
        snapshot.spawn_segment_id ~= "unknown"
        and snapshot.spawn_segment_id
        or snapshot.segment_id

    probe.last_stage_id =
        snapshot.stage_id

    probe.last_game_rank_add =
        snapshot.spawn_game_rank_add ~= "unknown"
        and snapshot.spawn_game_rank_add
        or snapshot.game_rank_add

    probe.last_item_drop_count =
        snapshot.drop_item_count ~= "unknown"
        and snapshot.drop_item_count
        or snapshot.item_drop_count

    probe.last_strong_individual =
        snapshot.is_strong_individual

    probe.last_is_true_dead =
        snapshot.is_true_dead

    probe.last_is_eliminated =
        snapshot.is_eliminated

    probe.last_is_processed_on_dead =
        snapshot.is_processed_on_dead

    probe.last_character_parameter_type =
        snapshot.character_parameter_type

    probe.last_character_parameter_ptr =
        snapshot.character_parameter_ptr

    probe.last_parameter_signature =
        snapshot.character_parameter_signature

    probe.last_source_method =
        snapshot.source_method

    probe.last_event =
        string.format(
            "%s | %s",
            snapshot.kind_id,
            snapshot.context_type
        )
end

local function record_context(
    ctx,
    context,
    source_method,
    context_arg,
    is_fallback
)
    if context == nil then
        probe.context_scan_failures =
            probe.context_scan_failures + 1
        return false
    end

    if not looks_like_enemy_context(ctx, context) then
        return false
    end

    local snapshot =
        read_context_snapshot(
            ctx,
            context
        )

    local duplicate_key =
        snapshot.context_ptr

    local now = os.clock()
    local previous_time =
        tonumber(
            probe.recent_contexts[duplicate_key]
        ) or -100.0

    -- notifyDead and ProcessedCharacterOnDead can both fire for the same
    -- enemy. Keep one discovery/reward record for that death.
    if now - previous_time < 1.5 then
        probe.duplicate_calls =
            probe.duplicate_calls + 1
        return false
    end

    probe.recent_contexts[duplicate_key] =
        now

    snapshot.source_method =
        source_method

    snapshot.context_arg =
        context_arg

    registry.record_kill(snapshot)

    probe.recorded_calls =
        probe.recorded_calls + 1

    if is_fallback == true then
        probe.fallback_recorded_calls =
            probe.fallback_recorded_calls + 1
    end

    update_last_snapshot(snapshot)

    return true
end

local function handle_notify_dead(ctx, args)
    if probe.enabled ~= true then
        return
    end

    probe.notify_calls =
        probe.notify_calls + 1

    local context,
          context_arg =
        find_enemy_context(
            ctx,
            args
        )

    if context == nil then
        probe.context_scan_failures =
            probe.context_scan_failures + 1

        probe.last_event =
            "notifyDead fired, but EnemyBaseContext was not resolved."

        return
    end

    record_context(
        ctx,
        context,
        probe.resolved_method,
        context_arg,
        false
    )
end

local function bool_arg_is_true(args, index)
    local raw =
        args ~= nil
        and args[index]
        or nil

    if raw == nil then
        return false
    end

    local converters = {
        sdk.to_int64,
        sdk.to_int32,
        sdk.to_uint64,
        sdk.to_uint32
    }

    for _, converter in ipairs(converters) do
        if converter ~= nil then
            local ok, value =
                pcall(function()
                    return converter(raw)
                end)

            if ok and value ~= nil then
                return tonumber(value) ~= 0
            end
        end
    end

    return tostring(raw) == "true"
end

local function handle_processed_character_on_dead(ctx, args)
    if probe.enabled ~= true then
        return
    end

    -- args[2] = CharacterContext instance
    -- args[3] = System.Boolean value
    if not bool_arg_is_true(args, 3) then
        return
    end

    probe.processed_dead_calls =
        probe.processed_dead_calls + 1

    local context =
        ctx.managed_from_arg(
            args,
            2
        )

    record_context(
        ctx,
        context,
        CHARACTER_CONTEXT_TYPE ..
        ".set_IsProcessedCharacterOnDead(System.Boolean)",
        2,
        true
    )
end

local function method_identity(method)
    if method == nil then
        return "nil"
    end

    local full_name = nil

    pcall(function()
        full_name =
            method:get_full_name()
    end)

    return tostring(full_name or method)
end

local function method_simple_name(method)
    if method == nil then
        return ""
    end

    local name = nil

    pcall(function()
        name =
            method:get_name()
    end)

    return tostring(name or "")
end

local function collect_notify_dead_methods(type_definition)
    local methods = {}
    local seen = {}

    local all_methods = nil

    pcall(function()
        all_methods =
            type_definition:get_methods()
    end)

    for _, method in ipairs(all_methods or {}) do
        if method_simple_name(method) == "notifyDead" then
            local identity =
                method_identity(method)

            if seen[identity] ~= true then
                seen[identity] = true
                methods[#methods + 1] = method
            end
        end
    end

    -- Compatibility fallback for REFramework builds where get_methods()
    -- does not expose the method collection.
    if #methods == 0 then
        for _, method_name in ipairs(METHOD_NAMES) do
            local method = nil

            pcall(function()
                method =
                    type_definition:get_method(
                        method_name
                    )
            end)

            if method ~= nil then
                local identity =
                    method_identity(method)

                if seen[identity] ~= true then
                    seen[identity] = true
                    methods[#methods + 1] = method
                end
            end
        end
    end

    return methods
end

local function install_notify_dead_method(
    ctx,
    method
)
    local identity =
        method_identity(method)

    local ok, error_text =
        pcall(function()
            sdk.hook(
                method,
                function(args)
                    probe.raw_hook_calls =
                        probe.raw_hook_calls + 1

                    handle_notify_dead(
                        ctx,
                        args
                    )

                    return sdk.PreHookResult.CALL_ORIGINAL
                end,
                function(retval)
                    return retval
                end
            )
        end)

    if not ok then
        return false,
            tostring(error_text)
    end

    probe.resolved_methods[
        #probe.resolved_methods + 1
    ] = identity

    probe.installed_method_count =
        probe.installed_method_count + 1

    return true,
        nil
end

local function install_processed_dead_fallback(
    ctx,
    type_name
)
    local type_definition =
        sdk.find_type_definition(
            type_name
        )

    if type_definition == nil then
        return false,
            type_name .. " type not found"
    end

    local method =
        type_definition:get_method(
            "set_IsProcessedCharacterOnDead(System.Boolean)"
        )

    if method == nil then
        method =
            type_definition:get_method(
                "set_IsProcessedCharacterOnDead"
            )
    end

    if method == nil then
        return false,
            type_name .. " processed-dead setter not found"
    end

    local ok, error_text =
        pcall(function()
            sdk.hook(
                method,
                function(args)
                    handle_processed_character_on_dead(
                        ctx,
                        args
                    )

                    return sdk.PreHookResult.CALL_ORIGINAL
                end,
                function(retval)
                    return retval
                end
            )
        end)

    if not ok then
        return false,
            tostring(error_text)
    end

    probe.resolved_methods[
        #probe.resolved_methods + 1
    ] = method_identity(method)

    probe.installed_method_count =
        probe.installed_method_count + 1

    return true,
        nil
end

function probe.install(ctx)
    if probe.installed then
        return true
    end

    probe.install_attempted = true
    probe.install_error = ""
    probe.resolved_methods = {}
    probe.installed_method_count = 0

    local type_definition =
        sdk.find_type_definition(
            MANAGER_TYPE
        )

    if type_definition == nil then
        probe.install_error =
            "chainsaw.EnemyManager was not found."

        return false
    end

    local notify_methods =
        collect_notify_dead_methods(
            type_definition
        )

    local errors = {}

    for _, method in ipairs(notify_methods) do
        local installed,
              error_text =
            install_notify_dead_method(
                ctx,
                method
            )

        if not installed then
            errors[#errors + 1] =
                method_identity(method)
                .. ": "
                .. tostring(error_text)
        end
    end

    -- Install the processed-death fallback on both the shared character
    -- context and enemy base context when available. Some enemy subclasses
    -- dispatch through one type but not the other.
    local fallback_types = {
        CHARACTER_CONTEXT_TYPE,
        "chainsaw.EnemyBaseContext"
    }

    for _, fallback_type in ipairs(fallback_types) do
        local installed,
              error_text =
            install_processed_dead_fallback(
                ctx,
                fallback_type
            )

        if not installed then
            errors[#errors + 1] =
                tostring(error_text)
        end
    end

    if probe.installed_method_count == 0 then
        probe.install_error =
            #errors > 0
            and table.concat(errors, " | ")
            or "No enemy death methods were available."

        return false
    end

    probe.installed = true

    probe.resolved_method =
        probe.resolved_methods[1]
        or "none"

    probe.last_source_method =
        probe.resolved_method

    probe.last_event =
        "Installed "
        .. tostring(probe.installed_method_count)
        .. " enemy death hook(s)."

    if #errors > 0 then
        probe.install_error =
            table.concat(errors, " | ")
    end

    return true
end

return probe
