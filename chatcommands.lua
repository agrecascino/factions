-------------------------------------------------------------------------------
-- factionsmod Mod by Sapier
--
-- License WTFPL
--
--! @file chatcommnd.lua
--! @brief factionsmod chat interface
--! @copyright Sapier
--! @author Sapier
--! @date 2013-05-08
--
-- Contact sapier a t gmx net
-------------------------------------------------------------------------------

--! @class factionsmod_chat
--! @brief chat interface class
factionsmod_chat = {}

-------------------------------------------------------------------------------
-- name: init()
--
--! @brief initialize chat interface
--! @memberof factionsmod_chat
--! @public
-------------------------------------------------------------------------------
function factionsmod_chat.init()

	minetest.register_privilege("faction_user",
		{
			description = "this user is allowed to interact with faction mod",
			give_to_singleplayer = true,
		}
	)
	
	minetest.register_privilege("faction_admin",
		{
			description = "this user is allowed to create or delete factionsmod",
			give_to_singleplayer = true,
		}
	)
	
	minetest.register_chatcommand("factionsmod",
		{
			params = "<cmd> <parameter 1> .. <parameter n>",
			description = "faction administration functions",
			privs = { interact=true },
			func = factionsmod_chat.cmdhandler,
		}
	)
	
	
	minetest.register_chatcommand("f",
		{
			params = "<factionname> text",
			description = "send message to a specific faction",
			privs = { faction_user=true },
			func = factionsmod_chat.chathandler,
		}
	)
end

-------------------------------------------------------------------------------
-- name: cmdhandler(playername,parameter)
--
--! @brief chat command handler
--! @memberof factionsmod_chat
--! @private
--
--! @param playername name
--! @param parameter data supplied to command
-------------------------------------------------------------------------------
function factionsmod_chat.cmdhandler(playername,parameter)

    --let's not duplicate code
	local player = minetest.env:get_player_by_name(playername)
	local params = parameter:split(" ")
	local cmd = params[1]
    local player_faction = factionsmod[playername]
    local player_position = player:getpos()
    local chunk = factionsmod.get_chunk(player_position)
    local chunkpos = factionsmod.get_chunkpos(player_position)
	
	--handle common commands
	if parameter == nil or
		parameter == "" then
        if player_faction then
            minetest.chat_send_player(playername, player_faction.description)
        else
            --TODO: message, no faction
        end
		return
	end
	
	if cmd == "claim" then
        if player_faction:has_permission(playername, "claim") then
            if not chunk then
                player_faction:claim_chunk(chunkpos)
            else
                if chunk == player_faction.name then
                    --TODO: error (chunk already claimed by faction)
                else
                    --TODO: error (chunk claimed by another faction)
                end
            end
        else
            --TODO: error message (no permission to claim)
        end
		return
	end

	if cmd == "unclaim" then
        if player_faction:has_permission(playername, "claim") then
            if chunk ~= player_faction.name then
                --TODO: error (not your faction's chunk)
            else
                player_faction:unclaim_chunk(chunkpos)
            end
        else
            --TODO: error (no permission to claim)
        end
	end

	--list all known factionsmod
	if cmd == "list" then
		local list = factionsmod.get_faction_list()
		local tosend = "factionsmod: current available factionsmod:"
		
		for i,v in ipairs(list) do
			if i ~= #list then
				tosend = tosend .. " " .. v .. ","
			else
				tosend = tosend .. " " .. v
			end
		end	
		minetest.chat_send_player(playername, tosend, false)
		return
	end
	
	--show factionsmod mod version
	if cmd == "version" then
		minetest.chat_send_player(playername, "factionsmod: version " .. factionsmod_version , false)
		return
	end
	
	--show description  of faction
	if cmd == "info" then
		if params[2] ~= nil then
			minetest.chat_send_player(playername,
				"factionsmod: " .. params[2] .. ": " ..
				factionsmod.factions[params[2]].description, false)
			return
		end
	end
	
	if cmd == "leave" then
        player_faction:remove_player(playername)
        --TODO: message?
	end

    if cmd == "kick" then
        if param[2] then
            if player_faction:has_permission(playername, "playerlist") then
                player_faction:remove_player(playername)
                --TODO: message?
            else
                --TODO: error (no permissions)
            end
        else
            --TODO: error (no player specified)
        end
    end
	
    --create new faction
    if cmd == "create" then
        if params[2] ~= nil then
            local factioname = params[2]
            if factionsmod.can_create_faction(factionname) then
                player_faction = factionsmod.create_faction(faction)
                player_faction:add_player(playername)
                player_faction:set_leader(playername)
            else
                --TODO: error (cannot create faction)
            end
        else
            --TODO: error (help message?)
        end
    end

	if cmd == "join" then
		if params[2] then	
            local factionname = params[2]
            local faction = factionsmod.factons[factionname]
            if not faction then
                --TODO: error (faction doesn't exist)
            else
                if faction:can_join(playername) then
                    if player_faction then -- leave old faction
                        player_faction:remove_player(playername)
                        --TODO: message
                    end
                    faction:add_player(playername)
                else
                    --TODO: error (could not join faction)
                end
            end	
		end
	end

    if cmd == "disband" then
        if player_faction:has_permission(playername, "disband") then
            player_faction:disband()
        else
            --TODO: error (no permission)
        end
    end

    if cmd == "close" then
        if player_faction:has_permission(playername, "playerlist") then
            player_faction:toggle_join_free(false)
        else
            --TODO: error (no permission)
        end
    end

    if cmd == "open" then
        if player_faction:has_permission(playername, "playerlist") then
            player_faction:toggle_join_free(true)
        else
            --TODO: error (no permission)
        end
    end

    if cmd == "description" then
        if player_faction:has_permission(playername, "description") then
            local description = {}
            for i=2, #params, 1 do
                table.insert(description, params[i])
            end
            player_faction:set_description(description.concat(" "))
        else
            --TODO: error (no permission)
        end
    end

    if cmd == "invite" then
        if params[2] then
            if player_faction:has_permission(playername, "playerlist") then
                player_faction:invite_player(params[2])
            else
                --TODO: error (no permission)
            end
        else
            --TODO: error (player unspecified)
        end
    end

    if cmd == "uninvite" then
        if params[2] then
            if player_faction:has_permission(playername, "playerlist") then
                player_faction:revoke_invite(params[2])
            else
                --TODO: error (no permission)
            end
        else
            --TODO: error (player unspecified)
        end
    end
	
	--all following commands require at least two parameters
	if params[2] then
		if minetest.check_player_privs(playername,{ faction_admin=true }) then
			
			--delete faction
			if cmd == "delete" then
                faction = factionsmod.factions[params[2]]
                if faction then
                    faction:disband()
                    --TODO: message
                else
                    --TODO: error (no such faction)
                end
			end
			
		end
	end

	factionsmod_chat.show_help(playername)
end

-------------------------------------------------------------------------------
-- name: show_help(playername,parameter)
--
--! @brief send help message to player
--! @memberof factionsmod_chat
--! @private
--
--! @param playername name
-------------------------------------------------------------------------------
function factionsmod_chat.show_help(playername)

	local MSG = function(text)
		minetest.chat_send_player(playername,text,false)
	end
	
	MSG("factionsmod mod")
	MSG("Usage:")
	MSG("\tUser commands:")
	MSG("\t\t/factionsmod                      -> info on your current faction")
	MSG("\t\t/factionsmod info <factionname>   -> show description of faction")
	MSG("\t\t/factionsmod list                 -> show list of factions")
	MSG("\t\t/factionsmod leave                -> leave current faction")
	MSG("\t\t/factionsmod join <factionname>   -> join specified faction")
	MSG("\t\t/factionsmod version              -> show version number of mod")
	
	MSG("\tAdmin commands:")
	MSG("\t\t/factionsmod create <factionname> -> create a new faction")
	MSG("\t\t/factionsmod delete <factionname> -> delete a faction faction")
	MSG("\t\t/factionsmod leave <factionname> <playername> -> remove player from faction")
	MSG("\t\t/factionsmod invite <factionname> <playername> -> invite player to faction")
	MSG("\t\t/factionsmod set_free <factionname> <value> -> set faction free to join")
	MSG("\t\t/factionsmod admin <factionname> <playername> <value> -> make player admin of faction")
	MSG("\t\t/factionsmod description <factionname> <text> -> set description for faction")
end

