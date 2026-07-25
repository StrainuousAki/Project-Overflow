------------------------------------------------------------
-- Maintenance classification — Build 49.39
-- Module: autorun/project_overflow/shader_probe.lua
-- Role: HUD, XP, material, geometry, or rendering implementation.
-- Status: experimental diagnostic support.
--
-- Compatibility policy:
--   Existing functions, hooks, module paths, and diagnostics are
--   intentionally retained in this maintenance pass.
--   `DEPRECATED` marks a supported legacy path, not removed code.
------------------------------------------------------------

------------------------------------------------------------
-- Project: Overflow — shader_probe.lua
-- Project: Overflow runtime module.
------------------------------------------------------------

local shader_probe = {}

local MAX_MATERIAL_PARAMS = 8

local MATERIALS = {
    overlay = {
        field_name = "OverlayMat",
        label = "OverlayMat",
        state_key = "overlay_mat",
        type_key = "overlay_type",
        values_key = "overlay_float_values",
        originals_key = "overlay_float_originals",
        count_key = "overlay_param_count"
    },
    reflect = {
        -- Native field is misspelled in the game type.
        field_name = "RefrectMat",
        label = "RefrectMat",
        state_key = "reflect_mat",
        type_key = "reflect_type",
        values_key = "reflect_float_values",
        originals_key = "reflect_float_originals",
        count_key = "reflect_param_count"
    }
}

local function ensure_state(ctx)
    local state = ctx.shader_probe

    state.material_lines = state.material_lines or {}
    state.method_lines = state.method_lines or {}

    state.overlay_float_values = state.overlay_float_values or {}
    state.overlay_float_originals = state.overlay_float_originals or {}
    state.reflect_float_values = state.reflect_float_values or {}
    state.reflect_float_originals = state.reflect_float_originals or {}

    state.overlay_param_count = tonumber(state.overlay_param_count) or 0
    state.reflect_param_count = tonumber(state.reflect_param_count) or 0

    state.last_applied_material = state.last_applied_material or "none"
    state.last_applied_index = tonumber(state.last_applied_index) or -1
    state.last_applied_value = tonumber(state.last_applied_value) or 0.0
end

local function safe_call(obj, method_name, ...)
    if obj == nil then
        return nil, "Object is nil."
    end

    local args = {...}
    local ok, result = pcall(function()
        return obj:call(method_name, table.unpack(args))
    end)

    if ok then
        return result, ""
    end

    return nil, tostring(result)
end

local function safe_field(obj, field_name)
    if obj == nil then
        return nil, "Object is nil."
    end

    local ok, result = pcall(function()
        return obj:get_field(field_name)
    end)

    if ok then
        return result, ""
    end

    return nil, tostring(result)
end

local function append_line(lines, text)
    table.insert(lines, tostring(text))
end

local function get_material_descriptor(kind)
    return MATERIALS[kind]
end

local function get_material(ctx, kind)
    local descriptor = get_material_descriptor(kind)
    if descriptor == nil then
        return nil, nil
    end

    return ctx.shader_probe[descriptor.state_key], descriptor
end

local function capture_behavior(ctx, args)
    ensure_state(ctx)

    if ctx.shader_probe.behavior ~= nil then
        return
    end

    for index = 2, 5 do
        local obj = ctx.managed_from_arg(args, index)

        if obj ~= nil then
            local type_name = ctx.type_name_from_obj(obj)

            if type_name == "chainsaw.HudShaderGuiBehavior" then
                ctx.shader_probe.behavior = obj
                ctx.shader_probe.behavior_type = type_name
                ctx.shader_probe.behavior_ptr = ctx.ptr_from_obj(obj)
                ctx.shader_probe.capture_count =
                    (tonumber(ctx.shader_probe.capture_count) or 0) + 1
                return
            end
        end
    end
end

local function get_param_count(material)
    local count = safe_call(material, "get_MaterialParamsCount()")
    count = math.floor(tonumber(count) or 0)
    return math.max(0, math.min(count, MAX_MATERIAL_PARAMS))
end

local function get_float(material, index)
    return safe_call(
        material,
        "get_VariableFloat" .. tostring(index) .. "()"
    )
end

local function set_float(material, index, value)
    value = tonumber(value)
    if value == nil then
        return false, "Float value is nil or invalid."
    end

    local _, err = safe_call(
        material,
        "set_VariableFloat" .. tostring(index) .. "(System.Single)",
        value
    )

    return err == "", err
end

local function inspect_material(ctx, kind)
    ensure_state(ctx)

    local material, descriptor = get_material(ctx, kind)
    local lines = {}
    ctx.shader_probe.material_lines = lines

    if descriptor == nil then
        ctx.shader_probe.last_error = "Unknown material kind: " .. tostring(kind)
        return
    end

    if material == nil then
        ctx.shader_probe.last_error = descriptor.label .. " is nil."
        return
    end

    ctx.shader_probe.last_error = ""

    append_line(lines, descriptor.label .. " : " .. ctx.type_name_from_obj(material))

    local count = get_param_count(material)
    ctx.shader_probe[descriptor.count_key] = count
    append_line(lines, "Parameter Count: " .. tostring(count))

    for index = 0, count - 1 do
        local suffix = tostring(index)
        local name = safe_call(material, "get_VariableName" .. suffix .. "()")
        local variable_type = safe_call(material, "get_VariableType" .. suffix .. "()")
        local float_value = safe_call(material, "get_VariableFloat" .. suffix .. "()")
        local vec_value = safe_call(material, "get_VariableVec" .. suffix .. "()")
        local color_value = safe_call(material, "get_VariableColor" .. suffix .. "()")
        local mixed_color = safe_call(material, "get_VariableColorMixed" .. suffix .. "()")
        local texture_value = safe_call(material, "get_VariableTexture" .. suffix .. "()")

        append_line(
            lines,
            string.format(
                "[%d] Name=%s Type=%s",
                index,
                tostring(name),
                tostring(variable_type)
            )
        )
        append_line(lines, "    Float: " .. tostring(float_value))
        append_line(lines, "    Vec4: " .. tostring(vec_value))
        append_line(lines, "    Color: " .. tostring(color_value))
        append_line(lines, "    Mixed Color: " .. tostring(mixed_color))
        append_line(lines, "    Texture: " .. tostring(texture_value))
    end
end

local function inspect_methods(ctx, kind)
    ensure_state(ctx)

    local material, descriptor = get_material(ctx, kind)
    local lines = {}
    ctx.shader_probe.method_lines = lines

    if descriptor == nil then
        ctx.shader_probe.last_error = "Unknown material kind: " .. tostring(kind)
        return
    end

    if material == nil then
        ctx.shader_probe.last_error = descriptor.label .. " is nil."
        return
    end

    local ok, err = pcall(function()
        local td = material:get_type_definition()
        append_line(lines, descriptor.label .. " relevant methods:")

        for _, method in ipairs(td:get_methods()) do
            local name = method:get_name()
            local lower_name = name ~= nil and name:lower() or ""

            if lower_name:find("variable", 1, true)
                or lower_name:find("material", 1, true)
                or lower_name:find("param", 1, true)
                or lower_name:find("float", 1, true)
                or lower_name:find("color", 1, true)
                or lower_name:find("texture", 1, true)
            then
                append_line(lines, name)
            end
        end
    end)

    if ok then
        ctx.shader_probe.last_error = ""
    else
        ctx.shader_probe.last_error = tostring(err)
    end
end

local function read_values(ctx, kind)
    ensure_state(ctx)

    local material, descriptor = get_material(ctx, kind)
    if material == nil then
        ctx.shader_probe.last_error = descriptor.label .. " is nil."
        return
    end

    local count = get_param_count(material)
    local values = ctx.shader_probe[descriptor.values_key]
    local originals = ctx.shader_probe[descriptor.originals_key]

    ctx.shader_probe[descriptor.count_key] = count
    ctx.shader_probe.last_error = ""

    for index = 0, count - 1 do
        local value, err = get_float(material, index)

        if err ~= "" then
            ctx.shader_probe.last_error =
                descriptor.label .. " Float" .. tostring(index) .. ": " .. err
            return
        end

        value = tonumber(value) or 0.0
        values[index + 1] = value
        originals[index + 1] = value
    end
end

local function apply_value(ctx, kind, index)
    ensure_state(ctx)

    local material, descriptor = get_material(ctx, kind)
    if material == nil then
        ctx.shader_probe.last_error = descriptor.label .. " is nil."
        return
    end

    local values = ctx.shader_probe[descriptor.values_key]
    local value = values[index + 1]
    local success, err = set_float(material, index, value)

    if not success then
        ctx.shader_probe.last_error =
            descriptor.label .. " Float" .. tostring(index) .. ": " .. err
        return
    end

    ctx.shader_probe.last_error = ""
    ctx.shader_probe.last_applied_material = descriptor.label
    ctx.shader_probe.last_applied_index = index
    ctx.shader_probe.last_applied_value = tonumber(value) or 0.0
end

local function apply_all(ctx, kind)
    ensure_state(ctx)

    local material, descriptor = get_material(ctx, kind)
    if material == nil then
        ctx.shader_probe.last_error = descriptor.label .. " is nil."
        return
    end

    local count = tonumber(ctx.shader_probe[descriptor.count_key]) or 0
    local values = ctx.shader_probe[descriptor.values_key]

    for index = 0, count - 1 do
        local success, err = set_float(material, index, values[index + 1])

        if not success then
            ctx.shader_probe.last_error =
                descriptor.label .. " Float" .. tostring(index) .. ": " .. err
            return
        end
    end

    ctx.shader_probe.last_error = ""
    ctx.shader_probe.last_applied_material = descriptor.label
    ctx.shader_probe.last_applied_index = -1
    ctx.shader_probe.last_applied_value = 0.0
end

local function restore_values(ctx, kind)
    ensure_state(ctx)

    local _, descriptor = get_material(ctx, kind)
    local count = tonumber(ctx.shader_probe[descriptor.count_key]) or 0
    local values = ctx.shader_probe[descriptor.values_key]
    local originals = ctx.shader_probe[descriptor.originals_key]

    for index = 0, count - 1 do
        values[index + 1] = originals[index + 1]
    end

    apply_all(ctx, kind)
end

function shader_probe.install(ctx)
    ensure_state(ctx)

    if ctx.shader_probe.installed then
        return
    end

    local ok, err = pcall(function()
        local td = sdk.find_type_definition("chainsaw.HudShaderGuiBehavior")

        if td == nil then
            error("Could not find chainsaw.HudShaderGuiBehavior.")
        end

        local candidates = {
            "onUpdate()",
            "update()",
            "setup()",
            "awake()"
        }

        local installed_hooks = {}

        for _, method_name in ipairs(candidates) do
            local method = td:get_method(method_name)

            if method ~= nil then
                sdk.hook(
                    method,
                    function(args)
                        capture_behavior(ctx, args)
                    end,
                    function(retval)
                        return retval
                    end
                )

                table.insert(installed_hooks, method_name)
            end
        end

        if #installed_hooks == 0 then
            error("No usable HudShaderGuiBehavior lifecycle methods found.")
        end

        ctx.shader_probe.last_hook = table.concat(installed_hooks, ", ")
        ctx.shader_probe.installed = true
    end)

    if not ok then
        ctx.shader_probe.last_error = tostring(err)
    end
end

function shader_probe.refresh(ctx)
    ensure_state(ctx)

    local behavior = ctx.shader_probe.behavior
    if behavior == nil then
        ctx.shader_probe.last_error = "No live HudShaderGuiBehavior captured."
        return
    end

    ctx.shader_probe.last_error = ""

    local path = safe_call(behavior, "get_GuiBehaviorPath()")
    ctx.shader_probe.gui_path = path ~= nil and tostring(path) or "nil"

    local folder = safe_call(behavior, "findGuiSceneFolder()")
    ctx.shader_probe.folder = folder
    ctx.shader_probe.folder_type =
        folder ~= nil and ctx.type_name_from_obj(folder) or "nil"
    ctx.shader_probe.folder_ptr =
        folder ~= nil and ctx.ptr_from_obj(folder) or "nil"

    for _, descriptor in pairs(MATERIALS) do
        local material, field_error = safe_field(behavior, descriptor.field_name)
        ctx.shader_probe[descriptor.state_key] = material
        ctx.shader_probe[descriptor.type_key] =
            material ~= nil and ctx.type_name_from_obj(material) or "nil"

        if field_error ~= "" then
            ctx.shader_probe.last_error = field_error
        end
    end
end

function shader_probe.select_folder(ctx, gui)
    if gui == nil then
        ctx.shader_probe.last_error = "GUI inspector module was not passed."
        return
    end

    local folder = ctx.shader_probe.folder
    if folder == nil then
        ctx.shader_probe.last_error = "No GUI scene folder captured."
        return
    end

    ctx.shader_probe.last_error = ""
    gui.select(ctx, folder, "HUD GUI Scene Folder")
    gui.inspect_selected(ctx)
end

local function select_material(ctx, gui, kind)
    if gui == nil then
        ctx.shader_probe.last_error = "GUI inspector module was not passed."
        return
    end

    local material, descriptor = get_material(ctx, kind)
    if material == nil then
        ctx.shader_probe.last_error = descriptor.label .. " is currently nil."
        return
    end

    ctx.shader_probe.last_error = ""
    gui.select(ctx, material, "HUD " .. descriptor.label)
    gui.inspect_selected(ctx)
end

function shader_probe.select_overlay_material(ctx, gui)
    select_material(ctx, gui, "overlay")
end

function shader_probe.select_reflect_material(ctx, gui)
    select_material(ctx, gui, "reflect")
end

function shader_probe.inspect_overlay_material(ctx)
    inspect_material(ctx, "overlay")
end

function shader_probe.inspect_reflect_material(ctx)
    inspect_material(ctx, "reflect")
end

function shader_probe.inspect_overlay_methods(ctx)
    inspect_methods(ctx, "overlay")
end

function shader_probe.inspect_reflect_methods(ctx)
    inspect_methods(ctx, "reflect")
end

function shader_probe.read_overlay_values(ctx)
    read_values(ctx, "overlay")
end

function shader_probe.read_reflect_values(ctx)
    read_values(ctx, "reflect")
end

function shader_probe.apply_overlay_float(ctx, index)
    apply_value(ctx, "overlay", index)
end

function shader_probe.apply_reflect_float(ctx, index)
    apply_value(ctx, "reflect", index)
end

function shader_probe.apply_all_overlay_floats(ctx)
    apply_all(ctx, "overlay")
end

function shader_probe.apply_all_reflect_floats(ctx)
    apply_all(ctx, "reflect")
end

function shader_probe.restore_overlay_floats(ctx)
    restore_values(ctx, "overlay")
end

function shader_probe.restore_reflect_floats(ctx)
    restore_values(ctx, "reflect")
end

return shader_probe