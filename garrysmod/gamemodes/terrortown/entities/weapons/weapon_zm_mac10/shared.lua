if SERVER then
   AddCSLuaFile( "shared.lua" )
end

SWEP.HoldType = "ar2"

if CLIENT then

   SWEP.PrintName = "MAC10"			
   SWEP.Slot = 2

   SWEP.Icon = "VGUI/ttt/icon_mac"
end


SWEP.Base = "weapon_tttbase"

SWEP.Kind = WEAPON_HEAVY
SWEP.WeaponID = AMMO_MAC10

SWEP.Primary.Damage      = 15
SWEP.Primary.Delay       = 0.065
SWEP.Primary.Cone        = 0.03 -- 0.025
SWEP.Primary.ClipSize    = 30
SWEP.Primary.ClipMax     = 60
SWEP.Primary.DefaultClip = 30
SWEP.Primary.Automatic   = true
SWEP.Primary.Ammo        = "smg1"
SWEP.Primary.Recoil      = 1.1
SWEP.Primary.Sound       = Sound( "Weapon_mac10.Single" )

SWEP.AutoSpawnable = true

SWEP.AmmoEnt = "item_ammo_smg1_ttt"

SWEP.ViewModel  = "models/weapons/v_smg_mac10.mdl"
SWEP.WorldModel = "models/weapons/w_smg_mac10.mdl"

SWEP.HeadshotMultiplier = 2

SWEP.IronSightsPos = Vector( 6.62, -3, 2.9 )
SWEP.IronSightsAng = Vector( 0.7, 5.3, 7 )

SWEP.DeploySpeed = 3
