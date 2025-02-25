----------------------
-- Slithereen Crush --
----------------------
LinkLuaModifier("modifier_slrdr_slithereen_crush_debuff", "heroes/slardar/slithereen_crush", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_slrdr_slithereen_crush_stun", "heroes/slardar/slithereen_crush", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_slrdr_slithereen_crush_puddle_thinker", "heroes/slardar/slithereen_crush", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_slrdr_slithereen_crush_puddle", "heroes/slardar/slithereen_crush", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_slrdr_slithereen_crush_recast", "heroes/slardar/slithereen_crush", LUA_MODIFIER_MOTION_NONE)


slrdr_slithereen_crush = slrdr_slithereen_crush or class({})
function slrdr_slithereen_crush:Precache(context)
	PrecacheResource("particle", "particles/units/heroes/hero_slardar/slardar_crush.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_slardar/slardar_crush_entity.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_slardar/slardar_water_puddle_test.vpcf", context)
	PrecacheResource("particle", "particles/generic_gameplay/generic_stunned.vpcf", context)
end
function slrdr_slithereen_crush:GetAOERadius() return self:GetSpecialValueFor("crush_radius") end
function slrdr_slithereen_crush:OnSpellStart(newRadius)
	if not IsServer() then return end
	local caster = self:GetCaster()
	local damage = self:GetSpecialValueFor("crush_damage")
	if caster.GetStrength and caster:GetStrength() > 0 then
		damage = damage + (caster:GetStrength() * self:GetSpecialValueFor("crush_damage_str_pct") / 100)
	end
	local radius = newRadius or self:GetSpecialValueFor("crush_radius")
	local slow_duration = self:GetSpecialValueFor("crush_extra_slow_duration")
	local recast = self:GetSpecialValueFor("recast")
	local recast_delay = self:GetSpecialValueFor("recast_delay")
	local stun_duration = self:GetSpecialValueFor("stun_duration")
	local shard_amp_duration = self:GetSpecialValueFor("shard_amp_duration")
	local haze = caster:FindAbilityByName("slrdr_corrosive_haze")
	
	local cast_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_slardar/slardar_crush.vpcf", PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControlEnt(cast_pfx, 0, caster, PATTACH_ABSORIGIN, nil , caster:GetAbsOrigin(), true)
	ParticleManager:SetParticleControl(cast_pfx, 1, Vector(radius, radius, radius))
	ParticleManager:ReleaseParticleIndex(cast_pfx)
	
	EmitSoundOnLocationWithCaster(caster:GetAbsOrigin(), "Hero_Slardar.Slithereen_Crush", caster)
	
	local damageTable = {
		victim = nil,
		attacker = caster,
		ability = self,
		damage = damage,
		damage_type = DAMAGE_TYPE_PHYSICAL,
	}
	local enemies = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HEROES_AND_CREEPS, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	for i = 1, #enemies do
		local impact_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_slardar/slardar_crush_entity.vpcf", PATTACH_ABSORIGIN, caster)
		ParticleManager:SetParticleControlEnt(impact_pfx, 0, enemies[i], PATTACH_ABSORIGIN, nil , enemies[i]:GetAbsOrigin(), true)
		ParticleManager:ReleaseParticleIndex(impact_pfx)
		
		if haze and haze:IsTrained() then
			if shard_amp_duration > 0 then
				enemies[i]:AddNewModifier(caster, haze, "modifier_slrdr_corrosive_haze", {duration = shard_amp_duration * (1 - enemies[i]:GetStatusResistance())})
			end
		end
		
		enemies[i]:AddNewModifier(caster, self, "modifier_slrdr_slithereen_crush_debuff", {duration = slow_duration * (1 - enemies[i]:GetStatusResistance())})
		enemies[i]:AddNewModifier(caster, self, "modifier_slrdr_slithereen_crush_stun", {duration = stun_duration * (1 - enemies[i]:GetStatusResistance())})
		
		damageTable.victim = enemies[i]
		ApplyDamage(damageTable)
	end

	if not newRadius and recast > 0 then
		caster:AddNewModifier(caster, self, "modifier_slrdr_slithereen_crush_recast", {duration = (recast * recast_delay) + FrameTime()})
	end
	
	local puddle_duration = self:GetSpecialValueFor("puddle_duration")
	if puddle_duration > 0 then
		local puddle_radius = self:GetSpecialValueFor("puddle_radius")
		CreateModifierThinker(caster, self, "modifier_slrdr_slithereen_crush_puddle_thinker", {duration = puddle_duration, radius = puddle_radius}, caster:GetAbsOrigin(), caster:GetTeamNumber(), false)
	end
end


modifier_slrdr_slithereen_crush_debuff = modifier_slrdr_slithereen_crush_debuff or class({})
function modifier_slrdr_slithereen_crush_debuff:IsHidden() return false end
function modifier_slrdr_slithereen_crush_debuff:IsPurgable() return true end
function modifier_slrdr_slithereen_crush_debuff:OnCreated()
	self:OnRefresh()
end
function modifier_slrdr_slithereen_crush_debuff:OnRefresh()
	self.ms_slow = self:GetAbility():GetSpecialValueFor("crush_extra_slow")
	self.as_slow = self:GetAbility():GetSpecialValueFor("crush_attack_slow")
end
function modifier_slrdr_slithereen_crush_debuff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
	}
end
function modifier_slrdr_slithereen_crush_debuff:GetModifierMoveSpeedBonus_Percentage() return self.ms_slow * (-1) end
function modifier_slrdr_slithereen_crush_debuff:GetModifierAttackSpeedBonus_Constant() return self.as_slow * (-1) end


modifier_slrdr_slithereen_crush_stun = modifier_slrdr_slithereen_crush_stun or class({})
function modifier_slrdr_slithereen_crush_stun:IsHidden() return false end
function modifier_slrdr_slithereen_crush_stun:IsStunDebuff() return true end
function modifier_slrdr_slithereen_crush_stun:IsPurgeException() return true end
function modifier_slrdr_slithereen_crush_stun:GetEffectName() return "particles/generic_gameplay/generic_stunned.vpcf" end
function modifier_slrdr_slithereen_crush_stun:GetEffectAttachType() return PATTACH_OVERHEAD_FOLLOW end
function modifier_slrdr_slithereen_crush_stun:CheckState()
	if not self:GetParent():IsDebuffImmune() then
		return {[MODIFIER_STATE_STUNNED] = true}
	end
end
function modifier_slrdr_slithereen_crush_stun:DeclareFunctions()
	if not self:GetParent():IsDebuffImmune() then
		return {MODIFIER_PROPERTY_OVERRIDE_ANIMATION}
	end
end
function modifier_slrdr_slithereen_crush_stun:GetOverrideAnimation() return ACT_DOTA_DISABLED end


modifier_slrdr_slithereen_crush_puddle_thinker = modifier_slrdr_slithereen_crush_puddle_thinker or class({})
function modifier_slrdr_slithereen_crush_puddle_thinker:IsHidden() return true end
function modifier_slrdr_slithereen_crush_puddle_thinker:IsPurgable() return false end
function modifier_slrdr_slithereen_crush_puddle_thinker:OnCreated(kv)
	if not IsServer() then return end
	local puddle = self:GetParent()
	self.radius = kv.radius
	local puddle_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_slardar/slardar_water_puddle_test.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster())
	ParticleManager:SetParticleControlEnt(puddle_pfx, 0, puddle, PATTACH_ABSORIGIN_FOLLOW, nil, puddle:GetAbsOrigin(), true)
	ParticleManager:SetParticleControl(puddle_pfx, 1, Vector(self.radius, 1, 1))
	ParticleManager:SetParticleControl(puddle_pfx, 15, Vector(255, 255, 255))
	self:AddParticle(puddle_pfx, false, false, -1, false, false)
end
function modifier_slrdr_slithereen_crush_puddle_thinker:OnDestroy()
	if not IsServer() then return end
	self:GetParent():RemoveSelf()
end
function modifier_slrdr_slithereen_crush_puddle_thinker:IsAura() return true end
function modifier_slrdr_slithereen_crush_puddle_thinker:IsAuraActiveOnDeath() return false end
function modifier_slrdr_slithereen_crush_puddle_thinker:GetAuraRadius() return self.radius end
function modifier_slrdr_slithereen_crush_puddle_thinker:GetAuraSearchFlags() return DOTA_UNIT_TARGET_FLAG_NONE end
function modifier_slrdr_slithereen_crush_puddle_thinker:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_BOTH end
function modifier_slrdr_slithereen_crush_puddle_thinker:GetAuraSearchType() return DOTA_UNIT_TARGET_HEROES_AND_CREEPS end
function modifier_slrdr_slithereen_crush_puddle_thinker:GetModifierAura() return "modifier_slrdr_slithereen_crush_puddle" end
function modifier_slrdr_slithereen_crush_puddle_thinker:GetAuraEntityReject(target)
	if target ~= self:GetCaster() then return true end
	return false
end


modifier_slrdr_slithereen_crush_puddle = modifier_slrdr_slithereen_crush_puddle or class({})
function modifier_slrdr_slithereen_crush_puddle:IsHidden() return true end
function modifier_slrdr_slithereen_crush_puddle:IsPurgable() return false end
function modifier_slrdr_slithereen_crush_puddle:OnCreated()
	self:OnRefresh()
	self.createdTime = GameRules:GetDOTATime(true, true)
	self:StartIntervalThink(1)
end
function modifier_slrdr_slithereen_crush_puddle:OnRefresh()
	self.hp_regen = self:GetAbility():GetSpecialValueFor("puddle_regen")
	self.armor = self:GetAbility():GetSpecialValueFor("puddle_armor")
	self.slow_resistance = self:GetAbility():GetSpecialValueFor("puddle_slow_resistance")
	self.str_pct = self:GetAbility():GetSpecialValueFor("puddle_strength_pct")
	self.movement_pct = self:GetAbility():GetSpecialValueFor("river_speed")
	self.max_effect = self:GetAbility():GetSpecialValueFor("puddle_max_effect")
end
function modifier_slrdr_slithereen_crush_puddle:OnIntervalThink()
	if not IsServer() then return end
	if self:GetParent().CalculateStatBonus then
		self:GetParent():CalculateStatBonus(false)
	end
end
function modifier_slrdr_slithereen_crush_puddle:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
	}
end
function modifier_slrdr_slithereen_crush_puddle:GetModifierConstantHealthRegen()
	local elapsedTime = GameRules:GetDOTATime(true, true) - self.createdTime
	return self.hp_regen * math.min(elapsedTime / self.max_effect, 1)
end
function modifier_slrdr_slithereen_crush_puddle:GetModifierPhysicalArmorBonus()
	local elapsedTime = GameRules:GetDOTATime(true, true) - self.createdTime
	return self.armor * math.min(elapsedTime / self.max_effect, 1)
end
function modifier_slrdr_slithereen_crush_puddle:GetModifierStatusResistanceStacking()
	local elapsedTime = GameRules:GetDOTATime(true, true) - self.createdTime
	return self.slow_resistance * math.min(elapsedTime / self.max_effect, 1)
end
function modifier_slrdr_slithereen_crush_puddle:GetModifierBonusStats_Strength()
	if not IsServer() then return end
	if self.lock then return end
	
	local bonus = 0
	self.lock = true
	bonus = self:GetParent():GetStrength() * (self.str_pct / 100)
	self.lock = false
	
	local elapsedTime = GameRules:GetDOTATime(true, true) - self.createdTime
	return bonus * math.min(elapsedTime / self.max_effect, 1)
end


modifier_slrdr_slithereen_crush_recast = modifier_slrdr_slithereen_crush_recast or class({})
function modifier_slrdr_slithereen_crush_recast:IsHidden() return true end
function modifier_slrdr_slithereen_crush_recast:IsPurgable() return false end
function modifier_slrdr_slithereen_crush_recast:OnCreated()
	self.recast = self:GetAbility():GetSpecialValueFor("recast")
	self.recast_delay = self:GetAbility():GetSpecialValueFor("recast_delay")
	self.crush_radius = self:GetAbility():GetSpecialValueFor("crush_radius")
	self.recast_bonus_radius = self:GetAbility():GetSpecialValueFor("recast_bonus_radius")
	self:StartIntervalThink(self.recast_delay)
end
function modifier_slrdr_slithereen_crush_recast:OnIntervalThink()
	if not IsServer() then return end
	self.count = (self.count or 0) + 1
--	self:GetParent():StartGesture(ACT_DOTA_CAST_ABILITY_2)
	self:GetAbility():OnSpellStart(self.crush_radius + (self.recast_bonus_radius * self.count))
end
