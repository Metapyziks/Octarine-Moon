/*
Advert 3, by Miss Saria Parkar. I swear this is better than the last one!
Includes commands for adding, removing, toggling, and listing adverts. Colour and time settings, and advert preservation
over server restarts, via a file (ev_adverts.txt in garrysmod/data). This file will be GLON encoded, please don't try to
edit it manually.
Example commands
/advert3 add meep 0 255 100 60 "This is a message!" ( where "meep" is any name ID, colour (R = 0, G = 255, B = 100) and time is 60(seconds))
		Already existing IDs will be overwritten.
/advert3 remove meep  (remove advert via the ID you created it with
/advert3 toggle meep [1/0](allows you to stop an advert from running without removing it. 1 for on, 0 for off, no number will reverse whatever toggle state it's in.
/advert3 list  (displays current adverts and the toggled states)

Requires ranks have Advert 3 permission set to use.

A menu interface for this is available, which greatly simplifies advert managing. (tab_advert3.lua)

Any problems. Please email me at thatcutekiwi@gmail.com Thanks!
*/

require("glon")

local PLUGIN = {}
PLUGIN.Title = "Advert3"
PLUGIN.Description = "Add, remove, modify adverts."
PLUGIN.Author = "SariaFace"
PLUGIN.ChatCommand = "advert3"
PLUGIN.Usage = "[add;remove;list;toggle][advert id][r][g][b][interval][message]"
PLUGIN.Privileges = { "Advert 3" }

if (SERVER) then
	local adFileName= "ev_adverts.txt"
	local function writeToFile(data)
		file.Write(adFileName, glon.encode(data))
	end

	adverts = {}
	adverts.Stored = {}
	if (#file.Find(adFileName, "DATA") > 0) then
		adverts.Stored = glon.decode(file.Read(adFileName, "DATA"))
		for k,v in pairs(adverts.Stored) do
			timer.Create("Advert_"..k, v.Time, 0, function()
				if (#player.GetAll() > 0) then
					evolve:Notify(v.Colour, v.Msg)
				end
			end)
			if (v.OnState == false) then
				timer.Pause("Advert_"..k)
			end
		end
	end


	------------------------------------------------------------------------------------
	function adverts.add(info)
		info[1] = info[1]:lower()
		if #info > 6 then
			info[6] = table.concat(info, " ", 6, #info)
		elseif #info < 6 then
			return "Advert: Incorrect arguements for Add"
		end
		local ow
		if adverts.Stored[info[1]] then
			ow = "Overwriting advert \""..adverts.Stored[info[1]].."\"."
		end

		adverts.Stored[info[1]] = {
			["Colour"] = Color(tonumber(info[2]),tonumber(info[3]),tonumber(info[4])),
			["Time"] = info[5],
			["Msg"] = info[6],
			["OnState"] = true
		}
		timer.Create("Advert_"..info[1], adverts.Stored[info[1]].Time, 0, function()
			if (#player.GetAll() > 0) then
				evolve:Notify(adverts.Stored[info[1]].Colour, adverts.Stored[info[1]].Msg)
			end
		end)
		writeToFile(adverts.Stored)
		return ow or "Advert created."
	end
	----------------------------------------------------------------------------------------
	function adverts.remove(info)
		if adverts.Stored[info[1]] then
			adverts.Stored[info[1]] = nil
			timer.Remove("Advert_"..info[1])
		else
			return "Advert: ID not found."
		end
		writeToFile(adverts.Stored)
		return "Advert: "..info[1].." has been removed."
	end
	-------------------------------------------------------------------------------------------
	function adverts.list()
		local str = "Registered adverts: "
		for k,v in pairs(adverts.Stored) do
			str = str..k.." On-"..tostring(v.OnState)..". "
		end
		return str or "No adverts loaded."
	end
	--------------------------------------------------------------------------------------------
	function adverts.toggle(args)
		if #args > 2 then return "Advert: Incorrect arguements for toggling" end
		if adverts.Stored[args[1]:lower()] then
			if !args[2] then
				adverts.Stored[args[1]].OnState= !adverts.Stored[args[1]].OnState
				timer.Toggle("Advert_"..args[1])
			elseif (args[2]=="1") then
				adverts.Stored[args[1]].OnState = true
				timer.UnPause("Advert_"..args[1])
			else
				adverts.Stored[args[1]].OnState = false
				timer.Pause("Advert_"..args[1])
			end
			return "Advert "..args[1].."'s On-State has been set to "..tostring(adverts.Stored[args[1]].OnState)
		else
			return "Advert: ID not found."
		end
	end
end

--===================================================================================--
function PLUGIN:Call( ply, args )
	if (SERVER) then
		if (ply:EV_HasPrivilege( "Advert 3" )) then
			local retStr
			if #args == 0 then
				evolve:Notify(ply, evolve.colors.red, "Advert Error: No arguements")
				return
			end
			local command = args[1]:lower()
			table.remove(args, 1)
			if adverts[command] then
				retStr = adverts[command](args)
			else
				retStr = "Advert: Incorrect command specified"
			end

			evolve:Notify(ply, evolve.colors.red, "Advert: "..retStr)
		else
			evolve:Notify(ply, evolve.colors.red, "You don't not have access to this command")
		end
	end
end
evolve:RegisterPlugin( PLUGIN )