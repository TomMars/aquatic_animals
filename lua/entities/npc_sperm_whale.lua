include("aquatic_neutral.lua")
AddCSLuaFile()

ENT.base = "aquatic_neutral"

ENT.model = "models/aquatic_animals/sperm_whale.mdl"
ENT.health = 4000
ENT.speed = 120
ENT.damage = 750
ENT.defensive = true
ENT.hasSound = true

ENT.radius = 2250
ENT.upStep = 60
ENT.soundLevel = 100

ENT.wreckable_vehicles = {"small", "big"}

local preyTypes = {
    ["shark"] = true,
    ["big_shark"] = true,
    ["huge_shark"] = true,
    ["huge_reptile"] = true,
    ["crocodile"] = true,
    ["killer_whale"] = true
}

local predatorTypes = {
    ["monster"] = true
}

if SERVER then
    for k, v in pairs(list.Get("NPC")) do
        if table.HasValue(v, "Aquatic Animals") or table.HasValue(v, "Aquatic Animals (Extinct)") then
            if preyTypes[v.Type] then
                ENT.prey[k] = true
            elseif predatorTypes[v.Type] then
                ENT.predator[k] = true
            end
        end
    end
end
