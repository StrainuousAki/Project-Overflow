------------------------------------------------------------
-- Maintenance classification — Build 49.39
-- Module: autorun/project_overflow/engine/reflection_snapshot.lua
-- Role: RE Engine reflection, capture, inspection, or runtime integration.
-- Status: active diagnostic/runtime support.
--
-- Compatibility policy:
--   Existing functions, hooks, module paths, and diagnostics are
--   intentionally retained in this maintenance pass.
--   `DEPRECATED` marks a supported legacy path, not removed code.
------------------------------------------------------------

------------------------------------------------------------
-- Project: Overflow — Bounded Reflection Snapshot
--
-- Captures metadata and simple field values from one known managed
-- object. It does not recursively walk references and never invokes
-- arbitrary methods. This keeps it much safer than a world-wide
-- Game Objects scan while still revealing designer parameter fields.
------------------------------------------------------------

local reflection = {
    max_fields = 128,
    max_methods = 160
}

local SIMPLE_TYPES = {
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
    ["System.Char"] = true,
    ["System.String"] = true,
    ["via.vec2"] = true,
    ["via.vec3"] = true,
    ["via.vec4"] = true,
    ["via.Quaternion"] = true,
    ["via.Range"] = true,
    ["via.NameHash"] = true
}

local function safe_type_name(type_definition)
    if type_definition == nil then
        return "unknown"
    end

    local ok, result =
        pcall(function()
            return type_definition:get_full_name()
        end)

    if ok and result ~= nil then
        return tostring(result)
    end

    return "unknown"
end

local function field_type_name(field)
    if field == nil then
        return "unknown"
    end

    local ok, result =
        pcall(function()
            return field:get_type()
        end)

    if ok and result ~= nil then
        return safe_type_name(result)
    end

    return "unknown"
end

local function field_name(field)
    if field == nil then
        return "unknown"
    end

    local ok, result =
        pcall(function()
            return field:get_name()
        end)

    if ok and result ~= nil then
        return tostring(result)
    end

    return "unknown"
end

local function method_name(method)
    if method == nil then
        return "unknown"
    end

    local ok, result =
        pcall(function()
            return method:get_name()
        end)

    if ok and result ~= nil then
        return tostring(result)
    end

    return "unknown"
end

local function value_text(value)
    if value == nil then
        return "nil"
    end

    local ok, result =
        pcall(function()
            return tostring(value)
        end)

    if ok then
        return result
    end

    return "<value error>"
end

local function is_enum_type(type_definition)
    if type_definition == nil then
        return false
    end

    local ok, result =
        pcall(function()
            return type_definition:is_a(
                sdk.typeof("System.Enum")
            )
        end)

    return ok and result == true
end

local function should_read_value(type_definition, type_name)
    if SIMPLE_TYPES[type_name] == true then
        return true
    end

    return is_enum_type(type_definition)
end

local function read_field_value(object, field, name, type_definition, type_name)
    if not should_read_value(type_definition, type_name) then
        return "<reference not traversed>"
    end

    local ok, result =
        pcall(function()
            return object:get_field(name)
        end)

    if not ok then
        return "<read error>"
    end

    if result == nil then
        return "nil"
    end

    if is_enum_type(type_definition) then
        local enum_ok, enum_text =
            pcall(function()
                return result:call("ToString")
            end)

        if enum_ok and enum_text ~= nil then
            return tostring(enum_text)
        end
    end

    return value_text(result)
end

function reflection.capture(ctx, object, label)
    local snapshot = {
        label = tostring(label or "Object"),
        object_ptr = "nil",
        type_name = "unknown",
        base_type_name = "unknown",
        fields = {},
        methods = {},
        field_count = 0,
        method_count = 0,
        truncated_fields = false,
        truncated_methods = false,
        error = ""
    }

    if object == nil then
        snapshot.error = "Object is nil."
        return snapshot
    end

    pcall(function()
        snapshot.object_ptr =
            tostring(ctx.ptr_string(object))
    end)

    local type_definition = nil

    local type_ok, type_result =
        pcall(function()
            return object:get_type_definition()
        end)

    if not type_ok or type_result == nil then
        snapshot.error =
            "Type definition could not be resolved."
        return snapshot
    end

    type_definition = type_result
    snapshot.type_name =
        safe_type_name(type_definition)

    pcall(function()
        snapshot.base_type_name =
            safe_type_name(
                type_definition:get_parent_type()
            )
    end)

    local fields = {}

    pcall(function()
        fields = type_definition:get_fields() or {}
    end)

    snapshot.field_count = #fields

    for index, field in ipairs(fields) do
        if index > reflection.max_fields then
            snapshot.truncated_fields = true
            break
        end

        local name = field_name(field)
        local field_type = nil

        pcall(function()
            field_type = field:get_type()
        end)

        local type_name =
            safe_type_name(field_type)

        snapshot.fields[#snapshot.fields + 1] = {
            name = name,
            type_name = type_name,
            value = read_field_value(
                object,
                field,
                name,
                field_type,
                type_name
            )
        }
    end

    local methods = {}

    pcall(function()
        methods = type_definition:get_methods() or {}
    end)

    snapshot.method_count = #methods

    for index, method in ipairs(methods) do
        if index > reflection.max_methods then
            snapshot.truncated_methods = true
            break
        end

        snapshot.methods[#snapshot.methods + 1] =
            method_name(method)
    end

    table.sort(
        snapshot.fields,
        function(left, right)
            return left.name < right.name
        end
    )

    table.sort(snapshot.methods)

    return snapshot
end

return reflection
