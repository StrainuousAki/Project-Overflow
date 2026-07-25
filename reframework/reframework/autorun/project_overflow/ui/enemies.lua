------------------------------------------------------------
-- Maintenance classification — Build 49.39
-- Module: autorun/project_overflow/ui/enemies.lua
-- Role: ImGui or native-overlay presentation and diagnostics.
-- Status: active UI.
--
-- Compatibility policy:
--   Existing functions, hooks, module paths, and diagnostics are
--   intentionally retained in this maintenance pass.
--   `DEPRECATED` marks a supported legacy path, not removed code.
------------------------------------------------------------

------------------------------------------------------------
-- Project: Overflow — Native Enemy Discovery UI
------------------------------------------------------------

local probe =
    require("project_overflow.engine.enemy_kill_probe")

local registry =
    require("project_overflow.systems.enemies.registry")

local database =
    require("project_overflow.systems.enemies.database")

local elites =
    require("project_overflow.systems.enemies.elites")

local rewards =
    require("project_overflow.systems.enemies.rewards")

local classifier =
    require("project_overflow.systems.enemies.classifier")

local biorand_manifest =
    require("project_overflow.systems.enemies.biorand_manifest")

local enemies_ui = {
    editors = {},
    database_revision = -1
}

local function get_editor(kind_id, enemy_id)
    local key = database.observation_key(kind_id, enemy_id)
    local current = database.get_appearance(kind_id, enemy_id)
    local editor = enemies_ui.editors[key]

    if editor == nil then
        editor = {
            description = tostring(current.description or "Unknown Model"),
            override_rpg = current.has_rpg_overrides == true,
            display_name_override =
                tostring(current.display_name or ""),
            family_override =
                tostring(current.family or ""),
            identified_override =
                current.identified == true,
            base_xp_override =
                tonumber(current.base_xp) or 10,
            fixed_xp =
                tonumber(current.fixed_xp) or -1,
            loot_table_override =
                tostring(current.loot_table or "enemy_standard"),
            elite_profile_override =
                tostring(current.elite_profile or "standard"),
            forced_elite_tier =
                tostring(current.forced_elite_tier or "inherit"),
            status = ""
        }

        enemies_ui.editors[key] = editor
    end

    return editor
end

local function value(label, content)
    imgui.text(
        label ..
        " : " ..
        tostring(content)
    )
end

local function draw_reflection_snapshot(snapshot, unique_id)
    if snapshot == nil then
        imgui.text("No reflection snapshot captured.")
        return
    end

    value("Label", snapshot.label)
    value("Type", snapshot.type_name)
    value("Base Type", snapshot.base_type_name)
    value("Object Ptr", snapshot.object_ptr)
    value("Field Count", snapshot.field_count)
    value("Method Count", snapshot.method_count)
    value("Error", snapshot.error)

    if imgui.tree_node(
        "Fields##" ..
        tostring(unique_id)
    ) then
        if #snapshot.fields == 0 then
            imgui.text("No fields captured.")
        else
            for _, field in ipairs(snapshot.fields) do
                imgui.separator()
                value("Name", field.name)
                value("Type", field.type_name)
                value("Value", field.value)
            end
        end

        if snapshot.truncated_fields == true then
            imgui.text("Field list truncated by safety limit.")
        end

        imgui.tree_pop()
    end

    if imgui.tree_node(
        "Method Names##" ..
        tostring(unique_id)
    ) then
        if #snapshot.methods == 0 then
            imgui.text("No methods captured.")
        else
            for _, method_name in ipairs(snapshot.methods) do
                imgui.text(method_name)
            end
        end

        if snapshot.truncated_methods == true then
            imgui.text("Method list truncated by safety limit.")
        end

        imgui.tree_pop()
    end
end

local function set_values_text(values)
    local result = {}

    for key, enabled in pairs(values or {}) do
        if enabled then
            result[#result + 1] =
                tostring(key)
        end
    end

    table.sort(result)

    if #result == 0 then
        return "none"
    end

    return table.concat(
        result,
        ", "
    )
end


local function draw_costume_slot(slot, unique_id)
    if slot == nil then
        imgui.text("No slot data.")
        return
    end

    value("Source", slot.source)
    value("Null", slot.is_null)
    value("Runtime Type", slot.type_name)
    value("Ptr", slot.ptr)
    value("Field Error", slot.field_error)

    local fields = slot.fields or {}

    if #fields == 0 then
        imgui.text("No declared Unit fields captured.")
        return
    end

    for index, field in ipairs(fields) do
        if imgui.tree_node(
            tostring(field.name) ..
            "##costume_field_" ..
            tostring(unique_id) ..
            "_" ..
            tostring(index)
        ) then
            value("Declared Type", field.declared_type)
            value("Value", field.value)
            value("Runtime Type", field.runtime_type)
            value("Ptr", field.ptr)
            imgui.tree_pop()
        end
    end
end

local function draw_costume_snapshot(snapshot, unique_id)
    if snapshot == nil then
        imgui.text("No targeted costume snapshot captured.")
        return
    end

    value("Body Updater Source", snapshot.body_updater_source)
    value("Body Updater Type", snapshot.body_updater_type)
    value("Body Updater Ptr", snapshot.body_updater_ptr)
    value("Costume Driver Source", snapshot.costume_driver_source)
    value("Costume Driver Type", snapshot.costume_driver_type)
    value("Costume Driver Ptr", snapshot.costume_driver_ptr)
    value("Costume Signature", snapshot.signature)

    for index, slot in ipairs(snapshot.slots or {}) do
        if imgui.tree_node(
            tostring(slot.name) ..
            " Unit##costume_slot_" ..
            tostring(unique_id) ..
            "_" ..
            tostring(index)
        ) then
            draw_costume_slot(
                slot,
                tostring(unique_id) ..
                "_" ..
                tostring(index)
            )

            imgui.tree_pop()
        end
    end
end

function enemies_ui.draw(ctx)
    database.ensure_loaded()

    if enemies_ui.database_revision ~= database.revision then
        enemies_ui.editors = {}
        enemies_ui.database_revision = database.revision
    end

    if not imgui.tree_node("Enemy Discovery") then
        return
    end

    imgui.text(
        "Enemy death discovery uses notifyDead plus a processed-dead fallback."
    )

    if not probe.installed then
        imgui.text("The startup hook is unavailable. Use Retry after the game finishes loading.")

        if imgui.button("Retry Native Death Hooks") then
            probe.install(ctx)
        end
    else
        imgui.text("Native death hooks were installed during Project: Overflow startup.")
    end

    local changed
    changed,
    probe.enabled =
        imgui.checkbox(
            "Record Native Enemy Deaths",
            probe.enabled == true
        )

    value("Installed", probe.installed)
    value("Install Attempted", probe.install_attempted)
    value("Resolved Method", probe.resolved_method)
    value("Install Error", probe.install_error)

    value("Raw notifyDead Calls", probe.raw_hook_calls)
    value("notifyDead Calls", probe.notify_calls)
    value(
        "Processed-Dead Fallback Calls",
        probe.processed_dead_calls
    )
    value(
        "Fallback Recorded Deaths",
        probe.fallback_recorded_calls
    )
    value("Recorded Deaths", probe.recorded_calls)
    value("Duplicate Calls", probe.duplicate_calls)
    value("Context Scan Failures", probe.context_scan_failures)
    value("Last Record Error", probe.last_record_error)

    imgui.separator()

    value("Last Event", probe.last_event)
    value("CharacterKindID", probe.last_kind_id)
    value("Concrete Context Type", probe.last_context_type)
    value("Spawner ID", probe.last_spawn_id)
    value("Stage ID", probe.last_stage_id)
    value("Segment ID", probe.last_segment_id)
    value("Game Rank Add", probe.last_game_rank_add)
    value("Item Drop Count", probe.last_item_drop_count)
    value("Strong Individual", probe.last_strong_individual)
    value("True Dead", probe.last_is_true_dead)
    value("Eliminated", probe.last_is_eliminated)
    value("Processed On Dead", probe.last_is_processed_on_dead)
    value("Character Parameter Type", probe.last_character_parameter_type)
    value("Character Parameter Ptr", probe.last_character_parameter_ptr)
    value("Parameter Signature", probe.last_parameter_signature)
    value("Runtime Fingerprint", probe.last_runtime_fingerprint)
    value("Classifier Match", probe.last_classifier_match)
    value("Classifier Family", probe.last_classifier_family)
    value("Classifier Source", probe.last_classifier_source)
    value("Classifier Status", classifier.last_status)

    if imgui.button("Reload Runtime Classifier") then
        classifier.load()
    end

    imgui.separator()

    if imgui.tree_node("BioRand Seed Manifest") then
        if
            biorand_manifest.loaded ~= true and
            biorand_manifest.load_attempted ~= true
        then
            biorand_manifest.load()
        end
        value("Opened Log Path", biorand_manifest.source_path)
        value("Loaded", biorand_manifest.loaded)
        value("Seed", biorand_manifest.seed)
        value("Campaign", biorand_manifest.campaign)
        value("Enemy Records", #biorand_manifest.records)
        value("Status", biorand_manifest.last_status)
        value("Error", biorand_manifest.last_error)

        if imgui.button("Reload BioRand output_leon.log") then
            biorand_manifest.load()
        end

        imgui.text(
            "The manifest loads automatically on the first enemy death."
        )

        imgui.text(
            "Place the active seed log at reframework/data/project_overflow/biorand/output_leon.log"
        )

        imgui.tree_pop()
    end

    imgui.separator()

    local changed

    changed,
    rewards.award_xp_enabled =
        imgui.checkbox(
            "Award Enemy XP",
            rewards.award_xp_enabled == true
        )

    changed,
    rewards.roll_loot_enabled =
        imgui.checkbox(
            "Roll Logical Loot",
            rewards.roll_loot_enabled == true
        )

    value("Resolved Rewards", rewards.resolved_count)
    value("Awarded XP Total", rewards.awarded_xp_total)

    if rewards.last ~= nil and imgui.tree_node("Last Reward Resolution") then
        local last = rewards.last

        value("Name", last.display_name)
        value("Family", last.family)
        value("Database Fallback", last.used_fallback)
        value("Elite Tier", last.elite_name)
        value("Base XP", last.base_xp)
        value(
            "Fixed Final XP",
            last.fixed_xp ~= nil
            and last.fixed_xp
            or "none"
        )
        value("Appearance Overrides", last.appearance_rpg_overrides)
        value("Forced Tier", last.forced_elite_tier)
        value("XP Multiplier", last.xp_multiplier)
        value("Final XP", last.final_xp)
        value(
            "Reward Classification Source",
            last.classification_source or "database/native fallback"
        )
        value(
            "BioRand Seed",
            last.biorand_seed or "none"
        )
        value("XP Awarded", last.xp_awarded)
        value("Loot Table", last.loot_table)

        if imgui.tree_node("Rolled Loot") then
            if #last.loot == 0 then
                imgui.text("No logical loot rolled.")
            else
                for _, item in ipairs(last.loot) do
                    value(item.id, item.count)
                end
            end

            imgui.tree_pop()
        end

        imgui.tree_pop()
    end

    if imgui.tree_node("Elite Tier Chances") then
        for profile_name, profile in pairs(elites.profiles()) do
            imgui.separator()
            imgui.text(profile_name)

            for _, option in ipairs(profile) do
                value(
                    option.id,
                    string.format("%.1f%%", option.chance * 100.0)
                )
            end
        end

        imgui.tree_pop()
    end

    if imgui.tree_node("Enemy Database") then
        local fallback = database.fallback()
        local stats = database.stats()

        value("Native IDs Registered", stats.total)
        value("Enemies Identified", stats.identified)
        value("Enemies Unidentified", stats.unidentified)
        value(
            "Discovery Completion",
            string.format("%.1f%%", stats.percent)
        )
        value("Database File", database.save_path)
        value("Database Status", database.last_status)
        value("Fallback XP", fallback.base_xp)

        value("Database Revision", database.revision)
        value(
            "Last Reload Clock",
            string.format("%.3f", database.last_load_clock or 0.0)
        )

        if imgui.button("Reload Enemy Database From Disk") then
            database.reload()
            enemies_ui.editors = {}
            enemies_ui.database_revision = database.revision
        end

        if imgui.tree_node("Appearance Records Summary") then
            for kind_id, _ in pairs(database.catalog()) do
                local groups = database.appearances(kind_id)

                if #groups > 0 then
                    imgui.separator()
                    value("CharacterKindID", kind_id)

                    for _, group in ipairs(groups) do
                        value(
                            tostring(group.description),
                            tostring(#(group.enemy_ids or {})) ..
                            " ID(s)"
                        )
                    end
                end
            end

            imgui.tree_pop()
        end

        imgui.tree_pop()
    end

    if imgui.tree_node("Discovered Enemy Records") then
        if #registry.discovered_order == 0 then
            imgui.text(
                "Kill an enemy after installing the native hook."
            )
        else
            for _, key in ipairs(registry.discovered_order) do
                local entry =
                    registry.discovered[key]

                local snapshot =
                    entry.last_snapshot or {}

                imgui.separator()
                value("Database Key", entry.key)
                value("CharacterKindID", entry.kind_id)
                value("Raw Kind Value", entry.kind_id_raw)
                value("Context Type", entry.context_type)
                value(
                    "Downstream Error",
                    entry.last_downstream_error or ""
                )

                local native_definition =
                    database.get(entry.kind_id)

                local definition =
                    database.get_appearance(
                        entry.kind_id,
                        entry.spawn_id
                    )

                value("Record Key", entry.key)
                value("Internal ID", native_definition.internal_id or "unregistered")
                value("Native Pool Name", native_definition.display_name)
                value("Native Pool Family", native_definition.family)
                value("Appearance ID", entry.spawn_id)
                value("Appearance Group", definition.description)
                value("Effective Display Name", definition.display_name)
                value("Effective Family", definition.family)
                value("IDs In Group", definition.appearance_group_size)
                value("Effective Base XP", definition.base_xp)
                value(
                    "Fixed Final XP",
                    definition.fixed_xp ~= nil
                    and definition.fixed_xp
                    or "inherit multiplier calculation"
                )
                value("Effective Loot Table", definition.loot_table)
                value("Effective Elite Profile", definition.elite_profile)
                value(
                    "Forced Elite Tier",
                    definition.forced_elite_tier or "inherit"
                )

                local fingerprint =
                    entry.last_snapshot ~= nil
                    and entry.last_snapshot.runtime_fingerprint
                    or entry.runtime_fingerprint
                    or "unresolved"

                local classification =
                    entry.last_snapshot ~= nil
                    and entry.last_snapshot.runtime_classification
                    or entry.runtime_classification

                value("Runtime Fingerprint", fingerprint)

                local position =
                    snapshot.world_position or {}

                value(
                    "World Position",
                    string.format(
                        "%.2f, %.2f, %.2f",
                        tonumber(position.x) or 0,
                        tonumber(position.y) or 0,
                        tonumber(position.z) or 0
                    )
                )

                local manifest_result =
                    snapshot.biorand_manifest_result
                    or entry.biorand_manifest_result

                if manifest_result ~= nil then
                    value(
                        "Manifest Match",
                        manifest_result.matched == true
                    )
                    value(
                        "Manifest Source",
                        manifest_result.source or "unknown"
                    )
                    value(
                        "Manifest Distance",
                        manifest_result.match_distance
                        or manifest_result.nearest_distance
                        or "n/a"
                    )

                    if manifest_result.manifest_record ~= nil then
                        value(
                            "BioRand Family",
                            manifest_result.manifest_record.family
                        )
                        value(
                            "BioRand Spawn",
                            manifest_result.manifest_record.spawn_name
                        )
                        value(
                            "BioRand Scene",
                            manifest_result.manifest_record.scene
                        )
                    end
                end

                value(
                    "Auto-Classified",
                    classification ~= nil and
                    classification.matched == true
                )

                if classification ~= nil then
                    value(
                        "Classifier Result",
                        classification.family or "unknown"
                    )
                    value(
                        "Classifier Source",
                        classification.source or "unresolved"
                    )
                end

                if
                    type(definition.appearance_enemy_ids) == "table" and
                    #definition.appearance_enemy_ids > 0
                then
                    value(
                        "Grouped Enemy IDs",
                        table.concat(
                            definition.appearance_enemy_ids,
                            ", "
                        )
                    )
                end

                if imgui.tree_node(
                    "Edit Native Pool Defaults##" ..
                    tostring(entry.kind_id)
                ) then
                    local family_key =
                        "family|" .. tostring(entry.kind_id)

                    if enemies_ui.editors[family_key] == nil then
                        enemies_ui.editors[family_key] = {
                            display_name =
                                tostring(native_definition.display_name or ""),
                            family =
                                tostring(native_definition.family or ""),
                            base_xp =
                                tonumber(native_definition.base_xp) or 10,
                            loot_table =
                                tostring(
                                    native_definition.loot_table
                                    or "enemy_standard"
                                ),
                            elite_profile =
                                tostring(
                                    native_definition.elite_profile
                                    or "standard"
                                ),
                            identified =
                                native_definition.identified == true,
                            status = ""
                        }
                    end

                    local family_editor =
                        enemies_ui.editors[family_key]

                    local changed

                    changed,
                    family_editor.display_name =
                        imgui.input_text(
                            "Display Name##" .. family_key,
                            family_editor.display_name
                        )

                    changed,
                    family_editor.family =
                        imgui.input_text(
                            "Family##" .. family_key,
                            family_editor.family
                        )

                    changed,
                    family_editor.base_xp =
                        imgui.drag_int(
                            "Base XP##" .. family_key,
                            family_editor.base_xp,
                            1,
                            0,
                            100000
                        )

                    changed,
                    family_editor.loot_table =
                        imgui.input_text(
                            "Loot Table##" .. family_key,
                            family_editor.loot_table
                        )

                    changed,
                    family_editor.elite_profile =
                        imgui.input_text(
                            "Elite Profile##" .. family_key,
                            family_editor.elite_profile
                        )

                    changed,
                    family_editor.identified =
                        imgui.checkbox(
                            "Identified##" .. family_key,
                            family_editor.identified == true
                        )

                    if imgui.button(
                        "Save Native Pool Defaults##" .. family_key
                    ) then
                        local ok, error_text =
                            database.update(
                                entry.kind_id,
                                {
                                    display_name =
                                        family_editor.display_name,
                                    family =
                                        family_editor.family,
                                    base_xp =
                                        family_editor.base_xp,
                                    loot_table =
                                        family_editor.loot_table,
                                    elite_profile =
                                        family_editor.elite_profile,
                                    identified =
                                        family_editor.identified
                                },
                                true
                            )

                        family_editor.status =
                            ok and "Saved native pool defaults."
                            or tostring(error_text)
                    end

                    value("Native Pool Editor Status", family_editor.status)
                    imgui.tree_pop()
                end

                if imgui.tree_node(
                    "Edit Appearance Group##" ..
                    tostring(key)
                ) then
                    local editor =
                        get_editor(
                            entry.kind_id,
                            entry.spawn_id
                        )

                    local changed

                    changed,
                    editor.description =
                        imgui.input_text(
                            "Description##" .. tostring(key),
                            editor.description
                        )

                    changed,
                    editor.override_rpg =
                        imgui.checkbox(
                            "Override Family RPG Settings##" ..
                            tostring(key),
                            editor.override_rpg == true
                        )

                    if editor.override_rpg == true then
                        imgui.text(
                            "These settings apply only to this appearance group."
                        )

                        changed,
                        editor.display_name_override =
                            imgui.input_text(
                                "Display Name Override##" ..
                                tostring(key),
                                editor.display_name_override
                            )

                        changed,
                        editor.family_override =
                            imgui.input_text(
                                "Family Override##" ..
                                tostring(key),
                                editor.family_override
                            )

                        changed,
                        editor.identified_override =
                            imgui.checkbox(
                                "Identified Override##" ..
                                tostring(key),
                                editor.identified_override == true
                            )

                        changed,
                        editor.base_xp_override =
                            imgui.drag_int(
                                "Base XP Override##" .. tostring(key),
                                editor.base_xp_override,
                                1,
                                0,
                                100000
                            )

                        changed,
                        editor.fixed_xp =
                            imgui.drag_int(
                                "Fixed Final XP (-1 = calculated)##" ..
                                tostring(key),
                                editor.fixed_xp,
                                1,
                                -1,
                                100000
                            )

                        changed,
                        editor.loot_table_override =
                            imgui.input_text(
                                "Loot Table Override##" ..
                                tostring(key),
                                editor.loot_table_override
                            )

                        changed,
                        editor.elite_profile_override =
                            imgui.input_text(
                                "Elite Profile Override##" ..
                                tostring(key),
                                editor.elite_profile_override
                            )

                        changed,
                        editor.forced_elite_tier =
                            imgui.input_text(
                                "Forced Tier##" ..
                                tostring(key),
                                editor.forced_elite_tier
                            )

                        imgui.text(
                            "Forced Tier: inherit, normal, champion, elite, legendary, or boss."
                        )
                    end

                    if imgui.button(
                        "Save Appearance Group##" ..
                        tostring(key)
                    ) then
                        local values = {
                            description = editor.description
                        }

                        if editor.override_rpg == true then
                            values.display_name_override =
                                editor.display_name_override

                            values.family_override =
                                editor.family_override

                            values.identified_override =
                                editor.identified_override

                            values.base_xp_override =
                                editor.base_xp_override

                            values.fixed_xp =
                                editor.fixed_xp >= 0
                                and editor.fixed_xp
                                or -1

                            values.loot_table_override =
                                editor.loot_table_override

                            values.elite_profile_override =
                                editor.elite_profile_override

                            values.forced_elite_tier =
                                editor.forced_elite_tier
                        else
                            values.clear_rpg_overrides = true
                        end

                        local ok, error_text =
                            database.update_appearance(
                                entry.kind_id,
                                entry.spawn_id,
                                values,
                                true
                            )

                        editor.status =
                            ok and "Saved appearance group."
                            or tostring(error_text)
                    end

                    value("Description Status", editor.status)

                    if imgui.button(
                        "Learn Classifier From This Enemy##" ..
                        tostring(key)
                    ) then
                        local effective =
                            database.get_appearance(
                                entry.kind_id,
                                entry.spawn_id
                            )

                        local ok, status =
                            classifier.learn(
                                fingerprint,
                                {
                                    description =
                                        editor.description,
                                    display_name =
                                        editor.display_name_override,
                                    family =
                                        editor.family_override,
                                    base_xp =
                                        editor.base_xp_override,
                                    fixed_xp =
                                        editor.fixed_xp >= 0
                                        and editor.fixed_xp
                                        or nil,
                                    loot_table =
                                        editor.loot_table_override,
                                    elite_profile =
                                        editor.elite_profile_override,
                                    forced_elite_tier =
                                        editor.forced_elite_tier
                                }
                            )

                        editor.status =
                            ok
                            and status
                            or tostring(status)
                    end

                    imgui.text(
                        "Confirm the enemy fields first, then learn its fingerprint."
                    )

                    if definition.appearance_group_size > 1 then
                        imgui.text(
                            "Renaming this merged appearance updates every enemy_id listed above."
                        )
                    else
                        imgui.text(
                            "This runtime enemy_id is isolated until deliberately merged."
                        )
                    end

                    imgui.tree_pop()
                end

                value("Kills", entry.kills)
                value("Stages", set_values_text(entry.stage_ids))
                value("Segments", set_values_text(entry.segment_ids))

                if entry.last_reward ~= nil then
                    value("Resolved Enemy Name", entry.last_reward.display_name)
                    value(
                        "Appearance Description",
                        entry.last_reward.description or "Unknown Model"
                    )
                    value("Elite", entry.last_reward.elite_name)
                    value("XP Value", entry.last_reward.final_xp)
                    value("Loot Table", entry.last_reward.loot_table)
                end

                if imgui.tree_node(
                    "Last Native Snapshot##" ..
                    tostring(key)
                ) then
                    value("Context Ptr", snapshot.context_ptr)
                    value("Context Arg", snapshot.context_arg)
                    value("HitPoint Type", snapshot.hitpoint_type)
                    value("Vital Type", snapshot.vital_type)
                    value("Weak Points Alive", snapshot.weak_point_count)
                    value("Strong Individual", snapshot.is_strong_individual)
                    value("True Dead", snapshot.is_true_dead)
                    value("Eliminated", snapshot.is_eliminated)
                    value("Processed On Dead", snapshot.is_processed_on_dead)
                    value("Game Rank Add", snapshot.game_rank_add)
                    value("Item Drop Count", snapshot.item_drop_count)
                    value("Spawn Param Type", snapshot.spawn_param_type)
                    value("Spawn Segment", snapshot.spawn_segment_id)
                    value("Spawn Rank Add", snapshot.spawn_game_rank_add)
                    value("Drop Item ID", snapshot.drop_item_id)
                    value("Drop Item Count", snapshot.drop_item_count)
                    value("Character Parameter Type", snapshot.character_parameter_type)
                    value("Character Parameter Ptr", snapshot.character_parameter_ptr)
                    value("Parameter Signature", snapshot.character_parameter_signature)

                    if imgui.tree_node(
                        "Targeted Costume Snapshot##" ..
                        tostring(key)
                    ) then
                        draw_costume_snapshot(
                            snapshot.costume_snapshot,
                            tostring(key)
                        )

                        imgui.tree_pop()
                    end

                    if imgui.tree_node(
                        "Reflection Inspector##" ..
                        tostring(key)
                    ) then
                        if imgui.tree_node(
                            "CharacterParameter##reflection_" ..
                            tostring(key)
                        ) then
                            draw_reflection_snapshot(
                                snapshot.character_parameter_reflection,
                                "character_" .. tostring(key)
                            )

                            imgui.tree_pop()
                        end

                        if imgui.tree_node(
                            "CharacterSpawnParam##reflection_" ..
                            tostring(key)
                        ) then
                            draw_reflection_snapshot(
                                snapshot.spawn_parameter_reflection,
                                "spawn_" .. tostring(key)
                            )

                            imgui.tree_pop()
                        end

                        imgui.tree_pop()
                    end

                    if imgui.tree_node(
                        "Character Parameter Values##" ..
                        tostring(key)
                    ) then
                        local values =
                            snapshot.character_parameter_values
                            or {}

                        if #values == 0 then
                            imgui.text(
                                "No whitelisted weapon, equipment, costume, or variant members resolved."
                            )
                        else
                            for _, entry in ipairs(values) do
                                value(entry.source, entry.value)
                            end
                        end

                        imgui.tree_pop()
                    end

                    imgui.tree_pop()
                end
            end
        end

        imgui.tree_pop()
    end

    if imgui.tree_node("Recent Deaths (Last 10)") then
        for _, event in ipairs(registry.kill_history) do
            local snapshot =
                type(event.snapshot) == "table"
                and event.snapshot
                or event

            local reward =
                type(event.reward) == "table"
                and event.reward
                or {}

            local stage_id =
                snapshot.stage_id
                or snapshot.stage
                or "unknown"

            local segment_id =
                snapshot.spawn_segment_id
                or snapshot.segment_id
                or snapshot.segment
                or "unknown"

            imgui.separator()

            value(
                "Kill",
                event.id
                or event.index
                or "unknown"
            )

            value(
                "Key",
                event.observation_key
                or event.key
                or "unknown"
            )

            value(
                "CharacterKindID",
                snapshot.kind_id
                or snapshot.kind_id_raw
                or "unknown"
            )

            value(
                "Context",
                snapshot.context_type
                or "unknown"
            )

            value(
                "Stage / Segment",
                tostring(stage_id)
                .. " / "
                .. tostring(segment_id)
            )

            value(
                "Spawner ID",
                snapshot.spawn_id
                or "unknown"
            )

            value(
                "Game Rank Add",
                snapshot.game_rank_add
                or reward.game_rank_add
                or "unknown"
            )

            value(
                "Strong Individual",
                snapshot.strong_individual ~= nil
                and snapshot.strong_individual
                or "unknown"
            )

            value(
                "Weak Points Alive",
                snapshot.weak_point_count
                or "unknown"
            )

            value(
                "Method",
                snapshot.source_method
                or event.source_method
                or "unknown"
            )

            value(
                "Completed",
                event.completed == true
            )
        end

        imgui.tree_pop()
    end

    if imgui.button("Clear Enemy Discovery Data") then
        registry.clear()
    end

    imgui.tree_pop()
end

return enemies_ui
