AddCSLuaFile()

ENT.Type 	= "anim"
ENT.Author 	= "TankNut"

ENT.Model 	= Model("models/ut2004/projectiles/grenade.mdl")

ENT.Damage 	= 70
ENT.Radius 	= 150

ENT.ExplodeSound = Sound("ut2004/weaponsounds/BExplosion3.wav")

PrecacheParticleSystem("ut2004_flak_smoketrail")

function ENT:Initialize()
	self:SetModel(self.Model)

	if CLIENT then
		ParticleEffectAttach("ut2004_flak_smoketrail", PATTACH_ABSORIGIN_FOLLOW, self, 0)
	else
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)

		self:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)

		local phys = self:GetPhysicsObject()

		if IsValid(phys) then
			phys:SetMaterial("metal_bouncy")
			--phys:SetDamping(0.15, 0.75)
			phys:Wake()
		end
	end
end

if SERVER then
	function ENT:SetTimer(time)
		self.ExplodeTimer = CurTime() + time
	end

	function ENT:Explode()
		self.ExplodeTimer = nil

		local pos = self:GetPos()

		util.BlastDamage(self, self.Player, self:GetPos(), 150, 70)

		self:EmitSound(self.ExplodeSound, 100, 100)

		local effectdata = EffectData()

		effectdata:SetOrigin(self:GetPos())

		util.Effect("ut2004_exp", effectdata)
		util.Effect("ut99_explight", effectdata)

		ParticleEffect("ut2004_flak_explosion1", self:GetPos(), self:GetAngles())

		util.Decal("Scorch", pos + Vector(0, 0, 8), pos - Vector(0, 0, 40), self)

		SafeRemoveEntity(self)
	end

	function ENT:Think()
		self:NextThink(CurTime())

		if self.KillVelocity and not self.VelocityKilled then
			local phys = self:GetPhysicsObject()

			if IsValid(phys) then
				phys:SetMaterial("metal")
				phys:SetVelocity(vector_origin)
			end

			self.VelocityKilled = true
		end

		if self.ExplodeTimer and self.ExplodeTimer < CurTime() then
			self:Explode()
		end

		return true
	end

	function ENT:PhysicsCollide(data)
		if data.HitEntity:IsPlayer() or data.HitEntity:IsNPC() then
			self:Explode()

			return
		end

		if data.Speed > 196 then
			self:EmitSound("ut2004/weaponsounds/BGrenfloor1.wav")
		else
			self.KillVelocity = true
		end
	end
end