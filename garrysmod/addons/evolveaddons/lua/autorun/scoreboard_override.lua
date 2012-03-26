if( SERVER ) then
	AddCSLuaFile( "scoreboard_override.lua" )
	
	local valid_tags = 
	{
		"sb_tag_none",
		"sb_tag_friend",
		"sb_tag_susp",
		"sb_tag_avoid",
		"sb_tag_kill",
		"sb_tag_miss"
	}
	
	local function recieveDetectiveRecommendation( ply, cmd, args )
		if IsValid( ply ) and ply:IsTerror() and ply:IsActiveDetective() and ply:Alive() then
			local plId = args[ 1 ]
			local tag = args[ 2 ]
			
			if table.HasValue( valid_tags, tag ) then
				local pl = ents.GetByIndex( plId )
				if IsValid( pl ) and pl:IsPlayer() and not pl:IsActiveDetective() then
					Msg( ply:Nick() .. " has tagged " .. pl:Nick() .. " as " .. tag .. ".\n" )
					pl:SetNWString( "DetectiveTag", tag )
				end
			end
		end
	end
	concommand.Add( "ttt_detective_tag", recieveDetectiveRecommendation )
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