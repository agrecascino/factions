-------------------------------------------------------------------------------
-- factions Mod by Sapier
--
-- License WTFPL
--
--! @file chatcommnd.lua
--! @brief factions chat interface
--! @copyright Sapier, agrecascino, shamoanjac
--! @author Sapier, agrecascino, shamoanjac
--! @date 2016-08-12
--
-- Contact sapier a t gmx net
-------------------------------------------------------------------------------

local send_error = function(player, message)
    minetest.chat_send_player(player, message)
end

factions_chat = {}

factions.commands = {}

factions.register_command = function(cmd_name, cmd)
    factions.commands[cmd_name] = { -- default command
        name = cmd_name,
        faction_permissions = {},
        global_privileges = {},
        format = {},
        infaction = true,
        description = "This command has no description.",
        run = function(self, player, argv)
            if self.global_privileges then
                local tmp = {}
                for i in ipairs(self.global_privileges) do
                    tmp[self.global_privileges[i]] = true
                end
                local bool, missing_privs = minetest.check_player_privs(player, tmp)
                if not bool then
                    send_error(player, "Unauthorized.")
                end
            end
            -- checks argument formats
            local args = {
                factions = {},
                players = {},
                strings = {},
                other = {}
            }
            if #argv < #(self.format) then
                send_error(player, "Not enough parameters.")
                return false
            end
            for i in ipairs(self.format) do
                local argtype = self.format[i]
                local arg = argv[i]
                if argtype == "faction" then
                    local fac = factions.get_faction(arg)
                    if not fac then
                        send_error(player, "Specified faction "..arg.." does not exist")
                        return false
                    else
                        table.insert(args.factions, fac)
                    end
                elseif argtype == "player" then
                    local pl = minetest.get_player_by_name(arg)
                    if not pl or not factions.players[arg] then
                        send_error(player, "Player is not online.")
                        return false
                    else
                        table.insert(args.players, pl)
                    end
                elseif argtype == "string" then
                    table.insert(args.strings, arg)
                else
                    minetest.log("error", "Bad format definition for function "..self.name)
                    send_error(player, "Internal server error")
                    return false
                end
            end
            for i=#self.format, #argv, 1 do
                table.insert(args.other, argv[i])
            end

            -- checks permissions
            local player_faction = factions.get_player_faction(player)
            if self.infaction and not player_faction then
                minetest.chat_send_player(player, "This command is only available within a faction.")
                return false
            end
            if self.faction_permissions then
                for i in ipairs(self.faction_permissions) do
                    if not player_faction:has_permission(player, self.faction_permissions[i]) then
                        send_error(player, "You don't have permissions to do that.")
                        return false
                    end
                end
            end

            -- get some more data
            local pos = minetest.get_player_by_name(player):getpos()
            local parcelpos = factions.get_parcel_pos(pos)
            return self.on_success(player, player_faction, pos, parcelpos, args)
        end,
        on_success = function(player, faction, pos, parcelpos, args)
            minetest.chat_send_player(player, "Not implemented yet!")
        end
    }
    -- override defaults
    for k, v in pairs(cmd) do
        factions.commands[cmd_name][k] = v
    end
end


local init_commands
init_commands = function()

	minetest.register_privilege("faction_user",
		{
			description = "this user is allowed to interact with faction mod",
			give_to_singleplayer = true,
		}
	)
	
	minetest.register_privilege("faction_admin",
		{
			description = "this user is allowed to create or delete factions",
			give_to_singleplayer = true,
		}
	)
	
	minetest.register_chatcommand("factions",
		{
			params = "<cmd> <parameter 1> .. <parameter n>",
			description = "faction administration functions",
			privs = { interact=true },
			func = factions_chat.cmdhandler,
		}
	)
	
	
	minetest.register_chatcommand("f",
		{
			params = "<command> parameters",
			description = "Factions commands. Type /f help for available commands.",
            privs = { interact=true},
			func = factions_chat.cmdhandler,
		}
	)
end
	

-------------------------------------------
-- R E G I S T E R E D   C O M M A N D S  |
-------------------------------------------

factions.register_command ("claim", {
    faction_permissions = {"claim"},
    description = "Claim the plot of land you're on.",
    on_success = function(player, faction, pos, parcelpos, args)
        local can_claim = faction:can_claim_parcel(parcelpos)
        if can_claim then
            minetest.chat_send_player(player, "Claming parcel "..parcelpos)
            faction:claim_parcel(parcelpos)
            return true
        else
            local parcel_faction = factions.get_parcel_faction(parcelpos)
            if not parcel_faction then
                send_error(player, "You faction cannot claim any (more) parcel(s).")
                return false
            elseif parcel_faction.name == faction.name then
                send_error(player, "This parcel already belongs to your faction.")
                return false
            else
                send_error(player, "This parcel belongs to another faction.")
                return false
            end
        end
    end
})

factions.register_command("unclaim", {
    faction_permissions = {"claim"},
    description = "Unclaim the plot of land you're on.",
    on_success = function(player, faction, pos, parcelpos, args)
        local parcel_faction = factions.get_parcel_faction(parcelpos)
        if parcel_faction.name ~= faction.name then
            send_error(player, "This parcel does not belong to you.")
            return false
        else
            faction:unclaim_parcel(parcelpos)
            return true
        end
    end
})

--list all known factions
factions.register_command("list", {
    description = "List all registered factions.",
    infaction = false,
    on_success = function(player, faction, pos, parcelpos, args)
        local list = factions.get_faction_list()
        local tosend = "Existing factions:"
        
        for i,v in ipairs(list) do
            if i ~= #list then
                tosend = tosend .. " " .. v .. ","
            else
                tosend = tosend .. " " .. v
            end
        end	
        minetest.chat_send_player(player, tosend, false)
        return true
    end
})

--show factions mod version
factions.register_command("version", {
    description = "Displays mod version.",
    on_success = function(player, faction, pos, parcelpos, args)
        minetest.chat_send_player(player, "factions: version " .. factions_version , false)
    end
})

--show description  of faction
factions.register_command("info", {
    format = {"faction"},
    description = "Shows a faction's description.",
    on_success = function(player, faction, pos, parcelpos, args)
        minetest.chat_send_player(player,
            "factions: " .. args.factions[1].name .. ": " ..
            args.factions[1].description, false)
        return true
    end
})

factions.register_command("leave", {
    description = "Leave your faction.",
    on_success = function(player, faction, pos, parcelpos, args)
        faction:remove_player(player)
        return true
    end
})

factions.register_command("kick", {
    faction_permissions = {"playerslist"},
    format = {"player"},
    description = "Kick a player from your faction.",
    on_success = function(player, faction, pos, parcelpos, args)
        local victim = args.players[1]
        local victim_faction = factions.get_player_faction(victim:get_player_name())
        if victim_faction and victim:get_player_name() ~= faction.leader then -- can't kick da king
            faction:remove_player(player)
            return true
        elseif not victim_faction then
            send_error(player, victim:get_player_name().." is not in your faction.")
            return false
        else
            send_error(player, victim:get_player_name().." cannot be kicked from your faction.")
            return false
        end
    end
})

--create new faction
factions.register_command("create", {
    format = {"string"},
    infaction = false,
    description = "Create a new faction.",
    on_success = function(player, faction, pos, parcelpos, args)
        if faction then
            send_error(player, "You are already in a faction.")
            return false
        end
        local factionname = args.strings[1]
        if factions.can_create_faction(factionname) then
            new_faction = factions.new_faction(factionname, nil)
            new_faction:add_player(player, new_faction.default_leader_rank)
            return true
        else
            send_error(player, "Faction cannot be created.")
            return false
        end
    end
})

factions.register_command("join", {
    format = {"faction"},
    description = "Join a faction.",
    infaction = false,
    on_success = function(player, faction, pos, parcelpos, args)
        local new_faction = args.factions[1]
        if new_faction:can_join(player) then
            if faction then -- leave old faction
                faction:remove_player(player)
            end
            new_faction:add_player(player)
        else
            send_error(player, "You cannot join this faction.")
            return false
        end
        return true
    end
})

factions.register_command("disband", {
    faction_permissions = {"disband"},
    description = "Disband your faction.",
    on_success = function(player, faction, pos, parcelpos, args)
        faction:disband()
        return true
    end
})

factions.register_command("close", {
    faction_permissions = {"playerslist"},
    description = "Make your faction invite-only.",
    on_success = function(player, faction, pos, parcelpos, args)
        faction:toggle_join_free(false)
        return true
    end
})

factions.register_command("open", {
    faction_permissions = {"playerslist"},
    description = "Allow any player to join your faction.",
    on_success = function(player, faction, pos, parcelpos, args)
        faction:toggle_join_free(true)
        return true
    end
})

factions.register_command("description", {
    faction_permissions = {"description"},
    description = "Set your faction's description",
    on_success = function(player, faction, pos, parcelpos, args)
        faction:set_description(table.concat(args.other," "))
        return true
    end
})

factions.register_command("invite", {
    format = {"player"},
    faction_permissions = {"playerslist"},
    description = "Invite a player to your faction.",
    on_success = function(player, faction, pos, parcelpos, args)
        faction:invite_player(args.players[1]:get_player_name())
        return true
    end
})

factions.register_command("uninvite", {
    format = {"player"},
    faction_permissions = {"playerslist"},
    description = "Revoke a player's invite.",
    on_success = function(player, faction, pos, parcelpos, args)
        faction:revoke_invite(args.players[1]:get_player_name())
        return true
    end
})

factions.register_command("delete", {
    global_privileges = {"faction_admin"},
    format = {"faction"},
    infaction = false,
    description = "Delete a faction.",
    on_success = function(player, faction, pos, parcelpos, args)
        args.factions[1]:disband()
        return true
    end
})

factions.register_command("ranks", {
    description = "List ranks within your faction",
    on_success = function(player, faction, pos, parcelpos, args)
        for rank, permissions in pairs(faction.ranks) do
            minetest.chat_send_player(player, rank..": "..table.concat(permissions, " "))
        end
        return true
    end
})

factions.register_command("who", {
    description = "List players in your faction, and their ranks.",
    on_success = function(player, faction, pos, parcelpos, args)
        if not faction.players then
            minetest.chat_send_player(player, "There is nobody in this faction ("..faction.name..")")
            return true
        end
        minetest.chat_send_player(player, "Players in faction "..faction.name..": ")
        for p, rank in pairs(faction.players) do
            minetest.chat_send_player(player, p.." ("..rank..")")
        end
        return true
    end
})

factions.register_command("newrank", {
    description = "Add a new rank.",
    format = {"string"},
    faction_permissions = {"ranks"},
    on_success = function(player, faction, pos, parcelpos, args)
        local rank = args.strings[1]
        if #rank > factions.rank then
            send_error(player, "Go away Todd")
            return false
        end
        if faction.ranks[rank] then
            send_error(player, "Rank already exists")
            return false
        end
        faction:add_rank(rank, args.other)
        return true
    end
})

factions.register_command("delrank", {
    description = "Replace and delete a rank.",
    format = {"string", "string"},
    faction_permissions = {"ranks"},
    on_success = function(player, faction, pos, parcelpos, args)
        local rank = args.strings[1]
        local newrank = args.strings[2]
        if not faction.ranks[rank] or not faction.ranks[newrank] then
            send_error(player, "One of the specified ranks do not exist.")
            return false
        end
        faction:delete_rank(rank, newrank)
        return true
    end
})

factions.register_command("setspawn", {
    description = "Set the faction's spawn",
    faction_permissions = {"spawn"},
    on_success = function(player, faction, pos, parcelpos, args)
        faction:set_spawn(pos)
        return true
    end
})

factions.register_command("where", {
    description = "See whose parcel you stand on.",
    infaction = false,
    on_success = function(player, faction, pos, parcelpos, args)
        local parcel_faction = factions.get_parcel_faction(parcelpos)
        local place_name = (parcel_faction and parcel_faction.name) or "Wilderness"
        minetest.chat_send_player(player, "You are standing on parcel "..parcelpos..", part of "..place_name)
        return true
    end
})

factions.register_command("help", {
    description = "Shows help for commands.",
    infaction = false,
    on_success = function(player, faction, pos, parcelpos, args)
        factions_chat.show_help(player)
        return true
    end
})

factions.register_command("spawn", {
    description = "Shows your faction's spawn",
    on_success = function(player, faction, pos, parcelpos, args)
        if faction.spawn then
            minetest.chat_send_player(player, "Spawn is at ("..table.concat(faction.spawn, ", ")..")")
            return true
        else
            minetest.chat_send_player(player, "Your faction has no spawn set.")
            return false
        end
    end
})

factions.register_command("promote", {
    description = "Promotes a player to a rank",
    format = {"player", "string"},
    faction_permissions = {"promote"},
    on_success = function(player, faction, pos, parcelpos, args)
        local rank = args.strings[1]
        if faction.ranks[rank] then
            faction:promote(args.players[1]:get_player_name(), rank)
            return true
        else
            send_error(player, "The specified rank does not exist.")
            return false
        end
    end
})

factions.register_command("power", {
    description = "Display your faction's power",
    on_success = function(player, faction, pos, parcelpos, args)
        minetest.chat_send_player(player, "Power: "..faction.power.."/"..faction.maxpower - faction.usedpower.."/"..faction.maxpower)
        return true
    end
})

factions.register_command("setbanner", {
    description = "Sets the banner you're on as the faction's banner.",
    faction_permissions = {"banner"},
    on_success = function(player, faction, pos, parcelpos, args)
        local meta = minetest.get_meta({x = pos.x, y = pos.y - 1, z = pos.z})
        local banner = meta:get_string("banner")
        if not banner then
            minetest.chat_send_player(player, "No banner found.")
            return false
        end
        faction:set_banner(banner)
    end
})

factions.register_command("convert", {
    description = "Load factions in the old format",
    infaction = false,
    global_privileges = {"faction_admin"},
    format = {"string"},
    on_success = function(player, faction, pos, parcelpos, args)
        if factions.convert(args.strings[1]) then
            minetest.chat_send_player(player, "Factions successfully converted.")
        else
            minetest.chat_send_player(player, "Error.")
        end
        return true
    end
})

factions.register_command("free", {
    description = "Forcefully frees a parcel",
    infaction = false,
    global_privileges = {"faction_admin"},
    on_success = function(player, faction, pos, parcelpos, args)
        local parcel_faction = factions.get_parcel_faction(parcelpos)
        if not parcel_faction then
            send_error(player, "No claim at this position")
            return false
        else
            parcel_faction:unclaim_parcel(parcelpos)
            return true
        end
    end
})

factions.register_command("chat", {
    description = "Send a message to your faction's members",
    on_success = function(player, faction, pos, parcelpos, args)
        local msg = table.concat(args.other, " ")
        faction:broadcast(msg, player)
    end
})

factions.register_command("forceupdate", {
    description = "Forces an update tick.",
    global_privileges = {"faction_admin"},
    on_success = function(player, faction, pos, parcelpos, args)
        factions.faction_tick()
    end
})

-------------------------------------------------------------------------------
-- name: cmdhandler(playername,parameter)
--
--! @brief chat command handler
--! @memberof factions_chat
--! @private
--
--! @param playername name
--! @param parameter data supplied to command
-------------------------------------------------------------------------------
factions_chat.cmdhandler = function (playername,parameter)

	local player = minetest.env:get_player_by_name(playername)
	local params = parameter:split(" ")
    local player_faction = factions.get_player_faction(playername)

	if parameter == nil or
		parameter == "" then
        if player_faction then
            minetest.chat_send_player(playername, "You are in faction "..player_faction.name..". Type /f help for a list of commands.")
        else
            minetest.chat_send_player(playername, "You are part of no faction")
        end
		return
	end

	local cmd = factions.commands[params[1]]
    if not cmd then
        send_error(playername, "Unknown command.")
        return false
    end

    local argv = {}
    for i=2, #params, 1 do
        table.insert(argv, params[i])
    end
	
    cmd:run(playername, argv)

end

-------------------------------------------------------------------------------
-- name: show_help(playername,parameter)
--
--! @brief send help message to player
--! @memberof factions_chat
--! @private
--
--! @param playername name
-------------------------------------------------------------------------------
function factions_chat.show_help(playername)

	local MSG = function(text)
		minetest.chat_send_player(playername,text,false)
	end
	
	MSG("factions mod")
	MSG("Usage:")
    for k, v in pairs(factions.commands) do
        local args = {}
        for i in ipairs(v.format) do
            table.insert(args, v.format[i])
        end
        MSG("\t/factions "..k.." <"..table.concat(args, "> <").."> : "..v.description)
    end
end

init_commands()

