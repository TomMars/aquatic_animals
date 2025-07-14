include("aquatic_neutral.lua")
AddCSLuaFile()

ENT.base = "aquatic_neutral"

ENT.model = "models/aquatic_animals/killer_whale.mdl"
ENT.health = 1000
ENT.speed = 110
ENT.damage = 175
ENT.defensive = true
ENT.hasSound = true

ENT.radius = 1500
ENT.upStep = 70

ENT.wreckable_vehicles = {"small"}

local ignoreTypes = {
    ["small_fish"] = true,
    ["fish"] = true,
    ["killer_whale"] = true,
    ["huge_whale"] = true,
    ["piranha"] = true
}

local predatorTypes = {
    ["huge_shark"] = true,
    ["sperm_whale"] = true,
    ["huge_reptile"] = true,
    ["monster"] = true
}

if SERVER then
    for k, v in pairs(list.Get("NPC")) do
        if table.HasValue(v, "Aquatic Animals") or table.HasValue(v, "Aquatic Animals (Extinct)") then
            if ignoreTypes[v.Type] then
                ENT.ignore[k] = true
            elseif predatorTypes[v.Type] then
                ENT.predator[k] = true
            else
                ENT.prey[k] = true
            end
        end
    end
end
