------------------------------------------------------------
-- Maintenance classification — Build 49.39
-- Module: autorun/project_overflow/hud.lua
-- Role: HUD, XP, material, geometry, or rendering implementation.
-- Status: active renderer.
--
-- Compatibility policy:
--   Existing functions, hooks, module paths, and diagnostics are
--   intentionally retained in this maintenance pass.
--   `DEPRECATED` marks a supported legacy path, not removed code.
------------------------------------------------------------

------------------------------------------------------------
-- Project: Overflow — hud.lua
-- Project: Overflow runtime module.
------------------------------------------------------------

local hud = {}

local function read_gui_property(obj, getter_name)
    if obj == nil then return "nil" end

    local ok, result = pcall(function()
        local td = obj:get_type_definition()
        local method = td:get_method(getter_name)

        if method == nil then
            return "no getter"
        end

        return method:call(obj)
    end)

    if ok then return tostring(result) end
    return "call failed"
end

function hud.refresh(ctx)
    if ctx.amount_status_gui == nil then return end

    local h = ctx.hud_native
    local obj = ctx.amount_status_gui

    h.type = ctx.type_name_from_obj(obj)
    h.curr_state = read_gui_property(obj, "get_CurrState()")
    h.frame_to_angle_rate = read_gui_property(obj, "get_FrameToAngleRate()")
    h.curr_max_frame = read_gui_property(obj, "get_CurrMaxFrame()")
    h.curr_max_angle = read_gui_property(obj, "get_CurrMaxAngle()")
    h.curr_rate = read_gui_property(obj, "get_CurrRate()")
    h.curr_angle = read_gui_property(obj, "get_CurrAngle()")
    h.curr_target_rate = read_gui_property(obj, "get_CurrTargetRate()")
    h.curr_target_angle = read_gui_property(obj, "get_CurrTargetAngle()")
    h.curr_rate_diff = read_gui_property(obj, "get_CurrRateDiff()")
    h.curr_virtual_min_frame = read_gui_property(obj, "get_CurrVirtualMinFrame()")
    h.curr_virtual_min_angle = read_gui_property(obj, "get_CurrVirtualMinAngle()")
    h.curr_virtual_max_frame = read_gui_property(obj, "get_CurrVirtualMaxFrame()")
    h.curr_virtual_max_angle = read_gui_property(obj, "get_CurrVirtualMaxAngle()")
end

local function call_amount_status(ctx, method_name, value)
    if ctx.amount_status_gui == nil then
        ctx.set_error("No AmountStatusGui captured.")
        return false
    end

    local ok, err = pcall(function()
        local td = ctx.amount_status_gui:get_type_definition()
        local method = td:get_method(method_name)

        if method == nil then
            error("Missing method: " .. method_name)
        end

        method:call(ctx.amount_status_gui, value)
    end)

    if not ok then
        ctx.set_error(err)
        return false
    end

    return true
end

function hud.clear_virtual(ctx)
    call_amount_status(ctx, "set_CurrVirtualMinFrame(System.Single)", 50.0)
    call_amount_status(ctx, "set_CurrVirtualMaxFrame(System.Single)", 50.0)
    hud.refresh(ctx)
end

function hud.normalize(ctx)
    call_amount_status(ctx, "set_CurrRate(System.Single)", 50.0)
    call_amount_status(ctx, "set_CurrTargetRate(System.Single)", 50.0)
    call_amount_status(ctx, "set_CurrVirtualMinFrame(System.Single)", 50.0)
    call_amount_status(ctx, "set_CurrVirtualMaxFrame(System.Single)", 50.0)
    hud.refresh(ctx)
end

local function record_amount_setter(ctx, method_name, value)
    ctx.amount_setter.calls = ctx.amount_setter.calls + 1
    ctx.amount_setter.last_method = method_name
    ctx.amount_setter.last_value = tostring(value)

    if method_name == "set_CurrRate(System.Single)" then
        ctx.amount_setter.curr_rate_calls = ctx.amount_setter.curr_rate_calls + 1
        ctx.amount_setter.curr_rate_value = tostring(value)
    elseif method_name == "set_CurrTargetRate(System.Single)" then
        ctx.amount_setter.curr_target_calls = ctx.amount_setter.curr_target_calls + 1
        ctx.amount_setter.curr_target_value = tostring(value)
    elseif method_name == "set_CurrRateDiff(System.Single)" then
        ctx.amount_setter.curr_diff_calls = ctx.amount_setter.curr_diff_calls + 1
        ctx.amount_setter.curr_diff_value = tostring(value)
    elseif method_name == "set_CurrMaxFrame(System.Single)" then
        ctx.amount_setter.curr_max_calls = ctx.amount_setter.curr_max_calls + 1
        ctx.amount_setter.curr_max_value = tostring(value)
    elseif method_name == "set_CurrVirtualMinFrame(System.Single)" then
        ctx.amount_setter.virt_min_calls = ctx.amount_setter.virt_min_calls + 1
        ctx.amount_setter.virt_min_value = tostring(value)
    elseif method_name == "set_CurrVirtualMaxFrame(System.Single)" then
        ctx.amount_setter.virt_max_calls = ctx.amount_setter.virt_max_calls + 1
        ctx.amount_setter.virt_max_value = tostring(value)
    end
end

local function hook_amount_setter(ctx, method_name)
    local td = sdk.find_type_definition("chainsaw.VitalAmountGui.AmountStatusGui")
    if td == nil then return false end

    local method = td:get_method(method_name)
    if method == nil then return false end

    sdk.hook(method,
        function(args)
            local ok, value = pcall(function()
                return sdk.to_float(args[3])
            end)

            if ok then
                record_amount_setter(ctx, method_name, value)
            else
                record_amount_setter(ctx, method_name, "unreadable")
            end

            if ctx.amount_setter.force_enabled then
                if method_name == "set_CurrVirtualMinFrame(System.Single)" then
                    ctx.amount_setter.last_value = "would force virt min to " .. tostring(ctx.amount_setter.force_rate)
                elseif method_name == "set_CurrVirtualMaxFrame(System.Single)" then
                    ctx.amount_setter.last_value = "would force virt max to " .. tostring(ctx.amount_setter.force_rate)
                end
            end
        end,
        function(retval)
            return retval
        end
    )

    return true
end

local function install_amount_setter_hooks(ctx)
    if ctx.amount_setter.installed then return end

    local hooked = 0

    if hook_amount_setter(ctx, "set_CurrRate(System.Single)") then hooked = hooked + 1 end
    if hook_amount_setter(ctx, "set_CurrTargetRate(System.Single)") then hooked = hooked + 1 end
    if hook_amount_setter(ctx, "set_CurrRateDiff(System.Single)") then hooked = hooked + 1 end
    if hook_amount_setter(ctx, "set_CurrMaxFrame(System.Single)") then hooked = hooked + 1 end
    if hook_amount_setter(ctx, "set_CurrVirtualMinFrame(System.Single)") then hooked = hooked + 1 end
    if hook_amount_setter(ctx, "set_CurrVirtualMaxFrame(System.Single)") then hooked = hooked + 1 end

    ctx.amount_setter.installed = true
    ctx.amount_setter.last_value = "hooked: " .. tostring(hooked)
end

function hud.install(ctx)
    if ctx.hud_native.installed then return end

    local td = sdk.find_type_definition("chainsaw.VitalAmountGui.AmountStatusGui")
    if td == nil then
        ctx.set_error("No AmountStatusGui type")
        return
    end

    local method =
        td:get_method("update(System.Single elapsedSec)") or
        td:get_method("update(System.Single)")

    if method == nil then
        ctx.set_error("No AmountStatusGui.update method")
        return
    end

    sdk.hook(method,
        function(args)
            ctx.hud_native.calls = ctx.hud_native.calls + 1

            local obj = ctx.managed_from_arg(args, 2)
            if obj ~= nil then
                ctx.amount_status_gui = obj

                hud.refresh(ctx)

                if ctx.circle_test.force_arc and ctx.circle_probe.circle ~= nil then
                    local ok, err = pcall(function()
                        local set_arc = ctx.circle_probe.circle
                            :get_type_definition()
                            :get_method("set_ArcAngle(via.Float2)")

                        if set_arc ~= nil then
                            set_arc:call(
                                ctx.circle_probe.circle,
                                Vector2f.new(0.0, ctx.circle_test.arc_y)
                            )
                        end
                    end)

                    if not ok then
                        ctx.circle_test.last_error = tostring(err)
                    end
                end
            end
        end,
        function(retval)
            return retval
        end
    )

    ctx.hud_native.installed = true
    install_amount_setter_hooks(ctx)
end

return hud