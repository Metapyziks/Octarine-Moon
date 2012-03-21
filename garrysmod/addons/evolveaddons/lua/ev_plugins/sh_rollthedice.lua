/*-------------------------------------------------------------------------------------------------------------------------
	Roll the dice
-------------------------------------------------------------------------------------------------------------------------*/

local PLUGIN = {}
PLUGIN.Title = "Roll the Dice"
PLUGIN.Description = "Roll a dice and see what happens!"
PLUGIN.Author = "Overv, modified by Metapyziks"
PLUGIN.ChatCommand = "rtd"
PLUGIN.Privileges = { "Roll the Dice" }

function PLUGIN:Call( ply, args )
	if ( ply:EV_HasPrivilege( "Roll the Dice" ) and ValidEntity( ply ) and ply:IsTerror() and GetRoundState() ~= ROUND_PREP ) then			
		if ( ( ply.EV_NextDiceRoll or 0 ) < CurTime() ) then
			evolve:Notify( evolve.colors.blue, ply:Nick(), evolve.colors.white, " has rolled the dice and ", evolve.colors.red, self:RollTheDice( ply ), evolve.colors.white, "!" )
			ply.EV_NextDiceRoll = CurTime() + 60
			timer.Simple( 60, function() evolve:Notify( ply, evolve.colors.blue, "You may now roll the dice!" ) end )
		else
			evolve:Notify( ply, evolve.colors.red, "Wait a little longer before rolling the dice again!" )
		end
	else
		evolve:Notify( ply, evolve.colors.red, evolve.constants.notallowed )
	end
end

function PLUGIN:PlayerSpawn( ply )
	ply.EV_ProvenInnocent = false
end

local weapons = 
{
	{ "weapon_ttt_health_station", 	"Health Station" 	},
	{ "weapon_ttt_teleport",		"Teleporter"		},
	{ "weapon_ttt_stungun",			"UMP Prototype"		},
	
	{ "weapon_ttt_m16",				"M16"				},
	{ "weapon_zm_mac10",			"MAC10"				},
	{ "weapon_zm_rifle",			"Rifle"				},
	{ "weapon_zm_shotgun",			"Shotgun"			},
	{ "weapon_zm_pistol",			"Pistol"			},
	{ "weapon_zm_revolver",			"Deagle"			},
	{ "weapon_zm_sledge",			"H.U.G.E-249"		}
}

local only_huges_for_johny = CreateConVar("rtd_only_huges_for_johny", "0")

function PLUGIN:RollTheDice( ply )

	local choice = math.random( 1, 7 )
	local give_huge = false
	
	if( only_huges_for_johny:GetBool() and ply:SteamID() == "STEAM_0:1:11957130" ) then
		choice = 6
		give_huge = true
	end
	
	if ( choice == 1 ) then
		if( ply:Health() == 100 ) then
			return self:RollTheDice( ply )
		end
	
		local hp = math.random( 1, 10 ) * 5
		if( hp + ply:Health() >= 100 ) then
			hp = 100 - ply:Health()
		end
		
		ply:SetHealth( ply:Health() + hp )
		
		return "received " .. hp .. " health"
	elseif ( choice == 2 ) then
		local hp = math.random( 1, 10 ) * 5
		if( hp >= ply:Health()) then
			hp = ply:Health() - 1
		end
		
		ply:SetHealth( ply:Health() - hp )
		
		return "lost " .. hp .. " health"
	elseif ( choice == 3 ) then
		if( not ply:IsTraitor()) then
			local proven = 0
			local tot = 0
			for _, pl in ipairs( player.GetAll()) do
				if( pl:IsTerror() and not pl:IsTraitor()) then
					tot = tot + 1
					if( pl.EV_ProvenInnocent ) then
						proven = proven + 1
					end
				end
			end
			if( ply.EV_ProvenInnocent or proven / tot > 0.333 or math.random( 1, 4 ) ~= 1 ) then
				return self:RollTheDice( ply )
			end
			ply.EV_ProvenInnocent = true
			return "was proven innocent"
		else
			return self:RollTheDice( ply )
		end
	elseif ( choice == 4 ) then
		local has_tester = false
		
		if( ply:HasWeapon( "weapon_ttt_wtester" )) then
			has_tester = true
		end
	
		ply:StripWeapons()
		ply:Give( "weapon_zm_improvised" )
		ply:Give( "weapon_ttt_unarmed" )
		ply:Give( "weapon_zm_carry" )
		
		if( has_tester ) then
			ply:Give( "weapon_ttt_wtester" )
		end
		
		return "had his weapons stripped"
	elseif ( choice == 5 ) then
		if( ply:IsTraitor() or ply:IsActiveDetective()) then
			ply:AddCredits( 1 )
			if( ply:IsActiveDetective()) then
				return "received a credit"
			else
				evolve:Notify( ply, evolve.colors.red, "You secretly received an equiptment credit!" )
			end
		end
		
		return "got nothing"
	elseif ( choice == 6 ) then
		
		local weapon_str = nil
		
		if( give_huge ) then
			weapon_str = { "weapon_zm_sledge", "H.U.G.E-249" }
		end
		
		while( weapon_str == nil ) do
		
			weapon_str = table.Random( weapons )
			
			if( ply:HasWeapon( weapon_str[ 1 ] )) then
				weapon_str = nil
			end
		end
		
		weapon = ents.Create( weapon_str[ 1 ] )
		weapon:SetPos( ply:GetPos())
		weapon:Spawn()
		
		return "received a " .. weapon_str[ 2 ]
	elseif ( choice == 7 ) then
		ply:Lock()
		timer.Simple( math.random( 10, 15 ), function() ply:UnLock() end )
		
		return "lost the ability to move for some time"
	end
end

evolve:RegisterPlugin( PLUGIN )