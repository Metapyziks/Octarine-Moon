local PLUGIN = {}
PLUGIN.Title = "Set Detective"
PLUGIN.Description = "Promote a player to Detectove."
PLUGIN.Author = "Lawton27"
PLUGIN.ChatCommand = "setdetective"
PLUGIN.Usage = "[players] - (optional)"
PLUGIN.Privileges = { "Promote To Detective" }

function PLUGIN:Call( ply, args )

	
	if ( ply:EV_HasPrivilege( "Promote To Detective" ) and GetRoundState() == ROUND_ACTIVE ) then
		local players = evolve:FindPlayer( args, ply )
		if ( #players > 0 ) then -- we have players to promote!
			print("There is players no need to find random")
		else -- otherwise we'll have to find someone...
			print("Looking for random players")
			-- first define some tables for the players we shall pick at random from
			local firstchoices = {} -- these players want to be detective
			local secondchoices = {} -- these players don't want to be detective but might have to be
			
			for k,v in pairs(player.GetAll()) do -- for all players
				-- first let's check that the person is alive, valid and not a traitor or detective
				print("looking at", v:Nick())
				if( v:IsValid() and v:IsTerror() and v:Alive() and not v:IsActiveDetective() and not v:IsRole(ROLE_TRAITOR)) then
					if v:GetAvoidDetective() then
						table.insert(secondchoices, v) -- if they want to be a second choice
						print("placing in second choice table")
					else
						table.insert(firstchoices, v) -- everyone else
						print("placing in first choice table")
					end
				end
			end
			-- now we need to pick someone at random
			if( #firstchoices > 0 ) then -- people who want to be detective exist
				print("now choosing from first choice table")
				table.insert(players, table.Random( firstchoices ))
			elseif( #secondchoices > 0 ) then  -- otherwise pick a second choice
				print("now choosing from second choice table")
				table.insert(players, table.Random( secondchoices ))
			else
				print("noone could be a detective :(")
				evolve:notify( ply, evolve.colors.red, "Unable to find suitable player to promote." )
			end
		end

		for _, pl in ipairs( players ) do
			print("attempting to promote", pl:Nick())
			if(pl:IsValid() and pl:IsTerror() and pl:Alive()) then
				if(pl:IsTraitor()) then
					evolve:Notify( ply, evolve.colors.red, "Cannot use this command on a traitor!" )
					print("was a traitor")
				elseif(pl:IsActiveDetective()) then
					evolve:Notify( ply, evolve.colors.blue, pl:Nick(), evolve.colors.red, "is already a Detective!" )
					print("was a detective")
				else
					pl:SetRole(ROLE_DETECTIVE)
					SendFullStateUpdate() -- See terrortown/gamemode/traitor_state.lua This sends the new status to all clients
					if( not pl:HasWeapon( "weapon_ttt_wtester" ) ) then
						pl:Give( "weapon_ttt_wtester" ) -- only gives player scanner if they don't already have one
					end
					pl:AddCredits( 1 )
					evolve:Notify( evolve.colors.blue, pl:Nick(), evolve.colors.white, " has been promoted to detective!" )
					print("promoted")
				end
			else
				evolve:Notify( ply, evolve.colors.red, "Unnable to promote player" )
				print("dead, invalid etc")
			end
		end
	else
		evolve:Notify( ply, evolve.colors.red, evolve.constants.notallowed )
	end
end

function PLUGIN:Menu( arg, players )
	if ( arg ) then
		RunConsoleCommand( "ev", "setdetective", unpack( players ) )
	else
		return "Set Detective", evolve.category.actions
	end
end

evolve:RegisterPlugin( PLUGIN )