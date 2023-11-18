include("aquatic_shark.lua")
AddCSLuaFile()

ENT.base = "aquatic_shark"

ENT.model = "models/aquatic_animals/great_white_shark_2.mdl"
ENT.health = 1000
ENT.speed = 110
ENT.damage = 200

ENT.upStep = 75

ENT.predator = {npc_sperm_whale = true, npc_megalodon = true}
ENT.wreckable_vehicles = {"small"}
