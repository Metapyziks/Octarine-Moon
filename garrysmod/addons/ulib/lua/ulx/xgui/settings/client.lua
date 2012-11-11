--Client settings module for ULX GUI -- by Stickly Man!
--A settings module for modifing XGUI-based settings, and allows for modules to add clientside setting here.

local client = xlib.makepanel{ parent=xgui.null }

client.panel = xlib.makepanel{ x=160, y=5, w=425, h=327, parent=client }

client.catList = xlib.makelistview{ x=5, y=5, w=150, h=307, parent=client }
client.catList:AddColumn( "Clientside Settings" )
client.catList.Columns[1].DoClick = function() end
client.catList.OnRowSelected = function( self, LineID, Line )
	local nPanel = xgui.modules.submodule[Line:GetValue(2)].panel
	if nPanel ~= client.curPanel then
		nPanel:SetZPos( 0 )
		xlib.addToAnimQueue( "pnlSlide", { panel=nPanel, startx=-435, starty=0, endx=0, endy=0, setvisible=true } )
		if client.curPanel then
			client.curPanel:SetZPos( -1 )
			xlib.addToAnimQueue( client.curPanel.SetVisible, client.curPanel, false )
		end
		xlib.animQueue_start()
		client.curPanel = nPanel
	else
		xlib.addToAnimQueue( "pnlSlide", { panel=nPanel, startx=0, starty=0, endx=-435, endy=0, setvisible=false } )
		self:ClearSelection()
		client.curPanel = nil
		xlib.animQueue_start()
	end
	if nPanel.onOpen then nPanel.onOpen() end --If the panel has it, call a function when it's opened
end

xlib.makebutton{ x=5, y=312, w=150, label="Save Clientside Settings", parent=client }.DoClick=function()
	xgui.saveClientSettings()
end

--Process modular settings
function client.processModules()
	client.catList:Clear()
	for i, module in ipairs( xgui.modules.submodule ) do
		if module.mtype == "client" and ( not module.access or LocalPlayer():query( module.access ) ) then
			local x,y = module.panel:GetSize()
			if x == y and y == 0 then module.panel:SetSize( 425, 327 ) end
			module.panel:SetParent( client.panel )
			local line = client.catList:AddLine( module.name, i )
			if ( module.panel == client.curPanel ) then
				client.curPanel = nil
				client.catList:SelectItem( line )
			else
				module.panel:SetVisible( false )
			end
		end
	end
	client.catList:SortByColumn( 1, false )
end
client.processModules()

xgui.hookEvent( "onProcessModules", nil, client.processModules )
xgui.addSettingModule( "Client", client, "icon16/layout_content.png" )


--------------------XGUI Clientside Module--------------------
local xguipnl = xlib.makepanel{ parent=xgui.null }
xlib.makebutton{ x=10, y=10, w=150, label="Refresh XGUI Modules", parent=xguipnl }.DoClick=function()
	xgui.processModules()
end
xlib.makebutton{ x=10, y=30, w=150, label="Refresh Server Data", parent=xguipnl }.DoClick=function( self )
	if xgui.isInstalled then  --We can't be in offline mode to do this
		self:SetDisabled( true )
		RunConsoleCommand( "xgui", "refreshdata" )
		timer.Simple( 30, function() self:SetDisabled( false ) end )
	end
end
xlib.makeslider{ x=10, y=55, w=150, label="Anim transition time", max=2, value=xgui.settings.animTime, decimal=2, parent=xguipnl, textcolor=color_black }.OnValueChanged = function( self, val )
	local testval = math.Clamp( tonumber( val ), 0, 2 )
	if testval ~= tonumber( val ) then self:SetValue( testval ) end
	xgui.settings.animTime = tonumber( val )
end
xlib.makecheckbox{ x=10, y=97, w=150, label="Show Startup Messages", value=xgui.settings.showLoadMsgs, parent=xguipnl, textcolor=color_black }.OnChange = function( self, bVal )
	xgui.settings.showLoadMsgs = bVal
end
xlib.makelabel{ x=10, y=120, label="Infobar color:", textcolor=color_black, parent=xguipnl }

xlib.makecolorpicker{ x=10, y=135, color=xgui.settings.infoColor, addalpha=true, alphamodetwo=true, parent=xguipnl }.OnChangeImmediate = function( self, color )
	xgui.settings.infoColor = color
end

----------------
--SKIN MANAGER--
----------------
--Include the extra skins in case nothing else has included them.
for _, file in ipairs( file.Find( "skins/*.lua", "LUA" ) ) do
	include( "skins/" .. file )
end
xlib.makelabel{ x=10, y=273, label="Derma Theme:", textcolor=color_black, parent=xguipnl }
xguipnl.skinselect = xlib.makecombobox{ x=10, y=290, w=150, parent=xguipnl }
if not derma.SkinList[xgui.settings.skin] then
	xgui.settings.skin = "Default"
end
xguipnl.skinselect:SetText( derma.SkinList[xgui.settings.skin].PrintName )
xgui.base.refreshSkin = true
xguipnl.skinselect.OnSelect = function( self, index, value, data )
	xgui.settings.skin = data
	xgui.base:SetSkin( data )
end
for skin, skindata in pairs( derma.SkinList ) do
	xguipnl.skinselect:AddChoice( skindata.PrintName, skin )
end
xgui.addSubModule( "XGUI Settings", xguipnl, nil, "client" )

----------------
--TAB ORDERING--
----------------
xguipnl.mainorder = xlib.makelistview{ x=175, y=10, w=115, h=110, parent=xguipnl }
xguipnl.mainorder:AddColumn( "Main Modules" )
xguipnl.mainorder.OnRowSelected = function( self, LineID, Line )
	xguipnl.upbtnM:SetDisabled( LineID <= 1 )
	xguipnl.downbtnM:SetDisabled( LineID >= #xgui.settings.moduleOrder )
end 
xguipnl.updateMainOrder = function()
	local selected = xguipnl.mainorder:GetSelectedLine() and xguipnl.mainorder:GetSelected()[1]:GetColumnText(1)
	xguipnl.mainorder:Clear()
	for i, v in ipairs( xgui.settings.moduleOrder ) do
		local l = xguipnl.mainorder:AddLine( v )
		if v == selected then xguipnl.mainorder:SelectItem( l ) end
	end
end
xgui.hookEvent( "onProcessModules", nil, xguipnl.updateMainOrder )
xguipnl.upbtnM = xlib.makespecialbutton{ x=250, y=120, w=20, btype="up", disabled=true, parent=xguipnl }
xguipnl.upbtnM.DoClick = function( self )
	self:SetDisabled( true )
	local i = xguipnl.mainorder:GetSelectedLine()
	table.insert( xgui.settings.moduleOrder, i-1, xgui.settings.moduleOrder[i] )
	table.remove( xgui.settings.moduleOrder, i+1 )
	xgui.processModules()
end
xguipnl.downbtnM = xlib.makespecialbutton{ x=270, y=120, w=20, btype="down", disabled=true, parent=xguipnl }
xguipnl.downbtnM.DoClick = function( self )
	self:SetDisabled( true )
	local i = xguipnl.mainorder:GetSelectedLine()
	table.insert( xgui.settings.moduleOrder, i+2, xgui.settings.moduleOrder[i] )
	table.remove( xgui.settings.moduleOrder, i )
	xgui.processModules()
end


xguipnl.settingorder = xlib.makelistview{ x=300, y=10, w=115, h=110, parent=xguipnl }
xguipnl.settingorder:AddColumn( "Setting Modules" )
xguipnl.settingorder.OnRowSelected = function( self, LineID, Line )
	xguipnl.upbtnS:SetDisabled( LineID <= 1 )
	xguipnl.downbtnS:SetDisabled( LineID >= #xgui.settings.settingOrder )
end 
xguipnl.updateSettingOrder = function()
	local selected = xguipnl.settingorder:GetSelectedLine() and xguipnl.settingorder:GetSelected()[1]:GetColumnText(1)
	xguipnl.settingorder:Clear()
	for i, v in ipairs( xgui.settings.settingOrder ) do
		local l = xguipnl.settingorder:AddLine( v )
		if v == selected then xguipnl.settingorder:SelectItem( l ) end
	end
end
xgui.hookEvent( "onProcessModules", nil, xguipnl.updateSettingOrder )
xguipnl.upbtnS = xlib.makespecialbutton{ x=395, y=120, w=20, btype="up", disabled=true, parent=xguipnl }
xguipnl.upbtnS.DoClick = function( self )
	self:SetDisabled( true )
	local i = xguipnl.settingorder:GetSelectedLine()
	table.insert( xgui.settings.settingOrder, i-1, xgui.settings.settingOrder[i] )
	table.remove( xgui.settings.settingOrder, i+1 )
	xgui.processModules()
end
xguipnl.downbtnS = xlib.makespecialbutton{ x=375, y=120, w=20, btype="down", disabled=true, parent=xguipnl }
xguipnl.downbtnS.DoClick = function( self )
	self:SetDisabled( true )
	local i = xguipnl.settingorder:GetSelectedLine()
	table.insert( xgui.settings.settingOrder, i+2, xgui.settings.settingOrder[i] )
	table.remove( xgui.settings.settingOrder, i )
	xgui.processModules()
end

--------------------
--XGUI POSITIONING--
--------------------
xlib.makelabel{ x=175, y=145, label="XGUI Positioning:", textcolor=color_black, parent=xguipnl }
local pos = tonumber( xgui.settings.xguipos.pos )
xguipnl.b7 = xlib.makespecialbutton{ x=175, y=160, w=20, btype="none", disabled=pos==7, parent=xguipnl }
xguipnl.b7.DoClick = function( self ) xguipnl.updatePos( 7 ) end
xguipnl.b8 = xlib.makespecialbutton{ x=195, y=160, w=20, btype="up",   disabled=pos==8, parent=xguipnl }
xguipnl.b8.DoClick = function( self ) xguipnl.updatePos( 8 ) end
xguipnl.b9 = xlib.makespecialbutton{ x=215, y=160, w=20, btype="none", disabled=pos==9, parent=xguipnl }
xguipnl.b9.DoClick = function( self ) xguipnl.updatePos( 9 ) end
xguipnl.b4 = xlib.makespecialbutton{ x=175, y=180, w=20, btype="left", disabled=pos==4, parent=xguipnl }
xguipnl.b4.DoClick = function( self ) xguipnl.updatePos( 4 ) end
xguipnl.b5 = xlib.makespecialbutton{ x=195, y=180, w=20, btype="updown", disabled=pos==5, parent=xguipnl }
xguipnl.b5.DoClick = function( self ) xguipnl.updatePos( 5 ) end
xguipnl.b6 = xlib.makespecialbutton{ x=215, y=180, w=20, btype="right", disabled=pos==6, parent=xguipnl }
xguipnl.b6.DoClick = function( self ) xguipnl.updatePos( 6 ) end
xguipnl.b1 = xlib.makespecialbutton{ x=175, y=200, w=20, btype="none", disabled=pos==1, parent=xguipnl }
xguipnl.b1.DoClick = function( self ) xguipnl.updatePos( 1 ) end
xguipnl.b2 = xlib.makespecialbutton{ x=195, y=200, w=20, btype="down", disabled=pos==2, parent=xguipnl }
xguipnl.b2.DoClick = function( self ) xguipnl.updatePos( 2 ) end
xguipnl.b3 = xlib.makespecialbutton{ x=215, y=200, w=20, btype="none", disabled=pos==3, parent=xguipnl }
xguipnl.b3.DoClick = function( self ) xguipnl.updatePos( 3 ) end

function xguipnl.updatePos( position, xoffset, yoffset, ignoreanim )
	position = position or 5
	xoffset = xoffset or tonumber( xgui.settings.xguipos.xoff )
	yoffset = yoffset or tonumber( xgui.settings.xguipos.yoff )
	xgui.settings.xguipos = { pos=position, xoff=xoffset, yoff=yoffset }
	xgui.SetPos( position, xoffset, yoffset, ignoreanim )
	xguipnl.b1:SetDisabled( position==1 )
	xguipnl.b2:SetDisabled( position==2 )
	xguipnl.b3:SetDisabled( position==3 )
	xguipnl.b4:SetDisabled( position==4 )
	xguipnl.b5:SetDisabled( position==5 )
	xguipnl.b6:SetDisabled( position==6 )
	xguipnl.b7:SetDisabled( position==7 )
	xguipnl.b8:SetDisabled( position==8 )
	xguipnl.b9:SetDisabled( position==9 )
end

xguipnl.xwang = xlib.makenumberwang{ x=245, y=167, w=50, min=-1000, max=1000, value=xgui.settings.xguipos.xoff, decimal=0, parent=xguipnl }
xguipnl.xwang.OnValueChanged = function( self, val )
	xguipnl.updatePos( xgui.settings.xguipos.pos, tonumber( val ), xgui.settings.xguipos.yoffset, true )
end
xguipnl.xwang.OnEnter = function( self )
	local val = tonumber( self:GetValue() )
	if not val then val = 0 end
	xguipnl.updatePos( xgui.settings.xguipos.pos, tonumber( val ), xgui.settings.xguipos.yoffset )
end
xguipnl.xwang.OnLoseFocus = function( self )
	hook.Call( "OnTextEntryLoseFocus", nil, self )
	self:OnEnter()
end
xlib.makelabel{ x=300, y=169, label="X Offset", textcolor=color_black, parent=xguipnl }

xguipnl.ywang = xlib.makenumberwang{ x=245, y=193, w=50, min=-1000, max=1000, value=xgui.settings.xguipos.yoff, decimal=0, parent=xguipnl }
xguipnl.ywang.OnValueChanged = function( self, val )
	xguipnl.updatePos( xgui.settings.xguipos.pos, xgui.settings.xguipos.xoffset, tonumber( val ), true )
end
xguipnl.ywang.OnEnter = function( self )
	local val = tonumber( self:GetValue() )
	if not val then val = 0 end
	xguipnl.updatePos( xgui.settings.xguipos.pos, xgui.settings.xguipos.xoffset, tonumber( val ) )
end
xguipnl.ywang.OnLoseFocus = function( self )
	hook.Call( "OnTextEntryLoseFocus", nil, self )
	self:OnEnter()
end
xlib.makelabel{ x=300, y=195, label="Y Offset", textcolor=color_black, parent=xguipnl }

-------------------------
--OPEN/CLOSE ANIMATIONS--
-------------------------
xlib.makelabel{ x=175, y=229, label="XGUI Animations:", textcolor=color_black, parent=xguipnl }
xlib.makelabel{ x=175, y=247, label="On Open:", textcolor=color_black, parent=xguipnl }
xguipnl.inAnim = xlib.makecombobox{ x=225, y=245, w=150, choices={ "Fade In", "Slide From Top", "Slide From Left", "Slide From Bottom", "Slide From Right" }, parent=xguipnl }
xguipnl.inAnim:ChooseOptionID( tonumber( xgui.settings.animIntype ) )
function xguipnl.inAnim:OnSelect( index, value, data )
	xgui.settings.animIntype = index
end
xlib.makelabel{ x=175, y=272, label="On Close:", textcolor=color_black, parent=xguipnl }
xguipnl.outAnim = xlib.makecombobox{ x=225, y=270, w=150, choices={ "Fade Out", "Slide To Top", "Slide To Left", "Slide To Bottom", "Slide To Right" }, parent=xguipnl }
xguipnl.outAnim:ChooseOptionID( tonumber( xgui.settings.animOuttype ) )
function xguipnl.outAnim:OnSelect( index, value, data )
	xgui.settings.animOuttype = index
end