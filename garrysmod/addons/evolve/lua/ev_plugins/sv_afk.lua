/*-------------------------------------------------------------------------------------------------------------------------
	!afk command
-------------------------------------------------------------------------------------------------------------------------*/

local PLUGIN = {}
PLUGIN.Title = "AFK"
PLUGIN.Description = "Show your status as AFK."
PLUGIN.Author = "MadDog"
PLUGIN.ChatCommand = "afk"
PLUGIN.Privileges = { "Kick if AFK" }

if SERVER then
	CreateConVar("ev_afktime","10") // How many minutes before a player gets kicked for being afk
	function PLUGIN:PlayerUse( ply ) ply.EV_AFKTimer = CurTime() end
	function PLUGIN:KeyRelease( ply ) ply.EV_AFKTimer = CurTime() end
	function PLUGIN:PlayerSay( ply, msg ) ply.EV_AFKTimer = CurTime() end

	function PLUGIN:Think()
		if ( self.NextAFKCheck and self.NextAFKCheck > CurTime() ) then return end
		self.NextAFKCheck = CurTime() + 0.1

		for _, ply in pairs( player.GetAll() ) do
			if ( ply:EyeAngles() != ply.EV_AFKAngles or ply:GetNWBool( "EV_Chatting", false) ) then
				ply.EV_AFKTimer = CurTime()
				ply.EV_AFKAngles = ply:EyeAngles()
			end

			if (ply:GetNWBool("EV_AFK") == true and !ply.AFK) then
				evolve:Notify( evolve.colors.blue, ply:Nick(), evolve.colors.white, " is now AFK.")
				ply.AFK = true
			elseif (ply:GetNWBool("EV_AFK") == false and ply.AFK == true) then
				evolve:Notify( evolve.colors.blue, ply:Nick(), evolve.colors.white, " is now back.")
				ply.AFK = false
			end

			--auto kick after 20min
			if (!ply:IsAdmin() and ply:EV_HasPrivilege( "Kick if AFK" )) and ply.EV_AFKTimer < CurTime() - ((60*60) * GetConVar("ev_afktime"):GetInt()) then
				evolve:Notify( evolve.colors.blue, ply:Nick(), evolve.colors.white, " has been kicked with the reason \"AFK\"." )

				if ( gatekeeper ) then
					gatekeeper.Drop( ply:UserID(), "Kicked: AFK Timer" )
				else
					ply:Kick( "AFK Timer" )
				end
			end
		end
	end

end

evolve:RegisterPlugin( PLUGIN )