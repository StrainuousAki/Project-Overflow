------------------------------------------------------------
-- Project: Overflow — Campaign + Slot-aware RPG Save Data
--
-- Native save identity is the pair:
--   campaign + native slot
--
-- Leon and Separate Ways therefore never share RPG progression even when
-- they use the same visible slot number.
------------------------------------------------------------

local save_data = {}

local ROOT = "project_overflow/profiles/"
local LEGACY_PATH = "project_overflow/player_profile.json"
local ACTIVE_PATH = ROOT .. "active_save.json"
local LEGACY_ACTIVE_PATH = ROOT .. "active_slot.json"

local active_key = nil
local active_campaign = nil
local active_record = nil

local function json_available()
    return json ~= nil and json.dump_file ~= nil and json.load_file ~= nil
end

local function normalize_campaign(value)
    local text = string.lower(tostring(value or ""))

    if
        text == "separate_ways"
        or text == "separateways"
        or text == "another_order"
        or text == "anotherorder"
        or text == "ada"
    then
        return "separate_ways"
    end

    if
        text == "leon"
        or text == "main"
        or text == "main_campaign"
    then
        return "leon"
    end

    return nil
end

local function manual_slot_limit(campaign_key)
    return normalize_campaign(campaign_key) == "separate_ways"
        and 10
        or 20
end

local function normalize_key(key, campaign_key)
    if key == "autosave" then
        return "autosave"
    end

    local limit =
        manual_slot_limit(
            campaign_key or active_campaign
        )

    local number = tonumber(key)

    if number ~= nil then
        number = math.floor(number)

        if number >= 1 and number <= limit then
            return string.format("slot_%02d", number)
        end
    end

    if type(key) == "string" then
        local value = tonumber(key:match("^slot_(%d%d)$"))

        if value ~= nil and value >= 1 and value <= limit then
            return string.format("slot_%02d", value)
        end
    end

    return nil
end

local function campaign_root(campaign_key)
    local normalized = normalize_campaign(campaign_key)

    return normalized ~= nil
        and (ROOT .. normalized .. "/")
        or nil
end

local function path_for(key, campaign_key)
    campaign_key = normalize_campaign(campaign_key or active_campaign)
    key = normalize_key(key, campaign_key)

    if key == nil or campaign_key == nil then
        return nil
    end

    return campaign_root(campaign_key)
        .. "player_profile_"
        .. key
        .. ".json"
end

local function legacy_slot_path(key)
    key = normalize_key(key, "leon")

    return key ~= nil
        and (ROOT .. "player_profile_" .. key .. ".json")
        or nil
end

local function read_profile_file(path)
    if not json_available() or path == nil then
        return nil
    end

    local ok, result = pcall(function()
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

    if payload.level ~= nil then
        return payload
    end

    return nil
end

local function write_profile_file(path, payload)
    if not json_available() or path == nil then
        return false
    end

    local ok = pcall(function()
        json.dump_file(path, payload)
    end)

    return ok
end

local function write_active_record(operation, raw_slot)
    if
        not json_available()
        or active_key == nil
        or active_campaign == nil
    then
        return false
    end

    local native_slot_id =
        active_key == "autosave"
        and "00"
        or active_key:match("^slot_(%d%d)$")

    active_record = {
        campaign = active_campaign,
        slot_key = active_key,
        composite_key = active_campaign .. ":" .. active_key,
        native_slot_id = native_slot_id,
        last_native_operation = operation or "selection",
        last_native_raw_slot = raw_slot,
        updated_at = os.time()
    }

    return pcall(function()
        json.dump_file(ACTIVE_PATH, active_record)
    end)
end

local function migrate_legacy_leon_profile(key)
    if normalize_campaign(active_campaign) ~= "leon" then
        return nil
    end

    local destination = path_for(key, "leon")

    if profile_from_payload(read_profile_file(destination)) ~= nil then
        return read_profile_file(destination)
    end

    local source = legacy_slot_path(key)
    local result = read_profile_file(source)

    if profile_from_payload(result) == nil then
        return nil
    end

    local loaded_profile = profile_from_payload(result)

    write_profile_file(
        destination,
        {
            campaign = "leon",
            slot_key = normalize_key(key, "leon"),
            saved_at = tonumber(result.saved_at) or os.time(),
            migrated_from = source,
            profile = loaded_profile
        }
    )

    return read_profile_file(destination) or result
end

function save_data.set_active_campaign(campaign_key)
    local normalized = normalize_campaign(campaign_key)

    if normalized == nil then
        return false, "Invalid RPG campaign."
    end

    active_campaign = normalized

    if active_key ~= nil then
        write_active_record("campaign_selection", active_key)
    end

    return true
end

function save_data.active_campaign()
    return active_campaign
end

function save_data.set_active_slot(key, campaign_key)
    local normalized_campaign =
        normalize_campaign(campaign_key or active_campaign)
    local normalized =
        normalize_key(key, normalized_campaign)

    if normalized == nil then
        return false, "Invalid RPG save slot."
    end

    if normalized_campaign == nil then
        return false, "Invalid RPG campaign."
    end

    active_campaign = normalized_campaign
    active_key = normalized
    write_active_record("selection", key)

    return true
end

function save_data.record_native_event(
    key,
    operation,
    raw_slot,
    campaign_key
)
    local normalized_campaign =
        normalize_campaign(campaign_key or active_campaign)
    local normalized =
        normalize_key(key, normalized_campaign)

    if normalized == nil then
        return false, "Invalid native RPG save slot."
    end

    if normalized_campaign == nil then
        return false, "Invalid native RPG campaign."
    end

    active_campaign = normalized_campaign
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
    active_campaign = nil
end

function save_data.active_slot()
    return active_key
end

function save_data.composite_key(key, campaign_key)
    local normalized_campaign =
        normalize_campaign(campaign_key or active_campaign)
    local normalized =
        normalize_key(key or active_key, normalized_campaign)

    if normalized == nil or normalized_campaign == nil then
        return nil
    end

    return normalized_campaign .. ":" .. normalized
end

function save_data.path(key, campaign_key)
    return path_for(
        key or active_key,
        campaign_key or active_campaign
    ) or "No native campaign/save slot selected"
end

function save_data.legacy_path()
    return LEGACY_PATH
end

function save_data.restore_active_slot()
    if not json_available() then
        return nil
    end

    local ok, result = pcall(function()
        return json.load_file(ACTIVE_PATH)
    end)

    if not ok or type(result) ~= "table" then
        ok, result = pcall(function()
            return json.load_file(LEGACY_ACTIVE_PATH)
        end)
    end

    if not ok or type(result) ~= "table" then
        return nil
    end

    local normalized_campaign =
        normalize_campaign(result.campaign or "leon")
    local normalized =
        normalize_key(result.slot_key, normalized_campaign)

    if normalized == nil or normalized_campaign == nil then
        return nil
    end

    active_campaign = normalized_campaign

    local profile_result =
        read_profile_file(
            path_for(normalized, normalized_campaign)
        )

    if
        profile_from_payload(profile_result) == nil
        and normalized_campaign == "leon"
    then
        profile_result =
            migrate_legacy_leon_profile(normalized)
    end

    if profile_from_payload(profile_result) == nil then
        active_key = nil
        active_record = nil
        return nil
    end

    active_key = normalized
    active_record = result

    if result.campaign == nil or result.last_native_operation == nil then
        write_active_record(
            "legacy_marker_migrated",
            result.slot_key
        )
    end

    return active_key
end

function save_data.restore_single_existing_slot()
    if active_key ~= nil or not json_available() then
        return active_key
    end

    -- Only auto-recover within Leon for backward compatibility. Separate Ways
    -- must first be identified by a native save/load request.
    active_campaign = "leon"

    local found = nil

    for _, key in ipairs(save_data.slot_keys("leon")) do
        local result =
            read_profile_file(
                path_for(key, "leon")
            )
            or migrate_legacy_leon_profile(key)

        if profile_from_payload(result) ~= nil then
            if found ~= nil and found ~= key then
                return nil
            end

            found = key
        end
    end

    if found ~= nil then
        save_data.set_active_slot(found, "leon")
    end

    return active_key
end

function save_data.save(profile, key, campaign_key)
    if not json_available() then
        return false, "REFramework JSON functions are unavailable."
    end

    local normalized_campaign =
        normalize_campaign(campaign_key or active_campaign)
    local normalized =
        normalize_key(key or active_key, normalized_campaign)
    local path =
        path_for(normalized, normalized_campaign)

    if path == nil then
        return false, "Native campaign/save slot is unknown; RPG save was skipped."
    end

    local payload = {
        campaign = normalized_campaign,
        slot_key = normalized,
        composite_key = normalized_campaign .. ":" .. normalized,
        saved_at = os.time(),
        profile = profile
    }

    local ok = write_profile_file(path, payload)

    if not ok then
        return false, "Could not write RPG profile."
    end

    return true
end

function save_data.load(key, campaign_key)
    if not json_available() then
        return nil, "REFramework JSON functions are unavailable."
    end

    local normalized_campaign =
        normalize_campaign(campaign_key or active_campaign)
    local normalized =
        normalize_key(key or active_key, normalized_campaign)
    local path =
        path_for(normalized, normalized_campaign)

    if path == nil then
        return nil, "Native campaign/save slot is unknown; RPG load was skipped."
    end

    local result = read_profile_file(path)

    if
        profile_from_payload(result) == nil
        and normalized_campaign == "leon"
    then
        result = migrate_legacy_leon_profile(normalized)
    end

    if type(result) ~= "table" then
        return nil,
            "No RPG profile exists for "
            .. normalized_campaign
            .. ":"
            .. tostring(normalized)
            .. "."
    end

    local loaded_profile = profile_from_payload(result)

    if loaded_profile == nil then
        return nil,
            "RPG profile data is invalid for "
            .. normalized_campaign
            .. ":"
            .. tostring(normalized)
            .. "."
    end

    if
        result.campaign ~= normalized_campaign
        or result.slot_key ~= normalized
        or type(result.profile) ~= "table"
    then
        write_profile_file(
            path,
            {
                campaign = normalized_campaign,
                slot_key = normalized,
                composite_key =
                    normalized_campaign .. ":" .. normalized,
                saved_at =
                    tonumber(result.saved_at)
                    or os.time(),
                profile = loaded_profile
            }
        )
    end

    return loaded_profile
end

function save_data.slot_keys(campaign_key)
    local normalized_campaign =
        normalize_campaign(campaign_key or active_campaign)
        or "leon"

    local keys = { "autosave" }
    local limit =
        manual_slot_limit(normalized_campaign)

    for index = 1, limit do
        keys[#keys + 1] =
            string.format("slot_%02d", index)
    end

    return keys
end

function save_data.manual_slot_limit(campaign_key)
    return manual_slot_limit(
        campaign_key or active_campaign
    )
end

function save_data.campaign_keys()
    return {
        "leon",
        "separate_ways"
    }
end

save_data.restore_active_slot()
save_data.restore_single_existing_slot()

return save_data
