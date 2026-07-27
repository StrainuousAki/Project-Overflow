------------------------------------------------------------
-- Project: Overflow — Debug and recovery controls
--
-- Direct HP, Max HP, XP, and profile-recovery tools live here. These controls
-- are intentionally manual; normal progression continues to save alongside
-- Resident Evil 4 through the native profile synchronization system.
------------------------------------------------------------


local rpg = require("project_overflow.systems.player.rpg")
local stat_application =
    require("project_overflow.systems.player.stat_application")

local cheats = {
    xp_amount = 100,
    set_xp = 0,
    recovery_slot = 0
}

local function value(label, content)
    imgui.text(label .. " : " .. tostring(content))
end

local function button_row(a, b, c)
    local pressed = nil
    if imgui.button(a) then pressed = a end
    if b ~= nil then
        imgui.same_line()
        if imgui.button(b) then pressed = b end
    end
    if c ~= nil then
        imgui.same_line()
        if imgui.button(c) then pressed = c end
    end
    return pressed
end

local function draw_hp(ctx, hp)
    if not imgui.tree_node("HP Controls") then return end
    local changed
    changed, ctx.ui.hp_amount =
        imgui.drag_int("HP Amount", ctx.ui.hp_amount, 1, 1, 5000)
    ctx.ui.hp_amount = ctx.clamp(ctx.ui.hp_amount, 1, 5000)
    local pressed = button_row("Heal", "Damage", "Full Heal")
    if pressed == "Heal" then hp.heal(ctx, ctx.ui.hp_amount) end
    if pressed == "Damage" then hp.damage(ctx, ctx.ui.hp_amount) end
    if pressed == "Full Heal" then hp.full_heal(ctx) end
    changed, ctx.ui.set_current_hp = imgui.drag_int(
        "Set Current HP", ctx.ui.set_current_hp, 1, 1, ctx.active_total_cap())
    if imgui.button("Apply Current HP") then
        hp.set_current(ctx, ctx.ui.set_current_hp)
    end
    imgui.tree_pop()
end

local function draw_max_hp(ctx, hp)
    if not imgui.tree_node("Max HP Controls") then return end
    local changed
    changed, ctx.ui.max_hp_amount =
        imgui.drag_int("Max HP Amount", ctx.ui.max_hp_amount, 1, 1, 5000)
    ctx.ui.max_hp_amount = ctx.clamp(ctx.ui.max_hp_amount, 1, 5000)
    local pressed = button_row("Add Max HP", "Remove Max HP")
    if pressed == "Add Max HP" then hp.add_max(ctx, ctx.ui.max_hp_amount) end
    if pressed == "Remove Max HP" then hp.add_max(ctx, -ctx.ui.max_hp_amount) end
    changed, ctx.ui.set_max_hp = imgui.drag_int(
        "Set Max HP", ctx.ui.set_max_hp, 1,
        ctx.state.min_custom_max_hp, ctx.active_total_cap())
    if imgui.button("Apply Max HP") then hp.set_max(ctx, ctx.ui.set_max_hp) end
    local reset = button_row("Reset Default", "Reset Vanilla Cap")
    if reset == "Reset Default" then hp.reset_default(ctx) end
    if reset == "Reset Vanilla Cap" then hp.reset_vanilla(ctx) end
    imgui.tree_pop()
end

local function draw_xp()
    if not imgui.tree_node("XP Controls") then return end
    local changed
    changed, cheats.xp_amount = imgui.drag_int(
        "XP Amount", cheats.xp_amount, 1, 1, 1000000)
    if imgui.button("Add XP") then rpg.add_experience(cheats.xp_amount) end
    imgui.same_line()
    if imgui.button("Remove XP") then rpg.remove_experience(cheats.xp_amount) end
    changed, cheats.set_xp = imgui.drag_int(
        "Set Current XP", cheats.set_xp, 1, 0, 1000000)
    if imgui.button("Set XP") then rpg.set_experience(cheats.set_xp) end
    imgui.same_line()
    if imgui.button("Reset Current XP") then
        rpg.set_experience(0)
        cheats.set_xp = 0
    end
    if imgui.button("Add XP Required for Next Level") then
        rpg.add_experience(rpg.required_xp())
    end
    imgui.same_line()
    if imgui.button("Force Level Up") then rpg.force_level() end
    value("Current XP", rpg.profile().experience)
    value("Next Level Requirement", rpg.required_xp())
    value("Last Levels Gained", rpg.last_levels_gained)
    imgui.tree_pop()
end

local function draw_profile_tools(ctx, hp)
    if not imgui.tree_node("Emergency RPG Profile Tools") then return end

    local active_campaign =
        rpg.active_campaign ~= nil
        and rpg.active_campaign()
        or nil

    local campaign_label =
        active_campaign == "separate_ways"
        and "Separate Ways (Ada)"
        or (
            active_campaign == "leon"
            and "Main Campaign (Leon)"
            or "Unresolved"
        )

    value("Detected Active Campaign", campaign_label)
    value(
        "Active RPG Identity",
        rpg.active_save_identity ~= nil
        and (rpg.active_save_identity() or "none")
        or "none"
    )

    if active_campaign == nil then
        imgui.text(
            "Campaign unresolved. Slot binding and profile save/load tools are hidden."
        )
        imgui.tree_pop()
        return
    end

    imgui.text(
        active_campaign == "separate_ways"
        and "Ada campaign recovery tools only."
        or "Leon campaign recovery tools only."
    )
    imgui.text("Cheat/recovery tools only. Normal progression saves with RE4.")
    local profile = rpg.profile()
    if imgui.button("Add Attribute Point") then
        profile.attribute_points = profile.attribute_points + 1
        rpg.last_message = "Added one attribute point."
    end
    -- Native game-save synchronization is the only automatic persistence
    -- path. Keep the old change-autosave capability disabled.
    rpg.autosave_on_change = false
    local save_label =
        active_campaign == "separate_ways"
        and "Save Ada RPG Profile"
        or "Save Leon RPG Profile"

    local load_label =
        active_campaign == "separate_ways"
        and "Load Ada RPG Profile"
        or "Load Leon RPG Profile"

    if imgui.button(save_label) then rpg.save() end
    imgui.same_line()
    if imgui.button(load_label) then rpg.load() end
    if imgui.button("Reset RPG Profile") then
        stat_application.remove_vitality(ctx, hp)
        rpg.reset()
    end
    if imgui.button("Reset Vitality HP Tracking") then
        stat_application.reset_tracking()
    end
    imgui.separator()
    imgui.text(
        active_campaign == "separate_ways"
        and "Ada RPG Profile Slot Recovery"
        or "Leon RPG Profile Slot Recovery"
    )
    imgui.text(
        active_campaign == "separate_ways"
        and "Bind/load only the Separate Ways RPG profile for the selected Ada save slot."
        or "Bind/load only the main-campaign RPG profile for the selected Leon save slot."
    )
    imgui.text(
        active_campaign == "separate_ways"
        and "Slot 0 = Autosave; slots 1-10 = Separate Ways manual saves."
        or "Slot 0 = Autosave; slots 1-20 = Leon manual saves."
    )

    local changed
    local recovery_slot_limit =
        rpg.manual_save_slot_limit ~= nil
        and rpg.manual_save_slot_limit(active_campaign)
        or (
            active_campaign == "separate_ways"
            and 10
            or 20
        )

    changed,
    cheats.recovery_slot =
        imgui.drag_int(
            active_campaign == "separate_ways"
            and "Ada RPG Profile Save Slot"
            or "Leon RPG Profile Save Slot",
            cheats.recovery_slot,
            1,
            0,
            recovery_slot_limit
        )

    cheats.recovery_slot =
        math.max(
            0,
            math.min(
                recovery_slot_limit,
                cheats.recovery_slot
            )
        )

    local recovery_key =
        cheats.recovery_slot == 0
        and "autosave"
        or cheats.recovery_slot

    value(
        active_campaign == "separate_ways"
        and "Ada Profile Recovery Target"
        or "Leon Profile Recovery Target",
        cheats.recovery_slot == 0
        and "Autosave"
        or string.format(
            "Manual Slot %02d",
            cheats.recovery_slot
        )
    )

    value(
        active_campaign == "separate_ways"
        and "Current Ada Active Slot"
        or "Current Leon Active Slot",
        rpg.active_save_slot() or "none"
    )

    local bind_label =
        active_campaign == "separate_ways"
        and "Bind and Load This Ada RPG Slot"
        or "Bind and Load This Leon RPG Slot"

    if imgui.button(bind_label) then
        if
            rpg.select_save_slot(
                recovery_key,
                true,
                active_campaign
            )
        then
            stat_application.reset_tracking()
        end
    end
    value("Save Path", rpg.save_path())
    imgui.tree_pop()
end

function cheats.draw(ctx, hp)
    -- This is visibility only. Runtime RPG systems and native hooks are
    -- initialized by project_overflow.lua and never depend on this tree.
    if not imgui.tree_node("Cheats") then return end
    draw_hp(ctx, hp)
    draw_max_hp(ctx, hp)
    draw_xp()
    draw_profile_tools(ctx, hp)
    imgui.tree_pop()
end

return cheats
