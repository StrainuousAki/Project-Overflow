------------------------------------------------------------
-- Maintenance classification — Build 49.39
-- Module: autorun/project_overflow/engine/live_enemy_inspector.lua
-- Role: RE Engine reflection, capture, inspection, or runtime integration.
-- Status: active diagnostic/runtime support.
--
-- Compatibility policy:
--   Existing functions, hooks, module paths, and diagnostics are
--   intentionally retained in this maintenance pass.
--   `DEPRECATED` marks a supported legacy path, not removed code.
------------------------------------------------------------

------------------------------------------------------------
-- Project: Overflow — Manual Live Enemy Inspector
--
-- This tool never runs reflection continuously. The user arms one
-- capture, the next live enemy context update is inspected synchronously,
-- and no managed object is retained after the snapshot is built.
------------------------------------------------------------

local inspector = {
    installed = false,
    install_attempted = false,
    install_error = "",
    resolved_method = "none",

    armed = false,
    capture_count = 0,
    skipped_contexts = 0,
    last_error = "",
    last_snapshot = nil,

    max_fields_per_object = 96,
    max_methods_per_object = 160
}

local CONTEXT_TYPE = "chainsaw.CharacterContext"

local METHOD_CANDIDATES = {
    "updateContextDataOnUpdatePhase()",
    "updateContextDataOnUpdatePhase"
}

local function safe_tostring(value)
    if value == nil then
        return "nil"
    end

    local ok, result = pcall(function()
        return tostring(value)
    end)

    if ok then
        return result
    end

    return "<unreadable>"
end

local function safe_call(object, method_name, ...)
    if object == nil then
        return nil
    end

    local args = { ... }

    local ok, result = pcall(function()
        return object:call(method_name, table.unpack(args))
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

    local ok, result = pcall(function()
        return object:get_field(field_name)
    end)

    if ok then
        return result
    end

    return nil
end

local function type_name(ctx, object)
    if object == nil then
        return "nil"
    end

    local ok, result = pcall(function()
        return ctx.type_name_from_obj(object)
    end)

    if ok and result ~= nil then
        return tostring(result)
    end

    return "unknown"
end

local function pointer_text(ctx, object)
    if object == nil then
        return "nil"
    end

    local ok, result = pcall(function()
        return ctx.ptr_string(object)
    end)

    if ok and result ~= nil then
        return tostring(result)
    end

    return safe_tostring(object)
end

local function get_character_parameter(context)
    return
        safe_call(context, "get_CharacterParameter") or
        safe_call(context, "get_CharacterParam") or
        safe_field(context, "<CharacterParameter>k__BackingField") or
        safe_field(context, "_CharacterParameter")
end

local function get_spawn_parameter(context)
    return
        safe_call(context, "get_CharacterSpawnParam") or
        safe_field(context, "<CharacterSpawnParam>k__BackingField") or
        safe_field(context, "_CharacterSpawnParam")
end

local function is_enemy_context(ctx, object)
    if object == nil then
        return false
    end

    local name = type_name(ctx, object)

    if name == "unknown" or name == "nil" then
        return false
    end

    if string.find(name, "Player", 1, true) ~= nil then
        return false
    end

    if string.find(name, "Context", 1, true) == nil then
        return false
    end

    return
        safe_call(object, "get_KindID") ~= nil or
        safe_call(object, "get_HitPoint") ~= nil or
        safe_call(object, "get_CharacterParameter") ~= nil
end

local function field_type_name(field)
    local ok, field_type = pcall(function()
        return field:get_type()
    end)

    if not ok or field_type == nil then
        return "unknown"
    end

    local name_ok, name = pcall(function()
        return field_type:get_full_name()
    end)

    if name_ok and name ~= nil then
        return tostring(name)
    end

    return "unknown"
end

local function declared_fields(ctx, object)
    local rows = {}

    if object == nil then
        return rows, "object was nil"
    end

    local ok, err = pcall(function()
        local td = object:get_type_definition()
        if td == nil then
            error("object has no type definition")
        end

        local fields = td:get_fields() or {}

        for index, field in ipairs(fields) do
            if index > inspector.max_fields_per_object then
                break
            end

            local field_name = "unknown"
            pcall(function()
                field_name = tostring(field:get_name())
            end)

            local read_ok, value = pcall(function()
                return field:get_data(object)
            end)

            rows[#rows + 1] = {
                index = index - 1,
                name = field_name,
                declared_type = field_type_name(field),
                value = read_ok and safe_tostring(value) or "<read failed>",
                runtime_type =
                    read_ok and type_name(ctx, value) or "unknown",
                ptr =
                    read_ok and pointer_text(ctx, value) or "nil"
            }
        end
    end)

    return rows, ok and "" or tostring(err)
end

local function method_names(object)
    local names = {}

    if object == nil then
        return names, "object was nil"
    end

    local ok, err = pcall(function()
        local td = object:get_type_definition()
        if td == nil then
            error("object has no type definition")
        end

        local methods = td:get_methods() or {}

        for index, method in ipairs(methods) do
            if index > inspector.max_methods_per_object then
                break
            end

            local name = "unknown"
            pcall(function()
                name = tostring(method:get_name())
            end)

            names[#names + 1] = name
        end

        table.sort(names)
    end)

    return names, ok and "" or tostring(err)
end

local function object_snapshot(ctx, label, object)
    local fields, field_error = declared_fields(ctx, object)
    local methods, method_error = method_names(object)

    return {
        label = label,
        type_name = type_name(ctx, object),
        object_ptr = pointer_text(ctx, object),
        fields = fields,
        methods = methods,
        field_error = field_error,
        method_error = method_error
    }
end

local function world_position(context)
    local position = safe_call(context, "get_Position")

    if position == nil then
        local body = safe_call(context, "get_BodyGameObject")
        local transform = safe_call(body, "get_Transform")
        position = safe_call(transform, "get_Position")
    end

    if position == nil then
        return "unknown"
    end

    local x = safe_field(position, "x")
    local y = safe_field(position, "y")
    local z = safe_field(position, "z")

    if x == nil or y == nil or z == nil then
        return safe_tostring(position)
    end

    return string.format(
        "%.4f, %.4f, %.4f",
        tonumber(x) or 0,
        tonumber(y) or 0,
        tonumber(z) or 0
    )
end

local function capture(ctx, context)
    local parameter = get_character_parameter(context)
    local spawn_parameter = get_spawn_parameter(context)

    local snapshot = {
        captured_at = os.clock(),
        context_type = type_name(ctx, context),
        context_ptr = pointer_text(ctx, context),
        kind_id = safe_tostring(safe_call(context, "get_KindID")),
        world_position = world_position(context),

        parameter_type = type_name(ctx, parameter),
        parameter_ptr = pointer_text(ctx, parameter),

        spawn_parameter_type = type_name(ctx, spawn_parameter),
        spawn_parameter_ptr = pointer_text(ctx, spawn_parameter),

        context = object_snapshot(ctx, "Enemy Context", context),
        parameter = object_snapshot(ctx, "Character Parameter", parameter),
        spawn_parameter =
            object_snapshot(ctx, "Character Spawn Parameter", spawn_parameter)
    }

    inspector.last_snapshot = snapshot
    inspector.capture_count = inspector.capture_count + 1
    inspector.last_error = ""
    inspector.armed = false
end

local function resolve_method(td)
    for _, method_name in ipairs(METHOD_CANDIDATES) do
        local method = nil

        pcall(function()
            method = td:get_method(method_name)
        end)

        if method ~= nil then
            return method, method_name
        end
    end

    return nil, "none"
end

function inspector.install(ctx, force)
    if inspector.installed and force ~= true then
        return true
    end

    inspector.install_attempted = true
    inspector.install_error = ""

    local ok, err = pcall(function()
        local td = sdk.find_type_definition(CONTEXT_TYPE)
        if td == nil then
            error("Could not find " .. CONTEXT_TYPE)
        end

        local method, method_name = resolve_method(td)
        if method == nil then
            error("Could not resolve updateContextDataOnUpdatePhase")
        end

        sdk.hook(
            method,
            function(args)
                if inspector.armed ~= true then
                    return
                end

                local context = ctx.managed_from_arg(args, 2)

                if not is_enemy_context(ctx, context) then
                    inspector.skipped_contexts =
                        inspector.skipped_contexts + 1
                    return
                end

                local capture_ok, capture_error = pcall(function()
                    capture(ctx, context)
                end)

                if not capture_ok then
                    inspector.last_error = tostring(capture_error)
                    inspector.armed = false
                end
            end,
            function(retval)
                return retval
            end
        )

        inspector.installed = true
        inspector.resolved_method =
            CONTEXT_TYPE .. "." .. method_name
    end)

    if not ok then
        inspector.installed = false
        inspector.install_error = tostring(err)
        return false
    end

    return true
end

function inspector.arm(ctx)
    if not inspector.installed then
        if not inspector.install(ctx) then
            return false
        end
    end

    inspector.last_error = ""
    inspector.armed = true
    return true
end

function inspector.cancel()
    inspector.armed = false
end

function inspector.clear()
    inspector.armed = false
    inspector.last_snapshot = nil
    inspector.last_error = ""
end

return inspector
