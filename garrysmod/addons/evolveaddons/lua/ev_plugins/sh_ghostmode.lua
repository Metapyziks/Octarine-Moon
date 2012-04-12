/*-------------------------------------------------------------------------------------------------------------------------
	Run a console command on someone
-------------------------------------------------------------------------------------------------------------------------*/

local PLUGIN = {}
PLUGIN.Title = "Ghost Mode"
PLUGIN.Description = "Makes traitors invisible with 1 health."
PLUGIN.Author = "Metapyziks"
PLUGIN.ChatCommand = "ghostmode"
PLUGIN.Usage = "[1/0]"
PLUGIN.Privileges = { "Ghost Mode" }

PLUGIN.EnabledConVar = CreateConVar( "ttt_ghostmode_enabled", "0" )
PLUGIN.HealthConVar = CreateConVar( "ttt_ghostmode_health", "1" )

function PLUGIN:Call( ply, args )
	if ( ply:EV_HasPrivilege( "Ghost Mode" ) ) then
		local wasenabled = self.EnabledConVar:GetBool()
		if #args == 0 or ( args[ 1 ] == "1" ) == self.EnabledConVar:GetBool() then
			local enabled = not wasenabled
			if enabled then
				game.ConsoleCommand( "ttt_ghost_mode 1" )
			else
				game.ConsoleCommand( "ttt_ghost_mode 0" )
			end
		end
	else
		evolve:Notify( ply, evolve.colors.red, evolve.constants.notallowed )
	end
end

if SERVER then
	local function prepareRound()
		if self.EnabledConVar:GetBool() then
			for _, ply in ipairs( player.GetAll() ) do
				if ply:GetMWBool( "EV_Ghosted", false ) then
					ply:SetRenderMode( RENDERMODE_NORMAL )
					ply:SetColor( 255, 255, 255, 255 )
					ply:SetCollisionGroup( COLLISION_GROUP_PLAYER )
					for _, w in ipairs( ply:GetWeapons() ) do
						w:SetRenderMode( RENDERMODE_NORMAL )
						w:SetColor( 255, 255, 255, 255 )
					end
					ply:SetNWBool( "EV_Ghosted", false )
				end
			end
		end
	end
	hook.Add( "TTTPrepareRound", "TTTPrepareRound_GhostMode", prepareRound )

	local function roundStart()
		if self.EnabledConVar:GetBool() then
			local health = self.HealthConVar:GetInt()
			for _, ply in ipairs( player.GetAll() ) do
				if ply:IsActiveTraitor() then
					ply:SetHealth( health )
					ply:SetRenderMode( RENDERMODE_NONE )
					ply:SetCollisionGroup( COLLISION_GROUP_WEAPON )
					ply:SetColor( 255, 255, 255, 0 )					
					for _, w in ipairs( ply:GetWeapons() ) do
						w:SetRenderMode( RENDERMODE_NONE )
						w:SetColor( 255, 255, 255, 0 )
					end
					ply:SetNWBool( "EV_Ghosted", true )
					ply:SetNWBool( "disguised", true )
				end
			end
		end
	end
	hook.Add( "TTTBeginRound", "TTTBeginRound_GhostMode", roundStart )
end

evolve:RegisterPlugin( PLUGIN )