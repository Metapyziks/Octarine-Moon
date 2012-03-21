-- Key overrides for TTT specific keyboard functions

local function SendWeaponDrop()
   RunConsoleCommand("ttt_dropweapon")

   -- Turn off weapon switch display if you had it open while dropping, to avoid
   -- inconsistencies.
   WSWITCH:Disable()
end

function GM:OnSpawnMenuOpen()
   SendWeaponDrop()
end

function GM:PlayerBindPress(ply, bind, pressed)
   if not ValidEntity(ply) then return end

   if bind == "invnext" and pressed then
      if ply:IsSpec() then
         TIPS.Next()
      else
         WSWITCH:SelectNext()
      end
      return true
   elseif bind == "invprev" and pressed then
      if ply:IsSpec() then
         TIPS.Prev()
      else
         WSWITCH:SelectPrev()
      end
      return true
   elseif bind == "+attack" then
      if WSWITCH.Show then
         if not pressed then
            WSWITCH:ConfirmSelection()
         end
         return true
      end
   elseif bind == "+sprint" then
      -- set voice type here just in case shift is no longer down when the
      -- PlayerStartVoice hook runs, which might be the case when switching to
      -- steam overlay
      ply.traitor_gvoice = false
      RunConsoleCommand("tvog", "0")
      return true
   elseif bind == "+use" and pressed then
      if ply:IsSpec() then
         RunConsoleCommand("ttt_spec_use")
         return true
      elseif TBHUD:PlayerIsFocused() then
         return TBHUD:UseFocused()
      end
   elseif string.sub(bind, 1, 4) == "slot" and pressed then
      local idx = tonumber(string.sub(bind, 5, -1)) or 1

      -- if radiomenu is open, override weapon select
      if RADIO.Show then
         RADIO:SendCommand(idx)
      else
         WSWITCH:SelectSlot(idx)
      end
      return true
   elseif string.find(bind, "zoom") and pressed then
      -- open or close radio
      RADIO:ShowRadioCommands(not RADIO.Show)
      return true
   elseif bind == "+voicerecord" then
      if not VOICE.CanSpeak() then
         return true
      end
   elseif bind == "gm_showteam" and pressed and ply:IsSpec() then
      local m = VOICE.CycleMuteState()
      RunConsoleCommand("ttt_mute_team", m)
      return true
   elseif bind == "+duck" and pressed and ply:IsSpec() then
      if not IsValid(ply:GetObserverTarget()) then
         if GAMEMODE.ForcedMouse then
            gui.EnableScreenClicker(false)
            GAMEMODE.ForcedMouse = false
         else
            gui.EnableScreenClicker(true)
            GAMEMODE.ForcedMouse = true
         end
      end
   elseif bind == "messagemode" and pressed and ply:IsSpec() then
      if GAMEMODE.round_state == ROUND_ACTIVE and DetectiveMode() then
         LANG.Msg("spec_teamchat_hint")
         return true
      end
   elseif bind == "noclip" and pressed then
      if not GetConVar("sv_cheats"):GetBool() then
         RunConsoleCommand("ttt_equipswitch")
         return true
      end
   elseif (bind == "gmod_undo" or bind == "undo") and pressed then
      RunConsoleCommand("ttt_dropammo")
      return true
   elseif string.sub(bind, 1, 8) == "+gm_spec" and pressed then
      local want = nil
      if bind == "+gm_special 1" then
         want = false
      elseif bind == "+gm_special 2" then
         want = true
      end

      if want != nil then
         GAMEMODE:ContinueVoted(want)
         return true
      end

      if bind == "+gm_special 11" then
         RunConsoleCommand("ttt_toggle_disguise")
      end
   end
end

-- Note that for some reason KeyPress and KeyRelease are called multiple times
-- for the same key event in multiplayer.
function GM:KeyPress(ply, key)
   if not IsFirstTimePredicted() then return end
   if not ValidEntity(ply) or ply != LocalPlayer() then return end

   if key == IN_SPEED and ply:IsActiveTraitor() then
      timer.Simple(0.05, RunConsoleCommand, "+voicerecord")
   end
end

function GM:KeyRelease(ply, key)
   if not IsFirstTimePredicted() then return end
   if not ValidEntity(ply) or ply != LocalPlayer() then return end

   if key == IN_SPEED and ply:IsActiveTraitor() then
      timer.Simple(0.05, RunConsoleCommand, "-voicerecord")
   end
end

