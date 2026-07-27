------------------------------------------------------------
-- Maintenance classification — Build 49.39
-- Module: autorun/project_overflow/systems/player/stat_application.lua
-- Role: Player RPG profile, attributes, saves, experience, and stat application.
-- Status: active subsystem.
--
-- Compatibility policy:
--   Existing functions, hooks, module paths, and diagnostics are
--   intentionally retained in this maintenance pass.
--   `DEPRECATED` marks a supported legacy path, not removed code.
------------------------------------------------------------

------------------------------------------------------------
-- Project: Overflow — Player Stat Application
--
-- Applies RPG-derived values to native game systems while keeping
-- herb, item, and manual Max HP upgrades separate from Vitality.
--
-- A value is not recorded as applied until the native HitPoint object
-- confirms it. Failed writes no longer get mistaken for external Max HP
-- changes on the following frame.
------------------------------------------------------------

local rpg =
    require("project_overflow.systems.player.rpg")

local application = {
    suspended = false,
    initialized = false,
    base_max_hp = 0,
    desired_vitality_bonus = 0,
    applied_vitality_bonus = 0,
    expected_max_hp = 0,

    apply_count = 0,
    apply_failure_count = 0,
    rebase_count = 0,

    last_apply_succeeded = false,
    last_native_max_hp = 0,
    last_status = "Waiting for native Max HP.",
    dirty = true,
    last_profile_bonus = nil,
    last_player_pointer = "nil",
    last_audit_clock = 0.0,
    audit_interval = 1.0,
    skipped_update_count = 0
}

local function rounded(value)
    return math.floor((tonumber(value) or 0) + 0.5)
end

local function get_profile_health()
    local profile = rpg.profile()

    if type(profile.health) ~= "table" then
        profile.health = {
            base_max_hp = 0,
            applied_vitality_bonus = 0,
            last_effective_max_hp = 0
        }
    end

    return profile.health
end

local function persist()
    local health = get_profile_health()

    health.base_max_hp = application.base_max_hp
    health.applied_vitality_bonus =
        application.applied_vitality_bonus
    health.last_effective_max_hp =
        application.expected_max_hp

    -- Keep the snapshot in the in-memory RPG profile. Disk persistence is
    -- owned exclusively by the native game-save synchronization hook.
end

local function initialize(current_max_hp, desired_bonus)
    local saved = get_profile_health()

    local saved_base =
        rounded(saved.base_max_hp)

    local saved_bonus =
        rounded(saved.applied_vitality_bonus)

    local saved_effective =
        rounded(saved.last_effective_max_hp)

    -- Only trust persisted tracking when the live value agrees with it.
    if
        saved_base > 0 and
        saved_effective > 0 and
        current_max_hp == saved_effective
    then
        application.base_max_hp = saved_base
        application.applied_vitality_bonus = saved_bonus
        application.expected_max_hp = saved_effective
        application.last_apply_succeeded = true
    elseif
        saved_base > 0 and
        saved_bonus > 0 and
        saved_bonus ~= desired_bonus and
        current_max_hp == saved_base + desired_bonus
    then
        -- Migration for profiles damaged when Vitality HP-per-point changed.
        -- The old load path subtracted the stale saved bonus from a Max HP
        -- value that already contained the new bonus:
        --
        --   corrupted base = real base + new bonus - old bonus
        --
        -- Recover the real base without hard-coding 1260, preserving yellow
        -- herb and other legitimate native Max HP upgrades.
        local recovered_base =
            saved_base
            + saved_bonus
            - desired_bonus

        application.base_max_hp =
            math.max(
                1,
                recovered_base
            )

        application.applied_vitality_bonus = 0
        application.expected_max_hp = current_max_hp
        application.last_apply_succeeded = false

        application.last_status =
            string.format(
                "Migrating stale Vitality tracking: Base %d + old bonus %d - new bonus %d = %d.",
                saved_base,
                saved_bonus,
                desired_bonus,
                application.base_max_hp
            )
    else
        -- For unrelated or unverifiable mismatches, preserve native Max HP as
        -- the authoritative base.
        application.base_max_hp = current_max_hp
        application.applied_vitality_bonus = 0
        application.expected_max_hp = current_max_hp
        application.last_apply_succeeded = false
    end

    application.desired_vitality_bonus = desired_bonus
    application.last_native_max_hp = current_max_hp
    application.initialized = true
end

local function rebase_external_change(current_max_hp)
    if application.last_apply_succeeded ~= true then
        return false
    end

    if
        application.expected_max_hp <= 0 or
        current_max_hp == application.expected_max_hp
    then
        return false
    end

    application.base_max_hp =
        math.max(
            1,
            current_max_hp -
            application.applied_vitality_bonus
        )

    application.expected_max_hp = current_max_hp
    application.rebase_count =
        application.rebase_count + 1

    application.last_status =
        "External Max HP change detected; base Max HP updated."

    return true
end

function application.update(ctx, health_system)
    if application.suspended then
        application.last_status = "Suspended during native profile load."
        return false
    end
    local current_max_hp =
        rounded(ctx.max_hp_number())

    if current_max_hp <= 0 then
        application.last_status =
            "Waiting for native Max HP."
        return false
    end

    local desired_bonus =
        rounded(rpg.derived_stats().max_hp_bonus)

    local player_pointer =
        tostring(
            ctx.state.player ~= nil
            and ctx.ptr_from_obj(ctx.state.player)
            or "nil"
        )
    local now = os.clock()
    local profile_changed =
        application.last_profile_bonus ~= desired_bonus
    local player_changed =
        application.last_player_pointer ~= player_pointer
    local audit_due =
        now - application.last_audit_clock
        >= application.audit_interval

    if
        application.dirty ~= true
        and not profile_changed
        and not player_changed
        and not audit_due
    then
        application.skipped_update_count =
            application.skipped_update_count + 1
        return false
    end

    application.last_profile_bonus = desired_bonus
    application.last_player_pointer = player_pointer
    application.last_audit_clock = now
    application.dirty = false

    if not application.initialized then
        initialize(current_max_hp, desired_bonus)
    end

    local changed =
        rebase_external_change(current_max_hp)

    application.desired_vitality_bonus =
        desired_bonus

    local desired_max_hp =
        application.base_max_hp +
        desired_bonus

    if current_max_hp ~= desired_max_hp then
        local write_succeeded =
            health_system.set_max(
                ctx,
                desired_max_hp
            ) == true

        local verified_max_hp =
            rounded(ctx.max_hp_number())

        if
            write_succeeded and
            verified_max_hp == desired_max_hp
        then
            application.apply_count =
                application.apply_count + 1

            application.applied_vitality_bonus =
                desired_bonus

            application.expected_max_hp =
                desired_max_hp

            application.last_native_max_hp =
                verified_max_hp

            application.last_apply_succeeded =
                true

            application.last_status =
                string.format(
                    "Applied: Base %d + Vitality %d = %d Max HP.",
                    application.base_max_hp,
                    desired_bonus,
                    desired_max_hp
                )

            persist()
            return true
        end

        application.apply_failure_count =
            application.apply_failure_count + 1

        application.last_apply_succeeded =
            false

        application.last_native_max_hp =
            verified_max_hp

        application.last_status =
            string.format(
                "Vitality write failed: expected %d, native Max HP is %d.",
                desired_max_hp,
                verified_max_hp
            )

        return false
    end

    application.applied_vitality_bonus =
        desired_bonus

    application.expected_max_hp =
        desired_max_hp

    application.last_native_max_hp =
        current_max_hp

    application.last_apply_succeeded =
        true

    local saved = get_profile_health()

    if
        changed or
        rounded(saved.base_max_hp) ~= application.base_max_hp or
        rounded(saved.applied_vitality_bonus) ~= desired_bonus or
        rounded(saved.last_effective_max_hp) ~= desired_max_hp
    then
        persist()
    end

    application.last_status =
        string.format(
            "Applied: Base %d + Vitality %d = %d Max HP.",
            application.base_max_hp,
            desired_bonus,
            desired_max_hp
        )

    return changed
end

function application.begin_native_load()
    application.suspended = true
    application.last_status = "Suspended during native profile load."
end

function application.end_native_load()
    application.suspended = false
    application.dirty = true
    application.last_audit_clock = 0.0
end

function application.mark_dirty(reason)
    application.dirty = true
    application.last_audit_clock = 0.0
    application.last_status =
        "Vitality marked dirty: "
        .. tostring(reason or "unspecified")
end

function application.reset_tracking()
    application.initialized = false
    application.base_max_hp = 0
    application.desired_vitality_bonus = 0
    application.applied_vitality_bonus = 0
    application.expected_max_hp = 0
    application.last_native_max_hp = 0
    application.last_apply_succeeded = false
    application.dirty = true
    application.last_profile_bonus = nil
    application.last_player_pointer = "nil"
    application.last_audit_clock = 0.0
    application.last_status = "Tracking reset."
end

-- Remove only the Max HP previously contributed by Vitality. The live value
-- may also contain yellow-herb/item upgrades, so restoring a hard-coded
-- vanilla value would incorrectly erase legitimate progression.
function application.remove_vitality(ctx, health_system, explicit_bonus)
    if ctx == nil or health_system == nil then
        application.last_status = "Vitality rollback unavailable."
        return false
    end

    local current_max_hp = rounded(ctx.max_hp_number())
    local saved = get_profile_health()
    local applied_bonus = math.max(0, rounded(explicit_bonus))
    if explicit_bonus == nil then
        applied_bonus = math.max(
            0,
            rounded(application.applied_vitality_bonus)
        )
    end
    if applied_bonus <= 0 then
        applied_bonus = math.max(0, rounded(saved.applied_vitality_bonus))
    end

    if current_max_hp <= 0 then
        application.last_status = "Waiting for native Max HP before rollback."
        return false
    end

    local target_max_hp = math.max(1, current_max_hp - applied_bonus)
    if applied_bonus > 0 and target_max_hp ~= current_max_hp then
        if health_system.set_max(ctx, target_max_hp) ~= true then
            application.last_status = "Failed to remove the Vitality Max HP bonus."
            return false
        end
        local verified = rounded(ctx.max_hp_number())
        if verified ~= target_max_hp then
            application.last_status = string.format(
                "Vitality rollback expected %d Max HP; native value is %d.",
                target_max_hp,
                verified
            )
            return false
        end
    end

    application.base_max_hp = target_max_hp
    application.desired_vitality_bonus = 0
    application.applied_vitality_bonus = 0
    application.expected_max_hp = target_max_hp
    application.last_native_max_hp = target_max_hp
    application.last_apply_succeeded = true
    application.initialized = true
    application.last_status = string.format(
        "Removed Vitality bonus %d; preserved native Max HP %d.",
        applied_bonus,
        target_max_hp
    )
    saved.base_max_hp = target_max_hp
    saved.applied_vitality_bonus = 0
    saved.last_effective_max_hp = target_max_hp
    return true
end

return application
