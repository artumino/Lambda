
SWEP.PrintName 				= "#HL2_Pistol"
SWEP.Base 					= "weapon_lambda_base"

SWEP.FiresUnderwater 		= true

SWEP.Primary.ClipSize		= 18
SWEP.Primary.DefaultClip	= 18
SWEP.Primary.Automatic		= true
SWEP.Primary.SemiAutomatic  = true
SWEP.Primary.Ammo			= "Pistol"
SWEP.Primary.Delay 		    = 0.5
SWEP.Primary.SemiDelay      = 0.1
SWEP.Primary.AccuracyPenalty = 0.2
SWEP.Primary.Spread = 0.1

SWEP.AutoReload             = true
SWEP.ViewModel 				= "models/weapons/c_pistol.mdl"
SWEP.WorldModel 			= "models/weapons/w_pistol.mdl"
SWEP.HoldType 				= "pistol"
SWEP.Weight 				= 2

SWEP.MaximumAccuracyPenaltyTime = 1.5

SWEP.Sounds =
{
	["EMPTY"] = "Weapon_Pistol.Empty",
	["SINGLE"] = "Weapon_Pistol.Single",
	["SINGLE_NPC"] = "Weapon_Pistol.NPC_Single",
	["DOUBLE"] = "",
	["BURST"] = "Weapon_Pistol.Burst",
	["RELOAD"] = "Weapon_Pistol.Reload",
	["RELOAD_NPC"] = "Weapon_Pistol.NPC_Reload",
	["MELEE_MISS"] = "",
	["MELEE_HIT"] = "",
	["MELEE_HIT_WORLD"] = "",
	["SPECIAL1"] = "Weapon_Pistol.Special1",
	["SPECIAL2"] = "Weapon_Pistol.Special2",
	["SPECIAL3"] = "",
}

function SWEP:DryFire()

    self:WeaponSound("EMPTY")
    self:SendWeaponAnim(ACT_VM_DRYFIRE)

    self:SetNextPrimaryFire( CurTime() + self:SequenceDuration())
    self:SetNextIdleTime(CurTime() + self:SequenceDuration())

end

function SWEP:AddViewKick()

	local owner = self:GetOwner()

	local ang = owner:GetViewPunchAngles()

	local x = util.SharedRandom("KickBack", -1.0, -0.3, 0)
	local y = util.SharedRandom("KickBack", -0.8, 0.8, 1)
	ang.x = x
	ang.y = y

	owner:ViewPunch(ang)

end