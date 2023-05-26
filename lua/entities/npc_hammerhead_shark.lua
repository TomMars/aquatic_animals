include("base_shark.lua")
AddCSLuaFile()

ENT.base = "base_shark"

ENT.model = "models/aquatic_animals/hammerhead_shark.mdl"
ENT.health = 150

ENT.ignore = {npc_blue_shark = true, npc_reef_shark = true, npc_hammerhead_shark = true}
