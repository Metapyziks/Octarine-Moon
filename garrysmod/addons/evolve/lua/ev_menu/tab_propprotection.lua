if FPP then
	MsgN("Evolve Prop Protection Menu is disabled because FPP is installed.")
else
	/*-------------------------------------------------------------------------------------------------------------------------
		Tab with Prop Protection settings
	-------------------------------------------------------------------------------------------------------------------------*/

	local TAB = {}
	TAB.Title = "Prop Protection"
	TAB.Description = "Manage Prop Protection settings."
	TAB.Icon = "icon16/world.png"
	TAB.Author = "Northdegree"
	TAB.Width = 520
	TAB.Privileges = { "Prop Protection menu" }
	TAB.Sort = 3
	TAB.ConVars = {
		{ "evolve_ppison", "Prop Protection Enabled" },
		{ "evolve_blacklistison", "Blacklist Enabled" },
		{ "evolve_blackiswhitelist", "Blacklist is Whitelist" },
		{ "evolve_highercantouchlowerrank", "Can touch lower ranks" }
	}
	TAB.ConVarCheckboxes = {}

	function TAB:ApplySettings()
		for _, v in pairs( self.ConVarCheckboxes ) do
			if ( GetConVar( v.ConVar ):GetBool() != v:GetChecked() ) then
				RunConsoleCommand( "ev", "convar", v.ConVar, evolve:BoolToInt( v:GetChecked() ) * ( v.OnValue or 1 ) )
				RunConsoleCommand("evolve_pp_save_settings")
			end
		end
	end

	function TAB:IsAllowed()
		return LocalPlayer():EV_HasPrivilege( "Prop Protection menu" )
	end

	function TAB:Update()
		for _, v in pairs( self.ConVarCheckboxes ) do
			v:SetChecked( GetConVar( v.ConVar ):GetInt() > 0 )
		end
	end

	GetBLModels = function(um)
		local model = um:ReadString()

		local Icon = vgui.Create("SpawnIcon", blpropsframe)
		Icon:SetModel(model, 1)
		Icon:SetSize(64, 64)
		Icon.DoClick = function()
			local menu = DermaMenu()
			menu:AddOption("Remove from Black-/Whitelist", function()
				RunConsoleCommand("evolve_pp_Remove_blacklist", model)
				Icon:Remove()
				blpropsframe:InvalidateLayout()
			end)
			menu:Open()
		end
		blpropsframe:AddItem(Icon)
	end
	usermessage.Hook("evolve_pp_blockedmodel", GetBLModels)


	function TAB:Initialize( pnl )	
		blpropsframe = vgui.Create("DPanelList", pnl)
		blpropsframe:SetSize(self.Width - 170, pnl:GetParent():GetTall() - 80)
		blpropsframe:SetPos(0, 0)
		blpropsframe:EnableHorizontal(true)
		blpropsframe:EnableVerticalScrollbar(true)
		blpropsframe:SetSpacing(0)
		blpropsframe:SetPadding(4)
		RunConsoleCommand("evolve_pp_get_blacklist")
		self.Settings = vgui.Create( "DPanelList", pnl )
		self.Settings:SetPos( self.Width - 165, 2 )
		self.Settings:SetSize( 165, pnl:GetParent():GetTall() - 33 )
		self.Settings:SetSpacing( 9 )
		self.Settings:SetPadding( 10 )
		self.Settings:EnableHorizontal( true )
		self.Settings:EnableVerticalScrollbar( true )
		
		for i, cv in pairs( self.ConVars ) do
			if ( ConVarExists( cv[1] ) ) then
				local cvCheckbox = vgui.Create( "DCheckBoxLabel", self.Settings )
				cvCheckbox:SetText( cv[2] )
				cvCheckbox:SetWide( self.Settings:GetWide() - 15 )
				cvCheckbox.Label:SetDark( true )
				cvCheckbox:SetValue( GetConVar( cv[1] ):GetInt() > 0 )
				cvCheckbox.ConVar = cv[1]
				cvCheckbox.OnValue = cv[3]
				cvCheckbox.OnChange = function( self )
					TAB:ApplySettings()
				end
				self.Settings:AddItem( cvCheckbox )
				
				table.insert( self.ConVarCheckboxes, cvCheckbox )
			end
		end
		local refreshbut = vgui.Create("Button", pnl)
		refreshbut:SetPos( 2, pnl:GetParent():GetTall() - 70 )
		refreshbut:SetSize( 80,30 )
		refreshbut:SetText( "Refresh" )
		refreshbut:SetVisible( true )
		function refreshbut:OnMousePressed()
			blpropsframe:Clear()
			RunConsoleCommand("evolve_pp_get_blacklist")
		end
		local addbut = vgui.Create("Button", pnl)
		addbut:SetPos( 92,pnl:GetParent():GetTall() - 70 )
		addbut:SetSize( 80,30 )
		addbut:SetText( "Add Model" )
		addbut:SetVisible( true )
		function addbut:OnMousePressed()
			Derma_StringRequest( "Add a Blacklisted Model", "Enter the path of the Model:", "", function( model )
				RunConsoleCommand("evolve_pp_add_blacklist",string.lower(model))
			end)
		end
		local addbutla = vgui.Create("Button", pnl)
		addbutla:SetPos( 182,pnl:GetParent():GetTall() - 70 )
		addbutla:SetSize( 150,30 )
		addbutla:SetText( "Add Model you're looking at" )
		addbutla:SetVisible( true )
		function addbutla:OnMousePressed()
			local LookingEnt = LocalPlayer():GetEyeTraceNoCursor().Entity
			local model = string.lower(LookingEnt:GetModel())
			if(IsValid(LookingEnt)) then
				RunConsoleCommand("evolve_pp_add_blacklist",model)	
			end	
		end
	end

	evolve:RegisterTab( TAB )
end