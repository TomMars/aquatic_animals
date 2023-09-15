AddCSLuaFile()

ENT.Base = "base_nextbot"

ENT.model = ""
ENT.health = 100
ENT.speed = 25
ENT.damage = 20
ENT.aggressive = false

ENT.radius = 1000
ENT.identicalRadius = false --identical radius on ground and underwater

ENT.ignore = {}
ENT.prey = {} --used for kind npcs
ENT.predator = {}

if CLIENT then return end

--TODO
--navmesh (clamp the wandering zone?)
--!!swimming behaviour!!
--sound
--random skin

function ENT:Initialize()
    self:SetModel(self.model)
    self:SetHealth(self.health)
    self:StartActivity(ACT_WALK)
    self.nav = navmesh.IsLoaded()

    self.fear = false
    self.target = nil
    self.turnCount = 0
    self.attack = false

    self.dmgRadius = math.pow(self.radius/4, 2)
    if self.identicalRadius then
        self.groundRadius = self.radius
    else
        self.groundRadius = self.radius/2
    end
    self.groundDmgRadius = math.pow(self.groundRadius*0.2, 2)

    if self.nav then
        self.goal = self:GetPos() + Vector(math.Rand(-1, 1), math.Rand(-1, 1), 0) * self.groundRadius
    else
        self.goal = self:GetPos() + Vector(math.Rand(-1, 1), math.Rand(-1, 1), 0) * (self.groundRadius * 50)
    end

    self.fearPlayers = false
    -- self.lastSound = ""
    self.idleState = false
    self.idleTimer = -1
    self.groundTimer = -1
end

function ENT:NoNavBehaviour() --when no navmesh
    if !self.fear then
        if self.target == nil then
            self.loco:SetDesiredSpeed(self.speed)
            self.loco:SetStepHeight(50)  --not colliding eachother

            if math.random(1, 100) == 2 then     --1% chance of having a random angle
                self.goal = self:GetPos() + Vector(math.Rand(-1, 1), math.Rand(-1, 1), 0) * (self.groundRadius * 50)
            end

            if self.idleTimer == -1 and math.random(1, 10) == 2 then     --10% chance of entering in idle state
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

                if !self.ignore[class] and v != self and ((self.prey[class] or (self.aggressive and (v:IsNextBot() or v:IsNPC()))) or ((self.aggressive or self.fearPlayers) and (v:IsPlayer() and GetConVarNumber("ai_ignoreplayers") == 0))) and v:Health() > 0 then
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
                if v == self.target and v:IsValid() and (!v:IsPlayer() or GetConVarNumber("ai_ignoreplayers") == 0) and v:Health() > 0 then
                    target = true
                    self.goal = self.target:GetPos()
                    break
                end 
            end

            if target then
                self.loco:SetDesiredSpeed(self.speed * 2)
                self.loco:SetStepHeight(32)
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
        self.loco:SetDesiredSpeed(self.speed * 2)
        self.loco:SetStepHeight(50)
        
        if self.turnCount >= 10 then
            local target = nil
            local bestPos = Vector(0,0,0)

            for _, v in pairs(ents.FindInSphere(self:GetPos(), self.groundRadius)) do 	 	--looking for predator

                if v:IsValid() and (self.predator[v:GetClass()] or (self.fearPlayers and v:IsPlayer() and GetConVarNumber("ai_ignoreplayers") == 0)) and v:Health() > 0 then
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

    if self:WaterLevel() == 3 and !self.attack then
        self.groundTimer = self.groundTimer + 1
        if self.groundTimer >= 150 then --and self:WaterLevel() == 3 
            local ent = ents.Create(string.sub(self:GetClass(), 1, -8))
            ent:SetPos(self:GetPos())
            ent:SetAngles(self:GetAngles())
            ent:SetSkin(self:GetSkin())
            ent.switchState = true
            ent:Spawn()
            self:Remove()
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

            if !self.ignore[class] and v != self and ((self.prey[class] or (self.aggressive and (v:IsNextBot() or v:IsNPC()))) or ((self.aggressive or self.fearPlayers) and (v:IsPlayer() and GetConVarNumber("ai_ignoreplayers") == 0))) and v:Health() > 0 then
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
            self.loco:SetDesiredSpeed(self.speed)
            self.loco:SetStepHeight(50)  --not colliding eachother
            if math.random(1, 3) == 2 then     --33% chance of having a random angle
                self:MoveToPos(self:GetPos() + Vector(math.Rand(-1, 1), math.Rand(-1, 1), 0) * (self.groundRadius/2))
            end
            self.idleState = true
            self:PlaySequenceAndWait("idle" .. math.random(1,3))
            self.idleState = false
            self:StartActivity(ACT_WALK)

        else
            self.loco:SetDesiredSpeed(self.speed * 2)
            self.loco:SetStepHeight(32)

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
                path:SetGoalTolerance(self.groundDmgRadius)
                path:Compute(self, self.target:GetPos())		-- Compute the path towards the enemies position

                while path:IsValid() and self.target != nil do
                
                    if path:GetAge() > 0.1 then					-- Since we are following the player we have to constantly remake the path
                        path:Compute(self, self.target:GetPos())-- Compute the path towards the enemy's position again
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
        self.loco:SetDesiredSpeed(self.speed * 2)
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

                if !self.ignore[class] and v != self and ((self.prey[class] or (self.aggressive and (v:IsNextBot() or v:IsNPC()))) or ((self.aggressive or self.fearPlayers) and (v:IsPlayer() and GetConVarNumber("ai_ignoreplayers") == 0))) and v:Health() > 0 then
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
                if v == self.target and v:IsValid() and (!v:IsPlayer() or GetConVarNumber("ai_ignoreplayers") == 0) and v:Health() > 0 then
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

            for _, v in pairs(ents.FindInSphere(self:GetPos(), self.groundRadius)) do 	 	--looking for predator

                if v:IsValid() and (self.predator[v:GetClass()] or (self.fearPlayers and v:IsPlayer() and GetConVarNumber("ai_ignoreplayers") == 0)) and v:Health() > 0 then
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
                for _, v in pairs(ents.FindInCone(self:GetPos(), self:GetForward(), self.groundRadius, 0,707)) do  --change the angle if facing the predator
                    if v == target then
                        self.goal = Angle(0, self:GetAngles().y + 180, 0):Forward() * self.groundRadius
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

    if self:WaterLevel() == 3 and !self.attack then
        self.groundTimer = self.groundTimer + 1
        if self.groundTimer >= 150 then --and self:WaterLevel() == 3 
            local ent = ents.Create(string.sub(self:GetClass(), 1, -8))
            ent:SetPos(self:GetPos())
            ent:SetAngles(self:GetAngles())
            ent:SetSkin(self:GetSkin())
            ent.switchState = true
            ent:Spawn()
            self:Remove()
        end
    else
        self.groundTimer = -1
    end
end

function ENT:RunBehaviour()
    repeat
        if self.nav then
            self:NavBehaviour()
        else
            self:NoNavBehaviour()
        end

        coroutine.wait(0.1)
    until(false)
end

function ENT:Think()
    if self.nav then
        self:NavThink()
    else
        self:NoNavThink()
    end
end

function ENT:OnContact(ent)
    if !self.fear and ent == self.target and !self.attack then     --restart the coroutine in order to play the attack sequence
        self.attack = true
        self:BehaveStart()
    end
end

function ENT:OnInjured(dmg)
    local attacker = dmg:GetAttacker()
    if self.target == nil and !self.predator[attacker:GetClass()] and (!attacker:IsPlayer() or GetConVarNumber("ai_ignoreplayers") == 0) then
        for _, v in pairs(ents.FindInSphere(self:GetPos(), self.groundRadius)) do
            if v == attacker then
                if !self.aggressive then
                    self.fear = true
                    if attacker:IsPlayer() then
                        self.fearPlayers = true
                    end
                end
                self.target = attacker
                if self.idleState then
                    self.idleState = false
                    self:StartActivity(ACT_WALK)
                end
                self:BehaveStart()
                break
            end
        end
    end
end
