/*-------------------------------------------------------------------------------------------------------------------------
	Allow admins to print damage logs
-------------------------------------------------------------------------------------------------------------------------*/

local PLUGIN = {}
PLUGIN.Title = "Damagelog"
PLUGIN.Description = "Outputs a damage log of the last round"
PLUGIN.Author = "Metapyziks"
PLUGIN.ChatCommand = "damagelog"

if( SERVER ) then
	function PLUGIN:Call( ply, args )
		if ( not ValidEntity( ply ) ) or ply:IsSuperAdmin() or GetRoundState() != ROUND_ACTIVE then
			ply:ConCommand( "ttt_print_damagelog" )
			evolve:Notify( ply, evolve.colors.white, "Damage log printed in console." )
		else
			evolve:Notify( ply, evolve.colors.red, "You are not allowed to print the damage log until the round ends!" )
		end
	end
end

evolve:RegisterPlugin( PLUGIN )