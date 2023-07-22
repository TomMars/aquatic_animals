include("aquatic_apex_mammal.lua")
AddCSLuaFile()

ENT.base = "aquatic_apex_mammal"

ENT.model = "models/aquatic_animals/sperm_whale.mdl"
ENT.health = 3000
ENT.speed = 120
ENT.damage = 500

ENT.radius = 3000
ENT.upStep = 60

ENT.ignore = {npc_sperm_whale = true}
ENT.wreckable_vehicles = {"small", "big"}
