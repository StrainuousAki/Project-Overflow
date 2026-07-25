------------------------------------------------------------
-- Project: Overflow — Item Window Menu State
-- Build 49.66
--
-- Read-only main inventory-tab discriminator.
--
-- Validated runtime route:
-- AppSingleton<chainsaw.HighwayGuiManager>.get_Instance()
--   -> get_CsItemWindowGuiControlBehavior()
--
-- No hooks, managed-object scans, writes, save/profile calls, or stat calls.
------------------------------------------------------------

local state = {
    poll_interval = 0.10,
    last_poll_time = 0.0,
    manager = nil,
    controller = nil,
    manager_source = "not resolved",
    controller_source = "not resolved",
    curr_step = nil,
    curr_root_state = nil,
    curr_focus_tab = nil,
    items_active = false,
    readable = false,
    poll_calls = 0,
    poll_failures = 0,
    last_error = "",
    status = "Item Window menu state has not been polled."
}

local ITEM_WINDOW_STEP_MOVE = 8
local ITEM_WINDOW_ROOT_MAIN = 17
local TAB_MAP = 0
local TAB_ITEMS = 1
local TAB_CRAFTING = 2
local TAB_KEY_TREASURE = 3
local TAB_FILES = 4

local function safe_call(object, method_name, ...)
    if object == nil then
        return nil, false
    end

    local arguments = { ... }
    local ok, result =
        pcall(function()
            return object:call(
                method_name,
                table.unpack(arguments)
            )
        end)

    return ok and result or nil, ok
end

local function safe_field(object, field_name)
    if object == nil then
        return nil, false
    end

    local ok, result =
        pcall(function()
            return object:get_field(
                field_name
            )
        end)

    return ok and result or nil, ok
end

local function enum_number(value)
    if value == nil then
        return nil
    end

    if type(value) == "number" then
        return math.floor(value)
    end

    local direct = tonumber(value)
    if direct ~= nil then
        return math.floor(direct)
    end

    local raw =
        safe_field(
            value,
            "value__"
        )

    direct = tonumber(raw)

    return direct ~= nil
        and math.floor(direct)
        or nil
end

local function read_enum(object, getter, field_name)
    local value, ok =
        safe_call(
            object,
            getter
        )

    if not ok or value == nil then
        value =
            safe_field(
                object,
                field_name
            )
    end

    return enum_number(value)
end

local function resolve_manager()
    if state.manager ~= nil then
        return state.manager
    end

    local definition = nil

    pcall(function()
        definition =
            sdk.find_type_definition(
                "AppSingleton`1<chainsaw.HighwayGuiManager>"
            )
    end)

    if definition == nil then
        pcall(function()
            definition =
                sdk.find_type_definition(
                    "AppSingleton<chainsaw.HighwayGuiManager>"
                )
        end)
    end

    if definition == nil then
        state.manager_source =
            "HighwayGuiManager AppSingleton type unavailable."

        return nil
    end

    local method = nil

    pcall(function()
        method =
            definition:get_method(
                "get_Instance()"
            )
    end)

    if method == nil then
        pcall(function()
            method =
                definition:get_method(
                    "get_Instance"
                )
        end)
    end

    if method == nil then
        state.manager_source =
            "HighwayGuiManager get_Instance unavailable."

        return nil
    end

    local manager = nil
    local ok, error_message =
        pcall(function()
            manager =
                method:call(nil)
        end)

    if not ok then
        state.last_error =
            tostring(error_message)

        state.manager_source =
            "HighwayGuiManager get_Instance call failed."

        return nil
    end

    state.manager =
        manager

    state.manager_source =
        manager ~= nil
        and "AppSingleton.get_Instance():call(nil)"
        or "HighwayGuiManager instance unavailable."

    return manager
end

local function resolve_controller()
    local manager =
        resolve_manager()

    if manager == nil then
        return nil
    end

    local controller, ok =
        safe_call(
            manager,
            "get_CsItemWindowGuiControlBehavior"
        )

    if not ok or controller == nil then
        controller =
            safe_field(
                manager,
                "_CsItemWindowGuiControlBehavior"
            )
    end

    if controller == nil then
        controller =
            safe_field(
                manager,
                "<CsItemWindowGuiControlBehavior>k__BackingField"
            )
    end

    state.controller =
        controller

    state.controller_source =
        controller ~= nil
        and "HighwayGuiManager Item Window controller"
        or "Item Window controller unavailable."

    return controller
end

local function tab_name(value)
    if value == TAB_MAP then
        return "Map"
    elseif value == TAB_ITEMS then
        return "Items"
    elseif value == TAB_CRAFTING then
        return "Crafting"
    elseif value == TAB_KEY_TREASURE then
        return "Keys & Treasures"
    elseif value == TAB_FILES then
        return "Files"
    end

    return "Unknown"
end

function state.update(attache_busy)
    local now =
        os.clock()

    if now - state.last_poll_time
        < state.poll_interval
    then
        return state.items_active
    end

    state.last_poll_time =
        now

    state.poll_calls =
        state.poll_calls + 1

    if attache_busy ~= true then
        state.items_active = false
        state.readable = false
        state.status =
            "Attaché case closed; Items progression hidden."

        return false
    end

    local controller =
        resolve_controller()

    if controller == nil then
        state.poll_failures =
            state.poll_failures + 1

        state.items_active = false
        state.readable = false
        state.manager = nil
        state.controller = nil
        state.status =
            "Item Window controller unavailable; progression hidden."

        return false
    end

    state.curr_step =
        read_enum(
            controller,
            "get_CurrStep",
            "<CurrStep>k__BackingField"
        )

    state.curr_root_state =
        read_enum(
            controller,
            "get_CurrRootState",
            "<CurrRootState>k__BackingField"
        )

    state.curr_focus_tab =
        read_enum(
            controller,
            "get_CurrFocusTabElement",
            "<CurrFocusTabElement>k__BackingField"
        )

    state.readable =
        state.curr_step ~= nil
        and state.curr_root_state ~= nil
        and state.curr_focus_tab ~= nil

    -- Fail closed during transitions and on unknown values. The progression
    -- overlay belongs only to the stable Items tab.
    state.items_active =
        state.readable
        and state.curr_step == ITEM_WINDOW_STEP_MOVE
        and state.curr_root_state == ITEM_WINDOW_ROOT_MAIN
        and state.curr_focus_tab == TAB_ITEMS

    state.status =
        state.items_active
        and "Stable Items tab confirmed."
        or (
            "Progression hidden: "
            .. tab_name(state.curr_focus_tab)
            .. " tab or transition state."
        )

    return state.items_active
end

function state.is_items_active()
    return state.items_active == true
end

return state
