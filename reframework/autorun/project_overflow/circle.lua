------------------------------------------------------------
-- Maintenance classification — Build 49.39
-- Module: autorun/project_overflow/circle.lua
-- Role: HUD, XP, material, geometry, or rendering implementation.
-- Status: experimental diagnostic support.
--
-- Compatibility policy:
--   Existing functions, hooks, module paths, and diagnostics are
--   intentionally retained in this maintenance pass.
--   `DEPRECATED` marks a supported legacy path, not removed code.
------------------------------------------------------------

------------------------------------------------------------
-- Project: Overflow — circle.lua
-- Project: Overflow runtime module.
------------------------------------------------------------

local circle = {}

local function circle_get(circle_obj, getter_name)
    local ok, value = pcall(function()
        local method = circle_obj:get_type_definition():get_method(getter_name)
        if method == nil then return "no getter" end
        return method:call(circle_obj)
    end)

    if ok then return tostring(value) end
    return "err"
end

local function circle_ptr(circle_obj)
    local ok, value = pcall(function()
        return string.format("0x%X", sdk.to_ptr(circle_obj))
    end)

    if ok then return value end
    return "managed"
end

function circle.capture(ctx)
    if ctx.amount_status_gui == nil then
        ctx.set_error("No AmountStatusGui captured.")
        return
    end

    local ok, err = pcall(function()
        local obj = ctx.amount_status_gui:get_field("_Circle")
        if obj == nil then
            ctx.set_error("AmountStatusGui._Circle is nil")
            return
        end

        ctx.circle_probe.circle = obj
        ctx.circle_probe.type = ctx.type_name_from_obj(obj)

        ctx.circle_probe.visible = circle_get(obj, "get_Visible()")
        ctx.circle_probe.play_frame = circle_get(obj, "get_PlayFrame()")
        ctx.circle_probe.color_scale = circle_get(obj, "get_ColorScale()")
    end)

    if not ok then ctx.set_error(err) end
end

local function call_circle_method(ctx, method_name, arg1)
    if ctx.circle_probe.circle == nil then
        ctx.circle_test.last_error = "No circle captured."
        return false
    end

    local ok, err = pcall(function()
        local method = ctx.circle_probe.circle:get_type_definition():get_method(method_name)
        if method == nil then error("Missing method: " .. method_name) end

        if arg1 ~= nil then
            method:call(ctx.circle_probe.circle, arg1)
        else
            method:call(ctx.circle_probe.circle)
        end
    end)

    ctx.circle_test.last_error = ok and "" or tostring(err)
    return ok
end

function circle.set_arc_half(ctx)
    call_circle_method(ctx, "set_ArcAngle(via.Float2)", Vector2f.new(0.0, 67.5))
end

function circle.set_arc_full(ctx)
    call_circle_method(ctx, "set_ArcAngle(via.Float2)", Vector2f.new(0.0, 135.0))
end

function circle.set_arc_overflow(ctx)
    ctx.update_overflow_math()
    call_circle_method(ctx, "set_ArcAngle(via.Float2)", Vector2f.new(0.0, ctx.state.overflow_angle))
end

function circle.set_arc_custom(ctx)
    call_circle_method(ctx, "set_ArcAngle(via.Float2)", Vector2f.new(0.0, ctx.circle_test.arc_y))
end

function circle.sample(ctx, circle_obj)
    local ptr = circle_ptr(circle_obj)
    if ctx.circle_explorer.samples[ptr] ~= nil then return end

    local count = 0
    for _ in pairs(ctx.circle_explorer.samples) do count = count + 1 end
    if count >= ctx.circle_explorer.max_samples then return end

    ctx.circle_explorer.samples[ptr] = {
        ptr = ptr,
        type = ctx.type_name_from_obj(circle_obj),
        arc_angle = circle_get(circle_obj, "get_ArcAngle()"),
        arc_start = circle_get(circle_obj, "get_ArcStart()"),
        inner_ratio = circle_get(circle_obj, "get_InnerRatio()"),
        size = circle_get(circle_obj, "get_Size()"),
        position = circle_get(circle_obj, "get_Position()"),
        global_position = circle_get(circle_obj, "get_GlobalPosition()"),
        visible = circle_get(circle_obj, "get_Visible()"),
        color = circle_get(circle_obj, "get_Color()"),
        outer_color = circle_get(circle_obj, "get_OuterColor()"),
        inner_color = circle_get(circle_obj, "get_InnerColor()")
    }
end

local function install_draw_explorer(ctx)
    if ctx.circle_explorer.installed then return end

    local candidates = {
        {"via.gui.Circle", "draw"},
        {"via.gui.Circle", "draw()"},
        {"via.gui.DrawableElement", "draw"},
        {"via.gui.DrawableElement", "draw()"},
        {"via.gui.Element", "draw"},
        {"via.gui.Element", "draw()"}
    }

    for _, c in ipairs(candidates) do
        local td = sdk.find_type_definition(c[1])
        if td ~= nil then
            local method = td:get_method(c[2])
            if method ~= nil then
                sdk.hook(method, function(args)
                    ctx.circle_explorer.calls = ctx.circle_explorer.calls + 1

                    local obj = ctx.managed_from_arg(args, 2)
                    if obj ~= nil and ctx.type_name_from_obj(obj) == "via.gui.Circle" then
                        circle.sample(ctx, obj)
                    end
                end, function(retval) return retval end)

                ctx.circle_explorer.installed = true
                ctx.circle_explorer.last_hook = c[1] .. "." .. c[2]
                return
            end
        end
    end

    ctx.circle_explorer.last_hook = "not hookable"
end

local function hook_circle_setter(ctx, method_name, value_reader)
    local td = sdk.find_type_definition("via.gui.Circle")
    if td == nil then return false end

    local method = td:get_method(method_name)
    if method == nil then return false end

    sdk.hook(method, function(args)
        ctx.circle_setter.calls = ctx.circle_setter.calls + 1
        ctx.circle_setter.last_method = method_name

        local raw_args = {}
        for i = 1, 8 do
            if args[i] == nil then
                table.insert(raw_args, tostring(i) .. "=nil")
            else
                table.insert(raw_args, tostring(i) .. "=" .. tostring(args[i]))
            end
        end

        ctx.circle_setter.last_type = table.concat(raw_args, " | ")

        if value_reader ~= nil then
            ctx.circle_setter.last_value = value_reader(args)
        end
    end, function(retval) return retval end)

    return true
end

local function install_setter_explorer(ctx)
    if ctx.circle_setter.installed then return end

    local hooked = 0

    if hook_circle_setter(ctx, "set_ArcStart(System.Single)", function(args)
        return tostring(sdk.to_float(args[3]))
    end) then hooked = hooked + 1 end

    if hook_circle_setter(ctx, "set_ArcAngle(via.Float2)", function(args)
        return "via.Float2"
    end) then hooked = hooked + 1 end

    if hook_circle_setter(ctx, "set_Color(via.Color)", function(args)
        return "via.Color"
    end) then hooked = hooked + 1 end

    if hook_circle_setter(ctx, "set_OuterColor(via.Color)", function(args)
        return "via.Color"
    end) then hooked = hooked + 1 end

    if hook_circle_setter(ctx, "set_InnerColor(via.Color)", function(args)
        return "via.Color"
    end) then hooked = hooked + 1 end

    ctx.circle_setter.installed = true
    ctx.circle_setter.last_value = "hooked: " .. tostring(hooked)
end

function circle.install(ctx)
    install_draw_explorer(ctx)
    install_setter_explorer(ctx)
end

return circle