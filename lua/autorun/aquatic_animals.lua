if !file.Exists("aquatic_animals/wreckable_vehicles.json", "DATA") then
    local tbl = {small= {"Airboat", "vehicle_kaw_jetski"}, big= {"Yacht_1", "Yacht_2"}, huge= {}}
    file.CreateDir("aquatic_animals")
    file.Write("aquatic_animals/wreckable_vehicles.json", util.TableToJSON(tbl, true))
end

hook.Add("AddToolMenuCategories", "AquaticAnimalsCategory", function()
    spawnmenu.AddToolCategory("Options", "AquaticAnimals", "#Aquatic Animals")
end)

hook.Add("PopulateToolMenu", "AquaticAnimalsSettings", function()
    spawnmenu.AddToolMenuOption("Options", "AquaticAnimals", "WreckableVehicles", "#Wreckable Vehicles", "", "", function(panel)

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
                for k, v in pairs(util.JSONToTable(file.Read("aquatic_animals/wreckable_vehicles.json"))[val]) do
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
                    if input:GetValue() != "" and cbox:GetValue() != "Size" then
                        pnl:AddLine(input:GetValue(), cbox:GetValue())
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
                        if input:GetValue() != "" and cbox:GetValue() != "Size" then
                            line:SetColumnText(1, input:GetValue())
                            line:SetColumnText(2, cbox:GetValue())
                        end
                        promptOpen = false
                    end
                end
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
                    file.Write("aquatic_animals/wreckable_vehicles.json", util.TableToJSON(tbl, true))
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
list.Set("NPC", "npc_blue_shark", {
    Name = "Blue Shark",
    Class = "npc_blue_shark",
    Category = "Aquatic Animals"
})

list.Set("NPC", "npc_reef_shark", {
    Name = "Reef Shark",
    Class = "npc_reef_shark",
    Category = "Aquatic Animals"
})

list.Set("NPC", "npc_hammerhead_shark", {
    Name = "Hammerhead Shark",
    Class = "npc_hammerhead_shark",
    Category = "Aquatic Animals"
})

list.Set("NPC", "npc_bull_shark", {
    Name = "Bull Shark",
    Class = "npc_bull_shark",
    Category = "Aquatic Animals"
})

list.Set("NPC", "npc_great_white_shark", {
    Name = "Great White Shark",
    Class = "npc_great_white_shark",
    Category = "Aquatic Animals"
})

list.Set("NPC", "npc_killer_whale", {
    Name = "Killer Whale",
    Class = "npc_killer_whale",
    Category = "Aquatic Animals"
})

list.Set("NPC", "npc_sperm_whale", {
    Name = "Sperm Whale",
    Class = "npc_sperm_whale",
    Category = "Aquatic Animals"
})

list.Set("NPC", "npc_megalodon", {
    Name = "Megalodon",
    Class = "npc_megalodon",
    Category = "Extinct Aquatic Animals"
})
