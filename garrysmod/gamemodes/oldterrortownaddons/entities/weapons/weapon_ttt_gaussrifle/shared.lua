
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
SWEP.ChargeTime 			= 60
SWEP.Primary.Recoil         = 3
SWEP.Primary.Automatic = true
SWEP.Primary.Damage = 100
SWEP.Primary.Cone = 0.0
SWEP.Primary.ClipSize = 2
SWEP.Primary.ClipMax = 2 -- keep mirrored to ammo
SWEP.Primary.DefaultClip = 2

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

SWEP.ViewModelFOV = 60

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

function SWEP:ShootBullet( dmg, recoil, numbul, cone, startpos )
	local firstshot = startpos == nil
	if firstshot then
		self.Weapon:SendWeaponAnim(self.PrimaryAnim)

		self.Owner:MuzzleFlash()
		self.Owner:SetAnimation( PLAYER_ATTACK1 )
	end

	if not IsFirstTimePredicted() then return end

	local sights = self:GetIronsights()

	numbul = numbul or 1
	cone   = cone   or 0
	startpos = startpos or self.Owner:GetShootPos()
	
	local dir = self.Owner:GetAimVector()

	local bullet = {}
	bullet.Num    = numbul
	bullet.Src    = startpos
	bullet.Dir    = dir
	bullet.Spread = Vector( cone, cone, 0 )
	bullet.Tracer = 4
	bullet.Force  = 50
	bullet.Damage = dmg
	
	local forcehurt = false
	local targ = nil
	local targpos = nil
	
	if firstshot and self:GetNWBool( "HasTarget" ) then
		targ = self:GetNWEntity( "CurTarget" )
		if IsValid( targ ) then
			forcehurt = true
			targpos = targ:GetPos() + Vector( 0, 0, 48 )
			if targ:Crouching() then
				targpos = targpos + Vector( 0, 0, -32 )
			end
			local diff = targpos - self.Owner:GetShootPos()
			bullet.Dir = diff
			bullet.Damage = 0
		end
	end
	if SERVER or (CLIENT and IsFirstTimePredicted()) then
		bullet.Callback = function(att, tr, dmginfo)
			local e = EffectData()
			e:SetEntity(att)
			e:SetStart(tr.StartPos)
			e:SetOrigin(tr.HitPos)
			e:SetMagnitude(tr.HitBox)
			e:SetScale(1)
			util.Effect("gauss_shot", e)
			
			if dmg >= 10 and not tr.HitSky then
				local trdata = {}
				trdata.start = tr.HitPos + 16 * dir
				trdata.endpos = tr.HitPos
				trdata.filter = lply
				trdata.mask = MASK_SHOT
				
				local trace = util.TraceLine( trdata )
				
				if not trace.StartSolid then
					self:ShootBullet( dmg * trace.Fraction * 0.9, recoil, numbul, cone + 0.125 * ( 1 - trace.Fraction ), trace.HitPos + 1 * dir )
				end
			end
			
			if firstshot and forcehurt then
				e:SetOrigin( targpos )
				if SERVER then
					local fdmginfo = DamageInfo()
					fdmginfo:SetDamage( dmg )
					fdmginfo:SetAttacker( self.Owner )
					fdmginfo:SetInflictor( self.Owner )
					fdmginfo:SetDamageType( DMG_BULLET )
					fdmginfo:SetDamageForce( 50 * tr.Normal )
					targ:DispatchTraceAttack( fdmginfo, startpos + ( self.Owner:GetAimVector() * 3 ), targpos )
				end
			end
		end
	end

	if firstshot and SERVER then
		local ply = self.Owner
		local pos = ply:GetPos()
		local ang = ply:EyeAngles()
		for _, ent in ipairs( ents.FindByClass( "weapon_ttt_teleport" ) ) do
			ent:SetTeleportMark( pos, ang )
		end
	end
	
	self.Owner:FireBullets( bullet )

	-- Owner can die after firebullets
	if not firstshot or (not IsValid(self.Owner)) or (not self.Owner:Alive()) or self.Owner:IsNPC() then return end

	if CLIENT and IsFirstTimePredicted() then

		-- reduce recoil if ironsighting
		recoil = sights and (recoil * 0.6) or recoil

		local eyeang = self.Owner:EyeAngles()
		eyeang.pitch = eyeang.pitch - recoil
		self.Owner:SetEyeAngles( eyeang )
	end
end

function SWEP.ScaleDamage( ply, hitgroup, dmginfo )
	if not SERVER or not dmginfo:IsBulletDamage() then return end
	local n = 1
		
	local att = dmginfo:GetAttacker()
	if not att or not att:IsPlayer() then return end
		
	local wep = att:GetActiveWeapon()
	if not wep or wep:GetClass() ~= "weapon_ttt_gaussrifle" then return end
		
	local len = ply:GetPos():Distance( att:GetPos() )
	local scale = math.max( math.min( 8.0, ( len - 256 ) / 256 ), 0.125 )
	
	local force = dmginfo:GetDamageForce()
	force:Normalize()
	
	dmginfo:ScaleDamage( scale )
	dmginfo:SetDamageForce( force * scale * 50 )
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
		if SERVER then
			self:SetNWFloat( "ChargeEnd", self.ChargeEnd )
		end
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
		self:SetNWBool( "HasTarget", false )
    else
        self:EmitSound(self.Secondary.Sound)
		self.ChargeEnd = self:GetNWFloat( "ChargeEnd" )
		self.CurTarget = nil
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

if SERVER then
	function playerChangeTarget( ply, cmd, args )
		if IsValid( ply ) and ply:Alive() then
			local wep = ply:GetActiveWeapon()
			if IsValid( wep ) and wep:GetClass() == "weapon_ttt_gaussrifle" then
				if not tonumber( args[ 1 ] ) or tonumber( args[ 1 ] ) == -1 then
					wep:SetNWBool( "HasTarget", false )
				else
					local targ = Entity( args[ 1 ] )
					if IsValid( targ ) and targ:IsPlayer() and targ:IsTerror() and targ:Alive() then
						wep:SetNWBool( "HasTarget", true )
						wep:SetNWEntity( "CurTarget", targ )
					end
				end
			end
		end
	end
	concommand.Add( "ttt_gauss_changetarget", playerChangeTarget )
end

if CLIENT then
	SWEP.LastTargCheck = 0
	SWEP.Targets = {}
	SWEP.CurTarget = nil
	SWEP.LastTargetTime = 0
	
	local scope = surface.GetTextureID("sprites/scope")
	function SWEP:CheckForTargets()
		self.LastTargCheck = CurTime()
		
		local lply = LocalPlayer()
		local aim = lply:GetAimVector()
		
		local fov = 10 / 180 * math.pi
		
		self.Targets = {}
		
		for _, ply in pairs( player.GetAll() ) do
			if ply ~= lply and IsValid( ply ) and ply:Alive() and ply:IsTerror() then
				local pos = ply:GetPos() + Vector( 0, 0, 48 )
				if ply:Crouching() then
					pos = pos + Vector( 0, 0, -32 )
				end
				local diff = pos - lply:GetShootPos()
				local norm = diff:GetNormal()
				local ang = math.acos( aim:Dot( norm ) )
				
				if ang < fov and diff:Length() > 128 then
					local trdata = {}
					trdata.start = lply:GetShootPos()
					trdata.endpos = pos
					trdata.filter = lply
					trdata.mask = MASK_SHOT
					local tr = util.TraceLine( trdata )
		
					if not tr.Hit or tr.Entity == ply or ( IsValid( tr.Entity ) and tr.Entity:GetParent() == ply ) or tr.HitPos:Distance( pos ) <= 16 then
						table.insert( self.Targets, { Angle = ang, Player = ply } )
					end
				end
			end
		end
		
		if self.CurTarget ~= nil and not table.HasValue( self.Targets, self.CurTarget ) then
			self:UpdateTarget( nil )
		end
		
		table.sort( self.Targets, function( a, b )
			return a.Angle < b.Angle
		end )
	end
	
	function SWEP:UpdateTarget( targ )
		if targ == nil and CurTime() - self.LastTargetTime < 0.5 then return end
		
		self.CurTarget = targ
		if IsValid( targ ) then
			RunConsoleCommand( "ttt_gauss_changetarget", targ:EntIndex() )
		else
			RunConsoleCommand( "ttt_gauss_changetarget", -1 )
		end			
	end

	function SWEP:DrawHUD()
		if self:GetIronsights() then
			if CurTime() - self.LastTargCheck > 0.25 then
				self:CheckForTargets()
			end
			
			surface.SetDrawColor( 0, 255, 0, 255 )
			
			local shootpos = self.Owner:GetShootPos()
			local aim = self.Owner:GetAimVector():Angle()
			local vup = Vector( 0, 0, 1 )
			local vright = aim:Right()
			
			local vtls = vup * 72 - vright * 16
			local vtlc = vup * 36 - vright * 16
			local vbrs = vright * 16
			local vbrc = vbrs
			
			local x = ScrW() / 2.0
			local y = ScrH() / 2.0
			
			local targdist = 0
			local newtarg = nil
			
			local lasttarg = false
			
			local curtarg = nil
			if self:GetNWBool( "HasTarget" ) then
				curtarg = self:GetNWEntity( "CurTarget" )
			end
			
			for _, targ in pairs( self.Targets ) do
				local ply = targ.Player
				local pos = ply:GetPos()
				local tl, br
				if ply:Crouching() then
					tl = ( pos + vtlc ):ToScreen()
					br = ( pos + vbrc ):ToScreen()
				else
					tl = ( pos + vtls ):ToScreen()
					br = ( pos + vbrs ):ToScreen()
				end
				
				tl.x = tl.x - 16
				tl.y = tl.y - 16
				br.x = br.x + 16
				br.y = br.y + 16
				
				if tl.x < x and tl.y < y and br.x > x and br.y > y then
					local dist = pos:Distance( shootpos )
					if dist < targdist or targdist == 0 then
						newtarg = ply
						targdist = dist
						self.LastTargetTime = CurTime()
					end
				end
				
				local width, height = br.x - tl.x, br.y - tl.y
				
				if curtarg == ply then
					lasttarg = true
					surface.SetDrawColor( 255, 0, 0, 255 )
				elseif lasttarg then
					lasttarg = false
					surface.SetDrawColor( 0, 255, 0, 255 )
				end
				
				surface.DrawOutlinedRect( tl.x, tl.y, width, height )
			end
			
			if newtarg ~= self.CurTarget then
				self:UpdateTarget( newtarg )
			end
		
			surface.SetDrawColor( 0, 0, 0, 255 )

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
				draw.SimpleText( text, "Default", ScrW() / 2, ScrH() * 3 / 4, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
			else
				draw.SimpleText( "NO AMMO", "Default", ScrW() / 2, ScrH() * 3 / 4, Color( 255, 0, 0, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
			end
		else
			return self.BaseClass.DrawHUD(self)
		end
	end

	function SWEP:AdjustMouseSensitivity()
		return (self:GetIronsights() and 0.2) or nil
	end
end
