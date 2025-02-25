--------------------
-- Harm Supremacy --
--------------------
LinkLuaModifier("modifier_orcl_harm_supremacy", "heroes/oracle/harm_supremacy", LUA_MODIFIER_MOTION_NONE)


orcl_harm_supremacy = orcl_harm_supremacy or class({})
function orcl_harm_supremacy:GetIntrinsicModifierName() return "modifier_orcl_harm_supremacy" end


modifier_orcl_harm_supremacy = modifier_orcl_harm_supremacy or class({})
function modifier_orcl_harm_supremacy:IsHidden() return true end
function modifier_orcl_harm_supremacy:IsPurgable() return false end
function modifier_orcl_harm_supremacy:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ABILITY_FULLY_CAST,
		MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
		MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL,
		MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL_VALUE,
	}
end
function modifier_orcl_harm_supremacy:OnAbilityFullyCast(params)
	if not IsServer() then return end
	local parent = self:GetParent()
	local ability = params.ability
	if not ability then return end
	if params.unit ~= parent then return end
	if parent:PassivesDisabled() then return end
	if ability:IsItem() then return end
	if ability:IsToggle() then return end
	if ability:GetEffectiveCooldown(-1) <= 0 then return end
	if not ability:ProcsMagicStick() then return end

	self:IncrementStackCount()
end
function modifier_orcl_harm_supremacy:GetModifierSpellAmplify_Percentage()
	if self:GetAbility() then return self:GetAbility():GetSpecialValueFor("total_spell_amp") end
end
function modifier_orcl_harm_supremacy:GetModifierOverrideAbilitySpecial(keys)
	if self:GetParent() == nil or keys.ability == nil then return 0 end
	if keys.ability == self:GetAbility() and keys.ability_special_value == "total_spell_amp" then
		return 1
	end
	return 0
end
function modifier_orcl_harm_supremacy:GetModifierOverrideAbilitySpecialValue(keys)
	if keys.ability == self:GetAbility() and keys.ability_special_value == "total_spell_amp" then
		return self:GetAbility():GetSpecialValueFor("spell_amp_per_cast") * self:GetStackCount()
	end
end
