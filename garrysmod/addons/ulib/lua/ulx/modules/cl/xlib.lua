--XLIB -- by Stickly Man!
--A library of helper functions used by XGUI for creating derma controls with a single line of code.

--Currently a bit disorganized and unstandardized, (just put in things as I needed them). I'm hoping to fix that soon.
--Also has a few ties into XGUI for keyboard focus stuff.

xlib = {}

function xlib.makecheckbox( t )
	local pnl = vgui.Create( "DCheckBoxLabel", t.parent )
	pnl:SetPos( t.x, t.y )
	pnl:SetText( t.label or "" )
	pnl:SizeToContents()
	pnl:SetValue( t.value or 0 )
	if t.convar then pnl:SetConVar( t.convar ) end
	if t.textcolor then pnl:SetTextColor( t.textcolor ) end
	if not t.tooltipwidth then t.tooltipwidth = 250 end
	if t.tooltip then
		if t.tooltipwidth ~= 0 then
			t.tooltip = xlib.wordWrap( t.tooltip, t.tooltipwidth, "Default" )
		end
		pnl:SetToolTip( t.tooltip )
	end
	if t.disabled then pnl:SetDisabled( t.disabled ) end
	--Replicated Convar Updating
	if t.repconvar then
		xlib.checkRepCvarCreated( t.repconvar )
		pnl:SetValue( GetConVar( t.repconvar ):GetBool() )
		function pnl.ConVarUpdated( sv_cvar, cl_cvar, ply, old_val, new_val )
			if cl_cvar == t.repconvar:lower() then
				pnl:SetValue( new_val )
			end
		end
		hook.Add( "ULibReplicatedCvarChanged", "XLIB_" .. t.repconvar, pnl.ConVarUpdated )
		function pnl:OnChange( bVal )
			RunConsoleCommand( t.repconvar, tostring( bVal and 1 or 0 ) )
		end
		pnl.Think = function() end --Override think functions to remove Garry's convar check to (hopefully) speed things up
		pnl.ConVarNumberThink = function() end
		pnl.ConVarStringThink = function() end
		pnl.ConVarChanged = function() end
	end
	--We need to set the enabled/disabled state of the checkbox whenever PerformLayout is called, otherwise if it's disabled before PerformLayout is first called, it won't look like it is.
	local tempfunc = pnl.PerformLayout
	pnl.PerformLayout = function( self )
		tempfunc( self )
		pnl:SetDisabled( pnl:GetDisabled() )
	end
	return pnl
end

function xlib.makelabel( t )
	local pnl = vgui.Create( "DLabel", t.parent )
	pnl:SetPos( t.x, t.y )
	pnl:SetText( t.label or "" )
	if not t.tooltipwidth then t.tooltipwidth = 250 end
	if t.tooltip then
		if t.tooltipwidth ~= 0 then
			t.tooltip = xlib.wordWrap( t.tooltip, t.tooltipwidth, "Default" )
		end
		pnl:SetToolTip( t.tooltip )
		pnl:SetMouseInputEnabled( true )
	end
	
	if t.font then pnl:SetFont( t.font ) end
	if t.w and t.wordwrap then
		pnl:SetText( xlib.wordWrap( t.label, t.w, t.font or "Default" ) )
	end
	pnl:SizeToContents()
	if t.w then pnl:SetWidth( t.w ) end
	if t.h then pnl:SetHeight( t.h ) end
	if t.textcolor then pnl:SetTextColor( t.textcolor ) end

	return pnl
end

function xlib.makelistlayout( t )
	local pnl = vgui.Create( "DListLayout" )
	pnl.scroll = vgui.Create( "DScrollPanel", t.parent )
	
	pnl.scroll:SetPos( t.x, t.y )
	pnl.scroll:SetSize( t.w, t.h )
	pnl:SetSize( t.w, t.h )
	pnl.scroll:AddItem( pnl )
	--pnl:SetSpacing( t.spacing or 5 ) TODO? :DockMargin( int, int, int, int )
	--pnl:SetPadding( t.padding or 5 )
	
	function pnl:PerformLayout()
		self:SetWide( self.scroll:GetWide() - ( self.scroll.VBar.Enabled and 16 or 0 ) )
		self:SizeToChildren( false, true )
	end
	return pnl
end

function xlib.makebutton( t )
	local pnl = vgui.Create( "DButton", t.parent )
	pnl:SetSize( t.w, t.h or 20 )
	pnl:SetPos( t.x, t.y )
	pnl:SetText( t.label or "" )
	pnl:SetDisabled( t.disabled )
	return pnl
end

function xlib.makespecialbutton( t )
	--local pnl = vgui.Create( "DSysButton", t.parent ) pnl:SetType( t.btype )
	local pnl = vgui.Create( "DButton", t.parent )
	pnl:SetSize( t.w, t.h or 20 )
	pnl:SetPos( t.x, t.y )
	pnl:SetDisabled( t.disabled )
	pnl:SetText( "" )
	pnl.Paint = function( panel, w, h ) derma.SkinHook( "Paint", "WindowCloseButton", panel, w, h ) end
	return pnl
end

function xlib.makeframe( t )
	local pnl = vgui.Create( "DFrame", t.parent )
	pnl:SetSize( t.w, t.h )
	if t.nopopup ~= true then pnl:MakePopup() end
	pnl:SetPos( t.x or ScrW()/2-t.w/2, t.y or ScrH()/2-t.h/2 )
	pnl:SetTitle( t.label or "" )
	if t.draggable ~= nil then pnl:SetDraggable( t.draggable ) end
	if t.showclose ~= nil then pnl:ShowCloseButton( t.showclose ) end
	if t.skin then pnl:SetSkin( t.skin ) end
	if t.visible ~= nil then pnl:SetVisible( t.visible ) end
	return pnl
end

function xlib.makepropertysheet( t )
	local pnl = vgui.Create( "DPropertySheet", t.parent )
	pnl:SetPos( t.x, t.y )
	pnl:SetSize( t.w, t.h )
	--Clears all of the tabs in the base, new parent set to xgui.null.
	function pnl:Clear()
		for _, Sheet in ipairs( self.Items ) do
			Sheet.Panel:SetParent( t.offloadparent )
			Sheet.Tab:Remove()
		end
		self.m_pActiveTab = nil
		self:SetActiveTab( nil )
		self.tabScroller.Panels = {}
		self.Items = {}
	end
	return pnl
end

function xlib.maketextbox( t )
	local pnl = vgui.Create( "DTextEntry", t.parent )
	pnl:SetPos( t.x, t.y )
	pnl:SetWide( t.w )
	pnl:SetTall( t.h or 20 )
	pnl:SetEnterAllowed( true )
	if t.convar then pnl:SetConVar( t.convar ) end
	if t.text then pnl:SetText( t.text ) end
	if t.enableinput then pnl:SetEnabled( t.enableinput ) end
	pnl.selectAll = t.selectall
	if not t.tooltipwidth then t.tooltipwidth = 250 end
	if t.tooltip then
		if t.tooltipwidth ~= 0 then
			t.tooltip = xlib.wordWrap( t.tooltip, t.tooltipwidth, "Default" )
		end
		pnl:SetToolTip( t.tooltip )
	end

	pnl.enabled = true
	function pnl:SetDisabled( val ) --Do some funky stuff to simulate enabling/disabling of a textbox
		pnl.enabled = not val
		pnl:SetEnabled( not val )
		pnl:SetPaintBackgroundEnabled( val )
	end
	if t.disabled then pnl:SetDisabled( t.disabled ) end

	--Replicated Convar Updating
	if t.repconvar then
		xlib.checkRepCvarCreated( t.repconvar )
		pnl:SetValue( GetConVar( t.repconvar ):GetString() )
		function pnl.ConVarUpdated( sv_cvar, cl_cvar, ply, old_val, new_val )
			if cl_cvar == t.repconvar:lower() then
				pnl:SetValue( new_val )
			end
		end
		hook.Add( "ULibReplicatedCvarChanged", "XLIB_" .. t.repconvar, pnl.ConVarUpdated )
		function pnl:UpdateConvarValue()
			RunConsoleCommand( t.repconvar, self:GetValue() )
		end
		function pnl:OnEnter()
			RunConsoleCommand( t.repconvar, self:GetValue() )
		end
		pnl.Think = function() end --Override think functions to remove Garry's convar check to (hopefully) speed things up
		pnl.ConVarNumberThink = function() end
		pnl.ConVarStringThink = function() end
		pnl.ConVarChanged = function() end
	end
	return pnl
end

function xlib.makelistview( t )
	local pnl = vgui.Create( "DListView", t.parent )
	pnl:SetPos( t.x, t.y )
	pnl:SetSize( t.w, t.h )
	pnl:SetMultiSelect( t.multiselect )
	pnl:SetHeaderHeight( t.headerheight or 20 )
	return pnl
end

function xlib.makecat( t )
	local pnl = vgui.Create( "DCollapsibleCategory", t.parent )
	pnl:SetPos( t.x, t.y )
	pnl:SetSize( t.w, t.h )
	pnl:SetLabel( t.label or "" )
	pnl:SetContents( t.contents )
	t.contents:Dock( TOP )

	if t.expanded ~= nil then pnl:SetExpanded( t.expanded ) end
	if t.checkbox then
		pnl.checkBox = vgui.Create( "DCheckBox", pnl.Header )
		pnl.checkBox:SetValue( t.expanded )
		function pnl.checkBox:DoClick()
			self:Toggle()
			pnl:Toggle()
		end
		function pnl.Header:OnMousePressed( mcode )
			if ( mcode == MOUSE_LEFT ) then
				self:GetParent():Toggle()
				self:GetParent().checkBox:Toggle()
				return
			end
			return self:GetParent():OnMousePressed( mcode )
		end
		local tempfunc = pnl.PerformLayout
		pnl.PerformLayout = function( self )
			tempfunc( self )
			self.checkBox:SetPos( self:GetWide()-18, 5 )
		end
	end

	function pnl:SetOpen( bVal )
		if not self:GetExpanded() and bVal then
			pnl.Header:OnMousePressed( MOUSE_LEFT ) --Call the mouse function so it properly toggles the checkbox state (if it exists)
		elseif self:GetExpanded() and not bVal then
			pnl.Header:OnMousePressed( MOUSE_LEFT )
		end
	end

	return pnl
end

function xlib.makepanel( t )
	local pnl = vgui.Create( "DPanel", t.parent )
	pnl:SetPos( t.x, t.y )
	pnl:SetSize( t.w, t.h )
	if t.visible ~= nil then pnl:SetVisible( t.visible ) end
	return pnl
end

function xlib.makeXpanel( t )
	pnl = vgui.Create( "xlib_Panel", t.parent )
	pnl:MakePopup()
	pnl:SetPos( t.x, t.y )
	pnl:SetSize( t.w, t.h )
	if t.visible ~= nil then pnl:SetVisible( t.visible ) end
	return pnl
end

function xlib.makenumberwang( t )
	local pnl = vgui.Create( "DNumberWang", t.parent )
	pnl:SetPos( t.x, t.y )
	pnl:SetDecimals( t.decimal or 0 )
	pnl:SetMinMax( t.min or 0, t.max or 255 )
	pnl:SizeToContents()
	pnl:SetValue( t.value )
	if t.w then pnl:SetWide( t.w ) end
	if t.h then pnl:SetTall( t.h ) end
	return pnl
end

function xlib.makecombobox( t )
	local pnl = vgui.Create( "DComboBox", t.parent )
	t.w = t.w or 100
	t.h = t.h or 20
	pnl:SetText( t.text or "" )
	pnl:SetPos( t.x, t.y )
	pnl:SetSize( t.w, t.h )

	if ( t.enableinput == true ) then
		pnl.TextEntry = vgui.Create( "DTextEntry", pnl )
		pnl.TextEntry:SetSize( t.w-20, t.h )
		pnl.TextEntry.selectAll = t.selectall
		pnl.TextEntry:SetEditable( true )
		
		pnl.TextEntry.OnMousePressed = function( button, mcode )
			--hook.Call( "OnTextEntryGetFocus", nil, self )
		end
	
		pnl.DropButton.OnMousePressed = function( button, mcode )
			--hook.Call( "OnTextEntryLoseFocus", nil, pnl.TextEntry )
			pnl:OpenMenu( pnl.DropButton )
		end
		
		pnl.TextEntry.OnLoseFocus = function( self )
			--hook.Call( "OnTextEntryLoseFocus", nil, self )
			self:UpdateConvarValue()
		end
		
		
	end

	if not t.tooltipwidth then t.tooltipwidth = 250 end
	if t.tooltip then
		if t.tooltipwidth ~= 0 then
			t.tooltip = xlib.wordWrap( t.tooltip, t.tooltipwidth, "Default" )
		end
		pnl:SetToolTip( t.tooltip )
	end

	if t.choices then
		for i, v in ipairs( t.choices ) do
			pnl:AddChoice( v )
		end
	end

	pnl.enabled = true
	function pnl:SetDisabled( val ) --Do some funky stuff to simulate enabling/disabling of a textbox
		self.enabled = not val
		--self.TextEntry:SetEnabled( not val )
		--self.TextEntry:SetPaintBackgroundEnabled( val )
		self.DropButton:SetDisabled( val )
		self.DropButton:SetMouseInputEnabled( not val )
		self:SetMouseInputEnabled( not val )
	end
	if t.disabled then pnl:SetDisabled( t.disabled ) end

	--Add support for Spacers
	function pnl:OpenMenu( pControlOpener ) --Garrys function with no comments, just adding a few things.
		if ( pControlOpener ) then
			if ( pControlOpener == self.TextEntry ) then
				return
			end
		end
		if ( #self.Choices == 0 ) then return end
		if ( self.Menu ) then
			self.Menu:Remove()
			self.Menu = nil
			return
		end
		self.Menu = DermaMenu()
			for k, v in pairs( self.Choices ) do
				if v == "--*" then --This is the string to determine where to add the spacer
					self.Menu:AddSpacer()
				else
					self.Menu:AddOption( v, function() self:ChooseOption( v, k ) end )
				end
			end
			local x, y = self:LocalToScreen( 0, self:GetTall() )
			self.Menu:SetMinimumWidth( self:GetWide() )
			self.Menu:Open( x, y, false, self )
		ULib.queueFunctionCall( self.RequestFocus, self ) --Force the menu to request focus when opened, to prevent the menu being open, but the focus being to the controls behind it.
	end

	--Replicated Convar Updating
	if t.repconvar then
		xlib.checkRepCvarCreated( t.repconvar )
		if t.isNumberConvar then --This is for convar settings stored via numbers (like ulx_rslotsMode)
			if t.numOffset == nil then t.numOffset = 1 end
			local cvar = GetConVar( t.repconvar ):GetInt()
			if tonumber( cvar ) and cvar + t.numOffset <= #pnl.Choices and cvar + t.numOffset > 0 then
				pnl:ChooseOptionID( cvar + t.numOffset )
			else
				pnl:SetText( "Invalid Convar Value" )
			end
			function pnl.ConVarUpdated( sv_cvar, cl_cvar, ply, old_val, new_val )
				if cl_cvar == t.repconvar:lower() then
					if tonumber( new_val ) and new_val + t.numOffset <= #pnl.Choices and new_val + t.numOffset > 0 then
						pnl:ChooseOptionID( new_val + t.numOffset )
					else
						pnl:SetText( "Invalid Convar Value" )
					end
				end
			end
			hook.Add( "ULibReplicatedCvarChanged", "XLIB_" .. t.repconvar, pnl.ConVarUpdated )
			function pnl:OnSelect( index )
				RunConsoleCommand( t.repconvar, tostring( index - t.numOffset ) )
			end
		else  --Otherwise, use each choice as a string for the convar
			pnl:SetText( GetConVar( t.repconvar ):GetString() )
			function pnl.ConVarUpdated( sv_cvar, cl_cvar, ply, old_val, new_val )
				if cl_cvar == t.repconvar:lower() then
					pnl:SetText( new_val )
				end
			end
			hook.Add( "ULibReplicatedCvarChanged", "XLIB_" .. t.repconvar, pnl.ConVarUpdated )
			function pnl:OnSelect( index, value )
				RunConsoleCommand( t.repconvar, value )
			end
		end
	end
	return pnl
end

function xlib.maketree( t )
	local pnl = vgui.Create( "DTree", t.parent )
	pnl:SetPos( t.x, t.y )
	pnl:SetSize( t.w, t.h )

	function pnl:Clear() --Clears the DTree.
		if self.RootNode.ChildNodes then
			self.RootNode.ChildNodes:Remove()
			self.m_pSelectedItem = nil
			self:InvalidateLayout()
		end
	end
	return pnl
end

function xlib.makecolorpicker( t )
	local pnl = vgui.Create( "xlibColorPanel", t.parent )
	pnl:SetPos( t.x, t.y )
	if t.noalphamodetwo then pnl:NoAlphaModeTwo() end --Provide an alternate layout with no alpha bar.
	if t.addalpha then 
		pnl:AddAlphaBar()
		if t.alphamodetwo then pnl:AlphaModeTwo() end
	end
	if t.color then pnl:SetColor( t.color ) end
	if t.repconvar then
		xlib.checkRepCvarCreated( t.repconvar )
		local col = GetConVar( t.repconvar ):GetString()
		if col == "0" then col = "0 0 0" end
		col = string.Split( col, " " )
		pnl:SetColor( Color( col[1], col[2], col[3] ) )
		function pnl.ConVarUpdated( sv_cvar, cl_cvar, ply, old_val, new_val )
			if cl_cvar == t.repconvar:lower() then
				local col = string.Split( new_val, " " )
				pnl:SetColor( Color( col[1], col[2], col[3] ) )
			end
		end
		hook.Add( "ULibReplicatedCvarChanged", "XLIB_" .. t.repconvar, pnl.ConVarUpdated )
		function pnl:OnChange( color )
			RunConsoleCommand( t.repconvar, color.r .. " " .. color.g .. " " .. color.b )
		end
	end
	return pnl
end

--Thanks to Megiddo for this code! :D
function xlib.wordWrap( text, width, font )
	surface.SetFont( font )
	if not surface.GetTextSize( "" ) then
		surface.SetFont( "default" ) --Set font to default if specified font does not return a size properly.
	end
	text = text:Trim()
	local output = ""
	local pos_start, pos_end = 1, 1
	while true do
		local begin, stop = text:find( "%s+", pos_end + 1 )
		
		if (surface.GetTextSize( text:sub( pos_start, begin or -1 ):Trim() ) > width and pos_end - pos_start > 0) then -- If it's not going to fit, split into a newline
			output = output .. text:sub( pos_start, pos_end ):Trim() .. "\n"
			pos_start = pos_end + 1
			pos_end = pos_end + 1
		else
			pos_end = stop
		end

		if not stop then -- We've hit our last word
			output = output .. text:sub( pos_start ):Trim()
			break
		end
	end
	return output
end

function xlib.makeprogressbar( t )
	pnl = vgui.Create( "DProgress", t.parent )
	pnl.Label = vgui.Create( "DLabel", pnl )
	pnl:SetPos( t.x, t.y )
	pnl:SetSize( t.w or 100, t.h or 20 )
	pnl:SetFraction( t.value or 0 )
	--if t.percent then
	--	pnl.m_bLabelAsPercentage = true
	--	pnl:UpdateText()
	--end
	return pnl
end

function xlib.checkRepCvarCreated( cvar )
	if GetConVar( cvar ) == nil then
		CreateClientConVar( cvar:lower(), 0, false, false ) --Replicated cvar hasn't been created via ULib. Create a temporary one to prevent errors
	end
end

--------------------------------------------------
--Megiddo and I are sick of number sliders and their spam of updating convars. Lets modify the NumSlider so that it only sets the value when the mouse is released! (And allows for textbox input)
--------------------------------------------------
function xlib.makeslider( t )
	local pnl = vgui.Create( "DNumSlider", t.parent )
	if t.fixclip ~= false then --Fixes clipping errors on the Knob by default, but disables it if specified.
		pnl.Slider.Knob:SetSize( 13, 13 )
		pnl.Slider.Knob:SetPos( 0, 0 )
		pnl.Slider.Knob:NoClipping( false )
	end
	pnl:SetText( t.label or "" )
	pnl:SetMinMax( t.min or 0, t.max or 100 )
	pnl:SetDecimals( t.decimal or 0 )
	if t.convar then pnl:SetConVar( t.convar ) end
	if not t.tooltipwidth then t.tooltipwidth = 250 end
	if t.tooltip then
		if t.tooltipwidth ~= 0 then
			t.tooltip = xlib.wordWrap( t.tooltip, t.tooltipwidth, "Default" )
		end
		pnl:SetToolTip( t.tooltip )
	end
	pnl:SetPos( t.x, t.y )
	pnl:SetWidth( t.w )
	pnl:SizeToContents()
	pnl.Label:SetTextColor( t.textcolor )
	pnl.Wang.selectAll = t.selectall
	if t.value then pnl:SetValue( t.value ) end

	pnl.Wang.OnLoseFocus = function( self )
		hook.Call( "OnTextEntryLoseFocus", nil, self )
		self:UpdateConvarValue()
		pnl.Wang:SetValue( pnl.Wang:GetValue() )
	end

	--Slider update stuff (Most of this code is copied from the default DNumSlider)
	pnl.Slider.TranslateValues = function( self, x, y )
		--Store the value and update the textbox to the new value
		pnl_x = x
		local val = pnl.Wang.m_numMin + ( ( pnl.Wang.m_numMax - pnl.Wang.m_numMin ) * x )
		if pnl.Wang.m_iDecimals == 0 then
			val = Format( "%i", val )
		else
			val = Format( "%." .. pnl.Wang.m_iDecimals .. "f", val )
			-- Trim trailing 0's and .'s 0 this gets rid of .00 etc
			val = string.TrimRight( val, "0" )
			val = string.TrimRight( val, "." )
		end
		pnl.Wang:SetText( val )
		return x, y
	end
	pnl.Slider.OnMouseReleased = function( self, mcode )
		pnl.Slider:SetDragging( false )
		pnl.Slider:MouseCapture( false )
		--Update the actual value to the value we stored earlier
		pnl.Wang:SetFraction( pnl_x )
	end

	--This makes it so the value doesnt change while you're typing in the textbox
	pnl.Wang.OnTextChanged = function() end

	--NumberWang update stuff(Most of this code is copied from the default DNumberWang)
	pnl.Wang.OnCursorMoved = function( self, x, y )
		if ( not self.Dragging ) then return end
		local fVal = self:GetFloatValue()
		local y = gui.MouseY()
		local Diff = y - self.HoldPos
		local Sensitivity = math.abs(Diff) * 0.025
		Sensitivity = Sensitivity / ( self:GetDecimals() + 1 )
		fVal = math.Clamp( fVal + Diff * Sensitivity, self.m_numMin, self.m_numMax )
		self:SetFloatValue( fVal )
		local x, y = self.Wanger:LocalToScreen( self.Wanger:GetWide() * 0.5, 0 )
		input.SetCursorPos( x, self.HoldPos )
		--Instead of updating the value, we're going to store it for later
		pnl_fVal = fVal

		if ( ValidPanel( self.IndicatorT ) ) then self.IndicatorT:InvalidateLayout() end
		if ( ValidPanel( self.IndicatorB ) ) then self.IndicatorB:InvalidateLayout() end

		--Since we arent updating the value, we need to manually set the value of the textbox. YAY!!
		val = tonumber( fVal )
		val = val or 0
		if ( self.m_iDecimals == 0 ) then
			val = Format( "%i", val )
		elseif ( val ~= 0 ) then
			val = Format( "%."..self.m_iDecimals.."f", val )
			val = string.TrimRight( val, "0" )
			val = string.TrimRight( val, "." )
		end
		self:SetText( val )
	end

	pnl.Wang.OnMouseReleased = function( self, mousecode )
		if ( self.Dragging ) then
			self:EndWang()
			self:SetValue( pnl_fVal )
		return end
	end

	pnl.enabled = true
	pnl.SetDisabled = function( self, bval )
		self.enabled = not bval
		self:SetMouseInputEnabled( not bval )
		self.Slider.Knob:SetVisible( not bval )
		self.Wang:SetPaintBackgroundEnabled( bval )
	end
	if t.disabled then pnl:SetDisabled( t.disabled ) end

	--Replicated Convar Updating
	if t.repconvar then
		xlib.checkRepCvarCreated( t.repconvar )
		pnl:SetValue( GetConVar( t.repconvar ):GetFloat() )
		function pnl.ConVarUpdated( sv_cvar, cl_cvar, ply, old_val, new_val )
			if cl_cvar == t.repconvar:lower() then
				if ( IsValid( pnl ) ) then	--Prevents random errors when joining. TODO: Remove this when sliders are.. better?
					pnl:SetValue( new_val )
				end
			end
		end
		hook.Add( "ULibReplicatedCvarChanged", "XLIB_" .. t.repconvar, pnl.ConVarUpdated )
		function pnl:OnValueChanged( val )
			RunConsoleCommand( t.repconvar, tostring( val ) )
		end
		pnl.Wang.ConVarStringThink = function() end --Override think functions to remove Garry's convar check to (hopefully) speed things up
		pnl.ConVarNumberThink = function() end
		pnl.ConVarStringThink = function() end
		pnl.ConVarChanged = function() end
	end
	return pnl
end


-----------------------------------------
--A stripped-down customized DPanel allowing for textbox input!
-----------------------------------------
local PANEL = {}
AccessorFunc( PANEL, "m_bPaintBackground", "PaintBackground" )
Derma_Hook( PANEL, "Paint", "Paint", "Panel" )
Derma_Hook( PANEL, "ApplySchemeSettings", "Scheme", "Panel" )

function PANEL:Init()
	self:SetPaintBackground( true )
end

derma.DefineControl( "xlib_Panel", "", PANEL, "EditablePanel" )


-----------------------------------------
--A copy of Garry's ColorCtrl used in the sandbox spawnmenu, with the following changes:
-- -Doesn't use convars whatsoever
-- -Is a fixed size, but you can have it with/without the alphabar, and there's two layout styles without the alpha bar.
-- -Has two functions: OnChange and OnChangeImmediate for greater control of handling changes.
-----------------------------------------
local PANEL = {}
function PANEL:Init()
	self.showAlpha=false

	self:SetSize( 130, 135 )

	self.RGBBar = vgui.Create( "DRGBPicker", self )
	self.RGBBar.OnChange = function( ctrl, color )
		if ( self.showAlpha ) then
			color.a = self.txtA:GetValue()
		end
		self:SetBaseColor( color )
	end
	self.RGBBar:SetSize( 15, 100 )
	self.RGBBar:SetPos( 5,5 )
	self.RGBBar.OnMouseReleased = function( self, mcode )
		self:MouseCapture( false )
		self:OnCursorMoved( self:CursorPos() )
		self:GetParent():OnChange( self:GetParent():GetColor() )
	end
	function self.RGBBar:SetColor( color )
		local h, s, v = ColorToHSV( color )
		self.LastY = ( 1 - h / 360 ) * self:GetTall()
	end

	self.ColorCube = vgui.Create( "DColorCube", self )
	self.ColorCube.OnUserChanged = function( ctrl ) self:ColorCubeChanged( ctrl ) end
	self.ColorCube:SetSize( 100, 100 )
	self.ColorCube:SetPos( 25,5 )
	self.ColorCube.OnMouseReleased = function( self, mcode )
		self:SetDragging( false )
		self:MouseCapture( false )
		self:GetParent():OnChange( self:GetParent():GetColor() )
	end

	self.txtR = xlib.makenumberwang{ x=7, y=110, w=35, value=255, parent=self }
	self.txtR.OnValueChanged = function( self, val )
		local p = self:GetParent()
		p:SetColor( Color( val, p.txtG:GetValue(), p.txtB:GetValue(), p.showAlpha and p.txtA:GetValue() ) )
	end
	self.txtR.OnEnter = function( self )
		local val = tonumber( self:GetValue() )
		if not val then val = 0 end
		self:OnValueChanged( val )
	end
	self.txtR.OnTextChanged = function( self )
		local val = tonumber( self:GetValue() )
		if not val then val = 0 end
		if val ~= math.Clamp( val, 0, 255 ) then self:SetValue( math.Clamp( val, 0, 255 ) ) end
		self:GetParent():UpdateColorText()
	end
	self.txtR.OnLoseFocus = function( self )
		if not tonumber( self:GetValue() ) then self:SetValue( "0" ) end
		local p = self:GetParent()
		p:OnChange( p:GetColor() )
		hook.Call( "OnTextEntryLoseFocus", nil, self )
	end
	function self.txtR.OnMouseReleased( self, mousecode )
		if ( self.Dragging ) then
			self:GetParent():OnChange( self:GetParent():GetColor() )
			self:EndWang()
		return end
	end
	self.txtG = xlib.makenumberwang{ x=47, y=110, w=35, value=100, parent=self }
	self.txtG.OnValueChanged = function( self, val )
		local p = self:GetParent()
		p:SetColor( Color( p.txtR:GetValue(), val, p.txtB:GetValue(), p.showAlpha and p.txtA:GetValue() ) )
	end
	self.txtG.OnEnter = function( self )
		local val = tonumber( self:GetValue() )
		if not val then val = 0 end
		self:OnValueChanged( val )
	end
	self.txtG.OnTextChanged = function( self )
		local val = tonumber( self:GetValue() )
		if not val then val = 0 end
		if val ~= math.Clamp( val, 0, 255 ) then self:SetValue( math.Clamp( val, 0, 255 ) ) end
		self:GetParent():UpdateColorText()
	end
	self.txtG.OnLoseFocus = function( self )
		if not tonumber( self:GetValue() ) then self:SetValue( "0" ) end
		local p = self:GetParent()
		p:OnChange( p:GetColor() )
		hook.Call( "OnTextEntryLoseFocus", nil, self )
	end
	function self.txtG.OnMouseReleased( self, mousecode )
		if ( self.Dragging ) then
			self:GetParent():OnChange( self:GetParent():GetColor() )
			self:EndWang()
		return end
	end
	self.txtB = xlib.makenumberwang{ x=87, y=110, w=35, value=100, parent=self }
	self.txtB.OnValueChanged = function( self, val )
		local p = self:GetParent()
		p:SetColor( Color( p.txtR:GetValue(), p.txtG:GetValue(), val, p.showAlpha and p.txtA:GetValue() ) )
	end
	self.txtB.OnEnter = function( self )
		local val = tonumber( self:GetValue() )
		if not val then val = 0 end
		self:OnValueChanged( val )
	end
	self.txtB.OnTextChanged = function( self )
		local val = tonumber( self:GetValue() )
		if not val then val = 0 end
		if val ~= math.Clamp( val, 0, 255 ) then self:SetValue( math.Clamp( val, 0, 255 ) ) end
		self:GetParent():UpdateColorText()
	end
	self.txtB.OnLoseFocus = function( self )
		if not tonumber( self:GetValue() ) then self:SetValue( "0" ) end
		local p = self:GetParent()
		p:OnChange( p:GetColor() )
		hook.Call( "OnTextEntryLoseFocus", nil, self )
	end
	function self.txtB.OnMouseReleased( self, mousecode )
		if ( self.Dragging ) then
			self:GetParent():OnChange( self:GetParent():GetColor() )
			self:EndWang()
		return end
	end

	self:SetColor( Color( 255, 0, 0, 255 ) )
end

function PANEL:AddAlphaBar()
	self.showAlpha = true
	self.txtA = xlib.makenumberwang{ x=150, y=82, w=35, value=255, parent=self }
	self.txtA.OnValueChanged = function( self, val )
		local p = self:GetParent()
		p:SetColor( Color( p.txtR:GetValue(), p.txtG:GetValue(), p.txtB:GetValue(), val ) )
	end
	self.txtA.OnEnter = function( self )
		local val = tonumber( self:GetValue() )
		if not val then val = 0 end
		self:OnValueChanged( val )
	end
	self.txtA.OnTextChanged = function( self )
		local p = self:GetParent()
		local val = tonumber( self:GetValue() )
		if not val then val = 0 end
		if val ~= math.Clamp( val, 0, 255 ) then self:SetValue( math.Clamp( val, 0, 255 ) ) end
		p.AlphaBar:SetValue( 1 - ( val / 255) )
		p:OnChangeImmediate( p:GetColor() )
	end
	self.txtA.OnLoseFocus = function( self )
		if not tonumber( self:GetValue() ) then self:SetValue( "0" ) end
		local p = self:GetParent()
		p:OnChange( p:GetColor() )
		hook.Call( "OnTextEntryLoseFocus", nil, self )
	end
	function self.txtA.OnMouseReleased( self, mousecode )
		if ( self.Dragging ) then
			self:GetParent():OnChange( self:GetParent():GetColor() )
			self:EndWang()
		return end
	end

	self.AlphaBar = vgui.Create( "DAlphaBar", self )
	self.AlphaBar.OnChange = function( ctrl, alpha ) self:SetColorAlpha( alpha*255 ) end
	self.AlphaBar:SetPos( 25,5 )
	self.AlphaBar:SetSize( 15, 100 )
	self.AlphaBar:SetValue( 1 )
	self.AlphaBar.OnMouseReleased = function( self, mcode )
		self:MouseCapture( false )
		self:OnCursorMoved( self:CursorPos() )
		self:GetParent():OnChange( self:GetParent():GetColor() )
	end
	
	self.ColorCube:SetPos( 45,5 )
	self:SetSize( 190, 110 )
	self.txtR:SetPos( 150, 7 )
	self.txtG:SetPos( 150, 32 )
	self.txtB:SetPos( 150, 57 )
end

function PANEL:AlphaModeTwo()
	self:SetSize( 156, 135 )
	self.AlphaBar:SetPos( 28,5 )
	self.ColorCube:SetPos( 51,5 )
	self.txtR:SetPos( 5, 110 )
	self.txtG:SetPos( 42, 110 )
	self.txtB:SetPos( 79, 110 )
	self.txtA:SetPos( 116, 110 )
end

function PANEL:NoAlphaModeTwo()
	self:SetSize( 170, 110 )
	self.txtR:SetPos( 130, 7 )
	self.txtG:SetPos( 130, 32 )
	self.txtB:SetPos( 130, 57 )
end

function PANEL:UpdateColorText()
	self.RGBBar:SetColor( Color( self.txtR:GetValue(), self.txtG:GetValue(), self.txtB:GetValue(), self.showAlpha and self.txtA:GetValue() ) )
	self.ColorCube:SetColor( Color( self.txtR:GetValue(), self.txtG:GetValue(), self.txtB:GetValue(), self.showAlpha and self.txtA:GetValue() ) )
	if ( self.showAlpha ) then self.AlphaBar:SetBarColor( Color( self.txtR:GetValue(), self.txtG:GetValue(), self.txtB:GetValue(), 255 ) ) end
	self:OnChangeImmediate( self:GetColor() )
end

function PANEL:SetColor( color )
	self.RGBBar:SetColor( color )
	self.ColorCube:SetColor( color )

	if tonumber( self.txtR:GetValue() ) ~= color.r then self.txtR:SetText( color.r or 255 ) end
	if tonumber( self.txtG:GetValue() ) ~= color.g then self.txtG:SetText( color.g or 0 ) end
	if tonumber( self.txtB:GetValue() ) ~= color.b then self.txtB:SetText( color.b or 0 ) end

	if ( self.showAlpha ) then
		self.txtA:SetText( color.a or 0 )
		self.AlphaBar:SetBarColor( Color( color.r, color.g, color.b ) )
		self.AlphaBar:SetValue( ( ( color.a or 0 ) / 255) )
	end

	self:OnChangeImmediate( color )
end

function PANEL:SetBaseColor( color )
	self.ColorCube:SetBaseRGB( color )

	self.txtR:SetText(self.ColorCube.m_OutRGB.r)
	self.txtG:SetText(self.ColorCube.m_OutRGB.g)
	self.txtB:SetText(self.ColorCube.m_OutRGB.b)

	if ( self.showAlpha ) then
		self.AlphaBar:SetBarColor( Color( self:GetColor().r, self:GetColor().g, self:GetColor().b ) )
	end
	self:OnChangeImmediate( self:GetColor() )
end

function PANEL:SetColorAlpha( alpha )
	if ( self.showAlpha ) then
		alpha = alpha or 0
		self.txtA:SetValue(alpha)
	end
end

function PANEL:ColorCubeChanged( cube )
	self.txtR:SetText(cube.m_OutRGB.r)
	self.txtG:SetText(cube.m_OutRGB.g)
	self.txtB:SetText(cube.m_OutRGB.b)
	if ( self.showAlpha ) then
		self.AlphaBar:SetBarColor( Color( self:GetColor().r, self:GetColor().g, self:GetColor().b ) )
	end
	self:OnChangeImmediate( self:GetColor() )
end

function PANEL:GetColor()
	local color = Color( self.txtR:GetValue(), self.txtG:GetValue(), self.txtB:GetValue() )
	if ( self.showAlpha ) then
		color.a = self.txtA:GetValue()
	else
		color.a = 255
	end
	return color
end

function PANEL:PerformLayout()
	self:SetColor( Color( self.txtR:GetValue(), self.txtG:GetValue(), self.txtB:GetValue(), self.showAlpha and self.txtA:GetValue() ) )
end

function PANEL:OnChangeImmediate( color )
	--For override
end

function PANEL:OnChange( color )
	--For override
end

vgui.Register( "xlibColorPanel", PANEL, "DPanel" )



-------------------------
--Custom Animation System
-------------------------
--This is a heavily edited version of Garry's derma animation stuff with the following differences:
	--Allows for animation chains (one animation to begin right after the other)
	--Can call functions anywhere during the animation cycle.
	--Reliably calls a start/end function for each animation so the animations always shows/ends properly.
	--Animations can be completely disabled by setting 0 for the animation time.
local xlibAnimation = {}
xlibAnimation.__index = xlibAnimation

function xlib.anim( runFunc, startFunc, endFunc )
	local anim = {}
	anim.runFunc = runFunc
	anim.startFunc = startFunc
	anim.endFunc = endFunc
	setmetatable( anim, xlibAnimation )
	return anim
end

xlib.animTypes = {}
xlib.registerAnimType = function( name, runFunc, startFunc, endFunc )
	xlib.animTypes[name] = xlib.anim( runFunc, startFunc, endFunc )
end

function xlibAnimation:Start( Length, Data )
	self.startFunc( Data )
	if ( Length == 0 ) then
		self.endFunc( Data )
		xlib.animQueue_call()
	else
		self.Length = Length
		self.StartTime = SysTime()
		self.EndTime = SysTime() + Length
		self.Data = Data
		table.insert( xlib.activeAnims, self )
	end
end

function xlibAnimation:Stop()
	self.runFunc( 1, self.Data )
	self.endFunc( self.Data )
	for i, v in ipairs( xlib.activeAnims ) do
		if v == self then table.remove( xlib.activeAnims, i ) break end
	end
	xlib.animQueue_call()
end

function xlibAnimation:Run()
	local CurTime = SysTime()
	local delta = (CurTime - self.StartTime) / self.Length
	if ( CurTime > self.EndTime ) then
		self:Stop()
	else
		self.runFunc( delta, self.Data )
	end
end

--Animation Ticker
xlib.activeAnims = {}
xlib.animRun = function()
	for _, v in ipairs( xlib.activeAnims ) do
		v.Run( v )
	end
end
hook.Add( "XLIBDoAnimation", "xlib_runAnims", xlib.animRun )

-------------------------
--Animation chain manager
-------------------------
xlib.animQueue = {}
xlib.animBackupQueue = {}

--This will allow us to make animations run faster when linked together 
--Makes sure the entire animation length = animationTime (~0.2 sec by default)
xlib.animStep = 0

--Call this to begin the animation chain
xlib.animQueue_start = function()
	if xlib.animRunning then --If a new animation is starting while one is running, then we should instantly stop the old one.
		xlib.animQueue_forceStop()
		return --The old animation should be finished now, and the new one should be starting
	end
	xlib.curAnimStep = xlib.animStep
	xlib.animStep = 0
	xlib.animQueue_call()
end

xlib.animQueue_forceStop = function()
	--This will trigger the currently chained animations to run at 0 seconds.
	xlib.curAnimStep = -1
	if type( xlib.animRunning ) == "table" then xlib.animRunning:Stop() end
end

xlib.animQueue_call = function()
	if #xlib.animQueue > 0 then
		local func = xlib.animQueue[1]
		table.remove( xlib.animQueue, 1 )
		func()
	else
		xlib.animRunning = nil
		--Check for queues in the backup that haven't been started.
		if #xlib.animBackupQueue > 0 then
			xlib.animQueue = table.Copy( xlib.animBackupQueue )
			xlib.animBackupQueue = {}
			xlib.animQueue_start()
		end
	end
end	

xlib.addToAnimQueue = function( obj, ... )
	local arg = { ... }
	--If there is an animation running, then we need to store the new animation stuff somewhere else temporarily.
	--Also, if ignoreRunning is true, then we'll add the anim to the regular queue regardless of running status.
	local outTable = xlib.animRunning and xlib.animBackupQueue or xlib.animQueue
		
	if type( obj ) == "function" then
		table.insert( outTable, function() xlib.animRunning = true  obj( unpack( arg ) )  xlib.animQueue_call() end )
	elseif type( obj ) == "string" and xlib.animTypes[obj] then
		--arg[1] should be data table, arg[2] should be length
		length = arg[2] or xgui.settings.animTime
		xlib.animStep = xlib.animStep + 1
		table.insert( outTable, function() xlib.animRunning = xlib.animTypes[obj]  xlib.animRunning:Start( ( xlib.curAnimStep ~= -1 and ( length/xlib.curAnimStep ) or 0 ), arg[1] ) end )
	else
		Msg( "Error: XGUI recieved an invalid animation call! TYPE:" .. type( obj ) .. " VALUE:" .. tostring( obj ) .. "\n" )
	end
end

-------------------------
--Default Animation Types
-------------------------
--Slide animation
local function slideAnim_run( delta, data )
	--data.panel, data.startx, data.starty, data.endx, data.endy, data.setvisible
	data.panel:SetPos( data.startx+((data.endx-data.startx)*delta), data.starty+((data.endy-data.starty)*delta) )
end

local function slideAnim_start( data )
	data.panel:SetPos( data.startx, data.starty )
	if data.setvisible == true then
		data.panel:SetVisible( true )
	end
end

local function slideAnim_end( data )
	data.panel:SetPos( data.endx, data.endy )
	if data.setvisible == false then
		data.panel:SetVisible( false )
	end
end
xlib.registerAnimType( "pnlSlide", slideAnim_run, slideAnim_start, slideAnim_end )

--Fade animation
local function fadeAnim_run( delta, data )
	if data.panelOut then data.panelOut:SetAlpha( 255-(delta*255) ) data.panelOut:SetVisible( true ) end
	if data.panelIn then data.panelIn:SetAlpha( 255 * delta ) data.panelIn:SetVisible( true ) end
end

local function fadeAnim_start( data )
	if data.panelOut then data.panelOut:SetAlpha( 255 ) data.panelOut:SetVisible( true ) end
	if data.panelIn then data.panelIn:SetAlpha( 0 ) data.panelIn:SetVisible( true ) end
end

local function fadeAnim_end( data )
	if data.panelOut then data.panelOut:SetVisible( false ) end
	if data.panelIn then data.panelIn:SetAlpha( 255 ) end
end
xlib.registerAnimType( "pnlFade", fadeAnim_run, fadeAnim_start, fadeAnim_end )