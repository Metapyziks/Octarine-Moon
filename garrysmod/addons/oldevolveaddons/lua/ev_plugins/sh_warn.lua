/*-------------------------------------------------------------------------------------------------------------------------
	Warn a player
-------------------------------------------------------------------------------------------------------------------------*/

local PLUGIN = {}
PLUGIN.Title = "Warn"
PLUGIN.Description = "Warn a player and force them to skip a round."
PLUGIN.Author = "Metapyziks"
PLUGIN.ChatCommand = "warn"
PLUGIN.Usage = "<player> [skipround (1/0)] [reason]"
PLUGIN.Privileges = { "Warn" }
PLUGIN.SlayNextRound = {}

function PLUGIN:Warn( admin, ply, reason, skipround )
	
	evolve:Notify( evolve.colors.blue, admin:Nick(), evolve.colors.white, " warned ", evolve.colors.red, ply:Nick(), evolve.colors.white, " for ", evolve.colors.red, reason, evolve.colors.white, "." )
	
	if( skipround ) then
		evolve:Notify( evolve.colors.red, ply:Nick(), evolve.colors.white, " will not take part in the next round." )
		ply.SlayReason = reason
		table.insert( self.SlayNextRound, ply:UniqueID() )
	end
	
	HISTORY.AddWarning( admin, ply:UniqueID(), reason )
end

function PLUGIN:Call( ply, args )
	if( ply:EV_HasPrivilege( "Warn" ) ) then
		local pl = evolve:FindPlayer( args[1] )
		
		if ( #pl > 1 ) then
			evolve:Notify( ply, evolve.colors.white, "Did you mean ", evolve.colors.red, evolve:CreatePlayerList( pl, true ), evolve.colors.white, "?" )
			return
		elseif ( #pl == 1 ) then
			pl = pl[1]
		else
			evolve:Notify( ply, evolve.colors.red, evolve.constants.noplayers )
			return
		end
		
		local skipround = ( args[2] or "1" ) == "1"
		local reason = args[3] or "unacceptable behaviour"
		
		if( #args > 3 ) then
			for k, v in pairs( args ) do
				if( k > 3 ) then
					reason = reason .. " " .. v
				end
			end
		end
		
		if( SERVER ) then
			self:Warn( ply, pl, reason, skipround )
		end
	else
		evolve:Notify( ply, evolve.colors.red, evolve.constants.notallowed )
	end
end

function PLUGIN:Menu( arg, players )
	if ( arg ) then
		RunConsoleCommand( "ev", "warn", players[1], arg )
	else
		return "Warn", evolve.category.administration, {
			{ "RDMing", { 1, "random death matching" } },
			{ "Mic Spam", { 1, "mic Spamming" } },
			{ "Rude to Players", { 1, "being rude to players" } }
		}
	end
end

function OverridePlayerSpawning()

	local plymeta = FindMetaTable( "Player" )
	if not plymeta then return end

	function plymeta:Warned()
		return table.HasValue( PLUGIN.SlayNextRound, self:UniqueID() )
	end

	-- Preps a player for a new round, spawning them if they should. If dead_only is
	-- true, only spawns if player is dead, else just makes sure he is healed.
	function plymeta:SpawnForRound(dead_only)
		if self:Warned() then
			if( self.SlayReason ) then
				evolve:Notify( evolve.colors.red, self:Nick(), evolve.colors.white, " will not take part in this round due to ", evolve.colors.red, self.SlayReason, evolve.colors.white, "." )
			else
				evolve:Notify( evolve.colors.red, self:Nick(), evolve.colors.white, " will not take part in this round." )
			end
			
			if( self:Alive() ) then
				self:Kill()
			end
			
			self:SetNWBool("body_found", true)
			
			return false
		end
	
		-- wrong alive status and not a willing spec who unforced after prep started
		-- (and will therefore be "alive")
		if dead_only and self:Alive() and (not self:IsSpec()) then
			-- if the player does not need respawn, make sure he has full health
			self:SetHealth(self:GetMaxHealth())
			return false
		end

		if not self:ShouldSpawn() then return false end

		-- respawn anyone else
		if self:Team() == TEAM_SPEC then
			self:UnSpectate()
		end

		self:StripAll()
		self:SetTeam(TEAM_TERROR)
		self:Spawn()

		-- tell caller that we spawned
		return true
	end

	function plymeta:ShouldSpawn()
		-- do not spawn players who have been warned
		if( self:Warned()) then return false end

		-- do not spawn players who have not been through initspawn
		if (not self:IsSpec()) and (not self:IsTerror()) then return false end
		-- do not spawn forced specs
		if self:IsSpec() and self:GetForceSpec() then return false end

	   return true
	end
	
	function ClearWarnings()
		PLUGIN.SlayNextRound = {}
	end
	
	hook.Add( "TTTBeginRound", "ClearWarnings", ClearWarnings )
end

timer.Simple( 1.0, OverridePlayerSpawning )

evolve:RegisterPlugin( PLUGIN )