--------------------
-- Corrosive Haze --
--------------------
LinkLuaModifier("modifier_slrdr_corrosive_haze", "heroes/slardar/corrosive_haze", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_slrdr_corrosive_haze_self_buff", "heroes/slardar/corrosive_haze", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_slrdr_corrosive_haze_thinker", "heroes/slardar/corrosive_haze", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_slrdr_corrosive_haze_puddle", "heroes/slardar/corrosive_haze", LUA_MODIFIER_MOTION_NONE)


slrdr_corrosive_haze = slrdr_corrosive_haze or class({})
function slrdr_corrosive_haze:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local duration = self:GetSpecialValueFor("duration")
	
	if target:TriggerSpellAbsorb(self) then return end
	EmitSoundOnLocationWithCaster(caster:GetAbsOrigin(), "Hero_Slardar.Amplify_Damage", caster)
	target:AddNewModifier(caster, self, "modifier_slrdr_corrosive_haze", {duration = duration * (1 - target:GetStatusResistance())})
end


modifier_slrdr_corrosive_haze = modifier_slrdr_corrosive_haze or class({})
function modifier_slrdr_corrosive_haze:IsHidden() return false end
function modifier_slrdr_corrosive_haze:IsPurgable() return self.undispellable == 0 end
function modifier_slrdr_corrosive_haze:GetStatusEffectName() return "particles/status_fx/status_effect_slardar_amp_damage.vpcf" end
function modifier_slrdr_corrosive_haze:IsDebuff() return true end
function modifier_slrdr_corrosive_haze:OnCreated()
	self:OnRefresh()
	
	if not IsServer() then return end
	local caster = self:GetCaster()
	local owner = self:GetParent()
	local buff_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_slardar/slardar_amp_damage.vpcf", PATTACH_OVERHEAD_FOLLOW, self:GetCaster())
	ParticleManager:SetParticleControlEnt(buff_pfx, 0, owner, PATTACH_OVERHEAD_FOLLOW, "attach_hitloc", owner:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(buff_pfx, 1, owner, PATTACH_OVERHEAD_FOLLOW, "attach_hitloc", owner:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(buff_pfx, 2, owner, PATTACH_OVERHEAD_FOLLOW, "attach_hitloc", owner:GetAbsOrigin(), true)
	self:AddParticle(buff_pfx, false, false, -1, false, true)
	
	if self.has_self_buff > 0 then
		self.selfArmor = self.armor_reduction * (self.armor_pct / 100)
		self.buff = caster:AddNewModifier(caster, self:GetAbility(), "modifier_slrdr_corrosive_haze_self_buff", {duration = self:GetRemainingTime(), bonus_armor = self.selfArmor, undispellable = self.undispellable})
		self.buff:IncrementStackCount()
	end
	
	self:StartIntervalThink(0.5)
end
function modifier_slrdr_corrosive_haze:OnRefresh()
	self.armor_reduction = self:GetAbility():GetSpecialValueFor("armor_reduction")
	self.has_self_buff = self:GetAbility():GetSpecialValueFor("has_self_buff")
	self.armor_pct = self:GetAbility():GetSpecialValueFor("armor_pct")
	self.undispellable = self:GetAbility():GetSpecialValueFor("undispellable")

	if not IsServer() then return end
	local caster = self:GetCaster()
	local target = self:GetParent()
	if caster and target and caster:IsAlive() and target:IsAlive() then
		caster:PerformAttack(target, true, true, true, false, false, false, true)
	end
	
	if self.has_self_buff > 0 and self.buff then
		self.buff:SetDuration(self:GetRemainingTime(), true)
		self.buff:ForceRefresh()
	end
end
function modifier_slrdr_corrosive_haze:OnIntervalThink()
	if not IsServer() then return end
	if not self:GetAbility() then return end
	local caster = self:GetCaster()
	local current_position = self:GetParent():GetAbsOrigin()
	local radius = self:GetAbility():GetSpecialValueFor("puddle_radius")
	local duration = self:GetAbility():GetSpecialValueFor("puddle_duration")
	
	if not self.lastThinker or self.lastThinker:IsNull() then
		self.lastThinker = CreateModifierThinker(caster, self:GetAbility(), "modifier_slrdr_corrosive_haze_thinker", {duration = duration, radius = radius}, current_position, caster:GetTeamNumber(), false)
	elseif (current_position - self.lastThinker:GetAbsOrigin()):Length2D() > radius then
		self.lastThinker = CreateModifierThinker(caster, self:GetAbility(), "modifier_slrdr_corrosive_haze_thinker", {duration = duration, radius = radius}, current_position, caster:GetTeamNumber(), false)
	end
end
function modifier_slrdr_corrosive_haze:OnDestroy()
	if not IsServer() then return end
	if self.buff then
		self.buff.armor_reduction = self.buff.armor_reduction - self.selfArmor
		self.buff:SetDuration(self.buff:GetRemainingTime(), true)
		self.buff:ForceRefresh()
		self.buff:DecrementStackCount()
		if self.buff:GetStackCount() <= 0 then self.buff:Destroy() end
	end
end
function modifier_slrdr_corrosive_haze:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_PROVIDES_FOW_POSITION,
	}
end
function modifier_slrdr_corrosive_haze:GetModifierPhysicalArmorBonus() return self.armor_reduction * (-1) end
function modifier_slrdr_corrosive_haze:GetModifierProvidesFOWVision() return 1 end
function modifier_slrdr_corrosive_haze:CheckState()
	return {
		[MODIFIER_STATE_INVISIBLE] = false,
	}
end


modifier_slrdr_corrosive_haze_self_buff = modifier_slrdr_corrosive_haze_self_buff or class({})
function modifier_slrdr_corrosive_haze_self_buff:IsHidden() return false end
function modifier_slrdr_corrosive_haze_self_buff:IsPurgable() return self.undispellable == 0 end
function modifier_slrdr_corrosive_haze_self_buff:DestroyOnExpire() return false end
function modifier_slrdr_corrosive_haze_self_buff:OnCreated(kv)
	if IsServer() then
		self.armor_reduction = 0
		self:SetHasCustomTransmitterData(true)
	end
	self:OnRefresh(kv)
end
function modifier_slrdr_corrosive_haze_self_buff:OnRefresh(kv)
	self.undispellable = self:GetAbility():GetSpecialValueFor("undispellable")

	if not IsServer() then return end
	self.armor_reduction = (self.armor_reduction or 0) + (kv.bonus_armor or 0)
	self:SendBuffRefreshToClients()
end
function modifier_slrdr_corrosive_haze_self_buff:AddCustomTransmitterData() return {armor_reduction = self.armor_reduction} end
function modifier_slrdr_corrosive_haze_self_buff:HandleCustomTransmitterData(data) self.armor_reduction = data.armor_reduction end
function modifier_slrdr_corrosive_haze_self_buff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
	}
end
function modifier_slrdr_corrosive_haze_self_buff:GetModifierPhysicalArmorBonus() return self.armor_reduction end


modifier_slrdr_corrosive_haze_thinker = modifier_slrdr_corrosive_haze_thinker or class({})
function modifier_slrdr_corrosive_haze_thinker:IsHidden() return true end
function modifier_slrdr_corrosive_haze_thinker:IsPurgable() return false end
function modifier_slrdr_corrosive_haze_thinker:OnCreated(kv)
	if not IsServer() then return end
	local puddle = self:GetParent()
	self.radius = kv.radius
	local puddle_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_slardar/slardar_water_puddle_test.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster())
	ParticleManager:SetParticleControlEnt(puddle_pfx, 0, puddle, PATTACH_ABSORIGIN_FOLLOW, nil, puddle:GetAbsOrigin(), true)
	ParticleManager:SetParticleControl(puddle_pfx, 1, Vector(self.radius, 1, 1))
	ParticleManager:SetParticleControl(puddle_pfx, 15, Vector(255, 255, 255))
	self:AddParticle(puddle_pfx, false, false, -1, false, false)
end
function modifier_slrdr_corrosive_haze_thinker:IsAura() return true end
function modifier_slrdr_corrosive_haze_thinker:IsAuraActiveOnDeath() return false end
function modifier_slrdr_corrosive_haze_thinker:GetAuraRadius() return self.radius end
function modifier_slrdr_corrosive_haze_thinker:GetAuraSearchFlags() return DOTA_UNIT_TARGET_FLAG_NONE end
function modifier_slrdr_corrosive_haze_thinker:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_BOTH end
function modifier_slrdr_corrosive_haze_thinker:GetAuraSearchType() return DOTA_UNIT_TARGET_HEROES_AND_CREEPS end
function modifier_slrdr_corrosive_haze_thinker:GetModifierAura() return "modifier_slrdr_corrosive_haze_puddle" end
function modifier_slrdr_corrosive_haze_thinker:GetAuraEntityReject(target)
	if target ~= self:GetCaster() then return true end
	return false
end


modifier_slrdr_corrosive_haze_puddle = modifier_slrdr_corrosive_haze_puddle or class({})
function modifier_slrdr_corrosive_haze_puddle:IsHidden() return true end
function modifier_slrdr_corrosive_haze_puddle:IsPurgable() return false end
