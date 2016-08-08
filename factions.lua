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


factions.Faction = {
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
}

factions.Faction.__index = factions.Faction

function factions.Faction:new(faction) 
    faction = {
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
    } or faction
    setmetatable(faction, self)
    return faction
end


factions.new_faction = function(name)
    local faction =  factions.Faction:new(nil)
    faction.name = name
    factions.factions[name] = faction
    factions.save()
    return faction
end

function factions.Faction.increase_power(self, power)
    self.power = self.power + power
    factions.save()
end

function factions.Faction.decrease_power(self, power)
    self.power = self.power - power
    factions.save()
end

function factions.Faction.add_player(self, player, rank)
    self.players[player] = rank or self.default_rank
    factions.players[player] = self.name
    self:on_player_join(player)
    self.invited_players[player] = nil
    factions.save()
end

function factions.Faction.remove_player(self, player)
    self.players[player] = nil
    factions.players[player] = nil
    self:on_player_leave(player)
    factions.save()
end

function factions.Faction.claim_chunk(self, chunkpos)
    factions.chunks[chunkpos] = self.name
    self.land[chunkpos] = true
    self:on_claim_chunk(chunkpos)
    factions.save()
end
function factions.Faction.unclaim_chunk(self, chunkpos)
    factions.chunks[chunkpos] = nil
    self.land[chunkpos] = nil
    self:on_unclaim_chunk(chunkpos)
    factions.save()
end
function factions.Faction.disband(self)
    for k, _ in pairs(self.players) do -- remove players affiliation
        factions.players[k] = nil
    end
    for k, v in pairs(self.land) do -- remove chunk claims
        factions.chunks[k] = nil
    end
    self:on_disband()
    factions.factions[self.name] = nil
    factions.save()
end
function factions.Faction.set_leader(self, player)
    self.leader = player
    self.players[player] = self.default_leader_rank
    self:on_new_leader()
    factions.save()
end
function factions.Faction.has_permission(self, player, permission)
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
end
function factions.Faction.set_description(self, new)
    self.description = new
    self:on_change_description()
    factions.save()
end
function factions.Faction.invite_player(self, player)
    self.invited_players[player] = true
    self:on_player_invited(player)
    factions.save()
end
function factions.Faction.revoke_invite(self, player)
    self.invited_players[player] = nil
    self:on_revoke_invite(player)
    factions.save()
end
function factions.Faction.is_invited(self, player)
    return table.contains(self.invited_players, player)
end
function factions.Faction.toggle_join_free(self, bool)
    self.join_free = bool
    self:on_toggle_join_free()
    factions.save()
end
function factions.Faction.can_join(self, player)
    return self.join_free or self.invited_players[player]
end
function factions.Faction.new_alliance(self, faction)
    self.allies[faction] = true
    self:on_new_alliance(faction)
    if self.enemies[faction] then
        self:end_enemy(faction)
    end
    factions.save()
end
function factions.Faction.end_alliance(self, faction)
    self.allies[faction] = nil
    self:on_end_alliance(faction)
    factions.save()
end
function factions.Faction.new_enemy(self, faction)
    self.enemies[faction] = true
    self:on_new_enemy(faction)
    if self.allies[faction] then
        self:end_alliance(faction)
    end
    factions.save()
end
function factions.Faction.end_enemy(self, faction)
    self.enemies[faction] = nil
    self:on_end_enemy(faction)
    factions.save()
end
function factions.Faction.set_spawn(self, pos)
    self.spawn = pos
    self:on_set_spawn()
    factions.save()
end
function factions.Faction.add_rank(self, rank, perms)
    self.ranks[rank] = perms
    self:on_new_rank(rank)
    factions.save()
end
function factions.Faction.delete_rank(self, rank, newrank)
    for player, r in pairs(self.players) do
        if r == rank then
            self.players[player] = newrank
        end
    end
    self.ranks[rank] = nil
    self:on_delete_rank(rank, newrank)
    factions.save()
end

--------------------------
-- callbacks for events --
function factions.Faction.on_create(self)  --! @brief called when the faction is added to the global faction list
    --TODO: implement
end
function factions.Faction.on_player_leave(self, player)
    --TODO: implement
end
function factions.Faction.on_player_join(self, player)
    --TODO: implement
end
function factions.Faction.on_claim_chunk(self, pos)
    --TODO: implement
end
function factions.Faction.on_unclaim_chunk(self, pos)
    --TODO: implement
end
function factions.Faction.on_disband(self, pos)
    --TODO: implement
end
function factions.Faction.on_new_leader(self)
    --TODO: implement
end
function factions.Faction.on_change_description(self)
    --TODO: implement
end
function factions.Faction.on_player_invited(self, player)
    --TODO: implement
end
function factions.Faction.on_toggle_join_free(self, player)
    --TODO: implement
end
function factions.Faction.on_new_alliance(self, faction)
    --TODO: implement
end
function factions.Faction.on_end_alliance(self, faction)
    --TODO: implement
end
function factions.Faction.on_set_spawn(self)
    --TODO: implement
end
function factions.Faction.on_add_rank(self, rank)
    --TODO: implement
end
function factions.Faction.on_delete_rank(self, rank, newrank)
    --TODO: implement
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
            setmetatable(faction, factions.Faction)
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

