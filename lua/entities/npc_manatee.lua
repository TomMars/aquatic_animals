include("aquatic_mammal.lua")
AddCSLuaFile()

ENT.base = "aquatic_mammal"

ENT.model = "models/aquatic_animals/manatee.mdl"
ENT.speed = 70

ENT.predator = {npc_blue_shark = true, npc_reef_shark = true, npc_hammerhead_shark = true, npc_bull_shark = true, 
                npc_great_white_shark = true, npc_great_white_shark_2 = true, npc_killer_whale = true, 
                npc_megalodon = true}