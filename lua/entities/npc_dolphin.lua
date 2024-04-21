include("aquatic_neutral.lua")
AddCSLuaFile()

ENT.base = "aquatic_neutral"

ENT.model = "models/aquatic_animals/dolphin.mdl"
ENT.defensive = true
ENT.hasSound = true

ENT.prey = {npc_blue_shark = true, npc_reef_shark = true, npc_hammerhead_shark = true, npc_bull_shark = true,
            npc_crocodile = true, npc_piranha = true, npc_bass = true, npc_pike = true,
            npc_tuna = true}
ENT.predator = {npc_great_white_shark = true, npc_great_white_shark_2 = true, npc_killer_whale = true, npc_megalodon = true,
                npc_mosasaurus = true}
