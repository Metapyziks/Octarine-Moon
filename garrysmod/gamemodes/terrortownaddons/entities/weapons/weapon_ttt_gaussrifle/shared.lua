
if SERVER then
   AddCSLuaFile( "shared.lua" )
   resource.AddFile("materials/VGUI/ttt/icon_gauss.vmt")
end

SWEP.HoldType           = "ar2"

if CLIENT then
   SWEP.PrintName          = "Gauss Rifle"

   SWEP.Slot               = 7

   SWEP.Icon = "VGUI/ttt/icon_gauss"
   
   SWEP.EquipMenuData = {
      type = "Weapon",
      desc = "High power, high accuracy\nGauss rifle which leaves a\ntracer after each shot.\nCan only be shot when zoomed\nin, and has limited ammo."
   };
end


SWEP.Base               = "weapon_tttbase"
SWEP.Spawnable = true
SWEP.AdminSpawnable = true

SWEP.Kind = WEAPON_EQUIP
SWEP.WeaponID = AMMO_RIFLE
SWEP.CanBuy = {ROLE_TRAITOR}
SWEP.LimitedStock = true

SWEP.Primary.Delay          = 1.7
SWEP.ChargeTime 			= 15
SWEP.Primary.Recoil         = 3
SWEP.Primary.Automatic = true
SWEP.Primary.Damage = 100
SWEP.Primary.Cone = 0.0
SWEP.Primary.ClipSize = 3
SWEP.Primary.ClipMax = 3 -- keep mirrored to ammo
SWEP.Primary.DefaultClip = 3

SWEP.ChargeEnd = 0

SWEP.HeadshotMultiplier = 1.5

SWEP.AutoSpawnable      = true
SWEP.Primary.Ammo 		= "AR2AltFire"
SWEP.ViewModel          = Model("models/weapons/v_snip_awp.mdl")
SWEP.WorldModel         = Model("models/weapons/w_snip_awp.mdl")

SWEP.Primary.Sound = Sound(")weapons/awp/awp1.wav")

SWEP.Secondary.Sound = Sound("Default.Zoom")

SWEP.IronSightsPos      = Vector( 5, -15, -2 )
SWEP.IronSightsAng      = Vector( 2.6, 1.37, 3.5 )

function SWEP:SetZoom(state)
    if CLIENT then 
       return
    else
       if state then
          self.Owner:SetFOV(20, 0.3)
       else
          self.Owner:SetFOV(0, 0.2)
       end
    end
end

function SWEP:ShootBullet( dmg, recoil, numbul, cone )

	self.Weapon:SendWeaponAnim(self.PrimaryAnim)

	self.Owner:MuzzleFlash()
	self.Owner:SetAnimation( PLAYER_ATTACK1 )

	if not IsFirstTimePredicted() then return end

	local sights = self:GetIronsights()

	numbul = numbul or 1
	cone   = cone   or 0.01

	local bullet = {}
	bullet.Num    = numbul
	bullet.Src    = self.Owner:GetShootPos()
	bullet.Dir    = self.Owner:GetAimVector()
	bullet.Spread = Vector( cone, cone, 0 )
	bullet.Tracer = 4
	bullet.Force  = 10
	bullet.Damage = dmg
	if SERVER or (CLIENT and IsFirstTimePredicted()) then
		bullet.Callback = function(att, tr, dmginfo)			
			local e = EffectData()
			e:SetEntity(att)
			e:SetStart(tr.StartPos)
			e:SetOrigin(tr.HitPos)
			e:SetMagnitude(tr.HitBox)
			e:SetScale(1)

			util.Effect("gauss_shot", e)
		end
	end

	if SERVER then
		local ply = self.Owner
		local pos = ply:GetPos()
		local ang = ply:EyeAngles()
		for _, ent in ipairs( ents.FindByClass( "weapon_ttt_teleport" ) ) do
			ent:SetTeleportMark( pos, ang )
		end
	end

	self.Owner:FireBullets( bullet )

	-- Owner can die after firebullets
	if (not IsValid(self.Owner)) or (not self.Owner:Alive()) or self.Owner:IsNPC() then return end

	if ((SinglePlayer() and SERVER) or
		((not SinglePlayer()) and CLIENT and IsFirstTimePredicted())) then

		-- reduce recoil if ironsighting
		recoil = sights and (recoil * 0.6) or recoil

		local eyeang = self.Owner:EyeAngles()
		eyeang.pitch = eyeang.pitch - recoil
		self.Owner:SetEyeAngles( eyeang )
	end
end

function SWEP.ScaleDamage( ply, hitgroup, dmginfo )
	if not SERVER or not dmginfo:IsBulletDamage() then return end
	
	local att = dmginfo:GetAttacker()
	if not att or not att:IsPlayer() then return end
	
	local wep = att:GetActiveWeapon()
	if not wep or wep:GetClass() ~= "weapon_ttt_gaussrifle" then return end
	
	local len = ply:GetPos():Distance( att:GetPos() )
	local scale = math.max( math.min( 8.0, ( len - 256 ) / 256 ), 0.125 )
	-- DamageLog( "Gauss Rifle Shot {" .. len .. "," .. scale .. "}" )
	dmginfo:ScaleDamage( scale )
end
hook.Add( "ScalePlayerDamage", "GaussScaleDamage", SWEP.ScaleDamage )

function SWEP:CanPrimaryAttack()
	return self:GetIronsights() and CurTime() >= self.ChargeEnd and self:Clip1() > 0
end

function SWEP:PrimaryAttack()	
	if( self:CanPrimaryAttack() ) then
		self.BaseClass.PrimaryAttack( self )
		self:Reload()
		
		self.ChargeEnd = CurTime() + self.ChargeTime
	elseif( CLIENT ) then
		self:EmitSound(self.Secondary.Sound)
	end
	
	self.Weapon:SetNextPrimaryFire( CurTime() + 1.0 )
	self.Weapon:SetNextSecondaryFire( CurTime() + 0.3 )
end

-- Add some zoom to ironsights for this gun
function SWEP:SecondaryAttack()
    if not self.IronSightsPos then return end
    if self.Weapon:GetNextSecondaryFire() > CurTime() then return end
    
    bIronsights = not self:GetIronsights()
    
    self:SetIronsights( bIronsights )
    
    if SERVER then
        self:SetZoom(bIronsights)
     else
        self:EmitSound(self.Secondary.Sound)
    end
    
    self.Weapon:SetNextSecondaryFire( CurTime() + 0.3 )
end

function SWEP:PreDrop()
    self:SetZoom(false)
    self:SetIronsights(false)
    return self.BaseClass.PreDrop(self)
end

function SWEP:Reload()
    self.Weapon:DefaultReload( ACT_VM_RELOAD );
    self:SetIronsights( false )
    self:SetZoom(false)
end


function SWEP:Holster()
    self:SetIronsights(false)
    self:SetZoom(false)
    return true
end

if CLIENT then
   local scope = surface.GetTextureID("sprites/scope")
   function SWEP:DrawHUD()
      if self:GetIronsights() then
         surface.SetDrawColor( 0, 0, 0, 255 )
         
         local x = ScrW() / 2.0
         local y = ScrH() / 2.0
         local scope_size = ScrH()

         -- crosshair
         local gap = 80
         local length = scope_size
         surface.DrawLine( x - length, y, x - gap, y )
         surface.DrawLine( x + length, y, x + gap, y )
         surface.DrawLine( x, y - length, x, y - gap )
         surface.DrawLine( x, y + length, x, y + gap )

         gap = 0
         length = 50
         surface.DrawLine( x - length, y, x - gap, y )
         surface.DrawLine( x + length, y, x + gap, y )
         surface.DrawLine( x, y - length, x, y - gap )
         surface.DrawLine( x, y + length, x, y + gap )


         -- cover edges
         local sh = scope_size / 2
         local w = (x - sh) + 2
         surface.DrawRect(0, 0, w, scope_size)
         surface.DrawRect(x + sh - 2, 0, w, scope_size)

         surface.SetDrawColor(255, 0, 0, 255)
         surface.DrawLine(x, y, x + 1, y + 1)

         -- scope
         surface.SetTexture(scope)
         surface.SetDrawColor(255, 255, 255, 255)

         surface.DrawTexturedRectRotated(x, y, scope_size, scope_size, 0)
		 
		 surface.SetDrawColor(0, 0, 0, 255)
		 surface.DrawRect( ScrW() / 2 - 129, ScrH() * 3 / 4 - 9, 258, 18 )
		 if self:Clip1() ~= 0 then
			local ctime = CurTime()
			local r = 255
			local gb = 0
			if ctime >= self.ChargeEnd then
			   local wave = ( math.sin( ( CurTime() - self.ChargeEnd ) * math.pi * 2 ) * 0.5 + 0.5 )
			   r = wave * r + ( 1 - wave ) * 255
			   gb = wave * gb + ( 1 - wave ) * 255
			end
			surface.SetDrawColor(r, gb, gb, 255)
			local prog = math.max( math.min( ( CurTime() - self.ChargeEnd + self.ChargeTime ) / self.ChargeTime, 1 ), 0 )
			local len = math.floor( prog * 256 )
			surface.DrawRect( ScrW() / 2 - 128, ScrH() * 3 / 4 - 8, len, 16 )
			
			local text = "" .. math.floor( prog * 100 ) .. "%"
			if prog == 1 then
				text = "FULLY CHARGED"
			end
			draw.SimpleText( text, "ScoreboardText", ScrW() / 2, ScrH() * 3 / 4, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		 else
			draw.SimpleText( "NO AMMO", "ScoreboardText", ScrW() / 2, ScrH() * 3 / 4, Color( 255, 0, 0, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		 end
      else
         return self.BaseClass.DrawHUD(self)
      end
   end
   
   function SWEP:AdjustMouseSensitivity()
      return (self:GetIronsights() and 0.2) or nil
   end
end
