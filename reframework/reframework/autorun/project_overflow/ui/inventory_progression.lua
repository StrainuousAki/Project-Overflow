------------------------------------------------------------
-- Maintenance classification — Build 49.39
-- Module: autorun/project_overflow/ui/inventory_progression.lua
-- Role: ImGui or native-overlay presentation and diagnostics.
-- Status: active UI.
--
-- Compatibility policy:
--   Existing functions, hooks, module paths, and diagnostics are
--   intentionally retained in this maintenance pass.
--   `DEPRECATED` marks a supported legacy path, not removed code.
------------------------------------------------------------

------------------------------------------------------------
-- Project: Overflow — Inventory Progression Overlay
-- Transactional, resolution-aware attribute allocation panel.
------------------------------------------------------------

local rpg = require("project_overflow.systems.player.rpg")
local stats = require("project_overflow.systems.player.stats")
local item_window_menu_state =
    require("project_overflow.ui.item_window_menu_state")

local ATTRIBUTES = {
    { key = "strength", label = "STRENGTH" },
    { key = "vitality", label = "VITALITY" },
    { key = "dexterity", label = "DEXTERITY" },
    { key = "agility", label = "AGILITY" },
    { key = "intelligence", label = "INTELLIGENCE" },
    { key = "luck", label = "LUCK" }
}

local function empty_pending()
    local result = {}
    for _, attribute in ipairs(ATTRIBUTES) do result[attribute.key] = 0 end
    return result
end

local state_key = "project_overflow_inventory_progression_state"
local panel = rawget(_G, state_key) or {
    installed = false, open = false, open_calls = 0, close_calls = 0,
    installed_hooks = 0, reference_width = 2560.0,
    reference_height = 1440.0, reference_left = 101.0,
    reference_width_px = 524.0, vertical_offset = -70.0,
    force_visible = false, active_until = 0.0, active_pulses = 0,
    hover_attribute = "none", last_spent_attribute = "none",
    spend_count = 0, mouse_supported = false,
    input_status = "Waiting for inventory input.",
    status = "Inventory progression hooks not installed.",
    last_type = "none", last_method = "none",
    pending = empty_pending(), pending_total = 0,
    bounds = nil, blocked_native_clicks = 0, native_click_pending = false,
    case_behavior = nil, items_inventory_value = nil,
    current_inventory_value = "unknown", items_screen_visible = false,
    last_controller_probe = 0.0, controller_probe_status = "Not scanned",
    screen_width = 2560.0, screen_height = 1440.0,
    uniform_scale = 1.0, resolution_source = "reference fallback"
}
_G[state_key] = panel
-- Fields added by newer builds must also exist when reusing persistent state.
panel.native_click_pending = panel.native_click_pending == true
panel.items_screen_visible = panel.items_screen_visible == true
panel.last_controller_probe = tonumber(panel.last_controller_probe) or 0.0
panel.controller_probe_status = panel.controller_probe_status or "Not scanned"
panel.screen_width = tonumber(panel.screen_width) or 2560.0
panel.screen_height = tonumber(panel.screen_height) or 1440.0
panel.uniform_scale = tonumber(panel.uniform_scale) or 1.0
panel.resolution_source = panel.resolution_source or "reference fallback"
panel.hook_revision = tonumber(panel.hook_revision) or 0
panel.native_mouse_x = tonumber(panel.native_mouse_x)
panel.native_mouse_y = tonumber(panel.native_mouse_y)
panel.native_mouse_down = panel.native_mouse_down == true
panel.mouse_input_source = panel.mouse_input_source or "unavailable"
panel.native_view_width = tonumber(panel.native_view_width)
panel.native_view_height = tonumber(panel.native_view_height)
panel.input_client_width = tonumber(panel.input_client_width)
panel.input_client_height = tonumber(panel.input_client_height)
panel.observed_mouse_max_x = tonumber(panel.observed_mouse_max_x) or 0.0
panel.observed_mouse_max_y = tonumber(panel.observed_mouse_max_y) or 0.0
panel.input_scale_source = panel.input_scale_source or "unresolved"
panel.last_render_width = tonumber(panel.last_render_width)
panel.last_render_height = tonumber(panel.last_render_height)
panel.last_native_view_width = tonumber(panel.last_native_view_width)
panel.last_native_view_height = tonumber(panel.last_native_view_height)
panel.input_recalibrate_until = tonumber(panel.input_recalibrate_until) or 0.0
panel.input_reset_count = tonumber(panel.input_reset_count) or 0
panel.input_reset_reason = panel.input_reset_reason or "none"
panel.startup_calibration_frames = tonumber(panel.startup_calibration_frames) or 0
panel.pair_candidate_width = tonumber(panel.pair_candidate_width)
panel.pair_candidate_height = tonumber(panel.pair_candidate_height)
panel.pair_candidate_hits = tonumber(panel.pair_candidate_hits) or 0
panel.native_sample_generation = tonumber(panel.native_sample_generation) or 0
panel.startup_native_generation = tonumber(panel.startup_native_generation) or 0
panel.startup_imgui_x = tonumber(panel.startup_imgui_x)
panel.startup_imgui_y = tonumber(panel.startup_imgui_y)
panel.startup_imgui_moved = panel.startup_imgui_moved == true
panel.live_imgui_mouse_x = tonumber(panel.live_imgui_mouse_x)
panel.live_imgui_mouse_y = tonumber(panel.live_imgui_mouse_y)
panel.live_imgui_mouse_time = tonumber(panel.live_imgui_mouse_time) or 0.0
panel.cursor_pair_error = tonumber(panel.cursor_pair_error) or 0.0
panel.cursor_source_switches = tonumber(panel.cursor_source_switches) or 0
panel.last_cursor_source = tostring(panel.last_cursor_source or "none")
panel.imgui_cursor_fresh_duration =
    tonumber(panel.imgui_cursor_fresh_duration) or 0.20

panel.attache_manager = nil
panel.attache_busy = false
panel.attache_manager_polls = 0
panel.attache_manager_failures = 0
panel.attache_manager_last_error = ""
panel.attache_manager_status = "Waiting for AttacheCaseManager singleton."

panel.map_manager = nil
panel.map_active = panel.map_active == true
panel.map_poll_interval =
    math.max(
        0.10,
        tonumber(panel.map_poll_interval) or 0.15
    )
panel.map_last_poll_time =
    tonumber(panel.map_last_poll_time) or 0.0
panel.map_poll_calls =
    tonumber(panel.map_poll_calls) or 0
panel.map_poll_failures =
    tonumber(panel.map_poll_failures) or 0
panel.map_last_error =
    tostring(panel.map_last_error or "")
panel.map_poll_status =
    tostring(
        panel.map_poll_status
        or "MapManager has not been polled."
    )

panel.item_window_probe_type = nil
panel.item_window_probe_interval =
    math.max(
        1.00,
        tonumber(panel.item_window_probe_interval) or 1.00
    )
panel.performance_diagnostics_enabled =
    panel.performance_diagnostics_enabled == true
panel.item_window_probe_last_time =
    tonumber(panel.item_window_probe_last_time) or 0.0
panel.item_window_probe_calls =
    tonumber(panel.item_window_probe_calls) or 0
panel.item_window_probe_failures =
    tonumber(panel.item_window_probe_failures) or 0
panel.item_window_probe_signature =
    tostring(panel.item_window_probe_signature or "")
panel.item_window_probe_status =
    tostring(
        panel.item_window_probe_status
        or "Item Window probe has not run."
    )
panel.item_window_probe_root_state =
    panel.item_window_probe_root_state
panel.item_window_probe_state_type =
    panel.item_window_probe_state_type
panel.item_window_probe_start_type =
    panel.item_window_probe_start_type
panel.item_window_probe_step =
    panel.item_window_probe_step
panel.item_window_probe_hub_step =
    panel.item_window_probe_hub_step

panel.fade_alpha = tonumber(panel.fade_alpha) or 0.0
panel.fade_target = tonumber(panel.fade_target) or 0.0
panel.fade_in_duration = tonumber(panel.fade_in_duration) or 0.05
panel.fade_out_duration = tonumber(panel.fade_out_duration) or 0.04
panel.fade_last_time = tonumber(panel.fade_last_time) or os.clock()
panel.fade_input_active = false
panel.render_alpha = 1.0
panel.exit_requested = false
panel.exit_request_time = 0.0
panel.exit_latch_duration =
    tonumber(panel.exit_latch_duration) or 0.45
panel.exit_latch_armed =
    panel.exit_latch_armed ~= false
panel.exit_latch_generation =
    tonumber(panel.exit_latch_generation) or 0
panel.exit_hook_installed = false
panel.exit_hook_calls = 0
panel.exit_hook_status = "Exit hook not installed."
panel.last_attache_busy = panel.last_attache_busy == true
panel.items_heartbeat_until =
    tonumber(panel.items_heartbeat_until) or 0.0
panel.items_heartbeat_duration =
    tonumber(panel.items_heartbeat_duration) or 0.20
panel.items_heartbeat_calls =
    tonumber(panel.items_heartbeat_calls) or 0
panel.strong_items_heartbeat_until =
    tonumber(panel.strong_items_heartbeat_until) or 0.0
panel.strong_items_heartbeat_duration =
    math.max(0.50, tonumber(panel.strong_items_heartbeat_duration) or 0.75)
panel.strong_items_heartbeat_calls =
    tonumber(panel.strong_items_heartbeat_calls) or 0
panel.strong_items_heartbeat_source =
    tostring(panel.strong_items_heartbeat_source or "none")
panel.strong_items_confirmed =
    panel.strong_items_confirmed == true

panel.last_target_item_type =
    tostring(
        panel.last_target_item_type
        or "none"
    )

panel.last_selection_inventory_type =
    panel.last_selection_inventory_type

panel.last_selection_previous =
    panel.last_selection_previous

panel.last_selection_current =
    panel.last_selection_current

panel.target_item_probe_calls =
    tonumber(
        panel.target_item_probe_calls
    ) or 0

panel.selection_probe_calls =
    tonumber(
        panel.selection_probe_calls
    ) or 0

panel.case_method_probe_counts =
    type(panel.case_method_probe_counts) == "table"
    and panel.case_method_probe_counts
    or {}

panel.case_method_probe_last =
    tostring(
        panel.case_method_probe_last
        or "none"
    )

panel.case_method_probe_total =
    tonumber(
        panel.case_method_probe_total
    ) or 0

panel.case_method_probe_installed =
    tonumber(
        panel.case_method_probe_installed
    ) or 0

panel.charms_active =
    panel.charms_active == true

panel.charms_blocker_until =
    tonumber(
        panel.charms_blocker_until
    ) or 0.0

panel.charms_blocker_duration =
    math.max(
        0.20,
        tonumber(
            panel.charms_blocker_duration
        ) or 0.35
    )

panel.charms_heartbeat_calls =
    tonumber(
        panel.charms_heartbeat_calls
    ) or 0

panel.charms_hook_installed =
    panel.charms_hook_installed == true

panel.itembox_method_probe_counts =
    type(panel.itembox_method_probe_counts) == "table"
    and panel.itembox_method_probe_counts
    or {}

panel.itembox_method_probe_total =
    tonumber(
        panel.itembox_method_probe_total
    ) or 0

panel.itembox_method_probe_last =
    tostring(
        panel.itembox_method_probe_last
        or "none"
    )

panel.itembox_method_probe_installed =
    tonumber(
        panel.itembox_method_probe_installed
    ) or 0

panel.itembox_ambient_open_calls =
    tonumber(
        panel.itembox_ambient_open_calls
    ) or 0
panel.items_session_active =
    panel.items_session_active == true
panel.items_session_generation =
    tonumber(panel.items_session_generation) or 0
panel.items_last_confirmed_time =
    tonumber(panel.items_last_confirmed_time) or 0.0
panel.items_step_grace_duration =
    tonumber(panel.items_step_grace_duration) or 0.35
panel.items_last_live_step =
    tonumber(panel.items_last_live_step)
panel.visibility_diagnostics =
    type(panel.visibility_diagnostics) == "table"
    and panel.visibility_diagnostics
    or {}
panel.visibility_diagnostic_limit =
    tonumber(panel.visibility_diagnostic_limit) or 20
panel.visibility_last_signature =
    tostring(panel.visibility_last_signature or "")
panel.visibility_last_record_time =
    tonumber(panel.visibility_last_record_time) or 0.0
panel.items_session_source =
    tostring(panel.items_session_source or "none")
panel.save_menu_active =
    panel.save_menu_active == true
panel.save_menu_blocker_until =
    tonumber(panel.save_menu_blocker_until) or 0.0
panel.save_menu_blocker_duration =
    tonumber(
        panel.save_menu_blocker_duration
    ) or 0.0

panel.save_menu_session_latched =
    panel.save_menu_session_latched == true

panel.typewriter_menu_active =
    panel.typewriter_menu_active == true

panel.typewriter_menu_open_calls =
    tonumber(
        panel.typewriter_menu_open_calls
    ) or 0

panel.typewriter_menu_close_calls =
    tonumber(
        panel.typewriter_menu_close_calls
    ) or 0

panel.typewriter_hook_status =
    tostring(
        panel.typewriter_hook_status
        or "Typewriter behavior hook not installed."
    )

panel.typewriter_legacy_hook_status =
    tostring(
        panel.typewriter_legacy_hook_status
        or "Legacy parent-menu resolver not installed."
    )

panel.typewriter_select_hook_installed =
    panel.typewriter_select_hook_installed == true
panel.typewriter_select_open_calls =
    tonumber(panel.typewriter_select_open_calls) or 0
panel.typewriter_select_close_calls =
    tonumber(panel.typewriter_select_close_calls) or 0
panel.typewriter_select_last_method =
    tostring(panel.typewriter_select_last_method or "none")
panel.typewriter_select_step =
    panel.typewriter_select_step

panel.storage_gui_hook_installed =
    panel.storage_gui_hook_installed == true
panel.storage_gui_open_calls =
    tonumber(panel.storage_gui_open_calls) or 0
panel.storage_gui_close_calls =
    tonumber(panel.storage_gui_close_calls) or 0
panel.storage_gui_last_method =
    tostring(panel.storage_gui_last_method or "none")

panel.typewriter_direct_hook_installed =
    panel.typewriter_direct_hook_installed == true

panel.typewriter_direct_calls =
    tonumber(
        panel.typewriter_direct_calls
    ) or 0

panel.typewriter_direct_last_method =
    tostring(
        panel.typewriter_direct_last_method
        or "none"
    )

panel.typewriter_gmflag_hook_installed =
    panel.typewriter_gmflag_hook_installed == true
panel.typewriter_gmflag_calls =
    tonumber(panel.typewriter_gmflag_calls) or 0
panel.typewriter_gmflag_last_value =
    panel.typewriter_gmflag_last_value
panel.typewriter_gmflag_last_method =
    tostring(panel.typewriter_gmflag_last_method or "none")
panel.typewriter_gmflag_last_runtime_type =
    tostring(panel.typewriter_gmflag_last_runtime_type or "none")

panel.typewriter_bt_hook_installed =
    panel.typewriter_bt_hook_installed == true

panel.typewriter_bt_start_calls =
    tonumber(
        panel.typewriter_bt_start_calls
    ) or 0

panel.typewriter_bt_end_calls =
    tonumber(
        panel.typewriter_bt_end_calls
    ) or 0

panel.typewriter_bt_last_method =
    tostring(
        panel.typewriter_bt_last_method
        or "none"
    )

panel.typewriter_transition_pending =
    panel.typewriter_transition_pending == true

panel.typewriter_transition_resolution =
    tostring(
        panel.typewriter_transition_resolution
        or "none"
    )

panel.armoury_state_probe_installed =
    tonumber(
        panel.armoury_state_probe_installed
    ) or 0

panel.armoury_state_probe_calls =
    tonumber(
        panel.armoury_state_probe_calls
    ) or 0

panel.armoury_state_last_method =
    tostring(
        panel.armoury_state_last_method
        or "none"
    )

panel.armoury_state_runtime_type =
    tostring(
        panel.armoury_state_runtime_type
        or "none"
    )

panel.armoury_state_next_raw =
    panel.armoury_state_next_raw

panel.armoury_hub_step_raw =
    panel.armoury_hub_step_raw

panel.armoury_hub_probe_calls =
    tonumber(
        panel.armoury_hub_probe_calls
    ) or 0

panel.armoury_hub_children =
    type(panel.armoury_hub_children) == "table"
    and panel.armoury_hub_children
    or {}

panel.armoury_hub_active_child =
    tostring(
        panel.armoury_hub_active_child
        or "none"
    )

panel.armoury_screen_class =
    tostring(
        panel.armoury_screen_class
        or "unknown"
    )

panel.armoury_screen_source =
    tostring(
        panel.armoury_screen_source
        or "none"
    )

panel.armoury_state_blocker_calls =
    tonumber(
        panel.armoury_state_blocker_calls
    ) or 0
panel.storage_active =
    panel.storage_active == true

panel.itembox_session_active =
    panel.itembox_session_active == true

panel.itembox_session_open_calls =
    tonumber(
        panel.itembox_session_open_calls
    ) or 0

panel.itembox_session_close_calls =
    tonumber(
        panel.itembox_session_close_calls
    ) or 0

panel.itembox_hook_status =
    tostring(
        panel.itembox_hook_status
        or "GmItemBox session hooks not installed."
    )

panel.itembox_last_open_method =
    tostring(
        panel.itembox_last_open_method
        or "none"
    )

panel.itembox_last_close_method =
    tostring(
        panel.itembox_last_close_method
        or "none"
    )

panel.itembox_open_hook_count =
    tonumber(
        panel.itembox_open_hook_count
    ) or 0

panel.itembox_close_hook_count =
    tonumber(
        panel.itembox_close_hook_count
    ) or 0

panel.itembox_context_hook_installed =
    panel.itembox_context_hook_installed == true
panel.itembox_recv_param_hook_installed =
    panel.itembox_recv_param_hook_installed == true
panel.itembox_last_context_raw =
    panel.itembox_last_context_raw
panel.itembox_last_context_text =
    tostring(panel.itembox_last_context_text or "none")
panel.itembox_last_param_type =
    panel.itembox_last_param_type
panel.itembox_last_param_arg =
    panel.itembox_last_param_arg
panel.itembox_context_calls =
    tonumber(panel.itembox_context_calls) or 0
panel.itembox_recv_param_calls =
    tonumber(panel.itembox_recv_param_calls) or 0

panel.itembox_last_user_object_type =
    tostring(
        panel.itembox_last_user_object_type
        or "none"
    )

panel.itembox_last_user_context_id =
    panel.itembox_last_user_context_id

panel.itembox_last_user_context_type =
    tostring(
        panel.itembox_last_user_context_type
        or "none"
    )

panel.itembox_user_object_probe_calls =
    tonumber(
        panel.itembox_user_object_probe_calls
    ) or 0
panel.storage_blocker_until =
    tonumber(panel.storage_blocker_until) or 0.0
panel.storage_blocker_duration =
    tonumber(panel.storage_blocker_duration) or 0.15
panel.save_menu_open_calls =
    tonumber(panel.save_menu_open_calls) or 0
panel.save_menu_close_calls =
    tonumber(panel.save_menu_close_calls) or 0
panel.storage_open_calls =
    tonumber(panel.storage_open_calls) or 0
panel.storage_close_calls =
    tonumber(panel.storage_close_calls) or 0
panel.blocker_status =
    tostring(panel.blocker_status or "No blockers active.")
panel.save_menu_latch_remaining = 0.0
panel.active_inventory_read_status =
    tostring(
        panel.active_inventory_read_status
        or "Not read yet."
    )
panel.case_step_read_status =
    tostring(
        panel.case_step_read_status
        or "Not read yet."
    )

-- Never preserve an open/visible inventory lifecycle across script reloads.
-- The concrete attaché-case hooks or controller recovery below must prove the
-- inventory is currently active before the progression panel can draw.
panel.force_visible = false
panel.open = false
panel.items_screen_visible = false
panel.active_until = 0.0
panel.case_behavior = nil
panel.current_inventory_value = "unknown"
panel.items_inventory_value = nil
panel.bounds = nil
panel.hover_attribute = "none"
panel.native_click_pending = false
panel.fade_alpha = 0.0
panel.fade_target = 0.0
panel.fade_last_time = os.clock()
panel.fade_input_active = false
panel.render_alpha = 1.0
panel.exit_requested = false
panel.exit_request_time = 0.0
panel.exit_latch_armed = true
panel.exit_latch_generation = 0
panel.exit_hook_calls = 0
panel.exit_hook_status = "Waiting for requestExitAttacheCaseLight hook."
panel.last_attache_busy = false
panel.items_heartbeat_until = 0.0
panel.items_heartbeat_calls = 0
panel.strong_items_heartbeat_until = 0.0
panel.strong_items_heartbeat_calls = 0
panel.strong_items_heartbeat_source = "none"
panel.strong_items_confirmed = false
panel.items_session_active = false
panel.items_session_generation = 0
panel.items_last_confirmed_time = 0.0
panel.items_last_live_step = nil
panel.save_menu_active = false
panel.save_menu_session_latched = false
panel.save_menu_blocker_until = 0.0
panel.typewriter_menu_active = false
panel.typewriter_direct_calls = 0
panel.typewriter_direct_last_method = "none"
panel.typewriter_gmflag_calls = 0
panel.typewriter_gmflag_last_value = nil
panel.typewriter_gmflag_last_method = "none"
panel.typewriter_gmflag_last_runtime_type = "none"
panel.typewriter_bt_start_calls = 0
panel.typewriter_bt_end_calls = 0
panel.typewriter_bt_last_method = "none"
panel.typewriter_transition_pending = false
panel.typewriter_transition_resolution = "none"
panel.armoury_state_probe_calls = 0
panel.armoury_state_last_method = "none"
panel.armoury_state_runtime_type = "none"
panel.armoury_state_next_raw = nil
panel.armoury_hub_step_raw = nil
panel.armoury_hub_probe_calls = 0
panel.armoury_hub_children = {}
panel.armoury_hub_active_child = "none"
panel.armoury_screen_class = "unknown"
panel.armoury_screen_source = "none"
panel.armoury_state_blocker_calls = 0
panel.storage_active = false
panel.itembox_session_active = false
panel.storage_active = false
panel.storage_session_latched =
    panel.storage_session_latched == true
panel.storage_blocker_until = 0.0
panel.blocker_status = "No blockers active."
panel.case_method_probe_counts = {}
panel.case_method_probe_last = "none"
panel.case_method_probe_total = 0
panel.case_method_probe_installed = 0
panel.charms_active = false
panel.charms_blocker_until = 0.0
panel.itembox_method_probe_counts = {}
panel.itembox_method_probe_total = 0
panel.itembox_method_probe_last = "none"
panel.itembox_method_probe_installed = 0
panel.itembox_ambient_open_calls = 0

-- Script reloads preserve this module's global panel table, including the
-- previous native cursor sample and inferred client extent. Those stale
-- values can offset the painted cursor until Windows sends a focus refresh.
-- Discard only the cached input samples here; the working adaptive transform
-- remains unchanged and rebuilds itself from fresh hook values.
panel.native_mouse_x = nil
panel.native_mouse_y = nil
panel.native_mouse_down = false
panel.native_view_width = nil
panel.native_view_height = nil
panel.last_native_view_width = nil
panel.last_native_view_height = nil
panel.input_client_width = nil
panel.input_client_height = nil
panel.observed_mouse_max_x = 0.0
panel.observed_mouse_max_y = 0.0
panel.last_render_width = nil
panel.last_render_height = nil
panel.input_scale_source = "startup cursor-pair calibration"
panel.input_recalibrate_until = os.clock() + 0.35
panel.startup_calibration_frames = 30
panel.pair_candidate_width = nil
panel.pair_candidate_height = nil
panel.pair_candidate_hits = 0
panel.startup_native_generation = panel.native_sample_generation
panel.startup_imgui_x = nil
panel.startup_imgui_y = nil
panel.startup_imgui_moved = false
panel.live_imgui_mouse_x = nil
panel.live_imgui_mouse_y = nil
panel.live_imgui_mouse_time = 0.0
panel.cursor_pair_error = 0.0
panel.last_cursor_source = "none"
panel.input_reset_reason = "project_overflow.lua reload"

-- Refresh the render surface immediately instead of displaying dimensions
-- retained by the previous script instance until the first later draw pass.
if imgui ~= nil and imgui.get_display_size ~= nil then
    pcall(function()
        local size = imgui.get_display_size()
        local width = tonumber(size.x or size[1])
        local height = tonumber(size.y or size[2])

        if width ~= nil and height ~= nil and
            width > 0.0 and height > 0.0 then
            panel.screen_width = width
            panel.screen_height = height
            panel.last_render_width = width
            panel.last_render_height = height
            panel.resolution_source = "imgui.get_display_size (startup)"
        end
    end)
end

-- Migrate the earlier shipped layout defaults without overwriting a custom
-- placement. These are reference-space values and still scale uniformly.
if panel.reference_left == 70.0 and panel.reference_width_px == 639.0 then
    panel.reference_left, panel.reference_width_px = 101.0, 524.0
end

local HOOK_REVISION = 95

local function clear_pending(message)
    panel.pending = empty_pending()
    panel.pending_total = 0
    if message ~= nil then panel.input_status = message end
end

local function method_name(method)
    local ok, value = pcall(function() return method:get_name() end)
    return ok and tostring(value or "") or ""
end

local mouse_state
local inside

local function forced_imgui_mouse_state()
    if imgui == nil then
        return -1.0, -1.0, false, false
    end

    local mouse_x = -1.0
    local mouse_y = -1.0
    local mouse_down = false
    local mouse_clicked = false

    if imgui.get_mouse_pos ~= nil then
        pcall(function()
            local point =
                imgui.get_mouse_pos()

            if point ~= nil then
                mouse_x =
                    tonumber(
                        point.x or point[1]
                    ) or -1.0

                mouse_y =
                    tonumber(
                        point.y or point[2]
                    ) or -1.0
            end
        end)
    end

    if imgui.is_mouse_down ~= nil then
        pcall(function()
            mouse_down =
                imgui.is_mouse_down(0) == true
        end)
    end

    if imgui.is_mouse_clicked ~= nil then
        pcall(function()
            mouse_clicked =
                imgui.is_mouse_clicked(0) == true
        end)
    end

    return
        mouse_x,
        mouse_y,
        mouse_down,
        mouse_clicked
end

local function enum_value(value)
    local numeric = tonumber(value)
    if numeric ~= nil then return numeric end
    pcall(function() numeric = tonumber(value:get_field("value__")) end)
    return numeric
end

local function enum_argument(value)
    local numeric = enum_value(value)
    if numeric ~= nil then return numeric end
    pcall(function() numeric = tonumber(sdk.to_int64(value)) end)
    if numeric == nil then
        pcall(function() numeric = tonumber(sdk.to_int32(value)) end)
    end
    return numeric
end

local function reset_input_calibration(reason)
    panel.input_client_width = nil
    panel.input_client_height = nil
    panel.observed_mouse_max_x = 0.0
    panel.observed_mouse_max_y = 0.0
    panel.input_scale_source = "cursor-pair recalibration"
    panel.input_recalibrate_until = os.clock() + 0.35
    panel.startup_calibration_frames = 30
    panel.pair_candidate_width = nil
    panel.pair_candidate_height = nil
    panel.pair_candidate_hits = 0
    panel.startup_native_generation = panel.native_sample_generation
    panel.startup_imgui_x = nil
    panel.startup_imgui_y = nil
    panel.startup_imgui_moved = false
    panel.input_reset_count = (tonumber(panel.input_reset_count) or 0) + 1
    panel.input_reset_reason = tostring(reason or "display change")
end

local function observe_native_mouse(px, py, source)
    px, py = tonumber(px), tonumber(py)
    if px == nil or py == nil then return end
    panel.native_mouse_x, panel.native_mouse_y = px, py
    panel.native_sample_generation =
        (tonumber(panel.native_sample_generation) or 0) + 1
    panel.observed_mouse_max_x = math.max(panel.observed_mouse_max_x or 0.0, px)
    panel.observed_mouse_max_y = math.max(panel.observed_mouse_max_y or 0.0, py)
    if source ~= nil then panel.mouse_input_source = source end
end

-- Resolve the native coordinate domain from one fresh native/ImGui cursor
-- pair. This avoids waiting for the cursor to reach a screen edge or for a
-- focus transition before the initial mapping becomes correct.
local function calibrate_input_from_cursor_pair(
    render_width,
    render_height,
    native_x,
    native_y,
    display_x,
    display_y
)
    native_x, native_y = tonumber(native_x), tonumber(native_y)
    display_x, display_y = tonumber(display_x), tonumber(display_y)

    if native_x == nil or native_y == nil or
        display_x == nil or display_y == nil then
        return false
    end

    if native_x < 4.0 or native_y < 4.0 then
        return false
    end

    local candidates = {
        { render_width, render_height },
        { 1280.0, 720.0 },
        { 1600.0, 900.0 },
        { 1920.0, 1080.0 },
        { 2560.0, 1440.0 },
        { 3440.0, 1440.0 },
        { 3840.0, 2160.0 }
    }

    local best_width, best_height, best_error = nil, nil, math.huge

    for _, size in ipairs(candidates) do
        local width, height = size[1], size[2]
        if width > 0.0 and height > 0.0 then
            local mapped_x = native_x * (render_width / width)
            local mapped_y = native_y * (render_height / height)
            local dx = mapped_x - display_x
            local dy = mapped_y - display_y
            local error = math.sqrt(dx * dx + dy * dy)

            if error < best_error then
                best_width, best_height, best_error = width, height, error
            end
        end
    end

    local tolerance = math.max(18.0, math.min(render_width, render_height) * 0.018)
    if best_width == nil or best_error > tolerance then
        panel.pair_candidate_hits = 0
        return false
    end

    if panel.pair_candidate_width == best_width and
        panel.pair_candidate_height == best_height then
        panel.pair_candidate_hits = (tonumber(panel.pair_candidate_hits) or 0) + 1
    else
        panel.pair_candidate_width = best_width
        panel.pair_candidate_height = best_height
        panel.pair_candidate_hits = 1
    end

    if panel.pair_candidate_hits < 3 then
        panel.input_scale_source = string.format(
            "cursor-pair candidate %.0fx%.0f (%d/3)",
            best_width,
            best_height,
            panel.pair_candidate_hits
        )
        return false
    end

    panel.input_client_width = best_width
    panel.input_client_height = best_height
    panel.input_scale_source = string.format(
        "cursor-pair calibrated %.0fx%.0f",
        best_width,
        best_height
    )
    panel.startup_calibration_frames = 0
    panel.input_recalibrate_until = 0.0
    return true
end

-- The windowed game's cursor uses its client/back-buffer coordinates even
-- when REFramework draws at the configured output resolution. Learn that
-- client extent conservatively from a cursor reaching a standard edge.
local function input_client_size(render_width, render_height, current_x, current_y)
    local max_x = math.max(tonumber(panel.observed_mouse_max_x) or 0.0,
        tonumber(current_x) or 0.0)
    local max_y = math.max(tonumber(panel.observed_mouse_max_y) or 0.0,
        tonumber(current_y) or 0.0)

    -- RE4 windowed mode can expose a DPI-logical 1920x1080 pointer while the
    -- game and REFramework draw at 2560x1440. Detect that coordinate domain
    -- directly from either the current point or the observed extrema.
    if render_width >= 2500.0 and render_height >= 1400.0 and
        max_x <= 1935.0 and max_y <= 1095.0 and
        (max_x >= 1750.0 or max_y >= 980.0) then
        panel.input_client_width, panel.input_client_height = 1920.0, 1080.0
        panel.input_scale_source = "1920x1080 DPI-logical cursor"
        return 1920.0, 1080.0
    end

    local candidates = {
        { 1280.0, 720.0 }, { 1600.0, 900.0 }, { 1920.0, 1080.0 },
        { 2560.0, 1440.0 }, { 3440.0, 1440.0 }, { 3840.0, 2160.0 }
    }
    for _, size in ipairs(candidates) do
        if max_x >= size[1] * 0.94 and max_x <= size[1] * 1.03 and
            max_y >= size[2] * 0.94 and max_y <= size[2] * 1.03 then
            panel.input_client_width, panel.input_client_height = size[1], size[2]
            panel.input_scale_source = "observed native cursor extent"
            return size[1], size[2]
        end
    end

    local width, height = tonumber(panel.input_client_width),
        tonumber(panel.input_client_height)
    if width ~= nil and height ~= nil and width > 0 and height > 0 then
        panel.input_scale_source = "remembered native cursor extent"
        return width, height
    end

    -- A native main-view size that differs from the draw surface is useful as
    -- a fallback, but an equal 2560x1440 view does not disprove DPI-logical
    -- pointer coordinates and therefore must not override the test above.
    width, height = tonumber(panel.native_view_width), tonumber(panel.native_view_height)
    if width ~= nil and height ~= nil and width > 0 and height > 0 and
        (math.abs(width - render_width) > 2 or math.abs(height - render_height) > 2) then
        panel.input_scale_source = "native main-view size"
        return width, height
    end

    panel.input_client_width, panel.input_client_height = render_width, render_height
    panel.input_scale_source = "render-space fallback"
    return render_width, render_height
end

local function active_inventory_value(object)
    if object == nil then
        panel.active_inventory_read_status =
            "No captured CaseCustomMenuGuiBehavior."

        return nil
    end

    local value = nil
    local getter_ok = false
    local field_ok = false

    getter_ok =
        pcall(function()
            value =
                object:call(
                    "get_CurrActiveInventory()"
                )
        end)

    if value == nil then
        getter_ok =
            pcall(function()
                value =
                    object:call(
                        "get_CurrActiveInventory"
                    )
            end)
    end

    if value == nil then
        field_ok =
            pcall(function()
                value =
                    object:get_field(
                        "<CurrActiveInventory>k__BackingField"
                    )
            end)
    end

    local numeric =
        enum_value(value)

    if numeric ~= nil then
        panel.active_inventory_read_status =
            getter_ok
            and "Read from get_CurrActiveInventory."
            or (
                field_ok
                and "Read from CurrActiveInventory backing field."
                or "Converted active inventory value."
            )
    else
        panel.active_inventory_read_status =
            string.format(
                "Unavailable (getter=%s, field=%s, raw=%s).",
                tostring(getter_ok),
                tostring(field_ok),
                tostring(value)
            )
    end

    return numeric
end

local function current_case_step(object)
    if object == nil then
        panel.case_step_read_status =
            "No captured CaseCustomMenuGuiBehavior."

        return nil
    end

    local value = nil
    local getter_ok = false
    local field_ok = false

    getter_ok =
        pcall(function()
            value =
                object:call(
                    "get_CurrStep()"
                )
        end)

    if value == nil then
        getter_ok =
            pcall(function()
                value =
                    object:call(
                        "get_CurrStep"
                    )
            end)
    end

    if value == nil then
        field_ok =
            pcall(function()
                value =
                    object:get_field(
                        "<CurrStep>k__BackingField"
                    )
            end)
    end

    local numeric =
        enum_value(value)

    if numeric ~= nil then
        panel.case_step_read_status =
            getter_ok
            and "Read from get_CurrStep."
            or (
                field_ok
                and "Read from CurrStep backing field."
                or "Converted case-step value."
            )
    else
        panel.case_step_read_status =
            string.format(
                "Unavailable (getter=%s, field=%s, raw=%s).",
                tostring(getter_ok),
                tostring(field_ok),
                tostring(value)
            )
    end

    return numeric
end

local function record_visibility_diagnostic(
    source,
    busy,
    step,
    active_inventory
)
    local signature =
        table.concat(
            {
                tostring(source or "unknown"),
                tostring(busy),
                tostring(step),
                tostring(active_inventory),
                tostring(panel.items_screen_visible),
                tostring(panel.open)
            },
            "|"
        )

    local now = os.clock()

    if
        signature == panel.visibility_last_signature
        and now - panel.visibility_last_record_time < 0.25
    then
        return
    end

    panel.visibility_last_signature =
        signature
    panel.visibility_last_record_time =
        now

    local history =
        panel.visibility_diagnostics or {}

    history[#history + 1] =
        string.format(
            "t=%.3f src=%s busy=%s step=%s active=%s learned=%s visible=%s open=%s heartbeat=%.3f",
            now,
            tostring(source or "unknown"),
            tostring(busy),
            tostring(step),
            tostring(active_inventory),
            tostring(panel.items_inventory_value),
            tostring(panel.items_screen_visible),
            tostring(panel.open),
            math.max(
                0.0,
                (tonumber(panel.items_heartbeat_until) or 0.0)
                - now
            )
        )

    local limit =
        math.max(
            5,
            math.floor(
                tonumber(panel.visibility_diagnostic_limit) or 20
            )
        )

    while #history > limit do
        table.remove(history, 1)
    end

    panel.visibility_diagnostics =
        history
end

-- Hooks can miss an already-open case when Project: Overflow is reloaded.
-- Recover its live behavior at a low frequency instead of polling every frame.
local function discover_case_behavior()
    local now = os.clock()
    if panel.case_behavior ~= nil and current_case_step(panel.case_behavior) == 2 then
        return panel.case_behavior
    end
    if now - panel.last_controller_probe < 0.20 then return panel.case_behavior end
    panel.last_controller_probe = now
    local definition = sdk.find_type_definition(
        "chainsaw.gui.CaseCustomMenuGuiBehavior")
    if definition == nil or sdk.get_managed_objects == nil then
        panel.controller_probe_status = "Managed-object scan unavailable"
        return nil
    end
    local objects = nil
    local ok = pcall(function() objects = sdk.get_managed_objects(definition) end)
    if not ok or objects == nil then
        panel.controller_probe_status = "Managed-object scan failed"
        return nil
    end
    for _, object in ipairs(objects) do
        if current_case_step(object) == 2 then -- CaseCustomMenu Step.Move
            panel.case_behavior = object
            panel.controller_probe_status = "Recovered active Items controller"
            return object
        end
    end
    panel.controller_probe_status = "No active case controller"
    panel.case_behavior = nil
    return nil
end

local function get_attache_case_manager()
    if panel.attache_manager ~= nil then
        return panel.attache_manager
    end

    local manager = nil
    local ok,
          error_message =
        pcall(function()
            manager =
                sdk.get_managed_singleton(
                    "chainsaw.AttacheCaseManager"
                )
        end)

    if not ok then
        panel.attache_manager_failures =
            panel.attache_manager_failures + 1

        panel.attache_manager_last_error =
            tostring(error_message)

        panel.attache_manager_status =
            "AttacheCaseManager singleton lookup failed."

        return nil
    end

    if manager == nil then
        panel.attache_manager_status =
            "AttacheCaseManager singleton unavailable."

        return nil
    end

    panel.attache_manager =
        manager

    panel.attache_manager_status =
        "AttacheCaseManager singleton captured."

    return manager
end

local function poll_attache_case_busy()
    local manager =
        get_attache_case_manager()

    panel.attache_manager_polls =
        panel.attache_manager_polls + 1

    if manager == nil then
        panel.attache_busy = false
        return false
    end

    local ok,
          result =
        pcall(function()
            return manager:call(
                "get_IsAttacheCaseBusy()"
            )
        end)

    if not ok then
        panel.attache_manager_failures =
            panel.attache_manager_failures + 1

        panel.attache_manager_last_error =
            tostring(result)

        panel.attache_manager =
            nil

        panel.attache_busy = false

        panel.attache_manager_status =
            "Busy poll failed; reacquiring manager."

        return false
    end

    local busy =
        result == true
        or tonumber(result) == 1

    panel.attache_busy =
        busy

    panel.attache_manager_status =
        busy
        and "Attaché case is busy/open."
        or "Attaché case is closed."

    return busy
end

local function poll_map_gui_open()
    local now =
        os.clock()

    if now - panel.map_last_poll_time
        < panel.map_poll_interval
    then
        return panel.map_active == true
    end

    panel.map_last_poll_time =
        now

    panel.map_poll_calls =
        panel.map_poll_calls + 1

    if panel.map_manager == nil then
        local ok,
              manager =
            pcall(function()
                return sdk.get_managed_singleton(
                    "chainsaw.MapManager"
                )
            end)

        if not ok then
            panel.map_poll_failures =
                panel.map_poll_failures + 1

            panel.map_last_error =
                tostring(manager)

            panel.map_poll_status =
                "MapManager singleton lookup failed."

            panel.map_active = false

            return false
        end

        panel.map_manager =
            manager
    end

    if panel.map_manager == nil then
        panel.map_poll_status =
            "MapManager singleton unavailable."

        panel.map_active = false

        return false
    end

    local ok,
          result =
        pcall(function()
            return panel.map_manager:call(
                "isMapGuiOpen()"
            )
        end)

    if not ok then
        panel.map_poll_failures =
            panel.map_poll_failures + 1

        panel.map_last_error =
            tostring(result)

        panel.map_poll_status =
            "Map GUI poll failed; manager will be reacquired."

        panel.map_manager = nil
        panel.map_active = false

        return false
    end

    panel.map_active =
        result == true
        or tonumber(result) == 1

    panel.map_poll_status =
        panel.map_active
        and "MapManager reports map GUI open."
        or "MapManager reports map GUI closed."

    return panel.map_active
end

local function read_enum_property(
    object,
    getter,
    fallback_field
)
    if object == nil then
        return nil
    end

    local value = nil

    pcall(function()
        value =
            object:call(
                getter .. "()"
            )
    end)

    if value == nil then
        pcall(function()
            value =
                object:call(
                    getter
                )
        end)
    end

    if value == nil
        and fallback_field ~= nil
    then
        pcall(function()
            value =
                object:get_field(
                    fallback_field
                )
        end)
    end

    return enum_value(
        value
    )
end

local function poll_item_window_diagnostics(
    attache_busy
)
    if attache_busy ~= true then
        panel.item_window_probe_status =
            "Attaché case closed; probe idle."

        return
    end

    local now =
        os.clock()

    if now - panel.item_window_probe_last_time
        < panel.item_window_probe_interval
    then
        return
    end

    panel.item_window_probe_last_time =
        now

    panel.item_window_probe_calls =
        panel.item_window_probe_calls + 1

    if panel.item_window_probe_type == nil then
        local ok,
              definition =
            pcall(function()
                return sdk.find_type_definition(
                    "chainsaw.ItemWindowGuiControlBehavior"
                )
            end)

        if not ok then
            panel.item_window_probe_failures =
                panel.item_window_probe_failures + 1

            panel.item_window_probe_status =
                "ItemWindowGuiControlBehavior type lookup failed."

            return
        end

        panel.item_window_probe_type =
            definition
    end

    if panel.item_window_probe_type == nil then
        panel.item_window_probe_status =
            "ItemWindowGuiControlBehavior type unavailable."

        return
    end

    local ok,
          controllers =
        pcall(function()
            return sdk.get_managed_objects(
                panel.item_window_probe_type
            )
        end)

    if not ok or controllers == nil then
        panel.item_window_probe_failures =
            panel.item_window_probe_failures + 1

        panel.item_window_probe_status =
            "Item Window controller scan failed."

        return
    end

    local selected = nil

    for _, controller in ipairs(controllers) do
        local root_state =
            read_enum_property(
                controller,
                "get_CurrRootState",
                "<CurrRootState>k__BackingField"
            )

        local state_type =
            read_enum_property(
                controller,
                "get_CurrStateType",
                "<CurrStateType>k__BackingField"
            )

        local start_type =
            read_enum_property(
                controller,
                "get_CurrStartType",
                "<CurrStartType>k__BackingField"
            )

        local step =
            read_enum_property(
                controller,
                "get_CurrStep",
                "<CurrStep>k__BackingField"
            )

        local behavior_hub = nil

        pcall(function()
            behavior_hub =
                controller:call(
                    "get_BehaviorHub()"
                )
        end)

        if behavior_hub == nil then
            pcall(function()
                behavior_hub =
                    controller:get_field(
                        "<BehaviorHub>k__BackingField"
                    )
            end)
        end

        local hub_step =
            read_enum_property(
                behavior_hub,
                "get_CurrStep",
                "<CurrStep>k__BackingField"
            )

        if root_state ~= nil
            or state_type ~= nil
            or start_type ~= nil
            or step ~= nil
            or hub_step ~= nil
        then
            selected = {
                root_state = root_state,
                state_type = state_type,
                start_type = start_type,
                step = step,
                hub_step = hub_step
            }

            break
        end
    end

    if selected == nil then
        panel.item_window_probe_root_state = nil
        panel.item_window_probe_state_type = nil
        panel.item_window_probe_start_type = nil
        panel.item_window_probe_step = nil
        panel.item_window_probe_hub_step = nil
        panel.item_window_probe_status =
            "No readable Item Window controller values."

        return
    end

    panel.item_window_probe_root_state =
        selected.root_state
    panel.item_window_probe_state_type =
        selected.state_type
    panel.item_window_probe_start_type =
        selected.start_type
    panel.item_window_probe_step =
        selected.step
    panel.item_window_probe_hub_step =
        selected.hub_step

    local signature =
        table.concat(
            {
                tostring(selected.root_state),
                tostring(selected.state_type),
                tostring(selected.start_type),
                tostring(selected.step),
                tostring(selected.hub_step)
            },
            "|"
        )

    panel.item_window_probe_status =
        "root="
        .. tostring(selected.root_state)
        .. " stateType="
        .. tostring(selected.state_type)
        .. " startType="
        .. tostring(selected.start_type)
        .. " step="
        .. tostring(selected.step)
        .. " hubStep="
        .. tostring(selected.hub_step)

    if signature ~= panel.item_window_probe_signature then
        panel.item_window_probe_signature =
            signature

        pcall(function()
            log.info(
                "[Overflow][ItemWindowProbe] "
                .. panel.item_window_probe_status
            )
        end)
    end
end

local function valid_inventory_value(value)
    local numeric =
        tonumber(
            value
        )

    return
        numeric ~= nil
        and numeric >= 0
end

local function apply_attache_case_visibility()
    if panel.force_visible == true then
        panel.exit_requested = false
        panel.exit_request_time = 0.0
        panel.exit_latch_armed = true
        panel.open = true
        panel.items_session_active = true
        panel.items_session_source = "Force Visible"
        panel.items_screen_visible = true
        panel.fade_alpha = 1.0
        panel.fade_target = 1.0
        panel.fade_input_active = true
        panel.status =
            "Progression screen forced visible."

        return true
    end

    local busy =
        poll_attache_case_busy()

    local now =
        os.clock()

    local exit_deadline =
        (
            tonumber(
                panel.exit_request_time
            ) or 0.0
        )
        + math.max(
            0.10,
            tonumber(
                panel.exit_latch_duration
            ) or 0.45
        )

    if
        panel.exit_requested == true
        and now >= exit_deadline
    then
        panel.exit_requested = false
        panel.exit_request_time = 0.0
        panel.exit_latch_armed = true
        panel.last_attache_busy = false
        panel.exit_hook_status =
            "Close latch expired; ready for next inventory session."
    end

    local diagnostic_step =
        current_case_step(
            panel.case_behavior
        )

    local diagnostic_inventory =
        active_inventory_value(
            panel.case_behavior
        )

    record_visibility_diagnostic(
        "visibility_poll",
        busy,
        diagnostic_step,
        diagnostic_inventory
    )

    if busy then
        -- Save/typewriter blocking is a permanent session latch. Internal
        -- confirmation and input transitions cannot release it. Only an
        -- explicit native close/deactivate/destroy lifecycle hook clears it.
        local now =
            os.clock()

        panel.save_menu_latch_remaining =
            panel.save_menu_session_latched == true
            and -1.0
            or 0.0

        panel.save_menu_active =
            panel.save_menu_session_latched == true

        -- A verified storage lifecycle latch must outlive the short item-box
        -- heartbeat. The heartbeat can open a temporary blocker, but it may
        -- not clear ArmouryGuiBehavior/ArmouryEnter ownership while storage
        -- remains open.
        panel.storage_active =
            panel.storage_session_latched == true
            or now
                <= (
                    tonumber(
                        panel.storage_blocker_until
                    ) or 0.0
                )

        panel.charms_active =
            now
            <= (
                tonumber(
                    panel.charms_blocker_until
                ) or 0.0
            )

        poll_map_gui_open()
        -- Full managed-object enumeration is diagnostic-only. Running it
        -- repeatedly while the case is open can stack badly with trainers and
        -- item-indicator scripts that inspect the same GUI controllers.
        if panel.performance_diagnostics_enabled == true then
            poll_item_window_diagnostics(
                busy
            )
        else
            panel.item_window_probe_status =
                "Managed-object diagnostics disabled."
        end

        local verified_items_tab =
            item_window_menu_state.update(
                busy
            )

        -- The validated HighwayGuiManager Items signature is authoritative.
        -- Equipped charms can leave the CaseCustom heartbeat alive after
        -- returning to Items, so Charms may block only when Items is not the
        -- currently verified main tab.
        local charms_blocking =
            panel.charms_active == true
            and verified_items_tab ~= true

        local blocked =
            panel.save_menu_active == true
            or panel.typewriter_menu_active == true
            or panel.storage_active == true
            or charms_blocking
            or panel.map_active == true

        local live_inventory_valid =
            valid_inventory_value(
                diagnostic_inventory
            )

        local live_inventory_matches =
            live_inventory_valid
            and (
                panel.items_inventory_value == nil
                or tonumber(diagnostic_inventory)
                    == tonumber(panel.items_inventory_value)
            )

        -- Strong heartbeat experiments remain diagnostic-only. Both Charms
        -- and Items share the tested icon/control callbacks, so they cannot
        -- own visibility without a second verified discriminator.
        panel.strong_items_confirmed =
            now <= (
                tonumber(panel.strong_items_heartbeat_until) or 0.0
            )
            and live_inventory_matches

        local confirmed_items =
            not blocked
            and verified_items_tab == true

        panel.items_session_active =
            confirmed_items

        panel.items_session_source =
            confirmed_items
            and "HighwayGuiManager confirms stable Items tab"
            or (
                blocked
                and "Blocked by verified native controller"
                or item_window_menu_state.status
            )

        panel.items_screen_visible =
            confirmed_items

        if not confirmed_items then
            panel.open = false
            panel.items_session_active = false
            panel.items_screen_visible = false
            panel.bounds = nil
            panel.hover_attribute = "none"
            panel.native_click_pending = false
            panel.last_attache_busy = false
            if charms_blocking then
                panel.status =
                    "Charms screen active; progression blocked."
            elseif panel.map_active == true then
                panel.status =
                    "Map screen active; progression blocked by safe poll."
            elseif verified_items_tab ~= true then
                panel.status =
                    item_window_menu_state.status
            else
                panel.status =
                    panel.blocker_status
            end

            return false
        end

        -- A stale close request must never suppress a later valid inventory
        -- session. The request hook is only a short animation latch now.
        if panel.exit_requested ~= true then
            panel.exit_request_time = 0.0
        end

        panel.last_attache_busy = true
        panel.exit_latch_armed = true

        if panel.open ~= true then
            panel.open_calls =
                panel.open_calls + 1
        end

        panel.open = true
        panel.status =
            panel.exit_requested == true
            and "Attaché case closing early."
            or (
                confirmed_items
                and "Native inventory Items screen is active."
                or "Native inventory Items screen is opening."
            )

        return true
    end

    if panel.open == true
        or panel.items_screen_visible == true
    then
        panel.close_calls =
            panel.close_calls + 1
    end

    panel.open = false
    panel.exit_requested = false
    panel.exit_request_time = 0.0
    panel.exit_latch_armed = true

    -- Storage/typewriter blocking is heartbeat-owned and expires when its
    -- native open calls stop. Do not clear it from a transient manager-close
    -- edge during menu transitions.
    if panel.save_menu_active ~= true
        and panel.typewriter_menu_active ~= true
        and panel.storage_session_latched ~= true
        and os.clock()
            > (
                tonumber(
                    panel.storage_blocker_until
                ) or 0.0
            )
    then
        panel.storage_active = false
        panel.blocker_status =
            "No blockers active."
    end

    local typewriter_was_active =
        panel.typewriter_menu_active == true

    panel.typewriter_menu_active = false
    panel.typewriter_transition_pending = false
    panel.typewriter_transition_resolution = "manager closed"

    if typewriter_was_active then
        panel.typewriter_menu_close_calls =
            (tonumber(panel.typewriter_menu_close_calls) or 0) + 1
    end

    -- AttacheCaseManager can briefly report closed during parent-menu
    -- transitions. Only a verified storage close lifecycle may release the
    -- storage session latch.
    if panel.storage_session_latched ~= true then
        panel.storage_active = false
        panel.armoury_screen_class = "closed"
        panel.armoury_screen_source = "AttacheCaseManager closed"
    end

    panel.items_session_active = false
    panel.items_session_source = "none"
    panel.items_last_live_step = nil
    panel.items_last_confirmed_time = 0.0
    panel.items_screen_visible = false
    panel.bounds = nil
    panel.hover_attribute = "none"
    panel.last_attache_busy = false
    panel.items_heartbeat_until = 0.0

    -- Keep the exit latch set through the whole close. It is cleared only
    -- when a later false -> true busy transition proves a new inventory open.
    panel.status =
        "AttacheCaseManager reports closed."

    return false
end

local function install_attache_exit_hook()
    local definition =
        sdk.find_type_definition(
            "chainsaw.AttacheCaseManager"
        )

    if definition == nil then
        panel.exit_hook_status =
            "AttacheCaseManager type not found."

        return 0
    end

    local method = nil

    for _, method_name in ipairs({
        "requestExitAttacheCaseLight()",
        "requestExitAttacheCaseLight"
    }) do
        pcall(function()
            method =
                definition:get_method(
                    method_name
                )
        end)

        if method ~= nil then
            break
        end
    end

    if method == nil then
        panel.exit_hook_status =
            "requestExitAttacheCaseLight not found."

        return 0
    end

    local ok,
          error_message =
        pcall(function()
            sdk.hook(
                method,
                function(args)
                    panel.exit_hook_calls =
                        panel.exit_hook_calls + 1

                    if panel.exit_latch_armed == true then
                        panel.exit_latch_armed = false
                        panel.exit_latch_generation =
                            panel.exit_latch_generation + 1
                        panel.exit_requested = true
                        panel.exit_request_time = os.clock()
                        panel.exit_hook_status =
                            "Early close requested."

                        -- Stop interaction immediately, before the native busy
                        -- flag clears at the end of the closing animation.
                        panel.fade_input_active = false
                        panel.native_click_pending = false
                    else
                        panel.exit_hook_status =
                            "Repeated close request ignored."
                    end

                    return sdk.PreHookResult.CALL_ORIGINAL
                end,
                function(retval)
                    return retval
                end
            )
        end)

    if not ok then
        panel.exit_hook_status =
            "Exit hook failed: "
            .. tostring(error_message)

        return 0
    end

    panel.exit_hook_installed = true
    panel.exit_hook_status =
        "requestExitAttacheCaseLight hook installed."

    return 1
end

local LIFECYCLE = {
    -- Every icon in the visible Items grid receives this concrete update.
    -- This is the only early-opening heartbeat because generic case behavior
    -- also runs in typewriter, save, storage, and other non-Items workflows.
    { type_name = "chainsaw.gui.casecustom.CaseCustomMenuIconControl",
      opening = true, pulse = true, items_pulse = true,
      capture_behavior = false,
      methods = { "lateUpdate(System.Single deltaTime)", "lateUpdate" } },
    -- draw() is the most dependable heartbeat for the visible attaché-case
    -- Items screen. setup/lateUpdate can be inherited or skipped depending on
    -- the RE4/REFramework build, while this concrete override is rendered for
    -- every visible Items frame.
    { type_name = "chainsaw.gui.CaseCustomMenuGuiBehavior", opening = true,
      pulse = true, items_pulse = false, methods = { "draw()", "draw" } },
    -- Some RE4/REFramework builds do not dispatch the concrete draw override
    -- through hooks. Install the common active update variants as independent
    -- heartbeats; whichever one fires keeps the Items panel alive.
    { type_name = "chainsaw.gui.CaseCustomMenuGuiBehavior", opening = true,
      pulse = true, items_pulse = false, install_all = true,
      methods = { "update()", "update",
        "lateUpdate(System.Single deltaTime)",
        "lateUpdate(System.Single)", "lateUpdate()", "lateUpdate",
        "updateOnActive()", "updateOnActive",
        "render()", "render" } },
    -- Concrete Items operations are invoked even on builds where inherited
    -- lifecycle overrides never reach REFramework hooks.
    { type_name = "chainsaw.gui.CaseCustomMenuGuiBehavior", opening = true,
      pulse = true, items_pulse = false, install_all = true,
      methods = {
        "updateItemIcon(System.Boolean resetup, System.Boolean start)",
        "updateItemIcon(System.Boolean,System.Boolean)",
        "updateItemIcon",
        "updateTargetItem(chainsaw.gui.casecustom.CaseCustomSelectType type, chainsaw.gui.casecustom.CaseCustomInfoBase item)",
        "updateTargetItem(chainsaw.gui.casecustom.CaseCustomSelectType,chainsaw.gui.casecustom.CaseCustomInfoBase)",
        "updateTargetItem",
        "onSelectionChanged(chainsaw.InventoryType type, System.Int32 prev, System.Int32 curr)",
        "onSelectionChanged(chainsaw.InventoryType,System.Int32,System.Int32)",
        "onSelectionChanged"
      } },
    { type_name = "chainsaw.gui.CaseCustomMenuGuiBehavior", opening = true,
      pulse = true, methods = { "lateUpdateOnActive()", "lateUpdateOnActive" } },
    { type_name = "chainsaw.gui.CaseCustomMenuGuiBehavior", opening = true,
      pulse = true, items_pulse = true,
      methods = { "onSetup(chainsaw.GuiControllerBehavior controller)", "onSetup" } },
    { type_name = "chainsaw.gui.CaseCustomMenuGuiBehavior", opening = true,
      pulse = true, items_pulse = true,
      methods = { "setup(chainsaw.gui.CaseCustomMenuGuiBehavior.OpenParam)", "setup" } },
    { type_name = "chainsaw.gui.CaseCustomMenuGuiBehavior", opening = true,
      pulse = true, items_pulse = true,
      install_all = true,
      methods = {
        "recieveGuiParam(chainsaw.gui.CaseCustomMenuGuiBehavior.OpenParam param)",
        "recieveGuiParam(chainsaw.gui.CaseCustomMenuGuiBehavior.OpenParam)",
        "recieveGuiParam"
      } },
    { type_name = "chainsaw.gui.CaseCustomMenuGuiBehavior", opening = false,
      install_all = true, methods = { "finalize()", "finalize",
        "onDeactivateEvent()", "onDeactivateEvent",
        "onDeactiveEvent()", "onDeactiveEvent", "onDestroy()", "onDestroy" } }
}

local function is_strong_items_heartbeat(type_name, method_name_value)
    -- Hover and selection callbacks are shared with Charms. Only the concrete
    -- item-grid icon controls prove that the real Items screen is rendering.
    return
        type_name ==
            "chainsaw.gui.casecustom.CaseCustomMenuIconControl"
        and tostring(method_name_value) == "lateUpdate"
end

local function hook_lifecycle(type_name, method, opening, pulse, items_pulse,
        capture_behavior)
    local name = method_name(method)
    sdk.hook(method, function(args)
        panel.last_type, panel.last_method = type_name, name
        if opening then
            local object = nil
            pcall(function() object = sdk.to_managed_object(args[2]) end)
            if object ~= nil and capture_behavior ~= false then
                panel.case_behavior = object
            end

            if pulse then
                local active_value =
                    active_inventory_value(
                        panel.case_behavior
                    )

                panel.current_inventory_value =
                    active_value or "unknown"

                if panel.items_inventory_value == nil
                    and valid_inventory_value(
                        active_value
                    )
                then
                    panel.items_inventory_value =
                        active_value
                end

                panel.active_pulses =
                    panel.active_pulses + 1

                if items_pulse == true then
                    local now = os.clock()

                    panel.items_session_source = tostring(name)
                    panel.items_last_confirmed_time = now
                    panel.items_heartbeat_until =
                        now + math.max(
                            0.05,
                            tonumber(panel.items_heartbeat_duration) or 0.20
                        )
                    panel.items_heartbeat_calls =
                        panel.items_heartbeat_calls + 1

                    local inventory_matches =
                        valid_inventory_value(
                            active_value
                        )
                        and (
                            panel.items_inventory_value == nil
                            or tonumber(active_value)
                                == tonumber(panel.items_inventory_value)
                        )

                    if is_strong_items_heartbeat(type_name, name)
                        and inventory_matches
                    then
                        panel.strong_items_heartbeat_until =
                            now + math.max(
                                0.20,
                                tonumber(panel.strong_items_heartbeat_duration) or 0.35
                            )
                        panel.strong_items_heartbeat_calls =
                            panel.strong_items_heartbeat_calls + 1
                        panel.strong_items_heartbeat_source =
                            tostring(type_name)
                            .. "."
                            .. tostring(name)
                            .. " inventory="
                            .. tostring(active_value)
                    elseif not inventory_matches then
                        panel.strong_items_heartbeat_until = 0.0
                        panel.strong_items_confirmed = false
                    end
                end

                panel.status =
                    items_pulse
                    and (
                        "Native inventory session signal: "
                        .. tostring(name)
                    )
                    or "Attaché-case non-Items heartbeat received."
            else
                panel.status =
                    "Attaché-case setup callback received; waiting for Items heartbeat."
            end
        else
            panel.open = false
            panel.case_behavior = nil
            panel.items_inventory_value = nil
            panel.current_inventory_value = "unknown"
            panel.items_session_active = false
            panel.items_session_source = "none"
            panel.items_last_live_step = nil
            panel.items_last_confirmed_time = 0.0
            panel.items_screen_visible = false
            panel.items_heartbeat_until = 0.0
            panel.strong_items_heartbeat_until = 0.0
            panel.strong_items_confirmed = false
            panel.strong_items_heartbeat_source = "none"
            panel.close_calls = panel.close_calls + 1
            clear_pending("Pending attribute changes discarded.")
            panel.status = "Attaché case inventory closed."
        end
    end, function(retval) return retval end)
end

local function install_blocker_heartbeat(
    type_name,
    methods,
    blocker_name
)
    local definition =
        sdk.find_type_definition(
            type_name
        )

    if definition == nil then
        return 0
    end

    local installed = 0
    local installed_keys = {}

    for _, candidate in ipairs(methods) do
        local method = nil

        pcall(function()
            method =
                definition:get_method(
                    candidate
                )
        end)

        if method ~= nil then
            local key =
                type_name
                .. "|"
                .. method_name(method)

            if installed_keys[key] ~= true then
                local ok =
                    pcall(function()
                        sdk.hook(
                            method,
                            function(args)
                                local now =
                                    os.clock()

                                if blocker_name == "save" then
                                    local was_latched =
                                        panel.save_menu_session_latched == true

                                    panel.save_menu_session_latched = true
                                    panel.save_menu_active = true
                                    panel.save_menu_blocker_until = math.huge
                                    panel.save_menu_latch_remaining = -1.0

                                    if not was_latched then
                                        panel.save_menu_open_calls =
                                            panel.save_menu_open_calls + 1
                                    end

                                    panel.blocker_status =
                                        "Native save/typewriter session permanently blocked until close."
                                else
                                    panel.storage_blocker_until =
                                        now
                                        + math.max(
                                            0.05,
                                            tonumber(
                                                panel.storage_blocker_duration
                                            ) or 0.20
                                        )

                                    panel.storage_active = true
                                    panel.storage_open_calls =
                                        panel.storage_open_calls + 1
                                    panel.blocker_status =
                                        "Native storage-screen heartbeat active."
                                end

                                panel.open = false
                                panel.items_session_active = false
                                panel.items_screen_visible = false
                                panel.bounds = nil
                                panel.hover_attribute = "none"
                                panel.native_click_pending = false
                                panel.fade_target = 0.0

                                return sdk.PreHookResult.CALL_ORIGINAL
                            end,
                            function(retval)
                                return retval
                            end
                        )
                    end)

                if ok then
                    installed =
                        installed + 1

                    installed_keys[key] =
                        true
                end
            end
        end
    end

    return installed
end

local function find_method_by_names(
    definition,
    exact_candidates,
    fallback_names
)
    if definition == nil then
        return nil
    end

    for _, candidate in ipairs(exact_candidates or {}) do
        local method = nil

        pcall(function()
            method =
                definition:get_method(
                    candidate
                )
        end)

        if method ~= nil then
            return method
        end
    end

    local methods = nil

    pcall(function()
        methods =
            definition:get_methods()
    end)

    for _, method in ipairs(methods or {}) do
        local name = nil

        pcall(function()
            name =
                method:get_name()
        end)

        for _, fallback in ipairs(fallback_names or {}) do
            if name == fallback then
                return method
            end
        end
    end

    return nil
end

local function raw_context_id(value)
    local numeric =
        enum_argument(
            value
        )

    if numeric ~= nil then
        return numeric
    end

    pcall(function()
        numeric =
            tonumber(
                sdk.to_int32(
                    value
                )
            )
    end)

    return numeric
end

local function managed_type_name(value)
    local object = nil
    local result = "none"

    pcall(function()
        object =
            sdk.to_managed_object(
                value
            )
    end)

    if object ~= nil then
        pcall(function()
            result =
                tostring(
                    object:get_type_definition():get_full_name()
                )
        end)
    end

    return result
end

local function install_itembox_method_probe()
    local definition =
        sdk.find_type_definition(
            "chainsaw.GmItemBox"
        )

    if definition == nil then
        return 0
    end

    local watched = {
        openItemBox = true,
        onOpenItemBox = true,
        onOpenItemBoxSub = true,
        onCloseItemBox = true,
        onCloseItemBoxSub = true,
        recvGmParam = true
    }

    local methods = nil
    local installed = 0
    local installed_keys = {}

    pcall(function()
        methods =
            definition:get_methods()
    end)

    local function hook_probe(method)
        if method == nil then
            return
        end

        local name =
            method_name(
                method
            )

        if watched[name] ~= true then
            return
        end

        local key =
            tostring(method)

        if installed_keys[key] == true then
            return
        end

        local ok =
            pcall(function()
                sdk.hook(
                    method,
                    function(_args)
                        if name == "openItemBox" then
                            -- Runtime testing proved this is a continuous
                            -- gameplay-side call that pauses while menus are
                            -- open. Keep it separate from menu lifecycle data.
                            panel.itembox_ambient_open_calls =
                                panel.itembox_ambient_open_calls + 1
                        else
                            panel.itembox_method_probe_total =
                                panel.itembox_method_probe_total + 1

                            panel.itembox_method_probe_counts[name] =
                                (
                                    tonumber(
                                        panel.itembox_method_probe_counts[name]
                                    ) or 0
                                ) + 1

                            panel.itembox_method_probe_last =
                                tostring(name)
                        end

                        return sdk.PreHookResult.CALL_ORIGINAL
                    end,
                    function(retval)
                        return retval
                    end
                )
            end)

        if ok then
            installed_keys[key] = true
            installed = installed + 1
        end
    end

    for _, method in ipairs(methods or {}) do
        hook_probe(
            method
        )
    end

    panel.itembox_method_probe_installed =
        installed

    return installed
end

-- Forward declaration: several early native hooks must suppress the overlay
-- before the helper implementation appears later in this module.
local suppress_progression_immediately

local function install_charms_blocker_hook()
    local definition =
        sdk.find_type_definition(
            "chainsaw.gui.CaseCustomMenuGuiBehavior"
        )

    if definition == nil then
        return 0
    end

    local method = nil

    for _, candidate in ipairs({
        "lateUpdateOnActive()",
        "lateUpdateOnActive"
    }) do
        pcall(function()
            method =
                definition:get_method(
                    candidate
                )
        end)

        if method ~= nil then
            break
        end
    end

    if method == nil then
        return 0
    end

    local ok =
        pcall(function()
            sdk.hook(
                method,
                function(_args)
                    local now =
                        os.clock()

                    panel.charms_blocker_until =
                        now
                        + math.max(
                            0.20,
                            tonumber(
                                panel.charms_blocker_duration
                            ) or 0.35
                        )

                    panel.charms_active = true
                    panel.charms_heartbeat_calls =
                        panel.charms_heartbeat_calls + 1

                    suppress_progression_immediately()

                    return sdk.PreHookResult.CALL_ORIGINAL
                end,
                function(retval)
                    return retval
                end
            )
        end)

    if not ok then
        return 0
    end

    panel.charms_hook_installed = true

    return 1
end

local function install_case_method_probe()
    local type_name =
        "chainsaw.gui.CaseCustomMenuGuiBehavior"

    local definition =
        sdk.find_type_definition(
            type_name
        )

    if definition == nil then
        return 0
    end

    local watched = {
        draw = true,
        update = true,
        lateUpdate = true,
        updateOnActive = true,
        lateUpdateOnActive = true,
        render = true,
        updateItemIcon = true,
        updateTargetItem = true,
        onSelectionChanged = true,
        changeStep = true
    }

    local methods = nil
    local installed = 0
    local installed_keys = {}

    pcall(function()
        methods =
            definition:get_methods()
    end)

    local function hook_probe(method)
        if method == nil then
            return
        end

        local name =
            method_name(
                method
            )

        if watched[name] ~= true then
            return
        end

        local key =
            tostring(method)

        if installed_keys[key] == true then
            return
        end

        local ok =
            pcall(function()
                sdk.hook(
                    method,
                    function(_args)
                        panel.case_method_probe_total =
                            panel.case_method_probe_total + 1

                        panel.case_method_probe_counts[name] =
                            (tonumber(
                                panel.case_method_probe_counts[name]
                            ) or 0) + 1

                        panel.case_method_probe_last =
                            tostring(name)

                        return sdk.PreHookResult.CALL_ORIGINAL
                    end,
                    function(retval)
                        return retval
                    end
                )
            end)

        if ok then
            installed_keys[key] = true
            installed = installed + 1
        end
    end

    for _, method in ipairs(methods or {}) do
        hook_probe(
            method
        )
    end

    panel.case_method_probe_installed =
        installed

    return installed
end

local function install_case_screen_probes()
    local definition =
        sdk.find_type_definition(
            "chainsaw.gui.CaseCustomMenuGuiBehavior"
        )

    if definition == nil then
        return 0
    end

    local installed = 0

    local target_method = nil

    for _, candidate in ipairs({
        "updateTargetItem(chainsaw.gui.casecustom.CaseCustomSelectType type, chainsaw.gui.casecustom.CaseCustomInfoBase item)",
        "updateTargetItem(chainsaw.gui.casecustom.CaseCustomSelectType,chainsaw.gui.casecustom.CaseCustomInfoBase)",
        "updateTargetItem"
    }) do
        pcall(function()
            target_method =
                definition:get_method(
                    candidate
                )
        end)

        if target_method ~= nil then
            break
        end
    end

    if target_method ~= nil then
        local ok =
            pcall(function()
                sdk.hook(
                    target_method,
                    function(args)
                        panel.target_item_probe_calls =
                            panel.target_item_probe_calls + 1

                        panel.last_target_item_type =
                            managed_type_name(
                                args[4]
                            )

                        return sdk.PreHookResult.CALL_ORIGINAL
                    end,
                    function(retval)
                        return retval
                    end
                )
            end)

        if ok then
            installed =
                installed + 1
        end
    end

    local selection_method = nil

    for _, candidate in ipairs({
        "onSelectionChanged(chainsaw.InventoryType type, System.Int32 prev, System.Int32 curr)",
        "onSelectionChanged(chainsaw.InventoryType,System.Int32,System.Int32)",
        "onSelectionChanged"
    }) do
        pcall(function()
            selection_method =
                definition:get_method(
                    candidate
                )
        end)

        if selection_method ~= nil then
            break
        end
    end

    if selection_method ~= nil then
        local ok =
            pcall(function()
                sdk.hook(
                    selection_method,
                    function(args)
                        panel.selection_probe_calls =
                            panel.selection_probe_calls + 1

                        panel.last_selection_inventory_type =
                            enum_argument(
                                args[3]
                            )

                        pcall(function()
                            panel.last_selection_previous =
                                tonumber(
                                    sdk.to_int32(
                                        args[4]
                                    )
                                )
                        end)

                        pcall(function()
                            panel.last_selection_current =
                                tonumber(
                                    sdk.to_int32(
                                        args[5]
                                    )
                                )
                        end)

                        return sdk.PreHookResult.CALL_ORIGINAL
                    end,
                    function(retval)
                        return retval
                    end
                )
            end)

        if ok then
            installed =
                installed + 1
        end
    end

    return installed
end

local function install_items_icon_grid_hooks()
    local type_name =
        "chainsaw.gui.casecustom.CaseCustomMenuIconControl"

    local definition =
        sdk.find_type_definition(
            type_name
        )

    if definition == nil then
        panel.strong_items_heartbeat_source =
            "CaseCustomMenuIconControl type not found"

        return 0
    end

    local installed = 0
    local installed_methods = {}
    local methods = nil

    pcall(function()
        methods =
            definition:get_methods()
    end)

    local function hook_icon_method(method)
        if method == nil then
            return
        end

        local name =
            method_name(
                method
            )

        if name ~= "lateUpdate" then
            return
        end

        local key =
            tostring(method)

        if installed_methods[key] == true then
            return
        end

        local ok =
            pcall(function()
                sdk.hook(
                    method,
                    function(_args)
                        local now =
                            os.clock()

                        panel.strong_items_heartbeat_until =
                            now
                            + math.max(
                                0.50,
                                tonumber(
                                    panel.strong_items_heartbeat_duration
                                ) or 0.75
                            )

                        panel.strong_items_heartbeat_calls =
                            panel.strong_items_heartbeat_calls + 1

                        panel.strong_items_heartbeat_source =
                            type_name
                            .. ".lateUpdate"

                        panel.items_last_confirmed_time =
                            now

                        return sdk.PreHookResult.CALL_ORIGINAL
                    end,
                    function(retval)
                        return retval
                    end
                )
            end)

        if ok then
            installed_methods[key] = true
            installed = installed + 1
        end
    end

    for _, method in ipairs(methods or {}) do
        hook_icon_method(
            method
        )
    end

    for _, candidate in ipairs({
        "lateUpdate(System.Single deltaTime)",
        "lateUpdate(System.Single)",
        "lateUpdate()",
        "lateUpdate"
    }) do
        local method = nil

        pcall(function()
            method =
                definition:get_method(
                    candidate
                )
        end)

        hook_icon_method(
            method
        )
    end

    return installed
end

local function object_type_name(object)
    if object == nil then
        return "none"
    end

    local result =
        "unknown"

    pcall(function()
        result =
            tostring(
                object:get_type_definition():get_full_name()
            )
    end)

    return result
end

local function component_from_game_object(game_object, type_name)
    if game_object == nil then
        return nil
    end

    local component = nil

    pcall(function()
        component =
            game_object:call(
                "getComponent(System.Type)",
                sdk.typeof(
                    type_name
                )
            )
    end)

    return component
end

local function capture_itembox_user_object(value)
    local game_object = nil

    pcall(function()
        game_object =
            sdk.to_managed_object(
                value
            )
    end)

    if game_object == nil then
        return
    end

    panel.itembox_user_object_probe_calls =
        panel.itembox_user_object_probe_calls + 1

    panel.itembox_last_user_object_type =
        object_type_name(
            game_object
        )

    local gm_base =
        component_from_game_object(
            game_object,
            "chainsaw.GmBase"
        )

    if gm_base ~= nil then
        local context_id = nil
        local context = nil

        pcall(function()
            context_id =
                gm_base:call(
                    "get_ID"
                )
        end)

        pcall(function()
            context =
                gm_base:call(
                    "get_Context"
                )
        end)

        panel.itembox_last_user_context_id =
            raw_context_id(
                context_id
            )

        panel.itembox_last_user_context_type =
            object_type_name(
                context
            )
    end
end

local function install_itembox_context_probe()
    local definition =
        sdk.find_type_definition(
            "chainsaw.GmItemBox"
        )

    if definition == nil then
        return 0
    end

    local installed = 0
    local open_context = nil

    for _, candidate in ipairs({
        "openItemBox(chainsaw.ContextID user)",
        "openItemBox(chainsaw.ContextID)",
        "openItemBox"
    }) do
        pcall(function()
            open_context =
                definition:get_method(
                    candidate
                )
        end)

        if open_context ~= nil then
            break
        end
    end

    if open_context ~= nil then
        local ok =
            pcall(function()
                sdk.hook(
                    open_context,
                    function(args)
                        local raw =
                            raw_context_id(
                                args[3]
                            )

                        panel.itembox_context_calls =
                            panel.itembox_context_calls + 1
                        panel.itembox_last_context_raw = raw
                        panel.itembox_last_context_text =
                            raw ~= nil
                            and tostring(raw)
                            or tostring(args[3] or "unknown")

                        panel.itembox_hook_status =
                            "Observed openItemBox ContextID "
                            .. tostring(panel.itembox_last_context_text)
                            .. "; diagnostic only."

                        return sdk.PreHookResult.CALL_ORIGINAL
                    end,
                    function(retval)
                        return retval
                    end
                )
            end)

        if ok then
            panel.itembox_context_hook_installed = true
            installed = installed + 1
        end
    end

    local recv_param = nil

    for _, candidate in ipairs({
        "recvGmParam(System.Int32 param_type, System.Int32 arg, via.GameObject user)",
        "recvGmParam(System.Int32,System.Int32,via.GameObject)",
        "recvGmParam"
    }) do
        pcall(function()
            recv_param =
                definition:get_method(
                    candidate
                )
        end)

        if recv_param ~= nil then
            break
        end
    end

    if recv_param ~= nil then
        local ok =
            pcall(function()
                sdk.hook(
                    recv_param,
                    function(args)
                        local param_type = nil
                        local param_arg = nil

                        pcall(function()
                            param_type =
                                tonumber(
                                    sdk.to_int32(
                                        args[3]
                                    )
                                )
                        end)

                        pcall(function()
                            param_arg =
                                tonumber(
                                    sdk.to_int32(
                                        args[4]
                                    )
                                )
                        end)

                        panel.itembox_recv_param_calls =
                            panel.itembox_recv_param_calls + 1
                        panel.itembox_last_param_type = param_type
                        panel.itembox_last_param_arg = param_arg

                        return sdk.PreHookResult.CALL_ORIGINAL
                    end,
                    function(retval)
                        return retval
                    end
                )
            end)

        if ok then
            panel.itembox_recv_param_hook_installed = true
            installed = installed + 1
        end
    end

    return installed
end

local function install_itembox_session_hooks()
    local definition =
        sdk.find_type_definition(
            "chainsaw.GmItemBox"
        )

    if definition == nil then
        panel.itembox_hook_status =
            "chainsaw.GmItemBox type not found."

        return 0
    end

    local open_names = {
        onOpenItemBox = true,
        onOpenItemBoxSub = true,
        openItemBox = true
    }

    local close_names = {
        onCloseItemBox = true,
        onCloseItemBoxSub = true,
        closeItemBox = true
    }

    local installed = 0
    local installed_methods = {}
    local open_hook_count = 0
    local close_hook_count = 0

    local methods = nil

    pcall(function()
        methods =
            definition:get_methods()
    end)

    local function hook_method(method, opening)
        if method == nil then
            return
        end

        local name =
            method_name(
                method
            )

        local key =
            tostring(name)
            .. "|"
            .. tostring(opening)

        if installed_methods[key] == true then
            return
        end

        local ok =
            pcall(function()
                sdk.hook(
                    method,
                    function(_args)
                        -- GmItemBox is shared by the normal attaché-case Items
                        -- screen, typewriter, and storage. Record lifecycle
                        -- telemetry only; never suppress progression here.
                        if opening then
                            panel.itembox_session_active = true
                            panel.itembox_last_open_method =
                                tostring(name)
                            panel.itembox_session_open_calls =
                                panel.itembox_session_open_calls + 1

                            -- onOpenItemBox/onOpenItemBoxSub receive the
                            -- workflow GameObject as their first parameter.
                            capture_itembox_user_object(
                                _args[3]
                            )
                        else
                            panel.itembox_session_active = false
                            panel.itembox_last_close_method =
                                tostring(name)
                            panel.itembox_session_close_calls =
                                panel.itembox_session_close_calls + 1
                        end

                        panel.itembox_hook_status =
                            "Diagnostic-only GmItemBox event: "
                            .. tostring(name)
                            .. " ("
                            .. (
                                opening
                                and "open"
                                or "close"
                            )
                            .. ")."

                        return sdk.PreHookResult.CALL_ORIGINAL
                    end,
                    function(retval)
                        return retval
                    end
                )
            end)

        if ok then
            installed_methods[key] = true
            installed = installed + 1

            if opening then
                open_hook_count =
                    open_hook_count + 1
            else
                close_hook_count =
                    close_hook_count + 1
            end
        end
    end

    for _, method in ipairs(methods or {}) do
        local name =
            method_name(
                method
            )

        if open_names[name] == true then
            hook_method(
                method,
                true
            )
        elseif close_names[name] == true then
            hook_method(
                method,
                false
            )
        end
    end

    panel.itembox_open_hook_count =
        open_hook_count

    panel.itembox_close_hook_count =
        close_hook_count

    panel.itembox_hook_status =
        "Diagnostic-only GmItemBox hooks: open="
        .. tostring(open_hook_count)
        .. ", close="
        .. tostring(close_hook_count)
        .. ", total="
        .. tostring(installed)
        .. "."

    return installed
end

local function boolean_argument(value)
    local result = nil
    pcall(function()
        result = sdk.to_int32(value) ~= 0
    end)
    return result
end

suppress_progression_immediately = function()
    panel.open = false
    panel.items_session_active = false
    panel.items_screen_visible = false
    panel.bounds = nil
    panel.hover_attribute = "none"
    panel.native_click_pending = false
    panel.fade_target = 0.0
    panel.fade_alpha = 0.0
end

local function classify_armoury_state(
    runtime_type,
    source
)
    local name =
        tostring(
            runtime_type
            or ""
        )

    local method =
        tostring(
            source
            or ""
        )

    -- Typewriter ownership is handled by the verified player behavior-tree
    -- onStart/onEnd lifecycle. ArmouryGuiState_Close remains diagnostic-only.

    -- Verified runtime entry signal for storage.
    if name ==
        "chainsaw.gui.armoury.ArmouryGuiState_ArmouryEnter"
    then
        return "storage", "ArmouryEnter"
    end

    -- Existing Save Game blocker remains authoritative.
    if name:find(
        "ArmouryGuiState_SaveLoad",
        1,
        true
    ) then
        return "save", "SaveLoad"
    end

    -- Returning to the normal attaché-case branch clears the parent blockers.
    if name:find(
        "ArmouryGuiState_AttacheCase",
        1,
        true
    ) then
        return "inventory", "AttacheCase"
    end

    -- Charms/customization remains owned by the verified Charms heartbeat.
    if name:find(
        "ArmouryGuiState_CaseCustom",
        1,
        true
    ) then
        return "case_custom", "CaseCustom"
    end

    return nil, "unclassified"
end

local function apply_armoury_screen_state(
    runtime_type,
    source
)
    local screen_class, matched =
        classify_armoury_state(
            runtime_type,
            source
        )

    if screen_class == nil then
        return
    end

    panel.armoury_screen_class =
        screen_class

    panel.armoury_screen_source =
        tostring(source)
        .. ":"
        .. tostring(matched)

    panel.armoury_state_blocker_calls =
        panel.armoury_state_blocker_calls + 1

    if screen_class == "storage" then
        local was_storage_active =
            panel.storage_active == true

        panel.storage_active = true
        panel.storage_session_latched = true
        panel.typewriter_menu_active = false

        if not was_storage_active then
            panel.storage_open_calls =
                (tonumber(panel.storage_open_calls) or 0) + 1
        end

        panel.blocker_status =
            "Verified ArmouryEnter storage state active."
    elseif screen_class == "typewriter" then
        local was_typewriter_active =
            panel.typewriter_menu_active == true

        panel.storage_active = false
        panel.typewriter_menu_active = true

        if not was_typewriter_active then
            panel.typewriter_menu_open_calls =
                (tonumber(panel.typewriter_menu_open_calls) or 0) + 1
        end

        panel.blocker_status =
            "Verified ArmouryGuiState_Close.onInit typewriter entry active."
    elseif screen_class == "save" then
        -- Preserve the parent typewriter latch while Save Game is open.
        panel.storage_active = false
        -- SaveLoadMenuGuiBehavior remains the authoritative Save Game blocker.
    elseif screen_class == "inventory" then
        panel.storage_active = false
        panel.storage_session_latched = false
        panel.storage_blocker_until = 0.0
        panel.typewriter_menu_active = false

        if panel.save_menu_active ~= true
            and panel.charms_active ~= true
        then
            panel.blocker_status =
                "No blockers active."
        end
    elseif screen_class == "case_custom" then
        panel.storage_active = false
        panel.storage_session_latched = false
        panel.storage_blocker_until = 0.0
        panel.typewriter_menu_active = false

        if panel.save_menu_active ~= true
            and panel.charms_active ~= true
        then
            panel.blocker_status =
                "No blockers active."
        end
    end

    if screen_class == "storage"
        or screen_class == "typewriter"
    then
        suppress_progression_immediately()
    end
end

local function install_armoury_state_probe()
    local installed = 0
    local installed_keys = {}

    local function hook_method(
        definition,
        method,
        label,
        read_next
    )
        if definition == nil or method == nil then
            return
        end

        local key =
            tostring(method)
            .. "|"
            .. tostring(label)

        if installed_keys[key] == true then
            return
        end

        local ok =
            pcall(function()
                sdk.hook(
                    method,
                    function(args)
                        local object = nil

                        pcall(function()
                            object =
                                sdk.to_managed_object(
                                    args[2]
                                )
                        end)

                        panel.armoury_state_probe_calls =
                            panel.armoury_state_probe_calls + 1

                        panel.armoury_state_last_method =
                            tostring(label)

                        panel.armoury_state_runtime_type =
                            object_type_name(
                                object
                            )

                        apply_armoury_screen_state(
                            panel.armoury_state_runtime_type,
                            label
                        )

                        if read_next == true then
                            panel.armoury_state_next_raw =
                                enum_argument(
                                    args[3]
                                )
                        end

                        return sdk.PreHookResult.CALL_ORIGINAL
                    end,
                    function(retval)
                        return retval
                    end
                )
            end)

        if ok then
            installed_keys[key] = true
            installed = installed + 1
        end
    end

    local state_definition =
        sdk.find_type_definition(
            "chainsaw.gui.armoury.ArmouryGuiStateBase"
        )

    if state_definition ~= nil then
        local methods = nil

        pcall(function()
            methods =
                state_definition:get_methods()
        end)

        for _, method in ipairs(methods or {}) do
            local name =
                method_name(
                    method
                )

            if name == "transit" then
                hook_method(
                    state_definition,
                    method,
                    "transit",
                    true
                )
            elseif name == "onInit"
                or name == "end"
                or name == "forceEnd"
            then
                hook_method(
                    state_definition,
                    method,
                    name,
                    false
                )
            end
        end
    end

    local hub_definition =
        sdk.find_type_definition(
            "chainsaw.gui.armoury.ArmouryGuiBehaviorHub"
        )

    if hub_definition ~= nil then
        local hub_method = nil

        for _, candidate in ipairs({
            "onUpdate()",
            "onUpdate"
        }) do
            pcall(function()
                hub_method =
                    hub_definition:get_method(
                        candidate
                    )
            end)

            if hub_method ~= nil then
                break
            end
        end

        if hub_method ~= nil then
            local ok =
                pcall(function()
                    sdk.hook(
                        hub_method,
                        function(args)
                            local object = nil

                            pcall(function()
                                object =
                                    sdk.to_managed_object(
                                        args[2]
                                    )
                            end)

                            if object ~= nil then
                                local step = nil

                                pcall(function()
                                    step =
                                        object:call(
                                            "get_CurrStep"
                                        )
                                end)

                                panel.armoury_hub_step_raw =
                                    enum_argument(
                                        step
                                    )

                                panel.armoury_hub_probe_calls =
                                    panel.armoury_hub_probe_calls + 1

                                local children = {
                                    {
                                        key = "typewriter",
                                        getter = "get_ArmourySelectGuiBehavior"
                                    },
                                    {
                                        key = "storage",
                                        getter = "get_ArmouryGuiBehavior"
                                    },
                                    {
                                        key = "save",
                                        getter = "get_SaveLoadMenuGuiBehavior"
                                    },
                                    {
                                        key = "case",
                                        getter = "get_CaseCustomMenuGuiBehavior"
                                    }
                                }

                                local active = {}

                                for _, child_info in ipairs(children) do
                                    local child = nil
                                    local valid = nil

                                    pcall(function()
                                        child =
                                            object:call(
                                                child_info.getter
                                            )
                                    end)

                                    if child ~= nil then
                                        pcall(function()
                                            valid =
                                                child:call(
                                                    "get_Valid"
                                                )
                                        end)
                                    end

                                    panel.armoury_hub_children[
                                        child_info.key
                                    ] = {
                                        exists = child ~= nil,
                                        valid = valid,
                                        type_name =
                                            object_type_name(
                                                child
                                            )
                                    }

                                    if child ~= nil
                                        and valid == true
                                    then
                                        table.insert(
                                            active,
                                            child_info.key
                                        )
                                    end
                                end

                                panel.armoury_hub_active_child =
                                    #active > 0
                                    and table.concat(active, ",")
                                    or "none"
                            end

                            return sdk.PreHookResult.CALL_ORIGINAL
                        end,
                        function(retval)
                            return retval
                        end
                    )
                end)

            if ok then
                installed = installed + 1
            end
        end
    end

    panel.armoury_state_probe_installed =
        installed

    return installed
end

local function install_typewriter_behavior_hook()
    local definition =
        sdk.find_type_definition(
            "chainsaw.PlayerBehaviorTreeAction_MFSM_SetTypeWriterNoInterpolation"
        )

    if definition == nil then
        return 0
    end

    local installed = 0
    local installed_keys = {}

    local function hook_method(method, opening)
        if method == nil then
            return
        end

        local key =
            tostring(method)
            .. "|"
            .. tostring(opening)

        if installed_keys[key] == true then
            return
        end

        local name =
            method_name(
                method
            )

        local ok =
            pcall(function()
                sdk.hook(
                    method,
                    function(_args)
                        panel.typewriter_bt_last_method =
                            tostring(name)

                        if opening then
                            panel.typewriter_bt_start_calls =
                                panel.typewriter_bt_start_calls + 1

                            -- Runtime testing shows onStart does not correspond
                            -- to a visible menu transition. Keep it as
                            -- diagnostic telemetry only.
                            panel.typewriter_transition_pending = false
                            panel.typewriter_transition_resolution =
                                "onStart diagnostic-only"
                        else
                            panel.typewriter_bt_end_calls =
                                panel.typewriter_bt_end_calls + 1

                            panel.typewriter_transition_pending = false

                            local manager_busy =
                                panel.last_attache_busy == true

                            if manager_busy then
                                local was_active =
                                    panel.typewriter_menu_active == true

                                panel.typewriter_menu_active = true

                                if not was_active then
                                    panel.typewriter_menu_open_calls =
                                        (tonumber(
                                            panel.typewriter_menu_open_calls
                                        ) or 0) + 1
                                end

                                panel.armoury_screen_class =
                                    "typewriter"

                                panel.armoury_screen_source =
                                    "PlayerBehaviorTreeAction.onEnd + manager busy"

                                panel.typewriter_transition_resolution =
                                    "opened"

                                panel.blocker_status =
                                    "Typewriter transition completed; menu is open."
                            else
                                local was_active =
                                    panel.typewriter_menu_active == true

                                panel.typewriter_menu_active = false

                                if was_active then
                                    panel.typewriter_menu_close_calls =
                                        (tonumber(
                                            panel.typewriter_menu_close_calls
                                        ) or 0) + 1
                                end

                                panel.armoury_screen_class =
                                    "closed"

                                panel.armoury_screen_source =
                                    "PlayerBehaviorTreeAction.onEnd + manager not busy"

                                panel.typewriter_transition_resolution =
                                    "closed"

                                if panel.save_menu_active ~= true
                                    and panel.storage_active ~= true
                                    and panel.charms_active ~= true
                                then
                                    panel.blocker_status =
                                        "No blockers active."
                                end
                            end
                        end

                        return sdk.PreHookResult.CALL_ORIGINAL
                    end,
                    function(retval)
                        return retval
                    end
                )
            end)

        if ok then
            installed_keys[key] = true
            installed = installed + 1
        end
    end

    local methods = nil

    pcall(function()
        methods =
            definition:get_methods()
    end)

    for _, method in ipairs(methods or {}) do
        local name =
            method_name(
                method
            )

        if name == "onStart" then
            hook_method(
                method,
                true
            )
        elseif name == "onEnd" then
            hook_method(
                method,
                false
            )
        end
    end

    for _, candidate in ipairs({
        "onStart(via.behaviortree.ActionArg arg)",
        "onStart(via.behaviortree.ActionArg)",
        "onStart"
    }) do
        local method = nil

        pcall(function()
            method =
                definition:get_method(
                    candidate
                )
        end)

        hook_method(
            method,
            true
        )
    end

    for _, candidate in ipairs({
        "onEnd(via.behaviortree.ActionArg arg)",
        "onEnd(via.behaviortree.ActionArg)",
        "onEnd"
    }) do
        local method = nil

        pcall(function()
            method =
                definition:get_method(
                    candidate
                )
        end)

        hook_method(
            method,
            false
        )
    end

    panel.typewriter_bt_hook_installed =
        installed > 0

    panel.typewriter_hook_status =
        installed > 0
        and (
            "Behavior-tree typewriter hook installed: "
            .. tostring(installed)
            .. " lifecycle hooks."
        )
        or "Behavior-tree typewriter hook failed to install."

    return installed
end

local function install_typewriter_gmflag_hook()
    local definition = sdk.find_type_definition("chainsaw.GmBase")
    if definition == nil then
        return 0
    end

    local methods = nil
    local installed = 0
    local installed_keys = {}

    pcall(function()
        methods = definition:get_methods()
    end)

    local function hook_method(method)
        if method == nil then
            return
        end

        local name = method_name(method)
        if name ~= "setGmFlag" and name ~= "onChangeGmFlag" then
            return
        end

        local key = tostring(method)
        if installed_keys[key] == true then
            return
        end

        local ok = pcall(function()
            sdk.hook(
                method,
                function(args)
                    local object = nil
                    pcall(function()
                        object = sdk.to_managed_object(args[2])
                    end)

                    if object == nil then
                        return sdk.PreHookResult.CALL_ORIGINAL
                    end

                    local runtime_type = object_type_name(object)
                    panel.typewriter_gmflag_last_runtime_type = runtime_type

                    if runtime_type ~= "chainsaw.GmTypeWriter" then
                        return sdk.PreHookResult.CALL_ORIGINAL
                    end

                    local enabled = boolean_argument(args[3])

                    panel.typewriter_gmflag_calls =
                        panel.typewriter_gmflag_calls + 1
                    panel.typewriter_gmflag_last_value = enabled
                    panel.typewriter_gmflag_last_method = tostring(name)

                    if enabled == true then
                        local was_active =
                            panel.typewriter_menu_active == true

                        panel.typewriter_menu_active = true

                        if not was_active then
                            panel.typewriter_menu_open_calls =
                                panel.typewriter_menu_open_calls + 1
                        end

                        panel.blocker_status =
                            "GmTypeWriter GmFlag enabled."

                        panel.open = false
                        panel.items_session_active = false
                        panel.items_screen_visible = false
                        panel.bounds = nil
                        panel.hover_attribute = "none"
                        panel.native_click_pending = false
                        panel.fade_target = 0.0
                    elseif enabled == false then
                        local was_active =
                            panel.typewriter_menu_active == true

                        panel.typewriter_menu_active = false

                        if was_active then
                            panel.typewriter_menu_close_calls =
                                panel.typewriter_menu_close_calls + 1
                        end

                        if panel.save_menu_active ~= true
                            and panel.storage_active ~= true
                            and panel.charms_active ~= true
                        then
                            panel.blocker_status =
                                "No blockers active."
                        end
                    end

                    return sdk.PreHookResult.CALL_ORIGINAL
                end,
                function(retval)
                    return retval
                end
            )
        end)

        if ok then
            installed_keys[key] = true
            installed = installed + 1
        end
    end

    for _, method in ipairs(methods or {}) do
        hook_method(method)
    end

    panel.typewriter_gmflag_hook_installed =
        installed > 0

    return installed
end

local function install_typewriter_direct_hook()
    local definition =
        sdk.find_type_definition(
            "chainsaw.GmTypeWriter"
        )

    if definition == nil then
        panel.typewriter_hook_status =
            "chainsaw.GmTypeWriter type not found."

        return 0
    end

    local methods = nil
    local installed = 0
    local installed_keys = {}

    pcall(function()
        methods =
            definition:get_methods()
    end)

    local function hook_method(method)
        if method == nil then
            return
        end

        local name =
            method_name(
                method
            )

        if name ~= "initInteractTrigger" then
            return
        end

        local key =
            tostring(method)

        if installed_keys[key] == true then
            return
        end

        local ok =
            pcall(function()
                sdk.hook(
                    method,
                    function(_args)
                        local was_active =
                            panel.typewriter_menu_active == true

                        panel.typewriter_menu_active = true
                        panel.typewriter_direct_calls =
                            panel.typewriter_direct_calls + 1
                        panel.typewriter_direct_last_method =
                            tostring(name)

                        if not was_active then
                            panel.typewriter_menu_open_calls =
                                panel.typewriter_menu_open_calls + 1
                        end

                        panel.blocker_status =
                            "Direct GmTypeWriter session active."

                        panel.open = false
                        panel.items_session_active = false
                        panel.items_screen_visible = false
                        panel.bounds = nil
                        panel.hover_attribute = "none"
                        panel.native_click_pending = false
                        panel.fade_target = 0.0

                        return sdk.PreHookResult.CALL_ORIGINAL
                    end,
                    function(retval)
                        return retval
                    end
                )
            end)

        if ok then
            installed_keys[key] = true
            installed = installed + 1
        end
    end

    for _, method in ipairs(methods or {}) do
        hook_method(
            method
        )
    end

    -- Exact lookup fallback.
    for _, candidate in ipairs({
        "initInteractTrigger(chainsaw.InteractTrigger trigger)",
        "initInteractTrigger(chainsaw.InteractTrigger)",
        "initInteractTrigger"
    }) do
        local method = nil

        pcall(function()
            method =
                definition:get_method(
                    candidate
                )
        end)

        hook_method(
            method
        )
    end

    panel.typewriter_direct_hook_installed =
        installed > 0

    panel.typewriter_hook_status =
        installed > 0
        and (
            "Direct GmTypeWriter hooks installed: "
            .. tostring(installed)
            .. "."
        )
        or "GmTypeWriter resolved, but initInteractTrigger hook failed."

    return installed
end

local function install_storage_gui_hooks()
    local definition =
        sdk.find_type_definition(
            "chainsaw.ArmouryGuiBehavior"
        )

    if definition == nil then
        return 0
    end

    local installed = 0
    local installed_keys = {}

    local function hook_lifecycle(method, opening)
        if method == nil then
            return
        end

        local key =
            tostring(method)
            .. "|"
            .. tostring(opening)

        if installed_keys[key] == true then
            return
        end

        local name =
            method_name(
                method
            )

        local ok =
            pcall(function()
                sdk.hook(
                    method,
                    function(_args)
                        panel.storage_gui_last_method =
                            tostring(name)

                        if opening then
                            local was_active =
                                panel.storage_active == true

                            panel.storage_gui_open_calls =
                                panel.storage_gui_open_calls + 1
                            panel.storage_active = true
                            panel.storage_session_latched = true
                            panel.typewriter_menu_active = false

                            if not was_active then
                                panel.storage_open_calls =
                                    (tonumber(panel.storage_open_calls) or 0) + 1
                            end

                            panel.armoury_screen_class =
                                "storage"
                            panel.armoury_screen_source =
                                "ArmouryGuiBehavior.onStartOpen"
                            panel.blocker_status =
                                "Storage GUI is open."

                            suppress_progression_immediately()
                        else
                            local was_active =
                                panel.storage_active == true

                            panel.storage_gui_close_calls =
                                panel.storage_gui_close_calls + 1
                            panel.storage_active = false
                            panel.storage_session_latched = false
                            panel.storage_blocker_until = 0.0

                            if was_active then
                                panel.storage_close_calls =
                                    (tonumber(panel.storage_close_calls) or 0) + 1
                            end

                            panel.armoury_screen_class =
                                "storage_closing"
                            panel.armoury_screen_source =
                                "ArmouryGuiBehavior.onStartClose"

                            -- Keep it hidden through the close transition. The
                            -- normal inventory path may restore it after the
                            -- storage GUI is actually gone.
                            suppress_progression_immediately()

                            if panel.save_menu_active ~= true
                                and panel.typewriter_menu_active ~= true
                                and panel.charms_active ~= true
                            then
                                panel.blocker_status =
                                    "Storage closing; progression held hidden."
                            end
                        end

                        return sdk.PreHookResult.CALL_ORIGINAL
                    end,
                    function(retval)
                        return retval
                    end
                )
            end)

        if ok then
            installed_keys[key] = true
            installed = installed + 1
        end
    end

    for _, candidate in ipairs({
        "onStartOpen()",
        "onStartOpen"
    }) do
        local method = nil
        pcall(function()
            method =
                definition:get_method(
                    candidate
                )
        end)
        hook_lifecycle(method, true)
    end

    for _, candidate in ipairs({
        "onStartClose()",
        "onStartClose"
    }) do
        local method = nil
        pcall(function()
            method =
                definition:get_method(
                    candidate
                )
        end)
        hook_lifecycle(method, false)
    end

    panel.storage_gui_hook_installed =
        installed > 0

    return installed
end

local function install_typewriter_select_hooks()
    local definition =
        sdk.find_type_definition(
            "chainsaw.ArmourySelectGuiBehavior"
        )

    if definition == nil then
        return 0
    end

    local installed = 0
    local installed_keys = {}

    local function hook_lifecycle(method, opening)
        if method == nil then
            return
        end

        local key =
            tostring(method)
            .. "|"
            .. tostring(opening)

        if installed_keys[key] == true then
            return
        end

        local name =
            method_name(
                method
            )

        local ok =
            pcall(function()
                sdk.hook(
                    method,
                    function(args)
                        local object = nil

                        pcall(function()
                            object =
                                sdk.to_managed_object(
                                    args[2]
                                )
                        end)

                        local step = nil

                        if object ~= nil then
                            pcall(function()
                                step =
                                    object:call(
                                        "get_CurrStep"
                                    )
                            end)
                        end

                        panel.typewriter_select_step =
                            enum_argument(
                                step
                            )

                        panel.typewriter_select_last_method =
                            tostring(name)

                        if opening then
                            local was_active =
                                panel.typewriter_menu_active == true

                            panel.typewriter_select_open_calls =
                                panel.typewriter_select_open_calls + 1
                            panel.typewriter_menu_active = true

                            if not was_active then
                                panel.typewriter_menu_open_calls =
                                    panel.typewriter_menu_open_calls + 1
                            end

                            panel.armoury_screen_class =
                                "typewriter"

                            panel.armoury_screen_source =
                                "ArmourySelectGuiBehavior.onStartOpen"

                            panel.blocker_status =
                                "Typewriter parent GUI is open."

                            suppress_progression_immediately()
                        else
                            local was_active =
                                panel.typewriter_menu_active == true

                            panel.typewriter_select_close_calls =
                                panel.typewriter_select_close_calls + 1
                            panel.typewriter_menu_active = false

                            if was_active then
                                panel.typewriter_menu_close_calls =
                                    panel.typewriter_menu_close_calls + 1
                            end

                            panel.armoury_screen_class =
                                "typewriter_closing"

                            panel.armoury_screen_source =
                                "ArmourySelectGuiBehavior.onStartClose"

                            suppress_progression_immediately()

                            if panel.save_menu_active ~= true
                                and panel.storage_active ~= true
                                and panel.charms_active ~= true
                            then
                                panel.blocker_status =
                                    "No blockers active."
                            end
                        end

                        return sdk.PreHookResult.CALL_ORIGINAL
                    end,
                    function(retval)
                        return retval
                    end
                )
            end)

        if ok then
            installed_keys[key] = true
            installed = installed + 1
        end
    end

    for _, candidate in ipairs({
        "onStartOpen()",
        "onStartOpen"
    }) do
        local method = nil
        pcall(function()
            method =
                definition:get_method(
                    candidate
                )
        end)
        hook_lifecycle(method, true)
    end

    for _, candidate in ipairs({
        "onStartClose()",
        "onStartClose"
    }) do
        local method = nil
        pcall(function()
            method =
                definition:get_method(
                    candidate
                )
        end)
        hook_lifecycle(method, false)
    end

    panel.typewriter_select_hook_installed =
        installed > 0

    if installed > 0 then
        panel.typewriter_hook_status =
            "ArmourySelectGuiBehavior lifecycle hooks installed: "
            .. tostring(installed)
            .. "."
    end

    return installed
end

local function install_typewriter_parent_hooks()
    local candidates = {
        "chainsaw.TypewriterMenuGuiBehavior",
        "chainsaw.TypeWriterMenuGuiBehavior",
        "chainsaw.TypewriterGuiBehavior",
        "chainsaw.TypeWriterGuiBehavior",
        "chainsaw.SavePointMenuGuiBehavior",
        "chainsaw.SavePointGuiBehavior"
    }

    local opening_methods = {
        "onSetup()",
        "onSetup",
        "onActivate()",
        "onActivate",
        "draw()",
        "draw",
        "open()",
        "open"
    }

    local closing_methods = {
        "onDestroy()",
        "onDestroy",
        "onDeactivateEvent()",
        "onDeactivateEvent",
        "onClose()",
        "onClose",
        "close()",
        "close"
    }

    local installed = 0
    local matched_type = nil
    local installed_keys = {}

    local function hook_methods(definition, methods, opening)
        for _, candidate in ipairs(methods) do
            local method = nil

            pcall(function()
                method =
                    definition:get_method(
                        candidate
                    )
            end)

            if method ~= nil then
                local key =
                    method_name(method)
                    .. "|"
                    .. tostring(opening)

                if installed_keys[key] ~= true then
                    local ok =
                        pcall(function()
                            sdk.hook(
                                method,
                                function(_args)
                                    if opening then
                                        local was_active =
                                            panel.typewriter_menu_active == true

                                        panel.typewriter_menu_active = true

                                        if not was_active then
                                            panel.typewriter_menu_open_calls =
                                                panel.typewriter_menu_open_calls + 1
                                        end

                                        panel.blocker_status =
                                            "Native typewriter parent menu active."

                                        panel.open = false
                                        panel.items_session_active = false
                                        panel.items_screen_visible = false
                                        panel.bounds = nil
                                        panel.hover_attribute = "none"
                                        panel.native_click_pending = false
                                        panel.fade_target = 0.0
                                    else
                                        local was_active =
                                            panel.typewriter_menu_active == true

                                        panel.typewriter_menu_active = false

                                        if was_active then
                                            panel.typewriter_menu_close_calls =
                                                panel.typewriter_menu_close_calls + 1
                                        end

                                        if panel.save_menu_active ~= true
                                            and panel.storage_active ~= true
                                        then
                                            panel.blocker_status =
                                                "No blockers active."
                                        end
                                    end

                                    return sdk.PreHookResult.CALL_ORIGINAL
                                end,
                                function(retval)
                                    return retval
                                end
                            )
                        end)

                    if ok then
                        installed = installed + 1
                        installed_keys[key] = true
                    end
                end
            end
        end
    end

    for _, type_name in ipairs(candidates) do
        local definition =
            sdk.find_type_definition(
                type_name
            )

        if definition ~= nil then
            matched_type = type_name

            hook_methods(
                definition,
                opening_methods,
                true
            )

            hook_methods(
                definition,
                closing_methods,
                false
            )
        end
    end

    if installed > 0 then
        panel.typewriter_legacy_hook_status =
            "Installed "
            .. tostring(installed)
            .. " typewriter hooks on "
            .. tostring(matched_type)
            .. "."
    else
        panel.typewriter_legacy_hook_status =
            "No known legacy parent-menu type resolved."
    end

    return installed
end

local function install_save_menu_session_hooks()
    local definition =
        sdk.find_type_definition(
            "chainsaw.SaveLoadMenuGuiBehavior"
        )

    if definition == nil then
        return 0
    end

    local installed = 0
    local installed_keys = {}

    local function hook_candidates(candidates, opening)
        for _, candidate in ipairs(candidates) do
            local method = nil

            pcall(function()
                method =
                    definition:get_method(
                        candidate
                    )
            end)

            if method ~= nil then
                local key =
                    method_name(method)
                    .. "|"
                    .. tostring(opening)

                if installed_keys[key] ~= true then
                    local ok =
                        pcall(function()
                            sdk.hook(
                                method,
                                function(_args)
                                    if opening then
                                        local was_latched =
                                            panel.save_menu_session_latched == true

                                        panel.save_menu_session_latched = true
                                        panel.save_menu_active = true
                                        panel.save_menu_blocker_until = math.huge
                                        panel.save_menu_latch_remaining = -1.0

                                        if not was_latched then
                                            panel.save_menu_open_calls =
                                                panel.save_menu_open_calls + 1
                                        end

                                        panel.blocker_status =
                                            "Save/typewriter session latched open."

                                        panel.open = false
                                        panel.items_session_active = false
                                        panel.items_screen_visible = false
                                        panel.bounds = nil
                                        panel.hover_attribute = "none"
                                        panel.native_click_pending = false
                                        panel.fade_target = 0.0
                                    else
                                        local was_latched =
                                            panel.save_menu_session_latched == true

                                        panel.save_menu_session_latched = false
                                        panel.save_menu_active = false
                                        panel.save_menu_blocker_until = 0.0
                                        panel.save_menu_latch_remaining = 0.0

                                        if was_latched then
                                            panel.save_menu_close_calls =
                                                panel.save_menu_close_calls + 1
                                        end

                                        if panel.storage_active ~= true then
                                            panel.blocker_status =
                                                "No blockers active."
                                        end
                                    end

                                    return sdk.PreHookResult.CALL_ORIGINAL
                                end,
                                function(retval)
                                    return retval
                                end
                            )
                        end)

                    if ok then
                        installed = installed + 1
                        installed_keys[key] = true
                    end
                end
            end
        end
    end

    hook_candidates(
        {
            "onSetup()",
            "onSetup",
            "onActivate()",
            "onActivate",
            "draw()",
            "draw"
        },
        true
    )

    hook_candidates(
        {
            "onDestroy()",
            "onDestroy",
            "onDeactivateEvent()",
            "onDeactivateEvent",
            "onClose()",
            "onClose",
            "close()",
            "close"
        },
        false
    )

    return installed
end

local function install_simple_blocker_hooks(
    type_name,
    open_methods,
    close_methods,
    blocker_name
)
    local definition =
        sdk.find_type_definition(
            type_name
        )

    if definition == nil then
        return 0
    end

    local installed = 0
    local installed_keys = {}

    local function install_methods(
        candidates,
        active
    )
        for _, candidate in ipairs(candidates) do
            local method = nil

            pcall(function()
                method =
                    definition:get_method(
                        candidate
                    )
            end)

            if method ~= nil then
                local key =
                    type_name
                    .. "|"
                    .. method_name(method)
                    .. "|"
                    .. tostring(active)

                if installed_keys[key] ~= true then
                    local ok =
                        pcall(function()
                            sdk.hook(
                                method,
                                function(args)
                                    local was_active =
                                        blocker_name == "save"
                                        and panel.save_menu_active == true
                                        or panel.storage_active == true

                                    if blocker_name == "save" then
                                        panel.save_menu_active =
                                            active

                                        if active and not was_active then
                                            panel.save_menu_open_calls =
                                                panel.save_menu_open_calls + 1
                                        elseif not active and was_active then
                                            panel.save_menu_close_calls =
                                                panel.save_menu_close_calls + 1
                                        end
                                    else
                                        if active then
                                            panel.storage_blocker_until =
                                                os.clock()
                                                + math.max(
                                                    0.05,
                                                    tonumber(
                                                        panel.storage_blocker_duration
                                                    ) or 0.15
                                                )

                                            if not was_active then
                                                panel.storage_open_calls =
                                                    panel.storage_open_calls + 1
                                            end

                                            panel.storage_active = true
                                        else
                                            if was_active then
                                                panel.storage_close_calls =
                                                    panel.storage_close_calls + 1
                                            end

                                            if panel.storage_session_latched ~= true then
                                                panel.storage_active = false
                                                panel.storage_blocker_until = 0.0
                                            end
                                        end
                                    end

                                    if active then
                                        panel.blocker_status =
                                            blocker_name == "save"
                                            and "Save/typewriter menu active."
                                            or "Storage/typewriter item-box heartbeat active."

                                        panel.open = false
                                        panel.items_session_active = false
                                        panel.items_screen_visible = false
                                        panel.bounds = nil
                                        panel.hover_attribute = "none"
                                        panel.native_click_pending = false
                                        panel.fade_target = 0.0
                                    elseif
                                        panel.save_menu_active ~= true
                                        and panel.storage_active ~= true
                                    then
                                        panel.blocker_status =
                                            "No blockers active."
                                    end

                                    return sdk.PreHookResult.CALL_ORIGINAL
                                end,
                                function(retval)
                                    return retval
                                end
                            )
                        end)

                    if ok then
                        installed =
                            installed + 1

                        installed_keys[key] =
                            true
                    end
                end
            end
        end
    end

    install_methods(
        open_methods,
        true
    )

    install_methods(
        close_methods,
        false
    )

    return installed
end

function panel.reset_case_method_probe()
    panel.case_method_probe_counts = {}
    panel.case_method_probe_last = "none"
    panel.case_method_probe_total = 0
end

function panel.reset_itembox_method_probe()
    panel.itembox_method_probe_counts = {}
    panel.itembox_method_probe_last = "none"
    panel.itembox_method_probe_total = 0
    panel.itembox_ambient_open_calls = 0
end

function panel.reset_armoury_state_probe()
    panel.armoury_state_probe_calls = 0
    panel.armoury_state_last_method = "none"
    panel.armoury_state_runtime_type = "none"
    panel.armoury_state_next_raw = nil
    panel.armoury_hub_step_raw = nil
    panel.armoury_hub_probe_calls = 0
end

function panel.install()
    if panel.installed and panel.hook_revision == HOOK_REVISION then return true end
    local installed, installed_keys = 0, {}

    installed =
        installed
        + install_attache_exit_hook()

    installed =
        installed
        + install_blocker_heartbeat(
            "chainsaw.SaveLoadMenuGuiBehavior",
            {
                "draw()",
                "draw"
            },
            "save"
        )

    installed =
        installed
        + install_armoury_state_probe()

    installed =
        installed
        + install_storage_gui_hooks()

    installed =
        installed
        + install_typewriter_select_hooks()

    installed =
        installed
        + install_typewriter_behavior_hook()

    installed =
        installed
        + install_typewriter_gmflag_hook()

    installed =
        installed
        + install_typewriter_direct_hook()

    installed =
        installed
        + install_typewriter_parent_hooks()

    installed =
        installed
        + install_save_menu_session_hooks()

    installed =
        installed
        + install_itembox_context_probe()

    installed =
        installed
        + install_itembox_session_hooks()

    installed =
        installed
        + install_items_icon_grid_hooks()

    installed =
        installed
        + install_case_screen_probes()

    installed =
        installed
        + install_charms_blocker_hook()

    installed =
        installed
        + install_itembox_method_probe()

    installed =
        installed
        + install_case_method_probe()

    for _, definition in ipairs(LIFECYCLE) do
        local type_definition = sdk.find_type_definition(definition.type_name)
        if type_definition ~= nil then
            for _, candidate in ipairs(definition.methods) do
                local method = nil
                pcall(function() method = type_definition:get_method(candidate) end)
                if method ~= nil then
                    local key = definition.type_name .. "|" .. method_name(method)
                    if installed_keys[key] ~= true then
                        local ok = pcall(function()
                            hook_lifecycle(definition.type_name, method,
                                definition.opening, definition.pulse,
                                definition.items_pulse,
                                definition.capture_behavior)
                        end)
                        if ok then installed, installed_keys[key] = installed + 1, true end
                    end
                    if definition.install_all ~= true then break end
                end
            end
        end
    end
    -- The progression panel is painted above the native case, so prevent a
    -- click aimed at it from also selecting an inventory cell underneath.
    local case_type = sdk.find_type_definition(
        "chainsaw.gui.CaseCustomMenuGuiBehavior")
    if case_type ~= nil then
        -- This enum transition is the authoritative attaché-case lifetime.
        -- Step.Move (2) is the interactive Items screen; Invalid (0) closes it.
        local change_step = nil
        pcall(function()
            change_step = case_type:get_method(
                "changeStep(chainsaw.gui.CaseCustomMenuGuiBehavior.Step next)") or
                case_type:get_method("changeStep")
        end)
        if change_step ~= nil then
            local ok = pcall(function()
                sdk.hook(change_step, function(args)
                    local behavior, step = nil, enum_argument(args[3])
                    pcall(function() behavior = sdk.to_managed_object(args[2]) end)
                    if behavior ~= nil then panel.case_behavior = behavior end
                    panel.last_type = "chainsaw.gui.CaseCustomMenuGuiBehavior"
                    panel.last_method = "changeStep"
                    panel.items_last_live_step =
                        step

                    panel.status =
                        "Observed native case animation step "
                        .. tostring(step)
                        .. "; visibility unchanged."

                    return sdk.PreHookResult.CALL_ORIGINAL
                end, function(retval) return retval end)
            end)
            if ok then installed = installed + 1 end
        end
        local click_method = nil
        for _, candidate in ipairs({
            "onMouseClick(via.gui.Control, via.gui.MouseEventArgs)",
            "onMouseClick(via.gui.Control,via.gui.MouseEventArgs)",
            "onMouseClick"
        }) do
            pcall(function() click_method = case_type:get_method(candidate) end)
            if click_method ~= nil then break end
        end
        if click_method ~= nil then
            local ok = pcall(function()
                sdk.hook(click_method, function(args)
                    if (panel.open or panel.force_visible) and panel.bounds ~= nil then
                        local mx, my = mouse_state()
                        local b = panel.bounds
                        if inside(mx, my, b.x, b.y, b.width, b.height) then
                            panel.blocked_native_clicks = panel.blocked_native_clicks + 1
                            -- Native case input is reliable even when ImGui's
                            -- configuration window is closed. Queue this click
                            -- for the painted controls to consume next frame.
                            panel.native_click_pending = true
                            return sdk.PreHookResult.SKIP_ORIGINAL
                        end
                    end
                    return sdk.PreHookResult.CALL_ORIGINAL
                end, function(retval) return retval end)
            end)
            if ok then installed = installed + 1 end
        end
    end
    -- Read the native inventory cursor itself. This remains valid while the
    -- game owns the mouse and ImGui's IO reports no usable coordinates.
    local cursor_type = sdk.find_type_definition("chainsaw.MouseCursorGuiBehavior")
    if cursor_type ~= nil then
        local cursor_update = nil
        for _, candidate in ipairs({ "update()", "update",
            "lateUpdateOnActive()", "lateUpdateOnActive" }) do
            pcall(function() cursor_update = cursor_type:get_method(candidate) end)
            if cursor_update ~= nil then break end
        end
        if cursor_update ~= nil then
            local ok = pcall(function()
                sdk.hook(cursor_update, function(args)
                    local cursor = nil
                    pcall(function() cursor = sdk.to_managed_object(args[2]) end)
                    if cursor ~= nil then
                        local point = nil
                        pcall(function()
                            point = cursor:call("getCurrentScreenPoint")
                        end)
                        if point ~= nil then
                            local px, py
                            pcall(function() px = tonumber(point.x or point[1]) end)
                            pcall(function() py = tonumber(point.y or point[2]) end)
                            if px ~= nil and py ~= nil then
                                observe_native_mouse(px, py,
                                    "native MouseCursorGuiBehavior")
                            end
                        end
                        local view = nil
                        pcall(function() view = cursor:call("getMainViewSize") end)
                        if view ~= nil then
                            local vw, vh
                            pcall(function()
                                vw = tonumber(view.w or view.width or view.x or view[1])
                            end)
                            pcall(function()
                                vh = tonumber(view.h or view.height or view.y or view[2])
                            end)
                            if vw ~= nil and vh ~= nil and vw > 0 and vh > 0 then
                                local previous_w = tonumber(panel.native_view_width)
                                local previous_h = tonumber(panel.native_view_height)

                                panel.native_view_width = vw
                                panel.native_view_height = vh

                                if previous_w ~= nil and previous_h ~= nil and
                                    (math.abs(previous_w - vw) > 2.0 or
                                     math.abs(previous_h - vh) > 2.0) then
                                    reset_input_calibration(
                                        string.format(
                                            "native view %.0fx%.0f -> %.0fx%.0f",
                                            previous_w, previous_h, vw, vh
                                        )
                                    )
                                end

                                panel.last_native_view_width = vw
                                panel.last_native_view_height = vh
                            end
                        end
                    end
                    return sdk.PreHookResult.CALL_ORIGINAL
                end, function(retval) return retval end)
            end)
            if ok then installed = installed + 1 end
        end
    end
    -- The game's HID state is the final authority for both position and the
    -- left-button trigger. These hooks continue to run while ImGui is behind
    -- the attaché-case GUI and therefore fix painted-control interaction.
    local mouse_state_type = sdk.find_type_definition("via.hid.MouseState")
    if mouse_state_type ~= nil then
        local point_type = sdk.find_type_definition("via.Point")
        local position_method = nil
        pcall(function()
            position_method = mouse_state_type:get_method("get_Position()") or
                mouse_state_type:get_method("get_Position")
        end)
        if position_method ~= nil then
            local ok = pcall(function()
                sdk.hook(position_method, function(args)
                    return sdk.PreHookResult.CALL_ORIGINAL
                end, function(retval)
                    local point = nil
                    pcall(function()
                        point = sdk.to_valuetype(retval, point_type)
                    end)
                    if point ~= nil then
                        local px, py
                        pcall(function() px = tonumber(point.x or point[1]) end)
                        pcall(function() py = tonumber(point.y or point[2]) end)
                        if px ~= nil and py ~= nil then
                            observe_native_mouse(px, py, "via.hid.MouseState")
                        end
                    end
                    return retval
                end)
            end)
            if ok then installed = installed + 1 end
        end
        local trigger_method = nil
        pcall(function()
            trigger_method = mouse_state_type:get_method(
                "isTrigger(via.hid.MouseButton button)") or
                mouse_state_type:get_method("isTrigger")
        end)
        if trigger_method ~= nil then
            local queried_button = -1
            local ok = pcall(function()
                sdk.hook(trigger_method, function(args)
                    queried_button = -1
                    local ok_button, native_button = pcall(sdk.to_int64, args[3])
                    if ok_button then
                        queried_button = tonumber(native_button) or -1
                    end
                    if queried_button < 0 then
                        queried_button = tonumber(args[3]) or -1
                    end
                    return sdk.PreHookResult.CALL_ORIGINAL
                end, function(retval)
                    local triggered = false
                    pcall(function() triggered = sdk.to_int64(retval) ~= 0 end)
                    -- MouseButton 0 is the primary/left button.
                    if queried_button == 0 and triggered and
                        (panel.open or panel.force_visible) then
                        panel.native_click_pending = true
                    end
                    return retval
                end)
            end)
            if ok then installed = installed + 1 end
        end
    end
    -- Capture native case cursor movement. ImGui receives the coordinates only
    -- while REFramework owns the cursor, so the game's MouseEventArgs is the
    -- authoritative source while the attaché case owns it.
    if case_type ~= nil then
        local function capture_event_position(args)
            local event = nil
            pcall(function() event = sdk.to_managed_object(args[3]) end)
            if event == nil then return end
            local position = nil
            for _, member in ipairs({ "get_Position", "get_MousePosition",
                "get_CursorPosition" }) do
                pcall(function() position = event:call(member) end)
                if position ~= nil then break end
            end
            if position == nil then
                for _, field in ipairs({ "Position", "MousePosition",
                    "CursorPosition", "_Position" }) do
                    pcall(function() position = event:get_field(field) end)
                    if position ~= nil then break end
                end
            end
            if position ~= nil then
                local px, py
                pcall(function() px = tonumber(position.x or position[1]) end)
                pcall(function() py = tonumber(position.y or position[2]) end)
                if px ~= nil and py ~= nil then
                    observe_native_mouse(px, py, "native case MouseEventArgs")
                    -- Some RE4/REFramework builds bypass the reflected
                    -- draw/changeStep wrappers. A mouse event dispatched by
                    -- this concrete attaché-case behavior is nevertheless an
                    -- authoritative Items-screen heartbeat.
                    if panel.open ~= true then panel.open_calls = panel.open_calls + 1 end
                    panel.open = true
                    panel.items_screen_visible = true
                    panel.active_until = os.clock() + 0.25
                    panel.active_pulses = panel.active_pulses + 1
                    panel.status = "Native attaché-case mouse heartbeat received."
                end
            end
        end
        for _, candidate in ipairs({
            "onMouseMove(via.gui.Control, via.gui.MouseEventArgs)",
            "onMouseMove(via.gui.Control,via.gui.MouseEventArgs)",
            "onMouseMove", "onMouseEnter(via.gui.Control, via.gui.MouseEventArgs)",
            "onMouseEnter"
        }) do
            local method = nil
            pcall(function() method = case_type:get_method(candidate) end)
            if method ~= nil then
                local ok = pcall(function()
                    sdk.hook(method, function(args)
                        capture_event_position(args)
                        return sdk.PreHookResult.CALL_ORIGINAL
                    end, function(retval) return retval end)
                end)
                if ok then installed = installed + 1 end
            end
        end
    end
    panel.installed_hooks, panel.installed = installed, installed > 0
    panel.hook_revision = panel.installed and HOOK_REVISION or panel.hook_revision
    panel.status = panel.installed
        and string.format("Installed %d attaché-case lifecycle hook(s).", installed)
        or "No attaché-case lifecycle methods resolved."
    return panel.installed
end

local function color_with_render_alpha(color)
    color =
        math.floor(
            tonumber(color) or 0
        )

    local source_alpha =
        math.floor(
            color / 0x1000000
        ) % 0x100

    local scaled_alpha =
        math.max(
            0,
            math.min(
                255,
                math.floor(
                    source_alpha
                    * math.max(
                        0.0,
                        math.min(
                            tonumber(panel.render_alpha) or 1.0,
                            1.0
                        )
                    )
                    + 0.5
                )
            )
        )

    return
        (color % 0x1000000)
        + scaled_alpha * 0x1000000
end

local function text(line, x, y, color)
    if draw == nil or draw.text == nil then return end
    color = color_with_render_alpha(color)
    local ok = pcall(function() draw.text(tostring(line), x, y, color) end)
    if not ok and Vector2f ~= nil then
        pcall(function() draw.text(tostring(line), Vector2f.new(x, y), color) end)
    end
end

local function centered_text(line, center_x, y, color, scale)
    line = tostring(line)
    local width = nil
    pcall(function()
        local size = imgui.calc_text_size(line)
        width = tonumber(size.x or size[1])
    end)
    -- REFramework builds without calc_text_size use a conservative native
    -- menu-font estimate so the block remains centered between its buttons.
    width = width or (#line * 7.2 * (scale or 1.0))
    text(line, center_x - width * 0.5, y, color)
end

local function filled_rect(x, y, width, height, color)
    if draw == nil or draw.filled_rect == nil then return end
    color = color_with_render_alpha(color)
    local ok = pcall(function() draw.filled_rect(x, y, width, height, color) end)
    if not ok and Vector2f ~= nil then
        pcall(function()
            draw.filled_rect(Vector2f.new(x, y), Vector2f.new(width, height), color)
        end)
    end
end

local function outline_rect(x, y, width, height, color)
    if draw == nil or draw.outline_rect == nil then return end
    color = color_with_render_alpha(color)
    local ok = pcall(function() draw.outline_rect(x, y, width, height, color) end)
    if not ok and Vector2f ~= nil then
        pcall(function()
            draw.outline_rect(Vector2f.new(x, y), Vector2f.new(width, height), color)
        end)
    end
end

local function line(x1, y1, x2, y2, color)
    if draw == nil or draw.line == nil then return end
    color = color_with_render_alpha(color)
    local ok = pcall(function() draw.line(x1, y1, x2, y2, color) end)
    if not ok and Vector2f ~= nil then
        pcall(function()
            draw.line(Vector2f.new(x1, y1), Vector2f.new(x2, y2), color)
        end)
    end
end

local function cursor_proxy(x, y, scale)
    local points = {
        {0, 0}, {0, 22}, {5, 17}, {10, 28},
        {14, 26}, {9, 16}, {19, 16}, {0, 0}
    }
    -- Stable low-cost proxy. This executes every render frame, so avoid the
    -- scanline polygon rasterizer that could overwhelm REFramework's draw path.
    for row = 1, 15 do
        local row_width = math.max(1.0, row * 0.72) * scale
        filled_rect(x + scale, y + row * scale, row_width,
            math.max(1.0, scale), 0xE0181818)
        filled_rect(x, y + (row - 1) * scale, row_width,
            math.max(1.0, scale), 0xFFF0F0F0)
    end
    for index = 1, #points - 1 do
        local a, b = points[index], points[index + 1]
        line(x + (a[1] + 1) * scale, y + (a[2] + 1) * scale,
            x + (b[1] + 1) * scale, y + (b[2] + 1) * scale, 0xE0000000)
    end
    for index = 1, #points - 1 do
        local a, b = points[index], points[index + 1]
        line(x + a[1] * scale, y + a[2] * scale,
            x + b[1] * scale, y + b[2] * scale, 0xFFFFFFFF)
    end
end

local function display_size()
    local attempts = {
        { name = "imgui.get_display_size", call = function()
            if imgui.get_display_size == nil then return nil end
            return imgui.get_display_size()
        end },
        { name = "imgui.get_io().display_size", call = function()
            if imgui.get_io == nil then return nil end
            local io = imgui.get_io()
            return io ~= nil and io.display_size or nil
        end }
    }
    for _, attempt in ipairs(attempts) do
        local ok, size = pcall(attempt.call)
        if ok and size ~= nil then
            local width, height
            pcall(function() width = tonumber(size.x or size[1]) end)
            pcall(function() height = tonumber(size.y or size[2]) end)
            if width ~= nil and height ~= nil and width > 0.0 and height > 0.0 then
                local previous_w = tonumber(panel.screen_width)
                local previous_h = tonumber(panel.screen_height)

                panel.screen_width, panel.screen_height = width, height
                panel.resolution_source = attempt.name

                if previous_w ~= nil and previous_h ~= nil and
                    (math.abs(previous_w - width) > 2.0 or
                     math.abs(previous_h - height) > 2.0) then
                    reset_input_calibration(
                        string.format(
                            "render surface %.0fx%.0f -> %.0fx%.0f",
                            previous_w, previous_h, width, height
                        )
                    )
                end

                panel.last_render_width = width
                panel.last_render_height = height
                return width, height
            end
        end
    end
    panel.resolution_source = "last valid/reference fallback"
    return panel.screen_width or panel.reference_width,
        panel.screen_height or panel.reference_height
end

local function geometry()
    local screen_width, screen_height = display_size()
    local scale = math.min(screen_width / panel.reference_width,
        screen_height / panel.reference_height)
    panel.uniform_scale = scale
    return { scale = scale, screen_width = screen_width,
        screen_height = screen_height, width = panel.reference_width_px * scale,
        row_height = 68.0 * scale, pad = 28.0 * scale }
end

mouse_state = function()
    local x, y, down, clicked
    local imgui_x, imgui_y
    -- REFramework exposes these direct helpers during on_frame even when its
    -- own configuration window is closed. get_io().mouse_down is unavailable
    -- in several builds, which made the painted controls non-interactive.
    local position_ok = pcall(function()
        local position = imgui.get_mouse_pos()
        imgui_x = tonumber(position.x or position[1])
        imgui_y = tonumber(position.y or position[2])
    end)

    local render_width = tonumber(panel.screen_width) or panel.reference_width
    local render_height = tonumber(panel.screen_height) or panel.reference_height

    local calibration_active =
        (tonumber(panel.startup_calibration_frames) or 0) > 0 or
        os.clock() < (tonumber(panel.input_recalibrate_until) or 0.0)

    if position_ok and imgui_x ~= nil and imgui_y ~= nil then
        local previous_x = tonumber(panel.live_imgui_mouse_x)
        local previous_y = tonumber(panel.live_imgui_mouse_y)

        if previous_x == nil
            or previous_y == nil
            or math.abs(imgui_x - previous_x) > 0.25
            or math.abs(imgui_y - previous_y) > 0.25
        then
            panel.live_imgui_mouse_time = os.clock()
        end

        panel.live_imgui_mouse_x = imgui_x
        panel.live_imgui_mouse_y = imgui_y

        if panel.startup_imgui_x == nil or panel.startup_imgui_y == nil then
            panel.startup_imgui_x = imgui_x
            panel.startup_imgui_y = imgui_y
        elseif math.abs(imgui_x - panel.startup_imgui_x) > 2.0 or
            math.abs(imgui_y - panel.startup_imgui_y) > 2.0 then
            panel.startup_imgui_moved = true
        end
    end

    local has_fresh_native_sample =
        panel.native_mouse_x ~= nil and
        panel.native_mouse_y ~= nil and
        (tonumber(panel.native_sample_generation) or 0) >
            (tonumber(panel.startup_native_generation) or 0)

    -- Cursor-pair calibration is only valid after ImGui has emitted a real
    -- post-reload movement sample. Its first value can remain stale until a
    -- screenshot/focus event, which was choosing the wrong scale at startup.
    if position_ok and panel.startup_imgui_moved == true and
        has_fresh_native_sample and
        (panel.open or panel.force_visible) then
        calibrate_input_from_cursor_pair(
            render_width,
            render_height,
            panel.native_mouse_x,
            panel.native_mouse_y,
            imgui_x,
            imgui_y
        )
    end

    -- During initialization, prefer the first fresh native game-cursor point.
    -- When the native main view matches the render surface this point is used
    -- directly; otherwise it is converted by the known view dimensions.
    if calibration_active and has_fresh_native_sample and
        (panel.open or panel.force_visible) then
        local native_x = panel.native_mouse_x
        local native_y = panel.native_mouse_y
        local view_width = tonumber(panel.native_view_width)
        local view_height = tonumber(panel.native_view_height)

        if view_width ~= nil and view_height ~= nil and
            view_width > 0.0 and view_height > 0.0 and
            (math.abs(view_width - render_width) > 2.0 or
             math.abs(view_height - render_height) > 2.0) then
            native_x = native_x * (render_width / view_width)
            native_y = native_y * (render_height / view_height)
            panel.input_scale_source = "startup native main-view transform"
        else
            panel.input_scale_source = "startup fresh native cursor"
        end

        panel.startup_calibration_frames = math.max(
            0,
            (tonumber(panel.startup_calibration_frames) or 0) - 1
        )

        x, y = native_x, native_y
        pcall(function() down = reframework:is_key_down(0x01) == true end)
        pcall(function() clicked = imgui.is_mouse_clicked(0) == true end)
        panel.mouse_supported = true
        panel.mouse_input_source = "fresh native cursor during initialization"
        return x, y, down == true, clicked == true
    end

    -- Before the first native post-reload sample exists, do not draw from the
    -- stale ImGui point. Returning an invalid position suppresses the proxy for
    -- only those first frames instead of visibly placing it in the wrong spot.
    if calibration_active and not has_fresh_native_sample then
        panel.mouse_supported = false
        panel.mouse_input_source = "waiting for fresh native cursor sample"
        return -1, -1, false, false
    end

    -- While the attaché case is active, its native cursor is authoritative.
    -- ImGui commonly retains a stale/off-screen coordinate because the game
    -- owns input at this point.
    if panel.native_mouse_x ~= nil and panel.native_mouse_y ~= nil and
        (panel.open or panel.force_visible) then
        local native_x, native_y = panel.native_mouse_x, panel.native_mouse_y
        local render_w = tonumber(panel.screen_width) or panel.reference_width
        local render_h = tonumber(panel.screen_height) or panel.reference_height
        local native_w, native_h = input_client_size(render_w, render_h, native_x, native_y)
        -- RE4 reports its menu cursor in the main-view render space (commonly
        -- 1920x1080) while draw/imgui use the output display space. Convert
        -- once here so painting and hit testing consume the identical point.
        if native_w ~= nil and native_h ~= nil and native_w > 0 and native_h > 0 then
            native_x = native_x * (render_w / native_w)
            native_y = native_y * (render_h / native_h)
        end
        local now = os.clock()

        local imgui_valid =
            position_ok
            and imgui_x ~= nil
            and imgui_y ~= nil
            and imgui_x >= -1.0
            and imgui_y >= -1.0
            and imgui_x <= render_w + 1.0
            and imgui_y <= render_h + 1.0

        local imgui_recent =
            imgui_valid
            and now - (tonumber(panel.live_imgui_mouse_time) or 0.0)
                <= math.max(
                    0.05,
                    tonumber(panel.imgui_cursor_fresh_duration) or 0.20
                )

        local delta_x = imgui_valid and (imgui_x - native_x) or 0.0
        local delta_y = imgui_valid and (imgui_y - native_y) or 0.0

        panel.cursor_pair_error =
            math.sqrt(delta_x * delta_x + delta_y * delta_y)

        local source =
            imgui_recent
            and "live ImGui window cursor + physical LMB"
            or (
                native_w ~= nil
                and "scaled native cursor + physical LMB"
                or "native cursor + physical LMB"
            )

        if source ~= panel.last_cursor_source then
            panel.cursor_source_switches =
                panel.cursor_source_switches + 1
            panel.last_cursor_source = source
        end

        if imgui_recent then
            x, y = imgui_x, imgui_y
        else
            x, y = native_x, native_y
        end

        panel.mouse_input_source = source
        pcall(function() down = reframework:is_key_down(0x01) == true end)
        pcall(function() clicked = imgui.is_mouse_clicked(0) == true end)
        panel.mouse_supported = true
        return x, y, down == true, clicked == true
    end
    if position_ok and imgui_x ~= nil and imgui_y ~= nil then
        x, y = imgui_x, imgui_y
        pcall(function() down = imgui.is_mouse_down(0) == true end)
        pcall(function() clicked = imgui.is_mouse_clicked(0) == true end)
        -- is_mouse_* can be unavailable even when get_mouse_pos succeeds.
        -- Ask REFramework for the physical left mouse button in that case.
        if down == nil and reframework ~= nil then
            pcall(function() down = reframework:is_key_down(0x01) == true end)
        end
        panel.mouse_supported = down ~= nil or clicked ~= nil
        panel.mouse_input_source = panel.mouse_supported
            and "imgui position + physical LMB" or "imgui position only"
        return x, y, down == true, clicked == true
    end
    local ok = pcall(function()
        local io = imgui.get_io()
        local position = io.mouse_pos
        x, y = tonumber(position.x or position[1]), tonumber(position.y or position[2])
        local buttons = io.mouse_down
        down = buttons ~= nil and (buttons[0] == true or buttons[1] == true)
    end)
    if (not ok or x == nil or y == nil) and panel.native_mouse_x ~= nil then
        local render_w = tonumber(panel.screen_width) or panel.reference_width
        local render_h = tonumber(panel.screen_height) or panel.reference_height
        local input_w, input_h = input_client_size(render_w, render_h, panel.native_mouse_x, panel.native_mouse_y)
        x = panel.native_mouse_x * (render_w / input_w)
        y = panel.native_mouse_y * (render_h / input_h)
    end
    if down == nil and reframework ~= nil then
        pcall(function() down = reframework:is_key_down(0x01) == true end)
    end
    panel.mouse_supported = x ~= nil and y ~= nil and down ~= nil
    panel.mouse_input_source = panel.mouse_supported and
        "native case position + physical LMB" or "unavailable"
    return x or -1, y or -1, down == true, false
end

inside = function(px, py, x, y, width, height)
    return px >= x and px <= x + width and py >= y and py <= y + height
end

-- Procedural fog made from layered, feathered ellipse slices. Each slice is
-- intersected with the supplied rectangle, providing a strict software mask.
local function masked_fog(x, y, width, height, phase, rgb, lobe_count, bands)
    if width <= 0.0 or height <= 0.0 then return end
    local right = x + width
    local alphas = { 0x08, 0x0C, 0x11, 0x17, 0x1E, 0x26 }
    lobe_count, bands = lobe_count or 8, bands or 7
    for index = 1, lobe_count do
        local radius = math.max(height * 1.6, 30.0 + (index % 4) * 14.0)
        local radius_y = math.max(height * 1.15,
            height * (1.35 + (index % 3) * 0.22))
        -- Each lobe has a slightly different velocity and a large travel
        -- domain. The combined field therefore takes many minutes to repeat
        -- instead of reading like a short tiled strip.
        local travel_x = math.max(720.0, width * 4.5 + radius * 2.0)
        local travel_y = math.max(180.0, height * 12.0 + radius_y * 2.0)
        local speed_x = 0.31 + index * 0.0137
        local speed_y = 0.17 + index * 0.0089
        local virtual_x = (phase * speed_x + index * 277.13 +
            math.sin(index * 2.17) * 47.0) % travel_x
        local virtual_y = (phase * speed_y + index * 113.71 +
            math.cos(index * 1.73) * 29.0) % travel_y
        -- Fold the larger virtual field into the visible mask. Horizontal and
        -- vertical offsets remain independent, so the fog visibly drifts down
        -- as it pans across the control.
        local center = x - radius +
            (virtual_x % math.max(1.0, width + radius * 2.0))
        local center_y = y - radius_y +
            (virtual_y % math.max(1.0, height + radius_y * 2.0))
        for layer = 1, #alphas do
            local layer_radius = radius * (1.20 - layer * 0.105)
            local layer_radius_y = radius_y * (1.20 - layer * 0.105)
            for band = 0, bands - 1 do
                local top = y + height * band / bands
                local bottom = y + height * (band + 1) / bands
                local band_center = (top + bottom) * 0.5
                local normalized_y = (band_center - center_y) /
                    math.max(1.0, layer_radius_y)
                local curve = math.sqrt(math.max(0.0,
                    1.0 - normalized_y * normalized_y))
                local half_width = layer_radius * curve
                local left = math.max(x, center - half_width)
                local clipped_right = math.min(right, center + half_width)
                if clipped_right > left then
                    local color = alphas[layer] * 0x1000000 + rgb
                    filled_rect(left, top, clipped_right - left,
                        math.max(1.0, bottom - top), color)
                end
            end
        end
    end
end

-- Only buttons receive the lifted face, glow, and moving translucent noise.
local function native_button(x, y, width, height, hovered, phase, enabled,
        gold_style)
    enabled = enabled ~= false
    local lift = enabled and hovered and 4.0 or 0.0
    local glow_alpha = enabled and hovered and (gold_style and 0x62 or 0x48) or 0x00
    if glow_alpha > 0 then
        filled_rect(x + 3.0, y + 3.0, width, height,
            glow_alpha * 0x1000000 + (gold_style and 0x5CD3FF or 0xF4F0E7))
    end
    local face_x, face_y = x - lift, y - lift
    local neutral_face = hovered and 0xE05A5B5D or 0xC348494B
    local gold_face = hovered and 0xD84A4A4A or 0xB9343537
    filled_rect(face_x, face_y, width, height,
        enabled and (gold_style and gold_face or neutral_face) or 0x9636383A)
    -- High-quality fog pans slowly behind the button's strict rectangular
    -- mask, and exists only while the enabled control is hovered.
    if hovered and enabled then
        masked_fog(face_x + 1.0, face_y + 1.0, width - 2.0, height - 2.0,
            phase, gold_style and 0x5CD3FF or 0xF4F0E7, 12, 26)
    end
    outline_rect(face_x, face_y, width, height,
        enabled and (gold_style and 0xD8D3A52C or 0xDDD7D4CE) or 0x88797874)
    outline_rect(face_x + 2.0, face_y + 2.0, width - 4.0, height - 4.0,
        enabled and (gold_style and 0x909F7E24 or 0xA0B7B2AA) or 0x6864615E)
    return face_x, face_y
end

local function button_symbol(symbol, face_x, face_y, width, height, color, scale)
    local cx, cy = face_x + width * 0.5, face_y + height * 0.5
    local arm, thickness = 8.0 * scale, math.max(2.0, 2.5 * scale)
    filled_rect(cx - arm, cy - thickness * 0.5, arm * 2.0, thickness, color)
    if symbol == "+" then
        filled_rect(cx - thickness * 0.5, cy - arm, thickness, arm * 2.0, color)
    end
end

local function glow_text(line, x, y, color, glow_color)
    text(line, x - 2.0, y, glow_color)
    text(line, x + 2.0, y, glow_color)
    text(line, x, y - 2.0, glow_color)
    text(line, x, y + 2.0, glow_color)
    text(line, x - 1.0, y - 1.0, glow_color)
    text(line, x + 1.0, y + 1.0, glow_color)
    text(line, x, y, color)
end

local function centered_glow_text(line, center_x, y, color, glow_color, scale)
    line = tostring(line)
    local width = nil
    pcall(function()
        local size = imgui.calc_text_size(line)
        width = tonumber(size.x or size[1])
    end)
    width = width or (#line * 7.2 * (scale or 1.0))
    glow_text(line, center_x - width * 0.5, y, color, glow_color)
end

local function fog_bar(x, y, width, height, phase)
    if width <= 0.0 then return end
    local mask_right = x + width
    -- A dim continuous fill keeps the progress readable beneath the fog.
    filled_rect(x, y, width, height, 0x303FA6D0)

    masked_fog(x, y, width, height, phase, 0x5CD3FF, 15, 32)

    -- Thin white leading edge, kept wholly inside the progress mask.
    local cap_width = math.min(width, 1.0)
    filled_rect(mask_right - cap_width, y, cap_width, height, 0xF0FFFFFF)
end

local function preview_profile(profile)
    local preview = { attributes = {} }
    for _, attribute in ipairs(ATTRIBUTES) do
        preview.attributes[attribute.key] =
            (tonumber(profile.attributes[attribute.key]) or 1) +
            (tonumber(panel.pending[attribute.key]) or 0)
    end
    return preview
end

local function derived_detail(attribute, derived)
    if attribute == "strength" then
        return string.format("Damage: x%.3f", derived.weapon_damage_multiplier)
    elseif attribute == "vitality" then
        return string.format("Max HP: +%d", derived.max_hp_bonus)
    elseif attribute == "dexterity" then
        return string.format("Melee Speed: x%.3f   Fire Rate: x%.3f",
            derived.action_speed_multiplier, derived.fire_rate_multiplier)
    elseif attribute == "agility" then
        local reload_duration_reduction =
            math.max(
                0.0,
                (
                    1.0
                    - (
                        1.0
                        / math.max(
                            1.0,
                            derived.reload_speed_multiplier
                        )
                    )
                ) * 100.0
            )

        return string.format("Movement Speed: x%.3f   Reload Time: -%.1f%%",
            derived.movement_speed_multiplier, reload_duration_reduction)
    elseif attribute == "intelligence" then
        return string.format("Recovery Bonus: x%.3f", derived.healing_multiplier)
    end
    return string.format("Critical Chance: +%.1f%%   Critical Damage: +%.1f%%",
        derived.critical_chance * 100.0, derived.critical_damage_bonus * 100.0)
end

local function confirm_pending(profile)
    local available = tonumber(profile.attribute_points) or 0
    if panel.pending_total <= 0 then return end
    if panel.pending_total > available then
        panel.input_status = "Not enough attribute points to confirm."
        return
    end
    for _, attribute in ipairs(ATTRIBUTES) do
        for _ = 1, panel.pending[attribute.key] do
            if not rpg.spend_attribute_point(attribute.key) then
                local failure = "Confirmation stopped: " .. tostring(rpg.last_message)
                clear_pending(failure)
                return
            end
        end
    end
    panel.spend_count = panel.spend_count + panel.pending_total
    panel.last_spent_attribute = "confirmed allocation"
    clear_pending("Attribute allocation confirmed.")
end

local previous_mouse_down = false

local function update_visibility_fade(is_open)
    local now =
        os.clock()

    local delta_time =
        math.max(
            0.0,
            math.min(
                now - (tonumber(panel.fade_last_time) or now),
                0.1
            )
        )

    panel.fade_last_time =
        now

    panel.fade_target =
        is_open and 1.0 or 0.0

    local alpha =
        math.max(
            0.0,
            math.min(
                tonumber(panel.fade_alpha) or 0.0,
                1.0
            )
        )

    if panel.fade_target > alpha then
        local duration =
            math.max(
                0.001,
                tonumber(panel.fade_in_duration) or 0.05
            )

        alpha =
            math.min(
                panel.fade_target,
                alpha + delta_time / duration
            )
    elseif panel.fade_target < alpha then
        local duration =
            math.max(
                0.001,
                tonumber(panel.fade_out_duration) or 0.04
            )

        alpha =
            math.max(
                panel.fade_target,
                alpha - delta_time / duration
            )
    end

    panel.fade_alpha =
        alpha

    panel.render_alpha =
        alpha

    -- Input stops immediately when the native attaché-case signal closes.
    panel.fade_input_active =
        is_open
        and alpha > 0.05

    return alpha > 0.001
end

function panel.draw()
    panel.install()

    local native_open =
        apply_attache_case_visibility()

    local draw_now =
        os.clock()

    if
        panel.exit_requested == true
        and draw_now >= (
            (tonumber(panel.exit_request_time) or 0.0)
            + math.max(
                0.10,
                tonumber(panel.exit_latch_duration) or 0.45
            )
        )
    then
        panel.exit_requested = false
        panel.exit_request_time = 0.0
        panel.exit_latch_armed = true
    end

    local transition_open =
        panel.force_visible == true
        or (
            native_open
            and panel.exit_requested ~= true
        )

    if not update_visibility_fade(transition_open) then
        panel.bounds = nil
        return
    end

    local profile = rpg.profile()
    local derived = stats.calculate(preview_profile(profile))
    local required = math.max(1, tonumber(rpg.required_xp()) or 1)
    local layout = geometry()
    local scale, width, pad = layout.scale, layout.width, layout.pad
    local header_height, footer_height = 178.0 * scale, 90.0 * scale
    local panel_height = header_height + #ATTRIBUTES * layout.row_height + footer_height
    -- Same uniform reference-space transform as the HP overlay. This panel is
    -- anchored from the left edge and vertical center (rather than the HUD's
    -- right/bottom anchor), preserving the selected 101/-70/524 placement.
    local x = panel.reference_left * scale
    local anchor_center_y = layout.screen_height * 0.5 +
        panel.vertical_offset * scale
    local y = math.max(24.0 * scale, anchor_center_y - panel_height * 0.5)
    panel.computed_x, panel.computed_y = x, y
    -- REFramework draw colors are ABGR, not ARGB.
    local white, gold, derived_gold = 0xFFFFFFFF, 0xFF5CD3FF, 0xFF3FA6D0
    local muted, gold_glow, derived_glow = 0xFFAAA9A5, 0x4408435D, 0x50082D3F
    -- Nearly transparent structure: the game menu remains the background.
    local panel_bg, row_bg, border = 0x0918191B, 0x07232426, 0x507B7770
    local button_text = 0xFF171719
    panel.bounds = { x = x, y = y, width = width, height = panel_height }

    filled_rect(x, y, width, panel_height, panel_bg)
    outline_rect(x, y, width, panel_height, border)
    glow_text("PROGRESSION", x + pad, y + 20.0 * scale, gold, gold_glow)
    text(string.format("LEVEL: %d", tonumber(profile.level) or 1),
        x + pad, y + 50.0 * scale, white)
    text(string.format("XP: %d / %d", tonumber(profile.experience) or 0, required),
        x + pad, y + 78.0 * scale, muted)
    local progress = math.max(0.0,
        math.min((tonumber(profile.experience) or 0) / required, 1.0))
    local bar_x, bar_y, bar_width = x + pad, y + 107.0 * scale, width - pad * 2.0
    filled_rect(bar_x, bar_y, bar_width, 8.0 * scale, 0x80454548)
    -- One material clock drives the XP bar and every hovered button.
    local fog_phase = os.clock() * 19.0
    fog_bar(bar_x, bar_y, bar_width * progress, 8.0 * scale, fog_phase)
    outline_rect(bar_x, bar_y, bar_width, 8.0 * scale, 0xB05CD3FF)
    glow_text(string.format("ATTRIBUTE POINTS: %d",
        math.max(0, (tonumber(profile.attribute_points) or 0) - panel.pending_total)),
        x + pad, y + 132.0 * scale, gold, gold_glow)

    local mouse_x,
          mouse_y,
          mouse_down,
          direct_clicked

    if panel.force_visible == true then
        mouse_x,
        mouse_y,
        mouse_down,
        direct_clicked =
            forced_imgui_mouse_state()
    else
        mouse_x,
        mouse_y,
        mouse_down,
        direct_clicked =
            mouse_state()
    end

    if
        panel.fade_input_active ~= true
        and panel.force_visible ~= true
    then
        mouse_x = -1
        mouse_y = -1
        mouse_down = false
        direct_clicked = false
        panel.native_click_pending = false
    end

    local native_clicked =
        panel.force_visible ~= true
        and panel.fade_input_active == true
        and panel.native_click_pending == true
    panel.native_click_pending = false
    local clicked = direct_clicked or native_clicked or
        (mouse_down and not previous_mouse_down)
    local phase = fog_phase
    local row_y = y + header_height
    panel.hover_attribute = "none"
    for _, attribute in ipairs(ATTRIBUTES) do
        local button_size = 38.0 * scale
        local minus_x, plus_x = x + pad, x + width - pad - button_size
        local button_y = row_y + (layout.row_height - button_size) * 0.5
        local minus_enabled = panel.pending[attribute.key] > 0
        local committed = tonumber(profile.attributes[attribute.key]) or 1
        local pending = panel.pending[attribute.key]
        local plus_enabled =
            panel.pending_total < (tonumber(profile.attribute_points) or 0) and
            committed + pending < stats.attribute_max()
        local minus_hovered = minus_enabled and
            inside(mouse_x, mouse_y, minus_x, button_y, button_size, button_size)
        local plus_hovered = plus_enabled and
            inside(mouse_x, mouse_y, plus_x, button_y, button_size, button_size)
        if minus_hovered or plus_hovered then panel.hover_attribute = attribute.key end

        filled_rect(x + 1.0 * scale, row_y, width - 2.0 * scale,
            layout.row_height - 2.0 * scale, row_bg)
        local center_x = x + width * 0.5
        local value_suffix = pending > 0 and string.format("  (+%d)", pending) or ""
        centered_text(string.format("%s: %d%s", attribute.label,
            committed + pending, value_suffix), center_x,
            row_y + 12.0 * scale, white, scale)
        centered_glow_text(derived_detail(attribute.key, derived), center_x,
            row_y + 37.0 * scale, derived_gold, derived_glow, scale)

        local minus_face_x, minus_face_y = native_button(minus_x, button_y,
            button_size, button_size, minus_hovered, phase, minus_enabled, false)
        button_symbol("-", minus_face_x, minus_face_y, button_size, button_size,
            minus_enabled and (minus_hovered and button_text or white) or 0xFF686868,
            scale)
        local plus_face_x, plus_face_y = native_button(plus_x, button_y,
            button_size, button_size, plus_hovered, phase, plus_enabled, true)
        button_symbol("+", plus_face_x, plus_face_y, button_size, button_size,
            plus_enabled and (plus_hovered and button_text or white) or 0xFF686868,
            scale)

        if clicked and minus_hovered then
            panel.pending[attribute.key] = panel.pending[attribute.key] - 1
            panel.pending_total = panel.pending_total - 1
            panel.input_status = "Removed one pending " .. attribute.label .. " point."
        elseif clicked and plus_hovered then
            panel.pending[attribute.key] = panel.pending[attribute.key] + 1
            panel.pending_total = panel.pending_total + 1
            panel.input_status = "Added one pending " .. attribute.label .. " point."
        end
        row_y = row_y + layout.row_height
    end

    local action_y, action_height = row_y + 14.0 * scale, 38.0 * scale
    local gap = 14.0 * scale
    local action_width = (width - pad * 2.0 - gap) * 0.5
    local cancel_x, confirm_x = x + pad, x + pad + action_width + gap
    local cancel_enabled = panel.pending_total > 0
    local confirm_enabled = cancel_enabled and
        panel.pending_total <= (tonumber(profile.attribute_points) or 0)
    local cancel_hovered = cancel_enabled and
        inside(mouse_x, mouse_y, cancel_x, action_y, action_width, action_height)
    local confirm_hovered = confirm_enabled and
        inside(mouse_x, mouse_y, confirm_x, action_y, action_width, action_height)
    local cancel_face_x, cancel_face_y = native_button(cancel_x, action_y,
        action_width, action_height, cancel_hovered, phase, cancel_enabled, false)
    local confirm_face_x, confirm_face_y = native_button(confirm_x, action_y,
        action_width, action_height, confirm_hovered, phase, confirm_enabled, true)
    text("CANCEL", cancel_face_x + action_width * 0.5 - 25.0 * scale,
        cancel_face_y + 8.0 * scale, cancel_enabled and white or 0xFF686868)
    text("CONFIRM", confirm_face_x + action_width * 0.5 - 29.0 * scale,
        confirm_face_y + 8.0 * scale, confirm_enabled and white or 0xFF686868)
    if clicked and cancel_hovered then
        clear_pending("Pending attribute changes cancelled.")
    elseif clicked and confirm_hovered then
        confirm_pending(profile)
    end
    panel.last_mouse_x, panel.last_mouse_y = mouse_x, mouse_y
    previous_mouse_down = mouse_down
    -- draw.* commands issued from on_present are discarded on some
    -- REFramework builds. Paint the opaque proxy last in the same overlay
    -- pass instead; the progression panel itself is already composited over
    -- the game's attaché-case cursor, so this guarantees cursor-on-top.
    if
        inside(
            mouse_x,
            mouse_y,
            x,
            y,
            width,
            panel_height
        )
        and (
            panel.force_visible == true
            or panel.fade_input_active == true
        )
    then
        cursor_proxy(
            mouse_x,
            mouse_y,
            math.max(0.8, scale)
        )
    end
end

-- Called from the presentation callback, after the game's GUI has rendered.
-- Keeping this separate from draw() ensures our high-contrast proxy sits over
-- the native attaché-case cursor instead of being covered by it.
function panel.draw_cursor()
    local b = panel.bounds
    local mx, my = panel.last_mouse_x, panel.last_mouse_y
    if
        (
            panel.force_visible == true
            or panel.items_screen_visible == true
        )
        and b ~= nil
        and mx ~= nil
        and my ~= nil
        and inside(
            mx,
            my,
            b.x,
            b.y,
            b.width,
            b.height
        )
    then
        cursor_proxy(mx, my, math.max(0.8, panel.uniform_scale or 1.0))
    end
end

-- Invoked from re.on_draw_ui, after the normal frame overlay. The proxy uses
-- the same scaled coordinate as hit testing, so it both remains visible over
-- the native attaché-case GUI and accurately communicates the click target.
function panel.is_input_layer_needed()
    return
        panel.force_visible == true
        or panel.items_screen_visible == true
        or (
            tonumber(panel.render_alpha) or 0.0
        ) > 0.001
end

function panel.draw_input_layer()
    if not panel.is_input_layer_needed() then
        return
    end

    panel.draw_cursor()
end

return panel
