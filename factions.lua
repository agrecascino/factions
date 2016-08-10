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


factions.factions = {}
--- settings
factions.lower_laimable_height = -512
factions.power_per_chunk = .5

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
}

util = {
    coords3D_string = function(coords)
        return coords.x..", "..coords.y..", "..coords.z
    end
}

factions.Faction.__index = factions.Faction

function factions.Faction:new(faction) 
    faction = {
        power = 0.,
        players = {},
        ranks = {["leader"] = {"disband", "claim", "playerslist", "build", "description", "ranks", "spawn", "banner", "promote"},
                 ["moderator"] = {"claim", "playerslist", "build", "spawn"},
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
        attacked_chunks = {},
        join_free = false,
        banner = "bg_white.png",
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

function factions.Faction.can_claim_chunk(self, chunkpos)
    local fac = factions.chunks[chunkpos]
    if fac then
        if factions.factions[fac].power < 0. and self.power >= factions.power_per_chunk then
            return true
        else
            return false
        end
    elseif self.power < factions.power_per_chunk then
        return false
    end
    return true
end

function factions.Faction.claim_chunk(self, chunkpos)
    -- check if claiming over other faction's territory
    local otherfac = factions.chunks[chunkpos]
    if otherfac then
        local faction = factions.factions[otherfac]
        faction:unclaim_chunk(chunkpos)
    end
    factions.chunks[chunkpos] = self.name
    self.land[chunkpos] = true
    self:decrease_power(factions.power_per_chunk)
    self:on_claim_chunk(chunkpos)
    factions.save()
end
function factions.Faction.unclaim_chunk(self, chunkpos)
    factions.chunks[chunkpos] = nil
    self.land[chunkpos] = nil
    self:increase_power(factions.power_per_chunk)
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
    self.spawn = {x=pos.x, y=pos.y, z=pos.z}
    self:on_set_spawn(pos)
    factions.save()
end
function factions.Faction.add_rank(self, rank, perms)
    self.ranks[rank] = perms
    self:on_add_rank(rank)
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
function factions.Faction.set_banner(self, newbanner)
    self.banner = newbanner
    self:on_new_banner()
end
function factions.Faction.promote(self, member, rank)
    self.players[member] = rank
    self:on_promote(member)
end
function factions.Faction.broadcast(self, msg, sender)
    local message = self.name.."> "..msg
    if sender then
        message = sender.."@"..message
    end
    message = "Faction<"..message
    for k, _ in pairs(self.players) do
        minetest.chat_send_player(k, message)
    end
end

--------------------------
-- callbacks for events --
function factions.Faction.on_create(self)  --! @brief called when the faction is added to the global faction list
    minetest.chat_send_all("Faction "..self.name" has been created.")
end
function factions.Faction.on_player_leave(self, player)
    self:broadcast(player.." has left this faction.")
end
function factions.Faction.on_player_join(self, player)
    self:broadcast(player.." has joined this faction.")
end
function factions.Faction.on_claim_chunk(self, pos)
    self:broadcast("Chunk ("..pos..") has been claimed.")
end
function factions.Faction.on_unclaim_chunk(self, pos)
    self:broadcast("Chunk ("..pos..") has been unclaimed.")
end
function factions.Faction.on_disband(self, pos)
    minetest.chat_send_all("Faction "..self.name.."has been disbanded.")
end
function factions.Faction.on_new_leader(self)
    self:broadcast(self.leader.." is now the leader of this faction.")
end
function factions.Faction.on_change_description(self)
    self:broadcast("Faction description has been modified to: "..self.description)
end
function factions.Faction.on_player_invited(self, player)
    minetest.chat_send_player(player, "You have been invited to faction "..self.name)
end
function factions.Faction.on_toggle_join_free(self, player)
    self:broadcast("This faction is now invite-free.")
end
function factions.Faction.on_new_alliance(self, faction)
    self:broadcast("This faction is now allied with "..faction)
end
function factions.Faction.on_end_alliance(self, faction)
    self:broadcast("This faction is no longer allied with "..faction.."!")
end
function factions.Faction.on_set_spawn(self)
    self:broadcast("The faction spawn has been set to ("..util.coords3D_string(pos)..").")
end
function factions.Faction.on_add_rank(self, rank)
    self:broadcast("The rank "..rank.." has been created with privileges: "..table.concat(self.ranks[rank]))
end
function factions.Faction.on_delete_rank(self, rank, newrank)
    self:broadcast("The rank "..rank.." has been deleted and replaced by "..newrank)
end
function factions.Faction.on_new_banner(self)
    self:broadcast("A new banner has been set.")
end
function factions.Faction.on_promote(self, member)
    minetest.chat_send_player(player, "You have been promoted to "..self.players[member])
end
function factions.Faction.on_revoke_invite(self, player)
    minetest.chat_send_player(player, "You are no longer invited to faction "..self.name)
end

--??????????????

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

function factions.convert(filename)
    local file, error = io.open(factions_worldid .. "/" .. filename, "r")
    if not file then
        minetest.chat_send_all("Cannot load file "..filename..". "..error)
        return false
    end
    local raw_data = file:read("*a")
    local data = minetest.deserialize(raw_data)
    local factionsmod = data.factionsmod
    local objects = data.objects
    for faction, attrs in pairs(factionsmod) do
        local newfac = factions.new_faction(faction)
        newfac:add_player(attrs.owner, "leader")
        for player, _ in pairs(attrs.adminlist) do
            if not newfac.players[player] then
                newfac:add_player(player, "moderator")
            end
        end
        for player, _ in pairs(attrs.invitations) do
            newfac:invite_player(player)
        end
        for i in ipairs(attrs.chunk) do
            local chunkpos = table.concat(attrs.chunk[i],",")
            newfac:claim_chunk(chunkpos)
        end
    end
    for player, attrs in pairs(objects) do
        local facname = attrs.factionsmod
        local faction = factions.factions[facname]
        if faction then
            faction:add_player(player)
        end
    end
    return true
end
			
minetest.register_on_dieplayer(
    function(player)
    end
)

local lastUpdate = 0.

minetest.register_globalstep(
    function(dtime)
        lastUpdate = lastUpdate + dtime
        if lastUpdate > .5 then
            local playerslist = minetest.get_connected_players()
            for i in pairs(playerslist) do
                local player = playerslist[i]
                local chunkpos = factions.get_chunk_pos(player:getpos())
                local faction = factions.chunks[chunkpos]
                player:hud_remove("factionLand")
                player:hud_add({
                    hud_elem_type = "text",
                    name = "factionLand",
                    number = 0xFFFFFF,
                    position = {x=0.1, y = .98},
                    text = faction or "Wilderness",
                    scale = {x=1, y=1},
                    alignment = {x=0, y=0},
                })
            end
        end
    end
)
minetest.register_on_joinplayer(
    function(player)
    end
)
minetest.register_on_respawnplayer(
    function(player)
        local playername = player:get_player_name()
        local faction = factions.players[playername]
        if not faction then
            return false
        else
            faction = factions.factions[faction]
            if not faction.spawn then
                return false
            else
                player:setpos(faction.spawn)
                return true
            end
        end
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

