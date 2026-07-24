------------------------------------------------------------
-- Maintenance classification — Build 49.39
-- Module: autorun/project_overflow/ui/about.lua
-- Role: ImGui or native-overlay presentation and diagnostics.
-- Status: active UI.
--
-- Compatibility policy:
--   Existing functions, hooks, module paths, and diagnostics are
--   intentionally retained in this maintenance pass.
--   `DEPRECATED` marks a supported legacy path, not removed code.
------------------------------------------------------------

------------------------------------------------------------
-- Project: Overflow — ui/about.lua
-- ImGui panels and attaché-case presentation.
------------------------------------------------------------

local about = {}

local function value(label, content)
    imgui.text(label .. " : " .. tostring(content))
end

local function wrapped(text)
    if imgui.text_wrapped ~= nil then
        imgui.text_wrapped(tostring(text))
    else
        imgui.text(tostring(text))
    end
end

function about.draw(project)
    if not imgui.tree_node("About") then return end

    imgui.text(project.name)
    imgui.text(project.subtitle)
    imgui.separator()

    value("Created by", project.author)
    value("Version", project.version_string())
    value("Internal Build", project.version.build)
    value("Powered by", project.framework)

    imgui.separator()
    imgui.text("Project Goals")
    wrapped("Project: Overflow aims to expand Resident Evil 4 Remake into a deeper RPG experience while preserving the feel, pacing, and native presentation of the original game.")

    imgui.separator()
    imgui.text("Special Thanks")

    for _, credit in ipairs(project.credits) do
        imgui.separator()
        imgui.text(credit.name)
        wrapped(credit.contribution)
    end

    imgui.separator()
    wrapped("Made with passion by StrainuousAki. Built on the incredible work of the REFramework Team and the Resident Evil modding community.")

    imgui.tree_pop()
end

return about
