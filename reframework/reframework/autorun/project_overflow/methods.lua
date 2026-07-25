------------------------------------------------------------
-- Maintenance classification — Build 49.39
-- Module: autorun/project_overflow/methods.lua
-- Role: Project: Overflow runtime support module.
-- Status: active support.
--
-- Compatibility policy:
--   Existing functions, hooks, module paths, and diagnostics are
--   intentionally retained in this maintenance pass.
--   `DEPRECATED` marks a supported legacy path, not removed code.
------------------------------------------------------------

------------------------------------------------------------
-- Project: Overflow — methods.lua
-- Project: Overflow runtime module.
------------------------------------------------------------

local methods = {}

local function selected(ctx)
    local obj = ctx.gui_inspector.selected
    if obj == nil then
        ctx.gui_inspector.invoke_result = "failed"
        ctx.gui_inspector.invoke_error = "No selected object."
        return nil
    end
    return obj
end

local function find_method(obj, search_name)
    local td = obj:get_type_definition()
    if td == nil then return nil end

    search_name = search_name:lower()

    for _, method in ipairs(td:get_methods()) do
        local name = method:get_name()
        if name ~= nil then
            local lower = name:lower()
            if lower == search_name or lower:find(search_name, 1, true) then
                return method
            end
        end
    end

    return nil
end

local function call_selected(ctx, method_name, ...)
    local obj = selected(ctx)
    if obj == nil then return end

    local ok, err = pcall(function(...)
        local method = find_method(obj, method_name)
        if method == nil then
            error("Missing method: " .. method_name)
        end

        method:call(obj, ...)
    end, ...)

    ctx.gui_inspector.invoke_result = ok and ("called " .. method_name) or "failed"
    ctx.gui_inspector.invoke_error = ok and "" or tostring(err)
end

function methods.call_selected_void(ctx, method_name)
    call_selected(ctx, method_name)
end

function methods.call_selected_float(ctx, method_name, value)
    call_selected(ctx, method_name, value)
end

function methods.call_selected_u32(ctx, method_name, value)
    call_selected(ctx, method_name, value)
end

return methods