AddCSLuaFile()

ENT.Type 		= "anim"
ENT.Author 		= "TankNut"

ENT.Model 		= Model("models/ut2004/projectiles/flakchunk.mdl")

ENT.MaxDamage 	= 13
ENT.MinDamage 	= 5

function ENT:Initialize()
	self:SetModel(self.Model)

	if CLIENT then
		local Pos = self:GetPos()
		local emitter = ParticleEmitter(Pos)

		self.Particle = emitter:Add("sprites/light_glow02_add", Pos)

		self.Particle:SetLifeTime(0)
		self.Particle:SetDieTime(10)

		self.Particle:SetStartAlpha(220)
		self.Particle:SetEndAlpha(0)

		self.Particle:SetStartSize(16)
		self.Particle:SetEndSize(8)

		self.Particle:SetAngles(Angle(0, 0, 0))
		self.Particle:SetAngleVelocity(Angle(0.1, 0, 0))

		self.Particle:SetRoll(math.Rand(0, 360))

		self.Particle:SetColor(255, 200, 0, 255)

		self.Particle:SetGravity(Vector(0,0,0))
		self.Particle:SetAirResistance(0)
		self.Particle:SetCollide(true)

		emitter:Finish()
	else
		local rand = math.random()

		if rand > 0.75 then
			self.Bounces = 3
		elseif rand > 0.25 then
			self.Bounces = 2
		else
			self.Bounces = 1
		end

		self.Trail = util.SpriteTrail(self, 0, Color(255, 200, 0), false, 15, 13, 0.15, 0.125, "trails/laser.vmt")

		self:PhysicsInitSphere(2, "metal_bouncy")
		self:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)

		local phys = self:GetPhysicsObject()

		if IsValid(phys) then
			phys:SetMass(1)
			phys:EnableDrag(false)
			phys:EnableGravity(false)
			phys:SetBuoyancyRatio(0)
			phys:Wake()
		end
	end
end

if CLIENT then
	function ENT:Think()
		self.Particle:SetPos(self:GetPos())
	end

	function ENT:OnRemove()
		self.Particle:SetDieTime(0)
	end
else
	function ENT:SetExpireTimer(time)
		self.LifeSpan = time
		self.ExpireTimer = CurTime() + time
	end

	function ENT:Think()
		self:NextThink(CurTime())

		if self.ExpireTimer and self.ExpireTimer < CurTime() then
			SafeRemoveEntity(self)
		end

		local phys = self:GetPhysicsObject()

		if IsValid(phys) and self.AddGravity and not phys:IsGravityEnabled() then
			phys:EnableGravity(true)
		end

		if self.NoOwner and IsValid(self:GetOwner()) then
			self:SetOwner()
		end

		return true
	end

	function ENT:PhysicsCollide(data)
		self.NoOwner = true
		self.AddGravity = true

		if not data.HitEntity:IsWorld() then
			local damage = math.Max(self.MinDamage, self.MaxDamage - self.MinDamage * math.max(0, self.LifeSpan - (self.ExpireTimer - CurTime()) - 1))

			local bullet = {}

			bullet.Attacker = self.Player
			bullet.Num = 1
			bullet.Src = data.HitPos
			bullet.Dir = data.HitPos - self:GetPos()
			bullet.Spread = Vector()
			bullet.Tracer = 0
			bullet.Force = 20
			bullet.HullSize = 1
			bullet.Damage = damage
			bullet.IgnoreEntity = self
			bullet.Callback = function(attacker, tr, dmg)
				dmg:SetDamageType(DMG_BUCKSHOT)
			end

			self:FireBullets(bullet)

			SafeRemoveEntity(self)

			return
		end

		if self.Bounces > 0 then
			local phys = data.PhysObject
			local vel = 0.65 * (data.OurOldVelocity - 2 * data.HitNormal * (data.OurOldVelocity:Dot(data.HitNormal)))

			phys:SetVelocity(vel)

			self.Bounces = self.Bounces - 1
		else
			SafeRemoveEntity(self)
		end
	end
end