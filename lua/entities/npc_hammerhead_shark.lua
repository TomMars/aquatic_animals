include("aquatic_shark.lua")
AddCSLuaFile()

ENT.base = "aquatic_shark"

ENT.model = "models/aquatic_animals/hammerhead_shark.mdl"
ENT.health = 150

ENT.ignore = {npc_blue_shark = true, npc_reef_shark = true, npc_hammerhead_shark = true, npc_bull_shark = true}
ENT.predator = {npc_great_white_shark = true, npc_killer_whale = true, npc_sperm_whale = true, npc_megalodon = true}
