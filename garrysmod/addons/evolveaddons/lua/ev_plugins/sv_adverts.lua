/*-------------------------------------------------------------------------------------------------------------------------
	Annoying chat adverts
-------------------------------------------------------------------------------------------------------------------------*/

local PLUGIN = {}
PLUGIN.Title = "Adverts"
PLUGIN.Description = "Annoying chat adverts"
PLUGIN.Author = "Metapyziks"
PLUGIN.Usage = nil
PLUGIN.Privileges = nil

PLUGIN.Adverts = {}

function PLUGIN:BroadcastChatAdverts()
	if( #self.Adverts > 0 and #player.GetAll() > 0 ) then
		evolve:Notify( evolve.colors.red, string.Trim( table.Random( self.Adverts )))
	end
	
	timer.Adjust( "EV_ChatAdverts", self.IntervalConvar:GetInt(), 0, PLUGIN.BroadcastChatAdverts, PLUGIN )
end

PLUGIN.IntervalConvar = CreateConVar("ev_advert_interval", "60")

timer.Create( "EV_ChatAdverts", PLUGIN.IntervalConvar:GetInt(), 0, PLUGIN.BroadcastChatAdverts, PLUGIN )

if( file.Exists( "ev_chatadverts.txt" )) then
	PLUGIN.Adverts = string.Explode( ";", file.Read( "ev_chatadverts.txt" ))
else
	file.Write( "ev_chatadverts.txt", "" )
end

evolve:RegisterPlugin( PLUGIN )