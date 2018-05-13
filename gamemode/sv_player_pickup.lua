local DbgPrintPickup = GetLogging("Pickup")
local DbgPrint = DbgPrintPickup

function GM:InitializePlayerPickup(ply)
	ply.ObjectPickupTable = {}
end

function GM:RegisterPlayerItemPickup(ply, item)
	item.UniqueEntityId = item.UniqueEntityId or self:GetNextUniqueEntityId()
	ply.ObjectPickupTable[item.UniqueEntityId] = true
end

function GM:RespawnObject(obj, delay)
	DbgPrintPickup("Respawning object " .. tostring(obj) .. " in " .. tostring(delay) .. " seconds")

	local data = self:GetLevelDesignerPlacedData(obj)
	local class = obj:GetClass()
	local pos = obj:GetPos()
	local ang = obj:GetAngles()
	local uniqueId = obj.UniqueEntityId

	if data ~= nil then
		pos = data.pos
		ang = data.ang
	end

	util.RunDelayed(function()

		local e = ents.Create(class)
		e.UniqueEntityId = uniqueId
		e:SetPos(pos)
		e:SetAngles(ang)
		e:Spawn()
		e:Activate()

		-- Keep it as level designer placed object.
		if data ~= nil then
			self:InsertLevelDesignerPlacedObject(e)
		end

		if delay > 0.0 then
			e:EmitSound("AlyxEmp.Charge")

			local effectdata = EffectData()
			effectdata:SetOrigin( pos )
			effectdata:SetScale(1)
			effectdata:SetMagnitude(5)
			util.Effect( "ElectricSpark", effectdata )
		end
	end, CurTime() + delay)

end

function GM:PlayerCanPickupAmmo(ply, ent)

	-- Limit the ammo to pickup based on the sk convars.
	if lambda_limit_default_ammo:GetBool() == false then
		return true
	end

	local res = true
	local capacity = 0
	local skill = tostring(game.GetSkillLevel())
	local class = ent:GetClass()
	local primaryFull = true
	local secondaryFull = true

	local CheckAmmoFull = function(ammoType, clipSize)

		if ammoType ~= -1 then
			local ammoName = game.GetAmmoName(ammoType)
			local cur = ply:GetAmmoCount(ammoType)
			local ammoMax = self.MAX_AMMO_DEF[ammoName]
			if clipSize == -1 then
				clipSize = 0
			end
			if ammoMax ~= nil then
				ammoMax = ammoMax:GetInt()
			else
				ammoMax = 9999
			end
			if cur >= ammoMax then
				return true
			end
		end

		return false
	end

	if ent:IsWeapon() then
		local clip1 = ent:Clip1()
		local clip2 = ent:Clip2()
		if clip1 > 0 and clip2 > 0 then
			primaryFull = CheckAmmoFull(ent:GetPrimaryAmmoType(), ent:Clip1())
			secondaryFull = CheckAmmoFull(ent:GetSecondaryAmmoType(), ent:Clip2())
			return primaryFull == false and secondaryFull == false
		elseif clip1 > 0 then
			primaryFull = CheckAmmoFull(ent:GetPrimaryAmmoType(), ent:Clip1())
			return primaryFull == false
		end
	end

	local ammo = self.ITEM_DEF[class]
	if ammo ~= nil then
		local cur = ply:GetAmmoCount(ammo.Type)
		local amount = ammo[skill]
		local ammoMax = ammo.Max:GetInt()
		if cur >= ammoMax then
			DbgPrint("Limited ammo pickup: " .. tostring(class) .. ", " .. ammo.Type)
			return false
		end
	end

	return true

end

function GM:PlayerDroppedWeapon(ply, wep)
	--wep.DroppedByPlayer = ply
end

function GM:PlayerCanPickupItem(ply, item)

	DbgPrintPickup("PlayerCanPickupItem", ply, item)

	if item.CreatedForPlayer ~= nil then
		if item.CreatedForPlayer == ply then
			DbgPrintPickup("Simple pickup, created for player: " .. tostring(ply))
			return true
		else
			-- Deny this weapon for whoever wants to touch it.
			return false
		end
	end

	item.UniqueEntityId = item.UniqueEntityId or self:GetNextUniqueEntityId()

	if self:CallGameTypeFunc("PlayerCanPickupItem", ply, item) == false then
		DbgPrintPickup("GameType prevented pickup")
		return false
	end

	local class = item:GetClass()
	local res = true

	-- Dont pickup stuff if we dont need it.
	if class == "item_health" or class == "item_healthvial" or class == "item_healthkit" then
		if ply:Health() >= ply:GetMaxHealth() then
			return false
		end
	elseif class == "item_battery" then
		if ply:Armor() >= 100 then
			return false
		end
	elseif class == "item_suit" then
		if ply:IsSuitEquipped() == true then
			return false
		else
			return true
		end
	end

	if self:PlayerCanPickupAmmo(ply, item) == false then
		return false
	end

	if self:CallGameTypeFunc("ShouldRespawnItem", item) == true then
		local respawnTime = self:CallGameTypeFunc("GetItemRespawnTime") or 1
		self:RespawnObject(item, respawnTime)
	else
		DbgPrint("Not respawning item: " .. class)
		return true
	end

	return true

end

function GM:PlayerCanPickupWeapon(ply, wep)

	if wep.DroppedByPlayer ~= nil then
		DbgPrintPickup(ply, "Simple pickup, dropped by other player")
		return true
	end

	if wep.CreatedForPlayer ~= nil then
		if wep.CreatedForPlayer == ply then
			DbgPrintPickup(ply, "Simple pickup, created for player")
			return true
		else
			-- Deny this weapon for whoever wants to touch it.
			return false
		end
	end

	if wep:GetClass() == "weapon_frag" then
		return self:PlayerCanPickupItem(ply, wep)
	end

	--DbgPrintPickup("PlayerCanPickupWeapon", ply, wep)

	wep.UniqueEntityId = wep.UniqueEntityId or self:GetNextUniqueEntityId()

	if self:CallGameTypeFunc("PlayerCanPickupWeapon", ply, wep) == false then
		--DbgPrint("GameType prevented pickup")
		return false
	end

	if ply:HasWeapon(wep:GetClass()) == true then
		if self:PlayerCanPickupAmmo(ply, wep) == false then
			return false
		end
		local clip1 = wep:Clip1()
		if clip1 > 0 then
			ply:GiveAmmo(clip1, wep:GetPrimaryAmmoType(), false)
		end
		local clip2 = wep:Clip2()
		if clip2 > 0 then
			ply:GiveAmmo(clip2, wep:GetSecondaryAmmoType(), false)
		end
		self:RegisterPlayerItemPickup(ply, wep)
		return false
	end

	return true

end

function GM:WeaponEquip(wep, owner)

	DbgPrintPickup("WeaponEquip", wep, owner, wep.CreatedForPlayer)

	local ply = owner
	if not IsValid(ply) then
		return
	end

	wep.UniqueEntityId = wep.UniqueEntityId or self:GetNextUniqueEntityId()
	self:RegisterPlayerItemPickup(ply, wep)

	if owner.IsCurrentlySpawning == false then
		local class = wep:GetClass()
		util.RunNextFrame(function()
			if not IsValid(ply) then return end
			ply:SelectWeapon(class)
		end)
		ply:EmitSound("Player.PickupWeapon")
	end

	if wep.CreatedForPlayer ~= owner and wep.DroppedByPlayer == nil then

		if wep:GetClass() ~= "weapon_frag" and self:CallGameTypeFunc("ShouldRespawnWeapon", wep) == true then
			local respawnTime = self:CallGameTypeFunc("GetWeaponRespawnTime") or 0.5
			self:RespawnObject(wep, respawnTime)
		end

	end

	wep.CreatedForPlayer = nil

end