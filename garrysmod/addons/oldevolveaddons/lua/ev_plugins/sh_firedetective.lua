local PLUGIN = {}
PLUGIN.Title = "Fire Detective"
PLUGIN.Description = "Fire the current detective and choose a new one"
PLUGIN.Author = "Lawton27"
PLUGIN.ChatCommand = "firedetective"
PLUGIN.Usage = "[players]"
PLUGIN.Privileges = { "Fire Detective" }

function PLUGIN:Call( ply, args )
	if ( ply:EV_HasPrivilege( "Fire Detective" ) ) then
		local players = evolve:FindPlayer( args )
		
		if ( #players == 0 ) then -- if there's no players we can assume the admin wants to demote the current detective(s)
			for k,v in pairs(player.GetAll()) do -- for all players
				if( v:IsActiveDetective()) then
					table.insert(players, v)
				end
			end
		end

		if ( #players == 0 ) then -- if we still have no players let admin know
			evolve:Notify( ply, evolve.colors.red, evolve.constants.noplayers )
		end

		for _, pl in ipairs( players ) do
			if pl:IsActiveDetective() and pl:Alive() then
				pl:SetRole(ROLE_INNOCENT)

				local hasM16 = false
				local hasHUGE = false
				local hasShotgun = false
				local hasMAC10 = false
				local hasScout = false

				local hasPistol = false
				local hasGlock = false
				local hasDeagle = false

				if( pl:HasWeapon( "weapon_ttt_m16" )) then -- what primary weapon did he have?
					hasM16 = true
				elseif( pl:HasWeapon( "weapon_zm_sledge" )) then
					hasHUGE = true
				elseif( pl:HasWeapon( "weapon_zm_shotgun" )) then
					hasShotgun = true
				elseif( pl:HasWeapon( "weapon_zm_mac10" )) then
					hasMAC10 = true
				elseif( pl:HasWeapon( "weapon_zm_rifle" )) then
					hasScout = true
				end

				if(pl:HasWeapon( "weapon_zm_pistol" )) then -- what pistol did he have?
					hasPistol = true
				elseif( pl:HasWeapon( "weapon_ttt_glock" )) then
					hasGlock = true
				elseif( pl:HasWeapon( "weapon_zm_revolver" )) then
					hasDeagle = true
				end

				pl:StripWeapons() -- we don't want him to have a DNA scanner anymore
				pl:Give( "weapon_zm_improvised" ) -- give him the basic things
				pl:Give( "weapon_ttt_unarmed" )
				pl:Give( "weapon_zm_carry" )
				
				if hasM16 then -- give him back his primary
					pl:Give( "weapon_ttt_m16" )
				elseif hasHUGE then
					pl:Give( "weapon_zm_sledge" )
				elseif hasShotgun then
					pl:Give( "weapon_zm_shotgun" )
				elseif hasMAC10 then
					pl:Give( "weapon_zm_mac10" )
				elseif hasScout then
					pl:Give( "weapon_zm_rifle" )
				end

				if hasPistol then -- give him back his secondary
					pl:Give( "weapon_zm_pistol" )
				elseif hasGlock then
					pl:Give( "weapon_ttt_glock" )
				elseif hasDeagle then
					pl:Give( "weapon_zm_revolver" )
				end
				evolve:Notify( evolve.colors.red, pl:Nick(), evolve.colors.white, " has been striped of his detective rank!" )
				PromotePlayerToDetective(FindRandomPlayerSuitableForDetective()) --choose a new detective
				-- it's important we run this function now as setting a new detective updates the ranks for players so they can see the current detective lost his rank
				-- if no other detective is available this person may get his rank back, that's fine.
			else
				evolve:Notify( ply, evolve.colors.red, pl:Nick(), evolve.colors.white, " has been forced to avoid being detective in future." )
				-- this is to show the admin it's worked even if used on someone who's not detective
			end
			pl:ConCommand( "ttt_avoid_detective 1" ) -- to avoid him being detective again anytime soon
		end
	else
		evolve:Notify( ply, evolve.colors.red, evolve.constants.notallowed )
	end
end

function PLUGIN:Menu( arg, players )
	if ( arg ) then
		RunConsoleCommand( "ev", "firedetective", unpack( players ) )
	else
		return "Fire Detective", evolve.category.punishment
	end
end

evolve:RegisterPlugin( PLUGIN )