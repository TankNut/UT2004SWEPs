EFFECT.EndMat 		= Material("ut2004/effects/shock_sparkle")
EFFECT.BeamMat 		= Material("ut2004/effects/ShockBeamTex")

function EFFECT:Init(data)
	if !IsValid(data:GetEntity()) then self:Remove() return end

	self:SetModel("models/ut2004/effects/shock_coil.mdl")
	self.Alpha = 1

	self.EndPos = data:GetOrigin()
	self.StartPos = self:GetTracerShootPos(data:GetStart(), data:GetEntity(), 1)

	self:SetRenderBoundsWS(self.StartPos, self.EndPos)

	self.Forward = (self.EndPos-self.StartPos):GetNormal()
	self.Angles = self.Forward:Angle()
	self.Distance = self.EndPos:Distance(self.StartPos)

	self:SetPos(self.StartPos)
	self:SetAngles(self.Angles)

	if cvars.Bool("ut2k4_lighting") then
		local dynlight = DynamicLight(data:GetEntity())
		dynlight.Pos = self.EndPos + data:GetNormal() * 10
		dynlight.Size = 90
		dynlight.Decay = 90
		dynlight.R = 60
		dynlight.G = 50
		dynlight.B = 255
		dynlight.Brightness = 4
		dynlight.DieTime = CurTime() + 0.4
	end
end

function EFFECT:Think()
	self.Alpha = self.Alpha - (FrameTime() * 2)

	if self.Alpha < 0 then return false end

	return true
end

function EFFECT:Render()
	local alpha = self.Alpha * 255
	local col = Color(alpha, alpha, alpha, alpha)

	self:SetColor(col)

	render.SetMaterial(self.EndMat)
	render.DrawSprite(self.StartPos, 20, 20, col)
	render.SetMaterial(self.BeamMat)
	render.DrawBeam(self.StartPos, self.EndPos, 10, 0, 1, col)

	for i = 0, self.Distance / 45 do
		self:SetupBones()
		self:SetPos(self.StartPos + self.Forward * i * 45)
		self:DrawModel()
	end

	self:SetPos(self.StartPos)
end