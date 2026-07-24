------------------------------------------------------------
-- Maintenance classification — Build 49.39
-- Module: autorun/project_overflow/engine/compatibility.lua
-- Role: Reserved engine namespace compatibility shim.
-- Status: deprecated compatibility shim.
--
-- Compatibility policy:
--   Existing functions, hooks, module paths, and diagnostics are
--   intentionally retained in this maintenance pass.
--   `DEPRECATED` marks a supported legacy path, not removed code.
------------------------------------------------------------

-- Build and API compatibility fallbacks.
-- DEPRECATED: Reserved compatibility namespace; retained so existing require() calls remain valid.
-- Future compatibility helpers should be implemented in a dedicated active module before this shim is removed.
local module = {}
return module
