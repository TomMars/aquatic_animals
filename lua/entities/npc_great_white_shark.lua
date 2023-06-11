include("base_shark.lua")
AddCSLuaFile()

ENT.base = "base_shark"

ENT.model = "models/aquatic_animals/great_white_shark.mdl"
ENT.health = 1000
ENT.speed = 110
ENT.damage = 200

ENT.upStep = 60

ENT.vehicles = {Airboat = true, vehicle_kaw_jetski = true}
