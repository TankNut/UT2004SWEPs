AddCSLuaFile()
DEFINE_BASECLASS("weapon_ut2004_newbase")

SWEP.Base 						= "weapon_ut2004_newbase"

SWEP.PrintName 					= "Shield Gun"
SWEP.Spawnable					= true
SWEP.Category 					= "Unreal Tournament 2004(New)"

if CLIENT then
	SWEP.WepSelectIcon			= surface.GetTextureID("vgui/ut2004/shieldgun")
end

SWEP.ViewModelFOV				= 60

SWEP.ViewModel					= Model("models/ut2004/weapons/v_shieldgun.mdl")
SWEP.WorldModel					= Model("models/ut2004/weapons/w_shieldgun.mdl")

SWEP.HoldType 					= "ar2"
SWEP.DeployDelay 				= 0.35
SWEP.HolsterDelay 				= 0.35

SWEP.DeploySound 				= Sound("ut2004/weaponsounds/shieldgun_change.wav")

SWEP.Primary.MinDamage 			= 40
SWEP.Primary.MaxDamage 			= 150
SWEP.Primary.MinSelfDamage 		= 0.8
SWEP.Primary.SelfDamageScale 	= 0.3
SWEP.Primary.Sound 				= Sound("ut2004/weaponsounds/BShieldGunFire.wav")
SWEP.Primary.ChargeSound 		= Sound("ut2004/weaponsounds/shieldgun_charge.wav")
SWEP.Primary.MinTime 			= 0.4
SWEP.Primary.MaxTime 			= 2.5
SWEP.Primary.Delay 				= 0.6
SWEP.Primary.Range 				= 112

SWEP.Secondary.Sound 			= Sound("ut2004/weaponsounds/bshield1.wav")
SWEP.Secondary.Delay 			= 1

PrecacheParticleSystem("ut2004_shieldgun_charge")

local function thirdperson(ent)
	local ply = LocalPlayer()

	return ply != ent:GetOwner() or (ply:GetViewEntity() != ply or ply:ShouldDrawLocalPlayer())
end

function SWEP:SetupDataTables()
	BaseClass.SetupDataTables(self)

	self:NetworkVar("Float", 2, "ChargeTime")
	self:NetworkVar("Float", 3, "ShieldTime")

	self:NetworkVar("Bool", 0, "FullyCharged")
	self:NetworkVar("Bool", 1, "DelayThink")
end

function SWEP:PrimaryAttack()
	self:SetWeaponAnim(ACT_VM_PULLBACK)
	self:EmitSound(self.Primary.ChargeSound, 80, 100, 0.5)

	self:SetChargeTime(CurTime())
	self:SetDelayThink(true)

	if game.SinglePlayer() then
		self:CallOnClient("ChargeEffect")
	else
		self:ChargeEffect()
	end

	self:SetNextPrimaryFire(math.huge)
	self:SetNextSecondaryFire(math.huge)
end

function SWEP:SecondaryAttack()
	self:SetWeaponAnim(ACT_VM_SECONDARYATTACK)
	self:EmitSound(self.Secondary.Sound, 80)

	self:SetShieldTime(CurTime())
	self:SetDelayThink(true)

	if IsFirstTimePredicted() then
		local ed = EffectData()

		ed:SetEntity(self)

		util.Effect("ut2004_shield_model", ed)
	end

	self:SetNextPrimaryFire(math.huge)
	self:SetNextSecondaryFire(math.huge)
end

function SWEP:KeyCheck(key)
	return not self:GetOwner():KeyDown(key) and not self:GetDelayThink()
end

function SWEP:Think()
	BaseClass.Think(self)

	local ply = self:GetOwner()

	local attacktime = self:GetChargeTime()

	if attacktime > 0 then
		local duration = CurTime() - attacktime

		if duration > self.Primary.MaxTime and not self:GetFullyCharged() then
			self:SetWeaponAnim(ACT_VM_PULLBACK_HIGH)
			self:SetFullyCharged(true)
		end

		if SERVER then
			ply:LagCompensation(true)
		end

		local tr = util.TraceLine({
			start = ply:GetShootPos(),
			endpos = ply:GetShootPos() + ply:GetAimVector() * self.Primary.Range,
			filter = ply,
			collisiongroup = COLLISION_GROUP_PLAYER
		})

		if SERVER then
			ply:LagCompensation(false)
		end

		local autofire = tr.Entity:IsNPC() or tr.Entity:IsPlayer()

		if duration > self.Primary.MinTime and (self:KeyCheck(IN_ATTACK) or autofire) then
			ply:SetAnimation(PLAYER_ATTACK1)

			self:SetNextIdle(CurTime() + self:SetWeaponAnim(ACT_VM_PRIMARYATTACK))
			self:EmitSound(self.Primary.Sound)

			self:Punch()

			self:SetChargeTime(0)
			self:SetFullyCharged(false)

			self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
			self:SetNextSecondaryFire(CurTime() + self.Primary.Delay)
		end
	end

	local shieldtime = self:GetShieldTime()

	if shieldtime > 0 and self:KeyCheck(IN_ATTACK2) then
		self:StopSound(self.Secondary.Sound)

		self:SetNextIdle(CurTime())
		self:SetShieldTime(0)

		self:SetNextPrimaryFire(CurTime())
		self:SetNextSecondaryFire(CurTime() + self.Secondary.Delay)
	end

	if IsFirstTimePredicted() then
		self:SetDelayThink(false)
	end
end

function SWEP:ChargeEffect()
	if SERVER then
		return
	end

	local vm = self:GetOwner():GetViewModel()

	self:StopParticles()
	vm:StopParticles()

	if thirdperson(self) then
		ParticleEffectAttach("ut2004_shieldgun_charge", PATTACH_POINT_FOLLOW, self, 1)
	else
		ParticleEffectAttach("ut2004_shieldgun_charge", PATTACH_POINT_FOLLOW, vm, 1)
	end
end

function SWEP:PunchEffect()
	if SERVER then
		return
	end

	local vm = self:GetOwner():GetViewModel()

	self:StopParticles()
	vm:StopParticles()

	if thirdperson(self) then
		ParticleEffectAttach("ut2004_shieldgun_muzzle", PATTACH_POINT_FOLLOW, self, 1)
	else
		ParticleEffectAttach("ut2004_shieldgun_muzzle", PATTACH_POINT_FOLLOW, vm, 1)
	end
end

function SWEP:Punch()
	if game.SinglePlayer() then
		self:CallOnClient("PunchEffect")
	else
		self:PunchEffect()
	end

	local ply = self:GetOwner()

	local time = math.Clamp(CurTime() - self:GetChargeTime(), self.Primary.MinTime, self.Primary.MaxTime)
	local damage = math.Remap(time, self.Primary.MinTime, self.Primary.MaxTime, self.Primary.MinDamage, self.Primary.MaxDamage)
	local force = math.Remap(time, self.Primary.MinTime, self.Primary.MaxTime, 32.5, 50)
	local bullet = {}

	bullet.Attacker = ply
	bullet.Num = 1
	bullet.Src = ply:GetShootPos()
	bullet.Dir = ply:GetAimVector()
	bullet.Spread = Vector(spread, spread, 0)
	bullet.Tracer = 0
	bullet.TracerName = ""
	bullet.Force = force
	bullet.Damage = damage
	bullet.HullSize = 0
	bullet.Distance = self.Primary.Range

	bullet.Callback = function(attacker, tr, dmg)
		dmg:SetDamageType(DMG_DIRECT)

		if SERVER and tr.HitWorld then
			dmg:SetDamageForce(-dmg:GetDamageForce())
			dmg:SetDamage(math.max(damage * self.Primary.SelfDamageScale, self.Primary.MinSelfDamage))

			ply:SetVelocity(dmg:GetDamageForce() * 0.01)
			ply:TakeDamageInfo(dmg)
		end
	end

	self:FireBullets(bullet)
end

function SWEP:DoImpactEffect()
	return true
end

local function shield(ply, dmg)
	local wep = ply:GetActiveWeapon()
	local active = IsValid(wep) and wep:GetClass() == "weapon_ut2004_shield_new" and wep:GetShieldTime() > 0

	if active then
		local dot = ply:GetAimVector():Dot((dmg:GetInflictor():WorldSpaceCenter() - ply:WorldSpaceCenter()):GetNormalized())

		if dot >= 0.63 then
			ply:EmitSound("ut2004/weaponsounds/ArmorHit.wav", 80, 100, 0.8)

			return true
		end
	end
end

hook.Add("EntityTakeDamage", "ut2004", function(ply, dmg)
	if ply:IsPlayer() and shield(ply, dmg) then
		return true
	end
end)

hook.Add("ScalePlayerDamage", "ut2004", function(ply, hitgroup, dmg)
	if shield(ply, dmg) then
		return true
	end
end)