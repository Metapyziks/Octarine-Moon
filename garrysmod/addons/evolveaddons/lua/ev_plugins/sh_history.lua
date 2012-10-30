/*-------------------------------------------------------------------------------------------------------------------------
	Record ban and warning history
-------------------------------------------------------------------------------------------------------------------------*/

if( SERVER ) then
	EVNT_WARNING 	= 0
	EVNT_KICK 		= 1
	EVNT_BAN 		= 2

	HISTORY = {}

	HISTORY.PlayerData = {}

	function HISTORY.LoadHistory()
		if ( file.Exists( "ev_warnhistory.txt" ) ) then
			debug.sethook()
			HISTORY.PlayerData = glon.decode( file.Read( "ev_warnhistory.txt" ) )
		else
			HISTORY.PlayerData = {}
		end
	end

	function HISTORY.SaveHistory()
		local h_a, h_b, h_c = debug.gethook()
		debug.sethook()
		file.Write( "ev_warnhistory.txt", glon.encode( HISTORY.PlayerData ) )
		debug.sethook( nil, h_a, h_b, h_c )
	end

	function HISTORY.AddWarning( admin, uid, reason )
		if( not HISTORY.PlayerData[ uid ] ) then
			HISTORY.PlayerData[ uid ] = {}
		end
		
		table.insert( HISTORY.PlayerData[ uid ],
		{	
			EventType = EVNT_WARNING,
			Admin = admin:Nick(),
			Reason = reason,
			Time = os.time()
		} )
	end

	function HISTORY.AddKick( admin, uid, reason )
		if( not HISTORY.PlayerData[ uid ] ) then
			HISTORY.PlayerData[ uid ] = {}
		end
		
		table.insert( HISTORY.PlayerData[ uid ],
		{	
			EventType = EVNT_KICK,
			Admin = admin:Nick(),
			Reason = reason,
			Time = os.time()
		} )
	end

	function HISTORY.AddBan( admin, uid, reason, duration )
		if( not HISTORY.PlayerData[ uid ] ) then
			HISTORY.PlayerData[ uid ] = {}
		end
		
		table.insert( HISTORY.PlayerData[ uid ],
		{	
			EventType = EVNT_BAN,
			Admin = admin:Nick(),
			Reason = reason,
			Duration = duration,
			Time = os.time()
		} )
	end

	function HISTORY.ClearHistory( uid )
		HISTORY.PlayerData[ uid ] = nil
	end
end

local PLUGIN = {}
PLUGIN.Title = "History"
PLUGIN.Description = "Record ban and warning history."
PLUGIN.Author = "Metapyziks"
PLUGIN.ChatCommand = "gethistory"
PLUGIN.Usage = "<player> [all/breif/count a/b/c]"
PLUGIN.Privileges = { "Show History" }


if( SERVER ) then
	function PLUGIN:InitPostEntity()
		HISTORY:LoadHistory()
	end

	function PLUGIN:ShutDown()
		print( "Saving event history..." )
		HISTORY:SaveHistory()
	end
end

function PLUGIN:Call( ply, args )
	if( ply:EV_HasPrivilege( "Show History" ) ) then
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
		
		local history = HISTORY.PlayerData[ pl:UniqueID() ]
		
		if( not history ) then
			evolve:Notify( ply, evolve.colors.red, pl:Nick(), evolve.colors.white, " has no history of bad behaviour." )
			return
		end
		
		if( args[2] == "a" || args[2] == "all" ) then
			local msg = "================\nEvent history for " .. pl:Nick() .. "\n"
			for k, v in pairs( history ) do
				msg = msg .. "    " .. evolve:FormatTime( os.time() - v.Time ) .. " ago: "
				
				if( v.EventType == EVNT_WARNING ) then
					msg = msg .. "WARNED"
				elseif( v.EventType == EVNT_KICK ) then
					msg = msg .. "KICKED"
				elseif( v.EventType == EVNT_BAN ) then
					msg = msg .. "BANNED for " .. evolve:FormatTime( v.Duration )
				end
				
				msg = msg .. " by " .. v.Admin .. " for " .. v.Reason .. "\n"
			end
			ply:PrintMessage( 2, msg .. "================\n" )
			
			evolve:Notify( ply, evolve.colors.red, pl:Nick(), evolve.colors.white, "'s history has been printed in the console." )
		elseif( args[2] == "b" || args[2] == "breif" ) then
			evolve:Notify( ply, evolve.colors.red, "Not implemented!" )
		elseif( args[2] == "c" || args[2] == "count" ) then
			local count = 0
			for k, v in pairs( history ) do
				count = count + 1
			end
			evolve:Notify( ply, evolve.colors.red, pl:Nick(), evolve.colors.white, " has ", evolve.colors.blue, tostring( count ), evolve.colors.white, " events on record." )
		elseif( args[2] == "x" || args[2] == "clear" ) then
			HISTORY.ClearHistory( pl:UniqueID() )
		else
			evolve:Notify( ply, evolve.colors.red, "Invalid argument '" .. args[2] .. "'" )
		end
	else
		evolve:Notify( ply, evolve.colors.red, evolve.constants.notallowed )
	end
end

function PLUGIN:Menu( arg, players )
	if ( arg ) then
		RunConsoleCommand( "ev", "gethistory", players[1], arg )
	else
		return "Show History", evolve.category.administration, {
			{ "All", "all" },
			{ "Breif", "breif" },
			{ "Event Count", "count" },
			{ "Clear history", "clear" },
		}
	end
end

evolve:RegisterPlugin( PLUGIN )