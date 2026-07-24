------------------------------------------------------------
-- Maintenance classification — Build 49.39
-- Module: autorun/project_overflow/systems/player/save_data.lua
-- Role: Player RPG profile, attributes, saves, experience, and stat application.
-- Status: active subsystem.
--
-- Compatibility policy:
--   Existing functions, hooks, module paths, and diagnostics are
--   intentionally retained in this maintenance pass.
--   `DEPRECATED` marks a supported legacy path, not removed code.
------------------------------------------------------------

------------------------------------------------------------
-- Project: Overflow — Slot-aware RPG Save Data
--
-- RE4 has twenty manual slots plus one autosave slot. Progression
-- is deliberately refused when the native slot is unknown so data
-- from separate playthroughs can never fall through to one profile.
------------------------------------------------------------

local save_data = {}

local ROOT = "project_overflow/profiles/"
local LEGACY_PATH = "project_overflow/player_profile.json"
local ACTIVE_PATH = ROOT .. "active_save.json"
local LEGACY_ACTIVE_PATH = ROOT .. "active_slot.json"
local active_key = nil
local active_record = nil

local function json_available()
    return json ~= nil and json.dump_file ~= nil and json.load_file ~= nil
end

local function read_profile_file(path)
    if not json_available() or path == nil then
        return nil
    end

    local ok,
          result =
        pcall(function()
            return json.load_file(path)
        end)

    if not ok or type(result) ~= "table" then
        return nil
    end

    return result
end

local function profile_from_payload(payload)
    if type(payload) ~= "table" then
        return nil
    end

    if type(payload.profile) == "table" then
        return payload.profile
    end

    -- Accept early profile files that stored the profile without an envelope.
    if payload.level ~= nil then
        return payload
    end

    return nil
end

local function write_active_record(operation, raw_slot)
    if not json_available() or active_key == nil then return false end
    local native_slot_id = active_key == "autosave"
        and "00"
        or active_key:match("^slot_(%d%d)$")
    active_record = {
        slot_key = active_key,
        native_slot_id = native_slot_id,
        last_native_operation = operation or "selection",
        last_native_raw_slot = raw_slot,
        updated_at = os.time()
    }
    local ok = pcall(function() json.dump_file(ACTIVE_PATH, active_record) end)
    return ok
end

local function normalize_key(key)
    if key == "autosave" then return "autosave" end
    local number = tonumber(key)
    if number ~= nil then
        number = math.floor(number)
        if number >= 1 and number <= 20 then
            return string.format("slot_%02d", number)
        end
    end
    if type(key) == "string" then
        local value = tonumber(key:match("^slot_(%d%d)$"))
        if value ~= nil and value >= 1 and value <= 20 then
            return string.format("slot_%02d", value)
        end
    end
    return nil
end

local function path_for(key)
    key = normalize_key(key)
    return key ~= nil and (ROOT .. "player_profile_" .. key .. ".json") or nil
end

function save_data.set_active_slot(key)
    local normalized = normalize_key(key)
    if normalized == nil then return false, "Invalid RPG save slot." end
    active_key = normalized
    write_active_record("selection", key)
    return true
end

function save_data.record_native_event(key, operation, raw_slot)
    local normalized = normalize_key(key)
    if normalized == nil then return false, "Invalid native RPG save slot." end
    active_key = normalized
    if not write_active_record(operation, raw_slot) then
        return false, "Could not update active_save.json."
    end
    return true
end

function save_data.active_record()
    return active_record
end

function save_data.clear_active_slot()
    active_key = nil
end

function save_data.active_slot()
    return active_key
end

function save_data.path(key)
    return path_for(key or active_key) or "No native save slot selected"
end

function save_data.legacy_path()
    return LEGACY_PATH
end

function save_data.restore_active_slot()
    if not json_available() then return nil end
    local ok, result = pcall(function() return json.load_file(ACTIVE_PATH) end)
    if not ok or type(result) ~= "table" then
        ok, result = pcall(function() return json.load_file(LEGACY_ACTIVE_PATH) end)
    end
    if not ok or type(result) ~= "table" then return nil end
    local normalized = normalize_key(result.slot_key)
    if normalized ~= nil then
        -- Never revive a marker whose isolated profile no longer exists.
        -- This also repairs markers produced by older ambiguous slot mapping.
        local profile_result =
            read_profile_file(
                path_for(normalized)
            )

        if
            profile_from_payload(profile_result)
            == nil
        then
            -- A stale marker must not select an empty or missing profile.
            active_key = nil
            active_record = nil
            return nil
        end

        active_key = normalized
        active_record = result
        -- Migrate a valid legacy marker immediately.
        if result.last_native_operation == nil then
            write_active_record("legacy_marker_migrated", result.slot_key)
        end
    end
    return active_key
end

-- Recover a lost active-slot marker only when the result is unambiguous.
-- This repairs upgrades/reinstalls that retained slot JSON files but lost
-- active_slot.json without ever borrowing progression from another slot.
function save_data.restore_single_existing_slot()
    if active_key ~= nil or not json_available() then return active_key end
    local found = nil
    for _, key in ipairs(save_data.slot_keys()) do
        local path = path_for(key)
        local result =
            read_profile_file(path)

        if
            profile_from_payload(result)
            ~= nil
        then
            if found ~= nil and found ~= key then
                return nil
            end

            found = key
        end
    end
    if found ~= nil then
        save_data.set_active_slot(found)
    end
    return active_key
end

function save_data.save(profile, key)
    if not json_available() then
        return false, "REFramework JSON functions are unavailable."
    end
    local path = path_for(key or active_key)
    if path == nil then
        return false, "Native save slot is unknown; RPG save was skipped."
    end
    local payload = {
        slot_key = normalize_key(key or active_key),
        saved_at = os.time(),
        profile = profile
    }
    local ok, result = pcall(function() return json.dump_file(path, payload) end)
    if not ok then return false, tostring(result) end
    return true
end

function save_data.load(key)
    if not json_available() then
        return nil, "REFramework JSON functions are unavailable."
    end

    local normalized =
        normalize_key(
            key or active_key
        )

    local path =
        path_for(normalized)

    if path == nil then
        return nil, "Native save slot is unknown; RPG load was skipped."
    end

    local result =
        read_profile_file(path)

    if type(result) ~= "table" then
        return nil, "No RPG profile exists for " .. normalized .. "."
    end

    local loaded_profile =
        profile_from_payload(result)

    if loaded_profile == nil then
        return nil, "RPG profile data is invalid for " .. normalized .. "."
    end

    -- The filename/native event owns slot identity. Repair a renamed file or
    -- stale envelope automatically instead of rejecting otherwise valid RPG
    -- progression because its embedded slot_key still names the old slot.
    if
        result.slot_key ~= normalized or
        type(result.profile) ~= "table"
    then
        pcall(function()
            json.dump_file(
                path,
                {
                    slot_key = normalized,
                    saved_at =
                        tonumber(result.saved_at)
                        or os.time(),
                    profile = loaded_profile
                }
            )
        end)
    end

    return loaded_profile
end

function save_data.slot_keys()
    local keys = { "autosave" }
    for index = 1, 20 do keys[#keys + 1] = string.format("slot_%02d", index) end
    return keys
end

save_data.restore_active_slot()
save_data.restore_single_existing_slot()

return save_data
