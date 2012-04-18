/*-------------------------------------------------------------------------------------------------------------------------
	Run a console command on someone
-------------------------------------------------------------------------------------------------------------------------*/

local PLUGIN = {}
PLUGIN.Title = "Ghost Mode"
PLUGIN.Description = "Makes traitors invisible with 1 health."
PLUGIN.Author = "Metapyziks"
PLUGIN.ChatCommand = "ghostmode"
PLUGIN.Usage = "[1/0]"
PLUGIN.Privileges = { "Ghost Mode" }
PLUGIN.WasGhostMode = false
PLUGIN.DisablePVP = false

PLUGIN.EnabledConVar = CreateConVar( "ttt_ghostmode_enabled", "0", { FCVAR_REPLICATED, FCVAR_NOTIFY } )
PLUGIN.HealthConVar = CreateConVar( "ttt_ghostmode_health", "1", { FCVAR_NOTIFY } )

function PLUGIN:Call( ply, args )
	if ( ply:EV_HasPrivilege( "Ghost Mode" ) ) then
		if SERVER then
			local wasenabled = self.EnabledConVar:GetBool()
			if #args == 0 or ( args[ 1 ] == "1" ) ~= wasenabled then
				local enabled = not wasenabled
				if enabled then
					RunConsoleCommand( "ttt_ghostmode_enabled", 1 )
					evolve:Notify( evolve.colors.red, "Ghost mode has been enabled!" )
				else
					RunConsoleCommand( "ttt_ghostmode_enabled", 0 )
					evolve:Notify( evolve.colors.red, "Ghost mode has been disabled!" )
				end
			end
		end
	else
		evolve:Notify( ply, evolve.colors.red, evolve.constants.notallowed )
	end
end

if SERVER then
	local replaceWeps =
	{
		"weapon_zm_shotgun",
		"weapon_zm_sledge",
		"weapon_zm_mac10",
		"weapon_ttt_m16",
		"weapon_zm_pistol",
		"weapon_zm_revolver"
	}
	local replaceAmmo =
	{
		"item_ammo_357_ttt",
		"item_ammo_smg1_ttt",
		"item_ammo_pistol_ttt",
		"item_box_buckshot_ttt",
		"item_ammo_revolver_ttt"
	}
	
	function PLUGIN:PostGamemodeLoaded()
		local fallsounds = {
			Sound("player/damage1.wav"),
			Sound("player/damage2.wav"),
			Sound("player/damage3.wav")
		};
		
		function GAMEMODE:GetFallDamage( ply, speed )
			return 0
		end

		function GAMEMODE:OnPlayerHitGround(ply, in_water, on_floater, speed)
			if in_water or speed < 450 or not IsValid(ply) then return end

			-- Everything over a threshold hurts you, rising exponentially with speed
			local damage = math.pow(0.05 * (speed - 420), 1.75)

			-- I don't know exactly when on_floater is true, but it's probably when
			-- landing on something that is in water.
			if on_floater then damage = damage / 2 end

			-- if we fell on a dude, that hurts (him)
			local ground = ply:GetGroundEntity()
			if IsValid(ground) and ground:IsPlayer() then
				if math.floor(damage) > 0 then
					local att = ply

					-- if the faller was pushed, that person should get attrib
					local push = ply.was_pushed
					if push then
						-- TODO: move push time checking stuff into fn?
						if math.max(push.t or 0, push.hurt or 0) > CurTime() - 4 then
							att = push.att
						end
					end

					local dmg = DamageInfo()

					if att == ply then
						-- hijack physgun damage as a marker of this type of kill
						dmg:SetDamageType(DMG_CRUSH + DMG_PHYSGUN)
					else
						-- if attributing to pusher, show more generic crush msg for now
						dmg:SetDamageType(DMG_CRUSH)
					end

					dmg:SetAttacker(att)
					dmg:SetInflictor(att)
					dmg:SetDamageForce(Vector(0,0,-1))
					dmg:SetDamage(damage)

					ground:TakeDamageInfo(dmg)
				end

				-- our own falling damage is cushioned
				damage = damage / 3
			end

			if math.floor(damage) > 0 then
				local oldDamage = damage
				if PLUGIN.EnabledConVar:GetBool()
					and ply:IsActiveTraitor() then
					damage = damage / 100
				end

				if math.floor(damage) > 0 then
					local dmg = DamageInfo()
					dmg:SetDamageType(DMG_FALL)
					dmg:SetAttacker(GetWorldEntity())
					dmg:SetInflictor(GetWorldEntity())
					dmg:SetDamageForce(Vector(0,0,1))
					dmg:SetDamage(damage)

					ply:TakeDamageInfo(dmg)
				end

				-- play CS:S fall sound if we got somewhat significant damage
				if oldDamage > 5 then
					WorldSound(table.Random(fallsounds), ply:GetShootPos(), 55 + math.Clamp(oldDamage, 0, 50), 100)
				end
			end
		end
	
		local ttt_postdm = GetConVar("ttt_postround_dm")
	
		function GAMEMODE:AllowPVP()
			local rs = GetRoundState()
			return not (rs == ROUND_PREP or (rs == ROUND_POST and not ttt_postdm:GetBool()) or (rs == ROUND_ACTIVE and PLUGIN.DisablePVP))
		end
	end

	local function prepareRound()
		if PLUGIN.WasGhostMode then
			for _, ply in ipairs( player.GetAll() ) do
				if ply:GetNWBool( "EV_Ghosted", false ) then
					ply:SetRenderMode( RENDERMODE_NORMAL )
					ply:SetColor( 255, 255, 255, 255 )
					ply:SetCollisionGroup( COLLISION_GROUP_PLAYER )
					for _, w in ipairs( ply:GetWeapons() ) do
						w:SetRenderMode( RENDERMODE_NORMAL )
						w:SetColor( 255, 255, 255, 255 )
					end
					ply:SetNWBool( "EV_Ghosted", false )
				end
			end
			PLUGIN.WasGhostMode = false
			PLUGIN.DisablePVP = false
		end
		if PLUGIN.EnabledConVar:GetBool() then
			timer.Simple( 0.5, function()
				for _, wep in ipairs( ents.FindByClass( "weapon_zm_rifle" ) ) do
					local pos = wep:GetPos()
					local ang = wep:GetAngles()
					wep:Remove()
					local new = ents.Create( table.Random( replaceWeps ) )
					new:SetPos( pos )
					new:SetAngles( ang )
					new:Spawn()
					new:Activate()
					new:PhysWake()
				end
				for _, ammo in ipairs( ents.FindByClass( "item_ammo_357_ttt" ) ) do
					local pos = ammo:GetPos()
					local ang = ammo:GetAngles()
					ammo:Remove()
					local new = ents.Create( table.Random( replaceAmmo ) )
					new:SetPos( pos )
					new:SetAngles( ang )
					new:Spawn()
					new:Activate()
					new:PhysWake()
				end
			end )
		end
	end
	hook.Add( "TTTPrepareRound", "TTTPrepareRound_GhostMode", prepareRound )

	local function roundStart()
		if PLUGIN.EnabledConVar:GetBool() then
			PLUGIN.WasGhostMode = true
			PLUGIN.DisablePVP = true
			timer.Simple( 10, function()
				PLUGIN.DisablePVP = false
			end )
			local health = PLUGIN.HealthConVar:GetInt()
			for _, ply in ipairs( player.GetAll() ) do
				if ply:IsActiveTraitor() then
					ply:SetHealth( health )
					ply:SetRenderMode( RENDERMODE_NONE )
					ply:SetCollisionGroup( COLLISION_GROUP_WEAPON )
					ply:SetColor( 255, 255, 255, 0 )					
					for _, w in ipairs( ply:GetWeapons() ) do
						w:SetRenderMode( RENDERMODE_NONE )
						w:SetColor( 255, 255, 255, 0 )
					end
					ply:SetNWBool( "EV_Ghosted", true )
					ply:SetNWBool( "disguised", true )
				end
			end
			evolve:Notify( evolve.colors.red, "Ghost mode is enabled! Traitors are invisible and only have " .. health .. " health!" )
		else
			PLUGIN.WasGhostMode = false
		end
	end
	hook.Add( "TTTBeginRound", "TTTBeginRound_GhostMode", roundStart )
end
if CLIENT then
	function PLUGIN:PostGamemodeLoaded()
		function RADIO:GetTargetType()
			if not ValidEntity(LocalPlayer()) then return end
			local trace = LocalPlayer():GetEyeTrace(MASK_SHOT)

			if not trace or (not trace.Hit) or (not IsValid(trace.Entity)) then return end

			local ent = trace.Entity

			if ent:IsPlayer() and not ( PLUGIN.EnabledConVar:GetBool() and ent:GetNWBool("disguised", false) ) then
				if ent:GetNWBool("disguised", false) then
					return "quick_disg", true
				else
					return ent, false
				end
			elseif ent:GetClass() == "prop_ragdoll" and CORPSE.GetPlayerNick(ent, "") != "" then

				if DetectiveMode() and not CORPSE.GetFound(ent, false) then
					return "quick_corpse", true
				else
					return ent, false
				end
			end
		end
	end
end

evolve:RegisterPlugin( PLUGIN )