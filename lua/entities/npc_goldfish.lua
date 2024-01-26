include("aquatic_neutral.lua")
AddCSLuaFile()

ENT.base = "aquatic_neutral"

ENT.model = "models/aquatic_animals/goldfish.mdl"
ENT.health = 2
ENT.speed = 45
ENT.damage = 1
ENT.fearPlayers = true

ENT.radius = 250
ENT.upStep = 25

ENT.ignore = {npc_roach = true, npc_goldfish = true}

if SERVER then
    for k, _ in pairs(list.Get("NPC")) do
        if !ENT.ignore[k] then ENT.predator[k] = true end
    end
end