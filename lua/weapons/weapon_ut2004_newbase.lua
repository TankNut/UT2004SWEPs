AddCSLuaFile()

SWEP.Author 					= "TankNut"

SWEP.Category 					= "Unreal Tournament 2004(New)"

SWEP.AutoSwitchTo				= false
SWEP.AutoSwitchFrom				= false

SWEP.SwayScale 					= 0.1
SWEP.BobScale 					= 0

SWEP.ViewModelFlip1 			= true

SWEP.HoldType 					= "normal"
SWEP.DeployDelay 				= 0
SWEP.HolsterDelay 				= 0

SWEP.Primary.ClipSize			= -1
SWEP.Primary.DefaultClip		= -1
SWEP.Primary.Automatic			= true
SWEP.Primary.Ammo				= "none"

SWEP.Secondary.ClipSize			= -1
SWEP.Secondary.DefaultClip		= -1
SWEP.Secondary.Automatic		= true
SWEP.Secondary.Ammo				= "none"

function SWEP:Initialize()
	self:SetDeploySpeed(1)
	self:SetHoldType(self.HoldType)
end

function SWEP:SetupDataTables()
	self:NetworkVar("Float", 0, "NextIdle")
	self:NetworkVar("Float", 1, "NextHolster")

	self:NetworkVar("Entity", 0, "HolsterTarget")
end

function SWEP:Deploy()
	if self.DeploySound then
		self:EmitSound(self.DeploySound)
	end

	self:SetDeployAnimation()

	return true
end

function SWEP:SetDeployAnimation()
	self:SetWeaponAnim(ACT_VM_DRAW)

	local delay = CurTime() + self.DeployDelay

	self:SetNextPrimaryFire(delay)
	self:SetNextSecondaryFire(delay)

	self:SetNextIdle(delay)
end

function SWEP:Holster(weapon)
	if weapon == self then
		return true
	end

	local holster = self:GetNextHolster()

	if holster > 0 then
		if holster > CurTime() then
			self:SetHolsterTarget(weapon)

			return false
		end

		if SERVER then
			self:SetNextHolster(0)
			self:SetHolsterTarget(NULL)
		end

		return true
	end

	self:SetHolsterAnimation()

	self:SetHolsterTarget(weapon)
	self:SetNextHolster(CurTime() + self.HolsterDelay)

	return false
end

function SWEP:SetHolsterAnimation()
	self:SetWeaponAnim(ACT_VM_HOLSTER)
	self:SetNextIdle(0)

	local delay = CurTime() + self.HolsterDelay

	self:SetNextPrimaryFire(delay)
	self:SetNextSecondaryFire(delay)
end

function SWEP:Think()
	local idle = self:GetNextIdle()

	if idle > 0 and idle <= CurTime() then
		self:SetNextIdle(0)
		self:Idle()
	end
end

function SWEP:Idle()
	self:SetWeaponAnim(ACT_VM_IDLE)
end

function SWEP:SetWeaponAnim(act, index)
	index = index or 0

	local vm = self:GetOwner():GetViewModel(index)

	vm:SendViewModelMatchingSequence(vm:SelectWeightedSequence(act))

	return vm:SequenceDuration()
end

if CLIENT then
	hook.Add("Think", "ut2004", function()
		local weapon = LocalPlayer():GetActiveWeapon()

		if IsValid(weapon) and weapon.Base == "weapon_ut2004_newbase" then
			local holster = weapon:GetNextHolster()

			if holster > 0 and holster <= CurTime() then
				input.SelectWeapon(weapon:GetHolsterTarget())
			end
		end
	end)
end