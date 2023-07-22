AddCSLuaFile()

ENT.Base = "base_nextbot"

ENT.model = ""
ENT.health = 100
ENT.speed = 100
ENT.damage = 20

ENT.radius = 1000
ENT.upStep = 20
ENT.minDepth = 103
ENT.maxDepth = 110

ENT.ignore = {}
ENT.predator = {}
ENT.wreckable_vehicles = {} --small, big, huge

if CLIENT then return end

function ENT:Initialize()
    self:SetModel(self.model)
    self:SetHealth(self.health)
    self:SetPos(self:GetPos() + Vector(0,0,200))
    self:StartActivity(ACT_IDLE)

    self.fear = false
    self.target = nil
    self.depth = self.maxDepth
    self.turnCount = 20
    self.attack = false
    self.lastPos = Vector(0, 0, 0)
    self.suffocate = -1

    self.vehicles = {}
    for _, val in pairs(self.wreckable_vehicles) do
        for _, v in pairs(util.JSONToTable(file.Read("aquatic_animals/wreckable_vehicles.json"))[val]) do
            self.vehicles[v] = true
        end
    end
end

function ENT:RunBehaviour()
    repeat
        if !self.fear then
            if self.target == nil then
                if self.turnCount == 20 and math.random(1, 100) == 2 then     --1% chance of having a random angle
                    self:SetAngles(Angle(0, math.random(0, 360), 0))
                end
                
                if self.depth == self.minDepth and self:WaterLevel() > 0 and math.random(1, 2000) == 2 then     --0,05% chance of changing depth
                    self.depth = self.maxDepth
                end
                
                if self.turnCount >= 10 then
                    local target = nil
                    local bestPos = nil

                    for _, v in pairs(ents.FindInSphere(self:GetPos(), self.radius)) do 	 	--looking for prey
                        local class = v:GetClass()

                        if ((!self.ignore[class] and v != self and (!v:IsPlayer() or GetConVarNumber("ai_ignoreplayers") == 0) and v:Health() > 0) or (v:IsVehicle() and self.vehicles[v:GetVehicleClass()] and v:IsEngineStarted() and (!v:GetDriver():IsPlayer() or GetConVarNumber("ai_ignoreplayers") == 0))) and v:WaterLevel() > 0 and self:WaterLevel() > 0 then
                            if self.predator[class] then
                                self.fear = true
                                self.target = v
                                self:BehaveStart()
                            else
                                if target != nil then       --target the closest prey
                                    local pos = self:GetPos():DistToSqr(v:GetPos())
                                    if pos < bestPos then
                                        target = v
                                        bestPos = pos
                                    end
                                else
                                    target = v
                                    bestPos = self:GetPos():DistToSqr(v:GetPos())
                                end
                            end
                        end 
                    end
                    self.target = target
                end

            else
                local target = false 	

                for _, v in pairs(ents.FindInSphere(self:GetPos(), self.radius)) do 	 --check if the prey still here	    
                    if v == self.target and v:IsValid() and (((!v:IsPlayer() or GetConVarNumber("ai_ignoreplayers") == 0) and v:Health() > 0) or (v:IsVehicle() and (!v:GetDriver():IsPlayer() or GetConVarNumber("ai_ignoreplayers") == 0))) and v:WaterLevel() > 0 and self:WaterLevel() > 0  then
                        target = true
                        break
                    end 
                end

                if target then
                    self:PointAtEntity(self.target)

                    if self.attack then     --damage the prey
                        self:PlaySequenceAndWait("attack")

                        if self.target:IsValid() and self.target:WaterLevel() > 0 then
                            if self.target:IsVehicle() then
                                self.target:EmitSound("physics/metal/metal_large_debris".. math.random(1, 2).. ".wav")
                                self.target:Remove()
                            else
                                self.target:TakeDamage(self.damage, self)
                    
                                if self.target:IsPlayer() then
                                    self.target:ViewPunch(Angle(math.random(-1,1)*25,math.random(-1,1)*25,math.random(-1,1)*25))
                                end
                            end
                        end

                        self:StartActivity(ACT_IDLE)
                        self.attack = false
                    end
                else
                    self:SetAngles(Angle(0, self:GetAngles().y, 0))
                    self.target = nil
                end
            end

        else        --fear
            if self.turnCount >= 10 then
                local target = nil
                local bestPos = Vector(0,0,0)

                for _, v in pairs(ents.FindInSphere(self:GetPos(), self.radius)) do 	 	--looking for predator

                    if self.predator[v:GetClass()] and v:IsValid() and (v:IsNextBot() or v:IsPlayer() or v:IsNPC()) and v:Health() > 0 and v:WaterLevel() > 0 and self:WaterLevel() > 0 then
                        if target != nil then       --flee the closest predator
                            local pos = self:GetPos():DistToSqr(v:GetPos())
                            if pos < bestPos then
                                target = v
                                bestPos = pos
                            end
                        else
                            target = v
                            bestPos = self:GetPos():DistToSqr(v:GetPos())
                        end
                    end 
                end

                if target == nil then
                    self.target = nil
                    self.fear = false
                else
                    if target != self.target then
                        for _, v in pairs(ents.FindInCone(self:GetPos(), self:GetForward(), self.radius, 0,707)) do  --change the angle if facing the predator
                            if v == target then
                                self:SetAngles(Angle(0, self:GetAngles().y + 180, 0))
                                self.turnCount = 0
                                break
                            end          
                        end
                        self.target = target
                    end
                end
            end
        end

        if self.turnCount < 20 then     -- avoid to be stuck
            self.turnCount = self.turnCount + 1
        else
            local pos = self:GetPos()

            if pos == self.lastPos then
                self:SetPos(pos + Vector(0,0,self.upStep))
            else
                self.lastPos = pos
            end
        end

        if self.suffocate > -1 then
            self.suffocate = self.suffocate + 1
            if self.suffocate >= 150 then
                self:TakeDamage(self:Health(), self)
            end
        end

        coroutine.wait(0.1)
    until(false)
end

function ENT:Think()
    if self:WaterLevel() == 3 then
        if self.target == nil then
            self.loco:SetVelocity(self:GetForward() * self.speed + self:GetUp() * self.depth)
        else
            self.loco:SetVelocity(self:GetForward() * (self.speed * 3) + self:GetUp() * self.depth)
        end
        self.suffocate = -1
    else
        self.depth = self.minDepth
        if self.suffocate == -1 then
            self.suffocate = 0
        elseif self.suffocate < 20 then
            self.loco:SetVelocity(self:GetForward() * (self.speed * 0.5) + self:GetUp() * 100)
        else
            self.loco:SetVelocity(self:GetForward() * (self.speed * 0.5) + self:GetUp())
        end
    end
end

function ENT:OnLandOnGround(ent)    --avoid to be stuck in the ground
    self:SetPos(self:GetPos() + Vector(0,0,self.upStep))
    if (self.fear or self.target == nil) and (self:WaterLevel() < 3 or math.random(1, 4) == 2) then
        self:SetAngles(Angle(0, self:GetAngles().y + 180, 0))
    end
    self.depth = self.maxDepth
end

function ENT:OnContact(ent)
    if !self.fear and ent == self.target and !self.attack then     --restart the coroutine in order to play the attack sequence
        self.attack = true
        self:BehaveStart()
        self.loco:SetVelocity(-self:GetForward() * self.speed * 5)
    end

    if self.turnCount == 20 and (self.fear or self.target == nil) and !self.loco:IsOnGround() then     --avoid to be stuck in the walls
        self.turnCount = 0
        if !self.fear then
            self.target = nil
        end
        self.loco:SetVelocity(-self:GetForward() * self.speed * 5)
        if !self.fear or ent != self.target then    --avoid to face the predator
            self:SetAngles(Angle(0, self:GetAngles().y + math.random(135, 225), 0))
        end
    end
end

function ENT:OnInjured(dmg)
    local attacker = dmg:GetAttacker()
    if self.target == nil and !self.predator[attacker:GetClass()] and (!attacker:IsPlayer() or GetConVarNumber("ai_ignoreplayers") == 0) then
        if attacker:WaterLevel() == 0 then
            self.depth = self.minDepth
        else
            for _, v in pairs(ents.FindInSphere(self:GetPos(), self.radius)) do
                if v == attacker then
                    self.target = attacker
                    break
                end
            end
        end
    end
end
