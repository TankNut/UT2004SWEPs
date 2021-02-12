function EFFECT:Init(data)
	self.Weapon = data:GetEntity()

	local ply = self.Weapon:GetOwner()

	if not IsValid(self.Weapon) then
		self:Remove()
		return
	end

	self:SetModel("models/ut2004/effects/shieldgun_shield.mdl")

	self:SetPos(ply:GetShootPos())
	self:SetAngles(ply:EyeAngles())

	self:SetModelScale(0.5)
end

function EFFECT:Think()
	self:SetPos(EyePos())
	self:SetAngles(EyeAngles())

	return IsValid(self.Weapon) and self.Weapon:GetShieldTime() > 0
end

function EFFECT:IsDrawingVM()
	return self.Weapon:IsCarriedByLocalPlayer() and not LocalPlayer():ShouldDrawLocalPlayer()
end

function EFFECT:Render()
	local pos, ang

	if self:IsDrawingVM() then
		pos, ang = LocalToWorld(Vector(36, -8, -8), Angle(0, 180, 0), EyePos(), EyeAngles())
	else
		local att = self.Weapon:GetAttachment(1)

		pos, ang = LocalToWorld(vector_origin, Angle(0, 180, 0), att.Pos, att.Ang)
	end

	self:SetPos(pos)
	self:SetAngles(ang)
	self:SetupBones()
	self:DrawModel()
end