SWEP.PrintName = "Lambda Base"
SWEP.Author = "Lambda"
SWEP.Instructions = ""
SWEP.Spawnable = false
SWEP.AdminOnly = false
SWEP.Base = "weapon_base"

SWEP.FiresUnderwater        = false
SWEP.UseHands = true
SWEP.ViewModelFOV   = 54

SWEP.Primary.ClipSize       = -1
SWEP.Primary.DefaultClip    = -1
SWEP.Primary.Automatic      = false
SWEP.Primary.SemiAutomatic  = false
SWEP.Primary.Ammo           = "none"
SWEP.Primary.Delay          = 0.0
SWEP.Primary.SemiDelay      = 0.0
SWEP.Primary.AccuracyPenalty = 0.05
SWEP.Primary.Spread = 1.0

SWEP.Secondary.ClipSize     = -1
SWEP.Secondary.DefaultClip  = -1
SWEP.Secondary.Automatic    = false
SWEP.Secondary.Ammo         = "none"

SWEP.NPCData =
{
    MinBurst = 2,
    MaxBurst = 5,
    FireRate = 0.075,
    MinRest = 0,
    MaxRest = 0,
}

local VECTOR_CONE_1DEGREES = Vector( 0.00873, 0.00873, 0.00873 )
local VECTOR_CONE_2DEGREES = Vector( 0.01745, 0.01745, 0.01745 )
local VECTOR_CONE_3DEGREES = Vector( 0.02618, 0.02618, 0.02618 )
local VECTOR_CONE_4DEGREES = Vector( 0.03490, 0.03490, 0.03490 )
local VECTOR_CONE_5DEGREES = Vector( 0.04362, 0.04362, 0.04362 )
local VECTOR_CONE_6DEGREES = Vector( 0.05234, 0.05234, 0.05234 )
local VECTOR_CONE_7DEGREES = Vector( 0.06105, 0.06105, 0.06105 )
local VECTOR_CONE_8DEGREES = Vector( 0.06976, 0.06976, 0.06976 )
local VECTOR_CONE_9DEGREES = Vector( 0.07846, 0.07846, 0.07846 )
local VECTOR_CONE_10DEGREES = Vector( 0.08716, 0.08716, 0.08716 )
local VECTOR_CONE_15DEGREES = Vector( 0.13053, 0.13053, 0.13053 )
local VECTOR_CONE_20DEGREES = Vector( 0.17365, 0.17365, 0.17365 )

local PROFICIENCY_SPREAD_AMOUNT =
{
    [WEAPON_PROFICIENCY_POOR] = VECTOR_CONE_20DEGREES,
    [WEAPON_PROFICIENCY_AVERAGE] = VECTOR_CONE_15DEGREES,
    [WEAPON_PROFICIENCY_GOOD] = VECTOR_CONE_9DEGREES,
    [WEAPON_PROFICIENCY_VERY_GOOD] = VECTOR_CONE_3DEGREES,
    [WEAPON_PROFICIENCY_PERFECT] = VECTOR_CONE_1DEGREES,
}


-- These tell the NPC how to use the weapon
AccessorFunc( SWEP, "fNPCMinBurst",     "NPCMinBurst" )
AccessorFunc( SWEP, "fNPCMaxBurst",     "NPCMaxBurst" )
AccessorFunc( SWEP, "fNPCFireRate",     "NPCFireRate" )
AccessorFunc( SWEP, "fNPCMinRestTime",  "NPCMinRest" )
AccessorFunc( SWEP, "fNPCMaxRestTime",  "NPCMaxRest" )

function SWEP:KeyValue(k, v)
    if self.Initialized ~= true then
        self:Initialize()
    end
end

function SWEP:Initialize()

    if self.Initialized == true then
        return
    end

    self:SetHoldType( self.HoldType )

    self.CalcViewModelView = nil
    self.GetViewModelPosition = nil

    self.AccuracyPenalty = 0.0
    self.NumShotsFired = 0
    self.FireDuration = 0.0
    self.LastAttackTime = 0
    self.SoonestPrimaryAttack = 0
    self.NextIdleTime = -1
    self.SpreadCone = Vector(0, 0, 0)
    self.Initialized = true

    self:SetNPCMinBurst(self.NPCData.MinBurst)
    self:SetNPCMaxBurst(self.NPCData.MaxBurst)
    self:SetNPCFireRate(self.NPCData.FireRate)
    self:SetNPCMinRest(self.NPCData.MinRest)
    self:SetNPCMaxRest(self.NPCData.MaxRest)

end

function SWEP:SetNextIdleTime(t)
    self.NextIdleTime = t
end

function SWEP:WeaponSound(sndType)
    local owner = self:GetOwner()
    if IsValid(owner) and owner:IsNPC() and (sndType == "RELOAD" or sndType == "SINGLE") then
        sndType = sndType .. "_NPC"
    end
    local snd = self.Sounds[sndType]
    if snd ~= nil then
        self:EmitSound(snd)
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

function SWEP:DryFire()

    self:WeaponSound("EMPTY")
    self:SendWeaponAnim(ACT_VM_DRYFIRE)

    self:SetNextPrimaryFire( CurTime() + self:SequenceDuration())
    self:SetNextIdleTime(CurTime() + self:SequenceDuration())

end

function SWEP:ShouldDrawUsingViewModel()
    if SERVER then
        return false
    end
    return self:IsCarriedByLocalPlayer() and LocalPlayer():ShouldDrawLocalPlayer() == false
end

function SWEP:ShootEffects(pos, dir, spread)

    local owner = self:GetOwner()

    self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
    owner:SetAnimation( PLAYER_ATTACK1 )
    --owner:MuzzleFlash()

    local ent = self
    if self:ShouldDrawUsingViewModel() then
        ent = owner:GetViewModel()
    end

    local muzzleId = ent:LookupAttachment("muzzle")
    if muzzleId <= 0 then
        muzzleId = ent:LookupAttachment("1")
    end
    if muzzleId <= 0 then
        muzzleId = 1
    end
    local attachment = ent:GetAttachment(muzzleId)

    local fx = EffectData()
    fx:SetEntity(ent)
    fx:SetOrigin(attachment.Pos)
    fx:SetNormal(owner:GetAimVector())
    fx:SetAttachment(muzzleId)
    util.Effect("CS_MuzzleFlash_X", fx)

    local whiz = EffectData()
    whiz:SetStart(pos)
    whiz:SetOrigin(pos + (dir * 8000))
    whiz:SetFlags(0x00000001)
    whiz:SetEntity(ent)
    whiz:SetScale(util.SharedRandom("MuzzleFlash", 0.8, 1.5, 0))
    util.Effect( "TracerSound", whiz, true )

end

function SWEP:ShootBullet( ammoType, numBullets, pos, dir, spread )

    --print("ShootBullet", ammoType, numBullets, pos, dir, spread)

    local owner = self:GetOwner()

    local ammoId = game.GetAmmoID(ammoType)
    --[[
    local dmg = 1
    if owner:IsNPC() then
        dmg = game.GetAmmoPlayerDamage(ammoId)
    else
        dmg = game.GetAmmoNPCDamage(ammoId)
    end
    local dmgForce = game.GetAmmoForce(ammoId)
    print(dmgForce)
    ]]

    local bullet = {}
    bullet.Num      = numBullets
    bullet.Src      = pos
    bullet.Dir      = dir
    bullet.Spread   = spread
    bullet.Tracer   = 1
    bullet.Force    = 1  -- Scale, already takes force by ammo type.
    bullet.Damage   = 0  -- 0 for ammo damage only.
    bullet.AmmoType = ammoType
    bullet.Callback = function(attacker, tr, dmginfo)
        debugoverlay.Cross(tr.HitPos, 1, 1, Color( 0, 255, 255 ), true)
    end

    self:ShootEffects(pos, dir, spread)

    self.Owner:FireBullets( bullet )

end

function SWEP:CanPrimaryAttack()

    if self:GetNextPrimaryFire() > CurTime() then
        return false
    end

    if self:Clip1() <= 0 then

        -- Empty.
        self:DryFire()

        -- Try to reload
        self:Reload()

        return false

    end

    return true

end

function SWEP:CalculateSpread()

    local owner = self:GetOwner()
    if owner:IsNPC() then
        local proficiency = GAMEMODE:GetDifficultyWeaponProficiency()
        return PROFICIENCY_SPREAD_AMOUNT[proficiency]
    end

    local movement = owner:GetAbsVelocity():Length() / owner:GetWalkSpeed()
    local movementSpread = VECTOR_CONE_10DEGREES * movement

    local accuracyPenalty = math.Clamp(self.AccuracyPenalty / 1.0, 0.0, 1.0)
    local randVec = Vector(util.SharedRandom("Kick", -0.1, 0.1, 0), util.SharedRandom("Kick", -0.1, 0.1, 1), util.SharedRandom("Kick", 0.0, 0.1, 2))
    local penaltySpread = randVec * accuracyPenalty

    local spread = (VECTOR_CONE_2DEGREES * self.Primary.Spread) + (movementSpread + penaltySpread) * 0.5

    return spread
end

local ai_shot_bias_min = GetConVar("ai_shot_bias_min")
local ai_shot_bias_max = GetConVar("ai_shot_bias_max")

function SWEP:CalculateSpreadDir(shootDir, spread, bias)

    local x
    local y
    local z
    local ang = shootDir:Angle()
    local vecRight = ang:Right()
    local vecUp = ang:Up()

    if bias == nil then
        bias = 1.0
    else
        bias = math.Clamp(bias, 0.0, 1.0)
    end

    local shotBiasMin = ai_shot_bias_min:GetFloat();
    local shotBiasMax = ai_shot_bias_max:GetFloat();

    -- 1.0 gaussian, 0.0 is flat, -1.0 is inverse gaussian
    local shotBias = ( ( shotBiasMax - shotBiasMin ) * bias ) + shotBiasMin;
    local flatness = math.abs(shotBias) * 0.5

    repeat do
        x = util.RandomFloat(-1, 1) * flatness + util.RandomFloat(-1, 1) * (1 - flatness);
        y = util.RandomFloat(-1, 1) * flatness + util.RandomFloat(-1, 1) * (1 - flatness);
        if shotBias < 0 then
            if x >= 0 then
                x = 1.0 - x
            else
                x = -1.0 - x
            end
            if y >= 0 then
                y = 1.0 - y
            else
                y = -1.0 - y
            end
        end
        z = (x * x) + (y * y)
    end until (z > 1)

    local res = shootDir + x * spread.x * vecRight + y * spread.y * vecUp;

    return res;
end

local SF_BULLSEYE_PERFECTACC = bit.lshift(1, 20)

function SWEP:CalculateShootDir()
   local owner = self:GetOwner()

    if not owner:IsNPC() then
        return (owner:EyeAngles() + owner:GetViewPunchAngles()):Forward()
    end

    local pos = owner:GetShootPos()
    local enemy = owner:GetEnemy()
    local enemyValid = IsValid(enemy)
    local newDir = owner:GetAimVector()

    -- Show fancy water bullets infront of the player.
    if enemyValid and enemy:IsPlayer() and owner:WaterLevel() ~= 3 and enemy:WaterLevel() == 3 then

        if util.RandomInt(0, 4) < 3 then
            local fwd = enemy:GetForward()
            local vel = enemy:GetVelocity()
            vel:Normalize()

            local velScale = fwd:Dot(vel)
            if velScale < 0 then
                velScale = 0
            end

            local aimPos = enemy:EyePos() + (48 * fwd) + (velScale * vel)
            newDir = aimPos - pos
            newDir:Normalize()
        end

    end

    if enemyValid == true and enemy.EyePos ~= nil then
        -- Randomly try to hit the head.
        if util.RandomInt(0, 5) < 4 then
            newDir = enemy:WorldSpaceCenter() - pos
        else
            newDir = enemy:EyePos() - pos
        end
    end

    -- At this point the direction is 100% accurate, modify via proficiency.
    local perfectAccuracy = false
    if enemyValid and enemy:IsPlayer() == false and enemy:Classify() == CLASS_BULLSEYE then
        if enemy:HasSpawnFlags(SF_BULLSEYE_PERFECTACC) == true then
            perfectAccuracy = true
        end
    end

    if perfectAccuracy == false then
        local proficiency = GAMEMODE:GetDifficultyWeaponProficiency()
        local spread = PROFICIENCY_SPREAD_AMOUNT[proficiency]
        --[[
        newDir = newDir + (VectorRand() * amount)
        ]]
        local oldDir = Vector(newDir)
        newDir = self:CalculateSpreadDir(newDir, spread * 200, 1)
        print(newDir - oldDir)
    end

    if enemyValid and enemy:IsPlayer() and enemy:ShouldShootMissTarget(owner) and false then

        -- Supposed to miss.
        local tr = util.TraceLine({
            start = pos,
            endpos = pos + (newDir * 8192),
            mask = MASK_SHOT,
            filter = ent,
        })

        if tr.Fraction ~= 1.0 and IsValid(tr.Entity) and tr.Entity:CanTakeDamage() and tr.Entity ~= enemy then
            return newDir
        end

        local missTarget = enemy:FindMissTarget()
        if missTarget ~= nil then
            local targetPos = missTarget:NearestPoint(enemy:GetPos())
            newDir = targetPos - pos
            newDir:Normalize()
        end

    end

    return newDir

end

function SWEP:CalculateShootPos()
    local owner = self:GetOwner()
    return owner:GetShootPos()
end

function SWEP:PrimaryAttack()

    if self:CanPrimaryAttack() == false then
        return
    end

    self:WeaponSound("SINGLE")

    local owner = self:GetOwner()
    local spread = self:CalculateSpread()
    local pos = self:CalculateShootPos()
    local dir = self:CalculateShootDir()
    self:ShootBullet(self.Primary.Ammo, 1, pos, dir, spread)

    self.NumShotsFired = self.NumShotsFired + 1
    self.AccuracyPenalty = self.AccuracyPenalty + self.Primary.AccuracyPenalty

    self:TakePrimaryAmmo( 1 )
    if owner:IsPlayer() then
        self:AddViewKick()
    end

    self:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
    self:SetNextIdleTime( CurTime() + self.Primary.Delay )

    if self.AutoReload == true and self:Clip1() == 0 and self:Ammo1() > 0 then
        self:Reload()
    end

end

function SWEP:SecondaryAttack()
end

function SWEP:OnReloaded()
end

function SWEP:Reload()
    if self:Ammo1() == 0 then
        return
    end
    if self:DefaultReload( ACT_VM_RELOAD ) == true then
        print("Reload Time: ", self:SequenceDuration())
        self.ReloadTimeFinish = CurTime() + self:SequenceDuration()
        self:SetNextIdleTime( CurTime() + self:SequenceDuration() )
        self:WeaponSound("RELOAD")
        self:GetOwner():SetAnimation( PLAYER_RELOAD );
        self.AccuracyPenalty = 0.0
    end
end

function SWEP:Equip()
    if IsFirstTimePredicted() == true then
        self:SendWeaponAnim( ACT_VM_DRAW )
        self:SetNextIdleTime(CurTime() + self:SequenceDuration())
    end
    return true
end

function SWEP:Deploy()
    if IsFirstTimePredicted() == true then
        print("Deploying")
        self:SendWeaponAnim( ACT_VM_DRAW )
        self:SetNextIdleTime(CurTime() + self:SequenceDuration())
        self:SetNextPrimaryFire(CurTime() + self:SequenceDuration())
    end
    return true
end

function SWEP:Holster( wep )
    self:StopSounds()
    return true
end

function SWEP:IsReloading()
    if self.ReloadTimeFinish == nil then
        return false
    end
    return CurTime() < self.ReloadTimeFinish
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
    if IsValid(owner) and owner:IsPlayer() then
        self:UpdatePenaltyTime()

        local inactive = owner:KeyDown(IN_ATTACK) == false and owner:KeyDown(IN_ATTACK2) == false and self:IsReloading() == false
        if self.Primary.SemiAutomatic == true and inactive == true and self:Clip1() > 0 then
            self:SetNextPrimaryFire(CurTime() - 0.01)
        end

        if inactive == true and self.NextIdleTime > 0 and CurTime() >= self.NextIdleTime then
            self:SendWeaponAnim( ACT_VM_IDLE )
            self.NextIdleTime = -1
        end
    end

end

function SWEP:UpdatePenaltyTime()
    if self.AccuracyPenalty == 0 then
        return
    end

    self.AccuracyPenalty = self.AccuracyPenalty - (FrameTime() * 2)
    if self.AccuracyPenalty < 0 then
        self.AccuracyPenalty = 0
    end
end

function SWEP:Ammo1()
    local owner = self:GetOwner()
    if owner:IsNPC() then
        return 9999
    end
    return owner:GetAmmoCount( self:GetPrimaryAmmoType() )
end

function SWEP:Ammo2()
    local owner = self:GetOwner()
    if owner:IsNPC() then
        return 9999
    end
    return owner:GetAmmoCount( self:GetSecondaryAmmoType() )
end

function SWEP:SetupWeaponHoldTypeForAI( t )

    self.ActivityTranslateAI = {}
    self.ActivityTranslateAI[ ACT_IDLE ]                    = ACT_IDLE_PISTOL
    self.ActivityTranslateAI[ ACT_IDLE_ANGRY ]              = ACT_IDLE_ANGRY_PISTOL
    self.ActivityTranslateAI[ ACT_RANGE_ATTACK1 ]           = ACT_RANGE_ATTACK_PISTOL
    self.ActivityTranslateAI[ ACT_RELOAD ]                  = ACT_RELOAD_PISTOL
    self.ActivityTranslateAI[ ACT_WALK_AIM ]                = ACT_WALK_AIM_PISTOL
    self.ActivityTranslateAI[ ACT_RUN_AIM ]                 = ACT_RUN_AIM_PISTOL
    self.ActivityTranslateAI[ ACT_GESTURE_RANGE_ATTACK1 ]   = ACT_GESTURE_RANGE_ATTACK_PISTOL
    self.ActivityTranslateAI[ ACT_RELOAD_LOW ]              = ACT_RELOAD_PISTOL_LOW
    self.ActivityTranslateAI[ ACT_RANGE_ATTACK1_LOW ]       = ACT_RANGE_ATTACK_PISTOL_LOW
    self.ActivityTranslateAI[ ACT_COVER_LOW ]               = ACT_COVER_PISTOL_LOW
    self.ActivityTranslateAI[ ACT_RANGE_AIM_LOW ]           = ACT_RANGE_AIM_PISTOL_LOW
    self.ActivityTranslateAI[ ACT_GESTURE_RELOAD ]          = ACT_GESTURE_RELOAD_PISTOL

    if t == "ar2" then

        self.ActivityTranslateAI[ ACT_RANGE_ATTACK1 ]       = ACT_RANGE_ATTACK_AR2
        self.ActivityTranslateAI[ ACT_RELOAD ]              = ACT_RELOAD_SMG1
        self.ActivityTranslateAI[ ACT_IDLE ]                = ACT_IDLE_SMG1
        self.ActivityTranslateAI[ ACT_IDLE_ANGRY ]          = ACT_IDLE_ANGRY_SMG1
        self.ActivityTranslateAI[ ACT_WALK ]                = ACT_WALK_RIFLE

        self.ActivityTranslateAI[ ACT_IDLE_RELAXED ]        = ACT_IDLE_SMG1_RELAXED
        self.ActivityTranslateAI[ ACT_IDLE_STIMULATED ]     = ACT_IDLE_SMG1_STIMULATED
        self.ActivityTranslateAI[ ACT_IDLE_AGITATED ]       = ACT_IDLE_ANGRY_SMG1

        self.ActivityTranslateAI[ ACT_WALK_RELAXED ]        = ACT_WALK_RIFLE_RELAXED
        self.ActivityTranslateAI[ ACT_WALK_STIMULATED ]     = ACT_WALK_RIFLE_STIMULATED
        self.ActivityTranslateAI[ ACT_WALK_AGITATED ]       = ACT_WALK_AIM_RIFLE

        self.ActivityTranslateAI[ ACT_RUN_RELAXED ]         = ACT_RUN_RIFLE_RELAXED
        self.ActivityTranslateAI[ ACT_RUN_STIMULATED ]      = ACT_RUN_RIFLE_STIMULATED
        self.ActivityTranslateAI[ ACT_RUN_AGITATED ]        = ACT_RUN_AIM_RIFLE

        self.ActivityTranslateAI[ ACT_IDLE_AIM_RELAXED ]        = ACT_IDLE_SMG1_RELAXED
        self.ActivityTranslateAI[ ACT_IDLE_AIM_STIMULATED ]     = ACT_IDLE_AIM_RIFLE_STIMULATED
        self.ActivityTranslateAI[ ACT_IDLE_AIM_AGITATED ]       = ACT_IDLE_ANGRY_SMG1

        self.ActivityTranslateAI[ ACT_WALK_AIM_RELAXED ]        = ACT_WALK_RIFLE_RELAXED
        self.ActivityTranslateAI[ ACT_WALK_AIM_STIMULATED ]     = ACT_WALK_AIM_RIFLE_STIMULATED
        self.ActivityTranslateAI[ ACT_WALK_AIM_AGITATED ]       = ACT_WALK_AIM_RIFLE

        self.ActivityTranslateAI[ ACT_RUN_AIM_RELAXED ]         = ACT_RUN_RIFLE_RELAXED
        self.ActivityTranslateAI[ ACT_RUN_AIM_STIMULATED ]      = ACT_RUN_AIM_RIFLE_STIMULATED
        self.ActivityTranslateAI[ ACT_RUN_AIM_AGITATED ]        = ACT_RUN_AIM_RIFLE

        self.ActivityTranslateAI[ ACT_WALK_AIM ]                = ACT_WALK_AIM_RIFLE
        self.ActivityTranslateAI[ ACT_WALK_CROUCH ]             = ACT_WALK_CROUCH_RIFLE
        self.ActivityTranslateAI[ ACT_WALK_CROUCH_AIM ]         = ACT_WALK_CROUCH_AIM_RIFLE
        self.ActivityTranslateAI[ ACT_RUN ]                     = ACT_RUN_RIFLE
        self.ActivityTranslateAI[ ACT_RUN_AIM ]                 = ACT_RUN_AIM_RIFLE
        self.ActivityTranslateAI[ ACT_RUN_CROUCH ]              = ACT_RUN_CROUCH_RIFLE
        self.ActivityTranslateAI[ ACT_RUN_CROUCH_AIM ]          = ACT_RUN_CROUCH_AIM_RIFLE
        self.ActivityTranslateAI[ ACT_GESTURE_RANGE_ATTACK1 ]   = ACT_GESTURE_RANGE_ATTACK_AR2
        self.ActivityTranslateAI[ ACT_COVER_LOW ]               = ACT_COVER_SMG1_LOW
        self.ActivityTranslateAI[ ACT_RANGE_AIM_LOW ]           = ACT_RANGE_AIM_AR2_LOW
        self.ActivityTranslateAI[ ACT_RANGE_ATTACK1_LOW ]       = ACT_RANGE_ATTACK_SMG1_LOW
        self.ActivityTranslateAI[ ACT_RELOAD_LOW ]              = ACT_RELOAD_SMG1_LOW
        self.ActivityTranslateAI[ ACT_GESTURE_RELOAD ]          = ACT_GESTURE_RELOAD_SMG1

    elseif t == "smg" then

        self.ActivityTranslateAI[ ACT_RANGE_ATTACK1 ]       = ACT_RANGE_ATTACK_SMG1
        self.ActivityTranslateAI[ ACT_RELOAD ]              = ACT_RELOAD_SMG1
        self.ActivityTranslateAI[ ACT_IDLE ]                = ACT_IDLE_SMG1
        self.ActivityTranslateAI[ ACT_IDLE_ANGRY ]          = ACT_IDLE_ANGRY_SMG1
        self.ActivityTranslateAI[ ACT_WALK ]                = ACT_WALK_RIFLE

        self.ActivityTranslateAI[ ACT_IDLE_RELAXED ]        = ACT_IDLE_SMG1_RELAXED
        self.ActivityTranslateAI[ ACT_IDLE_STIMULATED ]     = ACT_IDLE_SMG1_STIMULATED
        self.ActivityTranslateAI[ ACT_IDLE_AGITATED ]       = ACT_IDLE_ANGRY_SMG1

        self.ActivityTranslateAI[ ACT_WALK_RELAXED ]        = ACT_WALK_RIFLE_RELAXED
        self.ActivityTranslateAI[ ACT_WALK_STIMULATED ]     = ACT_WALK_RIFLE_STIMULATED
        self.ActivityTranslateAI[ ACT_WALK_AGITATED ]       = ACT_WALK_AIM_RIFLE

        self.ActivityTranslateAI[ ACT_RUN_RELAXED ]         = ACT_RUN_RIFLE_RELAXED
        self.ActivityTranslateAI[ ACT_RUN_STIMULATED ]      = ACT_RUN_RIFLE_STIMULATED
        self.ActivityTranslateAI[ ACT_RUN_AGITATED ]        = ACT_RUN_AIM_RIFLE

        self.ActivityTranslateAI[ ACT_IDLE_AIM_RELAXED ]        = ACT_IDLE_SMG1_RELAXED
        self.ActivityTranslateAI[ ACT_IDLE_AIM_STIMULATED ]     = ACT_IDLE_AIM_RIFLE_STIMULATED
        self.ActivityTranslateAI[ ACT_IDLE_AIM_AGITATED ]       = ACT_IDLE_ANGRY_SMG1

        self.ActivityTranslateAI[ ACT_WALK_AIM_RELAXED ]        = ACT_WALK_RIFLE_RELAXED
        self.ActivityTranslateAI[ ACT_WALK_AIM_STIMULATED ]     = ACT_WALK_AIM_RIFLE_STIMULATED
        self.ActivityTranslateAI[ ACT_WALK_AIM_AGITATED ]       = ACT_WALK_AIM_RIFLE

        self.ActivityTranslateAI[ ACT_RUN_AIM_RELAXED ]         = ACT_RUN_RIFLE_RELAXED
        self.ActivityTranslateAI[ ACT_RUN_AIM_STIMULATED ]      = ACT_RUN_AIM_RIFLE_STIMULATED
        self.ActivityTranslateAI[ ACT_RUN_AIM_AGITATED ]        = ACT_RUN_AIM_RIFLE

        self.ActivityTranslateAI[ ACT_WALK_AIM ]                = ACT_WALK_AIM_RIFLE
        self.ActivityTranslateAI[ ACT_WALK_CROUCH ]             = ACT_WALK_CROUCH_RIFLE
        self.ActivityTranslateAI[ ACT_WALK_CROUCH_AIM ]         = ACT_WALK_CROUCH_AIM_RIFLE
        self.ActivityTranslateAI[ ACT_RUN ]                     = ACT_RUN_RIFLE
        self.ActivityTranslateAI[ ACT_RUN_AIM ]                 = ACT_RUN_AIM_RIFLE
        self.ActivityTranslateAI[ ACT_RUN_CROUCH ]              = ACT_RUN_CROUCH_RIFLE
        self.ActivityTranslateAI[ ACT_RUN_CROUCH_AIM ]          = ACT_RUN_CROUCH_AIM_RIFLE
        self.ActivityTranslateAI[ ACT_GESTURE_RANGE_ATTACK1 ]   = ACT_GESTURE_RANGE_ATTACK_SMG1
        self.ActivityTranslateAI[ ACT_COVER_LOW ]               = ACT_COVER_SMG1_LOW
        self.ActivityTranslateAI[ ACT_RANGE_AIM_LOW ]           = ACT_RANGE_AIM_SMG1_LOW
        self.ActivityTranslateAI[ ACT_RANGE_ATTACK1_LOW ]       = ACT_RANGE_ATTACK_SMG1_LOW
        self.ActivityTranslateAI[ ACT_RELOAD_LOW ]              = ACT_RELOAD_SMG1_LOW
        self.ActivityTranslateAI[ ACT_GESTURE_RELOAD ]          = ACT_GESTURE_RELOAD_SMG1

    end

end
