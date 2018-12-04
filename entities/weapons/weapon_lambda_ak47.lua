
SWEP.PrintName 				= "AK-47"
SWEP.Base 					= "weapon_lambda_base"
SWEP.FiresUnderwater 		= true

SWEP.Primary.ClipSize		= 30
SWEP.Primary.DefaultClip	= 30
SWEP.Primary.Automatic		= true
SWEP.Primary.SemiAutomatic  = false
SWEP.Primary.Ammo			= "SMG1"
SWEP.Primary.Delay 		    = 0.1
SWEP.Primary.SemiDelay      = 0.1
SWEP.Primary.AccuracyPenalty = 0.4
SWEP.Primary.Spread = 0.3

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo			= "none"

SWEP.AutoReload             = true
SWEP.ViewModel 				= "models/weapons/cstrike/c_rif_ak47.mdl"
SWEP.WorldModel 			= "models/weapons/w_rif_ak47.mdl"
SWEP.HoldType 				= "smg"
SWEP.Weight 				= 3

sound.Add({
	name = "Weapon_AK47.Single",
	channel = CHAN_WEAPON,
	volume = 1.0,
	level = 80,
	pitch = { 95, 110 },
	sound = "weapons/ak47/ak47-1.wav",
})

SWEP.Sounds =
{
	["EMPTY"] = "Weapon_SMG1.Empty",
	["SINGLE"] = "Weapon_AK47.Single",
	["SINGLE_NPC"] = "Weapon_AK47.Single",
	["DOUBLE"] = "",
	["BURST"] = "Weapon_SMG1.Burst",
	["RELOAD"] = "Weapon_SMG1.Reload",
	["RELOAD_NPC"] = "Weapon_SMG1.NPC_Reload",
	["MELEE_MISS"] = "",
	["MELEE_HIT"] = "",
	["MELEE_HIT_WORLD"] = "",
	["SPECIAL1"] = "Weapon_SMG1.Special1",
	["SPECIAL2"] = "Weapon_SMG1.Special2",
	["SPECIAL3"] = "",
}

function SWEP:AddViewKick()

	local owner = self:GetOwner()

	local ang = owner:GetViewPunchAngles()

	local x = util.SharedRandom("KickBack", -1.0, -0.3, 0)
	local y = util.SharedRandom("KickBack", -0.8, 0.8, 1)
	ang.x = x
	ang.y = y

	owner:ViewPunch(ang)

end