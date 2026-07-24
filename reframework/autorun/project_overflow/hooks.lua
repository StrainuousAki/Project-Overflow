------------------------------------------------------------
-- Maintenance classification — Build 49.39
-- Module: autorun/project_overflow/hooks.lua
-- Role: Project: Overflow runtime support module.
-- Status: active support.
--
-- Compatibility policy:
--   Existing functions, hooks, module paths, and diagnostics are
--   intentionally retained in this maintenance pass.
--   `DEPRECATED` marks a supported legacy path, not removed code.
------------------------------------------------------------

------------------------------------------------------------
-- Project: Overflow — hooks.lua
-- Project: Overflow runtime module.
------------------------------------------------------------

local M = {}
local function managed(args, index)
    local ok, obj = pcall(sdk.to_managed_object, args[index])
    return ok and obj or nil
end
local function call_any(object, names)
    if not object then return nil end
    for _, name in ipairs(names) do
        local ok, result = pcall(object.call, object, name)
        if ok and result ~= nil then return result end
    end
end
local function game_object(object) return call_any(object, {"get_GameObject","get_gameObject","get_Owner"}) end
local function position_from(object)
    local go=game_object(object) or object
    local transform=call_any(go,{"get_Transform","get_transform"})
    local position=call_any(transform,{"get_Position","get_position"})
    if not position then return nil end
    local ok, result=pcall(function() return {x=tonumber(position.x),y=tonumber(position.y),z=tonumber(position.z)} end)
    return ok and result or nil
end
local function type_name(object)
    local ok, result=pcall(function() return object:get_type_definition():get_full_name() end)
    return ok and result or nil
end
local function object_name(object)
    return call_any(game_object(object), {"get_Name","get_name"})
end
local function find_method(type_name_value, names)
    local td=sdk.find_type_definition(type_name_value)
    if not td then return nil, "Type not found: "..type_name_value end
    for _, name in ipairs(names) do local method=td:get_method(name); if method then return method end end
    return nil, "Methods not found on "..type_name_value..": "..table.concat(names, ", ")
end
local function transaction(entry)
    local record=entry.manifest
    local loot=record and record.biorand_loot or nil
    return {
        committed_at=os.clock(), enemy_key=entry.key,
        manifest_id=record and record.manifest_id or nil,
        xp={amount=0,source="overflow_placeholder"},
        rewards={{source="biorand",source_id=record and record.drop_id or nil,item=loot and loot.item or nil,amount=loot and loot.amount or 0,raw=loot and loot.raw or nil}},
        overflow_augmentations={}, diagnostic_only=true,
    }
end
local function on_dead(ctx, enemy, source)
    local entry, fresh=ctx.registry:mark_dead(enemy, source, {
        type_name=type_name(enemy), object_name=object_name(enemy), position=position_from(enemy),
    })
    if not entry or not fresh then return end
    if entry.position then
        local record, distance=ctx.manifest:nearest(entry.position,{max_distance=ctx.config.match_max_distance})
        if record then record.matched=true; record.matched_enemy_key=entry.key; entry.manifest=record; entry.manifest_score=distance end
    end
    ctx.registry:commit_reward(entry, transaction(entry))
    if ctx.config.debug_log then
        local record=entry.manifest
        log.info(string.format("[Overflow] Death key=%s source=%s manifest=%s family=%s loot=%s", tostring(entry.key), tostring(source), tostring(record and record.manifest_id or "UNMATCHED"), tostring(record and record.family or "?"), tostring(record and record.biorand_loot and record.biorand_loot.raw or "?")))
    end
end
local function install_notify_dead(ctx)
    local method, err=find_method("chainsaw.EnemyManager", {"notifyDead","notifyDead(chainsaw.EnemyContext)","notifyDead(chainsaw.EnemyCharacterContext)"})
    if not method then ctx.hooks.notify_dead={installed=false,error=err}; return end
    sdk.hook(method, function(args)
        local enemy=managed(args,3) or managed(args,2)
        if enemy then on_dead(ctx,enemy,"EnemyManager.notifyDead") end
    end, function(retval) return retval end)
    ctx.hooks.notify_dead={installed=true,method=method:get_full_name()}
end
local function install_hp_fallback(ctx)
    local method, err=find_method("chainsaw.HitPointController", {"set_HitPoint(System.Int32)","set_HitPoint(System.Single)","set_HitPoint"})
    if not method then ctx.hooks.hp_fallback={installed=false,error=err}; return end
    sdk.hook(method, function(args)
        local controller=managed(args,2)
        local hp=sdk.to_int64(args[3])
        if controller and hp and hp <= 0 then on_dead(ctx,controller,"HitPointController.set_HitPoint") end
    end, function(retval) return retval end)
    ctx.hooks.hp_fallback={installed=true,method=method:get_full_name(),note="Broad fallback; may capture non-enemy HP controllers"}
end
function M.install(ctx) install_notify_dead(ctx); install_hp_fallback(ctx) end
return M
