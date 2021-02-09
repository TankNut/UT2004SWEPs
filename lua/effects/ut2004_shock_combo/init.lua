EFFECT.Mat1 = Material("ut2004/effects/shock_spheretex")

PrecacheParticleSystem("ut2004_shockcore_explosion")

function EFFECT:Init(data)
	self.Pos = data:GetOrigin()

	if cvars.Bool("ut2k4_lighting") then
		local dynlight = DynamicLight(0)

		dynlight.Pos = data:GetOrigin()
		dynlight.Size = 200
		dynlight.Decay = 200
		dynlight.R = 50
		dynlight.G = 80
		dynlight.B = 255
		dynlight.Brightness = 7
		dynlight.DieTime = CurTime() + 0.4
	end

	self.Time = 0
	self.Size2 = 0
	ParticleEffectAttach("ut2004_shockcore_explosion", PATTACH_ABSORIGIN_FOLLOW, self, 0)
end

function EFFECT:Think()
	self.Time = self.Time + FrameTime()

	self.Size2 = 10 - self.Time * 10
	self.Size2 = math.Clamp(self.Size2, 0, 5)

	return self.Time < 1.0
end

function EFFECT:Render()
	render.SetMaterial(self.Mat1)
	render.DrawSphere(self:GetPos(), 16 * self.Size2, 16, 16, color_white)

	local matrix = Matrix()

	matrix:SetTranslation(Vector(self.Time * 2, self.Time * 0.6, 0))
	matrix:SetScale(Vector(1, 0.5, 0))

	self.Mat1:SetMatrix("$basetexturetransform", matrix)
end