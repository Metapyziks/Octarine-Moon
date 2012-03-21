---- Help screen

local GetTranslation = LANG.GetTranslation
local GetPTranslation = LANG.GetParamTranslation

CreateConVar("ttt_spectator_mode", "0")
CreateConVar("ttt_mute_team_check", "0")

CreateClientConVar("ttt_avoid_detective", "0", true, true)

HELPSCRN = {}

function HELPSCRN:Show()
   local margin = 15
   
   local dframe = vgui.Create("DFrame")
   local w, h = 620, 470
   dframe:SetSize(w, h)
   dframe:Center()
   dframe:SetTitle(GetTranslation("help_title"))
   dframe:ShowCloseButton(true)

   local dbut = vgui.Create("DButton", dframe)
   local bw, bh = 50, 25
   dbut:SetSize(bw, bh)
   dbut:SetPos(w - bw - margin, h - bh - margin/2)
   dbut:SetText(GetTranslation("close"))
   dbut.DoClick = function() dframe:Close() end


   local dtabs = vgui.Create("DPropertySheet", dframe)
   dtabs:SetPos(margin, margin * 2)
   dtabs:SetSize(w - margin*2, h - margin*3 - bh)

   local padding = dtabs:GetPadding()

   padding = padding * 2

   local tutparent = vgui.Create("DPanel", dtabs)
   tutparent:SetPaintBackground(false)
   tutparent:StretchToParent(0, 0, 0, 0)

   self:CreateTutorial(tutparent)

   dtabs:AddSheet(GetTranslation("help_tut"), tutparent, "gui/silkicons/add", false, false, GetTranslation("help_tut_tip"))

   local dfretta = vgui.Create("DPanel", dtabs)
   dfretta:StretchToParent(padding,padding,padding,padding)
   dfretta:SetPaintBackground(false)
   
   dtabs:AddSheet("Fretta", dfretta, "gui/silkicons/page", false, false, GetTranslation("help_fretta_tip"))

   local dsettings = vgui.Create("DPanelList", dtabs)
   dsettings:StretchToParent(0,0,padding,0)   
   dsettings:EnableVerticalScrollbar(true)
   dsettings:SetPadding(10)
   dsettings:SetSpacing(10)

   --- Interface area

   local dgui = vgui.Create("DForm", dsettings)
   dgui:SetName(GetTranslation("set_title_gui"))

   local cb = nil

   dgui:CheckBox(GetTranslation("set_tips"), "ttt_tips_enable")

   dgui:CheckBox(GetTranslation("set_voice"), "ttt_voicechat_topleft")

   cb = dgui:NumSlider(GetTranslation("set_startpopup"), "ttt_startpopup_duration", 0, 60, 0)

   cb:SetTooltip(GetTranslation("set_startpopup_tip"))

   dgui:NumSlider(GetTranslation("set_cross_opacity"), "ttt_ironsights_crosshair_opacity", 0, 1, 1)

   dgui:CheckBox(GetTranslation("set_cross_disable"), "ttt_disable_crosshair")

   dgui:CheckBox(GetTranslation("set_minimal_id"), "ttt_minimal_targetid")

   dgui:CheckBox(GetTranslation("set_healthlabel"), "ttt_health_label")

   cb = dgui:CheckBox(GetTranslation("set_lowsights"), "ttt_ironsights_lowered")
   cb:SetTooltip(GetTranslation("set_lowsights_tip"))

   cb = dgui:CheckBox(GetTranslation("set_fastsw"), "ttt_weaponswitcher_fast")
   cb:SetTooltip(GetTranslation("set_fastsw_tip"))

   cb = dgui:CheckBox(GetTranslation("set_wswitch"), "ttt_weaponswitcher_stay")
   cb:SetTooltip(GetTranslation("set_wswitch_tip"))

   cb = dgui:CheckBox(GetTranslation("set_cues"), "ttt_cl_soundcues")

   dgui:CheckBox(GetTranslation("set_splash"), "ttt_cl_disable_frettasplash")

   dsettings:AddItem(dgui)

   --- Gameplay area

   local dplay = vgui.Create("DForm", dsettings)
   dplay:SetName(GetTranslation("set_title_play"))

   cb = dplay:CheckBox(GetTranslation("set_avoid_det"), "ttt_avoid_detective")
   cb:SetTooltip(GetTranslation("set_avoid_det_tip"))

   cb = dplay:CheckBox(GetTranslation("set_specmode"), "ttt_spectator_mode")
   cb:SetTooltip(GetTranslation("set_specmode_tip"))

   -- For some reason this one defaulted to on, unlike other checkboxes, so
   -- force it to the actual value of the cvar (which defaults to off)
   local mute = dplay:CheckBox(GetTranslation("set_mute"), "ttt_mute_team_check")
   mute:SetValue(GetConVar("ttt_mute_team_check"):GetBool())
   mute:SetTooltip(GetTranslation("set_mute_tip"))

   dsettings:AddItem(dplay)

   --- Language area
   local dlanguage = vgui.Create("DForm", dsettings)
   dlanguage:SetName(GetTranslation("set_title_lang"))

   local dlang = dlanguage:MultiChoice(GetTranslation("set_lang"), "ttt_language")
   dlang:SetEditable(false)

   dlang:AddChoice("Server default", "auto")
   for _, lang in pairs(LANG.GetLanguages()) do
      dlang:AddChoice(string.Capitalize(lang), lang)
   end


   dsettings:AddItem(dlanguage)

   dtabs:AddSheet(GetTranslation("help_settings"), dsettings, "gui/silkicons/wrench", false, false, GetTranslation("help_settings_tip"))

   local dform_fretta = vgui.Create("DForm", dfretta)
   dform_fretta:SetName("Fretta")
   dform_fretta:StretchToParent(padding*2,padding,padding,padding)

   local dmodevote = vgui.Create("DButton", dform_fretta)
   dmodevote:SetFont("Trebuchet22")
   dmodevote:SetText(GetTranslation("help_vote"))
   dmodevote:SizeToContents()
   dmodevote:SetSize(dmodevote:GetWide() + margin * 2, dmodevote:GetTall() + margin*2)
   dmodevote.ApplySchemeSettings = function() end

   dmodevote.DoClick = function(s)
                          RunConsoleCommand("voteforchange")
                          dframe:Close()
                       end


   local voting = LocalPlayer():GetNWBool("WantsVote", false) or GetConVarNumber( "fretta_voting" ) == 0
   dmodevote:SetDisabled(voting)

   dform_fretta:AddItem(dmodevote)

   dform_fretta:Help(GetTranslation("help_vote_tip"))
   
   dframe:MakePopup()
end


local function ShowTTTHelp(ply, cmd, args)
   HELPSCRN:Show()
end
concommand.Add("ttt_helpscreen", ShowTTTHelp)

-- Some spectator mode bookkeeping

local function SpectateCallback(cv, old, new)
   local num = tonumber(new)
   if num and (num == 0 or num == 1) then
      RunConsoleCommand("ttt_spectate", num)
   end
end
cvars.AddChangeCallback("ttt_spectator_mode", SpectateCallback)

local function MuteTeamCallback(cv, old, new)
   local num = tonumber(new)
   if num and (num == 0 or num == 1) then
      RunConsoleCommand("ttt_mute_team", num)
   end   
end
cvars.AddChangeCallback("ttt_mute_team_check", MuteTeamCallback)

--- Tutorial

local imgpath = "VGUI/ttt/help/tut0%d"
local tutorial_pages = 6
function HELPSCRN:CreateTutorial(parent)
   local w, h = parent:GetSize()
   local m = 5

   local bg = vgui.Create("DColouredBox", parent)
   bg:StretchToParent(0,0,0,0)
   bg:SetTall(330)
   bg:SetColor(COLOR_BLACK)

   local tut = vgui.Create("DImage", parent)
   tut:StretchToParent(0, 0, 0, 0)
   tut:SetVerticalScrollbarEnabled(false)

   tut:SetImage(Format(imgpath, 1))
   tut:SetWide(1024)
   tut:SetTall(512)

   tut.current = 1


   local bw, bh = 100, 30

   local bar = vgui.Create("TTTProgressBar", parent)
   bar:SetSize(200, bh)
   bar:SetPos(0, 330)
   bar:CenterHorizontal()
   bar:SetMin(1)
   bar:SetMax(tutorial_pages)
   bar:SetValue(1)
   bar:SetColor(Color(0,200,0))

   -- fixing your panels...
   bar.UpdateText = function(s)
                       s.Label:SetText(Format("%i / %i", s.m_iValue, s.m_iMax))
                    end

   bar:UpdateText()


   local bnext = vgui.Create("DButton", parent)
   bnext:SetFont("Trebuchet22")
   bnext:SetSize(bw, bh)
   bnext:SetText(GetTranslation("next"))
   bnext:SetPos(w - bw - 10, 330)

   local bprev = vgui.Create("DButton", parent)
   bprev:SetFont("Trebuchet22")
   bprev:SetSize(bw, bh)
   bprev:SetText(GetTranslation("prev"))
   bprev:SetPos(0, 330)

   bnext.DoClick = function()
                      if tut.current < tutorial_pages then
                         tut.current = tut.current + 1
                         tut:SetImage(Format(imgpath, tut.current))
                         bar:SetValue(tut.current)
                      end
                   end

   bprev.DoClick = function()
                      if tut.current > 1 then
                         tut.current = tut.current - 1
                         tut:SetImage(Format(imgpath, tut.current))
                         bar:SetValue(tut.current)
                      end
                   end

   bnext.ApplySchemeSettings = function() end
   bprev.ApplySchemeSettings = function() end
end

