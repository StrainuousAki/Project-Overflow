------------------------------------------------------------
-- Maintenance classification — Build 49.39
-- Module: autorun/project_overflow/systems/player/game_save_sync.lua
-- Role: Player RPG profile, attributes, saves, experience, and stat application.
-- Status: active subsystem.
--
-- Compatibility policy:
--   Existing functions, hooks, module paths, and diagnostics are
--   intentionally retained in this maintenance pass.
--   `DEPRECATED` marks a supported legacy path, not removed code.
------------------------------------------------------------

------------------------------------------------------------
-- Project: Overflow — Native Save / RPG Slot Synchronization
------------------------------------------------------------

local rpg = require("project_overflow.systems.player.rpg")
local stat_application =
    require("project_overflow.systems.player.stat_application")

local action_speed =
    require("project_overflow.systems.player.action_speed")

local sync = {
    installed = false,
    installed_hooks = 0,
    save_request_hook_installed = false,
    load_request_hook_installed = false,
    save_completion_hook_installed = false,
    load_completion_hook_installed = false,
    autosave_hook_installed = false,
    active_slot = nil,
    pending_slot = nil,
    pending_raw_slot = nil,
    ignored_menu_cursor_events = 0,
    save_events = 0,
    load_events = 0,
    skipped_events = 0,
    captures = 0,
    queued_save_slot = nil,
    queued_load_slot = nil,
    queued_save_raw_slot = nil,
    queued_load_raw_slot = nil,
    queued_save_profile = nil,
    save_delay_frames = 0,
    load_delay_frames = 0,
    load_requires_recapture = false,
    last_load_was_continue = false,
    native_save_requests = 0,
    native_load_requests = 0,
    autosave_requests = 0,
    last_native_request_slot = nil,
    last_native_save_request_slot = nil,
    last_native_load_request_slot = nil,
    last_resolved_save_slot = nil,
    last_resolved_load_slot = nil,
    last_save_manager_slot = nil,
    last_save_manager_source = nil,
    pending_load_request_slot = nil,
    pending_load_request_raw_slot = nil,
    load_request_locked = false,
    ignored_load_requests = 0,

    -- Campaign-session isolation. A native Continue/Load always produces a
    -- load request. A New Game started after returning to the title screen
    -- creates a fresh player without one.
    player_absent_frames = 0,
    title_gap_threshold_frames = 600,
    title_gap_armed = false,
    title_gap_load_serial = 0,
    native_load_serial = 0,
    last_runtime_player_ptr = "nil",
    new_game_resets = 0,
    last_new_game_reset = "none",
    campaign_initialization_pending = false,
    campaign_initialization_source = "none",
    campaign_initialization_resumes = 0,
    title_profile_resets = 0,

    profile_bound_player_ptr = "nil",
    profile_bound_load_serial = 0,
    character_binding_resets = 0,
    last_character_binding_status = "none",

    status = "Native RPG save hooks not installed."
}

local runtime_ctx = nil
local health_system = nil

local function copy_table(source)
    local result = {}
    for key, value in pairs(source or {}) do
        result[key] = type(value) == "table" and copy_table(value) or value
    end
    return result
end

local function capture_profile()
    return copy_table(rpg.profile())
end

local function refresh_health_snapshot()
    if runtime_ctx == nil or health_system == nil then return false end
    pcall(function()
        if health_system.refresh ~= nil then
            health_system.refresh(runtime_ctx)
        end
        stat_application.update(runtime_ctx, health_system)
    end)
    return true
end

local function managed(value)
    if value == nil then return nil end
    local ok, result = pcall(function() return sdk.to_managed_object(value) end)
    return ok and result or nil
end

local function field(object, name)
    if object == nil then return nil end
    local ok, result = pcall(function() return object:get_field(name) end)
    return ok and result or nil
end

local function call(object, name, ...)
    if object == nil then return nil end
    local arguments = { ... }
    local ok, result = pcall(function()
        return object:call(name, table.unpack(arguments))
    end)
    return ok and result or nil
end

local function number_value(value)
    if type(value) == "number" then return math.floor(value) end
    if value == nil then return nil end
    local direct = tonumber(value)
    if direct ~= nil then return math.floor(direct) end
    local enum_value = field(value, "value__")
    direct = tonumber(enum_value)
    return direct ~= nil and math.floor(direct) or nil
end

local function looks_autosave(value)
    return tostring(value or ""):lower():find("auto", 1, true) ~= nil
end

local function event_slot(object)
    if object == nil then return nil, nil end
    local candidates = {
        "SlotID", "SlotId", "slotId", "slotID", "SlotIndex", "slotIndex",
        "SaveSlot", "saveSlot", "AppSaveSlot", "SaveSlotID", "SaveSlotId",
        "TargetSlotID", "TargetSlotId", "_SlotID", "_SlotId",
        "<SlotID>k__BackingField", "<SlotId>k__BackingField",
        "<SlotIndex>k__BackingField", "<SaveSlot>k__BackingField"
    }
    for _, name in ipairs(candidates) do
        local value = field(object, name)
        if value ~= nil then
            if looks_autosave(value) then return "autosave", value end
            local number = number_value(value)
            if number ~= nil then return number, value end
        end
    end
    return nil, nil
end

local function normalize_manual_index(index)
    index =
        number_value(
            index
        )

    if index == nil then
        return nil
    end

    -- Runtime validation:
    -- visible slot 09 reports menu index 9. The menu index is therefore already
    -- the displayed 1..20 manual-slot number on this build and must not receive
    -- a +1 translation.
    if index >= 1 and index <= 20 then
        return index
    end

    return nil
end

-- Native AppSaveSlot IDs are stable and must not be treated like the
-- zero-based GUI cursor: 00 is autosave, while 01..20 are manual slots.
local function normalize_native_slot(value)
    if looks_autosave(value) then return "autosave" end
    local number = number_value(value)
    if number == 0 then return "autosave" end
    if number ~= nil and number >= 1 and number <= 20 then
        return number
    end
    return nil
end

local function normalize_native_request_slot(value)
    local slot_id =
        number_value(
            value
        )

    -- Native save-slot identity is direct and shared by save and load:
    --   0     = autosave
    --   1..20 = manual save slots 01..20
    if slot_id == 0 then
        return "autosave"
    end

    if slot_id ~= nil
        and slot_id >= 1
        and slot_id <= 20
    then
        return slot_id
    end

    return nil
end

local function select(key, load_profile)
    local ok = rpg.select_save_slot(key, load_profile == true)
    if ok then
        sync.active_slot = rpg.active_save_slot()
        sync.status = "Active native slot: " .. tostring(sync.active_slot)
    else
        sync.skipped_events = sync.skipped_events + 1
        sync.status = rpg.last_message
    end
    return ok
end

local function capture_menu_slot(_args)
    -- Save-menu selection callbacks expose cyclic cursor movement:
    -- autosave can report 01 or 20 depending on scroll direction, and manual
    -- rows report the neighboring destination. They are not transaction IDs.
    -- This function intentionally does nothing.
end

local function queue_native_save(key, raw, delay_frames, source)
    sync.queued_save_slot =
        key

    sync.queued_save_raw_slot =
        raw

    sync.queued_save_profile =
        nil

    sync.save_delay_frames =
        math.max(
            1,
            tonumber(delay_frames) or 5
        )

    sync.status =
        tostring(source or "Native save request")
        .. "; RPG write queued for "
        .. tostring(key)
        .. "."
end

local function capture_save_request(args)
    local raw_slot =
        number_value(
            args[3]
        )

    if raw_slot == nil then
        return
    end

    sync.native_save_requests =
        sync.native_save_requests + 1

    sync.last_native_request_slot =
        raw_slot

    sync.last_native_save_request_slot =
        raw_slot

    local key =
        normalize_native_request_slot(
            raw_slot
        )

    sync.last_resolved_save_slot =
        key

    if key ~= "autosave" then
        -- Runtime diagnostics showed the save-menu selection hooks do not fire
        -- on this path, while SaveDataManager exposes the actual manual slot
        -- directly. Capture it here, but leave the profile write owned by the
        -- native completion callback.
        sync.pending_slot =
            key

        sync.pending_raw_slot =
            raw_slot

        sync.menu_cursor_slot =
            sync.menu_cursor_slot

        sync.active_slot =
            key

        sync.captures =
            sync.captures + 1

        local selected =
            select(
                key,
                false
            )

        if selected then
            rpg.record_native_save_event(
                key,
                "save_request",
                raw_slot
            )

            sync.status =
                "Native manual save request captured for "
                .. tostring(key)
                .. "; waiting for completion callback."
        else
            sync.skipped_events =
                sync.skipped_events + 1

            sync.status =
                "Native manual save request captured, but active-slot selection failed for "
                .. tostring(key)
                .. "."
        end

        return
    end

    sync.autosave_requests =
        sync.autosave_requests + 1

    sync.captures =
        sync.captures + 1

    sync.pending_slot =
        "autosave"

    sync.pending_raw_slot =
        raw_slot

    sync.active_slot =
        "autosave"

    local previous_bound_player =
        sync.profile_bound_player_ptr

    local requires_fresh_campaign,
          live_player_pointer =
        current_player_requires_fresh_campaign()

    if requires_fresh_campaign
        and sync.title_gap_armed == true
    then
        -- A changed player is treated as a New Game only after a confirmed
        -- player-absence gap. Native save/typewriter screens can temporarily
        -- hide or recreate the player object, so pointer change alone must
        -- never clear the active RPG profile.
        suspend_for_uninitialized_campaign(
            "new character detected before first autosave"
        )

        sync.character_binding_resets =
            sync.character_binding_resets + 1

        sync.last_character_binding_status =
            "Player changed from "
            .. tostring(previous_bound_player)
            .. " to "
            .. tostring(live_player_pointer)
            .. " without a native load; defaults restored before autosave."
    end

    select(
        "autosave",
        false
    )

    if sync.campaign_initialization_pending == true then
        rpg.record_native_save_event(
            "autosave",
            "new_campaign_initialize",
            raw_slot
        )

        resume_campaign_application(
            "first native autosave request"
        )

        bind_profile_to_current_player(
            "first native autosave request"
        )
    elseif sync.profile_bound_player_ptr == "nil" then
        bind_profile_to_current_player(
            "existing campaign autosave"
        )
    end

    -- Autosave has no manual menu selection, so the native request queue owns
    -- this path exclusively.
    queue_native_save(
        "autosave",
        raw_slot,
        120,
        "Native autosave request captured"
    )
end

local function capture_load_request(args)
    local raw_slot =
        number_value(
            args[3]
        )

    if raw_slot == nil then
        return
    end

    sync.native_load_requests =
        sync.native_load_requests + 1

    sync.native_load_serial =
        sync.native_load_serial + 1

    sync.last_native_request_slot =
        raw_slot

    sync.last_native_load_request_slot =
        raw_slot

    local key =
        normalize_native_request_slot(
            raw_slot
        )

    sync.last_resolved_load_slot =
        key

    if key == nil then
        sync.status =
            "Native load request used unknown slot "
            .. tostring(raw_slot)
            .. "; ignored."

        return
    end

    -- A single native load produces several internal requests. The first valid
    -- row is the player's selected save; later requests are support/detail
    -- traffic and must not replace it.
    if sync.load_request_locked == true then
        sync.ignored_load_requests =
            sync.ignored_load_requests + 1

        sync.status =
            "Ignored later native load request raw "
            .. tostring(raw_slot)
            .. "; transaction locked to "
            .. tostring(sync.pending_load_request_slot)
            .. "."

        return
    end

    sync.pending_load_request_slot =
        key

    sync.pending_load_request_raw_slot =
        raw_slot

    sync.load_request_locked =
        true

    sync.active_slot =
        key

    sync.captures =
        sync.captures + 1

    local selected =
        select(
            key,
            false
        )

    if selected then
        sync.status =
            "Locked native load request raw "
            .. tostring(raw_slot)
            .. " directly to "
            .. tostring(key)
            .. "; waiting for completion callback."
    else
        sync.skipped_events =
            sync.skipped_events + 1

        sync.status =
            "Native load request captured, but active-slot selection failed for "
            .. tostring(key)
            .. "."
    end
end

local function mark_autosave()
    -- Retained only as a fallback signal. The real autosave write is owned by
    -- share.SaveDataManager.enqueueSaveRequest so this callback cannot write
    -- a stale profile before the native transaction begins.
    sync.pending_slot =
        "autosave"

    sync.pending_raw_slot =
        "autosave-trigger"

    sync.status =
        "Autosave trigger observed; waiting for native SaveDataManager request."
end

local function completion_slot(args)
    local event = managed(args[3])
    local key, raw = event_slot(event)

    -- SaveDataManager request capture is authoritative for both save and load
    -- because completion-event slot values use a different numbering space.
    if sync.pending_slot ~= nil then
        return
            sync.pending_slot,
            sync.pending_raw_slot
    end

    -- Autosave is unambiguous and must never consume a stale manual menu slot.
    if looks_autosave(key) or number_value(key) == 0 then
        return "autosave", raw or key
    end

    -- The captured menu value already equals the displayed 1..20 slot and must
    -- win over completion-event values, which can lag or refer to a different
    -- internal cursor during save/load transitions.
    if
        sync.pending_slot ~= nil
        and sync.pending_slot ~= "autosave"
    then
        return sync.pending_slot, sync.pending_raw_slot
    end

    -- Last-resort recovery when the menu hook did not fire: accept a native
    -- manual value only when it is already within the displayed 1..20 range.
    local event_number = number_value(key)
    local manual_slot =
        normalize_manual_index(
            event_number
        )

    if manual_slot ~= nil then
        return manual_slot, raw or key
    end

    return nil, raw or key
end

local function save_data_manager()
    local manager = nil

    pcall(function()
        manager =
            sdk.get_managed_singleton(
                "share.SaveDataManager"
            )
    end)

    return manager
end

local function request_slot_from_object(object)
    if object == nil then
        return nil
    end

    local raw =
        call(
            object,
            "get_SlotId"
        )
        or field(
            object,
            "<SlotId>k__BackingField"
        )
        or field(
            object,
            "SlotId"
        )

    return
        number_value(
            raw
        )
end

local function current_save_request_slot(manager)
    if manager == nil then
        return nil, nil
    end

    local request_candidates = {
        {
            source = "CurrentProcess",
            object =
                call(
                    manager,
                    "get_CurrentProcess"
                )
                or field(
                    manager,
                    "<CurrentProcess>k__BackingField"
                )
                or field(
                    manager,
                    "CurrentProcess"
                )
        },
        {
            source = "CurrentRequest",
            object =
                call(
                    manager,
                    "get_CurrentRequest"
                )
                or field(
                    manager,
                    "<CurrentRequest>k__BackingField"
                )
                or field(
                    manager,
                    "CurrentRequest"
                )
                or field(
                    manager,
                    "_CurrentRequest"
                )
        },
        {
            source = "Request",
            object =
                field(
                    manager,
                    "Request"
                )
                or field(
                    manager,
                    "_Request"
                )
        }
    }

    for _, candidate in ipairs(request_candidates) do
        local raw =
            request_slot_from_object(
                candidate.object
            )

        if raw ~= nil then
            return
                raw,
                candidate.source .. ".SlotId"
        end
    end

    return nil, nil
end

local function completed_save_slot(_menu_manager)
    local manager =
        save_data_manager()

    if manager == nil then
        return nil, nil, nil
    end

    local request_raw, request_source =
        current_save_request_slot(
            manager
        )

    local request_key =
        normalize_native_request_slot(
            request_raw
        )

    if request_key ~= nil then
        return
            request_key,
            request_raw,
            request_source
    end

    local direct_candidates = {
        {
            source = "LastSaveSlot",
            value =
                call(
                    manager,
                    "get_LastSaveSlot"
                )
                or field(
                    manager,
                    "<LastSaveSlot>k__BackingField"
                )
                or field(
                    manager,
                    "LastSaveSlot"
                )
        },
        {
            source = "CurrentSaveSlot",
            value =
                call(
                    manager,
                    "get_CurrentSaveSlot"
                )
                or field(
                    manager,
                    "<CurrentSaveSlot>k__BackingField"
                )
                or field(
                    manager,
                    "CurrentSaveSlot"
                )
        },
        {
            source = "LastRequestSlot",
            value =
                call(
                    manager,
                    "get_LastRequestSlot"
                )
                or field(
                    manager,
                    "<LastRequestSlot>k__BackingField"
                )
                or field(
                    manager,
                    "LastRequestSlot"
                )
        }
    }

    for _, candidate in ipairs(direct_candidates) do
        local raw =
            number_value(
                candidate.value
            )

        local key =
            normalize_native_request_slot(
                raw
            )

        if key ~= nil then
            return
                key,
                raw,
                candidate.source
        end
    end

    return nil, nil, nil
end

local function on_save_completed(args)
    -- Completing a native save proves that any preceding player-absence gap
    -- belonged to the save/typewriter flow rather than a New Game transition.
    -- Preserve the active RPG slot even when this particular completion event
    -- does not expose a SlotId.
    sync.title_gap_armed = false
    sync.player_absent_frames = 0

    local manager =
        managed(
            args[2]
        )

    local key, raw, source =
        completed_save_slot(
            manager
        )

    -- The request capture is authoritative when available. Manager fields are
    -- used when the request hook did not resolve in this runtime.
    if sync.pending_slot ~= nil then
        key =
            sync.pending_slot

        raw =
            sync.pending_raw_slot

        source =
            "captured save request"
    end

    if key == nil then
        key, raw =
            completion_slot(
                args
            )

        source =
            "completion-event fallback"
    end

    sync.last_save_manager_slot =
        raw

    sync.last_save_manager_source =
        source

    sync.last_resolved_save_slot =
        key

    if key == nil then
        sync.skipped_events =
            sync.skipped_events + 1

        sync.status =
            "Native save completed, but no save SlotId was available from "
            .. "request capture, SaveDataManager, or completion event; "
            .. "RPG write skipped."
    else
        local selected =
            select(
                key,
                false
            )

        if selected then
            rpg.record_native_save_event(
                key,
                "save_selected",
                raw
            )

            queue_native_save(
                key,
                raw,
                5,
                "Native save completed via "
                .. tostring(source)
            )

            sync.status =
                "Native save completed; "
                .. tostring(source)
                .. " resolved RPG save to "
                .. tostring(key)
                .. "."
        else
            sync.skipped_events =
                sync.skipped_events + 1

            sync.status =
                "Native save completed but active-slot selection failed for "
                .. tostring(key)
                .. "."
        end
    end

    sync.pending_slot = nil
    sync.pending_raw_slot = nil
end

local function on_load_completed(args)
    -- Restore and discard the previous profile's movement state before the
    -- loaded player object is recaptured. This prevents an already-multiplied
    -- fallback field value from becoming the next save's native baseline.
    if action_speed ~= nil
        and action_speed.begin_native_load ~= nil
    then
        pcall(function()
            action_speed.begin_native_load()
        end)
    end

    stat_application.begin_native_load()
    local manager = managed(args[2])
    local continue_load = call(manager, "get_IsLastDataLoadContinueData")
    if continue_load == nil then
        continue_load = field(manager, "<IsLastDataLoadContinueData>k__BackingField")
            or field(manager, "IsLastDataLoadContinueData")
    end
    sync.last_load_was_continue = continue_load == true

    local key, raw

    if sync.last_load_was_continue then
        key, raw =
            "autosave",
            "continue/autosave"
    elseif sync.pending_load_request_slot ~= nil then
        key, raw =
            sync.pending_load_request_slot,
            sync.pending_load_request_raw_slot
    else
        -- Last-resort compatibility path only. Normal loads must resolve from
        -- the dedicated SaveDataManager request latch.
        key, raw =
            completion_slot(
                args
            )
    end

    if key == nil and sync.active_slot ~= nil then
        key = sync.active_slot
        raw = "remembered active slot"
    end
    if key == nil then
        stat_application.end_native_load()
        sync.skipped_events = sync.skipped_events + 1
        sync.status = "Native load completed but its slot was unknown; RPG load skipped."
    else
        sync.queued_load_slot = key
        sync.queued_load_raw_slot = raw
        sync.load_delay_frames = 120
        sync.load_requires_recapture = true
        sync.status = "Native load completed; RPG load queued for " .. tostring(key) .. "."
    end
    sync.pending_load_request_slot = nil
    sync.pending_load_request_raw_slot = nil
    sync.load_request_locked = false

    -- Save-menu state is separate and must not be used to resolve loads.
    sync.pending_slot = nil
    sync.pending_raw_slot = nil
end

local function valid_player_pointer()
    if runtime_ctx == nil
        or runtime_ctx.state == nil
    then
        return nil
    end

    local pointer =
        runtime_ctx.state.player_ptr

    if pointer == nil
        or pointer == "nil"
        or pointer == "unknown"
        or pointer == "0"
    then
        return nil
    end

    return tostring(pointer)
end

local function bind_profile_to_current_player(source)
    local pointer =
        valid_player_pointer()

    if pointer == nil then
        return false
    end

    sync.profile_bound_player_ptr =
        pointer

    sync.profile_bound_load_serial =
        sync.native_load_serial

    sync.last_character_binding_status =
        "Bound RPG profile to player "
        .. tostring(pointer)
        .. " via "
        .. tostring(source or "unknown source")
        .. "."

    return true
end

local function current_player_requires_fresh_campaign()
    local pointer =
        valid_player_pointer()

    if pointer == nil then
        return false, nil
    end

    local bound =
        tostring(
            sync.profile_bound_player_ptr or "nil"
        )

    if bound == "nil" then
        return false, pointer
    end

    if pointer == bound then
        return false, pointer
    end

    -- A legitimate Continue/Load creates a different player instance too, but
    -- that instance is accompanied by a newer native load serial. Only a
    -- changed player with no corresponding load transaction is treated as a
    -- newly created campaign character.
    local loaded_for_new_player =
        sync.native_load_serial
        > (
            tonumber(
                sync.profile_bound_load_serial
            ) or 0
        )

    return not loaded_for_new_player, pointer
end

local function suspend_for_uninitialized_campaign(source)
    rpg.clear_save_slot()

    stat_application.begin_native_load()
    stat_application.reset_tracking()

    if action_speed ~= nil
        and action_speed.begin_native_load ~= nil
    then
        pcall(function()
            action_speed.begin_native_load()
        end)
    end

    if health_system ~= nil
        and runtime_ctx ~= nil
    then
        if health_system.begin_native_load ~= nil then
            pcall(function()
                health_system.begin_native_load(
                    runtime_ctx
                )
            end)
        end

        if health_system.mark_dirty ~= nil then
            pcall(function()
                health_system.mark_dirty(
                    runtime_ctx
                )
            end)
        end
    end

    sync.active_slot = nil
    sync.pending_slot = nil
    sync.pending_raw_slot = nil
    sync.pending_load_request_slot = nil
    sync.pending_load_request_raw_slot = nil
    sync.queued_load_slot = nil
    sync.queued_load_raw_slot = nil
    sync.queued_save_slot = nil
    sync.queued_save_raw_slot = nil
    sync.queued_save_profile = nil
    sync.load_delay_frames = 0
    sync.save_delay_frames = 0
    sync.load_requires_recapture = false
    sync.load_request_locked = false

    sync.profile_bound_player_ptr = "nil"
    sync.profile_bound_load_serial =
        sync.native_load_serial

    sync.campaign_initialization_pending = true
    sync.campaign_initialization_source =
        tostring(source or "title gap")

    sync.title_profile_resets =
        sync.title_profile_resets + 1

    sync.new_game_resets =
        sync.new_game_resets + 1

    sync.last_new_game_reset =
        "Defaults restored and stat application suspended at "
        .. sync.campaign_initialization_source
        .. "."

    sync.status =
        "Campaign initialization pending; waiting for native save identity."
end

local function resume_campaign_application(source)
    if sync.campaign_initialization_pending ~= true then
        return false
    end

    sync.campaign_initialization_pending = false
    sync.campaign_initialization_source =
        tostring(source or "native save initialized")

    if rpg.mark_campaign_initialized ~= nil then
        rpg.mark_campaign_initialized(
            sync.campaign_initialization_source
        )
    end

    stat_application.reset_tracking()
    stat_application.end_native_load()

    if health_system ~= nil
        and runtime_ctx ~= nil
        and health_system.mark_dirty ~= nil
    then
        pcall(function()
            health_system.mark_dirty(
                runtime_ctx
            )
        end)
    end

    bind_profile_to_current_player(
        source
    )

    sync.campaign_initialization_resumes =
        sync.campaign_initialization_resumes + 1

    sync.status =
        "RPG application resumed after "
        .. sync.campaign_initialization_source
        .. "."

    return true
end

local function update_campaign_session()
    local player_pointer =
        valid_player_pointer()

    if player_pointer == nil then
        sync.player_absent_frames =
            sync.player_absent_frames + 1

        if sync.player_absent_frames
            >= sync.title_gap_threshold_frames
            and sync.title_gap_armed ~= true
        then
            sync.title_gap_load_serial =
                sync.native_load_serial

            -- A long player-absence gap is only evidence that the title
            -- screen may have been entered. Do not clear the active RPG slot
            -- here: native save/typewriter menus can also keep the player
            -- unavailable for this long. The first autosave of a genuinely
            -- new player performs the reset after identity validation.
            sync.title_gap_armed = true

            sync.status =
                "Player absence gap detected; preserving RPG profile until "
                .. "a native load, completed save, or new-player autosave "
                .. "resolves the session."
        end

        sync.last_runtime_player_ptr =
            "nil"

        return
    end

    sync.player_absent_frames = 0
    sync.last_runtime_player_ptr =
        player_pointer
end

function sync.update()
    update_campaign_session()

    if sync.profile_bound_player_ptr == "nil"
        and sync.campaign_initialization_pending ~= true
        and rpg.active_save_slot() ~= nil
    then
        bind_profile_to_current_player(
            "restored active slot"
        )
    end
    if sync.queued_load_slot ~= nil then
        sync.load_delay_frames = math.max(0, sync.load_delay_frames - 1)
        if sync.load_delay_frames == 0 then
            local key = sync.queued_load_slot
            local raw = sync.queued_load_raw_slot
            if sync.load_requires_recapture then
                sync.load_requires_recapture = false
                if
                    health_system ~= nil and
                    runtime_ctx ~= nil and
                    health_system.begin_native_load ~= nil
                then
                    -- GameLoadCompleted is raised before the old damaged
                    -- player instance has fully disappeared. Waiting through
                    -- the settling period prevents immediately recapturing
                    -- that stale HitPoint. Vitality remains suspended while
                    -- the fresh loaded-player binding is acquired.
                    health_system.begin_native_load(runtime_ctx)
                end
                sync.load_delay_frames = 5
                sync.status =
                    "Native load settled; waiting for fresh player HitPoint."
                return
            end
            if health_system ~= nil and runtime_ctx ~= nil then
                if health_system.mark_dirty ~= nil then
                    health_system.mark_dirty(runtime_ctx)
                end
                if health_system.refresh ~= nil then
                    pcall(function() health_system.refresh(runtime_ctx) end)
                end
            end
            local live_max_hp = runtime_ctx ~= nil and
                tonumber(runtime_ctx.max_hp_number()) or 0
            if live_max_hp == nil or live_max_hp <= 0 then
                sync.load_delay_frames = 1
                sync.status = "Waiting for the loaded native HitPoint before RPG reconciliation."
                return
            end
            sync.queued_load_slot = nil
            sync.queued_load_raw_slot = nil
            -- Never subtract a persisted Vitality bonus before loading the
            -- target RPG profile. That bonus may have been saved under an
            -- older HP-per-point balance and can corrupt native Max HP before
            -- reconciliation. Resetting tracking after selection lets
            -- stat_application rebuild from the loaded snapshot safely.
            if select(key, true) then
                rpg.record_native_save_event(key, "load", raw)

                if sync.campaign_initialization_pending == true then
                    resume_campaign_application(
                        "loaded RPG profile reconciliation"
                    )
                else
                    stat_application.reset_tracking()
                    stat_application.end_native_load()
                end
                if health_system ~= nil and health_system.mark_dirty ~= nil then
                    health_system.mark_dirty(runtime_ctx)
                end
                refresh_health_snapshot()
                bind_profile_to_current_player(
                    "native load "
                    .. tostring(key)
                )

                sync.load_events = sync.load_events + 1
                sync.status = "RPG profile loaded after native " .. tostring(key) .. "."
            else
                stat_application.end_native_load()
                sync.skipped_events = sync.skipped_events + 1
                sync.status = "Deferred RPG load failed for " .. tostring(key) .. "."
            end
        end
    end
    if sync.queued_save_slot ~= nil then
        sync.save_delay_frames = math.max(0, sync.save_delay_frames - 1)
        if sync.save_delay_frames == 0 then
            local key = sync.queued_save_slot
            local raw = sync.queued_save_raw_slot
            local snapshot =
                sync.queued_save_profile

            sync.queued_save_slot = nil
            sync.queued_save_raw_slot = nil
            sync.queued_save_profile = nil

            refresh_health_snapshot()

            -- Native completion can precede final RPG/stat reconciliation.
            -- Capture the entire live profile now, after the delay. A queued
            -- snapshot remains supported for any future caller that provides
            -- one explicitly.
            local live =
                rpg.profile()

            if type(snapshot) ~= "table" then
                snapshot =
                    capture_profile()
            elseif type(live.health) == "table" then
                snapshot.health =
                    copy_table(
                        live.health
                    )
            end
            local selected = select(key, false)
            local saved, save_error = false, nil
            if selected then
                saved, save_error = rpg.save_profile_silent(snapshot)
            end
            if selected and saved then
                sync.active_slot =
                    rpg.active_save_slot()
                    or key

                rpg.record_native_save_event(
                    key,
                    "save",
                    raw
                )

                sync.active_slot =
                    rpg.active_save_slot()
                    or key

                sync.save_events = sync.save_events + 1
                sync.status =
                    "RPG profile saved after native "
                    .. tostring(key)
                    .. "; active slot is "
                    .. tostring(sync.active_slot)
                    .. "."
            else
                sync.skipped_events = sync.skipped_events + 1
                sync.status = "Deferred RPG save failed for " .. tostring(key) ..
                    ": " .. tostring(save_error or rpg.last_message or "unknown error")
            end
        end
    end
end

local function method_parameter_count(method)
    if method == nil then
        return nil
    end

    local count = nil

    pcall(function()
        local parameters =
            method:get_parameters()

        if parameters ~= nil then
            count =
                #parameters
        end
    end)

    return count
end

local function find_method(type_definition, signature, fallback_name, parameter_count)
    if type_definition == nil then
        return nil
    end

    local method = nil

    if signature ~= nil then
        pcall(function()
            method =
                type_definition:get_method(
                    signature
                )
        end)
    end

    if method ~= nil then
        return method
    end

    if fallback_name == nil then
        return nil
    end

    local methods = nil

    pcall(function()
        methods =
            type_definition:get_methods()
    end)

    for _, candidate in ipairs(methods or {}) do
        local name = nil

        pcall(function()
            name =
                candidate:get_name()
        end)

        if name == fallback_name then
            local count =
                method_parameter_count(
                    candidate
                )

            if parameter_count == nil
                or count == parameter_count
            then
                return candidate
            end
        end
    end

    return nil
end

local function install_hook(
    type_name,
    signature,
    pre,
    post,
    fallback_name,
    parameter_count
)
    local type_definition =
        sdk.find_type_definition(
            type_name
        )

    if type_definition == nil then
        return false
    end

    local method =
        find_method(
            type_definition,
            signature,
            fallback_name,
            parameter_count
        )

    if method == nil then
        return false
    end

    local ok =
        pcall(function()
            sdk.hook(
                method,
                pre or function() end,
                post or function(retval)
                    return retval
                end
            )
        end)

    if ok then
        sync.installed_hooks =
            sync.installed_hooks + 1
    end

    return ok
end

local function queue_remembered_profile()
    local remembered_slot = rpg.active_save_slot()
    if remembered_slot ~= nil then
        sync.queued_load_slot = remembered_slot
        sync.load_delay_frames = 120
        sync.status = sync.status .. " Queued remembered " ..
            tostring(remembered_slot) .. " profile after script enable."
        return true
    end
    return false
end

function sync.install(ctx, hp)
    runtime_ctx = ctx or runtime_ctx
    health_system = hp or health_system
    if sync.installed then
        queue_remembered_profile()
        return true
    end
    sync.save_request_hook_installed =
        install_hook(
            "share.SaveDataManager",
            "enqueueSaveRequest(System.Int32,share.SaveLoadRequestArgs)",
            capture_save_request,
            nil,
            "enqueueSaveRequest",
            nil
        )

    sync.load_request_hook_installed =
        install_hook(
            "share.SaveDataManager",
            "enqueueLoadRequest(System.Int32,share.SaveLoadRequestArgs)",
            capture_load_request,
            nil,
            "enqueueLoadRequest",
            nil
        )

    sync.save_completion_hook_installed =
        install_hook(
            "chainsaw.SaveLoadMenuGuiManager",
            "onGameSaveCompleted(share.GameSaveCompletedEventArgs)",
            on_save_completed
        )

    sync.load_completion_hook_installed =
        install_hook(
            "chainsaw.SaveLoadMenuGuiManager",
            "onGameLoadCompleted(share.GameLoadCompletedEventArgs)",
            on_load_completed
        )

    sync.autosave_hook_installed =
        install_hook(
            "chainsaw.AutoSaveSetting",
            "onHitAutoSave()",
            mark_autosave
        )

    sync.installed =
        sync.save_completion_hook_installed
        and sync.load_completion_hook_installed
        and sync.save_request_hook_installed
        and sync.load_request_hook_installed
    sync.status = sync.installed
        and string.format("Installed %d native save-slot hook(s).", sync.installed_hooks)
        or string.format("Only %d native save-slot hook(s) resolved.", sync.installed_hooks)
    queue_remembered_profile()
    return sync.installed
end

return sync
