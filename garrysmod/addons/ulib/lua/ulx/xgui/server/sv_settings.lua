--sv_groups -- by Stickly Man!
--Server-side code related to the settings menu.

local settings = {}
function settings.init()
	ULib.ucl.registerAccess( "xgui_gmsettings", "superadmin", "Allows changing of gamemode-specific settings on the settings tab in XGUI.", "XGUI" )
	ULib.ucl.registerAccess( "xgui_svsettings", "superadmin", "Allows changing of server and ULX-specific settings on the settings tab in XGUI.", "XGUI" )
	
	xgui.addDataType( "gimps", function() return ulx.gimpSays end, "xgui_svsettings", 0, -10 )
	xgui.addDataType( "adverts", function() return ulx.adverts end, "xgui_svsettings", 0, -10 )
	xgui.addDataType( "banreasons", function() return ulx.common_kick_reasons end, "xgui_svsettings", 0, -10 )
	xgui.addDataType( "votemaps", function() return settings.votemaps end, "xgui_svsettings", 0, -20 )
	
	ULib.replicatedWritableCvar( "sv_voiceenable", "rep_sv_voiceenable", GetConVarNumber( "sv_voiceenable" ), false, false, "xgui_svsettings" )
	ULib.replicatedWritableCvar( "sv_alltalk", "rep_sv_alltalk", GetConVarNumber( "sv_alltalk" ), false, false, "xgui_svsettings" )
	ULib.replicatedWritableCvar( "ai_disabled", "rep_ai_disabled", GetConVarNumber( "ai_disabled" ), false, false, "xgui_svsettings" )
	ULib.replicatedWritableCvar( "ai_keepragdolls", "rep_ai_keepragdolls", GetConVarNumber( "ai_keepragdolls" ), false, false, "xgui_svsettings" )
	ULib.replicatedWritableCvar( "ai_ignoreplayers", "rep_ai_ignoreplayers", GetConVarNumber( "ai_ignoreplayers" ), false, false, "xgui_svsettings" )
	ULib.replicatedWritableCvar( "sv_gravity", "rep_sv_gravity", GetConVarNumber( "sv_gravity" ), false, false, "xgui_svsettings" )
	ULib.replicatedWritableCvar( "phys_timescale", "rep_phys_timescale", GetConVarNumber( "phys_timescale" ), false, false, "xgui_svsettings" )
	
	function settings.addGimp( ply, args )
		if ULib.ucl.query( ply, "xgui_svsettings" ) then
			ulx.addGimpSay( args[1] )
			xgui.sendDataTable( {}, "gimps" )
			settings.saveGimps()
		end
	end
	xgui.addCmd( "addGimp", settings.addGimp )
	
	function settings.removeGimp( ply, args )
		if ULib.ucl.query( ply, "xgui_svsettings" ) then
			for a, b in ipairs( ulx.gimpSays ) do
				if b == args[1] then
					table.remove( ulx.gimpSays, a )
					xgui.sendDataTable( {}, "gimps" )
					settings.saveGimps()
					return nil
				end
			end
		end
	end
	xgui.addCmd( "removeGimp", settings.removeGimp )
	
	function settings.saveGimps()
		local orig_file = file.Read( "ulx/gimps.txt", "DATA" )
		local comment = xgui.getCommentHeader( orig_file )

		local new_file = comment

		for i, gimpSay in ipairs( ulx.gimpSays ) do
			new_file = new_file .. gimpSay .. "\n"
		end
		
		file.Write( "ulx/gimps.txt", new_file )
	end

	function settings.addBanReason( ply, args )
		if ULib.ucl.query( ply, "xgui_svsettings" ) then
			ulx.addKickReason( args[1] )
			xgui.sendDataTable( {}, "banreasons" )
			settings.saveBanReasons()
		end
	end
	xgui.addCmd( "addBanReason", settings.addBanReason )
	
	function settings.removeBanReason( ply, args )
		if ULib.ucl.query( ply, "xgui_svsettings" ) then
			for a, b in ipairs( ulx.common_kick_reasons ) do
				if b == args[1] then
					table.remove( ulx.common_kick_reasons, a )
					xgui.sendDataTable( {}, "banreasons" )
					settings.saveBanReasons()
					return nil
				end
			end
		end
	end
	xgui.addCmd( "removeBanReason", settings.removeBanReason )
	
	function settings.saveBanReasons()
		local orig_file = file.Read( "ulx/banreasons.txt", "DATA" )
		local comment = xgui.getCommentHeader( orig_file )

		local new_file = comment

		for i, banReason in ipairs( ulx.common_kick_reasons ) do
			new_file = new_file .. banReason .. "\n"
		end
		
		file.Write( "ulx/banreasons.txt", new_file )
	end	
	
	--[1]Message, [2]Delay, [3]GroupName/number, [4]Red, [5]Green, [6]Blue, [7]Length, [8]Hold
	function settings.addAdvert( ply, args )
		if ULib.ucl.query( ply, "xgui_svsettings" ) then
			if args[3] == "<No Group>" then args[3] = nil end
			local color = { r = tonumber( args[4] ), g = tonumber( args[5] ), b = tonumber( args[6] ), a = 255 } or nil
			ulx.addAdvert( args[1], tonumber( args[2] ), args[3], color, tonumber( args[7] ) )
			if args[8] ~= "hold" then
				xgui.sendDataTable( {}, "adverts" )
				settings.saveAdverts()
			end
		end
	end
	xgui.addCmd( "addAdvert", settings.addAdvert )
	
	--[1]Old GroupType, [2]Old GroupName, [3]Old Number (order in group)
	--[4]New Message, [5]New Repeat, [6]New Red, [7]New Green, [8]New Blue, [9]New Length
	 function settings.updateAdvert( ply, args )
		if ULib.ucl.query( ply, "xgui_svsettings" ) then
			local group = ( args[1] == "number" ) and tonumber( args[2] ) or args[2]
			local number = tonumber( args[3] )
			local advert = ulx.adverts[group][number]
			advert.message = args[4]
			advert.rpt = tonumber( args[5] )
			advert.color = { a=255, r=tonumber( args[6] ), g=tonumber( args[7] ), b=tonumber( args[8] ) }
			advert.len = tonumber( args[9] )
			xgui.sendDataTable( {}, "adverts" )
			settings.saveAdverts()
		end
	end
	xgui.addCmd( "updateAdvert", settings.updateAdvert )
	
	--[1]Old GroupType, [2]Old GroupName, [3]Old Number, [4]New Number
	function settings.moveAdvert( ply, args )
		if ULib.ucl.query( ply, "xgui_svsettings" ) then
			local group = ( args[1] == "number" ) and tonumber( args[2] ) or args[2]
			local number = tonumber( args[3] )
			local advert = ulx.adverts[group][number]
			table.remove( ulx.adverts[group], args[3] )
			table.insert( ulx.adverts[group], args[4], advert )
			xgui.sendDataTable( {}, "adverts" )
			settings.saveAdverts()
		end
	end
	xgui.addCmd( "moveAdvert", settings.moveAdvert )

	function settings.renameAdvertGroup( ply, args )
		if ULib.ucl.query( ply, "xgui_svsettings" ) then
			local old = args[1]
			local new = args[2]
			if ulx.adverts[old] then
				for k, v in pairs( ulx.adverts[old] ) do
					ulx.addAdvert( v.message, v.rpt, new, v.color, v.len )
				end
				settings.removeAdvertGroup( ply, { old, type( k ) } )
			end
		end
	end
	xgui.addCmd( "renameAdvertGroup", settings.renameAdvertGroup )
	
	--[1]GroupName, [2]Number, [3]GroupType, [4]"Ignore"
	function settings.removeAdvert( ply, args, hold )
		if ULib.ucl.query( ply, "xgui_svsettings" ) then
			if args[4] == "hold" then hold = true end
			local group = ( args[3] == "number" ) and tonumber( args[1] ) or args[1]
			local number = tonumber( args[2] )
			if number == #ulx.adverts[group] then
				ulx.adverts[group].removed_last = true
			end
			table.remove( ulx.adverts[group], number )
			if #ulx.adverts[group] == 0 then --Remove the existing group if no other adverts exist
				ulx.adverts[group] = nil
				timer.Remove( "ULXAdvert" .. type( group ) .. group )
			end
			if not hold then
				xgui.sendDataTable( {}, "adverts" )
				settings.saveAdverts()
			end
		end
	end
	xgui.addCmd( "removeAdvert", settings.removeAdvert )
	
	function settings.removeAdvertGroup( ply, args, hold )
		if ULib.ucl.query( ply, "xgui_svsettings" ) then
			local group = ( args[2] == "number" ) and tonumber( args[1] ) or args[1]
			for i=#ulx.adverts[group],1,-1 do
				settings.removeAdvert( ply, { group, i, args[2] }, true )
			end
			if not hold then
				xgui.sendDataTable( {}, "adverts" )
				settings.saveAdverts()
			end
		end
	end
	xgui.addCmd( "removeAdvertGroup", settings.removeAdvertGroup )
	
	function settings.saveAdverts()
		local orig_file = file.Read( "ulx/adverts.txt", "DATA" )
		local comment = xgui.getCommentHeader( orig_file )
		local new_file = comment

		for group_name, group_data in pairs( ulx.adverts ) do
			local output = ""
			for i, data in ipairs( group_data ) do
				if not data.len then -- Must be a tsay advert
					output = output .. string.format( '{\n\t"text" %q\n\t"red" %q\n\t"green" %q\n\t"blue" %q\n\t"time" %q\n}\n',
						data.message, data.color.r, data.color.g, data.color.b, data.rpt )
				else -- Must be a csay advert
					output = output .. string.format( '{\n\t"text" %q\n\t"red" %q\n\t"green" %q\n\t"blue" %q\n\t"time_on_screen" %q\n\t"time" %q\n}\n',
						data.message, data.color.r, data.color.g, data.color.b, data.len, data.rpt )
				end
			end

			if type( group_name ) ~= "number" then
				output = string.format( "%q\n{\n\t%s}\n", group_name, output:gsub( "\n", "\n\t" ) )
			end
			new_file = new_file .. output		
		end

		file.Write( "ulx/adverts.txt", new_file )
	end
	
	function settings.addVotemaps( ply, args )
		if ULib.ucl.query( ply, "xgui_svsettings" ) then
			for _, votemap in ipairs( args ) do
				table.insert( ulx.votemaps, votemap )
			end
		end
		settings.saveVotemaps( GetConVar( "ulx_votemapMapmode" ):GetInt() )
		xgui.sendDataTable( {}, "votemaps" )
	end
	xgui.addCmd( "addVotemaps", settings.addVotemaps )
	
	function settings.removeVotemaps( ply, args )
		if ULib.ucl.query( ply, "xgui_svsettings" ) then
			for _, votemap in ipairs( args ) do
				for i, map in ipairs( ulx.votemaps ) do
					if map == votemap then
						table.remove( ulx.votemaps, i )
						break
					end
				end
			end
		end
		settings.saveVotemaps( GetConVar( "ulx_votemapMapmode" ):GetInt() )
		xgui.sendDataTable( {}, "votemaps" )
	end
	xgui.addCmd( "removeVotemaps", settings.removeVotemaps )
	
	function settings.updatevotemaps()  --Populates a table of votemaps that gets sent to the admins.
		settings.votemaps = {}
		for _, v in ipairs( ulx.votemaps ) do
			table.insert( settings.votemaps, v )
		end
	end
	
	function settings.saveVotemaps( mapmode )
		local orig_file = file.Read( "ulx/votemaps.txt", "DATA" )
		local comment = xgui.getCommentHeader( orig_file )
		local new_file = comment

		if mapmode == 1 then --Use all maps EXCEPT what's specified in votemaps.txt
			for _, map in ipairs( ulx.maps ) do
				if not table.HasValue( ulx.votemaps, map ) then
					new_file = new_file .. map .. "\n"
				end
			end
		elseif mapmode == 2 then --Use only the maps specified in votemaps.txt
			for _, map in ipairs( ulx.votemaps ) do
				new_file = new_file .. map .. "\n"
			end
		else 
			Msg( "XGUI: Could not save votemaps- Invalid or nonexistent ulx_votemapMapmode cvar!\n" )
			return
		end
		
		file.Write( "ulx/votemaps.txt", new_file )
		settings.updatevotemaps()
	end
end

function settings.postinit()
	settings.updatevotemaps()

	local function votemapCvarUpdate( sv_cvar, cl_cvar, ply, old_val, new_val )
		if cl_cvar == "ulx_cl_votemapmapmode" then
			settings.saveVotemaps( tonumber( new_val ) )
		end
	end
	hook.Add( "ULibReplicatedCvarChanged", "XGUI_CatchVotemapCvarUpdate", votemapCvarUpdate )
end

xgui.addSVModule( "settings", settings.init, settings.postinit )