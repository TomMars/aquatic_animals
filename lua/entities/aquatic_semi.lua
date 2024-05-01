AddCSLuaFile()

ENT.Base = "base_nextbot"

ENT.model = ""
ENT.skin = {0}
ENT.health = 100
ENT.speed = 100
ENT.groundSpeed = 25
ENT.damage = 20
ENT.aggressive = false
ENT.hasSound = false
ENT.fearPlayers = false

ENT.radius = 1000
ENT.identicalRadius = false --identical radius on ground and underwater
ENT.upStep = 45
ENT.minDepth = 69
ENT.maxDepth = 76
ENT.soundLevel = 80
ENT.stepHeight = 32 --used to make npcs collide on ground when chasing a prey, depending on the model 
ENT.switchTimer = 1200 --time before switching to swimming

ENT.ignore = {}
ENT.prey = {} --used for kind npcs
ENT.predator = {}
ENT.wreckable_vehicles = {} --small, big, huge

if CLIENT then return end

function ENT:Initialize()
    self.ground_mdl = string.sub(self.model, 1, -5).. "_ground.mdl"

    if self:WaterLevel() == 0 then
        self.swim = false
        self:SetModel(self.ground_mdl)
        self:StartActivity(ACT_WALK)
    else
        self.swim = true
        self:SetModel(self.model)
        self:SetPos(self:GetPos() + Vector(0,0,200))
        self:StartActivity(ACT_IDLE)
    end
    self:SetSkin(self.skin[math.random(#self.skin)])

    self:SetHealth(self.health)
    self.nav = navmesh.IsLoaded()

    self.fear = false
    self.target = nil
    self.depth = self.maxDepth
    self.turnCount = 20
    self.attack = false

    self.dmgRadius = math.pow(self.radius*0.35, 2)
    if self.identicalRadius then
        self.groundRadius = self.radius
    else
        self.groundRadius = self.radius*0.5
    end
    self.groundDmgRadius = math.pow(self.groundRadius*0.3, 2)

    if self.nav then
        self.goal = self:GetPos() + Vector(math.Rand(-1, 1), math.Rand(-1, 1), 0) * self.groundRadius
    else
        self.goal = self:GetPos() + Vector(math.Rand(-1, 1), math.Rand(-1, 1), 0) * (self.groundRadius * 50)
    end

    self.idleState = false
    self.idleTimer = -1
    self.suffocate = -1
    self.groundTimer = -1
    self.class = self:GetClass()
    if self.hasSound then self.lastSound = "" end

    self.vehicles = {}
    for _, val in pairs(self.wreckable_vehicles) do
        for _, v in pairs(util.JSONToTable(file.Read("faubreins_animals/wreckable_vehicles.json"))[val]) do
            self.vehicles[v] = true
        end
    end
end

function ENT:NoNavBehaviour() --when no navmesh
    if !self.fear then
        if self.target == nil then
            self.loco:SetDesiredSpeed(self.groundSpeed)
            self.loco:SetStepHeight(50)  --not colliding eachother

            if math.random(1, 100) == 2 then     --1% chance of having a random angle
                self.goal = self:GetPos() + Vector(math.Rand(-1, 1), math.Rand(-1, 1), 0) * (self.groundRadius * 50)
                if self.hasSound and math.random(1, 2) == 2 then
                    self.lastSound = "aquatic_animals/".. string.sub(self.class, 5).. "_idle".. math.random(1,3).. ".mp3"
                    self:EmitSound(self.lastSound, self.soundLevel)
                end
            end

            if self.idleTimer == -1 and self.groundTimer == -1 and math.random(1, 10) == 2 then     --10% chance of entering in idle state
                self.idleState = true
                self:PlaySequenceAndWait("idle" .. math.random(1,3))
                self.idleState = false
                self:StartActivity(ACT_WALK)

            elseif self.idleTimer > -1 then   --used to replace the think function
                self.idleTimer = self.idleTimer + 1
                if self.idleTimer >= 600 then   --1min to wait before entering idle state again
                    self.idleTimer = -1
                end
            end

            local target = nil
            local bestPos = nil

            for _, v in pairs(ents.FindInSphere(self:GetPos(), self.groundRadius)) do 	 	--looking for prey
                local class = v:GetClass()

                if !self.ignore[class] and GetConVarNumber("ai_disabled") == 0 and v != self and ((self.prey[class] or self.predator[class] or (self.aggressive and !v:IsPlayer())) or ((self.aggressive or self.fearPlayers) and (v:IsPlayer() and GetConVarNumber("ai_ignoreplayers") == 0))) and v:Health() > 0 then
                    if self.predator[class] or (self.fearPlayers and v:IsPlayer()) then
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

        else
            local target = false 	

            for _, v in pairs(ents.FindInSphere(self:GetPos(), self.groundRadius)) do 	 --check if the prey still here	    
                if v == self.target and GetConVarNumber("ai_disabled") == 0 and v:IsValid() and (!v:IsPlayer() or GetConVarNumber("ai_ignoreplayers") == 0) and v:Health() > 0 then
                    target = true
                    self.goal = self.target:GetPos()
                    break
                end 
            end

            if target then
                self.loco:SetDesiredSpeed(self.groundSpeed * 2)
                self.loco:SetStepHeight(self.stepHeight)
                if self.attack then     --damage the prey
                    self:PlaySequenceAndWait("attack")

                    if self.target:IsValid() and self:GetPos():DistToSqr(self.target:GetPos()) <= self.groundDmgRadius then    --also check if the target is not too far away
                        self.target:TakeDamage(self.damage, self)
            
                        if self.target:IsPlayer() then
                            self.target:ViewPunch(Angle(math.random(-1,1)*25,math.random(-1,1)*25,math.random(-1,1)*25))
                        end
                    end

                    self:StartActivity(ACT_WALK)
                    self.attack = false
                end
            else
                self.goal = self:GetPos() + Vector(math.Rand(-1, 1), math.Rand(-1, 1), 0) * (self.groundRadius * 50)
                self.target = nil
            end
        end
        
    else        --fear
        self.loco:SetDesiredSpeed(self.groundSpeed * 2)
        self.loco:SetStepHeight(50)
        
        if self.turnCount >= 10 then
            local target = nil
            local bestPos = Vector(0,0,0)

            for _, v in pairs(ents.FindInSphere(self:GetPos(), self.groundRadius*3)) do 	 	--looking for predator

                if GetConVarNumber("ai_disabled") == 0 and v:IsValid() and (self.predator[v:GetClass()] or (self.fearPlayers and v:IsPlayer() and GetConVarNumber("ai_ignoreplayers") == 0)) and v:Health() > 0 then
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
                for _, v in pairs(ents.FindInCone(self:GetPos(), self:GetForward(), self.groundRadius, 0,707)) do  --change the angle if facing the predator
                    if v == target then
                        self.goal = Angle(0, self:GetAngles().y + 180, 0):Forward() * self.groundRadius * 50
                        self.turnCount = 0
                        break
                    end          
                end
                self.target = target
                if self.turnCount >= 10 and math.random(1, 50) == 2 then
                    self.goal = Angle(0, self:GetAngles().y + math.random(-45, 45), 0):Forward() * self.groundRadius * 50
                    self.turnCount = 0
                end
            end
        end
    end

    if self.turnCount < 20 then     --avoid to turn every 0.1s when fearing multiple predators
        self.turnCount = self.turnCount + 1
    end

    if !self.idleState and self:WaterLevel() == 3 and !self.attack then
        self.groundTimer = self.groundTimer + 1
        if self.groundTimer >= self.switchTimer * 0.25 then --and self:WaterLevel() == 3 
            self.swim = true
            self:SetModel(self.model)
            self:StartActivity(ACT_IDLE)
            self.loco:SetStepHeight(self.stepHeight)
            self:SetPos(self:GetPos() + Vector(0,0,self.upStep))
            self.groundTimer = -1
            self:SetNotSolid(true)
            timer.Simple(5, function() if IsValid(self) then self:SetNotSolid(false) end end)
        end
    else
        self.groundTimer = -1
    end
end

function ENT:NoNavThink() --when no navmesh
    if !self.idleState then
        self.loco:FaceTowards(self.goal)
        self.loco:Approach(self.goal, 1)
    else
        local target = nil
        local bestPos = nil

        for _, v in pairs(ents.FindInSphere(self:GetPos(), self.groundRadius)) do 	 	--looking for prey
            local class = v:GetClass()

            if !self.ignore[class] and GetConVarNumber("ai_disabled") == 0 and v != self and ((self.prey[class] or (self.aggressive and (v:IsNextBot() or v:IsNPC()))) or ((self.aggressive or self.fearPlayers) and (v:IsPlayer() and GetConVarNumber("ai_ignoreplayers") == 0))) and v:Health() > 0 then
                if self.predator[class] or (self.fearPlayers and v:IsPlayer()) then
                    self.fear = true
                    self.target = v
                    break
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
        if self.target != nil then
            self.idleState = false
            self:StartActivity(ACT_WALK)
            self:BehaveStart()
        else
            self.idleTimer = self.idleTimer + 1
        end
    end
end

function ENT:NavBehaviour() --when navmesh
    if !self.fear then
        if self.target == nil then
            self.loco:SetDesiredSpeed(self.groundSpeed)
            self.loco:SetStepHeight(50)  --not colliding eachother
            if math.random(1, 3) == 2 then     --33% chance of having a random angle
                self:MoveToPos(self:GetPos() + Vector(math.Rand(-1, 1), math.Rand(-1, 1), 0) * (math.random(self.groundRadius*0.25, self.groundRadius*0.5)))
                if self.hasSound and math.random(1, 2) == 2 then
                    self.lastSound = "aquatic_animals/".. string.sub(self.class, 5).. "_idle".. math.random(1,3).. ".mp3"
                    self:EmitSound(self.lastSound, self.soundLevel)
                end
            end
            if self.groundTimer == -1 then
                self.idleState = true
                self:PlaySequenceAndWait("idle" .. math.random(1,3))
                self.idleState = false
                self:StartActivity(ACT_WALK)
            end

        else
            self.loco:SetDesiredSpeed(self.groundSpeed * 2)
            self.loco:SetStepHeight(self.stepHeight)

            if self.attack then     --damage the prey
                self:PlaySequenceAndWait("attack")

                if self.target:IsValid() and self:GetPos():DistToSqr(self.target:GetPos()) <= self.groundDmgRadius then    --also check if the target is not too far away
                    self.target:TakeDamage(self.damage, self)
        
                    if self.target:IsPlayer() then
                        self.target:ViewPunch(Angle(math.random(-1,1)*25,math.random(-1,1)*25,math.random(-1,1)*25))
                    end
                end

                self:StartActivity(ACT_WALK)
                self.attack = false

            else
                --logic from gmod wiki ENT:Chase() https://wiki.facepunch.com/gmod/NextBot_NPC_Creation
                local path = Path("Follow")
                path:SetMinLookAheadDistance(self.groundRadius)
                path:SetGoalTolerance(self.groundDmgRadius*0.25)
                path:Compute(self, self.target:GetPos())		-- Compute the path towards the enemies position

                while path:IsValid() and self.target != nil and self.target:IsValid() do
                
                    if path:GetAge() > 0.1 then					-- Since we are following the target we have to constantly remake the path
                        path:Compute(self, self.target:GetPos())    -- Compute the path towards the enemy's position again
                    end
                    path:Update(self)								-- This function moves the bot along the path
                    
                    -- If we're stuck, then call the HandleStuck function and abandon
                    if self.loco:IsStuck() then
                        self:HandleStuck()
                        break
                    end
                    coroutine.yield()
                end
            end
        end
        
    else        --fear
        self.loco:SetDesiredSpeed(self.groundSpeed * 2)
        self.loco:SetStepHeight(50)
        self:MoveToPos(self.goal)
    end
end

function ENT:NavThink() --when navmesh
    if !self.fear then
        if self.target == nil then
            local target = nil
            local bestPos = nil

            if !self.idleState and self:GetPos():DistToSqr(self.goal) > self.groundRadius * self.groundRadius then  --when the npc is too far away for some reason
                self.goal = self:GetPos()   --avoid to restart the coroutine every tick
                self:BehaveStart()
            end

            for _, v in pairs(ents.FindInSphere(self:GetPos(), self.groundRadius)) do 	 	--looking for prey
                local class = v:GetClass()

                if !self.ignore[class] and GetConVarNumber("ai_disabled") == 0 and v != self and ((self.prey[class] or self.predator[class] or (self.aggressive and !v:IsPlayer())) or ((self.aggressive or self.fearPlayers) and (v:IsPlayer() and GetConVarNumber("ai_ignoreplayers") == 0))) and v:Health() > 0 then
                    if self.predator[class] or (self.fearPlayers and v:IsPlayer()) then
                        self.fear = true
                        target = v
                        break
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
            if self.target != nil then
                if self.idleState then
                    self.idleState = false
                    self:StartActivity(ACT_WALK)
                end
                self:BehaveStart()
            end
        
        else
            local target = false 	

            for _, v in pairs(ents.FindInSphere(self:GetPos(), self.groundRadius)) do 	 --check if the prey still here	    
                if v == self.target and GetConVarNumber("ai_disabled") == 0 and v:IsValid() and (!v:IsPlayer() or GetConVarNumber("ai_ignoreplayers") == 0) and v:Health() > 0 then
                    target = true
                    self.goal = self.target:GetPos()
                    break
                end 
            end

            if !target then
                self.target = nil
                self:BehaveStart()
            end
        end
    
    else    --fear
        if self.turnCount >= 50 then
            local target = nil
            local bestPos = Vector(0,0,0)

            for _, v in pairs(ents.FindInSphere(self:GetPos(), self.groundRadius*3)) do 	 	--looking for predator

                if GetConVarNumber("ai_disabled") == 0 and v:IsValid() and (self.predator[v:GetClass()] or (self.fearPlayers and v:IsPlayer() and GetConVarNumber("ai_ignoreplayers") == 0)) and v:Health() > 0 then
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
                self:BehaveStart()
            else
                for _, v in pairs(ents.FindInCone(self:GetPos(), self:GetForward(), self.groundRadius, 0,177)) do  --change the angle if facing the predator
                    if v == target then
                        self.goal = self:GetPos() + Vector(math.Rand(-1, 1), math.Rand(-1, 1), 0) * self.groundRadius
                        self.turnCount = 0
                        break
                    end          
                end
                self.target = target
                if self.turnCount >= 50 and math.random(1, 50) == 2 then
                    self.goal = Angle(0, self:GetAngles().y + math.random(-45, 45), 0):Forward() * self.groundRadius
                    self.turnCount = 0
                end
                self:BehaveStart()
            end
        end
    end

    if self.turnCount < 100 then     --avoid to turn every tick when fearing multiple predators
        self.turnCount = self.turnCount + 1
    end

    if !self.idleState and self:WaterLevel() == 3 and !self.attack then
        self.groundTimer = self.groundTimer + 1
        if self.groundTimer >= self.switchTimer then --and self:WaterLevel() == 3 
            self.swim = true
            self:SetModel(self.model)
            self:StartActivity(ACT_IDLE)
            self.loco:SetStepHeight(self.stepHeight)
            self:SetPos(self:GetPos() + Vector(0,0,self.upStep))
            self.groundTimer = -1
            self.turnCount = 0
            self:SetNotSolid(true)
            self:BehaveStart()
            timer.Simple(5, function() if IsValid(self) then self:SetNotSolid(false) end end)
        end
    else
        self.groundTimer = -1
    end
end

function ENT:SwimBehaviour()
    if !self.fear then
        if self.target == nil then
            if self.turnCount == 20 and math.random(1, 100) == 2 then     --1% chance of having a random angle
                self:SetAngles(Angle(0, math.random(0, 360), 0))
                if self.hasSound and math.random(1, 2) == 2 then
                    self.lastSound = "aquatic_animals/".. string.sub(self.class, 5).. "_idle".. math.random(1,3).. ".mp3"
                    self:EmitSound(self.lastSound, self.soundLevel)
                end
            end
            
            if self.depth == self.minDepth and self:WaterLevel() > 0 and math.random(1, 2000) == 2 then     --0,05% chance of changing depth
                self.depth = self.maxDepth
            end
            
            if self.turnCount >= 10 then
                local target = nil
                local bestPos = nil

                for _, v in pairs(ents.FindInSphere(self:GetPos(), self.radius)) do 	 	--looking for prey
                    local class = v:GetClass()

                    if GetConVarNumber("ai_disabled") == 0 and ((!self.ignore[class] and v != self and (self.prey[class] or self.predator[class] or (self.aggressive and !v:IsPlayer()) or ((self.aggressive or self.fearPlayers) and (v:IsPlayer() and GetConVarNumber("ai_ignoreplayers") == 0))) and v:Health() > 0) or (self.aggressive and v:IsVehicle() and self.vehicles[v:GetVehicleClass()] and v:GetDriver() != NULL and (!v:GetDriver():IsPlayer() or GetConVarNumber("ai_ignoreplayers") == 0))) and v:WaterLevel() > 0 and self:WaterLevel() > 0 then
                        if self.predator[class] or (self.fearPlayers and v:IsPlayer()) then
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
                if v == self.target and GetConVarNumber("ai_disabled") == 0 and v:IsValid() and (((!v:IsPlayer() or GetConVarNumber("ai_ignoreplayers") == 0) and v:Health() > 0) or (v:IsVehicle() and (!v:GetDriver():IsPlayer() or GetConVarNumber("ai_ignoreplayers") == 0))) and v:WaterLevel() > 0 and self:WaterLevel() > 0  then
                    target = true
                    break
                end 
            end

            if target then
                self:PointAtEntity(self.target)

                if self.attack then     --damage the prey
                    self:PlaySequenceAndWait("attack")

                    if self.target:IsValid() and self.target:WaterLevel() > 0 and self:GetPos():DistToSqr(self.target:GetPos()) <= self.dmgRadius then    --also check if the target is not too far away
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

            for _, v in pairs(ents.FindInSphere(self:GetPos(), self.radius*1.5)) do 	 	--looking for predator

                if  GetConVarNumber("ai_disabled") == 0 and v:IsValid() and (self.predator[v:GetClass()] or (self.fearPlayers and v:IsPlayer() and GetConVarNumber("ai_ignoreplayers") == 0)) and v:Health() > 0 and v:WaterLevel() > 0 and self:WaterLevel() > 0 then
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
    end
end

function ENT:SwimThink()
    local magicNum = -125/#player.GetAll()
    for _, ent in ents.Iterator() do if ent:IsNextBot() then magicNum = magicNum + 1 end end
    local lagFactor = 100
    if magicNum > 0 then lagFactor = 100 * (1 + (magicNum*0.001)) end

    if self:WaterLevel() == 3 then
        if self.target == nil then
            self.loco:SetVelocity(self:GetForward() * self.speed + (self:GetUp() * self.depth) * (lagFactor*engine.TickInterval()))
        else
            self.loco:SetVelocity(self:GetForward() * (self.speed * 4) + (self:GetUp() * self.depth) * (lagFactor*engine.TickInterval()))
        end
        self.suffocate = -1
    else
        self.depth = self.minDepth
        if self.suffocate == -1 then
            self.suffocate = 0
        elseif self.suffocate < 20 then
            self.loco:SetVelocity(self:GetForward() * (self.speed * 0.5) + (self:GetUp() * (self.minDepth -3)) * (lagFactor*engine.TickInterval()))
        else
            self.loco:SetVelocity(self:GetForward() * (self.speed * 0.5) + self:GetUp() * (lagFactor*engine.TickInterval()))
        end
    end
end

function ENT:RunBehaviour()
    repeat
        if !self.swim then
            if self.nav then
                self:NavBehaviour()
            else
                self:NoNavBehaviour()
            end
        else
            self:SwimBehaviour()
        end

        coroutine.wait(0.1)
    until(false)
end

function ENT:Think()
    if !self.swim then
        if self.nav then
            self:NavThink()
        else
            self:NoNavThink()
        end
    else
        self:SwimThink()
    end
end

function ENT:OnLandOnGround(ent)    --avoid to be stuck in the ground
    if self.swim then
        self:SetPos(self:GetPos() + Vector(0,0,self.upStep))
        if !self.attack and self:WaterLevel() < 3 then   --change to ground behaviour
            self.swim = false
            self:SetModel(self.ground_mdl)
            self:StartActivity(ACT_WALK)
            self.suffocate = -1
        else
            if (self.fear or self.target == nil) and math.random(1, 4) == 2 then
                self:SetAngles(Angle(0, self:GetAngles().y + 180, 0))
            end
            self.depth = self.maxDepth
        end
    end
end

function ENT:OnContact(ent)
    if !self.swim then
        if !self.fear and ent == self.target and !self.attack then     --restart the coroutine in order to play the attack sequence
            self.attack = true
            self:BehaveStart()
        end

    else
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
end

function ENT:OnInjured(dmg)
    if self.hasSound then
        self:StopSound(self.lastSound)
        self.lastSound = "aquatic_animals/".. string.sub(self.class, 5).. "_injured".. math.random(1,2).. ".mp3"
        self:EmitSound(self.lastSound, self.soundLevel)
    end

    if dmg:IsExplosionDamage() then dmg:SetDamage(dmg:GetDamage() * 20) end

    local attacker = dmg:GetAttacker()
    if self.target == nil and !self.predator[attacker:GetClass()] and (!attacker:IsPlayer() or GetConVarNumber("ai_ignoreplayers") == 0) then
        if self.swim and attacker:WaterLevel() == 0 then
            self.depth = self.minDepth
        else
            local rad = self.radius
            local isPly = attacker:IsPlayer()
            if !self.swim then rad = self.groundRadius*3 end
            for _, v in pairs(ents.FindInSphere(self:GetPos(), rad)) do
                if v == attacker then
                    if !self.aggressive then
                        local class = attacker:GetClass()
                        self.fear = true
                        if isPly then self.fearPlayers = true
                        elseif !self.predator[class] then self.predator[class] = true end
                    end
                    self.target = attacker
                    if !self.swim then
                        if self.idleState then
                            self.idleState = false
                            self:StartActivity(ACT_WALK)
                        end
                        self:BehaveStart()
                    end
                elseif !self.aggressive and isPly and v:GetClass() == self.class and v:IsValid() then   --surrounding npcs with the same class will fear players
                    v.fearPlayers = true
                    if v.target == nil then
                        v:BehaveStart()
                    end
                end
            end
        end
    end
end
