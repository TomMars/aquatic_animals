include("aquatic_hostile.lua")
AddCSLuaFile()

ENT.base = "aquatic_hostile"

ENT.model = "models/aquatic_animals/piranha.mdl"
ENT.health = 5
ENT.speed = 50
ENT.damage = 1

ENT.radius = 500
ENT.upStep = 25

ENT.ignore = {npc_piranha = true, npc_blue_whale = true}
ENT.predator = {npc_great_white_shark = true, npc_great_white_shark_2 = true, npc_killer_whale = true, npc_sperm_whale = true, 
                npc_megalodon = true, npc_mosasaurus = true}
