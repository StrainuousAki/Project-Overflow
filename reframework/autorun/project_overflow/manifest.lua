------------------------------------------------------------
-- Maintenance classification — Build 49.39
-- Module: autorun/project_overflow/manifest.lua
-- Role: Project: Overflow runtime support module.
-- Status: active support.
--
-- Compatibility policy:
--   Existing functions, hooks, module paths, and diagnostics are
--   intentionally retained in this maintenance pass.
--   `DEPRECATED` marks a supported legacy path, not removed code.
------------------------------------------------------------

------------------------------------------------------------
-- Project: Overflow — manifest.lua
-- Project: Overflow runtime module.
------------------------------------------------------------

local M = {}
local FAMILIES = {
    villager=true, soldier=true, zealot=true, brute=true, novistador=true,
    colmillos=true, armadura=true, regenerador=true, iron_maiden=true,
    arana=true, ganado=true, chainsaw=true, garrador=true, verdugo=true,
    gigante=true, del_lago=true, saddler=true, krauser=true, mendez=true,
    salazar=true,
}

local function trim(v) return tostring(v or ""):match("^%s*(.-)%s*$") end
local function words(line)
    local out = {}
    for word in tostring(line or ""):gmatch("%S+") do table.insert(out, word) end
    return out
end
local function scene_header(line) return tostring(line):match("^%s%s[%w_%-%.]+%.scn%.%d+%s*$") ~= nil end
local function family_index(parts)
    for i, word in ipairs(parts) do if FAMILIES[word:lower()] then return i end end
end

local function parse_drop(text)
    text = trim(text)
    if text == "" or text == "." or text == "*" then return { raw=text, kind="none", amount=0 } end
    local probability, remainder = text:match("^pC%(([%d%.]+)%%%)%s+(.+)$")
    if remainder then text = remainder end
    local item, amount = text:match("^(.-)%s+x(%d+)%s*$")
    return {
        raw = trim(text),
        kind = item and "fixed" or "raw",
        item = item and trim(item) or trim(text),
        amount = tonumber(amount) or 1,
        probability = tonumber(probability),
    }
end

local function parse_line(line, scene)
    if not line:find("CTXID%(") then return nil end
    local parts = words(line)
    local fi = family_index(parts)
    if not fi or fi < 6 then return nil end
    local uuid = line:match("^%s*([%x%-]+)%s+CTXID%(")
    local ctxid = line:match("(CTXID%([^%)]+%))")
    if not uuid or not ctxid then return nil end
    local stage_i = fi - 4
    local stage_id = tonumber(parts[stage_i])
    local x, y, z = tonumber(parts[stage_i+1]), tonumber(parts[stage_i+2]), tonumber(parts[stage_i+3])
    if not stage_id or not x or not y or not z then return nil end
    local name_parts = {}
    for i = 3, stage_i - 1 do table.insert(name_parts, parts[i]) end
    local family = parts[fi]:lower()
    local appearance_hash = tonumber(parts[fi+1])
    local cursor = fi + 2
    local weapon_parts = {}
    while cursor <= #parts do
        local token = parts[cursor]
        if tonumber(token) or token == "*" or token == "." or token:match("^pC%(") then break end
        table.insert(weapon_parts, token)
        cursor = cursor + 1
    end
    local drop_id = tonumber(parts[cursor])
    if drop_id then cursor = cursor + 1 end
    local drop_parts = {}
    for i = cursor, #parts do table.insert(drop_parts, parts[i]) end
    return {
        manifest_id=uuid, uuid=uuid, ctxid=ctxid, scene=scene,
        spawn_name=table.concat(name_parts, " "), stage_id=stage_id,
        position={x=x,y=y,z=z}, family=family,
        appearance_hash=appearance_hash, weapon=trim(table.concat(weapon_parts, " ")),
        drop_id=drop_id, biorand_loot=parse_drop(table.concat(drop_parts, " ")),
        raw_line=trim(line), matched=false,
    }
end

local Manifest = {}
Manifest.__index = Manifest
function Manifest:clear()
    self.path=nil; self.seed=nil; self.campaign=nil; self.records={}; self.by_stage={}; self.enemy_count=0; self.parse_errors={}
end
function Manifest:load(path)
    self:clear(); self.path=path
    local file, err = io.open(path, "r")
    if not file then error("Unable to open BioRand manifest: " .. tostring(path) .. " | " .. tostring(err)) end
    local scene=nil; local line_number=0
    for line in file:lines() do
        line_number=line_number+1
        if not self.seed then self.seed=tonumber(line:match("^Seed%s*=%s*(%d+)")) end
        if not self.campaign then self.campaign=line:match("^Campaign%s*=%s*(.+)$") end
        if scene_header(line) then
            scene=trim(line)
        elseif scene then
            local ok, record = pcall(parse_line, line, scene)
            if ok and record then
                record.line_number=line_number
                table.insert(self.records, record)
                self.by_stage[record.stage_id]=self.by_stage[record.stage_id] or {}
                table.insert(self.by_stage[record.stage_id], record)
            elseif not ok then
                table.insert(self.parse_errors, string.format("Line %d: %s", line_number, tostring(record)))
            end
        end
    end
    file:close(); self.enemy_count=#self.records; return self.enemy_count
end
function Manifest:nearest(position, options)
    if not position then return nil end
    options=options or {}
    local max_distance=tonumber(options.max_distance) or 18.0
    local max_sq=max_distance*max_distance
    local candidates=(options.stage_id and self.by_stage[options.stage_id]) or self.records
    local best=nil; local best_score=math.huge
    for _, record in ipairs(candidates) do
        if not record.matched or options.allow_matched then
            local dx=position.x-record.position.x; local dy=position.y-record.position.y; local dz=position.z-record.position.z
            local score=dx*dx+dy*dy+dz*dz
            if score <= max_sq then
                if options.family and options.family ~= "" and options.family ~= record.family then score=score+400 end
                if options.scene and options.scene ~= "" and options.scene ~= record.scene then score=score+900 end
                if score < best_score then best=record; best_score=score end
            end
        end
    end
    if not best then return nil end
    return best, math.sqrt(best_score)
end
function M.new() local instance=setmetatable({}, Manifest); instance:clear(); return instance end
return M
