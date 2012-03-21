if( SERVER ) then
	AddCSLuaFile( "scoreboard_override.lua" )
end
if( CLIENT ) then
	function OverrideScoreboard()
		local namecolor = {
		   default = Color(255, 255, 255, 255),
		   admin = Color(220, 180, 0, 255),
		   dev = Color(100, 240, 105, 255)
		};

		function GAMEMODE:TTTScoreboardColorForPlayer(ply)
		   if not IsValid(ply) then return namecolor.default end
			
			if( evolve ) then
				if( evolve.ranks ) then
					if( evolve.ranks[ ply:EV_GetRank() ] ) then
						return evolve.ranks[ ply:EV_GetRank() ].Color
					end
				end
			end
			
		   if ply:SteamID() == "STEAM_0:0:1963640" then
			  return namecolor.dev
		   elseif ply:IsAdmin() and GetGlobalBool("ttt_highlight_admins", true) then
			  return namecolor.admin
		   end
		   return namecolor.default
		end
	end

	timer.Simple( 1.0, OverrideScoreboard )
end