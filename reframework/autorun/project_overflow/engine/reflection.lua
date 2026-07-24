------------------------------------------------------------
-- Maintenance classification — Build 49.39
-- Module: autorun/project_overflow/engine/reflection.lua
-- Role: Reserved engine namespace compatibility shim.
-- Status: deprecated compatibility shim.
--
-- Compatibility policy:
--   Existing functions, hooks, module paths, and diagnostics are
--   intentionally retained in this maintenance pass.
--   `DEPRECATED` marks a supported legacy path, not removed code.
------------------------------------------------------------

-- Reflection and method lookup helpers.
-- DEPRECATED: Reserved compatibility namespace; retained so existing require() calls remain valid.
-- Active reflection helpers currently live in shared context and inspector modules.
local module = {}
return module
