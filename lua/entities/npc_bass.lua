include("aquatic_neutral.lua")
AddCSLuaFile()

ENT.base = "aquatic_neutral"

ENT.model = "models/aquatic_animals/bass.mdl"
ENT.health = 15
ENT.speed = 50
ENT.damage = 2
ENT.fearPlayers = true

ENT.radius = 250
ENT.upStep = 25

local ignoreTypes = {
    ["small_fish"] = true,
    ["fish"] = true
}

if SERVER then
    for k, v in pairs(list.Get("NPC")) do
        if table.HasValue(v, "Aquatic Animals") or table.HasValue(v, "Aquatic Animals (Extinct)") then
            if !ignoreTypes[v.Type] then
                ENT.predator[k] = true
            else
                ENT.ignore[k] = true
            end
        end
    end
end