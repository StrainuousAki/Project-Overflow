------------------------------------------------------------
-- Project: Overflow — Active Campaign Detection
--
-- Resolves the native campaign before RPG slot selection. Detection runs only
-- around native save/load events and inspects request, manager, and player
-- metadata for stable textual campaign markers.
------------------------------------------------------------

local campaign = {
    active = nil,
    last_detected = nil,
    last_source = "unresolved",
    last_evidence = "none",
    detection_count = 0,
    separate_ways_detections = 0,
    leon_detections = 0
}

local FIELD_NAMES = {
    "Campaign", "CampaignType", "CampaignID", "CampaignId",
    "Scenario", "ScenarioType", "ScenarioID", "ScenarioId",
    "GameMode", "GameModeType", "Mode", "ModeType",
    "PlayerType", "PlayerCharacter", "PlayerCharacterType",
    "Character", "CharacterType", "CharacterID", "CharacterId",
    "Story", "StoryType", "DLC", "DlcType",
    "_Campaign", "_Scenario", "_GameMode", "_PlayerType",
    "<Campaign>k__BackingField", "<CampaignType>k__BackingField",
    "<Scenario>k__BackingField", "<ScenarioType>k__BackingField",
    "<GameMode>k__BackingField", "<PlayerType>k__BackingField",
    "<CharacterType>k__BackingField"
}

local GETTER_NAMES = {
    "get_Campaign", "get_CampaignType", "get_CampaignID", "get_CampaignId",
    "get_Scenario", "get_ScenarioType", "get_ScenarioID", "get_ScenarioId",
    "get_GameMode", "get_GameModeType", "get_Mode", "get_ModeType",
    "get_PlayerType", "get_PlayerCharacter", "get_PlayerCharacterType",
    "get_Character", "get_CharacterType", "get_CharacterID", "get_CharacterId",
    "get_Story", "get_StoryType", "get_DLC", "get_DlcType"
}

local function lower(value)
    return string.lower(tostring(value or ""))
end

local function classify_text(value)
    local text = lower(value)

    if text == "" then
        return nil
    end

    if
        text:find("separateways", 1, true)
        or text:find("separate_ways", 1, true)
        or text:find("separate ways", 1, true)
        or text:find("anotherorder", 1, true)
        or text:find("another_order", 1, true)
        or text:find("another order", 1, true)
        or text:find("ada", 1, true)
    then
        return "separate_ways"
    end

    if
        text:find("leon", 1, true)
        or text:find("mainstory", 1, true)
        or text:find("main_story", 1, true)
        or text:find("main campaign", 1, true)
    then
        return "leon"
    end

    return nil
end

local function safe_type_name(object)
    if object == nil then
        return nil
    end

    local ok, result = pcall(function()
        local definition = object:get_type_definition()
        return definition ~= nil and definition:get_full_name() or nil
    end)

    return ok and result or nil
end

local function safe_field(object, name)
    if object == nil then
        return nil
    end

    local ok, result = pcall(function()
        return object:get_field(name)
    end)

    return ok and result or nil
end

local function safe_call(object, name)
    if object == nil then
        return nil
    end

    local ok, result = pcall(function()
        return object:call(name)
    end)

    return ok and result or nil
end

local function classify_value(value)
    if value == nil then
        return nil, nil
    end

    local direct = classify_text(value)
    if direct ~= nil then
        return direct, tostring(value)
    end

    local managed = nil
    pcall(function()
        managed = sdk.to_managed_object(value)
    end)

    if managed ~= nil then
        local type_name = safe_type_name(managed)
        local from_type = classify_text(type_name)
        if from_type ~= nil then
            return from_type, tostring(type_name)
        end

        local enum_name = safe_call(managed, "ToString")
        local from_enum = classify_text(enum_name)
        if from_enum ~= nil then
            return from_enum, tostring(enum_name)
        end
    end

    return nil, nil
end

local function inspect_object(object, source)
    if object == nil then
        return nil, nil, nil
    end

    local type_name = safe_type_name(object)
    local from_type = classify_text(type_name)

    if from_type ~= nil then
        return from_type, source .. ".type", tostring(type_name)
    end

    local object_text = safe_call(object, "ToString")
    local from_text = classify_text(object_text)

    if from_text ~= nil then
        return from_text, source .. ".ToString", tostring(object_text)
    end

    for _, field_name in ipairs(FIELD_NAMES) do
        local value = safe_field(object, field_name)
        local result, evidence = classify_value(value)

        if result ~= nil then
            return result, source .. "." .. field_name, evidence
        end
    end

    for _, getter_name in ipairs(GETTER_NAMES) do
        local value = safe_call(object, getter_name)
        local result, evidence = classify_value(value)

        if result ~= nil then
            return result, source .. "." .. getter_name, evidence
        end
    end

    return nil, nil, nil
end

function campaign.normalize(value)
    local text = lower(value)

    if
        text == "separate_ways"
        or text == "separateways"
        or text == "another_order"
        or text == "anotherorder"
        or text == "ada"
    then
        return "separate_ways"
    end

    if text == "leon" or text == "main" or text == "main_campaign" then
        return "leon"
    end

    return nil
end

function campaign.set_active(value, source, evidence)
    local normalized = campaign.normalize(value)

    if normalized == nil then
        return false
    end

    campaign.active = normalized
    campaign.last_detected = normalized
    campaign.last_source = tostring(source or "manual")
    campaign.last_evidence = tostring(evidence or value)
    campaign.detection_count = campaign.detection_count + 1

    if normalized == "separate_ways" then
        campaign.separate_ways_detections =
            campaign.separate_ways_detections + 1
    else
        campaign.leon_detections =
            campaign.leon_detections + 1
    end

    return true
end


local function inspect_reflected_object(
    object,
    source,
    depth,
    visited
)
    if object == nil then
        return nil, nil, nil
    end

    depth = tonumber(depth) or 0
    visited = visited or {}

    if depth > 2 then
        return nil, nil, nil
    end

    local pointer = tostring(object)
    pcall(function()
        pointer = string.format("0x%X", sdk.to_ptr(object))
    end)

    if visited[pointer] == true then
        return nil, nil, nil
    end

    visited[pointer] = true

    local direct, direct_source, direct_evidence =
        inspect_object(object, source)

    if direct ~= nil then
        return direct, direct_source, direct_evidence
    end

    local definition = nil
    pcall(function()
        definition = object:get_type_definition()
    end)

    if definition == nil then
        return nil, nil, nil
    end

    local fields = {}
    pcall(function()
        fields = definition:get_fields() or {}
    end)

    for index, field_definition in ipairs(fields) do
        if index > 192 then
            break
        end

        local field_name = "field_" .. tostring(index)
        pcall(function()
            field_name = field_definition:get_name()
        end)

        local name_result =
            classify_text(field_name)

        if name_result ~= nil then
            return
                name_result,
                source .. ".field_name",
                tostring(field_name)
        end

        local value = nil
        pcall(function()
            value = object:get_field(field_name)
        end)

        local value_result,
              value_evidence =
            classify_value(value)

        if value_result ~= nil then
            return
                value_result,
                source .. "." .. tostring(field_name),
                value_evidence
        end

        if depth < 2 and value ~= nil then
            local child = nil
            pcall(function()
                child = sdk.to_managed_object(value)
            end)

            if child ~= nil then
                local nested,
                      nested_source,
                      nested_evidence =
                    inspect_reflected_object(
                        child,
                        source .. "." .. tostring(field_name),
                        depth + 1,
                        visited
                    )

                if nested ~= nil then
                    return
                        nested,
                        nested_source,
                        nested_evidence
                end
            end
        end
    end

    return nil, nil, nil
end

function campaign.detect(request_object, manager_object, player_object)
    local candidates = {
        { request_object, "request" },
        { manager_object, "save_manager" },
        { player_object, "player" }
    }

    for _, entry in ipairs(candidates) do
        local result, source, evidence =
            inspect_reflected_object(
                entry[1],
                entry[2],
                0,
                {}
            )

        if result ~= nil then
            campaign.set_active(result, source, evidence)
            return result, source, evidence
        end
    end

    -- Never silently substitute Leon. The two campaigns reuse visible native
    -- slot numbers, so an unresolved campaign must skip RPG I/O rather than
    -- load or overwrite the other campaign's profile.
    return nil, "unresolved", "no campaign marker found"
end

function campaign.clear_active(source)
    campaign.active = nil
    campaign.last_source =
        tostring(source or "campaign cleared")
    campaign.last_evidence = "none"
end

function campaign.active_campaign()
    return campaign.active
end

return campaign
