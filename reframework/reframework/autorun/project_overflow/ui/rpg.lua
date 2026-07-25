------------------------------------------------------------
-- Project: Overflow — RPG progression and diagnostics
--
-- Draws progression information, runtime probes, and developer tuning tools.
-- Gameplay and persistence remain in their owning systems; this module edits
-- only the authoritative runtime values those systems expose.
------------------------------------------------------------


local rpg = require("project_overflow.systems.player.rpg")
local stat_application =
    require("project_overflow.systems.player.stat_application")
local stats =
    require("project_overflow.systems.player.stats")
local action_speed =
    require("project_overflow.systems.player.action_speed")
local critical =
    require("project_overflow.systems.player.critical")
local inventory_progression =
    require("project_overflow.ui.inventory_progression")
local game_save_sync =
    require("project_overflow.systems.player.game_save_sync")
local rpg_ui = {}

local ATTRIBUTES = {
    { key = "strength", label = "Strength" },
    { key = "vitality", label = "Vitality" },
    { key = "dexterity", label = "Dexterity" },
    { key = "agility", label = "Agility" },
    { key = "intelligence", label = "Intelligence" },
    { key = "luck", label = "Luck" }
}

local pending_attributes = {
    strength = 0,
    vitality = 0,
    dexterity = 0,
    agility = 0,
    intelligence = 0,
    luck = 0
}

local pending_attribute_total = 0

local function clear_pending_attributes()
    for _, attribute in ipairs(ATTRIBUTES) do
        pending_attributes[attribute.key] = 0
    end

    pending_attribute_total = 0
end

local function confirm_pending_attributes(profile)
    local available =
        math.max(
            0,
            tonumber(profile.attribute_points) or 0
        )

    if pending_attribute_total <= 0 then
        rpg.last_message =
            "No pending attribute distribution to confirm."

        return false
    end

    if pending_attribute_total > available then
        rpg.last_message =
            "Pending distribution exceeds available attribute points."

        return false
    end

    for _, attribute in ipairs(ATTRIBUTES) do
        local amount =
            math.max(
                0,
                math.floor(
                    tonumber(
                        pending_attributes[attribute.key]
                    ) or 0
                )
            )

        for _ = 1, amount do
            if not rpg.spend_attribute_point(attribute.key) then
                rpg.last_message =
                    "Attribute confirmation stopped: "
                    .. tostring(rpg.last_message)

                clear_pending_attributes()
                return false
            end
        end
    end

    clear_pending_attributes()
    rpg.last_message =
        "Confirmed debug attribute distribution."

    return true
end

local function value(label, content)
    imgui.text(label .. " : " .. tostring(content))
end

function rpg_ui.draw(ctx)
    if not imgui.tree_node("RPG Progression") then return end

    local profile = rpg.profile()
    local derived = rpg.derived_stats()
    local required_xp = rpg.required_xp()

    value("Level", profile.level)

    local progress_ratio =
        rpg.progress_ratio()

    local progress_percent =
        progress_ratio * 100.0

    imgui.text(
        string.format(
            "Experience: %d / %d XP (%.1f%%)",
            tonumber(profile.experience) or 0,
            tonumber(required_xp) or 0,
            progress_percent
        )
    )

    -- REFramework ImGui builds do not all expose the same progress_bar
    -- overload. Draw the label separately and keep the bar call simple.
    imgui.progress_bar(
        progress_ratio,
        260
    )

    value("Attribute Points", profile.attribute_points)
    value("Skill Points", profile.skill_points)

    if imgui.tree_node("Attributes") then
        imgui.text(
            "Debug distribution is queued until confirmed."
        )

        value(
            "Available After Pending",
            math.max(
                0,
                (tonumber(profile.attribute_points) or 0)
                - pending_attribute_total
            )
        )

        for _, attribute in ipairs(ATTRIBUTES) do
            local committed =
                tonumber(
                    profile.attributes[attribute.key]
                ) or 1

            local pending =
                tonumber(
                    pending_attributes[attribute.key]
                ) or 0

            value(
                attribute.label,
                pending > 0
                and string.format(
                    "%d (+%d pending)",
                    committed,
                    pending
                )
                or committed
            )

            imgui.same_line()

            local can_remove_pending =
                pending > 0

            if
                not can_remove_pending and
                imgui.begin_disabled ~= nil
            then
                imgui.begin_disabled()
            end

            if
                imgui.button(
                    "- Pending##rpg_pending_remove_"
                    .. attribute.key
                )
                and can_remove_pending
            then
                pending_attributes[attribute.key] =
                    pending - 1

                pending_attribute_total =
                    math.max(
                        0,
                        pending_attribute_total - 1
                    )
            end

            if
                not can_remove_pending and
                imgui.end_disabled ~= nil
            then
                imgui.end_disabled()
            end

            imgui.same_line()

            local can_add =
                pending_attribute_total
                < (
                    tonumber(
                        profile.attribute_points
                    ) or 0
                )

            if
                not can_add and
                imgui.begin_disabled ~= nil
            then
                imgui.begin_disabled()
            end

            if
                imgui.button(
                    "+ Pending##rpg_pending_add_"
                    .. attribute.key
                )
                and can_add
            then
                pending_attributes[attribute.key] =
                    pending + 1

                pending_attribute_total =
                    pending_attribute_total + 1
            end

            if
                not can_add and
                imgui.end_disabled ~= nil
            then
                imgui.end_disabled()
            end

            imgui.same_line()

            local can_refund =
                committed > 1

            if
                not can_refund and
                imgui.begin_disabled ~= nil
            then
                imgui.begin_disabled()
            end

            if
                imgui.button(
                    "Refund Committed##rpg_refund_"
                    .. attribute.key
                )
                and can_refund
            then
                rpg.refund_attribute_point(
                    attribute.key
                )
            end

            if
                not can_refund and
                imgui.end_disabled ~= nil
            then
                imgui.end_disabled()
            end
        end

        imgui.separator()

        value(
            "Pending Attribute Points",
            pending_attribute_total
        )

        local can_confirm =
            pending_attribute_total > 0
            and pending_attribute_total
                <= (
                    tonumber(
                        profile.attribute_points
                    ) or 0
                )

        if
            not can_confirm and
            imgui.begin_disabled ~= nil
        then
            imgui.begin_disabled()
        end

        if
            imgui.button(
                "Confirm Distribution"
            )
            and can_confirm
        then
            confirm_pending_attributes(
                profile
            )
        end

        if
            not can_confirm and
            imgui.end_disabled ~= nil
        then
            imgui.end_disabled()
        end

        imgui.same_line()

        local can_cancel =
            pending_attribute_total > 0

        if
            not can_cancel and
            imgui.begin_disabled ~= nil
        then
            imgui.begin_disabled()
        end

        if
            imgui.button(
                "Cancel Pending"
            )
            and can_cancel
        then
            clear_pending_attributes()

            rpg.last_message =
                "Canceled pending debug attribute distribution."
        end

        if
            not can_cancel and
            imgui.end_disabled ~= nil
        then
            imgui.end_disabled()
        end

        imgui.tree_pop()
    end

    if imgui.tree_node("Derived Stats") then
        value("Vitality Max HP Bonus", derived.max_hp_bonus)
        value("Weapon Damage Multiplier", string.format("%.3f", derived.weapon_damage_multiplier))
        value("Knife Attack Speed Multiplier", string.format("%.3f", derived.action_speed_multiplier))
        value("Movement Speed Multiplier", string.format("%.3f", derived.movement_speed_multiplier))
        value("Fire Rate Multiplier", string.format("%.3f", derived.fire_rate_multiplier))
        value("Reload Speed Multiplier", string.format("%.3f", derived.reload_speed_multiplier))
        value("Healing Multiplier", string.format("%.3f", derived.healing_multiplier))
        value("Critical Chance", string.format("%.2f%%", derived.critical_chance * 100.0))
        value("Critical Damage Bonus", string.format("%.2f%%", derived.critical_damage_bonus * 100.0))
        value(
            "Vitality HP Per Point",
            string.format(
                "%.3f",
                stats.balance().vitality_hp_per_point
            )
        )
        value("Tracked Base Max HP", stat_application.base_max_hp)
        value("Applied Vitality Bonus", stat_application.applied_vitality_bonus)
        value("Effective Max HP", stat_application.expected_max_hp)
        value("Max HP Application Status", stat_application.last_status)
        imgui.tree_pop()
    end

    if imgui.tree_node("Diagnostics") then
        if imgui.tree_node("Attribute Balance Tuning") then
            local balance =
                stats.balance()

            imgui.text(
                "Persistent debug tuning. Values save separately from RPG profiles."
            )
            imgui.text(
                "All per-point and clamp controls use 0.001 increments."
            )

            local changed_any = false

            local function tune(
                label,
                key,
                minimum,
                maximum
            )
                local changed, new_value =
                    imgui.drag_float(
                        label,
                        tonumber(balance[key]) or 0.0,
                        0.001,
                        minimum,
                        maximum
                    )

                if changed then
                    balance[key] =
                        math.max(
                            minimum,
                            math.min(
                                maximum,
                                tonumber(new_value) or minimum
                            )
                        )

                    changed_any = true
                end
            end

            if imgui.tree_node("Per-Attribute Values") then
                tune(
                    "Vitality: Max HP per Point",
                    "vitality_hp_per_point",
                    0.0,
                    1000.0
                )
                tune(
                    "Strength: Damage per Point",
                    "strength_damage_per_point",
                    0.0,
                    1.0
                )
                tune(
                    "Dexterity: Action Speed per Point",
                    "dexterity_speed_per_point",
                    0.0,
                    1.0
                )
                tune(
                    "Dexterity: Fire Rate First Point",
                    "dexterity_fire_rate_first_point",
                    0.0,
                    1.0
                )
                tune(
                    "Dexterity: Fire Rate Later Points",
                    "dexterity_fire_rate_per_later_point",
                    0.0,
                    1.0
                )
                tune(
                    "Agility: Movement per Point",
                    "agility_movement_per_point",
                    0.0,
                    1.0
                )
                tune(
                    "Agility: Reload First Point",
                    "agility_reload_first_point",
                    0.0,
                    1.0
                )
                tune(
                    "Agility: Reload Later Points",
                    "agility_reload_per_later_point",
                    0.0,
                    1.0
                )
                tune(
                    "Intelligence: Healing per Point",
                    "intelligence_healing_per_point",
                    0.0,
                    1.0
                )
                tune(
                    "Luck: Critical Chance per Point",
                    "luck_critical_per_point",
                    0.0,
                    1.0
                )
                tune(
                    "Luck: Critical Damage per Point",
                    "luck_critical_damage_per_point",
                    0.0,
                    1.0
                )
                imgui.tree_pop()
            end

            if imgui.tree_node("Maximum Clamps") then
                imgui.text(
                    "WARNING: Fire rate above x2.0 is known to crash with "
                    .. "the LE 5, TMP, and CQBR."
                )
                imgui.text(
                    "Extreme values are intentionally available for destructive testing."
                )
                imgui.text(
                    "Current health tests and overlay rendering are validated only "
                    .. "through 20,160 HP."
                )
                imgui.text(
                    "The Safe Total Cap is 20,160 HP and matches the eighth "
                    .. "2,520-HP boundary."
                )

                tune(
                    "Vitality: Maximum Max HP Bonus",
                    "vitality_max_hp_bonus",
                    0.0,
                    100000.0
                )
                tune(
                    "Strength: Maximum Damage Multiplier",
                    "strength_damage_max_multiplier",
                    1.0,
                    100.0
                )
                tune(
                    "Dexterity: Maximum Action Speed",
                    "dexterity_speed_max_multiplier",
                    1.0,
                    10.0
                )
                tune(
                    "Dexterity: Maximum Fire Rate",
                    "dexterity_fire_rate_max_multiplier",
                    1.0,
                    10.0
                )
                tune(
                    "Agility: Maximum Movement Speed",
                    "agility_movement_max_multiplier",
                    1.0,
                    10.0
                )
                tune(
                    "Agility: Maximum Reload Speed",
                    "agility_reload_max_multiplier",
                    1.0,
                    10.0
                )
                tune(
                    "Intelligence: Maximum Healing Multiplier",
                    "intelligence_healing_max_multiplier",
                    1.0,
                    100.0
                )
                tune(
                    "Luck: Maximum Critical Chance",
                    "luck_critical_chance_max",
                    0.0,
                    10.0
                )
                tune(
                    "Luck: Maximum Critical Damage",
                    "luck_critical_damage_max",
                    0.0,
                    100.0
                )
                imgui.tree_pop()
            end

            if changed_any then
                stat_application.reset_tracking()
                stats.save_balance()
                rpg.last_message =
                    stats.balance_status
            end

            if imgui.button("Restore Default Balance") then
                stats.restore_default_balance(
                    true
                )
                stat_application.reset_tracking()
                rpg.last_message =
                    stats.balance_status
            end

            imgui.same_line()

            if imgui.button("Reload Balance JSON") then
                stats.reload_balance()
                stat_application.reset_tracking()
                rpg.last_message =
                    stats.balance_status
            end

            value(
                "Balance JSON",
                stats.balance_path
            )
            value(
                "Balance Persistence",
                stats.balance_status
            )
            value(
                "Balance Saves",
                stats.balance_save_count
            )
            value(
                "Balance Loads",
                stats.balance_load_count
            )

            imgui.tree_pop()
        end
        -- This panel is drawn beside the attaché case. The manager's busy
        -- state opens it, while requestExitAttacheCaseLight starts the close
        -- fade before the native menu has completely disappeared.
        if imgui.tree_node("Attaché-Case Progression Panel") then
            local changed = false
            changed, inventory_progression.force_visible = imgui.checkbox(
                "Force Visible for Layout Testing",
                inventory_progression.force_visible
            )
            changed, inventory_progression.reference_left = imgui.drag_float(
                "Left Margin (2560 Reference)",
                inventory_progression.reference_left,
                1.0,
                0.0,
                1200.0
            )
            changed, inventory_progression.vertical_offset = imgui.drag_float(
                "Vertical Offset (1440 Reference)",
                inventory_progression.vertical_offset,
                1.0,
                -600.0,
                600.0
            )
            changed, inventory_progression.reference_width_px = imgui.drag_float(
                "Panel Width (2560 Reference)",
                inventory_progression.reference_width_px,
                1.0,
                320.0,
                1200.0
            )

            value("Panel Visible", inventory_progression.items_screen_visible)
            value("Items Session Active",
                inventory_progression.items_session_active == true)
            value("Items Session Source",
                inventory_progression.items_session_source or "none")
            value("Strong Items Confirmed",
                inventory_progression.strong_items_confirmed == true)
            value("Strong Items Heartbeats",
                inventory_progression.strong_items_heartbeat_calls or 0)
            value("Strong Items Source",
                inventory_progression.strong_items_heartbeat_source or "none")
            value("Strong Proof Rule",
                "diagnostic-only; shared with Charms")
            value("Target Item Probe Calls",
                inventory_progression.target_item_probe_calls or 0)
            value("Last Target Item Type",
                inventory_progression.last_target_item_type or "none")
            value("Selection Probe Calls",
                inventory_progression.selection_probe_calls or 0)
            value("Last Selection Inventory Type",
                inventory_progression.last_selection_inventory_type or "none")
            value("Last Selection Previous",
                inventory_progression.last_selection_previous or "none")
            value("Last Selection Current",
                inventory_progression.last_selection_current or "none")

            imgui.separator()

            value("Case Method Probe Hooks",
                inventory_progression.case_method_probe_installed or 0)
            value("Case Method Probe Total",
                inventory_progression.case_method_probe_total or 0)
            value("Case Method Probe Last",
                inventory_progression.case_method_probe_last or "none")
            value("Charms Blocker",
                inventory_progression.charms_active == true)
            value("Charms Hook Installed",
                inventory_progression.charms_hook_installed == true)
            value("Charms Heartbeats",
                inventory_progression.charms_heartbeat_calls or 0)
            value("Charms Blocker Remaining",
                string.format(
                    "%.3f",
                    math.max(
                        0.0,
                        (
                            inventory_progression.charms_blocker_until
                            or 0.0
                        ) - os.clock()
                    )
                ))

            local probe_counts =
                inventory_progression.case_method_probe_counts
                or {}

            value("draw", probe_counts.draw or 0)
            value("update", probe_counts.update or 0)
            value("lateUpdate", probe_counts.lateUpdate or 0)
            value("updateOnActive", probe_counts.updateOnActive or 0)
            value("lateUpdateOnActive", probe_counts.lateUpdateOnActive or 0)
            value("render", probe_counts.render or 0)
            value("updateItemIcon", probe_counts.updateItemIcon or 0)
            value("updateTargetItem", probe_counts.updateTargetItem or 0)
            value("onSelectionChanged", probe_counts.onSelectionChanged or 0)
            value("changeStep", probe_counts.changeStep or 0)

            if imgui.button("Reset Case Method Probe") then
                inventory_progression.reset_case_method_probe()
            end

            imgui.separator()

            value("ItemBox Method Probe Hooks",
                inventory_progression.itembox_method_probe_installed or 0)
            value("ItemBox Method Probe Total",
                inventory_progression.itembox_method_probe_total or 0)
            value("ItemBox Method Probe Last",
                inventory_progression.itembox_method_probe_last or "none")

            local item_box_probe_counts =
                inventory_progression.itembox_method_probe_counts
                or {}

            value("openItemBox Ambient Gameplay Calls",
                inventory_progression.itembox_ambient_open_calls or 0)
            value("openItemBox Probe Role",
                "ignored: continuous gameplay call")
            value("onOpenItemBox", item_box_probe_counts.onOpenItemBox or 0)
            value("onOpenItemBoxSub", item_box_probe_counts.onOpenItemBoxSub or 0)
            value("onCloseItemBox", item_box_probe_counts.onCloseItemBox or 0)
            value("onCloseItemBoxSub", item_box_probe_counts.onCloseItemBoxSub or 0)
            value("recvGmParam", item_box_probe_counts.recvGmParam or 0)

            if imgui.button("Reset ItemBox Method Probe") then
                inventory_progression.reset_itembox_method_probe()
            end
            value("Save/Typewriter Blocker",
                inventory_progression.save_menu_active == true)
            value("Save Blocker Remaining",
                string.format("%.3f",
                    math.max(
                        0.0,
                        (inventory_progression.save_menu_blocker_until or 0.0)
                        - os.clock()
                    )))
            value("Storage Blocker",
                inventory_progression.storage_active == true)
            value("Storage Blocker Remaining",
                string.format("%.3f",
                    math.max(
                        0.0,
                        (inventory_progression.storage_blocker_until or 0.0)
                        - os.clock()
                    )))
            value("Unblocked Stability Remaining",
                string.format("%.3f",
                    math.max(
                        0.0,
                        (inventory_progression.unblocked_stability_duration or 0.25)
                        - (
                            (
                                tonumber(
                                    inventory_progression.unblocked_since
                                ) or 0.0
                            ) > 0.0
                            and os.clock()
                                - (
                                    tonumber(
                                        inventory_progression.unblocked_since
                                    ) or 0.0
                                )
                            or 0.0
                        )
                    )))
            value("Blocker Status",
                inventory_progression.blocker_status or "unknown")
            value("Save Blocker Opens",
                inventory_progression.save_menu_open_calls or 0)
            value("Save Blocker Closes",
                inventory_progression.save_menu_close_calls or 0)
            value("Storage Blocker Opens",
                inventory_progression.storage_open_calls or 0)
            value("Storage Blocker Closes",
                inventory_progression.storage_close_calls or 0)
            value("Blocker Ownership",
                "Save draw heartbeat + exact storage enter/exit")

            value("Attaché Manager Captured", inventory_progression.attache_manager ~= nil)
            value("Attaché Case Busy", inventory_progression.attache_busy)
            value("Early Exit Requested", inventory_progression.exit_requested)
            value("Exit Latch Armed",
                inventory_progression.exit_latch_armed ~= false)
            value("Exit Latch Generation",
                inventory_progression.exit_latch_generation or 0)
            value("Exit Latch Duration",
                string.format("%.2f",
                    inventory_progression.exit_latch_duration or 0.45))
            value("Exit Latch Remaining",
                string.format("%.3f",
                    math.max(
                        0.0,
                        (inventory_progression.exit_request_time or 0.0)
                        + (inventory_progression.exit_latch_duration or 0.45)
                        - os.clock()
                    )))
            value("Exit Hook Installed", inventory_progression.exit_hook_installed)
            value("Exit Hook Calls", inventory_progression.exit_hook_calls)
            value("Fade Alpha", string.format("%.3f", inventory_progression.fade_alpha or 0.0))
            value("Fade Target", string.format("%.3f", inventory_progression.fade_target or 0.0))
            value("Manager Polls", inventory_progression.attache_manager_polls)
            value("Manager Poll Failures", inventory_progression.attache_manager_failures)
            value("Manager Status", inventory_progression.attache_manager_status)
            value("Exit Hook Status", inventory_progression.exit_hook_status)

            value("Current Case Step",
                inventory_progression.items_last_live_step or "unknown")
            value("Current Active Inventory",
                inventory_progression.current_inventory_value or "unknown")
            value("Learned Items Inventory",
                inventory_progression.items_inventory_value or "unknown")
            value("Invalid Inventory Sentinel",
                "-1 and all negative values rejected")
            value("Case Step Read Status",
                inventory_progression.case_step_read_status or "unknown")
            value("Active Inventory Read Status",
                inventory_progression.active_inventory_read_status or "unknown")

            imgui.separator()

            if imgui.tree_node("Item Window State Probe") then
                imgui.text(
                    "Switch between Items, Crafting, Files, and Keys & Treasures."
                )
                imgui.text(
                    "Copy these five values from each screen."
                )

                value("CurrRootState",
                    inventory_progression.item_window_probe_root_state
                        ~= nil
                        and inventory_progression.item_window_probe_root_state
                        or "unreadable")
                value("CurrStateType",
                    inventory_progression.item_window_probe_state_type
                        ~= nil
                        and inventory_progression.item_window_probe_state_type
                        or "unreadable")
                value("CurrStartType",
                    inventory_progression.item_window_probe_start_type
                        ~= nil
                        and inventory_progression.item_window_probe_start_type
                        or "unreadable")
                value("CurrStep",
                    inventory_progression.item_window_probe_step
                        ~= nil
                        and inventory_progression.item_window_probe_step
                        or "unreadable")
                value("BehaviorHub CurrStep",
                    inventory_progression.item_window_probe_hub_step
                        ~= nil
                        and inventory_progression.item_window_probe_hub_step
                        or "unreadable")

                value("Probe Calls",
                    inventory_progression.item_window_probe_calls or 0)
                value("Probe Failures",
                    inventory_progression.item_window_probe_failures or 0)
                value("Probe Status",
                    inventory_progression.item_window_probe_status
                        or "unknown")

                imgui.tree_pop()
            end

            if imgui.tree_node("Visibility Transition Log") then
                local history =
                    inventory_progression.visibility_diagnostics or {}

                if #history == 0 then
                    imgui.text("No visibility transitions captured yet.")
                else
                    for index, entry in ipairs(history) do
                        local line =
                            tostring(index)
                            .. ". "
                            .. tostring(entry)

                        if imgui.text_wrapped ~= nil then
                            imgui.text_wrapped(line)
                        else
                            imgui.text(line)
                        end
                    end
                end

                if imgui.button("Clear Visibility Log") then
                    inventory_progression.visibility_diagnostics = {}
                end

                imgui.tree_pop()
            end

            value("Resolution Source", inventory_progression.resolution_source)
            value("Live Resolution", string.format("%.0f x %.0f",
                inventory_progression.screen_width,
                inventory_progression.screen_height))
            value("Uniform Scale", string.format("%.4f",
                inventory_progression.uniform_scale))
            value("Computed Position", string.format("%.1f, %.1f",
                inventory_progression.computed_x or 0,
                inventory_progression.computed_y or 0))

            value("Mouse Input Available", inventory_progression.mouse_supported)
            value("Force Visible Input",
                inventory_progression.force_visible == true
                and "Direct ImGui mouse"
                or "Native inventory mouse")
            value("Mouse Input Source", inventory_progression.mouse_input_source)
            value("Cursor Pair Error",
                string.format("%.1f",
                    inventory_progression.cursor_pair_error or 0.0))
            value("Cursor Source Switches",
                inventory_progression.cursor_source_switches or 0)
            value("Cursor Mapping", "adaptive native-to-render transform")
            value("Calibration State", inventory_progression.input_scale_source)
            value("Calibration Resets", inventory_progression.input_reset_count or 0)
            value("Last Calibration Reset", inventory_progression.input_reset_reason or "none")
            value("Resolved Mouse Position", string.format("%.1f, %.1f",
                inventory_progression.last_mouse_x or -1,
                inventory_progression.last_mouse_y or -1))

            value("Hovered Attribute", inventory_progression.hover_attribute)
            value("Last Spent Attribute", inventory_progression.last_spent_attribute)
            value("Point Spend Count", inventory_progression.spend_count)
            value("Input Status", inventory_progression.input_status)
            value("Save/Typewriter Blocker",
                inventory_progression.save_menu_active == true)
            value("Save Session Latched",
                inventory_progression.save_menu_session_latched == true)
            value("Save Blocker Release",
                "native close/deactivate/destroy only")
            value("Typewriter Parent Blocker",
                inventory_progression.typewriter_menu_active == true)
            value("Typewriter Blocker Opens",
                inventory_progression.typewriter_menu_open_calls or 0)
            value("Typewriter Blocker Closes",
                inventory_progression.typewriter_menu_close_calls or 0)
            value("Typewriter Hook Status",
                inventory_progression.typewriter_hook_status or "unknown")
            value("Legacy Parent Resolver Status",
                inventory_progression.typewriter_legacy_hook_status or "unknown")
            value("Typewriter Select Hook",
                inventory_progression.typewriter_select_hook_installed == true)
            value("Typewriter Select Opens",
                inventory_progression.typewriter_select_open_calls or 0)
            value("Typewriter Select Closes",
                inventory_progression.typewriter_select_close_calls or 0)
            value("Typewriter Select Last Method",
                inventory_progression.typewriter_select_last_method or "none")
            value("Typewriter Select CurrStep",
                inventory_progression.typewriter_select_step or "none")
            value("Storage GUI Hook",
                inventory_progression.storage_gui_hook_installed == true)
            value("Storage GUI Opens",
                inventory_progression.storage_gui_open_calls or 0)
            value("Storage GUI Closes",
                inventory_progression.storage_gui_close_calls or 0)
            value("Storage GUI Last Method",
                inventory_progression.storage_gui_last_method or "none")
            value("Direct Typewriter Hook",
                inventory_progression.typewriter_direct_hook_installed == true)
            value("Direct Typewriter Calls",
                inventory_progression.typewriter_direct_calls or 0)
            value("Direct Typewriter Last Method",
                inventory_progression.typewriter_direct_last_method or "none")
            value("Typewriter GmFlag Hook",
                inventory_progression.typewriter_gmflag_hook_installed == true)
            value("Typewriter GmFlag Calls",
                inventory_progression.typewriter_gmflag_calls or 0)
            value("Typewriter GmFlag Last Method",
                inventory_progression.typewriter_gmflag_last_method or "none")
            value("Typewriter GmFlag Last Value",
                inventory_progression.typewriter_gmflag_last_value ~= nil
                and tostring(inventory_progression.typewriter_gmflag_last_value)
                or "none")
            value("Typewriter GmFlag Runtime Type",
                inventory_progression.typewriter_gmflag_last_runtime_type or "none")
            value("Typewriter Behavior Hook",
                inventory_progression.typewriter_bt_hook_installed == true)
            value("Typewriter Behavior Starts",
                inventory_progression.typewriter_bt_start_calls or 0)
            value("Typewriter Behavior Ends",
                inventory_progression.typewriter_bt_end_calls or 0)
            value("Typewriter Behavior Last Method",
                inventory_progression.typewriter_bt_last_method or "none")
            value("Typewriter Transition Pending",
                inventory_progression.typewriter_transition_pending == true)
            value("Typewriter Transition Resolution",
                inventory_progression.typewriter_transition_resolution or "none")

            imgui.separator()

            value("Armoury State Probe Hooks",
                inventory_progression.armoury_state_probe_installed or 0)
            value("Armoury State Probe Calls",
                inventory_progression.armoury_state_probe_calls or 0)
            value("Armoury State Last Method",
                inventory_progression.armoury_state_last_method or "none")
            value("Armoury State Runtime Type",
                inventory_progression.armoury_state_runtime_type or "none")
            value("Armoury State Next Raw",
                inventory_progression.armoury_state_next_raw or "none")
            value("Armoury Hub Step Raw",
                inventory_progression.armoury_hub_step_raw or "none")
            value("Armoury Hub Probe Calls",
                inventory_progression.armoury_hub_probe_calls or 0)
            value("Armoury Hub Active Child",
                inventory_progression.armoury_hub_active_child or "none")

            local hub_children =
                inventory_progression.armoury_hub_children
                or {}

            for _, child_key in ipairs({
                "typewriter",
                "storage",
                "save",
                "case"
            }) do
                local child =
                    hub_children[child_key]
                    or {}

                value(
                    "Hub Child " .. child_key,
                    string.format(
                        "exists=%s valid=%s type=%s",
                        tostring(child.exists == true),
                        child.valid ~= nil
                            and tostring(child.valid)
                            or "unknown",
                        tostring(child.type_name or "none")
                    )
                )
            end
            value("Armoury Screen Class",
                inventory_progression.armoury_screen_class or "unknown")
            value("Armoury Screen Source",
                inventory_progression.armoury_screen_source or "none")
            value("Armoury Blocker Updates",
                inventory_progression.armoury_state_blocker_calls or 0)
            value("Typewriter onStart Role",
                "diagnostic-only")
            value("Typewriter Open/Close Resolution",
                "onEnd + current AttacheCaseManager busy state")
            value("Verified Storage State",
                "ArmouryGuiState_ArmouryEnter")

            if imgui.button("Reset Armoury State Probe") then
                inventory_progression.reset_armoury_state_probe()
            end
            value("ItemBox Session Observed",
                inventory_progression.itembox_session_active == true)
            value("ItemBox Affects Visibility",
                false)
            value("ItemBox Session Opens",
                inventory_progression.itembox_session_open_calls or 0)
            value("ItemBox Session Closes",
                inventory_progression.itembox_session_close_calls or 0)
            value("ItemBox Hook Status",
                inventory_progression.itembox_hook_status or "unknown")
            value("ItemBox Open Hooks",
                inventory_progression.itembox_open_hook_count or 0)
            value("ItemBox Close Hooks",
                inventory_progression.itembox_close_hook_count or 0)
            value("Last ItemBox Open Method",
                inventory_progression.itembox_last_open_method or "none")
            value("Last ItemBox Close Method",
                inventory_progression.itembox_last_close_method or "none")
            value("ContextID Hook Installed",
                inventory_progression.itembox_context_hook_installed == true)
            value("ContextID Calls",
                inventory_progression.itembox_context_calls or 0)
            value("Last ItemBox ContextID",
                inventory_progression.itembox_last_context_text or "none")
            value("recvGmParam Hook Installed",
                inventory_progression.itembox_recv_param_hook_installed == true)
            value("recvGmParam Calls",
                inventory_progression.itembox_recv_param_calls or 0)
            value("Last Gm Param Type",
                inventory_progression.itembox_last_param_type or "none")
            value("Last Gm Param Arg",
                inventory_progression.itembox_last_param_arg or "none")
            value("User Object Probe Calls",
                inventory_progression.itembox_user_object_probe_calls or 0)
            value("Last User GameObject Type",
                inventory_progression.itembox_last_user_object_type or "none")
            value("Last User GmBase ContextID",
                inventory_progression.itembox_last_user_context_id or "none")
            value("Last User GmBase Context Type",
                inventory_progression.itembox_last_user_context_type or "none")
            value("Panel Status", inventory_progression.status)
            imgui.tree_pop()
        end

    if imgui.tree_node("RPG Save Slot Synchronization") then
        local active_record = rpg.active_save_record() or {}
        value("Active RPG Profile Slot",
            rpg.active_save_slot() or "none")
        value("Slot Convention",
            "0=autosave, 1-20=manual")
        value("Last Native Operation",
            active_record.last_native_operation or "none")
        value("Last Native Raw SlotId",
            active_record.last_native_raw_slot or "none")
        value("Last Resolved Save Slot",
            game_save_sync.last_resolved_save_slot or "none")
        value("Completed Save Manager SlotId",
            game_save_sync.last_save_manager_slot or "none")
        value("Completed Save Slot Source",
            game_save_sync.last_save_manager_source or "none")
        value("Last Resolved Load Slot",
            game_save_sync.last_resolved_load_slot or "none")
        value("Menu Cursor Hooks",
            "disabled: cyclic navigation only")
        value("Pending Save Transaction Slot",
            game_save_sync.pending_slot or "none")
        value("Pending Save Raw SlotId",
            game_save_sync.pending_raw_slot or "none")
        value("Queued RPG Save Slot",
            game_save_sync.queued_save_slot or "none")
        value("Locked Load Transaction Slot",
            game_save_sync.pending_load_request_slot or "none")
        value("Locked Load Raw SlotId",
            game_save_sync.pending_load_request_raw_slot or "none")
        value("Queued RPG Load Slot",
            game_save_sync.queued_load_slot or "none")
        value("Load Delay Frames", game_save_sync.load_delay_frames)
        value("Installed Hooks", game_save_sync.installed_hooks)
        value("Save Request Hook",
            game_save_sync.save_request_hook_installed == true)
        value("Load Request Hook",
            game_save_sync.load_request_hook_installed == true)
        value("Save Completion Hook",
            game_save_sync.save_completion_hook_installed == true)
        value("Load Completion Hook",
            game_save_sync.load_completion_hook_installed == true)
        value("Autosave Trigger Hook",
            game_save_sync.autosave_hook_installed == true)
        value("Slot Captures", game_save_sync.captures)
        value("Profile Path", rpg.save_path())
        value("Save Events", game_save_sync.save_events)
        value("Load Events", game_save_sync.load_events)
        value("Last Load Was Continue/Autosave", game_save_sync.last_load_was_continue)
        value("Native Load Serial",
            game_save_sync.native_load_serial)
        value("Main Menu Hook",
            game_save_sync.main_menu_hook_installed)
        value("Main Menu Active",
            game_save_sync.main_menu_active)
        value("Main Menu Phase",
            game_save_sync.main_menu_phase_name)
        value("Main Menu New Game Start",
            game_save_sync.main_menu_new_game_start)
        value("Main Menu Cleanup Fired",
            game_save_sync.main_menu_cleanup_fired)
        value("Main Menu Events",
            game_save_sync.main_menu_events)
        value("New Game Profile Resets",
            game_save_sync.new_game_resets)
        value("Title Profile Resets",
            game_save_sync.title_profile_resets)
        value("Campaign Initialization Pending",
            game_save_sync.campaign_initialization_pending)
        value("Campaign Initialization Source",
            game_save_sync.campaign_initialization_source)
        value("Campaign Initialization Resumes",
            game_save_sync.campaign_initialization_resumes)
        value("Profile-Bound Player Pointer",
            game_save_sync.profile_bound_player_ptr)
        value("Profile-Bound Load Serial",
            game_save_sync.profile_bound_load_serial)
        value("Character Binding Resets",
            game_save_sync.character_binding_resets)
        value("Character Binding Status",
            game_save_sync.last_character_binding_status)
        value("RPG Campaign Initialized",
            rpg.campaign_initialized)
        value("RPG Initialization Status",
            rpg.campaign_initialization_status)
        value("Last New Game Reset",
            game_save_sync.last_new_game_reset)
        value("Skipped Unsafe Events", game_save_sync.skipped_events)
        value("Status", game_save_sync.status)
        imgui.tree_pop()
    end

    if imgui.tree_node("Action Speed Hook") then
        value("Probe Installed", action_speed.hook_installed)
        value("Player Captures", action_speed.hook_calls)
        value("Captured Player", action_speed.player_context_type)
        value("Player Pointer", action_speed.player_context_ptr)
        value("Player Capture Hook", action_speed.player_capture_hook_installed)
        value("Player Capture Calls", action_speed.player_capture_hook_calls)
        value("Player Capture Status", action_speed.player_capture_status)
        value("Desired Knife Multiplier", string.format("%.3f", derived.action_speed_multiplier))
        value("Desired Fire Rate", string.format("%.3f", derived.fire_rate_multiplier))
        value("Desired Reload Speed", string.format("%.3f", derived.reload_speed_multiplier))
        value("Status", action_speed.last_status)
        value("Application Hook", action_speed.application_hook_installed)
        value("Player Animation Targets", action_speed.player_animation_target_count)
        value("Apply Count", action_speed.apply_count)
        value("Last Base Speed", string.format("%.3f", action_speed.last_base_speed))
        value("Last Applied Speed", string.format("%.3f", action_speed.last_applied_speed))
        value("Last Applied Multiplier", string.format("%.3f", action_speed.last_multiplier))
        value("Application Status", action_speed.application_status)
        value("Movement Object", action_speed.movement.pointer)
        value("Movement Field Applications", action_speed.movement.apply_count)
        value("Movement Field Status", action_speed.movement.status)
        value("Movement Load Resets",
            action_speed.movement.load_resets)
        value("Movement Values Restored On Load",
            action_speed.movement.load_restore_count)
        value("Last Movement Load Reset",
            action_speed.movement.last_load_reset_status)
        value("Movement Capture Source", action_speed.movement.capture_source)
        value("Movement Capture Attempts", action_speed.movement.capture_attempts)
        value("Movement Graph Scans", action_speed.movement.graph_scans)
        value("Movement Graph Objects Inspected",
            action_speed.movement.graph_objects_inspected)
        value("Movement UserData Hook",
            action_speed.movement.userdata_hook_installed)
        value("Movement UserData onLoad Calls",
            action_speed.movement.userdata_hook_calls)
        value("Movement Live Capture Hooks",
            action_speed.movement.live_capture_hooks_installed)
        value("Movement Live Capture Calls",
            action_speed.movement.live_capture_calls)
        value("Movement Live Capture Last Method",
            action_speed.movement.live_capture_last_method)
        value("Movement Live Capture Status",
            action_speed.movement.live_capture_status)
        value("Movement Direct Field Mode", action_speed.movement.field_write_mode)

        local movement_field_count = 0
        for _ in pairs(action_speed.movement.fields or {}) do
            movement_field_count = movement_field_count + 1
        end
        value("Movement Fields Captured", movement_field_count)

        if imgui.tree_node("Reload Action Rate") then
            value("Installed", action_speed.reload_action.installed)
            value("Installed Hooks",
                action_speed.reload_action.installed_hooks)
            value("Start Calls",
                action_speed.reload_action.start_calls)
            value("Update Calls",
                action_speed.reload_action.update_calls)
            value("End Calls",
                action_speed.reload_action.end_calls)
            value("Last Type",
                action_speed.reload_action.last_type)
            value("Last Pointer",
                action_speed.reload_action.last_pointer)
            value("Last Base Rate",
                string.format("%.4f",
                    action_speed.reload_action.last_base_rate))
            value("Last Applied Rate",
                string.format("%.4f",
                    action_speed.reload_action.last_applied_rate))
            value("Last Multiplier",
                string.format("%.3f",
                    action_speed.reload_action.last_multiplier))
            value("Native Duration Scale",
                string.format("%.4f",
                    action_speed.reload_action.last_native_duration_scale))
            value("Applied Duration Scale",
                string.format("%.4f",
                    action_speed.reload_action.last_applied_duration_scale))
            value("Applied Duration vs Native",
                string.format("%.1f%%",
                    action_speed.reload_action.last_duration_ratio * 100.0))
            value("Duration Reduction",
                string.format("%.1f%%",
                    action_speed.reload_action.last_duration_reduction_percent))
            value("Duration Note",
                "Normalized estimate: actual clip/frame duration is not exposed by this action.")
            value("Pre Apply Calls",
                action_speed.reload_action.pre_apply_calls)
            value("Post Apply Calls",
                action_speed.reload_action.post_apply_calls)
            value("Post-Original Readback Rate",
                string.format("%.4f",
                    action_speed.reload_action.post_readback_rate))
            value("Write Confirmed",
                action_speed.reload_action.write_confirmed)
            value("Original Overwrite Count",
                action_speed.reload_action.original_overwrite_count)
            value("Captured Arg Index",
                action_speed.reload_action.captured_arg_index)
            value("Captured Arg Type",
                action_speed.reload_action.captured_arg_type)
            value("Argument Scan",
                action_speed.reload_action.argument_scan_status)
            value("Application Mode",
                action_speed.reload_action.application_mode)
            value("Direct Gun Path Active",
                action_speed.reload_action.direct_gun_path_active)
            value("Behavior-Tree Application Suppressed",
                action_speed.reload_action.behavior_tree_application_suppressed)
            value("Legacy Cleanup Runs",
                action_speed.reload_action.cleanup_runs)
            value("Legacy Values Restored",
                action_speed.reload_action.cleanup_values_restored)
            value("Direct Gun Getter Calls",
                (
                    action_speed.native.channels.reload
                    and action_speed.native.channels.reload.count
                ) or 0)
            value("Direct Gun Base Rate",
                string.format("%.4f",
                    (
                        action_speed.native.channels.reload
                        and action_speed.native.channels.reload.base
                    ) or 0.0))
            value("Direct Gun Applied Rate",
                string.format("%.4f",
                    (
                        action_speed.native.channels.reload
                        and action_speed.native.channels.reload.applied
                    ) or 0.0))
            value("Reload Motion Type",
                action_speed.reload_action.motion_type)
            value("Reload Motion Pointer",
                action_speed.reload_action.motion_pointer)
            value("Reload Motion Layers",
                action_speed.reload_action.motion_layer_count)
            value("Reload Layers Applied",
                action_speed.reload_action.motion_layers_applied)
            value("Reload Layers Restored",
                action_speed.reload_action.motion_layers_restored)
            value("Last Layer Base Speed",
                string.format("%.4f",
                    action_speed.reload_action.last_layer_base_speed))
            value("Last Layer Applied Speed",
                string.format("%.4f",
                    action_speed.reload_action.last_layer_applied_speed))
            value("Last Method",
                action_speed.reload_action.last_method)
            value("Status",
                action_speed.reload_action.status)
            if action_speed.reload_action.error ~= "" then
                value("Error",
                    action_speed.reload_action.error)
            end
            imgui.tree_pop()
        end

        if imgui.tree_node("Player Body Movement") then
            value("Installed", action_speed.body_movement.installed)
            value("Installed Hooks",
                action_speed.body_movement.installed_hooks)
            value("Update Calls",
                action_speed.body_movement.update_calls)
            value("Motion Speed Getter Calls",
                action_speed.body_movement.getter_calls)
            value("Action Speed Setter Calls",
                action_speed.body_movement.setter_calls)
            value("Captured Type",
                action_speed.body_movement.type_name)
            value("Captured Pointer",
                action_speed.body_movement.pointer)
            value("Last Method",
                action_speed.body_movement.last_method)
            value("Last Base Speed",
                string.format("%.4f",
                    action_speed.body_movement.last_base_speed))
            value("Last Applied Speed",
                string.format("%.4f",
                    action_speed.body_movement.last_applied_speed))
            value("Last Raw Getter Speed",
                string.format("%.4f",
                    action_speed.body_movement.last_raw_speed))
            value("Last Normalized Speed",
                string.format("%.4f",
                    action_speed.body_movement.last_normalized_speed))
            value("Load Normalization Active",
                action_speed.body_movement.load_normalization_active)
            value("Load Normalization Old Base",
                string.format("%.4f",
                    action_speed.body_movement.load_normalization_old_base))
            value("Load Normalization Old Applied",
                string.format("%.4f",
                    action_speed.body_movement.load_normalization_old_applied))
            value("Load Normalization Old Multiplier",
                string.format("%.3f",
                    action_speed.body_movement.load_normalization_old_multiplier))
            value("Load Normalization Hits",
                action_speed.body_movement.load_normalization_hits)
            value("Load Normalization Clears",
                action_speed.body_movement.load_normalization_clears)
            value("Load Normalization Status",
                action_speed.body_movement.load_normalization_status)
            value("Last Multiplier",
                string.format("%.3f",
                    action_speed.body_movement.last_multiplier))
            value("Walk/Run Gate",
                action_speed.body_movement.locomotion_gate)
            value("Walk/Run Gate Reason",
                action_speed.body_movement.locomotion_gate_reason)
            value("MoveDir",
                string.format("%.4f",
                    action_speed.body_movement.last_move_dir))
            value("TargetMoveDir",
                string.format("%.4f",
                    action_speed.body_movement.last_target_move_dir))
            value("ObjectiveMoveDir",
                string.format("%.4f",
                    action_speed.body_movement.last_objective_move_dir))
            value("Status",
                action_speed.body_movement.status)
            imgui.tree_pop()
        end

        if imgui.tree_node("Native Speed Hooks") then
            value("Installed", action_speed.native.installed)
            value("Installed Hooks", action_speed.native.installed_hooks)
            value("Status", action_speed.native.status)

            local channel_order = {
                {"knife", "Knife Combat Speed"},
                {"melee", "Melee Combat Speed"},
                {"movement", "Movement Speed"},
                {"reload", "Reload Time"},
                {"weapon_transition", "Weapon Transition Time"}
            }
            for _, entry in ipairs(channel_order) do
                local channel = action_speed.native.channels[entry[1]]
                value(entry[2] .. " Calls", channel.count)
                value(entry[2] .. " Base", string.format("%.4f", channel.base))
                value(entry[2] .. " Applied", string.format("%.4f", channel.applied))
            end

            for _, failure in ipairs(action_speed.native.failed_hooks) do
                value("Unresolved", failure)
            end
            imgui.tree_pop()
        end

        if imgui.tree_node("Weapon Timing Probe") then
            value("Installed", action_speed.weapon_probe.installed)
            value("Installed Capture Hooks", action_speed.weapon_probe.installed_hooks)
            value("Getter Calls", action_speed.weapon_probe.calls)
            value("Captured Type", action_speed.weapon_probe.type_name)
            value("Captured Pointer", action_speed.weapon_probe.pointer)
            value("Status", action_speed.weapon_probe.status)
            for _, member in ipairs(action_speed.weapon_probe.members) do
                imgui.text(string.format(
                    "%s %s %s = %s",
                    member.kind,
                    member.type_name,
                    member.name,
                    member.value
                ))
            end
            if action_speed.weapon_probe.error ~= "" then
                value("Error", action_speed.weapon_probe.error)
            end
            imgui.tree_pop()
        end

        if imgui.tree_node("Player Equipment Actions") then
            value("Installed", action_speed.equipment_actions.installed)
            value("Installed Hooks", action_speed.equipment_actions.installed_hooks)
            value("Fire Calls", action_speed.equipment_actions.fire_calls)
            value("Dry Fire Calls", action_speed.equipment_actions.dry_fire_calls)
            value("Reload Start Calls", action_speed.equipment_actions.reload_start_calls)
            value("Reload Calls", action_speed.equipment_actions.reload_calls)
            value("Motion Type", action_speed.equipment_actions.motion_type)
            value("Motion Pointer", action_speed.equipment_actions.motion_pointer)
            value("Motion Layer Count", action_speed.equipment_actions.layer_count)
            value("Layers Applied Last Action", action_speed.equipment_actions.layers_applied)
            value("Total Layer Applications", action_speed.equipment_actions.layer_apply_count)
            value("Last Layer Base Speed", string.format("%.4f", action_speed.equipment_actions.last_layer_base_speed))
            value("Last Layer Applied Speed", string.format("%.4f", action_speed.equipment_actions.last_layer_applied_speed))
            value("Status", action_speed.equipment_actions.status)
            if action_speed.equipment_actions.layer_error ~= "" then
                value("Layer Error", action_speed.equipment_actions.layer_error)
            end
            if action_speed.equipment_actions.error ~= "" then
                value("Error", action_speed.equipment_actions.error)
            end
            imgui.tree_pop()
        end

        if imgui.button("Rescan Action Speed Members") then
            action_speed.scan()
        end

        value("Candidate Count", #action_speed.candidates)
        for index, candidate in ipairs(action_speed.candidates) do
            if index > 32 then
                value("More", #action_speed.candidates - 32)
                break
            end
            imgui.text(string.format(
                "%s.%s [%s] %s",
                candidate.owner,
                candidate.name,
                candidate.kind,
                candidate.type_name
            ))
        end

        if action_speed.last_error ~= "" then
            value("Error", action_speed.last_error)
        end
        imgui.tree_pop()
    end

    if imgui.tree_node("Luck Critical Hooks") then
        value("Installed", critical.installed)
        value("Installed Hooks", critical.installed_hooks)
        value("Status", critical.status)
        value("Captured Object", critical.object_ptr)
        value("Field Apply Count", critical.apply_count)
        value("Luck Bonus", string.format("%.2f%%", derived.critical_chance * 100.0))
        value("Normal Calls", critical.normal.calls)
        value("Normal Base", string.format("%.4f", critical.normal.base))
        value("Normal Applied", string.format("%.4f", critical.normal.applied))
        value("Limit Break Calls", critical.limit_break.calls)
        value("Limit Break Base", string.format("%.4f", critical.limit_break.base))
        value("Limit Break Applied", string.format("%.4f", critical.limit_break.applied))
        value("Critical Damage Calls", critical.damage.calls)
        value("Critical Damage Base", string.format("%.4f", critical.damage.base))
        value("Critical Damage Bonus", string.format("%.4f", critical.damage.bonus))
        value("Critical Damage Applied", string.format("%.4f", critical.damage.applied))
        for _, failure in ipairs(critical.failed) do
            value("Unresolved", failure)
        end
        if imgui.tree_node("Live DamageInfo Probe") then
            local probe = critical.hit_probe
            value("Calls", probe.calls)
            value("Original Damage", probe.original_damage)
            value("Damage", probe.damage)
            value("Weapon ID", probe.weapon_id)
            value("Native IsCritical", probe.is_critical)
            value("Is Kill", probe.is_kill)
            value("Owner Type", probe.owner_type)
            value("Owner Name", probe.owner_name)
            value("Weapon Object Type", probe.weapon_object_type)
            value("Attacker Type", probe.attacker_type)
            value("Target Type", probe.target_type)
            value("Eligible Player Hit", probe.eligible)
            value("Excluded Reason", probe.excluded_reason)
            value("Last Roll", string.format("%.4f", probe.roll))
            value("Crit Chance", string.format("%.2f%%", probe.crit_chance * 100.0))
            value("Strength Multiplier", string.format("%.3f", probe.strength_multiplier))
            value("Critical Multiplier", string.format("%.3f", probe.critical_multiplier))
            value("Final Damage", probe.final_damage)
            value("Modified Hits", probe.modified_hits)
            value("Rolled Critical Hits", probe.critical_hits)
            imgui.tree_pop()
        end
        imgui.tree_pop()
    end

    if imgui.tree_node("Intelligence Healing") then
        value("Multiplier", string.format("%.3f", derived.healing_multiplier))
        value("Preview Native Heal", ctx.state.intelligence_preview_native_heal or 0)
        value("Preview Expected Heal", ctx.state.intelligence_preview_modified_heal or 0)
        value("Committed Native Heal", ctx.state.intelligence_commit_native_heal or 0)
        value("Committed Expected Heal", ctx.state.intelligence_commit_expected_heal or 0)
        imgui.tree_pop()
    end

    imgui.tree_pop()
    end

    value("RPG Status", rpg.last_message)
    imgui.tree_pop()
end

return rpg_ui
