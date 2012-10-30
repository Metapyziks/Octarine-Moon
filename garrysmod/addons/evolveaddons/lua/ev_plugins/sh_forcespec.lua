local PLUGIN = {}
PLUGIN.Title = "Force Spectate"
PLUGIN.Description = "Force a player to spectate."
PLUGIN.Author = "Metapyziks"
PLUGIN.ChatCommand = "forcespec"
PLUGIN.Usage = "[players]"
PLUGIN.Privileges = { "Force Spectate" }

function PLUGIN:Call( ply, args )
	if ( ply:EV_HasPrivilege( "Force Spectate" ) ) then
		local players = evolve:FindPlayer( args, ply )
		
		for _, pl in ipairs( players ) do
			if pl:IsTerror() and pl:Alive() then
				if pl:IsActiveDetective() then -- set a new detective if needed
					PromotePlayerToDetective(FindRandomPlayerSuitableForDetective())
					pl:SetRole(ROLE_INNOCENT)
					pl:StripWeapons()
				end
				pl:Kill()
				pl:SetNWBool("body_found", true)
			end
			pl:ConCommand( "ttt_spectator_mode 1" )
			pl:ConCommand( "ttt_cl_idlepopup" )
		end
		
		if ( #players > 0 ) then
			evolve:Notify( evolve.colors.blue, ply:Nick(), evolve.colors.white, " has forced ", evolve.colors.red, evolve:CreatePlayerList( players ), evolve.colors.white, " to spectate." )
		else
			evolve:Notify( ply, evolve.colors.red, evolve.constants.noplayers )
		end
	else
		evolve:Notify( ply, evolve.colors.red, evolve.constants.notallowed )
	end
end

function PLUGIN:Menu( arg, players )
	if ( arg ) then
		RunConsoleCommand( "ev", "forcespec", unpack( players ) )
	else
		return "Force Spectate", evolve.category.punishment
	end
end

evolve:RegisterPlugin( PLUGIN )