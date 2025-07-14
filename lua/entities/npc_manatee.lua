include("aquatic_neutral.lua")
AddCSLuaFile()

ENT.base = "aquatic_neutral"

ENT.model = "models/aquatic_animals/manatee.mdl"
ENT.speed = 70
ENT.hasSound = true

local predatorTypes = {
    ["shark"] = true,
    ["big_shark"] = true,
    ["huge_shark"] = true,
    ["killer_whale"] = true,
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