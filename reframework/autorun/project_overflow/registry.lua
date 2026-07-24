------------------------------------------------------------
-- Maintenance classification — Build 49.39
-- Module: autorun/project_overflow/registry.lua
-- Role: Project: Overflow runtime support module.
-- Status: active support.
--
-- Compatibility policy:
--   Existing functions, hooks, module paths, and diagnostics are
--   intentionally retained in this maintenance pass.
--   `DEPRECATED` marks a supported legacy path, not removed code.
------------------------------------------------------------

------------------------------------------------------------
-- Project: Overflow — registry.lua
-- Project: Overflow runtime module.
------------------------------------------------------------

local M = {}
local Registry = {}
Registry.__index = Registry
local function now() return os.clock() end

function Registry:clear()
    self.live = {}
    self.deaths = {}
    self.transactions = {}
end

function Registry:key_from_object(object)
    if not object then return nil end
    local ok, address = pcall(function() return object:get_address() end)
    if ok and address then return string.format("0x%X", address) end
    return tostring(object)
end

function Registry:register(object, data)
    local key = self:key_from_object(object)
    if not key then return nil end
    local entry = self.live[key] or { key = key, created_at = now(), dead = false, reward_committed = false }
    if data then for field, value in pairs(data) do entry[field] = value end end
    entry.object = object
    entry.last_seen_at = now()
    self.live[key] = entry
    return entry
end

function Registry:mark_dead(object, source, data)
    local entry = self:register(object, data)
    if not entry then return nil, false end
    if entry.dead then
        entry.duplicate_death_count = (entry.duplicate_death_count or 0) + 1
        return entry, false
    end
    entry.dead = true
    entry.death_source = source
    entry.died_at = now()
    table.insert(self.deaths, 1, entry)
    while #self.deaths > 50 do table.remove(self.deaths) end
    return entry, true
end

function Registry:commit_reward(entry, transaction)
    if not entry or entry.reward_committed then return false end
    entry.reward_committed = true
    entry.reward_transaction = transaction
    table.insert(self.transactions, 1, transaction)
    while #self.transactions > 50 do table.remove(self.transactions) end
    return true
end

function Registry:prune()
    local cutoff = now() - 180.0
    for key, entry in pairs(self.live) do
        if entry.dead and (entry.died_at or 0) < cutoff then self.live[key] = nil end
    end
end

function M.new()
    local instance = setmetatable({}, Registry)
    instance:clear()
    return instance
end
return M
