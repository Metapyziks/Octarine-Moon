local CATEGORY_NAME = "Menus"

if file.Exists( "lua/ulx/modules/cl/motdmenu.lua", "GAME" ) or ulx.motdmenu_exists then
	CreateConVar( "motdfile", "ulx_motd.txt" ) -- Garry likes to add and remove this cvar a lot, so it's here just in case he removes it again.
	local function sendMotd( ply, showMotd )
		if showMotd == "1" then -- Assume it's a file
			if ply.ulxHasMotd then return end -- This player already has the motd
			if not file.Exists( GetConVarString( "motdfile" ), "GAME" ) then return end -- Invalid
			local f = file.Read( GetConVarString( "motdfile" ), "GAME" )

			ULib.clientRPC( ply, "ulx.rcvMotd", false, f )

			ply.ulxHasMotd = true

		else -- Assume URL
			ULib.clientRPC( ply, "ulx.rcvMotd", true, showMotd )
			ply.ulxHasMotd = nil
		end
	end

	local function showMotd( ply )
		local showMotd = GetConVarString( "ulx_showMotd" )
		if showMotd == "0" then return end
		if not ply:IsValid() then return end -- They left, doh!

		sendMotd( ply, showMotd )
		ULib.clientRPC( ply, "ulx.showMotdMenu" )
	end
	hook.Add( "PlayerInitialSpawn", "showMotd", showMotd )

	function ulx.motd( calling_ply )
		if not calling_ply:IsValid() then
			Msg( "You can't see the motd from the console.\n" )
			return
		end

		if GetConVarString( "ulx_showMotd" ) == "0" then
			ULib.tsay( ply, "The MOTD has been disabled on this server." )
			return
		end

		showMotd( calling_ply )
	end
	local motdmenu = ulx.command( CATEGORY_NAME, "ulx motd", ulx.motd, "!motd" )
	motdmenu:defaultAccess( ULib.ACCESS_ALL )
	motdmenu:help( "Show the message of the day." )
	if SERVER then ulx.convar( "showMotd", "1", " <0/1/(url)> - Shows the motd to clients on startup. Can specify URL here.", ULib.ACCESS_ADMIN ) end
end
