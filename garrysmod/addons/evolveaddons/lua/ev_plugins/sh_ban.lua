/*-------------------------------------------------------------------------------------------------------------------------
	Ban a player
		To do: Clean up this piece of shit.
-------------------------------------------------------------------------------------------------------------------------*/

local PLUGIN = {}
PLUGIN.Title = "Ban"
PLUGIN.Description = "Ban a player."
PLUGIN.Author = "Overv"
PLUGIN.ChatCommand = "ban"
PLUGIN.Usage = "<player> [time=5] [reason]"
PLUGIN.Privileges = { "Hour Ban", "Ban", "Permaban" }

function FormatDuration( str )
	str = string.TrimLeft( str )
	
	if( string.len( str ) == 0 ) then
		return 0
	end

	local len = string.len( str )
	local numEnd = string.find( str, "%a" )
	
	if( numEnd == nil || numEnd > len ) then
		return tonumber( str )
	else
		local num = tonumber( string.TrimRight( string.sub( str, 1, numEnd - 1 ) ) )
		
		if( num == nil ) then
			return -1
		end
		
		local scale = string.sub( str, numEnd, numEnd )
		
		if( scale == "s" ) then
			num = num / 60
		elseif( scale == "h" ) then
			num = num * 60
		elseif( scale == "d" ) then
			num = num * 60 * 24 
		elseif( scale == "w" ) then
			num = num * 60 * 24 * 7
		end
		
		if( numEnd == string.len( str ) ) then
			return num
		end
		
		local add = FormatDuration( string.sub( str, numEnd + 1 ) )
		
		if( add == -1 ) then
			return -1
		else
			return num + add
		end
	end
end

function PLUGIN:Call( ply, args )
	if( #args < 2 ) then
		args[ 2 ] = "5"
	end

	local dur = FormatDuration( args[ 2 ] )
	
	if( dur == -1 or dur == nil ) then
		evolve:Notify( ply, evolve.colors.white, "The given duration of ", evolve.colors.red, args[ 2 ], evolve.colors.white, " is invalid." )
		
		return
	end

	local time = math.Clamp( dur, 0, 525960 )
	
	if ( ( time > 0 and ( time <= 60 and ply:EV_HasPrivilege( "Hour Ban" ) ) or ply:EV_HasPrivilege( "Ban" ) ) or ( time == 0 and ply:EV_HasPrivilege( "Permaban" ) ) ) then
		/*-------------------------------------------------------------------------------------------------------------------------
			Get the unique ID to ban
		-------------------------------------------------------------------------------------------------------------------------*/
		
		local uid, pl
		
		if ( string.match( args[1] or "", "STEAM_[0-5]:[0-9]:[0-9]+" ) ) then
			uid = evolve:UniqueIDByProperty( "SteamID", args[1] )
			pl = player.GetByUniqueID( uid )
		else
			pl = evolve:FindPlayer( args[1] )
			
			if ( #pl > 1 ) then
				evolve:Notify( ply, evolve.colors.white, "Did you mean ", evolve.colors.red, evolve:CreatePlayerList( pl, true ), evolve.colors.white, "?" )
				
				return
			elseif ( #pl == 1 ) then
				pl = pl[1]
				uid = pl:UniqueID()
			end
		end
		
		/*-------------------------------------------------------------------------------------------------------------------------
			Make sure the player exists and we're allowed to ban it
		-------------------------------------------------------------------------------------------------------------------------*/
		
		if ( !uid or ( tonumber( evolve.ranks[ ply:EV_GetRank() ].Immunity ) <= tonumber( evolve.ranks[ evolve:GetProperty( uid, "Rank", "guest" ) ].Immunity ) and ply != NULL ) ) then
			evolve:Notify( ply, evolve.colors.red, evolve.constants.noplayers2 )
			return
		end
		
		/*-------------------------------------------------------------------------------------------------------------------------
			Gather data and perform ban
		-------------------------------------------------------------------------------------------------------------------------*/
		
		local length = time * 60
		local reason = table.concat( args, " ", 3 )
			if ( #reason == 0 ) then reason = "No reason specified" end
		local nick = evolve:GetProperty( uid, "Nick" )
		
		evolve:Ban( uid, length, reason, ply:UniqueID() )
		HISTORY.AddBan( ply, uid, reason, length )
		
		if ( length == 0 ) then
			evolve:Notify( evolve.colors.blue, ply:Nick(), evolve.colors.white, " banned ", evolve.colors.red, nick, evolve.colors.white, " permanently (" .. reason .. ")." )
		else
			evolve:Notify( evolve.colors.blue, ply:Nick(), evolve.colors.white, " banned ", evolve.colors.red, nick, evolve.colors.white, " for " .. length / 60 .. " minutes (" .. reason .. ")." )
		end
	else
		evolve:Notify( ply, evolve.colors.red, evolve.constants.notallowed )
	end
end

if ( SERVER ) then
	function PLUGIN:InitPostEntity()
		for uid, data in pairs( evolve.PlayerInfo ) do
			if ( evolve:IsBanned( uid ) ) then
				game.ConsoleCommand( "banid " .. ( data.BanEnd - os.time() ) / 60 .. " " .. data.SteamID .. "\n" )
			end
		end
	end
end

function PLUGIN:Menu( arg, players )
	if ( arg ) then
		RunConsoleCommand( "ev", "ban", players[1], arg )
	else
		return "Ban", evolve.category.administration, {
			{ "5 minutes", "5" },
			{ "10 minutes", "10" },
			{ "15 minutes", "15" },
			{ "30 minutes", "30" },
			{ "1 hour", "60" },
			{ "2 hours", "120" },
			{ "4 hours", "240" },
			{ "12 hours", "720" },
			{ "One day", "1440" },
			{ "Two days", "2880" },
			{ "One week", "10080" },
			{ "Two weeks", "20160" },
			{ "One month", "43200" },
			{ "One year", "525600" },
			{ "Permanently", "0" }
		}, "Time"
	end
end

evolve:RegisterPlugin( PLUGIN )