include("aquatic_hostile.lua")
AddCSLuaFile()

ENT.base = "aquatic_hostile"

ENT.model = "models/aquatic_animals/bull_shark.mdl"
ENT.damage = 35

ENT.upStep = 60

ENT.ignore = {npc_blue_shark = true, npc_reef_shark = true, npc_hammerhead_shark = true, npc_bull_shark = true,
              npc_blue_whale = true}
ENT.predator = {npc_great_white_shark = true, npc_great_white_shark_2 = true, npc_killer_whale = true, npc_sperm_whale = true, 
                npc_megalodon = true}
