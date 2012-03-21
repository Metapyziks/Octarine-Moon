-- This is a set of overrides and hook/concommand removals of things Fretta
-- installs that are for whatever reason not wanted in TTT.

-- Bring on the pain...
DeriveGamemode( "fretta" )

AddCSLuaFile("cl_fretta_must_die.lua")
AddCSLuaFile("vgui/continuevote.lua")

-- Kill Fretta's class Thinks and end of game checks (doing our own)
function GM:Think()
end

-- Do not freeze players and stuff
function GM:OnEndOfGame()
end
-- FIXME: will we be using Fretta's GM:EndOfGame? if not, above not needed

-- Any dmg limitations are handled in our EntityTakeDamage hook
function GM:PlayerShouldTakeDamage(victim, attacker)
   return true
end

-- Don't see this called anywhere, nor does base gm have it, but hey
function GM:PostPlayerDeath(ply)
end

-- Fretta has a timeleft command, but it's not very meaningful here, oh well
function GM:GetGameTimeLeft()
   return math.max(0, (GetConVar("ttt_time_limit_minutes"):GetInt() * 60) - CurTime())
end


-- The thing with Fretta's round handling is that it's all very nice and all
-- but I already have something more appropriate in place. So I have to turn
-- it all off with some ugly hacks.

function GM:CheckPlayerDeathRoundEnd()
end

-- Not really necessary to remove these
--hook.Remove("PlayerDisconnected", "RoundCheck_PlayerDisconnect")
--hook.Remove("PostPlayerDeath", "RoundCheck_PostPlayerDeath")

-- None of the other timer and round stuff should ever be started up because
-- we override GM:Initialize


-- And some spectator stuff we already have
concommand.Remove("spec_mode")
concommand.Remove("spec_next")
concommand.Remove("spec_prev")

-- We don't need all the CallClassFunction stuff Fretta does.

function GM:Move(ply, mv)
end

function GM:KeyPress(ply, key)
end

function GM:KeyRelease(ply, key)
end


---- End of round continue/change voting

--- Copies some of the gamemode/mapvote structure because that works pretty
--- well.

local ttt_grace = CreateConVar("ttt_fretta_votegracerounds", "0", 0, "Number of rounds that must be played before players can vote to change map/gamemode.")

local function RoundsPlayed()
   return GetConVarNumber("ttt_round_limit") - GetGlobalInt("ttt_rounds_left", 0)
end

-- The continue vote is basically a VoteForChange vote with a different hat
function GM:StartContinueVote()
   if fretta_voting:GetBool() then
      if CurTime() < GetConVarNumber("fretta_votegraceperiod") then return end
      if RoundsPlayed() <= ttt_grace:GetInt() then return end

      BroadcastLua("GAMEMODE:ShowContinueChooser()")
      SetGlobalBool("InContinueVote", true)
   end
end

-- Start gamemode vote if necessary, else do nothing
function GM:FinishContinueVote()
   if not fretta_voting:GetBool() then return end

   SetGlobalBool("InContinueVote", false)

   BroadcastLua("GAMEMODE:HideContinueChooser()")

   if CurTime() < GetConVarNumber("fretta_votegraceperiod") then return end
   if RoundsPlayed() <= ttt_grace:GetInt() then return end

   local frac = GAMEMODE:GetFractionOfPlayersThatWantChange() -- jesus h.
   if frac > fretta_votesneeded:GetFloat() then
      GAMEMODE:StartFrettaVote()
   end
end

local function VoteForChangeSilent(ply, cmd, args)
   if not fretta_voting:GetBool() then return end
   if not IsValid(ply) then return end
   if not #args == 1 then return end
   if GAMEMODE:InGamemodeVote() then return end
   
   local want = tonumber(args[1])

   if want == 0 then
      ply:SetNWBool("WantsVote", false)
   elseif want == 1 then
      ply:SetNWBool("WantsVote", true)
   end 
end
concommand.Add("votecontinue", VoteForChangeSilent)

---- Direct map voting, skipping gamemode vote

local ttt_mapvoting = CreateConVar("ttt_fretta_mapvoting", "0")

-- Start either a gamemode or a map vote
function GM:StartFrettaVote()
   if GAMEMODE.m_bVotingStarted or GAMEMODE:InGamemodeVote() then return end

   if ttt_mapvoting:GetBool() then
      -- manually set what would be the result of a GM vote otherwise
      GAMEMODE.WinningGamemode = "terrortown"

      SetGlobalBool("InGamemodeVote", true)
      GAMEMODE.m_bVotingStarted = true

      GAMEMODE:ClearPlayerWants()
      
      GAMEMODE:StartMapVote()
   else
      -- switching gamemodes, so remove ttt-specific tags
      GAMEMODE:UpdateServerTags(true)

      GAMEMODE.BaseClass.StartGamemodeVote(GAMEMODE)
   end
end

-- Override GM.StartGamemodeVote with StartFrettaVote so that standard fretta
-- stuff like VoteForChange mechanics will transparently start the correct type
-- of vote.
GM.StartGamemodeVote = GM.StartFrettaVote


-- When someone votes for change, the chat message says "voted to change
-- gamemode". This is hardcoded, so we are forced to override and duplicate
-- GM.VoteForChange just to change it.

function GM:VoteForChange( ply )
   if GetConVarNumber( "fretta_voting" ) == 0 then return end
   if ply:GetNWBool( "WantsVote" ) then return end
   if GAMEMODE:InGamemodeVote() then return end   

   ply:SetNWBool( "WantsVote", true )
   
   local VotesNeeded = GAMEMODE:GetVotesNeededForChange()
   local NeedTxt = ""
   if VotesNeeded > 0 and CurTime() < GetConVarNumber("fretta_votegraceperiod") then
      NeedTxt = " (need "..VotesNeeded.." more)"
   end

   local votetype = ttt_mapvoting:GetBool() and "map" or "gamemode"

   PrintMessage(HUD_PRINTTALK, Format("(VOTE)\t%s voted to change the %s", ply:Nick(), votetype) .. NeedTxt)
   
   MsgN( ply:Nick() .. " voted to change the " .. votetype )
   
   timer.Simple( 5, function() GAMEMODE:CountVotesForChange() end )

end

