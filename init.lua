-------------------------------------------------------------------------------
-- factions Mod by Sapier
--
-- License WTFPL
--
--! @file init.lua
--! @brief factions mod to be used by other mods
--! @copyright Sapier
--! @author Sapier
--! @date 2013-05-08
--!
-- Contact sapier a t gmx net
-------------------------------------------------------------------------------

factions_version = "0.8.0"

core.log("action", "MOD: factions (by sapier) loading ...")

--!path of mod
factions_modpath = minetest.get_modpath("factions")


dofile (factions_modpath .. "/factions.lua")
dofile (factions_modpath .. "/chatcommands.lua")
dofile (factions_modpath .. "/nodes.lua")

factions.load()

core.log("action","MOD: factions (by sapier) " .. factions_version .. " loaded.")
