include("base_shark.lua")
AddCSLuaFile()

ENT.base = "base_shark"

ENT.model = "models/aquatic_animals/megalodon.mdl"
ENT.health = 3000
ENT.speed = 120
ENT.damage = 1000

ENT.radius = 2000
ENT.upStep = 60

ENT.wreckable_vehicles = {"small", "big"}
