-- fired dart

if SERVER then
	AddCSLuaFile( "shared.lua" )
	
	ENT.CanRetrieve = true
else
	ENT.PrintName = "knife_thrown"
	ENT.Icon = "VGUI/ttt/icon_dart"
end

ENT.Type = "anim"
ENT.Model = Model( "models/crossbow_bolt.mdl" )
ENT.Sound = Sound( "weapons/crossbow/hit1.wav" )

function ENT:Initialize()
	self.Entity:SetModel( self.Model)
	self.Entity:PhysicsInit( SOLID_NONE )

	self:EmitSound( self.Sound, 100, 100 )
	
	self:SetCollisionBounds( Vector( -4, -4, -4 ), Vector( 4, 4, 4 ) )
end

if SERVER then
	function ENT:Use( activator, caller )
		MsgN( "## " .. activator:Nick() )
		if self.CanRetrieve and IsValid( activator ) and activator:IsPlayer() and activator:HasWeapon( "ttt_dartgun" ) and activator:GetAmmoCount( "AR2AltFire" ) < 2 then
			activator:GiveAmmo( 1, "AR2AltFire" )
			self:Remove()
		end
	end
end
