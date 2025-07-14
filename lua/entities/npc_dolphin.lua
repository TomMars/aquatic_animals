include("aquatic_neutral.lua")
AddCSLuaFile()

ENT.base = "aquatic_neutral"

ENT.model = "models/aquatic_animals/dolphin.mdl"
ENT.defensive = true
ENT.hasSound = true

local preyTypes = {
    ["shark"] = true,
    ["crocodile"] = true
}

local predatorTypes = {
    ["big_shark"] = true,
    ["huge_shark"] = true,
    ["killer_whale"] = true,
    ["huge_reptile"] = true,
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