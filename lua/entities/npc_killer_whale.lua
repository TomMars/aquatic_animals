include("aquatic_apex_mammal.lua")
AddCSLuaFile()

ENT.base = "aquatic_apex_mammal"

ENT.model = "models/aquatic_animals/killer_whale.mdl"
ENT.health = 1000
ENT.speed = 110
ENT.damage = 175

ENT.upStep = 70

ENT.ignore = {npc_killer_whale = true}
ENT.predator = {npc_megalodon = true}
ENT.wreckable_vehicles = {"small"}
