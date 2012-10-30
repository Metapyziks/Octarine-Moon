/*-------------------------------------------------------------------------------------------------------------------------
	Get information about a player
-------------------------------------------------------------------------------------------------------------------------*/

local PLUGIN = {}
PLUGIN.Title = "Get Info"
PLUGIN.Description = "Get information on a player"
PLUGIN.Author = "Helix Nebula"
PLUGIN.ChatCommand = "getinfo"
PLUGIN.Usage = "[players]"
PLUGIN.Privileges = { "Get Info" }

function EV_func_Player:CommunityID()
	local steamid = self:SteamID()
	local x, y, z = string.match( steamid, "STEAM_(%d+):(%d+):(%d+)" )
	if ( x and y and z ) then
		local friendid = string.format( "765%0.f", z * 2 + 61197960265728 + y )
		return friendid
	else
		return steamid
	end
end

function PLUGIN:Call( ply, args )
	if ( ply:EV_HasPrivilege( "Get Info" ) ) then
		local players = evolve:FindPlayer( args, ply )
		
		for _, pl in ipairs( players ) do
			ply:PrintMessage( HUD_PRINTCONSOLE, "Nick: " .. pl:Nick() )
			ply:PrintMessage( HUD_PRINTCONSOLE, "Steam ID: " .. pl:SteamID() )
			ply:PrintMessage( HUD_PRINTCONSOLE, "Community ID: " .. pl:CommunityID() )
			ply:PrintMessage( HUD_PRINTCONSOLE, "Rank: " .. evolve.ranks[ pl:EV_GetRank() ].Title )
			ply:PrintMessage( HUD_PRINTCONSOLE, "IP Address: " .. pl:IPAddress() )
		end
		
		if ( #players > 0 ) then
			--evolve:Notify( evolve.colors.blue, ply:Nick(), evolve.colors.white, " has got information about ", evolve.colors.red, evolve:CreatePlayerList( players ), evolve.colors.white, "." )
		else
			evolve:Notify( ply, evolve.colors.red, "No matching players found." )
		end
	else
		evolve:Notify( ply, evolve.colors.red, evolve.constants.notallowed )
	end
end

function PLUGIN:Menu( arg, players )
	if ( arg ) then
		RunConsoleCommand( "ev", "getinfo", unpack( players ) )
	else
		return "Get Info", evolve.category.administration
	end
end

evolve:RegisterPlugin( PLUGIN )