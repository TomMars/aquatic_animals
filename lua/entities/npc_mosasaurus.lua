include("aquatic_hostile.lua")
AddCSLuaFile()

ENT.base = "aquatic_hostile"

ENT.model = "models/aquatic_animals/mosasaurus.mdl"
ENT.health = 5000
ENT.speed = 120
ENT.damage = 1000

ENT.radius = 2250
ENT.upStep = 60

ENT.wreckable_vehicles = {"small", "big"}