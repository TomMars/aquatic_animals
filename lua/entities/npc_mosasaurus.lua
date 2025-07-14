include("aquatic_hostile.lua")
AddCSLuaFile()

ENT.base = "aquatic_hostile"

ENT.model = "models/aquatic_animals/mosasaurus.mdl"
ENT.health = 5000
ENT.speed = 120
ENT.damage = 1000

ENT.radius = 2250
ENT.upStep = 60

ENT.wreckable_vehicles = {"small", "big"}

local ignoreTypes = {
    ["small_fish"] = true,
    ["fish"] = true,
    ["piranha"] = true
}

local predatorTypes = {
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