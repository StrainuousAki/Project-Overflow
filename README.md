# Project: Overflow
Project: Overflow is an RPG progression overhaul for Resident Evil 4 Remake.  The goal of Project: Overflow is to expand Leon’s progression beyond the vanilla health and weapon systems by introducing leveling, attributes, XP, persistent character profiles, enemy rewards, expanded health, custom interfaces, and other RPG-inspired mechanics

# Current features

Project: Overflow currently includes:
Character levels and XP
Attribute-based progression
Expanded Max HP and overflow health rings
Enemy XP and reward tracking
Persistent RPG profiles linked to native saves
A custom progression interface
Modified healing, melee damage, critical hits, reload speed, fire rate, and other derived effects
Enemy database and BioRand compatibility systems
Development and diagnostic tools for testing and troubleshooting
Project: Overflow is still actively being developed, so some systems may change as balance, compatibility, and stability improve.

# Current development focus

My current priorities include:
Improving save and load stability
Expanding enemy and boss database coverage
Refining progression pacing and balance
Improving UI presentation and resolution compatibility
Testing normal and randomized playthroughs
Expanding XP, rewards, attributes, and combat interactions
Fixing compatibility issues with unusual enemy variants and other mods

# Requirements

Resident Evil 4 Remake
A compatible version of REFramework
A backup of your save files is strongly recommended
BioRand is optional and is not required for a normal playthrough.

# Installation

Install the required version of REFramework.
Download the attached project_overflow.zip.
Extract the ZIP file.
Copy the included reframework folder into your main Resident Evil 4 installation directory.
Merge folders when prompted.
Launch the game.
Open the REFramework overlay and confirm that Project: Overflow appears.
Do not place the ZIP itself directly into the game directory. It must be extracted first.
Back up your saves before installing or testing any mod.

# BioRand compatibility

Project: Overflow supports BioRand enemy data, but the correct manifest for your active seed must be copied into the mod’s manifest folder.
After generating or launching your BioRand seed, locate:
output_leon.log
Copy it into:
reframework/data/project_overflow/manifests/
The final path should be:
reframework/data/project_overflow/manifests/output_leon.log
Project: Overflow reads this file to improve identification of randomized enemy placements, XP values, rewards, and database compatibility.
Important:
Use the output_leon.log generated for the seed you are currently playing.
Copy the new file again whenever you switch or regenerate BioRand seeds.
Using a manifest from a different seed may cause incorrect enemy identification or reward data.
This file is only required when playing with BioRand enabled.

# Known issues

Project: Overflow remains in active development. Current known limitations may include:
Some BioRand replacement enemies may not report their identity or death state correctly.
Some bosses and rare enemy variants still need complete database entries.
Certain scripted or malformed BioRand enemies may fail to finalize their normal death and reward behavior.
UI behavior may vary depending on resolution, display mode, or other REFramework scripts.
Development builds may contain bugs, incomplete systems, or balance issues.

# Bug reports and feedback

When reporting a bug, please include:
Your Project: Overflow build number
Your game version
Your REFramework version
Whether BioRand or other gameplay mods are active
Your active BioRand seed, when applicable
Steps to reproduce the issue
Screenshots, logs, or video when possible
Detailed reports make it much easier to reproduce and fix problems.

# Support and access

Project: Overflow is a fan-made modification and is not being sold.
Patreon support helps fund development time, testing, software, tools, and my broader 3D artwork. Access to the public mod is not locked behind a paid membership.

# Support me on Patreon

Supporters may receive development updates, work-in-progress previews, technical breakdowns, polls, recognition, and optional testing opportunities when suitable builds are available.

https://patreon.com/StrainuousAkisLounge?utm_medium=unknown&utm_source=join_link&utm_campaign=creatorshare_creator&utm_content=copyLink

# Credits and thanks

Project: Overflow would not be possible without the work of the Resident Evil modding community.
Special thanks to:
The REFramework developers and contributors
The BioRand team
The Ultimate Trainer developers
The modding researchers and tool creators who document RE Engine systems
Friends and testers who have provided feedback, screenshots, saves, and playtesting
Everyone following, supporting, and helping improve the project
Project: Overflow is not affiliated with or endorsed by Capcom.
All trademarks, characters, and original game assets belong to their respective owners.

