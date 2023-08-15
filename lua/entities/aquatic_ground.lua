AddCSLuaFile()

ENT.Base = "base_nextbot"
ENT.Spawnable = true

ENT.model = "models/aquatic_animals/sea_turtle_ground.mdl"
ENT.health = 100
ENT.speed = 25
ENT.damage = 10
ENT.aggressive = false

ENT.radius = 500

ENT.ignore = {aquatic_ground = true}
ENT.predator = {}

if CLIENT then return end

function ENT:Initialize()
    self:SetModel(self.model)
    self:SetHealth(self.health)
    self:SetPos(self:GetPos() + Vector(0,0,200))
    self:StartActivity(ACT_IDLE)

    self.fear = false
    self.target = nil
    self.turnCount = 0
    self.attack = false
    self.pos = self:GetPos() + Vector(math.Rand(-1, 1), math.Rand(-1, 1), 0) * (self.radius * 10)
    self.fearPlayers = false
    -- self.lastSound = ""
end

function ENT:RunBehaviour()
    repeat
        if !self.fear then
            if self.target == nil then
                self.loco:SetDesiredSpeed(self.speed)
                self.loco:SetStepHeight(50)  --not colliding eachother
                if math.random(1, 100) == 2 then     --1% chance of having a random angle
                    self.pos = self:GetPos() + Vector(math.Rand(-1, 1), math.Rand(-1, 1), 0) * (self.radius * 10)
                end

                local target = nil
                local bestPos = nil

                    for _, v in pairs(ents.FindInSphere(self:GetPos(), self.radius)) do 	 	--looking for prey
                        local class = v:GetClass()

                    if !self.ignore[class] and v != self and (v:IsNextBot() or ((self.aggressive or self.fearPlayers) and (!v:IsPlayer() or GetConVarNumber("ai_ignoreplayers") == 0))) and v:Health() > 0 then
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

                        self:StartActivity(ACT_IDLE)
                        self.attack = false
                    end
                else
                    self.pos = self:GetPos() + Vector(math.Rand(-1, 1), math.Rand(-1, 1), 0) * (self.radius * 10)
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
                            self.pos = Angle(0, self:GetAngles().y + 180, 0):Forward() * self.radius * 10
                            self.turnCount = 0
                            break
                        end          
                    end
                    self.target = target
                    if self.turnCount >= 10 and math.random(1, 50) == 2 then
                        self.pos = Angle(0, self:GetAngles().y + math.random(-45, 45), 0):Forward() * self.radius * 10
                        self.turnCount = 0
                    end
                end
            end
        end

        if self.turnCount < 20 then     --avoid to turn every 0.1s when fearing multiple predators
            self.turnCount = self.turnCount + 1
        end

        coroutine.wait(0.1)
    until(false)
end

function ENT:Think()
    self.loco:FaceTowards(self.pos)
    self.loco:Approach(self.pos, 1)
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
                break
            end
        end
    end
end
