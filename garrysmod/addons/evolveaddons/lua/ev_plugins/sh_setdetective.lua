local PLUGIN = {}
PLUGIN.Title = "Set Detective"
PLUGIN.Description = "Promote a player to Detectove."
PLUGIN.Author = "Lawton27"
PLUGIN.ChatCommand = "setdetective"
PLUGIN.Usage = "[players]"
PLUGIN.Privileges = { "Promote To Detective" }

function PLUGIN:Call( ply, args )
	if ( ply:EV_HasPrivilege( "Promote To Detective" ) ) then
		local players = evolve:FindPlayer( args, ply )

		for _, pl in ipairs( players ) do
			if(pl:IsTraitor()) then
				evolve:Notify( ply, evolve.colors.red, "Cannot use this command on a traitor!" )
			elseif(ply:IsActiveDetective()) then
				evolve:notify( ply, evolve.colors.blue, pl:Nick(), evolve.color.red, "is already a Detective!" )
			else
				pl:SetRole(ROLE_DETECTIVE)
				SendFullStateUpdate() -- See terrortown/gamemode/traitor_state.lua This sends the new status to all clients
				if( not pl:HasWeapon( "weapon_ttt_wtester" ) ) then
					pl:Give( "weapon_ttt_wtester" ) -- only gives player scanner if they don't already have one
				end
				pl:AddCredits( 1 )
				evolve:Notify( evolve.colors.blue, ply:Nick(), evolve.colors.white, " has promoted ", evolve.colors.blue, pl:Nick(), evolve.colors.white, " to detective!" )
			end
		end

		if ( #players > 0 ) then
			
		else
			evolve:Notify( ply, evolve.colors.red, evolve.constants.noplayers )
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