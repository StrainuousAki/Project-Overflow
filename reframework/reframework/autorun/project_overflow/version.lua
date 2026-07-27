------------------------------------------------------------
-- Maintenance classification — Build 49.39
-- Module: autorun/project_overflow/version.lua
-- Role: Project version, build metadata, credits, and public description.
-- Status: authoritative metadata.
--
-- Compatibility policy:
--   Existing functions, hooks, module paths, and diagnostics are
--   intentionally retained in this maintenance pass.
--   `DEPRECATED` marks a supported legacy path, not removed code.
------------------------------------------------------------

------------------------------------------------------------
-- Project: Overflow
-- Resident Evil 4 Remake RPG Framework
--
-- Created by StrainuousAki
--
-- This module is the single source of truth for the public
-- version, internal build, credits, and project description.
------------------------------------------------------------

local project = {
    name = "Project: Overflow",
    subtitle = "Resident Evil 4 Remake RPG Framework",
    author = "StrainuousAki",

    version = {
        stage = "Alpha",
        major = 0,
        minor = 2,
        patch = 2,

        -- Internal development build. This can advance independently
        -- from the public semantic version above.
        build = "49.81"
    },

    framework = "REFramework",

    credits = {
        {
            name = "praydog",
            contribution =
                "Creator of REFramework, the foundation that makes Project: Overflow possible."
        },
        {
            name = "cursey",
            contribution =
                "For major REFramework, VR, scripting, and RE Engine ecosystem contributions."
        },
        {
            name = "The Hitchhiker",
            contribution =
                "For scripting, testing, feedback, and continued REFramework contributions."
        },
        {
            name = "alphaZomega",
            contribution =
                "For RE Engine research, tools, scripting support, and community contributions."
        },
        {
            name = "Bawkbasoup",
            contribution =
                "For inspiring the vision of expanding Resident Evil 4 into a deeper RPG experience."
        },
        {
            name = "GreenComfyTea",
            contribution =
                "Creator of the Enemy Health Bar mod, whose HUD work inspired parts of Project: Overflow's interface research."
        },
        {
            name = "re_duke",
            contribution =
                "For Resident Evil randomizers and long-standing, continued contributions to the community."
        },
        {
            name = "Resident Evil Modding Community",
            contribution =
                "For shared discoveries, documentation, reverse engineering, tools, testing, and support."
        }
    }
}

function project.version_string()
    return string.format(
        "%s %d.%d.%d",
        project.version.stage,
        project.version.major,
        project.version.minor,
        project.version.patch
    )
end

function project.build_string()
    return "Build " .. tostring(project.version.build)
end

return project
