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
	
	minetest.register_chatcommand("af",
		{
			params = "text",
			description = "send message to all factionsmod",
			privs = { faction_user=true },
			func = factionsmod_chat.allfactionsmod_chathandler,
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

	local player = minetest.env:get_player_by_name(playername)
	local params = parameter:split(" ")
	local cmd = params[1]
	
	--handle common commands
	if parameter == nil or
		parameter == "" then
		
		local playerfactionsmod = factionsmod.get_factionsmod(player)
		
		local tosend = "factionsmod: " .. playername .. " factionsmod:"
		for i,v in ipairs(playerfactionsmod) do
			if i ~= #playerfactionsmod then
				tosend = tosend .. " " .. v .. ","
			else
				tosend = tosend .. " " .. v
			end
		end	
		minetest.chat_send_player(playername, tosend, false)
		return
	end
	
	if cmd == "claim" then
		local playerfaction = factionsmod.get_factionsmod(player)
		if next(playerfaction) ~= nil then
		factionsmod.claim(playerfaction[1],player)
		end
		return
	end
	if cmd == "unclaim" then
		local playerfaction = factionsmod.get_factionsmod(player)
		if next(playerfaction) ~= nil then
		factionsmod.unclaim(playerfaction[1],player)
		end
		return
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
				factionsmod.get_description(params[2]), false)
			return
		end
	end
	
	if cmd == "leave" then
		if params[2] ~= nil then
			if params[3] ~= nil then
				local toremove = minetest.env:get_player_by_name(params[3])
				--allowed if faction_admin, admin of faction or player itself
				if factionsmod.is_admin(params[2],playername) and
					toremove ~= nil then
					
					factionsmod.member_remove(params[2],toremove)
					minetest.chat_send_player(playername, 
						"factionsmod: " .. params[3] .. " has been removed from " 
						.. params[2], false)
					return
				end
			else
				factionsmod.member_remove(params[2],player)
				minetest.chat_send_player(playername, 
						"factionsmod: You have left " .. params[2], false)
				return
			end
		end
	end
	
	--handle superadmin only commands
	--if minetest.check_player_privs(playername,{ faction_admin=true }) then
		--create new faction
		if cmd == "create" then
			if params[2] ~= nil then
				if factionsmod.add_faction(params[2]) then
					minetest.chat_send_player(playername,
						"factionsmod: created faction " .. params[2],
						false)
					if factionsmod.member_add(params[2],minetest.env:get_player_by_name(playername)) then
						minetest.chat_send_player(playername,
							"factionsmod: " .. playername .. " joined faction " ..
							params[2],
							false)
					end
					return
				else
					minetest.chat_send_player(playername,
						"factionsmod: FAILED to created faction " .. params[2],
						false)
					return
				end
			end
		end
	--end

	if cmd == "join" then
		if params[2] ~= nil then	
				--check for invitation
				if factionsmod.is_invited(params[2],playername) then
					if factionsmod.member_add(params[2],player) then
						minetest.chat_send_player(playername,
							"factionsmod: joined faction " ..
							params[2],
							false)
						return
					else
						minetest.chat_send_player(playername,
							"factionsmod: FAILED to join faction " ..
							params[2],
							false)
						return
					end
				else
					minetest.chat_send_player(playername,
						"factionsmod: you are not allowed to join " .. params[2],
						false)
					return
				end	
		end
	end
	
	--all following commands require at least two parameters
	if params[2] ~= nil then
		if minetest.check_player_privs(playername,{ faction_admin=true }) or
			factionsmod.is_admin(params[2],playername) then
			
			--delete faction
			if cmd == "delete" then
				if factionsmod.delete_faction(params[2]) then
					minetest.chat_send_player(playername,
						"factionsmod: deleted faction " .. params[2],
						false)
					return
				else
					minetest.chat_send_player(playername,
						"factionsmod: FAILED to deleted faction " .. params[2],
						false)
					return
				end
			end
			
			if cmd == "set_free" then
				if params[3] ~= nil  and
					(params[3] == "true" or params[3] == "false")then
					
					local value = false
					if params[3] == "true" then
						value = true
					end
					
					if factionsmod.set_free(params[2],value) then
						minetest.chat_send_player(playername,
							"factionsmod: free to join for " .. params[2] .. 
							" has been set to " .. params[3],
							false)
					else
						minetest.chat_send_player(playername,
							"factionsmod: FAILED to set free to join for " ..
							params[2],
							false)
					end
				end
			end
			
			--set player admin status
			if cmd == "admin" then
				if params[3] ~= nil and params[4] ~= nil and
					(params[4] == "true" or params[4] == "false") then
					
					local value = false
					if params[4] == "true" then
						value = true
					end
					
					if factionsmod.set_admin(params[2],params[3],value) then
						minetest.chat_send_player(playername,
							"factionsmod: adminstate of " .. params[3] .. 
							" has been set to " .. params[4],
							false)
					else
						minetest.chat_send_player(playername,
							"factionsmod: FAILED to set admin privileges for " ..
							params[3],
							false)
					end
				end
				return
			end
			
			if cmd == "description" and
				params[2] ~= nil and
				params[3] ~= nil then
				
				local desc = params[3]
				for i=4, #params, 1 do
					desc = desc .. " " .. params[i]
				end
				if factionsmod.set_description(params[2],desc) then
					minetest.chat_send_player(playername,
							"factionsmod: updated description of faction " .. 
							params[2],
							false)
					return
				else
					minetest.chat_send_player(playername,
							"factionsmod: FAILED to update description of faction " .. 
							params[2],
							false)
					return
				end
			end
			
			if cmd == "invite" and
				params[2] ~= nil and
				params[3] ~= nil then
				if factionsmod.member_invite(params[2],params[3]) then
					minetest.chat_send_player(params[3],
							"factionsmod: " .. params[3] .. 
							" you have been invited to join faction " .. params[2],
							false)
					minetest.chat_send_player(playername,
							"factionsmod: " .. params[3] .. 
							" has been invited to join faction " .. params[2],
							false)
					return
				else
					minetest.chat_send_player(playername,
							"factionsmod: FAILED to invite " .. params[3] ..
							" to join faction " .. params[2],
							false)
					return
				end
			end
		end
	end

	factionsmod_chat.show_help(playername)
end

-------------------------------------------------------------------------------
-- name: allfactionsmod_chathandler(playername,parameter)
--
--! @brief chat handler
--! @memberof factionsmod_chat
--! @private
--
--! @param playername name
--! @param parameter data supplied to command
-------------------------------------------------------------------------------
function factionsmod_chat.allfactionsmod_chathandler(playername,parameter)
	
	local player = minetest.env:get_player_by_name(playername)
	
	if player ~= nil then
	  local recipients = {}
	  
	  for faction,value in pairs(factionsmod.get_factionsmod(player)) do
		  for name,value in pairs(factionsmod.dynamic_data.membertable[faction]) do
			  local object_to_check = mientest.env:get_player_by_name(name)
			  
			  if object_to_check ~= nil then
				  recipients[name] = true
			  end
		  end
	  end
	  
	  for recipient,value in pairs(recipients) do
		  if recipient ~= playername then
			  minetest.chat_send_player(recipient,playername ..": " .. parameter,false)
		  end
	  end
	  return
	end
	factionsmod_chat.show_help(playername)
end

-------------------------------------------------------------------------------
-- name: chathandler(playername,parameter)
--
--! @brief chat handler
--! @memberof factionsmod_chat
--! @private
--
--! @param playername name
--! @param parameter data supplied to command
-------------------------------------------------------------------------------
function factionsmod_chat.chathandler(playername,parameter)
	
	local player = minetest.env:get_player_by_name(playername)	
	
	if player ~= nil then
	  local line = parameter:split(" ")	
	  local target_faction = line[1]	

	  local text = line[2]
	  for i=3,#line,1 do
		  text = text .. " " .. line[i]
	  end
	  
	  local valid_faction = false
	  
	  for faction,value in pairs(factionsmod.get_factionsmod(player)) do
		  if target_faction == faction then
			  valid_faction = true
		  end
	  end
	  
	  if faction ~= nil and valid_faction and
	      factionsmod.dynamic_data.membertable[faction] ~= nil then
		  for name,value in pairs(factionsmod.dynamic_data.membertable[faction]) do
			  local object_to_check = mientest.env:get_player_by_name(name)
			  factionsmod_chat.show_help(playername)
			  if object_to_check ~= nil and
				  name ~= playername then
				  minetest.chat_send_player(name,playername ..": " .. text,false)
			  end
		  end
	  else
		  minetest.chat_send_player(playername,
			  "factionsmod: you're not a member of " .. dump(faction),false)
	  end
	  return
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
	MSG("\t\t/factionsmod                      -> info on your current factionsmod")
	MSG("\t\t/factionsmod info <factionname>   -> show description of faction")
	MSG("\t\t/factionsmod list                 -> show list of factionsmod")
	MSG("\t\t/factionsmod leave <factionname>  -> leave specified faction")
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
