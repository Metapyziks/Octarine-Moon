-- Load our configs

local function init()
	-- Load our banned users
	if file.Exists( "cfg/banned_user.cfg", "GAME" ) then
		ULib.execFile( "cfg/banned_user.cfg", "GAME" )
	end
end
hook.Add( "Initialize", "ULXInitialize", init )

local function doMainCfg( path )
	ULib.execString( ULib.stripComments( file.Read( path, "DATA" ), ";" ) )
end

local function doDownloadCfg( path )
	local lines = ULib.explode( "\n+", ULib.stripComments( file.Read( path, "DATA" ), ";" ) )
	for _, line in ipairs( lines ) do
		line = line:Trim()
		if line:len() > 0 then
			ulx.addForcedDownload( ULib.stripQuotes( line ) )
		end
	end
end

local function doGimpCfg( path )
	ulx.clearGimpSays()
	local lines = ULib.explode( "\n+", ULib.stripComments( file.Read( path, "DATA" ), ";" ) )
	for _, line in ipairs( lines ) do
		line = line:Trim()
		if line:len() > 0 then
			ulx.addGimpSay( ULib.stripQuotes( line ) )
		end
	end
end

local function doAdvertCfg( path )
	local data_root, err = ULib.parseKeyValues( ULib.stripComments( file.Read( path, "DATA" ), ";" ) )
	if not data_root then Msg( "[ULX] Error in advert config: " .. err .. "\n" ) return end

	for group_name, row in pairs( data_root ) do
		if type( group_name ) == "number" then -- Must not be a group
			local color = Color( tonumber( row.red ) or ULib.DEFAULT_TSAY_COLOR.r, tonumber( row.green ) or ULib.DEFAULT_TSAY_COLOR.g, tonumber( row.blue ) or ULib.DEFAULT_TSAY_COLOR.b )
			ulx.addAdvert( row.text or "NO TEXT SUPPLIED FOR THIS ADVERT", tonumber( row.time ) or 300, _, color, tonumber( row.time_on_screen ) )
		else -- Must be a group
			if type( row ) ~= "table" then Msg( "[ULX] Error in advert config: Adverts are not properly formatted!\n" ) return end
			for i=1, #row do
				local row2 = row[ i ]
				local color = Color( tonumber( row2.red ) or 151, tonumber( row2.green ) or 211, tonumber( row2.blue ) or 255 )
				ulx.addAdvert( row2.text or "NO TEXT SUPPLIED FOR THIS ADVERT", tonumber( row2.time ) or 300, group_name, color, tonumber( row2.time_on_screen ) )
			end
		end
	end
end

local function doVotemapsCfg( path )
	ulx.clearVotemaps()
	local lines = ULib.explode( "\n+", ULib.stripComments( file.Read( path, "DATA" ), ";" ) )
	for _, line in ipairs( lines ) do
		line = line:Trim()
		if line:len() > 0 then
			ulx.votemapAddMap( line )
		end
	end
end

local function doReasonsCfg( path )
	local lines = ULib.explode( "\n+", ULib.stripComments( file.Read( path, "DATA" ), ";" ) )
	for _, line in ipairs( lines ) do
		line = line:Trim()
		if line:len() > 0 then
			ulx.addKickReason( ULib.stripQuotes( line ) )
		end
	end
end

local function doCfg()
	local things_to_execute = { -- Indexed by name, value of function to execute
		["config.txt"] = doMainCfg,
		["downloads.txt"] = doDownloadCfg,
		["gimps.txt"] = doGimpCfg,
		["adverts.txt"] = doAdvertCfg,
		["votemaps.txt"] = doVotemapsCfg,
		["banreasons.txt"] = doReasonsCfg,
	}

	local gamemode_name = GAMEMODE.Name:lower()
	local map_name = game.GetMap()

	for filename, fn in pairs( things_to_execute ) do
		-- Global config
		if file.Exists( "ulx/" .. filename, "DATA" ) then
			fn( "ulx/" .. filename )
		end

		-- Per gamemode config
		if file.Exists( "ulx/gamemodes/" .. gamemode_name .. "/" .. filename, "DATA" ) then
			fn( "ulx/gamemodes/" .. gamemode_name .. "/" .. filename )
		end

		-- Per map config
		if file.Exists( "ulx/maps/" .. map_name .. "/" .. filename, "DATA" ) then
			fn( "ulx/maps/" .. map_name .. "/" .. filename )
		end
	end

	ULib.queueFunctionCall( hook.Call, ulx.HOOK_ULXDONELOADING, _ ) -- We're done loading! Wait a tick so the configs load.

	if not game.IsDedicated() then
		hook.Remove( "PlayerInitialSpawn", "ULXDoCfg" )
	end
end

if game.IsDedicated() then
	hook.Add( "Initialize", "ULXDoCfg", doCfg, 20 )
else
	hook.Add( "PlayerInitialSpawn", "ULXDoCfg", doCfg, 20 ) -- TODO can we make this initialize too?
end
