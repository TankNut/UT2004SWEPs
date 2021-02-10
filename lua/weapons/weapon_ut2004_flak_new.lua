AddCSLuaFile()
DEFINE_BASECLASS("weapon_ut2004_newbase")

SWEP.Base 					= "weapon_ut2004_newbase"

SWEP.PrintName 				= "Flak Cannon"
SWEP.Spawnable				= true
SWEP.Category 				= "Unreal Tournament 2004(New)"

if CLIENT then
	SWEP.WepSelectIcon		= surface.GetTextureID("vgui/ut2004/flak")
end

SWEP.ViewModelFOV			= 50

SWEP.ViewModel				= Model("models/ut2004/weapons/v_flak.mdl")
SWEP.WorldModel				= Model("models/ut2004/weapons/w_flak.mdl")

SWEP.HoldType 				= "crossbow"
SWEP.DeployDelay 			= 0.35
SWEP.HolsterDelay 			= 0.35

SWEP.DeploySound 			= Sound("ut2004/weaponsounds/SwitchToFlakCannon.wav")

SWEP.Primary.Automatic 		= false
SWEP.Primary.Count 			= 9
SWEP.Primary.Spread 		= 7
SWEP.Primary.Delay 			= 0.8
SWEP.Primary.Sound 			= Sound("ut2004/weaponsounds/BFlakCannonFire.wav")

SWEP.Secondary.Delay 		= 1
SWEP.Secondary.Sound 		= Sound("ut2004/weaponsounds/BFlakCannonAltFire.wav")

function SWEP:PrimaryAttack()
	local ply = self:GetOwner()

	ply:SetAnimation(PLAYER_ATTACK1)

	self:SetNextIdle(CurTime() + self:SetWeaponAnim(ACT_VM_PRIMARYATTACK))
	self:EmitSound(self.Primary.Sound, 75, 100, 0.4)

	local spread = self.Primary.Spread * 0.5

	if SERVER then
		for i = 1, self.Primary.Count do
			local _, ang = LocalToWorld(vector_origin, Angle(math.Rand(-spread, spread), math.Rand(-spread, spread), 0), vector_origin, ply:GetAimVector():Angle())
			local ent = ents.Create("ut2004_flak_chunk")

			ent:SetPos(ply:GetShootPos())
			ent:SetAngles(AngleRand())
			ent:SetOwner(ply)
			ent:Spawn()
			ent:Activate()

			ent.Player = ply
			ent:SetExpireTimer(2.7)

			local phys = ent:GetPhysicsObject()

			if IsValid(phys) then
				phys:SetVelocity(ang:Forward() * 2250)
			end
		end
	end

	self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
	self:SetNextSecondaryFire(CurTime() + self.Primary.Delay)
end

function SWEP:SecondaryAttack()
	local ply = self:GetOwner()

	ply:SetAnimation(PLAYER_ATTACK1)

	self:SetNextIdle(CurTime() + self:SetWeaponAnim(ACT_VM_SECONDARYATTACK))
	self:EmitSound(self.Secondary.Sound, 75, 100, 0.4)

	if SERVER then
		local ent = ents.Create("ut2004_flak_shell")

		ent:SetPos(ply:GetShootPos())
		ent:SetAngles(ply:GetAimVector():Angle())
		ent:SetOwner(ply)
		ent:Spawn()
		ent:Activate()

		ent.Player = ply

		local phys = ent:GetPhysicsObject()

		if IsValid(phys) then
			phys:SetVelocity(ply:GetAimVector() * 2250 + Vector(0, 0, 225))
		end
	end

	self:SetNextPrimaryFire(CurTime() + self.Secondary.Delay)
	self:SetNextSecondaryFire(CurTime() + self.Secondary.Delay)
end