include("aquatic_semi.lua")
AddCSLuaFile()

ENT.base = "aquatic_semi"

ENT.model = "models/aquatic_animals/sea_turtle.mdl"
ENT.skin = {0, 1}
ENT.health = 50
ENT.speed = 50
ENT.groundSpeed = 5
ENT.damage = 10

ENT.prey = {}
ENT.predator = {npc_blue_shark = true, npc_reef_shark = true, npc_hammerhead_shark = true, npc_bull_shark = true, 
                npc_great_white_shark = true, npc_great_white_shark_2 = true, npc_killer_whale = true, npc_crocodile = true,
                npc_megalodon = true, npc_mosasaurus = true}