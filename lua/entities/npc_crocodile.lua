include("aquatic_semi.lua")
AddCSLuaFile()

ENT.base = "aquatic_semi"

ENT.model = "models/aquatic_animals/crocodile.mdl"
ENT.skin = {0, 1, 2}
ENT.health = 125
ENT.groundSpeed = 20
ENT.damage = 25
ENT.aggressive = true
ENT.hasSound = true

ENT.stepHeight = 25

ENT.ignore = {npc_crocodile = true, npc_manatee = true, npc_blue_whale = true}
ENT.predator = {npc_great_white_shark = true, npc_great_white_shark_2 = true, npc_killer_whale = true, 
                npc_sperm_whale = true, npc_megalodon = true}