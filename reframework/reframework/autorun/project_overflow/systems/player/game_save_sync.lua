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
local campaign =
    require("project_overflow.systems.player.campaign")
local stat_application =
    require("project_overflow.systems.player.stat_application")

local action_speed =
    require("project_overflow.systems.player.action_speed")

local sync = {
    installed = false,
    installed_hooks = 0,
    save_request_hook_installed = false,
    load_request_hook_installed = false,
    direct_save_request_hook_installed = false,
    direct_load_request_hook_installed = false,
    last_direct_save_request_raw_slot = nil,
    last_direct_load_request_raw_slot = nil,
    campaign_identifier_hook_installed = false,
    last_campaign_identifier = "none",
    last_cursor_slot = nil,
    last_cursor_is_autosave = nil,
    last_current_request_source = "none",
    last_current_request_raw_slot = nil,
    direct_save_flow_hook_installed = false,
    set_play_load_data_hook_installed = false,
    last_direct_flow_raw_slot = nil,
    last_set_play_load_slot = nil,
    last_set_play_load_is_autosave = nil,
    ignored_negative_request_slots = 0,
    save_completion_used_authoritative_campaign = false,
    save_completion_hook_installed = false,
    load_completion_hook_installed = false,
    autosave_hook_installed = false,
    active_slot = nil,
    active_campaign = "leon",
    pending_slot = nil,
    pending_campaign = nil,
    pending_raw_slot = nil,
    ignored_menu_cursor_events = 0,
    save_events = 0,
    load_events = 0,
    skipped_events = 0,
    captures = 0,
    queued_save_slot = nil,
    queued_load_slot = nil,
    queued_save_campaign = nil,
    queued_load_campaign = nil,
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
    pending_load_request_campaign = nil,
    pending_load_request_raw_slot = nil,
    load_request_locked = false,
    ignored_load_requests = 0,

    -- Main-menu lifecycle is the only authority allowed to clear an active
    -- campaign profile. Player and HitPoint captures are gameplay references,
    -- not proof that the game entered or left a campaign.
    main_menu_hook_installed = false,
    leon_menu_hook_installed = false,
    separate_ways_menu_hook_installed = false,
    separate_ways_menu_installed_hooks = 0,
    separate_ways_menu_resolved_type = "none",
    separate_ways_main_menu_method_hooks = 0,
    separate_ways_main_menu_methods = "none",
    separate_ways_last_method = "none",
    separate_ways_menu_active = false,
    separate_ways_menu_events = 0,
    campaign_menu_authority = "none",
    campaign_menu_trigger = "none",
    campaign_authority_serial = 0,
    last_loaded_profile_identity = "none",
    last_native_load_campaign = "none",
    last_native_load_slot = "none",
    main_menu_active = false,
    main_menu_cleanup_fired = false,
    main_menu_object = nil,
    main_menu_phase = nil,
    main_menu_phase_name = "unknown",
    main_menu_new_game_start = false,
    main_menu_events = 0,
    native_load_serial = 0,
    new_game_resets = 0,
    last_new_game_reset = "none",
    campaign_initialization_pending = false,
    campaign_initialization_source = "none",
    campaign_initialization_resumes = 0,
    title_profile_resets = 0,

    campaign_detection_source = "default",
    campaign_detection_evidence = "none",
    campaign_detection_count = 0,

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
    if type(value) == "number" then
        return math.floor(value)
    end

    if value == nil then
        return nil
    end

    -- Primitive parameters in sdk.hook args are commonly native pointers.
    -- Decode them before falling back to managed/enum conversion.
    local native_value = nil

    pcall(function()
        native_value =
            sdk.to_int64(value)
    end)

    if native_value ~= nil then
        return math.floor(native_value)
    end

    pcall(function()
        native_value =
            sdk.to_int32(value)
    end)

    if native_value ~= nil then
        return math.floor(native_value)
    end

    local direct =
        tonumber(value)

    if direct ~= nil then
        return math.floor(direct)
    end

    local enum_value =
        field(value, "value__")

    direct =
        tonumber(enum_value)

    return
        direct ~= nil
        and math.floor(direct)
        or nil
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

local function normalize_native_request_slot(
    value,
    campaign_key
)
    local slot_id =
        number_value(
            value
        )

    local normalized_campaign =
        campaign.normalize(campaign_key)

    local manual_limit =
        normalized_campaign == "separate_ways"
        and 10
        or 20

    -- Native save-slot identity:
    --   0       = autosave
    --   Leon    = manual slots 01..20
    --   Ada/AO  = manual slots 01..10
    if slot_id == 0 then
        return "autosave"
    end

    -- Separate Ways uses a physical 100-series save range:
    --   100 = autosave
    --   101..110 = manual slots 01..10
    if normalized_campaign == "separate_ways" then
        if slot_id == 100 then
            return "autosave"
        end

        if slot_id >= 101 and slot_id <= 110 then
            return slot_id - 100
        end
    end

    if slot_id ~= nil
        and slot_id >= 1
        and slot_id <= manual_limit
    then
        return slot_id
    end

    return nil
end

local function select(key, load_profile, campaign_key)
    campaign_key =
        campaign.normalize(campaign_key)
        or campaign.active_campaign()
        or "leon"

    campaign.set_active(
        campaign_key,
        "save synchronization",
        key
    )

    rpg.set_active_campaign(campaign_key)

    local ok =
        rpg.select_save_slot(
            key,
            load_profile == true,
            campaign_key
        )

    if ok then
        sync.active_slot = rpg.active_save_slot()
        sync.active_campaign = rpg.active_campaign()
        sync.status =
            "Active native RPG identity: "
            .. tostring(rpg.active_save_identity())
    else
        sync.skipped_events = sync.skipped_events + 1
        sync.status = rpg.last_message
    end

    return ok
end

local function resolve_campaign(args, operation)
    local request_object =
        args ~= nil
        and managed(args[4])
        or nil

    local manager_object =
        args ~= nil
        and managed(args[2])
        or nil

    local player_object =
        runtime_ctx ~= nil
        and runtime_ctx.state ~= nil
        and runtime_ctx.state.player
        or nil

    local detected = nil
    local source = nil
    local evidence = nil

    if sync.campaign_menu_authority == "separate_ways_ao_main_menu" then
        detected = "separate_ways"
        source = sync.campaign_menu_authority
        evidence = sync.campaign_menu_trigger
    elseif sync.campaign_menu_authority == "re4r_main_menu" then
        detected = "leon"
        source = sync.campaign_menu_authority
        evidence = sync.campaign_menu_trigger
    else
        detected,
        source,
        evidence =
            campaign.detect(
                request_object,
                manager_object,
                player_object
            )
    end

    detected =
        campaign.normalize(detected)

    sync.campaign_detection_source =
        tostring(source or operation or "unknown")
    sync.campaign_detection_evidence =
        tostring(evidence or "none")
    sync.campaign_detection_count =
        sync.campaign_detection_count + 1

    if detected == nil then
        sync.status =
            "Native "
            .. tostring(operation or "save/load")
            .. " campaign was unresolved; RPG profile I/O skipped to prevent Leon/Separate Ways crossover."

        return nil
    end

    sync.active_campaign = detected
    rpg.set_active_campaign(detected)

    return detected
end

local function capture_menu_slot(_args)
    -- Save-menu selection callbacks expose cyclic cursor movement:
    -- autosave can report 01 or 20 depending on scroll direction, and manual
    -- rows report the neighboring destination. They are not transaction IDs.
    -- This function intentionally does nothing.
end

local function queue_native_save(
    key,
    raw,
    delay_frames,
    source,
    campaign_key
)
    sync.queued_save_slot =
        key

    sync.queued_save_campaign =
        campaign.normalize(campaign_key)
        or sync.active_campaign

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


local function campaign_from_identifier(identifier)
    if identifier == nil then
        return nil
    end

    local text =
        string.lower(
            tostring(identifier)
        )

    if
        text:find("anotherorder", 1, true)
        or text:find("another_order", 1, true)
        or text:find("separate", 1, true)
        or text:find("ada", 1, true)
        or text:find("ao", 1, true)
    then
        return "separate_ways"
    end

    if
        text:find("main", 1, true)
        or text:find("leon", 1, true)
    then
        return "leon"
    end

    local numeric =
        number_value(
            identifier
        )

    -- Runtime disassembly of getCampaignIdentifier shows only two valid
    -- nonzero return values. Treat 1 as main campaign and 2 as AO/Separate Ways.
    if numeric == 1 then
        return "leon"
    end

    if numeric == 2 then
        return "separate_ways"
    end

    return nil
end

local function campaign_for_native_slot(raw_slot)
    local util =
        sdk.find_type_definition(
            "share.SaveDataUtil"
        )

    if util == nil then
        return nil, nil
    end

    local method =
        util:get_method(
            "getCampaignIdentifier(System.Int32)"
        )
        or util:get_method(
            "getCampaignIdentifier"
        )

    if method == nil then
        return nil, nil
    end

    local ok, identifier =
        pcall(function()
            return method:call(
                nil,
                raw_slot
            )
        end)

    if not ok then
        return nil, nil
    end

    sync.last_campaign_identifier =
        tostring(identifier)

    return
        campaign_from_identifier(identifier),
        identifier
end

local function cursor_slot_from_manager(manager)
    if manager == nil then
        return nil, nil
    end

    local cursor =
        call(
            manager,
            "get_TempPlayLoadData()"
        )
        or call(
            manager,
            "get_TempPlayLoadData"
        )
        or field(
            manager,
            "<TempPlayLoadData>k__BackingField"
        )
        or field(
            manager,
            "_TempPlayLoadData"
        )

    if cursor == nil then
        return nil, nil
    end

    local is_autosave =
        call(cursor, "get_IsAutoSaveData()")
        or call(cursor, "get_IsAutoSaveData")
        or field(cursor, "IsAutoSaveData")

    local slot =
        call(cursor, "get_Slot()")
        or call(cursor, "get_Slot")
        or field(cursor, "Slot")

    sync.last_cursor_slot =
        number_value(slot)

    sync.last_cursor_is_autosave =
        is_autosave == true

    if is_autosave == true then
        return "autosave", slot
    end

    return
        normalize_native_request_slot(
            slot,
            sync.active_campaign
        ),
        slot
end

local function capture_direct_save_flow(args)
    local raw_slot =
        number_value(
            args[3]
        )

    sync.last_direct_flow_raw_slot =
        raw_slot

    sync.status =
        "requestStartSaveGameDataFlow raw slot: "
        .. tostring(raw_slot)

    if raw_slot == nil or raw_slot < 0 then
        if raw_slot ~= nil and raw_slot < 0 then
            sync.ignored_negative_request_slots =
                sync.ignored_negative_request_slots + 1
        end
        return
    end

    local campaign_key =
        sync.active_campaign
        or resolve_campaign(
            args,
            "direct save flow"
        )

    if campaign_key == nil then
        return
    end

    local key =
        normalize_native_request_slot(
            raw_slot,
            campaign_key
        )

    if key == nil then
        return
    end

    sync.pending_slot = key
    sync.pending_campaign = campaign_key
    sync.pending_raw_slot = raw_slot
    sync.last_native_save_request_slot = raw_slot
    sync.last_resolved_save_slot = key
    sync.active_slot = key
    sync.captures = sync.captures + 1

    if select(key, false, campaign_key) then
        rpg.record_native_save_event(
            key,
            "direct_save_flow",
            raw_slot,
            campaign_key
        )

        sync.status =
            "requestStartSaveGameDataFlow captured "
            .. tostring(campaign_key)
            .. ":"
            .. tostring(key)
            .. "."
    end
end

local function capture_set_play_load_data(args)
    local is_autosave =
        args[3] == true
        or tostring(args[3]) == "true"

    local raw_slot =
        number_value(
            args[4]
        )

    sync.last_set_play_load_is_autosave =
        is_autosave

    sync.last_set_play_load_slot =
        raw_slot

    if raw_slot == nil then
        return
    end

    if raw_slot < 0 and is_autosave ~= true then
        sync.ignored_negative_request_slots =
            sync.ignored_negative_request_slots + 1
        return
    end

    local campaign_key =
        sync.active_campaign
        or resolve_campaign(
            args,
            "setPlayLoadData"
        )

    if campaign_key == nil then
        return
    end

    local key =
        is_autosave
        and "autosave"
        or normalize_native_request_slot(
            raw_slot,
            campaign_key
        )

    if key == nil then
        return
    end

    sync.pending_slot = key
    sync.pending_campaign = campaign_key
    sync.pending_raw_slot = raw_slot
    sync.last_native_save_request_slot = raw_slot
    sync.last_resolved_save_slot = key
    sync.active_slot = key
    sync.captures = sync.captures + 1

    if select(key, false, campaign_key) then
        rpg.record_native_save_event(
            key,
            is_autosave
            and "set_play_load_autosave"
            or "set_play_load_manual",
            raw_slot,
            campaign_key
        )

        sync.status =
            "setPlayLoadData captured "
            .. tostring(campaign_key)
            .. ":"
            .. tostring(key)
            .. "."
    end
end

local function capture_direct_save_request(args)
    local raw_slot =
        number_value(
            args[3]
        )

    sync.last_direct_save_request_raw_slot =
        raw_slot

    if raw_slot == nil then
        return
    end

    local detected_campaign =
        campaign_for_native_slot(
            raw_slot
        )

    local campaign_key =
        campaign.normalize(
            detected_campaign
        )
        or resolve_campaign(
            args,
            "direct save request"
        )

    if campaign_key == nil then
        sync.skipped_events =
            sync.skipped_events + 1
        return
    end

    local key =
        normalize_native_request_slot(
            raw_slot,
            campaign_key
        )

    if key == nil then
        sync.status =
            "Direct native save request used invalid "
            .. tostring(campaign_key)
            .. " slot "
            .. tostring(raw_slot)
            .. "."
        sync.skipped_events =
            sync.skipped_events + 1
        return
    end

    sync.direct_save_request_hook_installed = true
    sync.last_native_request_slot = raw_slot
    sync.last_native_save_request_slot = raw_slot
    sync.last_resolved_save_slot = key
    sync.pending_slot = key
    sync.pending_campaign = campaign_key
    sync.pending_raw_slot = raw_slot
    sync.active_slot = key
    sync.captures = sync.captures + 1

    if select(key, false, campaign_key) then
        rpg.record_native_save_event(
            key,
            "direct_save_request",
            raw_slot,
            campaign_key
        )

        sync.status =
            "Direct SaveDataManager request captured "
            .. tostring(campaign_key)
            .. ":"
            .. tostring(key)
            .. "; waiting for completion."
    end
end

local function capture_direct_load_request(args)
    local raw_slot =
        number_value(
            args[3]
        )

    sync.last_direct_load_request_raw_slot =
        raw_slot

    if raw_slot == nil then
        return
    end

    local detected_campaign =
        campaign_for_native_slot(
            raw_slot
        )

    local campaign_key =
        campaign.normalize(
            detected_campaign
        )
        or resolve_campaign(
            args,
            "direct load request"
        )

    if campaign_key == nil then
        sync.skipped_events =
            sync.skipped_events + 1
        return
    end

    local key =
        normalize_native_request_slot(
            raw_slot,
            campaign_key
        )

    if key == nil then
        sync.status =
            "Direct native load request used invalid "
            .. tostring(campaign_key)
            .. " slot "
            .. tostring(raw_slot)
            .. "."
        sync.skipped_events =
            sync.skipped_events + 1
        return
    end

    sync.direct_load_request_hook_installed = true
    sync.native_load_requests =
        sync.native_load_requests + 1
    sync.native_load_serial =
        sync.native_load_serial + 1
    sync.last_native_request_slot = raw_slot
    sync.last_native_load_request_slot = raw_slot
    sync.last_resolved_load_slot = key
    sync.pending_load_request_slot = key
    sync.pending_load_request_campaign = campaign_key
    sync.pending_load_request_raw_slot = raw_slot
    sync.load_request_locked = true
    sync.active_slot = key
    sync.captures = sync.captures + 1

    select(
        key,
        false,
        campaign_key
    )

    sync.status =
        "Direct SaveDataManager load request captured "
        .. tostring(campaign_key)
        .. ":"
        .. tostring(key)
        .. "; waiting for completion."
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

    local campaign_key =
        resolve_campaign(
            args,
            "save request"
        )

    if campaign_key == nil then
        sync.skipped_events =
            sync.skipped_events + 1
        return
    end

    if campaign_key == nil then
        sync.skipped_events =
            sync.skipped_events + 1
        return
    end

    local key =
        normalize_native_request_slot(
            raw_slot,
            campaign_key
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

        sync.pending_campaign =
            campaign_key

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
                false,
                campaign_key
            )

        if selected then
            rpg.record_native_save_event(
                key,
                "save_request",
                raw_slot,
                campaign_key
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

    if requires_fresh_campaign then
        -- This is the first save identity emitted by a newly created player,
        -- not a native Load Game transaction. Reset before autosave selection
        -- so no stale level, XP, attributes, HP tracking, movement state, or
        -- queued profile snapshot can be written into the new campaign.
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
        false,
        campaign_key
    )

    if sync.campaign_initialization_pending == true then
        rpg.record_native_save_event(
            "autosave",
            "new_campaign_initialize",
            raw_slot,
            campaign_key
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
        "Native autosave request captured",
        campaign_key
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

    local campaign_key =
        resolve_campaign(
            args,
            "load request"
        )

    local key =
        normalize_native_request_slot(
            raw_slot,
            campaign_key
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

    sync.pending_load_request_campaign =
        campaign_key

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
            false,
            campaign_key
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
        call(object, "get_SlotId")
        or call(object, "get_SlotID")
        or call(object, "get_Slot")
        or call(object, "get_slotId")
        or call(object, "get_slotId")
        or field(object, "<SlotId>k__BackingField")
        or field(object, "<SlotID>k__BackingField")
        or field(object, "<Slot>k__BackingField")
        or field(object, "SlotId")
        or field(object, "SlotID")
        or field(object, "slotId")
        or field(object, "slotID")
        or field(object, "Slot")
        or field(object, "_SlotId")
        or field(object, "_SlotID")
        or field(object, "_Slot")
        or field(object, "slot")
        or field(object, "slotId")

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

        if raw ~= nil and raw >= 0 then
            return
                raw,
                candidate.source .. ".SlotId"
        end

        if raw ~= nil and raw < 0 then
            sync.ignored_negative_request_slots =
                sync.ignored_negative_request_slots + 1
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
            sync.last_current_request_source =
                candidate.source
            sync.last_current_request_raw_slot =
                raw

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

    local menu_manager =
        managed(
            args[2]
        )

    local manager =
        save_data_manager()

    local campaign_key =
        sync.pending_campaign
        or sync.active_campaign
        or rpg.active_campaign()

    if campaign_key ~= nil then
        sync.save_completion_used_authoritative_campaign = true
    else
        campaign_key =
            resolve_campaign(
                args,
                "save completion"
            )
    end

    if campaign_key == nil then
        sync.skipped_events =
            sync.skipped_events + 1
        sync.pending_slot = nil
        sync.pending_campaign = nil
        sync.pending_raw_slot = nil
        return
    end

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
        key, raw, source =
            current_save_request_slot(
                manager
            )
    end

    if
        key == nil
        and sync.pending_slot == "autosave"
    then
        key, raw =
            cursor_slot_from_manager(
                manager
            )

        if key == "autosave" then
            source =
                "SaveDataManager.TempPlayLoadData explicit autosave"
        else
            key = nil
            raw = nil
        end
    end

    if
        key == nil
        and sync.last_native_save_request_slot ~= nil
    then
        raw =
            sync.last_native_save_request_slot

        key =
            normalize_native_request_slot(
                raw,
                campaign_key
            )

        if key ~= nil then
            source =
                "last direct save request"
        end
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
                false,
                campaign_key
            )

        if selected then
            rpg.record_native_save_event(
                key,
                "save_selected",
                raw,
                campaign_key
            )

            queue_native_save(
                key,
                raw,
                5,
                "Native save completed via "
                .. tostring(source),
                campaign_key
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
    sync.pending_campaign = nil
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
    local menu_manager = managed(args[2])
    local manager = save_data_manager()
    local continue_load = call(manager, "get_IsLastDataLoadContinueData")
    if continue_load == nil then
        continue_load = field(manager, "<IsLastDataLoadContinueData>k__BackingField")
            or field(manager, "IsLastDataLoadContinueData")
    end
    sync.last_load_was_continue = continue_load == true

    local key, raw

    local campaign_key =
        sync.pending_load_request_campaign
        or sync.active_campaign
        or rpg.active_campaign()

    if campaign_key == nil then
        campaign_key =
            resolve_campaign(
                args,
                "load completion"
            )
    end

    if campaign_key == nil then
        stat_application.end_native_load()
        sync.skipped_events =
            sync.skipped_events + 1
        sync.pending_load_request_slot = nil
        sync.pending_load_request_campaign = nil
        sync.pending_load_request_raw_slot = nil
        sync.load_request_locked = false
        return
    end

    if sync.last_load_was_continue then
        key, raw =
            "autosave",
            "continue/autosave"
    elseif sync.pending_load_request_slot ~= nil then
        key, raw =
            sync.pending_load_request_slot,
            sync.pending_load_request_raw_slot
    else
        local manager_slot =
            call(manager, "get_LastLoadSucceededGameSlot()")
            or call(manager, "get_LastLoadSucceededGameSlot")
            or call(manager, "get_LastLoadSlot()")
            or call(manager, "get_LastLoadSlot")
            or field(manager, "<LastLoadSucceededGameSlot>k__BackingField")
            or field(manager, "<LastLoadSlot>k__BackingField")

        raw =
            number_value(
                manager_slot
            )

        key =
            normalize_native_request_slot(
                raw,
                campaign_key
            )

        if key == nil then
            key, raw =
                cursor_slot_from_manager(
                    manager
                )
        end

        if key == nil then
            key, raw =
                completion_slot(
                    args
                )
        end
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
        sync.queued_load_campaign = campaign_key
        sync.queued_load_raw_slot = raw
        sync.load_delay_frames = 120
        sync.load_requires_recapture = true
        sync.status = "Native load completed; RPG load queued for " .. tostring(key) .. "."
    end
    sync.pending_load_request_slot = nil
    sync.pending_load_request_campaign = nil
    sync.pending_load_request_raw_slot = nil
    sync.load_request_locked = false

    -- Save-menu state is separate and must not be used to resolve loads.
    sync.pending_slot = nil
    sync.pending_raw_slot = nil
end

local function profile_owner_pointer()
    -- Stable RPG ownership uses only PlayerCharacterContext identity.
    if action_speed ~= nil then
        local player_type =
            tostring(
                action_speed.player_context_type
                or "unknown"
            )

        local pointer =
            action_speed.player_context_ptr

        local valid_type =
            player_type == "chainsaw.PlayerCharacterContext"
            or player_type == "chainsaw.PlayerCharacterContextComponent"

        if valid_type
            and action_speed.player_context ~= nil
            and pointer ~= nil
            and pointer ~= "nil"
            and pointer ~= "unknown"
            and pointer ~= "0"
        then
            return tostring(pointer)
        end
    end

    return nil
end

local function read_main_menu_state(object)
    object = object or sync.main_menu_object

    if object == nil then
        sync.main_menu_phase = nil
        sync.main_menu_phase_name = "unavailable"
        sync.main_menu_new_game_start = false
        return false
    end

    local phase =
        call(object, "get_CurrPhase()")
        or call(object, "get_CurrPhase")
        or field(object, "<CurrPhase>k__BackingField")

    sync.main_menu_phase =
        number_value(phase)

    sync.main_menu_phase_name =
        phase ~= nil
        and tostring(phase)
        or "unknown"

    sync.main_menu_new_game_start =
        field(object, "_IsNewGameStart") == true

    return true
end

local function set_campaign_from_menu(
    campaign_key,
    authority,
    trigger,
    object
)
    local normalized =
        campaign.normalize(campaign_key)

    if normalized == nil then
        return false
    end

    campaign.set_active(
        normalized,
        authority,
        trigger
    )

    rpg.set_active_campaign(
        normalized
    )

    sync.active_campaign =
        normalized

    sync.campaign_menu_authority =
        tostring(authority or "menu")

    sync.campaign_menu_trigger =
        tostring(trigger or "unknown")

    sync.campaign_authority_serial =
        sync.campaign_authority_serial + 1

    sync.campaign_detection_source =
        sync.campaign_menu_authority

    local type_name = "unknown"
    if object ~= nil then
        pcall(function()
            type_name =
                object:get_type_definition():get_full_name()
        end)
    end

    sync.campaign_detection_evidence =
        type_name
        .. "."
        .. sync.campaign_menu_trigger

    sync.campaign_detection_count =
        sync.campaign_detection_count + 1

    return true
end

local function capture_separate_ways_menu_enter(args)
    local object =
        managed(args[2])

    sync.separate_ways_menu_active = true
    sync.separate_ways_menu_events =
        sync.separate_ways_menu_events + 1

    set_campaign_from_menu(
        "separate_ways",
        "separate_ways_ao_main_menu",
        "enterInMainMenu",
        object
    )

    sync.status =
        "Separate Ways bonus-game menu entered; Ada campaign selected."
end

local function capture_separate_ways_menu_update(args)
    local object =
        managed(args[2])

    if sync.separate_ways_menu_active ~= true then
        sync.separate_ways_menu_active = true
        sync.separate_ways_menu_events =
            sync.separate_ways_menu_events + 1
    end

    set_campaign_from_menu(
        "separate_ways",
        "separate_ways_ao_main_menu",
        "update",
        object
    )
end

local function capture_separate_ways_menu_leave(args)
    local object =
        managed(args[2])

    sync.separate_ways_menu_active = false
    sync.separate_ways_menu_events =
        sync.separate_ways_menu_events + 1

    -- Keep Ada selected after leaving the bonus menu so the following
    -- gameplay save/load transaction remains bound to Separate Ways.
    set_campaign_from_menu(
        "separate_ways",
        "separate_ways_ao_main_menu",
        "leaveInMainMenu_to_gameplay",
        object
    )

    sync.status =
        "Separate Ways bonus-game menu left; Ada campaign retained for gameplay."
end

local function capture_main_menu_enter(args)
    local object =
        managed(args[2])

    sync.main_menu_object = object
    sync.main_menu_active = true

    sync.separate_ways_menu_active = false

    set_campaign_from_menu(
        "leon",
        "re4r_main_menu",
        "enterInMainMenu",
        object
    )
    sync.main_menu_cleanup_fired = false
    sync.main_menu_events =
        sync.main_menu_events + 1

    read_main_menu_state(object)
end

local function capture_main_menu_update(args)
    local object =
        managed(args[2])

    if object == nil then
        return
    end

    if sync.main_menu_active ~= true then
        sync.main_menu_active = true
        sync.main_menu_cleanup_fired = false
        sync.main_menu_events =
            sync.main_menu_events + 1
    end

    sync.main_menu_object = object

    sync.separate_ways_menu_active = false

    set_campaign_from_menu(
        "leon",
        "re4r_main_menu",
        "update",
        object
    )

    read_main_menu_state(object)
end

local function capture_main_menu_leave(args)
    local object =
        managed(args[2])

    if object ~= nil then
        read_main_menu_state(object)
    end

    sync.main_menu_active = false
    sync.main_menu_object = nil
    sync.main_menu_phase = nil
    sync.main_menu_phase_name = "left main menu"
    sync.main_menu_new_game_start = false
end

local function bind_profile_to_current_player(source)
    local pointer =
        profile_owner_pointer()

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
        profile_owner_pointer()

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
    sync.pending_campaign = nil
    sync.pending_raw_slot = nil
    sync.pending_load_request_slot = nil
    sync.pending_load_request_campaign = nil
    sync.pending_load_request_raw_slot = nil
    sync.queued_load_slot = nil
    sync.queued_load_campaign = nil
    sync.queued_load_raw_slot = nil
    sync.queued_save_slot = nil
    sync.queued_save_campaign = nil
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
        tostring(source or "main-menu campaign reset")

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
    if sync.main_menu_active ~= true then
        return
    end

    read_main_menu_state(
        sync.main_menu_object
    )

    if sync.main_menu_cleanup_fired == true then
        return
    end

    sync.main_menu_cleanup_fired = true

    suspend_for_uninitialized_campaign(
        sync.main_menu_new_game_start
        and "main menu entered for New Game"
        or "main menu entered"
    )

    if
        sync.separate_ways_menu_active ~= true
        and sync.campaign_menu_authority ~= "separate_ways_ao_main_menu"
    then
        set_campaign_from_menu(
            "leon",
            "re4r_main_menu",
            sync.main_menu_new_game_start
            and "new_game_selection"
            or "menu_selection",
            sync.main_menu_object
        )
    end

    sync.status =
        sync.main_menu_new_game_start
        and "Main menu confirmed New Game; fresh RPG initialization pending."
        or "Main menu confirmed; previous RPG profile cleared."
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
            local campaign_key =
                sync.queued_load_campaign
                or sync.active_campaign
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
            sync.queued_load_campaign = nil
            sync.queued_load_raw_slot = nil
            -- Never subtract a persisted Vitality bonus before loading the
            -- target RPG profile. That bonus may have been saved under an
            -- older HP-per-point balance and can corrupt native Max HP before
            -- reconciliation. Resetting tracking after selection lets
            -- stat_application rebuild from the loaded snapshot safely.
            if select(key, true, campaign_key) then
                sync.last_native_load_campaign =
                    tostring(campaign_key)

                sync.last_native_load_slot =
                    tostring(key)

                sync.last_loaded_profile_identity =
                    tostring(campaign_key)
                    .. ":"
                    .. tostring(key)

                rpg.record_native_save_event(
                    key,
                    "load",
                    raw,
                    campaign_key
                )

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
            local campaign_key =
                sync.queued_save_campaign
                or sync.active_campaign
            local raw = sync.queued_save_raw_slot
            local snapshot =
                sync.queued_save_profile

            sync.queued_save_slot = nil
            sync.queued_save_campaign = nil
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
            local selected =
                select(
                    key,
                    false,
                    campaign_key
                )
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
                    raw,
                    campaign_key
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
        sync.queued_load_campaign =
            rpg.active_campaign()
        sync.load_delay_frames = 120
        sync.status = sync.status .. " Queued remembered " ..
            tostring(remembered_slot) .. " profile after script enable."
        return true
    end
    return false
end


local function install_exact_separate_ways_menu_hooks()
    local type_name =
        "chainsaw.GameStateAOMainMenu"

    local entered =
        install_hook(
            type_name,
            "enterInMainMenu()",
            capture_separate_ways_menu_enter,
            nil,
            "enterInMainMenu",
            0
        )

    local updated =
        install_hook(
            type_name,
            "update()",
            capture_separate_ways_menu_update,
            nil,
            "update",
            0
        )

    local left =
        install_hook(
            type_name,
            "leaveInMainMenu()",
            capture_separate_ways_menu_leave,
            nil,
            "leaveInMainMenu",
            0
        )

    local installed = 0

    if entered then
        installed = installed + 1
    end

    if updated then
        installed = installed + 1
    end

    if left then
        installed = installed + 1
    end

    sync.separate_ways_menu_installed_hooks =
        installed

    sync.separate_ways_menu_hook_installed =
        entered
        and updated
        and left

    sync.separate_ways_menu_resolved_type =
        installed > 0
        and type_name
        or "none"

    sync.separate_ways_main_menu_method_hooks =
        0

    sync.separate_ways_main_menu_methods =
        "exact GameStateAOMainMenu lifecycle hooks"

    return sync.separate_ways_menu_hook_installed
end

function sync.install(ctx, hp, options)
    runtime_ctx = ctx or runtime_ctx
    health_system = hp or health_system
    options = type(options) == "table" and options or {}

    if sync.installed then
        queue_remembered_profile()
        return true
    end
    sync.direct_save_flow_hook_installed =
        install_hook(
            "share.SaveDataManager",
            "requestStartSaveGameDataFlow(System.Int32,share.GameSaveRequestArgs)",
            capture_direct_save_flow,
            nil,
            "requestStartSaveGameDataFlow",
            2
        )
        or install_hook(
            "share.SaveDataManager",
            "requestStartSaveGameDataFlow",
            capture_direct_save_flow,
            nil,
            "requestStartSaveGameDataFlow",
            2
        )

    sync.set_play_load_data_hook_installed =
        install_hook(
            "share.SaveDataManager",
            "setPlayLoadData(System.Boolean,System.Int32)",
            capture_set_play_load_data,
            nil,
            "setPlayLoadData",
            2
        )
        or install_hook(
            "share.SaveDataManager",
            "setPlayLoadData",
            capture_set_play_load_data,
            nil,
            "setPlayLoadData",
            2
        )

    sync.direct_save_request_hook_installed =
        install_hook(
            "share.SaveDataManager",
            "requestSaveGameData(System.Int32,share.GameSaveRequestArgs)",
            capture_direct_save_request,
            nil,
            "requestSaveGameData",
            2
        )
        or install_hook(
            "share.SaveDataManager",
            "requestSaveGameData",
            capture_direct_save_request,
            nil,
            "requestSaveGameData",
            2
        )

    sync.direct_load_request_hook_installed =
        install_hook(
            "share.SaveDataManager",
            "requestLoadGameData(System.Int32,share.GameLoadRequestArgs)",
            capture_direct_load_request,
            nil,
            "requestLoadGameData",
            2
        )
        or install_hook(
            "share.SaveDataManager",
            "requestLoadGameData",
            capture_direct_load_request,
            nil,
            "requestLoadGameData",
            2
        )

    sync.save_request_hook_installed =
        install_hook(
            "share.SaveDataManager",
            "enqueueSaveRequest(System.Int32,share.SaveLoadRequestArgs)",
            capture_save_request,
            nil,
            "enqueueSaveRequest",
            nil
        )
        or install_hook(
            "share.SaveDataManager",
            "enqueueSaveRequest",
            capture_save_request,
            nil,
            "enqueueSaveRequest",
            2
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
        or install_hook(
            "share.SaveDataManager",
            "enqueueLoadRequest",
            capture_load_request,
            nil,
            "enqueueLoadRequest",
            2
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

    local entered_main_menu =
        install_hook(
            "chainsaw.GameStateMainMenu",
            "enterInMainMenu()",
            capture_main_menu_enter
        )

    local updated_main_menu =
        install_hook(
            "chainsaw.GameStateMainMenu",
            "update()",
            capture_main_menu_update
        )

    local left_main_menu =
        install_hook(
            "chainsaw.GameStateMainMenu",
            "leaveInMainMenu()",
            capture_main_menu_leave
        )

    sync.main_menu_hook_installed =
        updated_main_menu
        and left_main_menu

    sync.leon_menu_hook_installed =
        entered_main_menu
        or updated_main_menu

    install_exact_separate_ways_menu_hooks()

    if entered_main_menu ~= true
        and updated_main_menu == true
    then
        sync.status =
            "Main-menu update hook installed; enter hook unavailable."
    end

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
