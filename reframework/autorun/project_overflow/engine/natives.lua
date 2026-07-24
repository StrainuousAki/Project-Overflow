------------------------------------------------------------
-- Maintenance classification — Build 49.39
-- Module: autorun/project_overflow/engine/natives.lua
-- Role: Reserved engine namespace compatibility shim.
-- Status: deprecated compatibility shim.
--
-- Compatibility policy:
--   Existing functions, hooks, module paths, and diagnostics are
--   intentionally retained in this maintenance pass.
--   `DEPRECATED` marks a supported legacy path, not removed code.
------------------------------------------------------------

-- Named access to captured RE Engine objects.
-- DEPRECATED: Reserved compatibility namespace; retained so existing require() calls remain valid.
-- Active native-object capture currently lives in shared context and subsystem modules.
local module = {}
return module
