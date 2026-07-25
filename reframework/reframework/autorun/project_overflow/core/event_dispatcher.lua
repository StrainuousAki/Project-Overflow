------------------------------------------------------------
-- Maintenance classification — Build 49.39
-- Module: autorun/project_overflow/core/event_dispatcher.lua
-- Role: Shared utility, context, constants, logging, or event infrastructure.
-- Status: active infrastructure.
--
-- Compatibility policy:
--   Existing functions, hooks, module paths, and diagnostics are
--   intentionally retained in this maintenance pass.
--   `DEPRECATED` marks a supported legacy path, not removed code.
------------------------------------------------------------

------------------------------------------------------------
-- Project: Overflow — Event Dispatcher
--
-- Small deterministic event bus for decoupling engine probes from
-- gameplay systems. Listeners run by descending priority and are
-- isolated with pcall so one subsystem cannot erase a kill record.
------------------------------------------------------------

local dispatcher = {
    listeners = {},
    sequence = 0,
    emitted_count = 0,
    listener_call_count = 0,
    listener_error_count = 0,
    last_event = "none",
    last_error = ""
}

local function clean_name(value, fallback)
    local text = tostring(value or "")

    if text == "" or text == "nil" then
        return fallback
    end

    return text
end

local function sort_listeners(listeners)
    table.sort(
        listeners,
        function(a, b)
            if a.priority == b.priority then
                return a.sequence < b.sequence
            end

            return a.priority > b.priority
        end
    )
end

function dispatcher.subscribe(event_name, listener_name, callback, priority)
    event_name = clean_name(event_name, "unknown_event")
    listener_name = clean_name(listener_name, "anonymous_listener")

    if type(callback) ~= "function" then
        return false, "callback must be a function"
    end

    dispatcher.listeners[event_name] =
        dispatcher.listeners[event_name] or {}

    local listeners = dispatcher.listeners[event_name]

    for _, listener in ipairs(listeners) do
        if listener.name == listener_name then
            listener.callback = callback
            listener.priority = tonumber(priority) or listener.priority or 0
            listener.enabled = true
            sort_listeners(listeners)
            return true, listener
        end
    end

    dispatcher.sequence = dispatcher.sequence + 1

    local listener = {
        name = listener_name,
        callback = callback,
        priority = tonumber(priority) or 0,
        sequence = dispatcher.sequence,
        enabled = true,
        calls = 0,
        errors = 0,
        last_error = "",
        last_duration = 0
    }

    listeners[#listeners + 1] = listener
    sort_listeners(listeners)

    return true, listener
end

function dispatcher.unsubscribe(event_name, listener_name)
    local listeners = dispatcher.listeners[tostring(event_name or "")]

    if listeners == nil then
        return false
    end

    for index, listener in ipairs(listeners) do
        if listener.name == listener_name then
            table.remove(listeners, index)
            return true
        end
    end

    return false
end

function dispatcher.emit(event_name, payload)
    event_name = clean_name(event_name, "unknown_event")

    dispatcher.emitted_count = dispatcher.emitted_count + 1
    dispatcher.last_event = event_name
    dispatcher.last_error = ""

    local result = {
        event_name = event_name,
        payload = payload,
        listener_count = 0,
        successful_count = 0,
        error_count = 0,
        errors = {}
    }

    local listeners = dispatcher.listeners[event_name] or {}

    for _, listener in ipairs(listeners) do
        if listener.enabled == true then
            result.listener_count = result.listener_count + 1
            listener.calls = listener.calls + 1
            dispatcher.listener_call_count =
                dispatcher.listener_call_count + 1

            local started_at = os.clock()
            local ok, listener_result =
                pcall(listener.callback, payload, event_name)

            listener.last_duration = os.clock() - started_at

            if ok then
                result.successful_count = result.successful_count + 1
                listener.last_error = ""
            else
                local error_text = tostring(listener_result)

                listener.errors = listener.errors + 1
                listener.last_error = error_text
                dispatcher.listener_error_count =
                    dispatcher.listener_error_count + 1
                dispatcher.last_error = error_text

                result.error_count = result.error_count + 1
                result.errors[#result.errors + 1] = {
                    listener = listener.name,
                    error = error_text
                }
            end
        end
    end

    return result
end

function dispatcher.get_listeners(event_name)
    return dispatcher.listeners[tostring(event_name or "")] or {}
end

function dispatcher.clear_stats()
    dispatcher.emitted_count = 0
    dispatcher.listener_call_count = 0
    dispatcher.listener_error_count = 0
    dispatcher.last_event = "none"
    dispatcher.last_error = ""

    for _, listeners in pairs(dispatcher.listeners) do
        for _, listener in ipairs(listeners) do
            listener.calls = 0
            listener.errors = 0
            listener.last_error = ""
            listener.last_duration = 0
        end
    end
end

return dispatcher
