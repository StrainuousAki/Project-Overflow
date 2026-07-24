------------------------------------------------------------
-- Maintenance classification — Build 49.39
-- Module: autorun/project_overflow/engine/resolution.lua
-- Role: Reserved engine namespace compatibility shim.
-- Status: deprecated compatibility shim.
--
-- Compatibility policy:
--   Existing functions, hooks, module paths, and diagnostics are
--   intentionally retained in this maintenance pass.
--   `DEPRECATED` marks a supported legacy path, not removed code.
------------------------------------------------------------

-- Live resolution and reference-space conversion.
-- DEPRECATED: Reserved compatibility namespace; retained so existing require() calls remain valid.
-- Active resolution conversion currently lives in shared context/UI rendering code.
local module = {}
return module
