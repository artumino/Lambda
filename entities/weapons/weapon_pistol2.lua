SWEP.PrintName 				= "#HL2_Pistol"
SWEP.Base 					= "weapon_lambda_base"
SWEP.FiresUnderwater 		= true

SWEP.Primary.ClipSize		= 18
SWEP.Primary.DefaultClip	= 18
SWEP.Primary.Automatic		= true
SWEP.Primary.SemiAutomatic  = true
SWEP.Primary.Ammo			= "Pistol"
SWEP.Primary.Delay 		    = 0.09
SWEP.Primary.SemiDelay      = 0.1
SWEP.Primary.AccuracyPenalty = 0.2
SWEP.Primary.Sound          = "Weapon_Pistol.Single"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo			= "none"

SWEP.AutoReload             = true
SWEP.UseHands 				= true
SWEP.ViewModel 				= "models/weapons/c_pistol.mdl"
SWEP.WorldModel 			= "models/weapons/w_pistol.mdl"
SWEP.HoldType 				= "pistol"
SWEP.ViewModelFOV 			= 54
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

function SWEP:Initialize()

	self:SetHoldType( self.HoldType )

	self.CalcViewModelView = nil
	self.GetViewModelPosition = nil

	self.AccuracyPenalty = 0.0
	self.NumShotsFired = 0
	self.LastAttackTime = 0
	self.SoonestPrimaryAttack = 0
	self.IsReloading = false
	self.NextIdleTime = CurTime()
	self.SpreadCone = Vector(0, 0, 0)
	self.Initialized = true

end

function SWEP:WeaponSound(sndType)
	local owner = self:GetOwner()
	if IsValid(owner) and owner:IsNPC() and (sndType == "RELOAD" or sndType == "SINGLE") then
		sndType = sndType .. "_NPC"
	end
	local snd = self.Sounds[sndType]
	if snd ~= nil then
		self.Weapon:EmitSound(snd)
	end
end

function SWEP:GetPrimaryAttackActivity()
	if self.NumShotsFired < 1 then
		return ACT_VM_PRIMARYATTACK
	elseif self.NumShotsFired < 2 then
		return ACT_VM_RECOIL1
	elseif self.NumShotsFired < 3 then
		return ACT_VM_RECOIL2
	end
	return ACT_VM_RECOIL3
end

function SWEP:PrimaryFireEffect()

	local owner = self:GetOwner()
	local act = self:GetPrimaryAttackActivity()

	self:SendWeaponAnim( act )
	owner:SetAnimation( PLAYER_ATTACK1 )
	owner:MuzzleFlash()

end

local VECTOR_CONE_5DEGREES = Vector( 0.04362, 0.04362, 0.04362 )
local VECTOR_CONE_1DEGREES = Vector( 0.00873, 0.00873, 0.00873 )
local VECTOR_CONE_6DEGREES = Vector( 0.05234, 0.05234, 0.05234 )
local VECTOR_CONE_20DEGREES = Vector( 0.17365, 0.17365, 0.17365 )

function SWEP:GetBulletSpread()
	local owner = self:GetOwner()
	if owner:IsNPC() then
		return VECTOR_CONE_5DEGREES
	end

	local ramp = math.Remap(self.AccuracyPenalty, 0.0, self.MaximumAccuracyPenaltyTime, 0.0, 1.0)
	ramp = math.Clamp(ramp, 0.0, 1.0)

	local cone = LerpVector(ramp, VECTOR_CONE_1DEGREES, VECTOR_CONE_6DEGREES)

	return cone
end

function SWEP:GetBulletTrajectory()

	local owner = self:GetOwner()
	local movement = math.Remap(owner:GetVelocity():Length() * 5 / owner:GetWalkSpeed(), 0, 1, 0, 1)
	local recoil = LerpVector(movement, VECTOR_CONE_1DEGREES, VECTOR_CONE_20DEGREES) * 2
	local recoilAng = Angle()
	recoilAng.x = util.RandomFloat(0, recoil.x)
	recoilAng.y = util.RandomFloat(0, recoil.y)
	recoilAng.z = util.RandomFloat(0, recoil.z)

	local aimAng = owner:EyeAngles() + owner:GetViewPunchAngles() + recoilAng
	local aimDir = aimAng:Forward()

	return aimDir

end

function SWEP:PrimaryFire(bullets)

	local owner = self:GetOwner()

	local ammoId = game.GetAmmoID(self.Primary.Ammo)
	local dmgForce = game.GetAmmoForce(ammoId)
	local dmg = 1
	if owner:IsPlayer() then
		dmg = game.GetAmmoNPCDamage(ammoId)
	elseif owner:IsNPC() then
		dmg = game.GetAmmoPlayerDamage(ammoId)
	end

	local bullet = {}
	bullet.Num		= bullets
	bullet.Src		= self.Owner:GetShootPos()
	bullet.Dir		= self:GetBulletTrajectory()
	bullet.Spread	= self:GetBulletSpread()
	bullet.Tracer	= 1
	bullet.Force	= dmgForce
	bullet.Damage	= dmg
	bullet.AmmoType = self.Primary.Ammo
	bullet.TracerName = "CS_MuzzleFlash_X"

	self.Owner:FireBullets( bullet )

	self:PrimaryFireEffect()
	self:TakePrimaryAmmo(bullets)

end

function SWEP:DryFire()

	self:WeaponSound("EMPTY")
	self:SendWeaponAnim(ACT_VM_DRYFIRE)

	local duration = self:SequenceDuration()
	self:SetNextPrimaryFire( CurTime() + duration  )
	self.NextIdleTime = CurTime() + duration

end

function SWEP:CanPrimaryAttack()

	if self:Clip1() <= 0 then

		-- Empty.
		self:DryFire()

		-- Try to reload
		self:Reload()

		return false

	end

	return true

end

function SWEP:UpdatePenaltyTime()

	local owner = self:GetOwner()
	if not IsValid(owner) then
		return
	end

	if owner:KeyDown(IN_ATTACK) == false and self:GetNextPrimaryFire() < CurTime() then
		self.AccuracyPenalty = math.Clamp(self.AccuracyPenalty - FrameTime(), 0.0, self.MaximumAccuracyPenaltyTime)
	end

end

function SWEP:PrimaryAttack()

	if self:CanPrimaryAttack() == false then
		return
	end

	local curTime = CurTime()
	if self.LastAttackTime - curTime > 0.5 then
		self.NumShotsFired = 0
	else
		self.NumShotsFired = self.NumShotsFired + 1
	end
	self.LastAttackTime = curTime
	self.SoonestPrimaryAttack = curTime + self.Primary.SemiDelay

	self:WeaponSound("SINGLE")
	self:PrimaryFire(1)
	self:AddViewKick()

	self:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
	self.NextIdleTime = CurTime() + self.Primary.Delay

	self.AccuracyPenalty = self.AccuracyPenalty + self.Primary.AccuracyPenalty

	if self.AutoReload == true and self:Clip1() == 0 and self:Ammo1() > 0 then
		self:Reload()
	end

end

function SWEP:SecondaryAttack()
end

function SWEP:OnReloaded()
	self.bReloading = false
end

function SWEP:Reload()
	if self:Ammo1() == 0 then
		return
	end
	if self:DefaultReload( ACT_VM_RELOAD ) == true then
		self:WeaponSound("RELOAD")
		self.bReloading = true
		self.AccuracyPenalty = 0.0
	end
end

function SWEP:Deploy()
	self.NextIdleTime = CurTime()
end

function SWEP:Holster( wep )
	self:StopSounds()
	return true
end

function SWEP:IsReloading()
	return self.bReloading or false
end

function SWEP:StopSounds()
	for _,v in pairs(self.Sounds) do
		if v == "" then
			continue
		end
		self:StopSound(v)
	end
end

function SWEP:Think()

	if self.Initialized ~= true then
		self:Initialize()
	end

	local owner = self:GetOwner()
	if IsValid(owner) == false then
		return
	end

	if self.NextIdleTime ~= 0 and CurTime() >= self.NextIdleTime then
		self:SendWeaponAnim(ACT_VM_IDLE)
		self.NextIdleTime = 0
	end

	self:UpdatePenaltyTime()

	if self.Primary.SemiAutomatic == true and owner:KeyDown(IN_ATTACK) == false and self.SoonestPrimaryAttack < CurTime() and self:Clip1() > 0 then
		self:SetNextPrimaryFire(CurTime() - 0.1)
	end

end

function SWEP:AddViewKick()

	local owner = self:GetOwner()
	--owner:ViewPunchReset(0)

	math.randomseed(1 + self.NumShotsFired)

	local ang = Angle()
	ang.x = util.RandomFloat(1.25, 1.5)
	ang.x = -0.9 --util.RandomFloat(-0.5, -1.0)
	ang.z = 0.0

	owner:ViewPunch(ang)

end
