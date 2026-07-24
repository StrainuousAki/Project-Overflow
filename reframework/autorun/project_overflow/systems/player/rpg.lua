------------------------------------------------------------
-- Maintenance classification — Build 49.39
-- Module: autorun/project_overflow/systems/player/rpg.lua
-- Role: Player RPG profile, attributes, saves, experience, and stat application.
-- Status: active subsystem.
--
-- Compatibility policy:
--   Existing functions, hooks, module paths, and diagnostics are
--   intentionally retained in this maintenance pass.
--   `DEPRECATED` marks a supported legacy path, not removed code.
------------------------------------------------------------

------------------------------------------------------------
-- Project: Overflow — RPG Foundation
--
-- Coordinates the profile, XP, leveling, derived stats, and save
-- data. UI and future gameplay hooks can use this single module.
------------------------------------------------------------

local player_profile =
    require("project_overflow.systems.player.profile")
local stats =
    require("project_overflow.systems.player.stats")
local experience =
    require("project_overflow.systems.player.experience")
local leveling =
    require("project_overflow.systems.player.leveling")
local save_data =
    require("project_overflow.systems.player.save_data")

local rpg = {
    last_message = "RPG profile ready.",
    last_levels_gained = 0,
    autosave_on_change = false
}

local function profile()
    return player_profile.get()
end

local function save_if_enabled()
    if rpg.autosave_on_change ~= true then
        return
    end

    rpg.save()
end

function rpg.profile()
    return profile()
end

function rpg.derived_stats()
    return stats.calculate(profile())
end

function rpg.required_xp()
    return experience.required_for_level(
        profile().level
    )
end

function rpg.progress_ratio()
    return experience.progress_ratio(
        profile()
    )
end

function rpg.add_experience(amount)
    experience.add(profile(), amount)

    rpg.last_levels_gained =
        leveling.process(profile())

    if rpg.last_levels_gained > 0 then
        rpg.last_message =
            "Level up! Gained " ..
            tostring(rpg.last_levels_gained) ..
            " level(s)."
    else
        rpg.last_message =
            "Added " ..
            tostring(math.floor(tonumber(amount) or 0)) ..
            " XP."
    end

    save_if_enabled()

    return rpg.last_levels_gained
end

function rpg.set_experience(amount)
    local data = profile()
    data.experience = math.max(
        0,
        math.floor(tonumber(amount) or 0)
    )

    rpg.last_levels_gained = leveling.process(data)
    if rpg.last_levels_gained > 0 then
        rpg.last_message =
            "Set XP and gained " ..
            tostring(rpg.last_levels_gained) ..
            " level(s)."
    else
        rpg.last_message =
            "Set current XP to " ..
            tostring(data.experience) .. "."
    end

    save_if_enabled()
    return data.experience
end

function rpg.remove_experience(amount)
    local data = profile()
    local removed = math.max(
        0,
        math.floor(tonumber(amount) or 0)
    )
    data.experience = math.max(
        0,
        (tonumber(data.experience) or 0) - removed
    )
    rpg.last_levels_gained = 0
    rpg.last_message =
        "Removed " .. tostring(removed) .. " XP."
    save_if_enabled()
    return data.experience
end

function rpg.force_level()
    rpg.last_levels_gained =
        leveling.force_level(profile())

    rpg.last_message =
        "Forced " ..
        tostring(rpg.last_levels_gained) ..
        " level(s)."

    save_if_enabled()
end

function rpg.spend_attribute_point(attribute_name)
    local ok, error_text =
        player_profile.add_attribute_point(
            attribute_name,
            1
        )

    if ok then
        rpg.last_message =
            "Increased " ..
            tostring(attribute_name) ..
            "."
        save_if_enabled()
    else
        rpg.last_message = error_text
    end

    return ok
end

-- Cheat/debug counterpart to spend_attribute_point. Keep the real attribute
-- floor at one and return the removed point to the unspent pool.
function rpg.refund_attribute_point(attribute_name)
    local data = profile()
    local attributes = data.attributes or {}
    local current = tonumber(attributes[attribute_name])
    if current == nil then
        rpg.last_message = "Unknown attribute: " .. tostring(attribute_name)
        return false
    end
    if current <= 1 then
        rpg.last_message = tostring(attribute_name) .. " is already at its base value."
        return false
    end
    attributes[attribute_name] = current - 1
    data.attribute_points = (tonumber(data.attribute_points) or 0) + 1
    rpg.last_message = "Refunded one " .. tostring(attribute_name) .. " point."
    return true
end

function rpg.save_silent()
    local ok, error_text = save_data.save(profile())
    return ok == true, error_text
end

-- Native save callbacks capture a detached profile snapshot. This prevents a
-- load/slot transition occurring a few frames later from changing the table
-- that belongs to the completed native save.
function rpg.save_profile_silent(snapshot)
    local ok, error_text = save_data.save(snapshot or profile())
    return ok == true, error_text
end

function rpg.save()
    local ok, error_text =
        save_data.save(profile())

    rpg.last_message =
        ok
        and "RPG profile saved."
        or "Save failed: " .. tostring(error_text)

    return ok
end

function rpg.load()
    local loaded, error_text =
        save_data.load()

    if loaded == nil then
        rpg.last_message =
            "Load failed: " .. tostring(error_text)
        return false
    end

    player_profile.replace(loaded)
    rpg.last_message = "RPG profile loaded."

    return true
end

function rpg.peek_save_slot(slot_key)
    return save_data.load(slot_key)
end

function rpg.reset()
    player_profile.reset()
    rpg.last_levels_gained = 0
    rpg.last_message = "RPG profile reset."
    save_if_enabled()
end

function rpg.save_path()
    return save_data.path()
end

function rpg.active_save_slot()
    return save_data.active_slot()
end

function rpg.record_native_save_event(slot_key, operation, raw_slot)
    return save_data.record_native_event(slot_key, operation, raw_slot)
end

function rpg.active_save_record()
    return save_data.active_record()
end

function rpg.select_save_slot(slot_key, load_profile)
    local ok, error_text = save_data.set_active_slot(slot_key)
    if not ok then
        rpg.last_message = tostring(error_text)
        return false
    end
    if load_profile == true then
        local loaded, load_error = save_data.load()
        if loaded ~= nil then
            player_profile.replace(loaded)
            rpg.campaign_initialized = true
            rpg.campaign_initialization_status =
                "loaded native RPG slot "
                .. tostring(save_data.active_slot())
            rpg.last_message = "Loaded RPG profile for " .. tostring(save_data.active_slot()) .. "."
            return true
        end
        -- A new/empty game slot receives fresh progression, never another slot's data.
        player_profile.reset()
        rpg.last_levels_gained = 0
        rpg.last_message = "Started fresh RPG profile for " ..
            tostring(save_data.active_slot()) .. ": " .. tostring(load_error)
    end
    return true
end

function rpg.clear_save_slot()
    save_data.clear_active_slot()
    player_profile.reset()
    rpg.last_levels_gained = 0
    rpg.campaign_initialized = false
    rpg.campaign_initialization_status =
        "Defaults restored; waiting for native character save initialization."
    rpg.last_message = "Native save slot cleared; progression is isolated."
end

function rpg.mark_campaign_initialized(source)
    rpg.campaign_initialized = true
    rpg.campaign_initialization_status =
        tostring(source or "native save initialized")
end

return rpg
