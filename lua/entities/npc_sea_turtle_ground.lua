include("aquatic_ground.lua")
AddCSLuaFile()

ENT.base = "aquatic_ground"

ENT.model = "models/aquatic_animals/sea_turtle_ground.mdl"
ENT.speed = 5
ENT.damage = 10
ENT.aggressive = false

ENT.predator = {npc_blue_shark = true, npc_reef_shark = true, npc_hammerhead_shark = true, npc_bull_shark = true, 
                npc_great_white_shark = true, npc_killer_whale = true, npc_sperm_whale = true, npc_megalodon = true}