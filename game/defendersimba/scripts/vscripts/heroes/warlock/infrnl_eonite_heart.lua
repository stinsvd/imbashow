------------------
-- Eonite Heart --
------------------
LinkLuaModifier("modifier_infrnl_eonite_heart", "heroes/warlock/infrnl_eonite_heart", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_infrnl_eonite_heart_burn", "heroes/warlock/infrnl_eonite_heart", LUA_MODIFIER_MOTION_NONE)

infrnl_eonite_heart = infrnl_eonite_heart or class({})
function infrnl_eonite_heart:Precache(context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_leshrac.vsndevts", context)
	PrecacheResource("particle", "particles/units/heroes/hero_phoenix/phoenix_fire_spirit_burn.vpcf", context)
	PrecacheResource("particle", "particles/custom/abilities/heroes/infrnl_eonite_heart/status_effect_infrnl_eonite_heart.vpcf", context)
	PrecacheResource("particle", "particles/custom/abilities/heroes/infrnl_eonite_heart/infrnl_eonite_heart_ambient.vpcf", context)
--	PrecacheResource("particle_folder", "particles/custom/abilities/heroes/infrnl_eonite_heart/", context)
end
function infrnl_eonite_heart:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local duration = self:GetSpecialValueFor("duration")
	
	caster:EmitSound("Hero_Leshrac.Nihilism.Cast")
	caster:AddNewModifier(caster, self, "modifier_infrnl_eonite_heart", {duration = duration})
end


modifier_infrnl_eonite_heart = modifier_infrnl_eonite_heart or class({})
function modifier_infrnl_eonite_heart:IsHidden() return false end
function modifier_infrnl_eonite_heart:IsPurgable() return false end
function modifier_infrnl_eonite_heart:GetStatusEffectName() return "particles/custom/abilities/heroes/infrnl_eonite_heart/status_effect_infrnl_eonite_heart.vpcf" end
function modifier_infrnl_eonite_heart:StatusEffectPriority() return 1 end
function modifier_infrnl_eonite_heart:GetEffectName() return "particles/custom/abilities/heroes/infrnl_eonite_heart/infrnl_eonite_heart_ambient.vpcf" end
function modifier_infrnl_eonite_heart:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end
function modifier_infrnl_eonite_heart:OnCreated() self:OnRefresh() end
function modifier_infrnl_eonite_heart:OnRefresh()
	self.bonus_health_pct = self:GetAbility():GetSpecialValueFor("bonus_health_pct")
	self.bonus_model_scale = self:GetAbility():GetSpecialValueFor("bonus_model_scale")
	self.burn_damage = self:GetAbility():GetSpecialValueFor("burn_damage")
	self.burn_duration = self:GetAbility():GetSpecialValueFor("burn_duration")
end
function modifier_infrnl_eonite_heart:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_EXTRA_HEALTH_PERCENTAGE,
		MODIFIER_PROPERTY_MODEL_SCALE,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end
function modifier_infrnl_eonite_heart:GetModifierExtraHealthPercentage() return self.bonus_health_pct end
function modifier_infrnl_eonite_heart:GetModifierModelScale() return self.bonus_model_scale end
function modifier_infrnl_eonite_heart:OnAttackLanded(keys)
	if not IsServer() then return end
	if self.burn_damage <= 0 then return end
	local target = keys.target
	local attacker = keys.attacker
	
	if not target then return end
	if not attacker then return end
	if attacker:PassivesDisabled() then return end
	if self:GetParent() == attacker then
		if attacker:GetTeamNumber() == target:GetTeamNumber() then return end
		if target:IsMagicImmune() then return end
		if target:IsBuilding() then return end
		if target:IsOther() then return end
		target:AddNewModifier(attacker, self:GetAbility(), "modifier_infrnl_eonite_heart_burn", {duration = self.burn_duration * (1 - target:GetStatusResistance())})
	end
end
function modifier_infrnl_eonite_heart:CheckState()
	return {
		[MODIFIER_STATE_DEBUFF_IMMUNE] = true,
	}
end

modifier_infrnl_eonite_heart_burn = modifier_infrnl_eonite_heart_burn or class({})
function modifier_infrnl_eonite_heart_burn:IsHidden() return false end
function modifier_infrnl_eonite_heart_burn:IsPurgable() return true end
function modifier_infrnl_eonite_heart_burn:OnCreated()
	self.burn_damage = self:GetAbility():GetSpecialValueFor("burn_damage")
	self.burn_interval = self:GetAbility():GetSpecialValueFor("burn_interval")
	self.burn_magic_resistance = self:GetAbility():GetSpecialValueFor("burn_magic_resistance")
	
	if not IsServer() then return end
	local caster = self:GetCaster()
	local owner = self:GetParent()
	local amb_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_phoenix/phoenix_fire_spirit_burn.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(amb_pfx, 0, owner, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", owner:GetAbsOrigin(), true)
	self:AddParticle(amb_pfx, false, false, -1, false, false)
	self.damageTable = {
		victim = owner,
		attacker = caster,
		ability = self:GetAbility(),
		damage = self.burn_damage * self.burn_interval,
		damage_type = DAMAGE_TYPE_MAGICAL,
	}
	self:StartIntervalThink(self.burn_interval)
end
function modifier_infrnl_eonite_heart_burn:OnIntervalThink()
	if not IsServer() then return end
	ApplyDamage(self.damageTable)
end
function modifier_infrnl_eonite_heart_burn:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
	}
end
function modifier_infrnl_eonite_heart_burn:GetModifierMagicalResistanceBonus() return self.burn_magic_resistance end
