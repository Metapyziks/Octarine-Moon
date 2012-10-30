/*-------------------------------------------------------------------------------------------------------------------------
	SWEP Restriction
-------------------------------------------------------------------------------------------------------------------------*/

local PLUGIN = {}
PLUGIN.Title = "SWEP Restriction"
PLUGIN.Description = "Restricts SWEP Spawning"
PLUGIN.Author = "Helix Nebula"
PLUGIN.Privileges = { "SWEP" }

function PLUGIN:PlayerGiveSWEP( ply, class, weapon )
	return ply:EV_HasPrivilege( "SWEP" )
end

function PLUGIN:PlayerSpawnSWEP( ply, class, weapon )
	return ply:EV_HasPrivilege( "SWEP" )
end

function PLUGIN:PlayerSpawnSENT( ply, name )
	if string.find(name, "weapon_") then
		return ply:EV_HasPrivilege( "SWEP" )
	end
end

evolve:RegisterPlugin( PLUGIN )