/*-------------------------------------------------------------------------------------------------------------------------
	TTT Punchometre
-------------------------------------------------------------------------------------------------------------------------*/

local PLUGIN = {}
PLUGIN.Title = "Punchometre"
PLUGIN.Description = "Add a punchometre boost permission."
PLUGIN.Author = "Metapyziks"
PLUGIN.Privileges = { "Infinite Punchometre", "Boosted Punchometre" }

if( SERVER ) then
	PLUGIN.LastThink = 0
	PLUGIN.Spectated = {}
	function PLUGIN:PostGamemodeLoaded()
		-- Override some TTT functions
		
		local propspec_toggle = CreateConVar("ttt_spec_prop_control", "1")

		local propspec_base = CreateConVar("ttt_spec_prop_base", "8")
		local propspec_min = CreateConVar("ttt_spec_prop_maxpenalty", "-6")
		local propspec_max = CreateConVar("ttt_spec_prop_maxbonus", "16")
		
		function PROPSPEC.Start(ply, ent)
			ply:Spectate(OBS_MODE_CHASE)
			ply:SpectateEntity(ent)

			local bonus = math.Clamp(math.ceil(ply:Frags() / 2), propspec_min:GetInt(), propspec_max:GetInt())

			local startPunches = 0
			local maxPunches = propspec_base:GetInt() + bonus

			if ply:EV_HasPrivilege( "Infinite Punchometre" ) then
				startPunches = maxPunches
			end

			ply.propspec = {ent=ent, t=0, retime=0, punches=startPunches, max=maxPunches}

			ent:SetNWEntity("spec_owner", ply)
			table.insert( PLUGIN.Spectated, ent )
			ent.spectated = true
			ply:SetNWInt("bonuspunches", bonus)
		end
		
		local propspec_force = CreateConVar("ttt_spec_prop_force", "110")
		local propspec_boosted_force = CreateConVar("ttt_spec_prop_boosted_force", "110")

		function PROPSPEC.Key(ply, key)
			local ent = ply.propspec.ent
			local phys = IsValid(ent) and ent:GetPhysicsObject()
			if (not IsValid(ent)) or (not IsValid(phys)) then 
				PROPSPEC.End(ply)
				return false
			end

			if not phys:IsMoveable() or ent:GetModel() == "models/props_c17/oildrum001_explosive" then
				PROPSPEC.End(ply)
				return true
			elseif phys:HasGameFlag(FVPHYSICS_PLAYER_HELD) then
				-- we can stay with the prop while it's held, but not affect it
				if key == IN_DUCK then
					PROPSPEC.End(ply)
				end
				return true
			end

			-- always allow leaving
			if key == IN_DUCK then
				PROPSPEC.End(ply)
				return true
			end

			local pr = ply.propspec
			if pr.t > CurTime() then return true end

			if pr.punches < 1 then return true end

			local m = math.min(150, phys:GetMass())
			local force = propspec_force:GetInt()

			if ply:EV_HasPrivilege( "Boosted Punchometre" ) then
				force = propspec_boosted_force:GetInt()
			end

			local aim = ply:GetAimVector()

			local mf = m * force

			pr.t = CurTime() + 0.15

			if key == IN_JUMP then
				-- upwards bump
				phys:ApplyForceCenter(Vector(0,0, mf))
				pr.t = CurTime() + 0.05
			elseif key == IN_FORWARD then
				-- bump away from player
				phys:ApplyForceCenter(aim * mf)
			elseif key == IN_BACK then
				phys:ApplyForceCenter(aim * (mf * -1))
			elseif key == IN_MOVELEFT then
				phys:AddAngleVelocity(Vector(0, 0, 200))
				phys:ApplyForceCenter(Vector(0,0, mf / 3))
			elseif key == IN_MOVERIGHT then
				phys:AddAngleVelocity(Vector(0, 0, -200))
				phys:ApplyForceCenter(Vector(0,0, mf / 3))
			else
				return true -- eat other keys, and do not decrement punches
			end

			if not ply:EV_HasPrivilege( "Infinite Punchometre" ) then
				pr.punches = math.max(pr.punches - 1, 0)
			else
				pr.punches = pr.max
			end
			ply:SetNWFloat("specpunches", pr.punches / pr.max)

			return true
		end

		local propspec_retime = CreateConVar("ttt_spec_prop_rechargetime", "1")

		function PROPSPEC.Recharge(ply)
			local pr = ply.propspec
			if pr.retime < CurTime() then
				pr.punches = math.min(pr.punches + 1, pr.max)
				ply:SetNWFloat("specpunches", pr.punches / pr.max)

				pr.retime = CurTime() + propspec_retime:GetFloat()
			end
		end
	end
	
	function PLUGIN:Think()
		local curtime = CurTime()
		if curtime - self.LastThink > 1.0 then
			self.LastThink = curtime
			
			local ended = {}
			for i, ent in ipairs( self.Spectated ) do
				local rem = false
				if not ent:IsValid() then
					rem = true
				else
					local ply = ent:GetNWEntity( "spec_owner" )
					if ( not ply or not ply:IsValid() ) then
						local phys = ent:GetPhysicsObject()
						if not phys:IsValid() or phys:IsAsleep() then
							rem = true
						end
					end
				end
				
				if rem then
					ent.spectated = false
					table.insert( ended, i - #ended )
				end
			end
			
			for _, i in ipairs( ended ) do
				table.remove( self.Spectated, i )
			end
		end
	end
	
	local propspec_dmgscale = CreateConVar( "ttt_spec_prop_damage_scale", "0" )
	
	function PLUGIN:EntityTakeDamage( ent, inflictor, attacker, amount, dmginfo )
		if not inflictor or inflictor:IsWorld() or inflictor:IsPlayer() or inflictor:IsWeapon() then return end
		
		if inflictor.spectated then
			dmginfo:ScaleDamage( propspec_dmgscale:GetFloat() )
		end
	end
end

evolve:RegisterPlugin( PLUGIN )