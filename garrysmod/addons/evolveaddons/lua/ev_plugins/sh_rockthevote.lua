/*-------------------------------------------------------------------------------------------------------------------------
	Rock the Vote
-------------------------------------------------------------------------------------------------------------------------*/

local PLUGIN = {}
PLUGIN.Title = "Rock the Vote"
PLUGIN.Description = "Rock the vote to change the map!"
PLUGIN.Author = "Metapyziks"
PLUGIN.ChatCommand = "rtv"
PLUGIN.Privileges = { "Rock the Vote", "Force Vote" }

PLUGIN.AdminForce = false
PLUGIN.VoteQueue = {}

if SERVER then
	function PLUGIN:Call( ply, args )
		if ( #args > 0 and args[ 1 ] == "force" and ( not ValidEntity( ply ) or ply:EV_HasPrivilege( "Force Vote" ) ) ) then
			self.AdminForce = ( #args == 1 or args[ 2 ] == "1" )
			if ( self.AdminForce ) then
				evolve:Notify( evolve.colors.blue, ply:Nick() .. " has forced a map vote" )
			else
				evolve:Notify( evolve.colors.blue, ply:Nick() .. " has cancelled a map vote" )
			end
		elseif ( ply:EV_HasPrivilege( "Rock the Vote" ) and ValidEntity( ply ) ) then
			local wantsVote = ply:GetNWBool( "WantsVote" ) or table.HasValue( self.VoteQueue, ply )
			
			if( not wantsVote ) then
				table.insert( self.VoteQueue, ply )
				evolve:Notify( evolve.colors.blue, ply:Nick() .. " has voted to change map" )
			else
				evolve:Notify( ply, evolve.colors.red, "You have already voted to change map!" )
			end
		else
			evolve:Notify( ply, evolve.colors.red, evolve.constants.notallowed )
		end
	end

	function PLUGIN:Think()
		if( GetRoundState() == ROUND_ACTIVE ) then
			for k, ply in ipairs( player.GetAll()) do
				if( ply:GetNWBool( "WantsVote" )) then
					table.insert( self.VoteQueue, ply )
					ply:SetNWBool( "WantsVote", false )
				end
			end
		elseif( self.AdminForce ) then
			for k, ply in ipairs( player.GetAll() ) do
				ply:SetNWBool( "WantsVote", true )
			end
		elseif( #self.VoteQueue > 0 ) then
			for k, ply in ipairs( self.VoteQueue ) do
				ply:SetNWBool( "WantsVote", true )
			end
			
			self.VoteQueue = {}
		end	
	end
end

evolve:RegisterPlugin( PLUGIN )