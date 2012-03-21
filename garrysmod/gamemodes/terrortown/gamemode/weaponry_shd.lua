
WEPS = {}

function WEPS.TypeForWeapon(class)
   local tbl = util.WeaponForClass(class)
   return tbl and tbl.Kind or WEAPON_NONE
end

-- You'd expect this to go on the weapon entity, but we need to be able to call
-- it on a swep table as well.
function WEPS.IsEquipment(wep)
   return wep.Kind and wep.Kind >= WEAPON_EQUIP
end
