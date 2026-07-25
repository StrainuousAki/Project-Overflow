------------------------------------------------------------
-- Maintenance classification — Build 49.39
-- Module: autorun/project_overflow/gui_inspector.lua
-- Role: HUD, XP, material, geometry, or rendering implementation.
-- Status: experimental diagnostic support.
--
-- Compatibility policy:
--   Existing functions, hooks, module paths, and diagnostics are
--   intentionally retained in this maintenance pass.
--   `DEPRECATED` marks a supported legacy path, not removed code.
------------------------------------------------------------

------------------------------------------------------------
-- Project: Overflow — gui_inspector.lua
-- Project: Overflow runtime module.
------------------------------------------------------------

local gui = {}

local relation_methods = {
    "get_Parent()",
    "get_Child()",
    "get_Children()",
    "get_Next()",
    "get_Prev()",
    "get_Component()",
    "get_ObjectData()",
    "get_Param()"
}

local function get_method(obj, method_name)
    if obj == nil then return nil end

    local ok, method = pcall(function()
        return obj:get_type_definition():get_method(method_name)
    end)

    if ok then return method end
    return nil
end

local function call(obj, method_name)
    local method = get_method(obj, method_name)
    if method == nil then return nil end

    local ok, result = pcall(function()
        return method:call(obj)
    end)

    if ok then return result end
    return nil
end

local function line(ctx, depth, obj, label)
    local indent = string.rep("  ", depth)
    table.insert(ctx.gui_inspector.lines, indent .. label .. " : " .. ctx.type_name_from_obj(obj))
end

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

function gui.select(ctx, obj, label)
    if obj == nil then
        ctx.gui_inspector.last_error = "Cannot select nil: " .. tostring(label)
        return
    end

    ctx.gui_inspector.selected = obj
    ctx.gui_inspector.selected_label = label
    ctx.gui_inspector.selected_type = ctx.type_name_from_obj(obj)
    ctx.gui_inspector.last_error = ""
end

function gui.select_related(ctx, method_name, label)
    local selected = ctx.gui_inspector.selected
    if selected == nil then
        ctx.gui_inspector.last_error = "No selected object."
        return
    end

    local result = call(selected, method_name)
    if result == nil then
        ctx.gui_inspector.last_error = "No result from " .. method_name
        return
    end

    gui.select(ctx, result, label)
end

local function find_method_fuzzy(obj, contains)
    local td = obj:get_type_definition()
    contains = contains:lower()

    for _, m in ipairs(td:get_methods()) do
        local name = m:get_name()
        if name ~= nil and name:lower():find(contains, 1, true) then
            return m
        end
    end

    return nil
end

function gui.duplicate_selected(ctx)
    local selected = ctx.gui_inspector.selected

    if selected == nil then
        ctx.gui_duplicate.last_error = "No selected object."
        ctx.gui_duplicate.result = "failed"
        return
    end

    ctx.gui_duplicate.source_type = ctx.type_name_from_obj(selected)
    ctx.gui_duplicate.clone = nil
    ctx.gui_duplicate.clone_label = "none"
    ctx.gui_duplicate.clone_type = "unknown"
    ctx.gui_duplicate.clone_ptr = "nil"
    ctx.gui_duplicate.last_error = ""

    local ok, err = pcall(function()
        local td = selected:get_type_definition()

        local duplicate_method =
            td:get_method("duplicate(System.String name)") or
            td:get_method("duplicate(System.String)") or
            td:get_method("duplicate") or
            find_method_fuzzy(selected, "duplicate")

        if duplicate_method == nil then
            error("Selected type has no duplicate method: " .. ctx.type_name_from_obj(selected))
        end

        local result = duplicate_method:call(selected, "BonusHealth_Test")

        if result == nil then
            ctx.gui_duplicate.result = "duplicate returned nil"
            ctx.gui_duplicate.clone_type = "nil"
            ctx.gui_duplicate.clone_ptr = "nil"
            return
        end

        ctx.gui_duplicate.clone_ptr = tostring(result)

        local managed_ok, managed_err = pcall(function()
            ctx.gui_duplicate.clone = result
            ctx.gui_duplicate.clone_label = "BonusHealth_Test"
            ctx.gui_duplicate.clone_type = ctx.type_name_from_obj(result)
            ctx.gui_duplicate.clone_ptr = ctx.ptr_from_obj(result)

            gui.select(ctx, result, "Duplicate Clone")
            gui.inspect_selected(ctx)
        end)

        if managed_ok then
            ctx.gui_duplicate.result = "managed clone returned"
        else
            ctx.gui_duplicate.clone = nil
            ctx.gui_duplicate.clone_label = "native/non-managed"
            ctx.gui_duplicate.clone_type = "not managed"
            ctx.gui_duplicate.result = "native/non-managed return"
            ctx.gui_duplicate.last_error = tostring(managed_err)
        end
    end)

    if not ok then
        ctx.gui_duplicate.last_error = tostring(err)
        ctx.gui_duplicate.result = "failed"
    end
end

function gui.select_duplicate(ctx)
    if ctx.gui_duplicate.clone == nil then
        ctx.gui_duplicate.last_error = "No duplicate clone captured."
        return
    end

    gui.select(ctx, ctx.gui_duplicate.clone, "Duplicate Clone")
    gui.inspect_selected(ctx)
end

function gui.inspect_selected(ctx)
    ctx.gui_inspector.lines = {}

    local obj = ctx.gui_inspector.selected
    if obj == nil then
        ctx.gui_inspector.last_error = "No selected object."
        return
    end

    line(ctx, 0, obj, ctx.gui_inspector.selected_label)

    for _, method_name in ipairs(relation_methods) do
        local result = call(obj, method_name)
        if result ~= nil then
            line(ctx, 1, result, method_name)
        end
    end
end

function gui.select_first_child_array(ctx)
    local selected = ctx.gui_inspector.selected
    if selected == nil then
        ctx.gui_inspector.last_error = "No selected object."
        return
    end

    local children = call(selected, "getChildren()")
    if children == nil then
        ctx.gui_inspector.last_error = "getChildren() returned nil."
        return
    end

    local ok, first = pcall(function()
        return children[0] or children[1]
    end)

    if ok and first ~= nil then
        gui.select(ctx, first, "Child[0]")
    else
        ctx.gui_inspector.last_error = "Could not index getChildren(). Type: " .. ctx.type_name_from_obj(children)
    end
end

local function walk(ctx, obj, depth, label)
    if obj == nil then return end
    if depth > ctx.gui_inspector.max_depth then return end

    line(ctx, depth, obj, label)

    for _, method_name in ipairs(relation_methods) do
        local result = call(obj, method_name)
        if result ~= nil then
            line(ctx, depth + 1, result, method_name)
        end
    end

    local next_obj = call(obj, "get_Next()")
    if next_obj ~= nil then
        walk(ctx, next_obj, depth, "Next")
    end
end

function gui.explore_tree(ctx)
    ctx.gui_inspector.lines = {}
    ctx.gui_inspector.last_error = ""

    local root = ctx.circle_probe.circle
    if root == nil then
        ctx.gui_inspector.last_error = "No captured circle. Click Capture Circle first."
        return
    end

    local ok, err = pcall(function()
        ctx.gui_inspector.root_type = ctx.type_name_from_obj(root)
        walk(ctx, root, 0, "Circle Root")
    end)

    if not ok then
        ctx.gui_inspector.last_error = tostring(err)
    end
end

function gui.inspect_fields(ctx)
    ctx.gui_inspector.field_lines = {}

    local obj = ctx.gui_inspector.selected
    if obj == nil then
        ctx.gui_inspector.last_error = "No selected object."
        return
    end

    local ok, err = pcall(function()
        local td = obj:get_type_definition()

        if td == nil then
            error("Selected object has no type definition.")
        end

        local fields = td:get_fields()

        if fields == nil then
            error("Selected type returned no fields.")
        end

        for _, field in ipairs(fields) do
            local field_name = field:get_name()
            local field_type = "unknown"

            local type_ok, field_td = pcall(function()
                return field:get_type()
            end)

            if type_ok and field_td ~= nil then
                local name_ok, type_name = pcall(function()
                    return field_td:get_full_name()
                end)

                if name_ok and type_name ~= nil then
                    field_type = type_name
                end
            end

            local read_ok, value = pcall(function()
                return field:get_data(obj)
            end)

            local line_text =
                tostring(field_name) ..
                " [" ..
                tostring(field_type) ..
                "] = "

            if read_ok then
                line_text = line_text .. safe_tostring(value)
            else
                line_text = line_text .. "<read failed>"
            end

            table.insert(ctx.gui_inspector.field_lines, line_text)
        end

        ctx.gui_inspector.last_error = ""
    end)

    if not ok then
        ctx.gui_inspector.last_error = tostring(err)
    end
end

return gui