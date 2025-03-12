------------------
-- Stout Shield --
------------------
LinkLuaModifier("modifier_stout_shield_cus", "items/shields", LUA_MODIFIER_MOTION_NONE)


item_stout_shield_cus = item_stout_shield_cus or class({})
function item_stout_shield_cus:GetIntrinsicModifierName() return "modifier_stout_shield_cus" end


modifier_stout_shield_cus = modifier_stout_shield_cus or class({})
function modifier_stout_shield_cus:IsHidden() return true end
function modifier_stout_shield_cus:IsPurgable() return false end
function modifier_stout_shield_cus:IsPermanent() return true end
function modifier_stout_shield_cus:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PHYSICAL_CONSTANT_BLOCK,
	}
end
function modifier_stout_shield_cus:GetModifierPhysical_ConstantBlock(keys)
	if not IsServer() then return end
	local ability = self:GetAbility()
	if not ability then return end
	local attacker = keys.attacker
	if not attacker then return end
	local block_chance = ability:GetSpecialValueFor("block_chance")
	if attacker:IsHero() or RollPseudoRandomPercentage(math.min(block_chance, 100), ability:entindex(), self:GetParent()) then
		if self:GetParent():IsRangedAttacker() then
			return ability:GetSpecialValueFor("damage_block_ranged")
		else
			return ability:GetSpecialValueFor("damage_block_melee")
		end
	end
end



----------------------
-- Quelling Blade 2 --
----------------------
LinkLuaModifier("modifier_quelling_blade_2", "items/shields", LUA_MODIFIER_MOTION_NONE)


item_quelling_blade_2 = item_quelling_blade_2 or class({})
function item_quelling_blade_2:GetIntrinsicModifierName() return "modifier_quelling_blade_2" end
function item_quelling_blade_2:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local targetPos = target:GetAbsOrigin()
	GridNav:DestroyTreesAroundPoint(targetPos, 1, true)
	EmitSoundOnLocationWithCaster(targetPos, "DOTA_Item.Tango.Activate", caster)
end


modifier_quelling_blade_2 = modifier_quelling_blade_2 or class({})
function modifier_quelling_blade_2:IsHidden() return true end
function modifier_quelling_blade_2:IsPurgable() return false end
function modifier_quelling_blade_2:IsPermanent() return true end
function modifier_quelling_blade_2:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end
function modifier_quelling_blade_2:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_PHYSICAL,
		MODIFIER_PROPERTY_PHYSICAL_CONSTANT_BLOCK,
	}
end
function modifier_quelling_blade_2:GetModifierBonusStats_Strength()
	if self:GetAbility() then return self:GetAbility():GetSpecialValueFor("bonus_all_stats") end
end
function modifier_quelling_blade_2:GetModifierBonusStats_Agility()
	if self:GetAbility() then return self:GetAbility():GetSpecialValueFor("bonus_all_stats") end
end
function modifier_quelling_blade_2:GetModifierBonusStats_Intellect()
	if self:GetAbility() then return self:GetAbility():GetSpecialValueFor("bonus_all_stats") end
end
function modifier_quelling_blade_2:GetModifierProcAttack_BonusDamage_Physical(keys)
	if not IsServer() then return end
	local ability = self:GetAbility()
	if not ability then return end
	local attacker = keys.attacker
	if not attacker then return end
	if attacker ~= self:GetParent() then return end
	local target = keys.target
	if not target then return end
	if not target:IsHero() then
		if attacker:IsRangedAttacker() then
			return ability:GetSpecialValueFor("damage_bonus_ranged")
		else
			return ability:GetSpecialValueFor("damage_bonus")
		end
	end
end
function modifier_quelling_blade_2:GetModifierPhysical_ConstantBlock(keys)
	if not IsServer() then return end
	local ability = self:GetAbility()
	if not ability then return end
	local attacker = keys.attacker
	if not attacker then return end
	local block_chance = ability:GetSpecialValueFor("block_chance")
	if attacker:IsHero() or RollPseudoRandomPercentage(math.min(block_chance, 100), ability:entindex(), self:GetParent()) then
		if self:GetParent():IsRangedAttacker() then
			return ability:GetSpecialValueFor("damage_block_ranged")
		else
			return ability:GetSpecialValueFor("damage_block_melee")
		end
	end
end



--------------
-- Uniguard --
--------------
LinkLuaModifier("modifier_uniguard", "items/shields", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_uniguard_cooldown", "items/shields", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_uniguard_active", "items/shields", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_uniguard_active_cooldown", "items/shields", LUA_MODIFIER_MOTION_NONE)


item_uniguard = item_uniguard or class({})
function item_uniguard:GetIntrinsicModifierName() return "modifier_uniguard" end
function item_uniguard:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local caster_loc = caster:GetAbsOrigin()
	local duration = self:GetSpecialValueFor("active_duration")
	local active_radius = self:GetSpecialValueFor("active_radius")
	local cooldown = self:GetEffectiveCooldown(-1) - 1

	caster:EmitSound("Item.CrimsonGuard.Cast")

	local nearby_allies = FindUnitsInRadius(caster:GetTeamNumber(), caster_loc, nil, active_radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BUILDING, DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS + DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD, FIND_ANY_ORDER, false)
	for _, ally in pairs(nearby_allies) do
		if not ally:HasModifier("modifier_uniguard_active_cooldown") then
			ally:AddNewModifier(caster, self, "modifier_uniguard_active", {duration = duration})
			if cooldown > 0 then
				ally:AddNewModifier(caster, self, "modifier_uniguard_active_cooldown", {duration = cooldown})
			end
		end
	end
end

item_uniguard_2 = item_uniguard
item_uniguard_3 = item_uniguard
item_uniguard_4 = item_uniguard


modifier_uniguard = modifier_uniguard or class({})
function modifier_uniguard:IsHidden() return true end
function modifier_uniguard:IsPurgable() return false end
function modifier_uniguard:IsPermanent() return true end
function modifier_uniguard:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end
function modifier_uniguard:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
		MODIFIER_PROPERTY_PHYSICAL_CONSTANT_BLOCK,
		MODIFIER_PROPERTY_MAGICAL_CONSTANT_BLOCK,
	}
end
function modifier_uniguard:GetModifierBonusStats_Strength()
	if self:GetAbility() then return self:GetAbility():GetSpecialValueFor("bonus_strength") end
end
function modifier_uniguard:GetModifierBonusStats_Agility()
	if self:GetAbility() then return self:GetAbility():GetSpecialValueFor("bonus_agility") end
end
function modifier_uniguard:GetModifierBonusStats_Intellect()
	if self:GetAbility() then return self:GetAbility():GetSpecialValueFor("bonus_intellect") end
end
function modifier_uniguard:GetModifierConstantHealthRegen()
	if self:GetAbility() then return self:GetAbility():GetSpecialValueFor("bonus_health_regen") end
end
function modifier_uniguard:GetModifierConstantManaRegen()
	if self:GetAbility() then return self:GetAbility():GetSpecialValueFor("bonus_mana_regen") end
end
function modifier_uniguard:GetModifierPhysicalArmorBonus()
	if self:GetAbility() then return self:GetAbility():GetSpecialValueFor("bonus_armor") end
end
function modifier_uniguard:GetModifierMagicalResistanceBonus()
	if self:GetAbility() then return self:GetAbility():GetSpecialValueFor("bonus_magic_armor") end
end
function modifier_uniguard:GetModifierPhysical_ConstantBlock(keys)
	if not IsServer() then return end
	local ability = self:GetAbility()
	if not ability then return end
	local block_chance = ability:GetSpecialValueFor("block_chance")
	if RollPseudoRandomPercentage(math.min(block_chance, 100), ability:entindex(), self:GetParent()) then
		if self:GetParent():IsRangedAttacker() then
			return ability:GetSpecialValueFor("block_damage_ranged")
		else
			return ability:GetSpecialValueFor("block_damage_melee")
		end
	end
end
function modifier_uniguard:GetModifierMagical_ConstantBlock(keys)
	if not IsServer() then return end
	local ability = self:GetAbility()
	if not ability then return end
	local damage = keys.damage
	if damage <= 0 then return end
	local owner = self:GetParent()
	if owner:HasModifier("modifier_uniguard_cooldown") then return end
	local min_damage = ability:GetSpecialValueFor("min_damage")
	if damage < min_damage then return end
	local magic_block_cooldown = ability:GetSpecialValueFor("magic_block_cooldown")
	owner:AddNewModifier(owner, ability, "modifier_uniguard_cooldown", {duration = magic_block_cooldown})
	local magic_damage_block = ability:GetSpecialValueFor("magic_damage_block")
	local block = math.min(magic_damage_block, damage)
	owner:EmitSound("DOTA_Item.InfusedRaindrop")
	SendOverheadEventMessage(nil, OVERHEAD_ALERT_MAGICAL_BLOCK, owner, block, nil)
	return block
end


modifier_uniguard_cooldown = modifier_uniguard_cooldown or class({})
function modifier_uniguard_cooldown:IsHidden() return false end
function modifier_uniguard_cooldown:IsPurgable() return false end
function modifier_uniguard_cooldown:IsDebuff() return true end
function modifier_uniguard_cooldown:RemoveOnDeath() return false end

modifier_uniguard_active_cooldown = modifier_uniguard_cooldown


modifier_uniguard_active = modifier_uniguard_active or class({})
function modifier_uniguard_active:IsDebuff() return false end
function modifier_uniguard_active:IsPurgable() return true end
function modifier_uniguard_active:OnCreated()
	if not IsServer() then return end
	local owner = self:GetParent()
	local crimson_guard_pfx = ParticleManager:CreateParticle("particles/items2_fx/vanguard_active.vpcf", PATTACH_OVERHEAD_FOLLOW, self:GetCaster())
	ParticleManager:SetParticleControlEnt(crimson_guard_pfx, 0, owner, PATTACH_OVERHEAD_FOLLOW, nil, owner:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(crimson_guard_pfx, 1, owner, PATTACH_ABSORIGIN_FOLLOW, nil, owner:GetAbsOrigin(), true)
	self:AddParticle(crimson_guard_pfx, false, false, -1, false, false)

	self.active_block = self:GetAbility():GetSpecialValueFor("active_block")
	self.max_hp_pct = self:GetAbility():GetSpecialValueFor("active_block_max_hp_pct")
	self.block = self.active_block + (self:GetCaster():GetMaxHealth() * (self.max_hp_pct / 100))
	self:SetHasCustomTransmitterData(true)

	self:OnIntervalThink()
	self:StartIntervalThink(0.1)
end
function modifier_uniguard_active:OnRefresh()
	self.active_block = self:GetAbility():GetSpecialValueFor("active_block")
	self.max_hp_pct = self:GetAbility():GetSpecialValueFor("active_block_max_hp_pct")
	self.block = self.active_block + (self:GetCaster():GetMaxHealth() * (self.max_hp_pct / 100))
	self:SendBuffRefreshToClients()
end
function modifier_uniguard_active:OnIntervalThink()
	if not IsServer() then return end
	self.block = self.active_block + (self:GetCaster():GetMaxHealth() * (self.max_hp_pct / 100))
	self:SendBuffRefreshToClients()
end
function modifier_uniguard_active:AddCustomTransmitterData()
	return {
		block = self.block,
	}
end
function modifier_uniguard_active:HandleCustomTransmitterData(data)
	self.block = data.block
end
function modifier_uniguard_active:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PHYSICAL_CONSTANT_BLOCK,
	}
end
function modifier_uniguard_active:GetModifierPhysical_ConstantBlock()
	if IsClient() then return self.block end
	if not IsServer() then return end
	return self.block
end



---------------------
-- Pipe of Insight --
---------------------
LinkLuaModifier("modifier_pipe_of_insight", "items/shields", LUA_MODIFIER_MOTION_NONE)
for i = 1, 3 do
	LinkLuaModifier("modifier_pipe_of_insight_"..i.."_aura", "items/shields", LUA_MODIFIER_MOTION_NONE)
end
LinkLuaModifier("modifier_pipe_of_insight_barrier", "items/shields", LUA_MODIFIER_MOTION_NONE)


item_pipe_of_insight = item_pipe_of_insight or class({})
function item_pipe_of_insight:GetAOERadius() return self:GetSpecialValueFor("aura_radius") end
function item_pipe_of_insight:GetIntrinsicModifierName() return "modifier_pipe_of_insight" end
function item_pipe_of_insight:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor("barrier_radius")
	local duration = self:GetSpecialValueFor("barrier_duration")
	
	local targets = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HEROES_AND_CREEPS + DOTA_UNIT_TARGET_BUILDING, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)
	for i = 1, #targets do
		targets[i]:RemoveModifierByName("modifier_pipe_of_insight_barrier")
		targets[i]:AddNewModifier(caster, self, "modifier_pipe_of_insight_barrier", {duration = duration})
	end
	caster:EmitSound("DOTA_Item.Pipe.Activate")
end

item_pipe_of_insight_2 = item_pipe_of_insight
item_pipe_of_insight_3 = item_pipe_of_insight


modifier_pipe_of_insight = modifier_pipe_of_insight or class({})
function modifier_pipe_of_insight:IsHidden() return true end
function modifier_pipe_of_insight:IsPurgable() return false end
function modifier_pipe_of_insight:IsPermanent() return true end
function modifier_pipe_of_insight:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end
function modifier_pipe_of_insight:OnCreated()
	self.level = self:GetAbility():GetLevel()
end
function modifier_pipe_of_insight:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
		MODIFIER_PROPERTY_MAGICAL_CONSTANT_BLOCK,
	}
end
function modifier_pipe_of_insight:GetModifierConstantHealthRegen()
	if self:GetAbility() then return self:GetAbility():GetSpecialValueFor("bonus_health_regen") end
end
function modifier_pipe_of_insight:GetModifierMagicalResistanceBonus()
	if self:GetAbility() then return self:GetAbility():GetSpecialValueFor("bonus_magic_armor") end
end
function modifier_pipe_of_insight:GetModifierMagical_ConstantBlock(keys)
	if not IsServer() then return end
	local ability = self:GetAbility()
	if not ability then return end
	local damage = keys.damage
	if damage <= 0 then return end
	local owner = self:GetParent()
	if owner:HasModifier("modifier_uniguard_cooldown") then return end
	local min_damage = ability:GetSpecialValueFor("min_damage")
	if damage < min_damage then return end
	local magic_block_cooldown = ability:GetSpecialValueFor("magic_block_cooldown")
	owner:AddNewModifier(owner, ability, "modifier_uniguard_cooldown", {duration = magic_block_cooldown})
	local magic_damage_block = ability:GetSpecialValueFor("magic_damage_block")
	local block = math.min(magic_damage_block, damage)
	owner:EmitSound("DOTA_Item.InfusedRaindrop")
	SendOverheadEventMessage(nil, OVERHEAD_ALERT_MAGICAL_BLOCK, owner, block, nil)
	return block
end
function modifier_pipe_of_insight:IsAura() return true end
function modifier_pipe_of_insight:IsAuraActiveOnDeath() return false end
function modifier_pipe_of_insight:GetAuraRadius()
	if self:GetAbility() then return self:GetAbility():GetSpecialValueFor("aura_radius") end
end
function modifier_pipe_of_insight:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_FRIENDLY end
function modifier_pipe_of_insight:GetAuraSearchType() return DOTA_UNIT_TARGET_HEROES_AND_CREEPS end
function modifier_pipe_of_insight:GetAuraSearchFlags() return DOTA_UNIT_TARGET_FLAG_NONE end
function modifier_pipe_of_insight:GetAuraDuration() return 0.5 end
function modifier_pipe_of_insight:GetModifierAura() return "modifier_pipe_of_insight_"..self.level.."_aura" end
function modifier_pipe_of_insight:GetAuraEntityReject(target)
	local level = self.level
	for i = 3, level + 1, -1 do
		if target:HasModifier("modifier_pipe_of_insight_"..i.."_aura") then
			return true
		end
	end
end


modifier_pipe_of_insight_aura = modifier_pipe_of_insight_aura or class({})
function modifier_pipe_of_insight_aura:IsHidden() return false end
function modifier_pipe_of_insight_aura:IsPurgable() return false end
function modifier_pipe_of_insight_aura:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
	}
end
function modifier_pipe_of_insight_aura:GetModifierConstantHealthRegen()
	if self:GetAbility() then return self:GetAbility():GetSpecialValueFor("aura_health_regen") end
end
function modifier_pipe_of_insight_aura:GetModifierMagicalResistanceBonus()
	if self:GetAbility() then return self:GetAbility():GetSpecialValueFor("aura_magic_resistance") end
end

modifier_pipe_of_insight_1_aura = modifier_pipe_of_insight_aura
modifier_pipe_of_insight_2_aura = modifier_pipe_of_insight_aura
modifier_pipe_of_insight_3_aura = modifier_pipe_of_insight_aura


modifier_pipe_of_insight_barrier = modifier_pipe_of_insight_barrier or class({})
function modifier_pipe_of_insight_barrier:IsHidden() return false end
function modifier_pipe_of_insight_barrier:IsDebuff() return false end
function modifier_pipe_of_insight_barrier:IsPurgable() return false end
function modifier_pipe_of_insight_barrier:IsPurgeException() return false end
function modifier_pipe_of_insight_barrier:OnCreated()
	if not IsServer() then return end
	local owner = self:GetParent()
	self.barrier_block = self:GetAbility():GetSpecialValueFor("barrier_block")
	if owner.GetMaxMana then
		self.barrier_block = self.barrier_block + (self:GetCaster():GetMaxMana() * (self:GetAbility():GetSpecialValueFor("barrier_block_max_mp_pct") / 100))
	end
	self.max_barrier_block = self.barrier_block
	self:SetHasCustomTransmitterData(true)

	local hood_pfx = ParticleManager:CreateParticle("particles/items2_fx/pipe_of_insight_v2.vpcf", PATTACH_OVERHEAD_FOLLOW, self:GetCaster())
	ParticleManager:SetParticleControlEnt(hood_pfx, 0, owner, PATTACH_OVERHEAD_FOLLOW, nil, owner:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(hood_pfx, 1, owner, PATTACH_ABSORIGIN_FOLLOW, nil, owner:GetAbsOrigin(), true)
	ParticleManager:SetParticleControl(hood_pfx, 2, Vector(owner:GetModelRadius() * 1.1, 0, 0))
	self:AddParticle(hood_pfx, false, false, -1, false, false)
end
function modifier_pipe_of_insight_barrier:AddCustomTransmitterData()
	return {
		barrier_block = self.barrier_block,
		max_barrier_block = self.max_barrier_block,
	}
end
function modifier_pipe_of_insight_barrier:HandleCustomTransmitterData(data)
	self.barrier_block = data.barrier_block
	self.max_barrier_block = data.max_barrier_block
end
function modifier_pipe_of_insight_barrier:DeclareFunctions()
	return {MODIFIER_PROPERTY_INCOMING_SPELL_DAMAGE_CONSTANT}
end
function modifier_pipe_of_insight_barrier:GetModifierIncomingSpellDamageConstant(keys)
	if IsClient() then
		if keys.report_max then
			return self.max_barrier_block
		else
			return self.barrier_block
		end
	end
	
	if not IsServer() then return end
	if keys.damage_type == DAMAGE_TYPE_MAGICAL then
		if keys.damage >= self.barrier_block then
			self:Destroy()
			return self.barrier_block * (-1)
		else
			self.barrier_block = self.barrier_block - keys.damage
			self:SendBuffRefreshToClients()
			return keys.damage * (-1)
		end
	end
end
