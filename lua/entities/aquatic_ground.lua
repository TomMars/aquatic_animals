AddCSLuaFile()

ENT.Base = "base_nextbot"

ENT.model = ""
ENT.health = 100
ENT.speed = 25
ENT.damage = 20
ENT.aggressive = false

ENT.radius = 500

ENT.ignore = {}
ENT.prey = {} --used for kind npcs
ENT.predator = {}

if CLIENT then return end

--TODO
--polish ground dmg range
--navmesh (might fix not colliding eachother)
--!!swimming behaviour!!
--sound
--random skin

function ENT:Initialize()
    self:SetModel(self.model)
    self:SetHealth(self.health)
    self:StartActivity(ACT_WALK)

    self.fear = false
    self.target = nil
    self.turnCount = 0
    self.attack = false
    self.pos = self:GetPos() + Vector(math.Rand(-1, 1), math.Rand(-1, 1), 0) * (self.radius * 50)
    self.fearPlayers = false
    -- self.lastSound = ""
    self.idleState = false
    self.idleTimer = -1
    self.groundTimer = -1
end

function ENT:NoNavBehaviour() --when no nav mesh
    if !self.fear then
        if self.target == nil then
            self.loco:SetDesiredSpeed(self.speed)
            self.loco:SetStepHeight(50)  --not colliding eachother

            if math.random(1, 100) == 2 then     --1% chance of having a random angle
                self.pos = self:GetPos() + Vector(math.Rand(-1, 1), math.Rand(-1, 1), 0) * (self.radius * 50)
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

            for _, v in pairs(ents.FindInSphere(self:GetPos(), self.radius)) do 	 	--looking for prey
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

            for _, v in pairs(ents.FindInSphere(self:GetPos(), self.radius)) do 	 --check if the prey still here	    
                if v == self.target and v:IsValid() and (!v:IsPlayer() or GetConVarNumber("ai_ignoreplayers") == 0) and v:Health() > 0 then
                    target = true
                    self.pos = self.target:GetPos()
                    break
                end 
            end

            if target then
                self.loco:SetDesiredSpeed(self.speed * 2)
                self.loco:SetStepHeight(32)
                if self.attack then     --damage the prey
                    self:PlaySequenceAndWait("attack")

                    if self.target:IsValid() then
                        self.target:TakeDamage(self.damage, self)
            
                        if self.target:IsPlayer() then
                            self.target:ViewPunch(Angle(math.random(-1,1)*25,math.random(-1,1)*25,math.random(-1,1)*25))
                        end
                    end

                    self:StartActivity(ACT_WALK)
                    self.attack = false
                end
            else
                self.pos = self:GetPos() + Vector(math.Rand(-1, 1), math.Rand(-1, 1), 0) * (self.radius * 50)
                self.target = nil
            end
        end
        
    else        --fear
        self.loco:SetDesiredSpeed(self.speed * 2)
        self.loco:SetStepHeight(50)
        
        if self.turnCount >= 10 then
            local target = nil
            local bestPos = Vector(0,0,0)

            for _, v in pairs(ents.FindInSphere(self:GetPos(), self.radius)) do 	 	--looking for predator

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
                for _, v in pairs(ents.FindInCone(self:GetPos(), self:GetForward(), self.radius, 0,707)) do  --change the angle if facing the predator
                    if v == target then
                        self.pos = Angle(0, self:GetAngles().y + 180, 0):Forward() * self.radius * 50
                        self.turnCount = 0
                        break
                    end          
                end
                self.target = target
                if self.turnCount >= 10 and math.random(1, 50) == 2 then
                    self.pos = Angle(0, self:GetAngles().y + math.random(-45, 45), 0):Forward() * self.radius * 50
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

function ENT:NoNavThink() --when no nav mesh
    if !self.idleState then
        self.loco:FaceTowards(self.pos)
        self.loco:Approach(self.pos, 1)
    else
        local target = nil
        local bestPos = nil

        for _, v in pairs(ents.FindInSphere(self:GetPos(), self.radius)) do 	 	--looking for prey
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

function ENT:RunBehaviour()
    repeat
        self:NoNavBehaviour()

        coroutine.wait(0.1)
    until(false)
end

function ENT:Think()
    self:NoNavThink()
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
        for _, v in pairs(ents.FindInSphere(self:GetPos(), self.radius)) do
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
