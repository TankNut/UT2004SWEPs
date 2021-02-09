AddCSLuaFile()
DEFINE_BASECLASS("weapon_ut2004_newbase")

SWEP.Base 					= "weapon_ut2004_newbase"

SWEP.PrintName 				= "Assault Rifle"
SWEP.Spawnable				= true
SWEP.Category 				= "Unreal Tournament 2004(New)"

if CLIENT then
	SWEP.WepSelectIcon		= surface.GetTextureID("vgui/ut2004/assault")
end

SWEP.ViewModelFOV			= 70

SWEP.ViewModel				= Model("models/ut2004/weapons/v_assault.mdl")
SWEP.WorldModel				= Model("models/ut2004/weapons/w_assault.mdl")
SWEP.DualWorldModel 		= Model("models/ut2004/weapons/w_assault_dual.mdl")

SWEP.HoldType 				= "ar2"
SWEP.DeployDelay 			= 0.35
SWEP.HolsterDelay 			= 0.35

SWEP.DeploySound 			= Sound("ut2004/weaponsounds/switchtoassaultrifle.wav")

SWEP.Primary.Damage 		= 7
SWEP.Primary.Spread 		= 10
SWEP.Primary.Delay 			= 0.14
SWEP.Primary.DualDelay 		= 0.07
SWEP.Primary.Sound 			= Sound("UT2004_AR.Fire")

SWEP.Secondary.Automatic 	= false
SWEP.Secondary.MinForce 	= 700
SWEP.Secondary.MaxForce 	= 1600
SWEP.Secondary.MinTime 		= 0.2
SWEP.Secondary.ChargeTime 	= 1
SWEP.Secondary.Delay 		= 0.5
SWEP.Secondary.Sound 		= Sound("ut2004/newweaponsounds/NewGrenadeShoot.wav")

function SWEP:SetupDataTables()
	BaseClass.SetupDataTables(self)

	self:NetworkVar("Bool", 0, "HasSecondWeapon")
	self:NetworkVar("Bool", 1, "AltWeapon")

	self:NetworkVar("Float", 2, "GrenadeTime")
end

function SWEP:Deploy()
	if self:GetHasSecondWeapon() then
		self:CreateSecondVM()
	end

	return BaseClass.Deploy(self)
end

function SWEP:Holster(weapon)
	local can = BaseClass.Holster(self, weapon)

	if can then
		local vm = self:GetOwner():GetViewModel(1)

		vm:SetWeaponModel(self.ViewModel, nil)
	end

	return can
end

function SWEP:SetHolsterAnimation()
	BaseClass.SetHolsterAnimation(self)

	self:SetWeaponAnim(ACT_VM_HOLSTER, 1)
end

function SWEP:Idle()
	BaseClass.Idle(self)

	self:SetWeaponAnim(ACT_VM_IDLE, 1)
end

function SWEP:PrimaryAttack()
	local ply = self:GetOwner()

	ply:SetAnimation(PLAYER_ATTACK1)

	self:SetNextIdle(CurTime() + self:SetWeaponAnim(ACT_VM_PRIMARYATTACK, self:GetAltWeapon() and 1 or 0))
	self:EmitSound(self.Primary.Sound)

	local spread = math.rad(self.Primary.Spread * 0.5)

	local bullet = {}

	bullet.Attacker = ply
	bullet.Num = 1
	bullet.Src = ply:GetShootPos()
	bullet.Dir = ply:GetAimVector()
	bullet.Spread = Vector(spread, spread, 0)
	bullet.Tracer = 0
	bullet.TracerName = ""
	bullet.Force = 10
	bullet.Damage = self.Primary.Damage

	self:FireBullets(bullet)

	local delay = self.Primary.Delay

	if self:GetHasSecondWeapon() then
		delay = self.Primary.DualDelay

		self:SetAltWeapon(not self:GetAltWeapon())
	end

	self:SetNextPrimaryFire(CurTime() + delay)
end

function SWEP:SecondaryAttack()
	self:SetGrenadeTime(CurTime())

	self:SetNextPrimaryFire(math.huge)
	self:SetNextSecondaryFire(math.huge)
end

function SWEP:Think()
	BaseClass.Think(self)

	local ply = self:GetOwner()
	local time = self:GetGrenadeTime()
	local duration = CurTime() - time

	if time > 0 and duration > self.Secondary.MinTime and not ply:KeyDown(IN_ATTACK2) then
		local force = math.Clamp(math.Remap(duration, 0, self.Secondary.ChargeTime, self.Secondary.MinForce, self.Secondary.MaxForce), self.Secondary.MinForce, self.Secondary.MaxForce)

		if SERVER then
			local ent = ents.Create("ut2004_assrifle_grenade")

			ent:SetPos(ply:GetShootPos())
			ent:SetAngles(AngleRand())
			ent:SetOwner(ply)
			ent:Spawn()
			ent:Activate()

			ent.Player = ply
			ent:SetTimer(3)

			local phys = ent:GetPhysicsObject()

			if IsValid(phys) then
				phys:SetVelocity(ply:GetAimVector() * force + Vector(0, 0, 128))
				phys:AddAngleVelocity(Vector(300, math.random(-600, 600), 0))
			end
		end

		ply:SetAnimation(PLAYER_ATTACK1)

		self:SetNextIdle(CurTime() + self:SetWeaponAnim(ACT_VM_SECONDARYATTACK, self:GetAltWeapon() and 1 or 0))
		self:EmitSound(self.Secondary.Sound)

		if self:GetHasSecondWeapon() then
			self:SetAltWeapon(not self:GetAltWeapon())
		end

		self:SetGrenadeTime(0)

		self:SetNextPrimaryFire(CurTime() + self.Secondary.Delay)
		self:SetNextSecondaryFire(CurTime() + self.Secondary.Delay)
	end
end

function SWEP:GiveSecondWeapon()
	self:CallOnClient("GiveSecondWeapon")

	self:EmitSound(self.DeploySound)

	self:SetHoldType("duel")
	self:SetModel(self.DualWorldModel)

	self.WorldModel = self.DualWorldModel

	if self:GetOwner():GetActiveWeapon() == self then
		self:CreateSecondVM()
		self:SetDeployAnimation()
	end

	self:SetHasSecondWeapon(true)
end

function SWEP:CreateSecondVM()
	local vm = self:GetOwner():GetViewModel(1)

	vm:SetWeaponModel(self.ViewModel, self)

	self:SetWeaponAnim(ACT_VM_DRAW, 1)
end

function SWEP:OnReloaded()
	if self:GetHasSecondWeapon() then
		self:SetModel(self.DualWorldModel)

		self.WorldModel = self.DualWorldModel
	end
end

if SERVER then
	hook.Add("PlayerCanPickupWeapon", "ut2004", function(ply, weapon)
		if weapon:GetClass() == "weapon_ut2004_assrifle_new" and ply:HasWeapon("weapon_ut2004_assrifle_new") then
			local existing = ply:GetWeapon("weapon_ut2004_assrifle_new")

			if not existing:GetHasSecondWeapon() then
				weapon:Remove()
				existing:GiveSecondWeapon()

				return false
			end
		end
	end)
end