
DeriveGamemode( "fretta" )

include("vgui/continuevote.lua")

---- Continue vote at end of round
local cont_chooser = nil
local function GetContinueChooser()
   if IsValid(cont_chooser) then return cont_chooser end
   cont_chooser = vgui.Create("ContinueVote")
   return cont_chooser
end

function GM:ShowContinueChooser()
   GetContinueChooser():Show()
end

function GM:HideContinueChooser()
   GetContinueChooser():Hide()
end

function GM:ContinueVoted(want)
   if GetGlobalBool("InContinueVote", false) then
      RunConsoleCommand("votecontinue", want and 1 or 0)
   end
end

---- Fretta overrides/fixes

util.SafeRemoveHook("InitPostEntity", "CreateDeathNotify")

function GM:DrawPlayerRing(ply)
end
util.SafeRemoveHook("PrePlayerDraw", "DrawPlayerRing")

function GM:InputMouseApply(cmd, x, y, angle)
end

function GM:Move(ply, mv)
end

function GM:KeyPress(ply, key)
end

function GM:KeyRelease(ply, key)
end


local logo = surface.GetTextureID("VGUI/ttt/score_logo")
local lw, lh = 215 / 2, 220 / 2
local helptxt = {text="", font="Trebuchet22", xalign=TEXT_ALIGN_CENTER, color=COLOR_WHITE}
local bgcolor = Color(200, 0, 0, 40)
function GM:PaintSplashScreen(w, h)
   draw.RoundedBox(16, w/2 - 230, h/2 - 128, 460, 256, bgcolor)

   surface.SetTexture( logo )
   surface.SetDrawColor( 255, 255, 255, 255 )
   surface.DrawTexturedRect( w / 2 - lw, h / 2 - lh, 256, 256 )

   helptxt.text = LANG.GetTranslation("intro_help")

   helptxt.pos = {w / 2, h / 2 + 80}
   draw.TextShadow(helptxt, 2, 255)
end
