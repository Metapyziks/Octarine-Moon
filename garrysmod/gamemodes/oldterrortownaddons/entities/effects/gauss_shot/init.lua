
function EFFECT:Init(data)
   self.ShotStart = data:GetStart()
   self.ShotEnd   = data:GetOrigin()

   -- ws = worldspace
   self:SetRenderBoundsWS(self.ShotStart, self.ShotEnd)

   self.HitBox    = data:GetMagnitude()

   self.Duration  = 10
   self.EndTime   = CurTime() + self.Duration

   self.FadeIn   = CurTime() + 0.2
   self.FadeOut  = self.EndTime - 3

   self.Width = 0
   self.WidthMax = 5
end

function EFFECT:Think()
   if self.EndTime < CurTime() then
      return false
   end

	if self.FadeOut < CurTime() then
      self.Width = self.WidthMax * (1 - ((CurTime() - self.FadeOut) / 3))
	else
	  self.Width = self.WidthMax
	end
   return true
end

local shot_mat = Material("cable/blue_elec")
--local clr = Color(0, 0, 100, 255)
function EFFECT:Render()
   render.SetMaterial(shot_mat)

   render.DrawBeam(self.ShotStart, self.ShotEnd, self.Width, 0, 0, self.Color)
end
