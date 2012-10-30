/*-------------------------------------------------------------------------------------------------------------------------
	Give a weapon to a player
-------------------------------------------------------------------------------------------------------------------------*/

local PLUGIN = {}
PLUGIN.Title = "Give weapon"
PLUGIN.Description = "Give a weapon to a player."
PLUGIN.Author = "Overv"
PLUGIN.ChatCommand = "give"
PLUGIN.Usage = "<players> <weapon>"
PLUGIN.Privileges = { "Give weapon" }

function PLUGIN:Call( ply, args )
	if ( ply:EV_HasPrivilege( "Give weapon" ) ) then
		local players = evolve:FindPlayer( args, ply )
		local wep = args[ #args ]
		
		if ( #args < 2 ) then
			evolve:Notify( ply, evolve.colors.red, "No weapon specified!" )
		elseif ( string.Left( args[2], 7 ) != "weapon_" and !table.HasValue( evolve.privileges, "@" .. args[2] ) ) then
			evolve:Notify( ply, evolve.colors.red, "The specified item isn't a weapon!" )
		else
			if ( #players > 0 ) then
				for _, pl in ipairs( players ) do
					pl:Give( wep )
				end
				
				evolve:Notify( evolve.colors.blue, ply:Nick(), evolve.colors.white, " has given ", evolve.colors.red, evolve:CreatePlayerList( players ), evolve.colors.white, " a " .. wep .. "." )
			else
				evolve:Notify( ply, evolve.colors.red, evolve.constants.noplayers )
			end
		end
	else
		evolve:Notify( ply, evolve.colors.red, evolve.constants.notallowed )
	end
end

function PLUGIN:Menu( arg, players )
	if ( arg ) then
		table.insert( players, arg )
		RunConsoleCommand( "ev", "give", unpack( players ) )
	else
		return "Give", evolve.category.actions, {
			{ "Health Station", 	"weapon_ttt_health_station" },
			{ "Teleporter",			"weapon_ttt_teleport"		},
			{ "UMP Prototype",		"weapon_ttt_stungun" 		},
			{ "Binoculars",			"weapon_ttt_binoculars"		},
			{ "C4 Explosive",		"weapon_ttt_c4"				},
			{ "Visualizer",			"weapon_ttt_cse"			},
			{ "Decoy",				"weapon_ttt_decoy"			},
			{ "Defuser",			"weapon_ttt_defuser"		},
			{ "Flaregun",			"weapon_ttt_flaregun"		},
			{ "Knife",				"weapon_ttt_knife"			},
			{ "Newton Launcher",	"weapon_ttt_push"			},
			{ "Poltergeist",		"weapon_ttt_phammer"		},
			{ "Radio",				"weapon_ttt_radio"			},
			{ "Silenced Pistol",	"weapon_ttt_sipistol"		},
			{ "DNA Scanner",		"weapon_ttt_wtester"		},
			{ "Gauss Rifle",		"weapon_ttt_gaussrifle"		},
			{ "Dartgun",			"weapon_ttt_dartgun"		},
			
			{ "M16",				"weapon_ttt_m16" 			},
			{ "MAC10",				"weapon_zm_mac10" 			},
			{ "Rifle", 				"weapon_zm_rifle" 			},
			{ "Shotgun",			"weapon_zm_shotgun" 		},
			{ "Pistol",				"weapon_zm_pistol" 			},
			{ "Deagle",				"weapon_zm_revolver" 		},
			{ "H.U.G.E-249",		"weapon_zm_sledge" 			}
		}
	end
end

evolve:RegisterPlugin( PLUGIN )