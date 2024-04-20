include("aquatic_neutral.lua")
AddCSLuaFile()

ENT.base = "aquatic_neutral"

ENT.model = "models/aquatic_animals/sperm_whale.mdl"
ENT.health = 4000
ENT.speed = 120
ENT.damage = 750
ENT.defensive = true
ENT.hasSound = true

ENT.radius = 2250
ENT.upStep = 60
ENT.soundLevel = 100

ENT.ignore = {npc_sperm_whale = true, npc_sea_turtle = true, npc_dolphin = true, npc_manatee = true, 
              npc_blue_whale = true, npc_piranha = true, npc_roach = true, npc_goldfish = true,
              npc_bass = true, npc_pike = true}
ENT.wreckable_vehicles = {"small", "big"}

if SERVER then
    for k, v in pairs(list.Get("NPC")) do
        if !ENT.ignore[k] and (table.HasValue(v, "Aquatic Animals") or table.HasValue(v, "Aquatic Animals (Extinct)")) then ENT.prey[k] = true end
    end
end
