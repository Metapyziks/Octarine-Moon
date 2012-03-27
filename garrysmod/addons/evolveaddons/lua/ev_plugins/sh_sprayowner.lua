/*-------------------------------------------------------------------------------------------------------------------------
	Get a Spray's Owner
-------------------------------------------------------------------------------------------------------------------------*/

local PLUGIN = {}
PLUGIN.Title = "Get Spray Owner"
PLUGIN.Description = "Find the player who placed the spray you are looking at"
PLUGIN.Author = "Metapyziks"
PLUGIN.ChatCommand = "sprayowner"
PLUGIN.Usage = nil
PLUGIN.Privileges = { "Get Spray Owner" }

if( SERVER ) then
	PLUGIN.Sprays = {}
	
	function PLUGIN:AddSpray( ply, pos )		
		for i, sp in ipairs( self.Sprays ) do
			if sp.Owner == ply then
				sp.Pos = pos
				return
			end
		end
		
		table.insert( self.Sprays, { Owner = ply, Pos = pos } )
	end
	
	function PLUGIN:GetSprayOwner( pos )
		local nearest = nil
		local ndist = 96
		local i = #self.Sprays
		while i > 0 do
			local spray = self.Sprays[ i ]
			if not IsValid( spray.Owner ) then
				table.remove( self.Sprays, i )
			else
				local dist = pos:Distance( spray.Pos )
				if dist < ndist then
					nearest = spray
					ndist = dist
				end
			end
			i = i - 1
		end
		
		if nearest then
			return nearest.Owner
		else
			return nil
		end
	end
	
	function PLUGIN:PlayerSpray( ply )
		local trdata = {}
		trdata.start = ply:GetShootPos()
		trdata.endpos = trdata.start + ply:GetAimVector() * 128
		trdata.filter = ply
		trdata.mask = MASK_SOLID_BRUSHONLY
		local tr = util.TraceLine( trdata )
		PLUGIN:AddSpray( ply, tr.HitPos )
	end

	function PLUGIN:Call( ply, args )
		if IsValid( ply ) and ply:EV_HasPrivilege( "Get Spray Owner" ) then
			local trdata = {}
			trdata.start = ply:GetShootPos()
			trdata.endpos = trdata.start + ply:GetAimVector() * 4096
			trdata.filter = ply
			trdata.mask = MASK_SOLID_BRUSHONLY
			local tr = util.TraceLine( trdata )
			local owner = self:GetSprayOwner( tr.HitPos )
			if owner then
				evolve:Notify( ply, evolve.colors.white, "That spray was placed by ", evolve.colors.blue, owner:Nick(),
					evolve.colors.white, ", Steam ID ", evolve.colors.red, owner:SteamID(), evolve.colors.white, "."  )
			else
				evolve:Notify( ply, evolve.colors.red, "No sprays found near where you are looking." )
			end
		else
			evolve:Notify( ply, evolve.colors.red, evolve.constants.notallowed )
		end
	end
end

evolve:RegisterPlugin( PLUGIN )