------------------------------------------------------------
-- Maintenance classification — Build 49.39
-- Module: autorun/project_overflow/engine/hooks.lua
-- Role: Reserved engine namespace compatibility shim.
-- Status: deprecated compatibility shim.
--
-- Compatibility policy:
--   Existing functions, hooks, module paths, and diagnostics are
--   intentionally retained in this maintenance pass.
--   `DEPRECATED` marks a supported legacy path, not removed code.
------------------------------------------------------------

-- Safe REFramework hook registration.
-- DEPRECATED: Reserved compatibility namespace; retained so existing require() calls remain valid.
-- Active hook registration currently lives in concrete subsystem modules.
local module = {}
return module
