EFFECT.GlowMat 		= Material(  "particle/particle_glow_04_additive" )

function EFFECT:Init(data)
	self.Origin = data:GetOrigin()
	self.Normal = data:GetAngles():Forward()
	self.Alpha = 2

	ParticleEffectAttach("ut2004_shockcore_impact", PATTACH_ABSORIGIN_FOLLOW, self, 0)
end

function EFFECT:Think()
	if self.Alpha <= 0 then
		return false
	end

	self.Alpha = self.Alpha - FrameTime()

	return true
end

function EFFECT:Render()
	local alpha = math.Clamp(math.Remap(self.Alpha, 0, 1, 0, 255), 0, 255)

	render.SetMaterial(self.GlowMat)
	render.DrawQuadEasy(self.Origin, self.Normal, 24, 24, Color(128, 128, 255, alpha), 0)
	render.DrawQuadEasy(self.Origin, self.Normal, 12, 12, Color(128, 128, 128, alpha), 0)
end