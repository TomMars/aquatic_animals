include("aquatic_hostile.lua")
AddCSLuaFile()

ENT.base = "aquatic_hostile"

ENT.model = "models/aquatic_animals/reef_shark.mdl"
ENT.skin = {0, 1}

local ignoreTypes = {
    ["small_fish"] = true,
    ["shark"] = true,
    ["whale"] = true,
    ["huge_whale"] = true
}

local predatorTypes = {
    ["big_shark"] = true,
    ["huge_shark"] = true,
    ["killer_whale"] = true,
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