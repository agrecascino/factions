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
factionsmod.factions = {}
factionsmod.chunks = {}
factionsmod.players = {}

factionsmod.print = function(text)
	print("factionsmod: " .. dump(text))
end

factionsmod.dbg_lvl1 = function() end --factionsmod.print  -- errors
factionsmod.dbg_lvl2 = function() end --factionsmod.print  -- non cyclic trace
factionsmod.dbg_lvl3 = function() end --factionsmod.print  -- cyclic trace

factionsmod.factions = {}
--- settings
factionsmod.lower_claimable_height = -512

---------------------
--! @brief returns whether a faction can be created or not (allows for implementation of blacklists and the like)
factionsmod.can_create_faction = function(name)
    if factionsmod.factions[name] then
        return false
    else
        return true
    end,
end

---------------------
--! @brief create a faction object
factionsmod.new_faction = function(name)
    local faction = {
        name = name,
        power = 0.,
        players = {},
        ranks = {["leader"] = {"disband", "claim", "playerlist", "build", "edit"},
                 ["member"] = {"build"}
                },
        leader = nil,
        default_rank = "member",
        default_leader_rank = "leader",
        description = "Default faction description.",
        invited_players = {},
        land = {},
        allies = {},
        enemies = {},
        join_free = false

        ----------------------
        --  methods
        increase_power = function(self, power)
            self.power = self.power + power
        end,
        decrease_power = function(self, power)
            self.power = self.power - power
        end,
        add_player = function(self, player, rank)
            self.players[player] = rank or self.default_rank
            self:on_player_join(player)
            self.invited_players[player] = nil
        end,
        remove_player = function(self, player)
            self.players[player] = nil
            self:on_player_leave(player)
        end,
        claim_chunk = function(self, chunkpos)
            factionsmod.chunks[chunkpos] = self.name
            self.land[chunkpos] = true
            self:on_claim_chunk(chunkpos)
        end,
        unclaim_chunk = function(self, chunkpos)
            factionsmod.chunks[chunkpos] = nil
            self.land[chunkpos] = nil
            self:on_unclaim_chunks(chunkpos)
        end,
        disband = function(self)
            factionsmod.factions[self.name] = nil
            for i in ipairs(self.players) do -- remove players affiliation
                factionsmod.players[self.players[i]] = nil
            end
            for k, v in self.land do -- remove chunk claims
                factionsmod.chunks[v] = nil
            end
            self:on_disband()
        end,
        set_leader = function(self, player)
            self.leader = player
            self.players[player] = self.default_leader_rank
            self:on_new_leader()
        end,
        has_permission = function(self, player, permission)
            local p = self.players[player]
            if not p then
                return false
            end
            return table.contains(self.groups[p], permission)
        end,
        set_description = function(self, new)
            self.description = new
            self:on_change_description()
        end,
        invite_player = function(self, player)
            self.invited_players[player] = true
            self:on_player_invited(player)
        end,
        revoke_invite = function(self, player)
            self.invited_player[player = nil
            self:on_revoke_invite(player)
        end,
        is_invited = function(self, player)
            return table.contains(self.invited_players, player)
        end,
        toggle_join_free = function(self, bool)
            self.join_free = bool
            self:on_toggle_join_free()
        end,
        can_join = function(self, player)
            return self.join_free or invited_players[player]
        end,
        new_alliance = function(self, faction)
            self.allies[faction] = true
            self:on_new_alliance(faction)
            if self.enemies[faction] then
                self:end_enemy(faction)
            end
        end,
        end_alliance = function(self, faction)
            self.allies[faction] = nil
            self:on_end_alliance(faction)
        end,
        new_enemy = function(self, faction)
            self.enemies[faction] = true
            self:on_new_enemy[faction]
            if self.allies[faction] then
                self:end_alliance(faction)
            end
        end,
        end_enemy = function(self, faction)
            self.enemies[faction] = nil
            self:on_end_enemy[faction]
        end,

        -----------------------
        -- callbacks for events
        on_create = function(self)  --! @brief called when the faction is added to the global faction list
            --TODO: implement
        end,
        on_player_leave = function(self, player)
            --TODO: implement
        end,
        on_player_join = function(self, player)
            --TODO: implement
        end,
        on_claim_chunk = function(self, pos)
            --TODO: implement
        end,
        on_unclaim_chunk = function(self, pos)
            --TODO: implement
        end,
        on_disband = function(self, pos)
            --TODO: implement
        end,
        on_new_leader = function(self)
            --TODO: implement
        end,
        on_change_description = function(self)
            --TODO: implement
        end,
        on_player_invited = function(self, player)
            --TODO: implement
        end,
        on_toggle_join_free = function(self, player)
            --TODO: implement
        end,
        on_new_alliance = function(self, faction)
            --TODO: implement
        end,
        on_end_alliance = function(self, faction)
            --TODO: implement
        end,
    }
    factionsmod[name] = faction
    return faction
end

--??????????????
function factionsmod.fix_powercap(name)
	factionsmod.data.factionsmod[name].powercap = #factionsmod.dynamic_data.membertable[name] + 10
end
--??????????????

function factionsmod.get_chunk(pos)
    return factionsmod.chunks[factionsmod.get_chunkpos(pos)]
end

function factionsmod.get_chunkpos(pos)
    return {math.floor(pos.x / 16.), math.floor(pos.z / 16.)}


-------------------------------------------------------------------------------
-- name: add_faction(name)
--
--! @brief add a faction
--! @memberof factionsmod
--! @public
--
--! @param name of faction to add
--!
--! @return faction object/false (succesfully added faction or not)
-------------------------------------------------------------------------------
function factionsmod.add_faction(name)
        if factionsmod.can_create_faction(name) then
            local fac = factionsmod.new_faction(name)
            fac:on_create()
            return fac
        else
            return nil
        end,
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
	
	for key,value in pairs(factionsmod.factions) do
		table.insert(retval,key)
	end
	
	return retval
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
		file:write(minetest.serialize(factionsmod.factions))
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
		factionsmod.factions = minetest.deserialize(raw_data)
        for facname, faction in pairs(factionsmod.factions) do
            for i in ipairs(faction.players) do
                factionsmod.players[faction.players[i]] = facname
            end
            for chunkpos, val in pairs(faction.land) do
                factionsmod.chunks[chunkpos] = val
            end
        end
		file:close()
    end
end
			
--autojoin players to faction players
minetest.register_on_dieplayer(
    function(player)
    end
)

minetest.register_globalstep(
    function(dtime)
    end
)
minetest.register_on_joinplayer(
    function(player)
    end
)

