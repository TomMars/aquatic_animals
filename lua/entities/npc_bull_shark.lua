include("base_shark.lua")
AddCSLuaFile()

ENT.base = "base_shark"

ENT.model = "models/aquatic_animals/bull_shark.mdl"

ENT.upStep = 50

ENT.ignore = {npc_blue_shark = true, npc_reef_shark = true, npc_hammerhead_shark = true, npc_bull_shark = true}
ENT.predator = {npc_great_white_shark = true, npc_megalodon = true}