include("aquatic_semi.lua")
AddCSLuaFile()

ENT.base = "aquatic_semi"

ENT.model = "models/aquatic_animals/sea_turtle.mdl"
ENT.skin = {0, 1}
ENT.health = 75
ENT.speed = 75
ENT.groundSpeed = 5
ENT.damage = 10

ENT.prey = {}

local predatorTypes = {
    ["shark"] = true,
    ["big_shark"] = true,
    ["huge_shark"] = true,
    ["killer_whale"] = true,
    ["crocodile"] = true,
    ["huge_reptile"] = true,
    ["monster"] = true
}

if SERVER then
    for k, v in pairs(list.Get("NPC")) do
        if table.HasValue(v, "Aquatic Animals") or table.HasValue(v, "Aquatic Animals (Extinct)") then
            if predatorTypes[v.Type] then
                ENT.predator[k] = true
            end
        end
    end
end