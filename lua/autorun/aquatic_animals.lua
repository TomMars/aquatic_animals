if !file.Exists("faubreins_animals/wreckable_vehicles.json", "DATA") then
    local tbl = {small= {"Airboat", "vehicle_kaw_jetski"}, big= {"Yacht_1", "Yacht_2"}, huge= {}}
    file.CreateDir("faubreins_animals")
    file.Write("faubreins_animals/wreckable_vehicles.json", util.TableToJSON(tbl, true))
end

hook.Add("AddToolMenuCategories", "FaubreinsAnimalsCategory", function()
    spawnmenu.AddToolCategory("Options", "FaubreinsAnimals", "#Faubrein's Animals")
end)

hook.Add("PopulateToolMenu", "FaubreinsAnimalsSettings", function()
    spawnmenu.AddToolMenuOption("Options", "FaubreinsAnimals", "WreckableVehicles", "#Wreckable Vehicles", "", "", function(panel)

        function PopupFrame(title)
            local frame = vgui.Create("DFrame")
            frame:SetSize(600, 100)
            frame:Center()
            frame:MakePopup()
            frame:SetTitle(title)
            frame:SetDraggable(false)
            frame:SetDeleteOnClose(true)
            return frame
        end

        function PromptFrame(title)
            local frame = PopupFrame(title)
            local input = vgui.Create("DTextEntry", frame)
            input:SetSize(200, 25)
            input:Dock(TOP)

            local cbox = vgui.Create("DComboBox", frame)
            cbox:SetSize(200, 25)
            cbox:Dock(TOP)
            cbox:SetValue("Size")
            cbox:AddChoice("small")
            cbox:AddChoice("big")
            cbox:AddChoice("huge")
            return frame, input, cbox
        end

        function LoadFile(dlist)
            for key, val in pairs({"small", "big", "huge"}) do
                for k, v in pairs(util.JSONToTable(file.Read("faubreins_animals/wreckable_vehicles.json"))[val]) do
                    dlist:AddLine(v, val)
                end
            end
        end

        local pnl = vgui.Create("DListView", panel)
        pnl:SetSize(500, 500)
        pnl:Dock(TOP)
        pnl:AddColumn("Class")
        pnl:AddColumn("Size")
        LoadFile(pnl)
        local promptOpen = false

        local add = vgui.Create("DButton", panel)
        add:Dock(TOP)
        add:SetText("Add")

        function add:DoClick()
            if !promptOpen then
                promptOpen = true
                local frame, input, cbox = PromptFrame("Add a wreckable vehicle")

                function frame:OnClose()
                    local exists = false
                    local ival = input:GetValue()
                    for _, v in pairs(pnl:GetLines()) do
                        if ival == v:GetColumnText(1) then exists = true break end
                    end
                    if !exists and ival != "" and cbox:GetValue() != "Size" then
                        pnl:AddLine(ival, cbox:GetValue())
                    elseif exists then
                        notification.AddLegacy("Class "..ival.." is already wreckable", NOTIFY_ERROR, 5)
                        surface.PlaySound("buttons/button10.wav")
                    end
                    promptOpen = false
                end
            end
        end

        local modify = vgui.Create("DButton", panel)
        modify:Dock(TOP)
        modify:SetText("Modify") 

        function modify:DoClick()
            if !promptOpen then
                local _, line = pnl:GetSelectedLine()

                if line != nil then
                    promptOpen = true
                    local frame, input, cbox = PromptFrame("Modify a wreckable vehicle")
                    input:SetValue(line:GetColumnText(1))
                    cbox:SetValue(line:GetColumnText(2))

                    function frame:OnClose()
                        local exists = false
                        local ival = input:GetValue()
                        for _, v in pairs(pnl:GetLines()) do
                            if ival == v:GetColumnText(1) and v!= line then exists = true break end
                        end
                        if !exists and ival != "" then
                            line:SetColumnText(1, ival)
                            line:SetColumnText(2, cbox:GetValue())
                        elseif exists then
                            notification.AddLegacy("Class "..ival.." is already wreckable", NOTIFY_ERROR, 5)
                            surface.PlaySound("buttons/button10.wav")
                        end
                        promptOpen = false
                    end
                end
            end
        end

        local ad = vgui.Create("DButton", panel)
        ad:Dock(TOP)
        ad:SetText("Auto Detect")

        function ad:DoClick()
            local tbl = {}
            for _, v in pairs(pnl:GetLines()) do
                tbl[v:GetColumnText(1)] = true
            end
            for k, _ in pairs(list.Get("Vehicles")) do
                if !tbl[k] then pnl:AddLine(k, "small") end
            end            
            for k, _ in pairs(list.Get("simfphys_vehicles")) do  --symfphys
                if !tbl[k] then pnl:AddLine(k, "small") end
            end
        end

        local rem = vgui.Create("DButton", panel)
        rem:Dock(TOP)
        rem:SetText("Remove")

        function rem:DoClick()
            for k, v in pairs(pnl:GetSelected()) do
                pnl:RemoveLine(v:GetID())
            end
        end

        local reset = vgui.Create("DButton", panel)
        reset:Dock(TOP)
        reset:SetText("Reload")

        function reset:DoClick()
            for k, v in pairs(pnl:GetLines()) do
                pnl:RemoveLine(v:GetID())
            end
            LoadFile(pnl)
        end
        
        local save = vgui.Create("DButton", panel)
        save:Dock(TOP)
        save:SetText("Save")

        function save:DoClick()
            if !promptOpen then
                promptOpen = true
                local frame = PopupFrame("Do you want to save ?")
                local yes = vgui.Create("DButton", frame)
                yes:SetSize(200, 50)
                yes:Dock(TOP)
                yes:SetText("Save")

                function yes:DoClick()
                    local tbl = {small = {}, big = {}, huge = {}}
                    for k,v in pairs(pnl:GetLines()) do
                        table.insert(tbl[v:GetColumnText(2)], v:GetColumnText(1))
                    end
                    file.Write("faubreins_animals/wreckable_vehicles.json", util.TableToJSON(tbl, true))
                    frame:Close()
                end

                function frame:OnClose()
                    promptOpen = false
                end
            end
        end
    end)
end)


--------------- SPAWNLIST -----------------
if !game.SinglePlayer() then
    local animals = {"Blue Shark", "Reef Shark", "Hammerhead Shark", "Bull Shark", "Great White Shark", 
                    "Great White Shark 2", "Killer Whale", "Sperm Whale", "Sea Turtle", "Dolphin",
                    "Manatee", "Blue Whale", "Crocodile", "Piranha", "Roach",
                    "Goldfish", "Bass", "Pike", "Tuna"}

    for _, name in pairs(animals) do
        local class = "npc_".. string.Replace(string.lower(name), " ", "_")
        list.Set("NPC", class, {
            Name = name,
            Class = class,
            Category = "Aquatic Animals"
        })
    end

    animals = {"Megalodon", "Mosasaurus"}

    for _, name in pairs(animals) do
        local class = "npc_".. string.Replace(string.lower(name), " ", "_")
        list.Set("NPC", class, {
            Name = name,
            Class = class,
            Category = "Aquatic Animals (Extinct)"
        })
    end
else
    local msg = true
    hook.Add( "PlayerSpawn", "AquaticSinglePlayerError", function(ply)
        if msg then
            PrintMessage(HUD_PRINTTALK, "Aquatic Animals are not working in singleplayer")
            PrintMessage(HUD_PRINTTALK, "Launching a LAN game will allow you to spawn the npcs")
            msg = false
        end
    end )
end
