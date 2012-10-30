/*-------------------------------------------------------------------------------------------------------------------------
	Message of the Day
-------------------------------------------------------------------------------------------------------------------------*/

local PLUGIN = {}
PLUGIN.Title = "MOTD"
PLUGIN.Description = "Message of the Day."
PLUGIN.Author = "Metapyziks"
PLUGIN.ChatCommand = "motd"
PLUGIN.Usage = nil
PLUGIN.Privileges = nil

function PLUGIN:PlayerInitialSpawn( ply )
	timer.Simple( 1, function()
		umsg.Start( "EV_ShowMoTD", ply ) 
		umsg.End()
	end)
end

function PLUGIN:Call( ply, args )
	umsg.Start( "EV_ShowMoTD", ply )
	umsg.End()
end

if (CLIENT) then
	function PLUGIN:CreateMenu()		
		self.MotdPanel = vgui.Create("DFrame")
		local w,h = ScrW() - 200,ScrH() - 200
		self.MotdPanel:SetPos( 100,100 )
		self.MotdPanel:SetSize( w,h )
		self.MotdPanel:SetTitle( "MOTD" )
		self.MotdPanel:SetVisible( false )
		self.MotdPanel:SetDraggable( false )
		self.MotdPanel:ShowCloseButton( true )
		self.MotdPanel:SetDeleteOnClose( false )
		self.MotdPanel:SetScreenLock( true )
		self.MotdPanel:MakePopup()
		
		self.MotdBox = vgui.Create("HTML",self.MotdPanel)
		self.MotdBox:StretchToParent( 4,25,4,4 )
		self.MotdBox:OpenURL( "http://www.octarinemoon.co.uk/motd/" )
		self.MotdPanel:SetVisible( true )
	end
	timer.Simple( 0.1, function() PLUGIN:CreateMenu() end)
	
	usermessage.Hook( "EV_ShowMoTD", function()
		if( PLUGIN.MotdPanel ) then
			PLUGIN.MotdPanel:SetVisible( true )
		else
			PLUGIN:CreateMenu()
		end
	end )
end

evolve:RegisterPlugin( PLUGIN )