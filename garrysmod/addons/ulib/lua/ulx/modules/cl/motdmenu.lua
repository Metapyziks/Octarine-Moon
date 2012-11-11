ulx.motdmenu_exists = true

local isUrl
local url

function ulx.showMotdMenu()
	local window = vgui.Create( "DFrame" )
	if ScrW() > 640 then -- Make it larger if we can.
		window:SetSize( ScrW()*0.9, ScrH()*0.9 )
	else
		window:SetSize( 640, 480 )
	end
	window:Center()
	window:SetTitle( "ULX MOTD" )
	window:SetVisible( true )
	window:MakePopup()

	local html = vgui.Create( "HTML", window )

	local button = vgui.Create( "DButton", window )
	button:SetText( "Close" )
	button.DoClick = function() window:Close() end
	button:SetSize( 100, 40 )
	button:SetPos( (window:GetWide() - button:GetWide()) / 2, window:GetTall() - button:GetTall() - 10 )

	html:SetSize( window:GetWide() - 20, window:GetTall() - button:GetTall() - 50 )
	html:SetPos( 10, 30 )
	if not isUrl then
		html:SetHTML( file.Read( "ulx_motd.txt", "DATA" ) )
	else
		html:OpenURL( url )
	end
end

function ulx.rcvMotd( isUrl_, text )
	isUrl = isUrl_
	if not isUrl then
		file.Write( "ulx_motd.txt", text )
	else
		if text:find( "://", 1, true ) then
			url = text
		else
			url = "http://" .. text
		end
	end
end
