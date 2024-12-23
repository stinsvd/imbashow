---------------------
-- Guardian Sprint --
---------------------
LinkLuaModifier("modifier_slrdr_guardian_sprint", "heroes/slardar/guardian_sprint", LUA_MODIFIER_MOTION_NONE)


slrdr_guardian_sprint = slrdr_guardian_sprint or class({})
function slrdr_guardian_sprint:Precache(context)
	PrecacheResource("particle", "particles/units/heroes/hero_slardar/slardar_sprint.vpcf", context)
end
function slrdr_guardian_sprint:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local duration = self:GetSpecialValueFor("duration")
	caster:AddNewModifier(caster, self, "modifier_slrdr_guardian_sprint", {duration = duration})
	caster:EmitSound("Hero_Slardar.Sprint")
end


modifier_slrdr_guardian_sprint = modifier_slrdr_guardian_sprint or class({})
function modifier_slrdr_guardian_sprint:IsHidden() return false end
function modifier_slrdr_guardian_sprint:IsPurgable() return false end
function modifier_slrdr_guardian_sprint:GetEffectName() return "particles/units/heroes/hero_slardar/slardar_sprint.vpcf" end
function modifier_slrdr_guardian_sprint:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end
function modifier_slrdr_guardian_sprint:OnCreated()
	self:OnRefresh()
end
function modifier_slrdr_guardian_sprint:OnRefresh()
	self.movement_pct = self:GetAbility():GetSpecialValueFor("bonus_speed")
	self.speed_burst_percent = self:GetAbility():GetSpecialValueFor("speed_burst_percent")
	self.slow_resistance = self:GetAbility():GetSpecialValueFor("slow_resistance")
	self.speed_burst_duration = self:GetAbility():GetSpecialValueFor("speed_burst_duration")
	self.slow_resist_burst_duration = self:GetAbility():GetSpecialValueFor("slow_resist_burst_duration")
end
function modifier_slrdr_guardian_sprint:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_MOVESPEED_REDUCTION_PERCENTAGE,
		MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS,
	}
end
function modifier_slrdr_guardian_sprint:GetModifierMoveSpeedBonus_Percentage()
	if self:GetElapsedTime() < self.speed_burst_duration then return self.movement_pct + self.speed_burst_percent end
	return self.movement_pct
end
function modifier_slrdr_guardian_sprint:GetModifierMoveSpeedReductionPercentage()
	if self:GetElapsedTime() < self.slow_resist_burst_duration then return 100 - self.slow_resistance end
	return 100
end
function modifier_slrdr_guardian_sprint:GetActivityTranslationModifiers() return "sprint" end
function modifier_slrdr_guardian_sprint:CheckState()
	local state = {[MODIFIER_STATE_NO_UNIT_COLLISION] = true,}
	if self:GetParent():HasModifier("modifier_slrdr_seaborn_sentinel_river") then
		state[MODIFIER_STATE_ROOTED] = false
	end
	return state
end
