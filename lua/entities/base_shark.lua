AddCSLuaFile()

ENT.Base 			= "base_nextbot"

ENT.model = ""
ENT.health = 100
ENT.speed = 100
ENT.damage = 20

ENT.radius = 1000
ENT.upStep = 20
ENT.minDepth = 104
ENT.maxDepth = 110

ENT.ignore = {}
ENT.predator = {}

if CLIENT then 
    return 
end

-- TODO
-- target the closest prey (in the search loop calculate pos of every ent with vector "distance"!!!)
-- predator system
-- bull shark

function ENT:Initialize()
    self:SetModel(self.model)
    self:SetHealth(self.health)
    self:SetPos(self:GetPos() + Vector(0,0,200))
    self:StartActivity(ACT_IDLE)

    self.target = nil
    self.depth = self.maxDepth
    self.turnCount = 20
    self.attack = false
    self.lastPos = Vector(0, 0, 0)
end

function ENT:RunBehaviour()
    repeat
        if self.target == nil then
            if self.turnCount == 20 and math.random(1, 100) == 2 then     --1% chance of having a random angle
                self:SetAngles(Angle(0, math.random(0, 360), 0))
            end
            
            if self.depth == self.minDepth and self:WaterLevel() > 0 and math.random(1, 2000) == 2 then     --0,05% chance of changing depth
                self.depth = self.maxDepth
            end
            
            if self.turnCount >= 10 then
                local nearby = ents.FindInSphere(self:GetPos(), self.radius)

                for k,v in pairs(nearby) do 	 	--looking for prey
                    local class = v:GetClass() 

                    if (!self.ignore[class] and v != self and (v:IsNextBot() or (!v:IsPlayer() or GetConVarNumber("ai_ignoreplayers") == 0) or v:IsNPC())) and v:Health() > 0 and v:WaterLevel() > 0 and self:WaterLevel() > 0 then
                        self.target = v
                        break
                    end 
                end
            end

        else
            local nearby = ents.FindInSphere(self:GetPos(), self.radius)
            local target = false 	

            for k,v in pairs(nearby) do 	 --check if the prey still here	    
                if v == self.target and IsValid(v) and (v:IsNextBot() or v:IsPlayer() or v:IsNPC()) and v:Health() > 0 and v:WaterLevel() > 0 and self:WaterLevel() > 0 then
                    target = true
                    break
                end 
            end

            if target then
                self:PointAtEntity(self.target)

                if self.attack then     --damage the prey
                    self:PlaySequenceAndWait("attack")

                    if IsValid(self.target) and self.target:WaterLevel() > 0 then
                        self.target:TakeDamage(self.damage, self)
            
                        if self.target:IsPlayer() then
                            self.target:ViewPunch(Angle(math.random(-1,1)*25,math.random(-1,1)*25,math.random(-1,1)*25))
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

        if self.turnCount < 20 then
            self.turnCount = self.turnCount + 1
        else
            local pos = self:GetPos()

            if pos == self.lastPos then
                self:SetPos(pos + Vector(0,0,self.upStep))
            else
                self.lastPos = pos
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
    else
        self.loco:SetVelocity(self:GetForward() * (self.speed * 0.5) + self:GetUp() * 100)
        self.depth = self.minDepth
    end
end

function ENT:OnLandOnGround(ent)    --avoid to be stuck in the ground
    self:SetPos(self:GetPos() + Vector(0,0,self.upStep))
    if self.target == nil and math.random(1, 4) == 2 then
        self:SetAngles(Angle(0, self:GetAngles().y + 180, 0))
    end
    
    self.depth = self.maxDepth
end

function ENT:OnContact(ent)
    if ent == self.target and !self.attack then     --restart the coroutine in order to play the attack sequence
        self.attack = true
        self:BehaveStart()
        self.loco:SetVelocity(-self:GetForward() * self.speed * 5)
    end

    if self.turnCount == 20 and (self.target == nil or (math.random(1, 4) == 2 and ent:IsWorld())) and !self.loco:IsOnGround() then     --avoid to be stuck in the walls
        self.turnCount = 0
        self.target = nil
        self.loco:SetVelocity(-self:GetForward() * self.speed * 5)
        self:SetAngles(Angle(0, self:GetAngles().y + math.random(135, 225), 0))
    end
end

function ENT:OnInjured(dmg)
    local attacker = dmg:GetAttacker()
    if self.target == nil and !self.predator[attacker:GetClass()] and (!attacker:IsPlayer() or GetConVarNumber("ai_ignoreplayers") == 0) then
        if attacker:WaterLevel() == 0 then
            self.depth = self.minDepth
        else
            self.target = attacker
        end
    end
end
