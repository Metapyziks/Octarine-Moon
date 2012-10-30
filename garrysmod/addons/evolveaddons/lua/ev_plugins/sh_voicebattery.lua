/*-------------------------------------------------------------------------------------------------------------------------
	TTT Voice Battery
-------------------------------------------------------------------------------------------------------------------------*/

local PLUGIN = {}
PLUGIN.Title = "Longer Voice Battery"
PLUGIN.Description = "Voice battery lasts longer."
PLUGIN.Author = "Metapyziks"
PLUGIN.Usage = nil
PLUGIN.Privileges = { "Longer Voice Battery" }

evolve:RegisterPlugin( PLUGIN )

if( CLIENT ) then
	function PLUGIN:PostGamemodeLoaded()
		local battery_max = 100
		local battery_min = 10
	
		local function GetDrainRate()
			if not GetGlobalBool("ttt_voice_drain", false) then return 0 end

			if GetRoundState() != ROUND_ACTIVE then return 0 end
			local ply = LocalPlayer()
			if (not IsValid(ply)) or ply:IsSpec() then return 0 end

			if ply:IsAdmin() or ply:IsDetective() or ply:EV_HasPrivilege( "Longer Voice Battery" ) then
				return GetGlobalFloat("ttt_voice_drain_admin", 0)
			else
				return GetGlobalFloat("ttt_voice_drain_normal", 0)
			end
		end
		
		local function GetRechargeRate()
			local r = GetGlobalFloat("ttt_voice_drain_recharge", 0.05)
			if LocalPlayer().voice_battery < battery_min then
				r = r / 2
			end

			return r
		end
		
		local function IsTraitorChatting(client)
			return client:IsActiveTraitor() and (not client.traitor_gvoice)
		end

		function VOICE.Tick()
			if not GetGlobalBool("ttt_voice_drain", false) then return end

			local client = LocalPlayer()
			if VOICE.IsSpeaking() and (not IsTraitorChatting(client)) then
				client.voice_battery = client.voice_battery - GetDrainRate()

				--print("speaking", client.voice_battery)

				if not VOICE.CanSpeak() then
					client.voice_battery = 0
					RunConsoleCommand("-voicerecord")
				end
			elseif client.voice_battery < battery_max then
				client.voice_battery = client.voice_battery + GetRechargeRate()
			end
		end
	end
end