-------------------------------------------------------------------------------
-- factionsmod Mod by Sapier
--
-- License WTFPL
--
--! @file factionsmod.lua
--! @brief factionsmod core file containing datastorage
--! @copyright Sapier
--! @author Sapier
--! @date 2013-05-08
--
-- Contact sapier a t gmx net
-------------------------------------------------------------------------------

--read some basic information
local factionsmod_worldid = minetest.get_worldpath()

--! @class factionsmod
--! @brief main class for factionsmod
factionsmod = {}

--! @brief runtime data
factionsmod.data = {}
factionsmod.data.factionsmod = {}
factionsmod.data.objects = {}
factionsmod.dynamic_data = {}
factionsmod.dynamic_data.membertable = {}

factionsmod.print = function(text)
	print("factionsmod: " .. dump(text))
end

factionsmod.dbg_lvl1 = function() end --factionsmod.print  -- errors
factionsmod.dbg_lvl2 = function() end --factionsmod.print  -- non cyclic trace
factionsmod.dbg_lvl3 = function() end --factionsmod.print  -- cyclic trace

-------------------------------------------------------------------------------
-- name: add_faction(name)
--
--! @brief add a faction
--! @memberof factionsmod
--! @public
--
--! @param name of faction to add
--!
--! @return true/false (succesfully added faction or not)
-------------------------------------------------------------------------------
function factionsmod.add_faction(name)

	if factionsmod.data.factionsmod[name] == nil then
		factionsmod.data.factionsmod[name] = {}
		factionsmod.data.factionsmod[name].reputation = {}
		factionsmod.data.factionsmod[name].base_reputation = {}
		factionsmod.data.factionsmod[name].adminlist = {}
		factionsmod.data.factionsmod[name].invitations = {}
		factionsmod.data.factionsmod[name].owner = ""
		
		factionsmod.dynamic_data.membertable[name] = {}
		
		factionsmod.save()
		
		return true
	end

	return false
end

-------------------------------------------------------------------------------
-- name: set_base_reputation(faction1,faction2,value)
--
--! @brief set base reputation between two factionsmod
--! @memberof factionsmod
--! @public
--
--! @param faction1 first faction
--! @param faction2 second faction
--! @param value value to use
--!
--! @return true/false (succesfully added faction or not)
-------------------------------------------------------------------------------
function factionsmod.set_base_reputation(faction1,faction2,value)

	if factionsmod.data.factionsmod[faction1] ~= nil and
		factionsmod.data.factionsmod[faction2] ~= nil then
		
		factionsmod.data.factionsmod[faction1].base_reputation[faction2] = value
		factionsmod.data.factionsmod[faction2].base_reputation[faction1] = value
		factionsmod.save()
		return true
	end
	return false
end

-------------------------------------------------------------------------------
-- name: get_base_reputation(faction1,faction2)
--
--! @brief get base reputation between two factionsmod
--! @memberof factionsmod
--! @public
--
--! @param faction1 first faction
--! @param faction2 second faction
--!
--! @return reputation/0 if none set
-------------------------------------------------------------------------------
function factionsmod.get_base_reputation(faction1,faction2)
	factionsmod.dbg_lvl3("get_base_reputation: "  .. faction1 .. "<-->" .. faction2)
	if factionsmod.data.factionsmod[faction1] ~= nil and
		factionsmod.data.factionsmod[faction2] ~= nil then
		if factionsmod.data.factionsmod[faction1].base_reputation[faction2] ~= nil then
			return factionsmod.data.factionsmod[faction1].base_reputation[faction2]
		end
	end
	return 0
end

-------------------------------------------------------------------------------
-- name: set_description(name,description)
--
--! @brief set description for a faction
--! @memberof factionsmod
--! @public
--
--! @param name of faction
--! @param description text describing a faction
--!
--! @return true/false (succesfully set description)
-------------------------------------------------------------------------------
function factionsmod.set_description(name,description)

	if factionsmod.data.factionsmod[name] ~= nil then
		factionsmod.data.factionsmod[name].description = description
		factionsmod.save()
		return true
	end
	return false
end

-------------------------------------------------------------------------------
-- name: get_description(name)
--
--! @brief get description for a faction
--! @memberof factionsmod
--! @public
--
--! @param name of faction
--!
--! @return description or ""
-------------------------------------------------------------------------------
function factionsmod.get_description(name)

	if factionsmod.data.factionsmod[name] ~= nil and
		factionsmod.data.factionsmod[name].description ~= nil then
		return factionsmod.data.factionsmod[name].description
	end
	return ""
end

-------------------------------------------------------------------------------
-- name: exists(name)
--
--! @brief check if a faction exists
--! @memberof factionsmod
--! @public
--! @param name name to check
--!
--! @return true/false
-------------------------------------------------------------------------------
function factionsmod.exists(name)
	
	for key,value in pairs(factionsmod.data.factionsmod) do
		if key == name then
			return true
		end
	end
	
	return false
end

-------------------------------------------------------------------------------
-- name: get_faction_list()
--
--! @brief get list of factionsmod
--! @memberof factionsmod
--! @public
--!
--! @return list of factionsmod
-------------------------------------------------------------------------------
function factionsmod.get_faction_list()

	local retval = {}
	
	for key,value in pairs(factionsmod.data.factionsmod) do
		table.insert(retval,key)
	end
	
	return retval
end

-------------------------------------------------------------------------------
-- name: delete_faction(name)
--
--! @brief delete a faction
--! @memberof factionsmod
--! @public
--
--! @param name of faction to delete
--!
--! @return true/false (succesfully added faction or not)
-------------------------------------------------------------------------------
function factionsmod.delete_faction(name)

	factionsmod.data.factionsmod[name] = nil
	
	factionsmod.save()
	
	if factionsmod.data.factionsmod[name] == nil then
		return true
	end

	return false
end

-------------------------------------------------------------------------------
-- name: member_add(name,object)
--
--! @brief add an entity or player to a faction
--! @memberof factionsmod
--! @public
--
--! @param name of faction to add object to
--! @param object to add to faction
--!
--! @return true/false (succesfully added faction or not)
-------------------------------------------------------------------------------
function factionsmod.claim()
end
function factionsmod.unclaim()
end
function factionsmod.member_add(name, object)
	local new_entry = {}
	new_entry.factionsmod = {}
	
	if object.object ~= nil then
		object = object.object
	end
	if next(factionsmod.get_factionsmod(object)) ~= nil then
		for k,v in pairs(factionsmod.get_factionsmod(object)) do
			if k ~= nil then
				factionsmod.member_remove(k,object)
			end
		end
	end
	if not factionsmod.exists(name) then
		print("Unable to add to NON existant faction >" .. name .. "<")
		return false
	end
	
	new_entry.name,new_entry.temporary = factionsmod.get_name(object)
	
	factionsmod.dbg_lvl2("Adding name=" .. dump(new_entry.name) .. " to faction: " .. name )
	
	if new_entry.name ~= nil then
		if factionsmod.data.objects[new_entry.name] == nil then
			factionsmod.data.objects[new_entry.name] = new_entry
		end
		
		if factionsmod.data.objects[new_entry.name].factionsmod[name] == nil then
			factionsmod.data.objects[new_entry.name].factionsmod[name] = true
			factionsmod.dynamic_data.membertable[name][new_entry.name] = true
			factionsmod.data.factionsmod[name].invitations[new_entry.name] = nil
			if factionsmod.data.factionsmod[name].owner == "" then
				factionsmod.data.factionsmod[name].owner = object:get_player_name()
				factionsmod.set_admin(name,object:get_player_name(), true)
			end
			factionsmod.save()
			return true
		end
	end
	
	--return false if no valid object or already member
	return false
end

-------------------------------------------------------------------------------
-- name: member_invite(name,playername)
--
--! @brief invite a player for joining a faction
--! @memberof factionsmod
--! @public
--
--! @param name of faction to add object to
--! @param name of player to invite
--!
--! @return true/false (succesfully added invitation or not)
-------------------------------------------------------------------------------
function factionsmod.member_invite(name, playername)

	if factionsmod.data.factionsmod[name] ~= nil and
		factionsmod.data.factionsmod[name].invitations[playername] == nil then
		factionsmod.data.factionsmod[name].invitations[playername] = true
		factionsmod.save()
		return true
	end
	
	--return false if not a valid faction or player already invited
	return false
end

-------------------------------------------------------------------------------
-- name: member_remove(name,object)
--
--! @brief remove an entity or player to a faction
--! @memberof factionsmod
--! @public
--
--! @param name of faction to add object to
--! @param object to add to faction
--!
--! @return true/false (succesfully added faction or not)
-------------------------------------------------------------------------------
function factionsmod.member_remove(name,object)

	local id,type = factionsmod.get_name(object)
	
	factionsmod.dbg_lvl2("removing name=" .. dump(id) .. " to faction: " .. name )
	
	if id ~= nil and
		factionsmod.data.objects[id] ~= nil and
		factionsmod.data.objects[id].factionsmod[name] ~= nil then
		factionsmod.data.objects[id].factionsmod[name] = nil
		factionsmod.dynamic_data.membertable[name][id] = nil
		if factionsmod.data.factionsmod[name].owner == object:get_player_name() then
			factionsmod.delete_faction(name)
		end
		factionsmod.save()
		return true
	end
	
	if id ~= nil and
		factionsmod.data.factionsmod[name].invitations[id] ~= nil then
		factionsmod.data.factionsmod[name].invitations[id] = nil
		factionsmod.save()
		return true
	end

	return false
end

-------------------------------------------------------------------------------
-- name: set_admin(name,playername,value)
--
--! @brief set admin priviles for a playername
--! @memberof factionsmod
--! @public
--
--! @param name of faction to add object to
--! @param playername to change rights
--! @param value true/false has or has not admin privileges
--!
--! @return true/false (succesfully changed privileges)
-------------------------------------------------------------------------------
function factionsmod.set_admin(name,playername,value)
	mobf_assert_backtrace(type(playername) == "string")
	if factionsmod.data.factionsmod[name] ~= nil then
		if value then
			factionsmod.data.factionsmod[name].adminlist[playername] = true
			factionsmod.save()
			return true
		else
			factionsmod.data.factionsmod[name].adminlist[playername] = nil
			factionsmod.save()
			return true
		end
	else
		print("factionsmod: no faction >" .. name .. "< found")
	end

	return false
end

-------------------------------------------------------------------------------
-- name: set_free(name,value)
--
--! @brief set faction to be joinable by everyone
--! @memberof factionsmod
--! @public
--
--! @param name of faction to add object to
--! @param value true/false has or has not admin privileges
--!
--! @return true/false (succesfully added faction or not)
-------------------------------------------------------------------------------
function factionsmod.set_free(name,value)

	if factionsmod.data.factionsmod[name] ~= nil then
		if value then
			if factionsmod.data.factionsmod[name].open == nil then
				factionsmod.data.factionsmod[name].open = true
				factionsmod.save()
				return true
			else
				return false
			end
		else
			if factionsmod.data.factionsmod[name].open == nil then
				return false
			else
				factionsmod.data.factionsmod[name].open = nil
				factionsmod.save()
				return true
			end
		end
	end

	return false
end

-------------------------------------------------------------------------------
-- name: is_free(name)
--
--! @brief check if a fraction is free to join
--! @memberof factionsmod
--! @public
--
--! @param name of faction to add object to
--
--! @return true/false (free or not)
-------------------------------------------------------------------------------
function factionsmod.is_free(name)
	if factionsmod.data.factionsmod[name] ~= nil and
		factionsmod.data.factionsmod[name].open then
			return true
	end
	
	return false
end

-------------------------------------------------------------------------------
-- name: is_admin(name,playername)
--
--! @brief read admin privilege of player
--! @memberof factionsmod
--! @public
--
--! @param name of faction to check rights
--! @param playername to change rights
--!
--! @return true/false (succesfully added faction or not)
-------------------------------------------------------------------------------
function factionsmod.is_admin(name,playername)

	if factionsmod.data.factionsmod[name] ~= nil and
		factionsmod.data.factionsmod[name].adminlist[playername] == true then
		return true
	end
	
	return false
end

-------------------------------------------------------------------------------
-- name: is_invited(name,playername)
--
--! @brief read invitation status of player
--! @memberof factionsmod
--! @public
--
--! @param name of faction to check for invitation
--! @param playername to change rights
--!
--! @return true/false (succesfully added faction or not)
-------------------------------------------------------------------------------
function factionsmod.is_invited(name,playername)

	if factionsmod.data.factionsmod[name] ~= nil and
		( factionsmod.data.factionsmod[name].invitations[playername] == true or
		factionsmod.data.factionsmod[name].open == true) then
		return true
	end
	
	return false
end

-------------------------------------------------------------------------------
-- name: get_factionsmod(object)
--
--! @brief get list of factionsmod for an object
--! @memberof factionsmod
--! @public
--
--! @param object to get list for
--!
--! @return list of factionsmod
-------------------------------------------------------------------------------
function factionsmod.get_factionsmod(object)

	local id,type = factionsmod.get_name(object)
	
	local retval = {}
	if id ~= nil and
		factionsmod.data.objects[id] ~= nil then
		for key,value in pairs(factionsmod.data.objects[id].factionsmod) do
			table.insert(retval,key)
		end
	end
	
	return retval
end

-------------------------------------------------------------------------------
-- name: is_member(name,object)
--
--! @brief check if object is member of name
--! @memberof factionsmod
--! @public
--
--! @param name of faction to check
--! @param object to check
--!
--! @return true/false
-------------------------------------------------------------------------------
function factionsmod.is_member(name,object)

	local retval = false
	
	local id,type = factionsmod.get_name(object)

	if id ~= nil and
		factionsmod.data.objects[id] ~= nil then
		for key,value in pairs(factionsmod.data.objects[id].factionsmod) do
			if key == name then
				retval = true
				break
			end
		end
	end
	
	return retval
end


-------------------------------------------------------------------------------
-- name: get_reputation(name,object)
--
--! @brief get reputation of an object
--! @memberof factionsmod
--! @public
--
--! @param name name of faction to check for reputation
--! @param object object to get reputation for
--!
--! @return number value -100 to 100 0 being neutral, -100 beeing enemy 100 friend
-------------------------------------------------------------------------------
function factionsmod.get_reputation(name,object)

	local id,type = factionsmod.get_name(object)
	
	factionsmod.dbg_lvl3("get_reputation: "  .. name .. "<-->" .. dump(id))
	
	if id ~= nil and
		factionsmod.data.factionsmod[name] ~= nil then
		
		factionsmod.dbg_lvl3("get_reputation: object reputation: "  .. dump(factionsmod.data.factionsmod[name].reputation[id]))
		
		if factionsmod.data.factionsmod[name].reputation[id] == nil then
			factionsmod.data.factionsmod[name].reputation[id]
				= factionsmod.calc_base_reputation(name,object)
		end

		return factionsmod.data.factionsmod[name].reputation[id]
	else
		factionsmod.dbg_lvl3("get_reputation: didn't find any factionsmod for: "  .. name)
	end

	return 0
end

-------------------------------------------------------------------------------
-- name: modify_reputation(name,object,delta)
--
--! @brief modify reputation of an object for a faction
--! @memberof factionsmod
--! @public
--
--! @param name name of faction to modify reputation
--! @param object object to change reputation
--! @param delta value to change reputation
--!
--! @return true/false
-------------------------------------------------------------------------------
function factionsmod.modify_reputation(name,object,delta)
	
	local id,type = factionsmod.get_name(object)
	
	if factionsmod.data.factionsmod[name] ~= nil then
		if factionsmod.data.factionsmod[name].reputation[id] == nil then
			factionsmod.data.factionsmod[name].reputation[id]
				= factionsmod.calc_base_reputation(name,object)
		end
		
		factionsmod.data.factionsmod[name].reputation[id]
			= factionsmod.data.factionsmod[name].reputation[id] + delta
		factionsmod.save()
		return true
	end
	
	return false
end

-------------------------------------------------------------------------------
-- name: get_name(object)
--
--! @brief get textual name of object
--! @memberof factionsmod
--! @private
--
--! @param object fetch name for this
--!
--! @return name or nil,is temporary element
-------------------------------------------------------------------------------
function factionsmod.get_name(object)
	if object == nil then
		return nil,true
	end
	
	if object.object ~= nil then
		object = object.object
	end
	
	if object:is_player() then
		return object:get_player_name(),false
	else
		local luaentity = object:get_luaentity()
		
		if luaentity ~= nil then
			return tostring(luaentity),true
		end
	end
	
	return nil,true
end

-------------------------------------------------------------------------------
-- name: calc_base_reputation(name,object)
--
--! @brief calculate initial reputation of object within a faction
--! @memberof factionsmod
--! @private
--
--! @param name name of faction
--! @param object calc reputation for this
--!
--! @return reputation value
-------------------------------------------------------------------------------
function factionsmod.calc_base_reputation(name,object)

	--calculate initial reputation based uppon all groups
	local object_factionsmod = factionsmod.get_factionsmod(object)
	local rep_value = 0
	
	factionsmod.dbg_lvl3("calc_base_reputation: " .. name .. " <--> " .. tostring(object))
	
	if object_factionsmod ~= nil then
		factionsmod.dbg_lvl3("calc_base_reputation: " .. tostring(object) .. " is in " .. #object_factionsmod .. " factionsmod")
		for k,v in pairs(object_factionsmod) do
			if factionsmod.data.factionsmod[v] == nil then
				print("factionsmod: warning object is member of faction " .. v .. " which doesn't exist")
			else
				factionsmod.dbg_lvl3("calc_base_reputation: " .. name .. " <--> " .. v .. " rep=" .. dump(factionsmod.data.factionsmod[v].base_reputation[name]))
				if factionsmod.data.factionsmod[v].base_reputation[name] ~= nil then
				rep_value =
					rep_value + factionsmod.data.factionsmod[v].base_reputation[name]
				end
			end
		end
		
		rep_value = rep_value / #object_factionsmod
	end
	
	return rep_value
end

-------------------------------------------------------------------------------
-- name: save()
--
--! @brief save data to file
--! @memberof factionsmod
--! @private
-------------------------------------------------------------------------------
function factionsmod.save()

	--saving is done much more often than reading data to avoid delay
	--due to figuring out which data to save and which is temporary only
	--all data is saved here
	--this implies data needs to be cleant up on load
	
	local file,error = io.open(factionsmod_worldid .. "/" .. "factionsmod.conf","w")
	
	if file ~= nil then
		file:write(minetest.serialize(factionsmod.data))
		file:close()
	else
		minetest.log("error","MOD factionsmod: unable to save factionsmod world specific data!: " .. error)
	end
	
end

-------------------------------------------------------------------------------
-- name: load()
--
--! @brief load data from file
--! @memberof factionsmod
--! @private
--
--! @return true/false
-------------------------------------------------------------------------------
function factionsmod.load()
	local file,error = io.open(factionsmod_worldid .. "/" .. "factionsmod.conf","r")
	
	if file ~= nil then
		local raw_data = file:read("*a")
		file:close()
		
		if raw_data ~= nil and
			raw_data ~= "" then
			
			local raw_table = minetest.deserialize(raw_data)
			
			
			--read object data
			local temp_objects = {}
			
			if raw_table.objects ~= nil then
				for key,value in pairs(raw_table.objects) do
				
					if value.temporary == false then
						factionsmod.data.objects[key] = value
					else
						temp_objects[key] = true
					end
				end
			end
			
			if raw_table.factionsmod ~= nil then
				for key,value in pairs(raw_table.factionsmod) do
					factionsmod.data.factionsmod[key] = {}
					factionsmod.data.factionsmod[key].base_reputation = value.base_reputation
					factionsmod.data.factionsmod[key].adminlist = value.adminlist
					factionsmod.data.factionsmod[key].open = value.open
					factionsmod.data.factionsmod[key].invitations = value.invitations
					
					factionsmod.data.factionsmod[key].reputation = {}
					for repkey,repvalue in pairs(value.reputation) do
						if temp_objects[repkey] == nil then
							factionsmod.data.factionsmod[key].reputation[repkey] = repvalue
						end
					end
					
					factionsmod.dynamic_data.membertable[key] = {}
				end
			end
			
			--populate dynamic faction member table
			for id,object in pairs(factionsmod.data.objects) do
				for name,value in pairs(factionsmod.data.objects[id].factionsmod) do
					if value then
						factionsmod.dynamic_data.membertable[name][id] = true
					end
				end
			end
		end
	else
		local file,error = io.open(factionsmod_worldid .. "/" .. "factionsmod.conf","w")
		
		if file ~= nil then
			file:close()
		else
			minetest.log("error","MOD factionsmod: unable to save factionsmod world specific data!: " .. error)
		end
	end

	--create special faction players
	--factionsmod.add_faction("players")

	--autojoin players to faction players
	minetest.register_on_joinplayer(
		function(player)
			if player:is_player() then
				--factionsmod.member_add("players",player)
			end
		end
	)
end