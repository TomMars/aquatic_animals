include("aquatic_neutral.lua")
AddCSLuaFile()

ENT.base = "aquatic_neutral"

ENT.model = "models/aquatic_animals/tuna.mdl"
ENT.health = 15
ENT.speed = 55
ENT.damage = 2
ENT.fearPlayers = true

ENT.radius = 250
ENT.upStep = 25

ENT.ignore = {npc_roach = true, npc_goldfish = true, npc_bass = true, npc_pike = true, 
              npc_tuna = true}

if SERVER then
    for k, _ in pairs(list.Get("NPC")) do
        if !ENT.ignore[k] and !ENT.prey[k] then ENT.predator[k] = true end
    end
end