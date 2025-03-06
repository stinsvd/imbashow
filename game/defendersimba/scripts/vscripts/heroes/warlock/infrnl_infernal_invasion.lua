-----------------------
-- Infernal Invasion --
-----------------------
LinkLuaModifier("modifier_infrnl_infernal_invasion", "heroes/warlock/infrnl_infernal_invasion", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_infrnl_infernal_invasion_caster", "heroes/warlock/infrnl_infernal_invasion", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_infrnl_infernal_invasion_target", "heroes/warlock/infrnl_infernal_invasion", LUA_MODIFIER_MOTION_NONE)

infrnl_infernal_invasion = infrnl_infernal_invasion or class({})
function infrnl_infernal_invasion:Precache(context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_dragon_knight.vsndevts", context)
	PrecacheResource("particle", "particles/custom/heroes/infernal/infernal_invasion_cast.vpcf", context)
	PrecacheResource("particle", "particles/items3_fx/nemesis_curse_debuff.vpcf", context)
end
function infrnl_infernal_invasion:GetBehavior()
	if not self:GetCaster():HasModifier("modifier_infrnl_infernal_invasion_caster") then
		return DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_IGNORE_BACKSWING
	end
	return self.BaseClass.GetBehavior(self)
end
function infrnl_infernal_invasion:GetCastAnimation() return ACT_DOTA_FLAIL end
function infrnl_infernal_invasion:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	if caster:HasModifier("modifier_infrnl_infernal_invasion_caster") then
		caster:RemoveModifierByName("modifier_infrnl_infernal_invasion_caster")
		return
	end
	local casterPos = caster:GetAbsOrigin()
	local duration = self:GetSpecialValueFor("duration")
	local units_count = self:GetSpecialValueFor("golems_count")
	if units_count <= 0 then return end
	local maxHealth = caster:GetMaxHealth() * (self:GetSpecialValueFor("maxhp") / 100)
	local armor = caster:GetPhysicalArmorValue(false) * (self:GetSpecialValueFor("armor") / 100)
	local magicResist = (caster:Script_GetMagicalArmorValue(false, self) * 100) * (self:GetSpecialValueFor("magic_resist") / 100)

	local player_id
	if caster.GetPlayerID then
		player_id = caster:GetPlayerID()
	elseif caster:GetOwner() and caster:GetOwner().GetPlayerID then
		player_id = caster:GetOwner():GetPlayerID()
	else
		return
	end

	local upgrade = caster:FindModifierByName("modifier_infrnl_burning_spirit")
	if upgrade then
		local shards_per_cast = 1	--self:GetSpecialValueFor("shards_per_cast")
		for i = 1, shards_per_cast do
			upgrade:IncrementStackCount()
		end
	end

	local bonusStacks = 0
	local infrnlStats = CustomNetTables:GetTableValue("heroes_stats", "Infernal")
	if infrnlStats then
		bonusStacks = infrnlStats.infrnl_infernal_invasion_burn_damage or 0
	end

	caster:EmitSound("Hero_DragonKnight.DragonTail.Cast.Kindred")

	self.infernals = {}
	local angle = 360 / units_count
	local distance = 100
	for i = 1, units_count do
		local radians = math.rad(angle * i)
		local position = casterPos + Vector(math.cos(radians), math.sin(radians), 0) * distance
		local unit = CreateUnitByName("npc_dota_mini_infernal_cus", position, true, caster, caster, caster:GetTeamNumber())
		unit:SetBaseMaxHealth(math.max(maxHealth, 1))
		unit:SetMaxHealth(math.max(maxHealth, 1))
		unit:SetHealth(math.max(maxHealth, 1))
		unit:SetPhysicalArmorBaseValue(armor)
		unit:SetControllableByPlayer(player_id, true)
		unit:SetForwardVector((position - casterPos):Normalized())
		unit:AddNewModifier(caster, self, "modifier_infrnl_infernal_invasion", {}):SetStackCount(magicResist)
		unit:AddNewModifier(caster, self, "modifier_kill", {duration = duration})

		local switch = unit:AddAbility("infrnl_infernal_invasion_switch")
		if switch then
			if unit:GetAbilityByIndex(0) and unit:GetAbilityByIndex(0) ~= switch then
				unit:SwapAbilities(unit:GetAbilityByIndex(0):GetAbilityName(), switch:GetAbilityName(), false, true)
			end
			switch:SetLevel(1)
		end
		local miniFireball = unit:AddAbility("infrnl_mini_fire_ball")
		if miniFireball then
			if unit:GetAbilityByIndex(1) and unit:GetAbilityByIndex(1) ~= miniFireball then
				unit:SwapAbilities(unit:GetAbilityByIndex(1):GetAbilityName(), miniFireball:GetAbilityName(), false, true)
			end
			miniFireball.bonusStacks = bonusStacks
			miniFireball:SetLevel(self:GetLevel())
		end
		local miniFist = unit:AddAbility("infrnl_mini_flaming_fists")
		if miniFist then
			miniFist.bonusStacks = bonusStacks
			miniFist:SetLevel(self:GetLevel())
		end
		local miniImmolation = unit:AddAbility("infrnl_mini_immolation")
		if miniImmolation then
			miniImmolation.bonusStacks = bonusStacks
			miniImmolation:SetLevel(self:GetLevel())
		end

		table.insert(self.infernals, unit)
	end

	caster:Stop()
	caster:AddNewModifier(caster, self, "modifier_infrnl_infernal_invasion_caster", {duration = duration})
	local cast_pfx = ParticleManager:CreateParticle("particles/custom/heroes/infernal/infernal_invasion_cast.vpcf", PATTACH_WORLDORIGIN, caster)
	ParticleManager:SetParticleControl(cast_pfx, 0, casterPos)
	ParticleManager:SetParticleControl(cast_pfx, 1, Vector(1, 0, 0))
	ParticleManager:ReleaseParticleIndex(cast_pfx)
end


modifier_infrnl_infernal_invasion = modifier_infrnl_infernal_invasion or class({})
function modifier_infrnl_infernal_invasion:IsHidden() return true end
function modifier_infrnl_infernal_invasion:IsPurgable() return false end
function modifier_infrnl_infernal_invasion:OnCreated()
	if not IsServer() then return end
	self:GetParent():SetModelScale(0.75)
end
function modifier_infrnl_infernal_invasion:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_DIRECT_MODIFICATION,
	}
end
function modifier_infrnl_infernal_invasion:GetModifierMagicalResistanceDirectModification() return self:GetStackCount() end


modifier_infrnl_infernal_invasion_caster = modifier_infrnl_infernal_invasion_caster or class({})
function modifier_infrnl_infernal_invasion_caster:IsHidden() return true end
function modifier_infrnl_infernal_invasion_caster:IsPurgable() return false end
function modifier_infrnl_infernal_invasion_caster:OnCreated()
	if not IsServer() then return end
	local owner = self:GetParent()
	local immolation = owner:FindAbilityByName("infrnl_immolation")
	if immolation and immolation:GetToggleState() then
		immolation:ToggleAbility()
	end
	owner:AddNoDraw()
	self.infernals = self:GetAbility().infernals
	if self.infernals then
		self.target = self.infernals[RandomInt(1, #self.infernals)]
		self.target:AddNewModifier(owner, self:GetAbility(), "modifier_infrnl_infernal_invasion_target", {})
	end
	self:StartIntervalThink(0.1)
end
function modifier_infrnl_infernal_invasion_caster:OnDestroy()
	if not IsServer() then return end
	local owner = self:GetParent()
	if self.infernals then
		for _, unit in pairs(self.infernals) do
			unit:ForceKill(false)
			Timers:CreateTimer(5, function()
				if unit and not unit:IsNull() then
					UTIL_Remove(unit)
				end
			end)
		end
		self.infernals = {}
	end
	if self:GetRemainingTime() > 0 then
		local fail_hp = self:GetAbility():GetSpecialValueFor("fail_hp")
		self:GetParent():ModifyHealth(self:GetParent():GetHealth() * ((100 - fail_hp) / 100), nil, false, 0)
	end
	owner:Stop()
	owner:RemoveNoDraw()
end
function modifier_infrnl_infernal_invasion_caster:OnIntervalThink()
	if not IsServer() then return end
	if self.target and not self.target:IsNull() and self.target:IsAlive() then
		self:GetParent():SetAbsOrigin(self.target:GetAbsOrigin())
		self:GetParent():SetForwardVector(self.target:GetForwardVector())
	else
		for i = #self.infernals, 1, -1 do
			if not self.target or self.infernals[i]:IsNull() or not self.infernals[i]:IsAlive() then
				table.remove(self.infernals, i)
			end
		end
		if #self.infernals > 0 then
			self.target = self.infernals[RandomInt(1, #self.infernals)]
			self.target:AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_infrnl_infernal_invasion_target", {})
		else
			self:Destroy()
		end
	end
end
function modifier_infrnl_infernal_invasion_caster:CheckState()
	return {
		[MODIFIER_STATE_INVULNERABLE] = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
		[MODIFIER_STATE_SILENCED] = true,
		[MODIFIER_STATE_MUTED] = true,
		[MODIFIER_STATE_UNSELECTABLE] = true,
		[MODIFIER_STATE_UNTARGETABLE] = true,
		[MODIFIER_STATE_IGNORING_MOVE_AND_ATTACK_ORDERS] = true,
	}
end


modifier_infrnl_infernal_invasion_target = modifier_infrnl_infernal_invasion_target or class({})
function modifier_infrnl_infernal_invasion_target:IsHidden() return true end
function modifier_infrnl_infernal_invasion_target:IsPurgable() return false end
function modifier_infrnl_infernal_invasion_target:OnCreated()
	local owner = self:GetParent()
	if IsClient() then
		local target_pfx = ParticleManager:CreateParticle("particles/items3_fx/nemesis_curse_debuff.vpcf", PATTACH_ABSORIGIN_FOLLOW, owner)
		ParticleManager:SetParticleControlEnt(target_pfx, 0, owner, PATTACH_OVERHEAD_FOLLOW, "attach_hitloc", owner:GetAbsOrigin(), true)
		self:AddParticle(target_pfx, false, false, -1, false, true)
	end
end




infrnl_infernal_invasion_switch = infrnl_infernal_invasion_switch or class({})
function infrnl_infernal_invasion_switch:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local owner = caster:GetOwner()
	if owner then
		local inv_mod = owner:FindModifierByName("modifier_infrnl_infernal_invasion_caster")
		if inv_mod then
			inv_mod.target:RemoveModifierByName("modifier_infrnl_infernal_invasion_target")
			inv_mod.target = caster
			caster:AddNewModifier(owner, inv_mod:GetAbility(), "modifier_infrnl_infernal_invasion_target", {})
		end
	end
end




---------------
-- Fire Ball --
---------------
LinkLuaModifier("modifier_infrnl_mini_fire_ball_stacks", "heroes/warlock/infrnl_infernal_invasion", LUA_MODIFIER_MOTION_NONE)

infrnl_mini_fire_ball = infrnl_mini_fire_ball or class({})
function infrnl_mini_fire_ball:Precache(context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_dragon_knight.vsndevts", context)
	PrecacheResource("particle", "particles/units/heroes/hero_batrider/batrider_base_attack.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_phoenix/phoenix_fire_spirit_burn_creep.vpcf", context)
end
function infrnl_mini_fire_ball:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local speed = self:GetSpecialValueFor("speed")
	local damage = self:GetSpecialValueFor("damage") / 100
	local bonus_damage = self:GetSpecialValueFor("bonus_damage")
	local bonus_damage_pct = self:GetSpecialValueFor("bonus_damage_pct") / 100
	local stun_duration = self:GetSpecialValueFor("stun_duration")
	local duration = self:GetSpecialValueFor("duration")

	caster:EmitSound("Hero_DragonKnight.Fireball.Cast")
	local info = {
		Target = self:GetCursorTarget(),
		Ability = self,
		Source = caster,
		EffectName = "particles/units/heroes/hero_batrider/batrider_base_attack.vpcf",
		iMoveSpeed = speed,
		bProvidesVision = true,
		iVisionRadius = 400,
		iVisionTeamNumber = caster:GetTeamNumber(),
		ExtraData = {
			casterHP = caster:GetMaxHealth(),
			damage = damage,
			bonus_damage = bonus_damage,
			bonus_damage_pct = bonus_damage_pct,
			duration = duration,
			stun_duration = stun_duration,
		}
	}
	ProjectileManager:CreateTrackingProjectile(info)
end
function infrnl_mini_fire_ball:OnProjectileHit_ExtraData(target, loc, ExtraData)
	if not IsServer() then return end
	if not target then return end
	if target:TriggerSpellAbsorb(self) then return end
	local caster = self:GetCaster():GetOwner()
	if not caster then return end
	local casterHP = ExtraData.casterHP
	local base_damage = ExtraData.damage
	local currentStacks = target:GetModifierStackCount("modifier_infrnl_mini_fire_ball_stacks", caster)
	local bonus_damage = ExtraData.bonus_damage * currentStacks
	local bonus_damage_pct = ExtraData.bonus_damage_pct * currentStacks
	local damage = (casterHP * (base_damage + bonus_damage_pct)) + bonus_damage
	local stun_duration = ExtraData.stun_duration
	local duration = ExtraData.duration

	SendOverheadEventMessage(nil, 4, target, damage , nil)

	target:EmitSound("Hero_DragonKnight.Fireball.Target")
	target:AddNewModifier(caster, self, "modifier_stunned", {duration = stun_duration * (1 - target:GetStatusResistance())})
	local stacks = target:AddNewModifier(caster, self, "modifier_infrnl_mini_fire_ball_stacks", {duration = duration * (1 - target:GetStatusResistance())})
	if stacks then
		stacks:IncrementStackCount()
	end

	ApplyDamage({
		victim = target,
		attacker = caster,
		ability = self,
		damage = damage,
		damage_type = DAMAGE_TYPE_MAGICAL,
	})
end


modifier_infrnl_mini_fire_ball_stacks = modifier_infrnl_mini_fire_ball_stacks or class({})
function modifier_infrnl_mini_fire_ball_stacks:IsHidden() return false end
function modifier_infrnl_mini_fire_ball_stacks:IsPurgable() return false end
function modifier_infrnl_mini_fire_ball_stacks:GetEffectName() return "particles/units/heroes/hero_phoenix/phoenix_fire_spirit_burn_creep.vpcf" end
function modifier_infrnl_mini_fire_ball_stacks:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end




------------------------
-- Mini-Flaming Fists --
------------------------
LinkLuaModifier("modifier_infrnl_mini_flaming_fists", "heroes/warlock/infrnl_infernal_invasion", LUA_MODIFIER_MOTION_NONE)

infrnl_mini_flaming_fists = infrnl_mini_flaming_fists or class({})
function infrnl_mini_flaming_fists:Precache(context)
	PrecacheResource("particle", "particles/units/heroes/hero_doom_bringer/doom_bringer_lvl_death.vpcf", context)
end
function infrnl_mini_flaming_fists:GetIntrinsicModifierName() return "modifier_infrnl_mini_flaming_fists" end


modifier_infrnl_mini_flaming_fists = modifier_infrnl_mini_flaming_fists or class({})
function modifier_infrnl_mini_flaming_fists:IsHidden() return true end
function modifier_infrnl_mini_flaming_fists:IsPurgable() return false end
function modifier_infrnl_mini_flaming_fists:OnCreated() self:OnRefresh() end
function modifier_infrnl_mini_flaming_fists:OnRefresh()
	if not IsServer() then return end
	self.bonusStacks = self:GetAbility().bonusStacks
	self.damageTable = {
		victim = nil,
		attacker = self:GetCaster(),
		ability = self:GetAbility(),
		damage = nil,
		damage_type = DAMAGE_TYPE_MAGICAL,
	}
end
function modifier_infrnl_mini_flaming_fists:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end
function modifier_infrnl_mini_flaming_fists:OnAttackLanded(keys)
	if not IsServer() then return end
	local ability = self:GetAbility()
	if not ability then return end
	local target = keys.target
	if not target then return end
	local attacker = keys.attacker
	if not attacker then return end
	if target:IsBuilding() or target:IsOther() then return end
	if attacker:PassivesDisabled() then return end
	if self:GetParent() ~= attacker then return end
	local chance = ability:GetSpecialValueFor("chance")
	if RollPercentage(chance) then
		local base_damage = ability:GetSpecialValueFor("up_base_damage") * self.bonusStacks
		local hpleft_damage = ability:GetSpecialValueFor("hpleft_damage") / 100
		local damage = (attacker:GetMaxHealth() - attacker:GetHealth()) * hpleft_damage

		local hit_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_doom_bringer/doom_bringer_lvl_death.vpcf", PATTACH_ABSORIGIN_FOLLOW, attacker)
		ParticleManager:SetParticleControlEnt(hit_pfx, 0, target, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), false)
		ParticleManager:ReleaseParticleIndex(hit_pfx)

		self.damageTable.damage = damage + base_damage
		self.damageTable.victim = target
		ApplyDamage(self.damageTable)
	end
end




---------------------
-- Mini-Immolation --
---------------------
LinkLuaModifier("modifier_infrnl_mini_immolation", "heroes/warlock/infrnl_infernal_invasion", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_infrnl_mini_immolation_burn_aura", "heroes/warlock/infrnl_infernal_invasion", LUA_MODIFIER_MOTION_NONE)

infrnl_mini_immolation = infrnl_mini_immolation or class({})
function infrnl_mini_immolation:GetAOERadius() return self:GetSpecialValueFor("radius") end
function infrnl_mini_immolation:GetIntrinsicModifierName() return "modifier_infrnl_mini_immolation" end

modifier_infrnl_mini_immolation = modifier_infrnl_mini_immolation or class({})
function modifier_infrnl_mini_immolation:IsHidden() return true end
function modifier_infrnl_mini_immolation:IsPurgable() return false end
function modifier_infrnl_mini_immolation:IsPermanent() return true end
function modifier_infrnl_mini_immolation:OnCreated()
	self.radius = self:GetAbility():GetSpecialValueFor("radius")
	if not IsServer() then return end
	local caster = self:GetCaster()
	local amb_pfx = ParticleManager:CreateParticle("particles/items2_fx/radiance_owner.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(amb_pfx, 0, caster, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
	self:AddParticle(amb_pfx, false, false, -1, false, false)
end
function modifier_infrnl_mini_immolation:IsAura()
	if self:GetParent():PassivesDisabled() then return false end
	return true
end
function modifier_infrnl_mini_immolation:IsAuraActiveOnDeath() return false end
function modifier_infrnl_mini_immolation:GetAuraRadius() return self.radius end
function modifier_infrnl_mini_immolation:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_ENEMY end
function modifier_infrnl_mini_immolation:GetAuraSearchType() return DOTA_UNIT_TARGET_HEROES_AND_CREEPS end
function modifier_infrnl_mini_immolation:GetAuraSearchFlags() return DOTA_UNIT_TARGET_FLAG_NONE end
function modifier_infrnl_mini_immolation:GetAuraDuration() return 0.2 end
function modifier_infrnl_mini_immolation:GetModifierAura() return "modifier_infrnl_mini_immolation_burn_aura" end

-- Mini-Immolation Burn Aura --
modifier_infrnl_mini_immolation_burn_aura = modifier_infrnl_mini_immolation_burn_aura or class({})
function modifier_infrnl_mini_immolation_burn_aura:IsHidden() return false end
function modifier_infrnl_mini_immolation_burn_aura:IsDebuff() return true end
function modifier_infrnl_mini_immolation_burn_aura:IsPurgable() return false end
function modifier_infrnl_mini_immolation_burn_aura:OnCreated()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local owner = self:GetParent()
	self.bonusStacks = self:GetAbility().bonusStacks
	self.interval = self:GetAbility():GetSpecialValueFor("interval")
	local baseDamage = self:GetAbility():GetSpecialValueFor("up_base_damage_per_second") * self.bonusStacks
	local maxhpDamage = self:GetAbility():GetSpecialValueFor("maxhp_damage_per_second")
	self.dps_aura = (baseDamage + (caster:GetMaxHealth() * (maxhpDamage / 100)))
	
	self.burn_pfx = ParticleManager:CreateParticle("particles/items2_fx/radiance.vpcf", PATTACH_POINT_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(self.burn_pfx, 0, owner, PATTACH_POINT_FOLLOW, "attach_hitloc", owner:GetAbsOrigin(), true)
	ParticleManager:SetParticleControl(self.burn_pfx, 1, caster:GetAbsOrigin())
	self:AddParticle(self.burn_pfx, false, false, -1, false, false)
	
	self.damageTable = {
		victim = owner,
		attacker = caster,
		ability = self:GetAbility(),
		damage = self.dps_aura * self.interval,
		damage_type = DAMAGE_TYPE_MAGICAL
	}
	self:StartIntervalThink(self.interval)
end
function modifier_infrnl_mini_immolation_burn_aura:OnIntervalThink()
	if not IsServer() then return end
	if self.burn_pfx then
		ParticleManager:SetParticleControl(self.burn_pfx, 1, self:GetCaster():GetAbsOrigin())
	end
	ApplyDamage(self.damageTable)
end
