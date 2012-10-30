/*-------------------------------------------------------------------------------------------------------------------------
	TTT Get Traitors
-------------------------------------------------------------------------------------------------------------------------*/

local PLUGIN = {}
PLUGIN.Title = "Get Traitors"
PLUGIN.Description = "Tells the spectating player who is traitor"
PLUGIN.Author = "Metapyziks"
PLUGIN.ChatCommand = "gettraitors"
PLUGIN.Usage = nil
PLUGIN.Privileges = { "Get Traitors" }

function PLUGIN:Call( ply, args )
	if( ply:EV_HasPrivilege( "Get Traitors" )) then
		if( ply:Alive() and ply:IsTerror()) then
			evolve:Notify( ply, evolve.colors.red, "You can't check who is traitor while you are playing!" )
		else
			local traitors = {}
			for _, pl in ipairs( player.GetAll()) do
				if( pl:IsTraitor() and pl:Alive()) then
					table.insert( traitors, pl )
				end
			end
			
			evolve:Notify( ply, evolve.colors.red, evolve:CreatePlayerList( traitors ), evolve.colors.white, " is a traitor!" )
		end
	else
		evolve:Notify( ply, evolve.colors.red, evolve.constants.notallowed )
	end
end

if( SERVER ) then
	
	EV_InitialPlayerCount = 0
	
	function SelectRoles()
	   local choices = {}
	   local prev_roles = {
		  [ROLE_INNOCENT] = {},
		  [ROLE_TRAITOR] = {},
		  [ROLE_DETECTIVE] = {}
	   };

	   if not GAMEMODE.LastRole then GAMEMODE.LastRole = {} end

	   EV_InitialPlayerCount = 0
	   
	   for k,v in pairs(player.GetAll()) do
		  -- everyone on the spec team is in specmode
		  if IsValid(v) and (not v:IsSpec()) then
			 -- save previous role and sign up as possible traitor/detective
			 EV_InitialPlayerCount = EV_InitialPlayerCount + 1
			 local r = GAMEMODE.LastRole[v:UniqueID()] or v:GetRole() or ROLE_INNOCENT

			 table.insert(prev_roles[r], v)

			 table.insert(choices, v)
		  end

		  v:SetRole(ROLE_INNOCENT)
	   end

	   -- determine how many of each role we want
	   local choice_count = #choices
	   local traitor_count = GetTraitorCount(choice_count)
	   local det_count = GetDetectiveCount(choice_count)

	   if choice_count == 0 then return end

	   -- first select traitors
	   local ts = 0
	   while ts < traitor_count do
		  -- select random index in choices table
		  local pick = math.random(1, #choices)

		  -- the player we consider
		  local pply = choices[pick]

		  -- make this guy traitor if he was not a traitor last time, or if he makes
		  -- a roll
		  if IsValid(pply) and 
			 ((not table.HasValue(prev_roles[ROLE_TRAITOR], pply)) or (math.random(1, 3) == 2)) then
			 pply:SetRole(ROLE_TRAITOR)

			 table.remove(choices, pick)
			 ts = ts + 1
		  end
	   end

	   -- now select detectives, explicitly choosing from players who did not get
	   -- traitor, so becoming detective does not mean you lost a chance to be
	   -- traitor
	   local ds = 0
	   local min_karma = GetConVarNumber("ttt_detective_min_karma") or 0
	   while (ds < det_count) and (#choices > 1) do
		  local pick = math.random(1, #choices)
		  local pply = choices[pick]

		  -- we are less likely to be a detective unless we were innocent last round
		  if (IsValid(pply) and
			  ((pply:GetBaseKarma() > min_karma and
			   table.HasValue(prev_roles[ROLE_INNOCENT], pply)) or
			   math.random(1,4) == 2)) then
			 pply:SetRole(ROLE_DETECTIVE)

			 table.remove(choices, pick)
			 ds = ds + 1
		  end
	   end

	   GAMEMODE.LastRole = {}

	   for _, ply in pairs(player.GetAll()) do
		  -- initialize credit count for everyone based on their role
		  ply:SetDefaultCredits()

		  -- store a uid -> role map
		  GAMEMODE.LastRole[ply:UniqueID()] = ply:GetRole()
	   end
	end
end

evolve:RegisterPlugin( PLUGIN )