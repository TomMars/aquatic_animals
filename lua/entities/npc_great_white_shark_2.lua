include("aquatic_hostile.lua")
AddCSLuaFile()

ENT.base = "aquatic_hostile"

ENT.model = "models/aquatic_animals/great_white_shark_2.mdl"
ENT.health = 1000
ENT.speed = 110
ENT.damage = 200

ENT.radius = 1500
ENT.upStep = 75

ENT.ignore = {npc_blue_whale = true}
ENT.predator = {npc_sperm_whale = true, npc_megalodon = true, npc_mosasaurus = true}
ENT.wreckable_vehicles = {"small"}
