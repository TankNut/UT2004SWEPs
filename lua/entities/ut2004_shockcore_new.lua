AddCSLuaFile()

ENT.Type 			= "anim"
ENT.Author 			= "TankNut"

ENT.Model 			= Model("models/XQM/Rails/gumball_1.mdl")

ENT.Damage 			= 45
ENT.Radius 			= 135

ENT.ComboDamage 	= 200
ENT.ComboRadius 	= 247.5

ENT.ExplodeSound 	= Sound("ut2004/weaponsounds/ShockRifleExplosion.wav")
ENT.ComboSound 		= Sound("ut2004/weaponsounds/ShockComboFire.wav")

PrecacheParticleSystem("ut2004_shockcore")

function ENT:Initialize()
	self:SetModel(self.Model)
	self:DrawShadow(false)

	if CLIENT then
		ParticleEffectAttach("ut2004_shockcore", PATTACH_ABSORIGIN_FOLLOW, self, 0)
	else
		self:PhysicsInitSphere(10, "metal")
		self:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)

		local phys = self:GetPhysicsObject()

		if IsValid(phys) then
			phys:SetMass(2)
			phys:EnableDrag(false)
			phys:EnableGravity(false)
			phys:SetBuoyancyRatio(0)
			phys:Wake()
		end
	end
end

if CLIENT then
	function ENT:Draw()
	end
else
	function ENT:SetExpireTimer(time)
		self.ExpireTimer = CurTime() + time
	end

	function ENT:Explode()
		util.BlastDamage(self, self:GetOwner(), self:GetPos(), self.Radius, self.Damage)

		self:EmitSound(self.ExplodeSound, 75, 100)

		SafeRemoveEntity(self)
	end

	function ENT:ComboExplode(inflictor)
		util.BlastDamage(self, inflictor, self:GetPos(), self.ComboRadius, self.ComboDamage)

		self:EmitSound(self.ComboSound, 120)

		local ed = EffectData()

		ed:SetOrigin(self:GetPos())
		ed:SetAngles(self:GetAngles())

		util.Effect("ut2004_shock_combo", ed)

		SafeRemoveEntity(self)
	end

	function ENT:Think()
		self:NextThink(CurTime())

		if self.ExpireTimer and self.ExpireTimer < CurTime() then
			SafeRemoveEntity(self)
		end

		return true
	end

	function ENT:PhysicsCollide()
		self:Explode()
	end

	function ENT:OnTakeDamage(dmg)
		if dmg:GetInflictor():GetClass() == "weapon_ut2004_shock_new" then
			self:ComboExplode(dmg:GetAttacker())
		end
	end
end