AddCSLuaFile()

ENT.Type 		= "anim"
ENT.Author 		= "TankNut"

ENT.Model 		= Model("models/ut2004/projectiles/flakshell.mdl")

ENT.Radius 		= 220
ENT.Damage 		= 90

ENT.Count 		= 6

function ENT:Initialize()
	self:SetModel(self.Model)

	if CLIENT then
		ParticleEffectAttach("ut2004_flak_smoketrail", PATTACH_ABSORIGIN_FOLLOW, self, 0)

		local Pos = self:GetPos()
		local emitter = ParticleEmitter(Pos)

		self.Particle = emitter:Add("sprites/light_glow02_add", Pos)

		self.Particle:SetLifeTime(0)
		self.Particle:SetDieTime(10)

		self.Particle:SetStartAlpha(220)
		self.Particle:SetEndAlpha(0)

		self.Particle:SetStartSize(16)
		self.Particle:SetEndSize(14)

		self.Particle:SetAngles(Angle(0, 0, 0))
		self.Particle:SetAngleVelocity(Angle(0.1, 0, 0))

		self.Particle:SetRoll(math.Rand(0, 360))

		self.Particle:SetColor(255, 200, 0, 255)

		self.Particle:SetGravity(Vector(0,0,0))
		self.Particle:SetAirResistance(0)
		self.Particle:SetCollide(true)

		emitter:Finish()
	else
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)

		self:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)

		local phys = self:GetPhysicsObject()

		if IsValid(phys) then
			phys:SetBuoyancyRatio(0)
			phys:Wake()
		end
	end
end

if CLIENT then
	function ENT:Think()
		self.Particle:SetPos(self:GetPos())

		local vel = self:GetVelocity()

		if vel:Length() > 0 then
			self:SetAngles(self:GetVelocity():Angle())
		end
	end

	function ENT:OnRemove()
		self.Particle:SetDieTime(0)
	end
else
	function ENT:Think()
		self:NextThink(CurTime())

		if SERVER and self.Explode then
			for i = 1, self.Count do
				local ent = ents.Create("ut2004_flak_chunk")

				ent:SetPos(self:GetPos())
				ent:SetAngles(AngleRand())
				ent:SetOwner(self)
				ent:Spawn()
				ent:Activate()

				ent.Player = self.Player
				ent:SetExpireTimer(2.7)

				local phys = ent:GetPhysicsObject()

				if IsValid(phys) then
					phys:SetVelocity(VectorRand() * 2250)
				end
			end

			SafeRemoveEntity(self)
		end

		return true
	end

	function ENT:PhysicsCollide(data)
		local pos = self:GetPos()

		util.BlastDamage(self, self.Player, pos, self.Radius, self.Damage)

		self:EmitSound("ut2004/weaponsounds/BExplosion1.wav", 100, 100)

		ParticleEffect( "ut2004_flak_explosion", pos, self:GetAngles())

		local ed = EffectData()

		ed:SetOrigin(pos)

		util.Effect("ut99_explight", ed)

		self.Explode = true
	end
end