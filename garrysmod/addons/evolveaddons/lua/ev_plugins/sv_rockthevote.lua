/*-------------------------------------------------------------------------------------------------------------------------
	Rock the Vote
-------------------------------------------------------------------------------------------------------------------------*/

local PLUGIN = {}
PLUGIN.Title = "Rock the Vote"
PLUGIN.Description = "Rock the vote to change the map!"
PLUGIN.Author = "Metapyziks"
PLUGIN.ChatCommand = "rtv"
PLUGIN.Privileges = { "Rock the Vote" }

PLUGIN.VoteQueue = {}

function PLUGIN:Call( ply, args )
	if ( ply:EV_HasPrivilege( "Rock the Vote" ) and ValidEntity( ply ) ) then
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
	elseif( #self.VoteQueue > 0 ) then
		for k, ply in ipairs( self.VoteQueue ) do
			ply:SetNWBool( "WantsVote", true )
		end
		
		self.VoteQueue = {}
	end	
end

evolve:RegisterPlugin( PLUGIN )