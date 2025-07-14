include("aquatic_hostile.lua")
AddCSLuaFile()

ENT.base = "aquatic_hostile"

ENT.model = "models/aquatic_animals/great_white_shark_2.mdl"
ENT.health = 1000
ENT.speed = 110
ENT.damage = 200

ENT.radius = 1500
ENT.upStep = 75

ENT.wreckable_vehicles = {"small"}

local ignoreTypes = {
    ["small_fish"] = true,
    ["fish"] = true,
    ["piranha"] = true,
    ["huge_whale"] = true
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
            end
        end
    end
end