AddCSLuaFile()
DEFINE_BASECLASS("weapon_ut2004_newbase")

SWEP.Base 					= "weapon_ut2004_newbase"

SWEP.PrintName 				= "Minigun"
SWEP.Spawnable				= true
SWEP.Category 				= "Unreal Tournament 2004(New)"

if CLIENT then
	SWEP.WepSelectIcon		= surface.GetTextureID("vgui/ut2004/minigun")
end

SWEP.ViewModelFOV			= 70

SWEP.ViewModel				= Model("models/ut2004/weapons/v_minigun.mdl")
SWEP.WorldModel				= Model("models/ut2004/weapons/w_minigun.mdl")

SWEP.HoldType 				= "shotgun"
SWEP.DeployDelay 			= 0.35
SWEP.HolsterDelay 			= 0.35

SWEP.DeploySound 			= Sound("ut2004/weaponsounds/switchtominigun.wav")
SWEP.EmptySound 			= Sound("ut2004/weaponsounds/miniempty.wav")

SWEP.WindUp 				= 0.35

SWEP.Primary.Automatic 		= false
SWEP.Primary.Damage 		= 7
SWEP.Primary.Spread 		= 8.6
SWEP.Primary.Delay 			= 0.05
SWEP.Primary.Sound 			= Sound("ut2004/newweaponsounds/NewMinigunFire.wav")
SWEP.Primary.Anim 			= ACT_VM_PULLBACK

SWEP.Secondary.Automatic 	= false
SWEP.Secondary.Damage 		= 15
SWEP.Secondary.Spread 		= 2.3
SWEP.Secondary.Delay 		= 0.15
SWEP.Secondary.Sound 		= Sound("ut2004/weaponsounds/minialtfireb.wav")
SWEP.Secondary.Anim 		= ACT_VM_PULLBACK_HIGH

function SWEP:SetupDataTables()
	BaseClass.SetupDataTables(self)

	self:NetworkVar("Float", 2, "FireTime")

	self:NetworkVar("Bool", 0, "Firing")
	self:NetworkVar("Bool", 1, "FirstShot")
	self:NetworkVar("Bool", 2, "AltMode")
end

function SWEP:PrimaryAttack()
	self:SetWeaponAnim(ACT_VM_PRIMARYATTACK)

	self:EmitSound(self.EmptySound)

	self:SetFireTime(CurTime())
	self:SetFiring(true)
	self:SetFirstShot(true)
	self:SetAltMode(false)

	self:SetNextPrimaryFire(CurTime() + self.WindUp)
end

function SWEP:SecondaryAttack()
	self:SetWeaponAnim(ACT_VM_PRIMARYATTACK)

	self:EmitSound(self.EmptySound)

	self:SetFireTime(CurTime())
	self:SetFiring(true)
	self:SetFirstShot(true)
	self:SetAltMode(true)

	self:SetNextPrimaryFire(CurTime() + self.WindUp)
end

function SWEP:FireBullet(tab)
	local ply = self:GetOwner()

	ply:SetAnimation(PLAYER_ATTACK1)

	local spread = math.rad(tab.Spread * 0.5)

	local bullet = {}

	bullet.Attacker = ply
	bullet.Num = 1
	bullet.Src = ply:GetShootPos()
	bullet.Dir = ply:GetAimVector()
	bullet.Spread = Vector(spread, spread, 0)
	bullet.Tracer = 0
	bullet.Force = 10
	bullet.Damage = tab.Damage

	if CLIENT then
		ply:GetViewModel():GetAttachment(0)
	end

	self:FireBullets(bullet)

	self:SetNextPrimaryFire(CurTime() + tab.Delay)
end

function SWEP:Think()
	BaseClass.Think(self)

	local ply = self:GetOwner()

	if CLIENT then
		self:UpdateBones()
	end

	if self:GetFiring() then
		local key = self:GetAltMode() and IN_ATTACK2 or IN_ATTACK

		if ply:KeyReleased(key) then
			self:SetFireTime(CurTime())
			self:SetFiring(false)

			self:SetWeaponAnim(ACT_VM_PULLBACK_LOW)

			self:EmitSound(self.EmptySound)

			self:SetNextIdle(CurTime() + self.WindUp)

			self:SetNextPrimaryFire(CurTime())
			self:SetNextSecondaryFire(CurTime())

			return
		end

		if self:GetNextPrimaryFire() <= CurTime() then
			local alt = self:GetAltMode()
			local tab = alt and self.Secondary or self.Primary

			self:FireBullet(tab)

			if self:GetFirstShot() then
				self:SetNextIdle(0)

				self:SetFirstShot(false)
				self:SetWeaponAnim(tab.Anim)
				self:EmitSound(tab.Sound)
			end
		end
	end
end

if CLIENT then
	function SWEP:ResetBones()
		local vm = self:GetOwner():GetViewModel()

		vm:ManipulateBoneAngles(1, angle_zero)
		vm:ManipulateBoneAngles(2, angle_zero)
	end

	function SWEP:Holster(weapon)
		BaseClass.Holster(self, weapon)

		self:ResetBones()
	end

	function SWEP:OnRemove()
		self:ResetBones()
	end

	function SWEP:UpdateBones()
		local vm = self:GetOwner():GetViewModel()

		local time = CurTime() - self:GetFireTime()
		local rate = math.Clamp(math.Remap(time, 0, self.WindUp, 0, 1), 0, 1)

		if not self:GetFiring() then
			rate = 1 - rate
		end

		local mul = (self:GetAltMode() and 5 or 7) * FrameTime() * 90

		vm:ManipulateBoneAngles(1, vm:GetManipulateBoneAngles(1) + Angle(0, 0, rate * mul))
		vm:ManipulateBoneAngles(2, vm:GetManipulateBoneAngles(2) + Angle(0, 0, -rate * mul))

		vm:SetupBones()
	end
end