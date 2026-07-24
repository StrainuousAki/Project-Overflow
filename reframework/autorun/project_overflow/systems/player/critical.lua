------------------------------------------------------------
-- Maintenance classification — Build 49.39
-- Module: autorun/project_overflow/systems/player/critical.lua
-- Role: Player RPG profile, attributes, saves, experience, and stat application.
-- Status: active subsystem.
--
-- Compatibility policy:
--   Existing functions, hooks, module paths, and diagnostics are
--   intentionally retained in this maintenance pass.
--   `DEPRECATED` marks a supported legacy path, not removed code.
------------------------------------------------------------

------------------------------------------------------------
-- Project: Overflow — Outgoing DamageInfo Discovery
--
-- Live per-hit modifier for HitManager.calcInfo. It copies scalar metadata,
-- classifies ownership, and mutates only eligible player DamageInfo while the
-- object is valid. It never retains native objects across the hook call.
------------------------------------------------------------

local rpg = require("project_overflow.systems.player.rpg")

local critical = {
    installed = false,
    installed_hooks = 0,
    failed = {},
    object = nil,
    object_ptr = "not retained",
    apply_count = 0,
    status = "Waiting to install player DamageInfo modifier.",
    normal = { calls = 0, base = 0.0, bonus = 0.0, applied = 0.0 },
    limit_break = { calls = 0, base = 0.0, bonus = 0.0, applied = 0.0 },
    damage = { calls = 0, base = 0.0, bonus = 0.0, applied = 0.0 },
    hit_probe = {
        calls = 0,
        original_damage = 0,
        damage = 0,
        weapon_id = "unknown",
        is_critical = false,
        is_kill = false,
        owner_type = "unknown",
        owner_name = "unknown",
        weapon_object_type = "unknown",
        attacker_type = "unknown",
        target_type = "unknown",
        eligible = false,
        excluded_reason = "none",
        roll = 0.0,
        crit_chance = 0.0,
        critical_hits = 0,
        modified_hits = 0,
        strength_multiplier = 1.0,
        critical_multiplier = 1.0,
        final_damage = 0
    }
}

local function safe_type(object)
    if object == nil then return "nil" end
    local ok, value = pcall(function()
        return object:get_type_definition():get_full_name()
    end)
    return ok and tostring(value or "unknown") or "unknown"
end

local function safe_call(object, method_name)
    if object == nil then return nil end
    local ok, value = pcall(function() return object:call(method_name) end)
    return ok and value or nil
end

local function scalar_text(value)
    if value == nil then return "unknown" end
    local ok, text = pcall(function() return value:call("ToString") end)
    return ok and tostring(text or value) or tostring(value)
end

local function numeric_id(value)
    if value == nil then return -1 end
    local direct = tonumber(value)
    if direct ~= nil then return direct end
    local text = scalar_text(value)
    return tonumber(string.match(text, "%-?%d+")) or -1
end

local function managed_arg(args, index)
    local object = nil
    pcall(function() object = sdk.to_managed_object(args[index]) end)
    return object
end

local function snapshot(info, attacker, target)
    if info == nil then return end
    local probe = critical.hit_probe
    probe.calls = probe.calls + 1
    probe.original_damage =
        tonumber(safe_call(info, "get_OriginalDamage")) or 0
    probe.damage = tonumber(safe_call(info, "get_Damage")) or 0
    local weapon_value = safe_call(info, "get_WeaponID")
    local weapon_id = numeric_id(weapon_value)
    probe.weapon_id = tostring(weapon_id)
    probe.is_critical = safe_call(info, "get_IsCritical") == true
    probe.is_kill = safe_call(info, "get_IsKill") == true

    local owner = safe_call(info, "get_AttackOwnerObject")
    local weapon_object = safe_call(info, "get_WeaponGameObject")
    probe.owner_type = safe_type(owner)
    probe.owner_name = scalar_text(safe_call(owner, "get_Name"))
    probe.weapon_object_type = safe_type(weapon_object)
    probe.attacker_type = safe_type(attacker)
    probe.target_type = safe_type(target)

    local owner_name_lower = string.lower(probe.owner_name)
    local player_owner =
        string.match(owner_name_lower, "^ch0a") ~= nil
    local base_damage = probe.damage

    probe.eligible = false
    probe.excluded_reason = "none"
    if not player_owner then
        probe.excluded_reason = "non-player attack owner"
    elseif base_damage <= 0 then
        probe.excluded_reason = "zero damage"
    else
        probe.eligible = true
    end

    if not probe.eligible then
        probe.final_damage = base_damage
        critical.status = "Observed excluded DamageInfo: " ..
            probe.excluded_reason .. "."
        return
    end

    local derived = rpg.derived_stats()
    local strength_multiplier = math.max(
        1.0,
        tonumber(derived.weapon_damage_multiplier) or 1.0
    )
    local crit_chance = math.max(
        0.0,
        math.min(0.50, tonumber(derived.critical_chance) or 0.0)
    )
    local roll = math.random()
    local rolled_critical = roll < crit_chance
    local critical_multiplier = rolled_critical and (
        1.0 + math.max(
            0.0,
            tonumber(derived.critical_damage_bonus) or 0.0
        )
    ) or 1.0
    local final_damage = math.max(1, math.floor(
        base_damage * strength_multiplier * critical_multiplier + 0.5
    ))

    local damage_ok = pcall(function()
        info:call("set_Damage", final_damage)
    end)
    local critical_ok = true
    if rolled_critical then
        critical_ok = pcall(function()
            info:call("set_IsCritical", true)
        end)
    end

    probe.roll = roll
    probe.crit_chance = crit_chance
    probe.strength_multiplier = strength_multiplier
    probe.critical_multiplier = critical_multiplier
    probe.final_damage = final_damage
    if damage_ok then
        probe.modified_hits = probe.modified_hits + 1
    end
    if rolled_critical and critical_ok then
        probe.critical_hits = probe.critical_hits + 1
        probe.is_critical = true
    end
    critical.apply_count = probe.modified_hits
    critical.damage.base = base_damage
    critical.damage.bonus = critical_multiplier - 1.0
    critical.damage.applied = final_damage
    critical.status = string.format(
        "Applied player hit: %d -> %d%s.",
        base_damage,
        final_damage,
        rolled_critical and " CRITICAL" or ""
    )
end

function critical.install()
    if critical.installed then return true end
    local hit_manager = sdk.find_type_definition("chainsaw.HitManager")
    if hit_manager == nil then
        critical.status = "chainsaw.HitManager type missing."
        return false
    end
    local method = hit_manager:get_method(
        "calcInfo(chainsaw.HitController.DamageInfo, chainsaw.HitController, chainsaw.HitController)"
    ) or hit_manager:get_method("calcInfo")
    if method == nil then
        critical.status = "HitManager.calcInfo method missing."
        return false
    end

    local stack = {}
    local ok, error_text = pcall(function()
        sdk.hook(method, function(args)
            stack[#stack + 1] = {
                info = managed_arg(args, 3),
                attacker = managed_arg(args, 4),
                target = managed_arg(args, 5)
            }
        end, function(retval)
            local entry = stack[#stack]
            stack[#stack] = nil
            if entry ~= nil then
                snapshot(entry.info, entry.attacker, entry.target)
            end
            return retval
        end)
    end)
    if not ok then
        critical.failed[#critical.failed + 1] = tostring(error_text)
        critical.status = "calcInfo probe installation failed."
        return false
    end
    critical.installed = true
    critical.installed_hooks = 1
    critical.status = "Player-only HitManager.calcInfo modifier installed."
    return true
end

function critical.update()
    critical.install()
    return false
end

return critical
