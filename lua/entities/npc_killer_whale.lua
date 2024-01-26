include("aquatic_neutral.lua")
AddCSLuaFile()

ENT.base = "aquatic_neutral"

ENT.model = "models/aquatic_animals/killer_whale.mdl"
ENT.health = 1000
ENT.speed = 110
ENT.damage = 175
ENT.defensive = true
ENT.hasSound = true

ENT.radius = 1500
ENT.upStep = 70

ENT.ignore = {npc_killer_whale = true, npc_blue_whale = true, npc_roach = true, npc_goldfish = true}
ENT.predator = {npc_sperm_whale = true, npc_megalodon = true, npc_mosasaurus = true}
ENT.wreckable_vehicles = {"small"}

if SERVER then
    for k, v in pairs(list.Get("NPC")) do
        if !ENT.ignore[k] and (table.HasValue(v, "Animals") or table.HasValue(v, "Aquatic Animals") or table.HasValue(v, "Aquatic Animals (Extinct)")) then ENT.prey[k] = true end
    end
end
