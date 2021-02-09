AddCSLuaFile()
DEFINE_BASECLASS("weapon_ut2004_newbase")

SWEP.Base 					= "weapon_ut2004_newbase"

SWEP.PrintName 				= "Shock Rifle"
SWEP.Spawnable				= true
SWEP.Category 				= "Unreal Tournament 2004(New)"

if CLIENT then
	SWEP.WepSelectIcon		= surface.GetTextureID("vgui/ut2004/shockrifle")
end

SWEP.ViewModelFOV			= 60

SWEP.ViewModel				= Model("models/ut2004/weapons/v_shock.mdl")
SWEP.WorldModel				= Model("models/ut2004/weapons/w_shock.mdl")

SWEP.HoldType 				= "ar2"
SWEP.DeployDelay 			= 0.35
SWEP.HolsterDelay 			= 0.35

SWEP.DeploySound 			= Sound("ut2004/weaponsounds/switchtoshockrifle.wav")

SWEP.Primary.Damage 		= 60
SWEP.Primary.Delay 			= 0.7
SWEP.Primary.Sound 			= Sound("ut2004/weaponsounds/BShockRifleFire.wav")

SWEP.Secondary.Force 		= 1035
SWEP.Secondary.Delay 		= 0.48
SWEP.Secondary.Sound 		= Sound("ut2004/weaponsounds/BShockRifleAltFire.wav")

function SWEP:PrimaryAttack()
	local ply = self:GetOwner()

	ply:SetAnimation(PLAYER_ATTACK1)

	self:SetNextIdle(CurTime() + self:SetWeaponAnim(ACT_VM_PRIMARYATTACK))
	self:EmitSound(self.Primary.Sound, 75, 100, 0.4)

	local bullet = {}

	bullet.Attacker = ply
	bullet.Num = 1
	bullet.Src = ply:GetShootPos()
	bullet.Dir = ply:GetAimVector()
	bullet.Spread = Vector()
	bullet.Tracer = 0
	bullet.Force = 20
	bullet.HullSize = 1
	bullet.Damage = self.Primary.Damage

	bullet.Callback = function(attacker, tr, dmg)
		dmg:SetDamageType(DMG_PLASMA)

		local ed = EffectData()

		ed:SetStart(tr.StartPos)
		ed:SetNormal(tr.HitNormal)
		ed:SetAttachment(1)
		ed:SetOrigin(tr.HitPos)
		ed:SetEntity(self)

		util.Effect("ut2004_shock_beam", ed)
		util.Effect("ut2004_mflash_shock", ed)

		if tr.HitWorld then
			ed = EffectData()

			ed:SetOrigin(tr.HitPos + tr.HitNormal)
			ed:SetAngles(tr.HitNormal:Angle())

			util.Effect("ut2004_shock_ring", ed)
			util.Effect("ut2004_shock_hitglow", ed)
		end
	end

	self:FireBullets(bullet)

	self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
	self:SetNextSecondaryFire(CurTime() + self.Primary.Delay)
end

function SWEP:SecondaryAttack()
	local ply = self:GetOwner()

	ply:SetAnimation(PLAYER_ATTACK1)

	self:SetNextIdle(CurTime() + self:SetWeaponAnim(ACT_VM_SECONDARYATTACK))
	self:EmitSound(self.Secondary.Sound, 100, 100, 0.4)

	if SERVER then
		local ent = ents.Create("ut2004_shockcore_new")

		ent:SetPos(ply:GetShootPos())
		ent:SetAngles(ply:EyeAngles())
		ent:SetOwner(ply)
		ent:Spawn()
		ent:Activate()

		ent.Player = ply
		ent:SetExpireTimer(10)

		local phys = ent:GetPhysicsObject()

		if IsValid(phys) then
			phys:SetVelocity(ply:GetAimVector() * self.Secondary.Force)
		end
	end

	self:SetNextPrimaryFire(CurTime() + self.Secondary.Delay)
	self:SetNextSecondaryFire(CurTime() + self.Secondary.Delay)
end

function SWEP:DoImpactEffect(tr, dmg)
	return true
end