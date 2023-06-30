include("base_shark.lua")
AddCSLuaFile()

ENT.base = "base_shark"

ENT.model = "models/aquatic_animals/killer_whale.mdl"
ENT.health = 1000
ENT.speed = 110
ENT.damage = 175

ENT.upStep = 70

ENT.ignore = {npc_killer_whale = true}
ENT.predator = {npc_megalodon = true}
ENT.vehicles = {Airboat = true, vehicle_kaw_jetski = true}
