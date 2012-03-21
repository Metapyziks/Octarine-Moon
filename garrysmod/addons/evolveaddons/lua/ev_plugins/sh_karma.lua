/*-------------------------------------------------------------------------------------------------------------------------
	TTT Karma Editing
-------------------------------------------------------------------------------------------------------------------------*/

local PLUGIN = {}
PLUGIN.Title = "Karma"
PLUGIN.Description = "Modifies a player's karma."
PLUGIN.Author = "Metapyziks"
PLUGIN.ChatCommand = "karma"
PLUGIN.Usage = nil
PLUGIN.Privileges = { "Karma" }

function PLUGIN:Call( ply, args )
	if ( KARMA and ply:EV_HasPrivilege( "Karma" ) ) then
		local players = evolve:FindPlayer( args, ply, true )
		local value = tonumber( args[ #args ] ) or 1000
		
		for _, pl in ipairs( players ) do
			pl:SetLiveKarma( value )
			KARMA.ApplyKarma( pl )
			pl:SetBaseKarma(pl:GetLiveKarma())
		end
		
		if ( #players > 0 ) then
			evolve:Notify( evolve.colors.blue, ply:Nick(), evolve.colors.white, " changed ", evolve.colors.red, evolve:CreatePlayerList( players ), evolve.colors.white, "'s karma to ", evolve.colors.red, tostring( value ), evolve.colors.white, "." )
		else
			evolve:Notify( ply, evolve.colors.red, evolve.constants.noplayers )
		end
	else
		evolve:Notify( ply, evolve.colors.red, evolve.constants.notallowed )
	end
end

function PLUGIN:Menu( arg, players )
	if ( arg ) then
		table.insert( players, arg )
		RunConsoleCommand( "ev", "karma", unpack( players ) )
	else
		return "Set Karma", evolve.category.actions, { { "None", 0 }, { "100", 100 }, { "200", 200 }, { "300", 300 }, { "400", 400 }, { "500", 500 }, { "600", 600 }, { "700", 700 }, { "800", 800 }, { "900", 900 }, { "Full", 1000 } }
	end
end

evolve:RegisterPlugin( PLUGIN )