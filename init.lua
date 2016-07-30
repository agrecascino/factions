-------------------------------------------------------------------------------
-- factionsmod Mod by Sapier
--
-- License WTFPL
--
--! @file init.lua
--! @brief factionsmod mod to be used by other mods
--! @copyright Sapier
--! @author Sapier
--! @date 2013-05-08
--!
-- Contact sapier a t gmx net
-------------------------------------------------------------------------------

local factionsmod_version = "0.1.6"

core.log("action", "MOD: factionsmod (by sapier) loading ...")

--!path of mod
factionsmod_modpath = minetest.get_modpath("factionsmod")


dofile (factionsmod_modpath .. "/factionsmod.lua")
dofile (factionsmod_modpath .. "/chatcommands.lua")

factionsmod.load()
factionsmod_chat.init()

core.log("action","MOD: factionsmod (by sapier) " .. factionsmod_version .. " loaded.")
