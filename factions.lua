-------------------------------------------------------------------------------
-- factions Mod by Sapier
--
-- License WTFPL
--
--! @file factions.lua
--! @brief factions core file containing datastorage
--! @copyright Sapier
--! @author Sapier
--! @date 2013-05-08
--
-- Contact sapier a t gmx net
-------------------------------------------------------------------------------

--read some basic information
local factions_worldid = minetest.get_worldpath()

--! @class factions
--! @brief main class for factions
factions = {}

--! @brief runtime data
factions.factions = {}
factions.chunks = {}
factions.players = {}

factions.print = function(text)
	print("factions: " .. dump(text))
end

factions.dbg_lvl1 = function() end --factions.print  -- errors
factions.dbg_lvl2 = function() end --factions.print  -- non cyclic trace
factions.dbg_lvl3 = function() end --factions.print  -- cyclic trace

factions.factions = {}
--- settings
factions.lower_laimable_height = -512

---------------------
--! @brief returns whether a faction can be created or not (allows for implementation of blacklists and the like)
factions.can_create_faction = function(name)
    if factions.factions[name] then
        return false
    else
        return true
    end
end

---------------------
--! @brief create a faction object
factions.new_faction = function(name)
    local faction = {
        name = name,
        power = 0.,
        players = {},
        ranks = {["leader"] = {"disband", "claim", "playerlist", "build", "edit", "ranks"},
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
        join_free = false,
        spawn = nil,

        ----------------------
        --  methods
        increase_power = function(self, power)
            self.power = self.power + power
            factions.save()
        end,
        decrease_power = function(self, power)
            self.power = self.power - power
            factions.save()
        end,
        add_player = function(self, player, rank)
            self.players[player] = rank or self.default_rank
            factions.players[player] = self.name
            self:on_player_join(player)
            self.invited_players[player] = nil
            factions.save()
        end,
        remove_player = function(self, player)
            self.players[player] = nil
            factions.players[player] = nil
            self:on_player_leave(player)
            factions.save()
        end,
        claim_chunk = function(self, chunkpos)
            factions.chunks[chunkpos] = self.name
            self.land[chunkpos] = true
            self:on_claim_chunk(chunkpos)
            factions.save()
        end,
        unclaim_chunk = function(self, chunkpos)
            factions.chunks[chunkpos] = nil
            self.land[chunkpos] = nil
            self:on_unclaim_chunks(chunkpos)
            factions.save()
        end,
        disband = function(self)
            for i in ipairs(self.players) do -- remove players affiliation
                factions.players[self.players[i]] = nil
            end
            for k, v in pairs(self.land) do -- remove chunk claims
                factions.chunks[v] = nil
            end
            self:on_disband()
            factions.factions[self.name] = nil
            factions.save()
        end,
        set_leader = function(self, player)
            self.leader = player
            self.players[player] = self.default_leader_rank
            self:on_new_leader()
            factions.save()
        end,
        has_permission = function(self, player, permission)
            local p = self.players[player]
            if not p then
                return false
            end
            local perms = self.ranks[p]
            for i in ipairs(perms) do
                if perms[i] == permission then
                    return true
                end
            end
            return false
        end,
        set_description = function(self, new)
            self.description = new
            self:on_change_description()
            factions.save()
        end,
        invite_player = function(self, player)
            self.invited_players[player] = true
            self:on_player_invited(player)
            factions.save()
        end,
        revoke_invite = function(self, player)
            self.invited_players[player] = nil
            self:on_revoke_invite(player)
            factions.save()
        end,
        is_invited = function(self, player)
            return table.contains(self.invited_players, player)
        end,
        toggle_join_free = function(self, bool)
            self.join_free = bool
            self:on_toggle_join_free()
            factions.save()
        end,
        can_join = function(self, player)
            return self.join_free or self.invited_players[player]
        end,
        new_alliance = function(self, faction)
            self.allies[faction] = true
            self:on_new_alliance(faction)
            if self.enemies[faction] then
                self:end_enemy(faction)
            end
            factions.save()
        end,
        end_alliance = function(self, faction)
            self.allies[faction] = nil
            self:on_end_alliance(faction)
            factions.save()
        end,
        new_enemy = function(self, faction)
            self.enemies[faction] = true
            self:on_new_enemy(faction)
            if self.allies[faction] then
                self:end_alliance(faction)
            end
            factions.save()
        end,
        end_enemy = function(self, faction)
            self.enemies[faction] = nil
            self:on_end_enemy(faction)
            factions.save()
        end,
        set_spawn = function(self, pos)
            self.spawn = pos
            self:on_set_spawn()
            factions.save()
        end,
        add_rank = function(self, rank, perms)
            self.ranks[rank] = perms
            self:on_new_rank(rank)
            factions.save()
        end,
        delete_rank = function(self, rank, newrank)
            for player, r in pairs(self.players) do
                if r == rank then
                    self.players[player] = newrank
                end
            end
            self.ranks[rank] = nil
            self:on_delete_rank(rank, newrank)
            factions.save()
        end,

        --------------------------
        -- callbacks for events --
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
        on_set_spawn = function(self)
            --TODO: implement
        end,
        on_add_rank = function(self, rank)
            --TODO: implement
        end,
        on_delete_rank = function(self, rank, newrank)
            --TODO: implement
        end,
    }
    factions.factions[name] = faction
    factions.save()
    return faction
end

--??????????????
function factions.fix_powercap(name)
	factions.data.factions[name].powercap = #factions.dynamic_data.membertable[name] + 10
end
--??????????????

function factions.get_chunk(pos)
    return factions.chunks[factions.get_chunkpos(pos)]
end

function factions.get_chunk_pos(pos)
    return math.floor(pos.x / 16.)..","..math.floor(pos.z / 16.)
end


-------------------------------------------------------------------------------
-- name: add_faction(name)
--
--! @brief add a faction
--! @memberof factions
--! @public
--
--! @param name of faction to add
--!
--! @return faction object/false (succesfully added faction or not)
-------------------------------------------------------------------------------
function factions.add_faction(name)
    if factions.can_create_faction(name) then
        local fac = factions.new_faction(name)
        fac:on_create()
        return fac
    else
        return nil
    end
end

-------------------------------------------------------------------------------
-- name: get_faction_list()
--
--! @brief get list of factions
--! @memberof factions
--! @public
--!
--! @return list of factions
-------------------------------------------------------------------------------
function factions.get_faction_list()

	local retval = {}
	
	for key,value in pairs(factions.factions) do
		table.insert(retval,key)
	end
	
	return retval
end

-------------------------------------------------------------------------------
-- name: save()
--
--! @brief save data to file
--! @memberof factions
--! @private
-------------------------------------------------------------------------------
function factions.save()

	--saving is done much more often than reading data to avoid delay
	--due to figuring out which data to save and which is temporary only
	--all data is saved here
	--this implies data needs to be cleant up on load
	
	local file,error = io.open(factions_worldid .. "/" .. "factions.conf","w")
	
	if file ~= nil then
		file:write(minetest.serialize(factions.factions))
		file:close()
	else
		minetest.log("error","MOD factions: unable to save factions world specific data!: " .. error)
	end
	
end

-------------------------------------------------------------------------------
-- name: load()
--
--! @brief load data from file
--! @memberof factions
--! @private
--
--! @return true/false
-------------------------------------------------------------------------------
function factions.load()
	local file,error = io.open(factions_worldid .. "/" .. "factions.conf","r")
	
	if file ~= nil then
		local raw_data = file:read("*a")
		factions.factions = minetest.deserialize(raw_data)
        for facname, faction in pairs(factions.factions) do
            minetest.log("action", facname..","..faction.name)
            for player, rank in pairs(faction.players) do
                minetest.log("action", player..","..rank)
                factions.players[player] = facname
            end
            for chunkpos, val in pairs(faction.land) do
                factions.chunks[chunkpos] = facname
            end
        end
		file:close()
    end
end
			
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


local default_is_protected = minetest.is_protected
minetest.is_protected = function(pos, player)
    local chunkpos = factions.get_chunk_pos(pos)
    local faction = factions.chunks[chunkpos]
    if not faction then
        return default_is_protected(pos, player)
    else
        faction = factions.factions[faction]
        return not faction:has_permission(player, "build")
    end
end

