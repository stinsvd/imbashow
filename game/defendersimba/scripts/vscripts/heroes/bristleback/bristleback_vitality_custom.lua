LinkLuaModifier("modifier_bristleback_vitality_custom", "heroes/bristleback/bristleback_vitality_custom", LUA_MODIFIER_MOTION_NONE)


bristleback_vitality_custom = bristleback_vitality_custom or class({})
function bristleback_vitality_custom:GetIntrinsicModifierName() return "modifier_bristleback_vitality_custom" end


modifier_bristleback_vitality_custom = modifier_bristleback_vitality_custom or class({})
function modifier_bristleback_vitality_custom:IsHidden() return true end
function modifier_bristleback_vitality_custom:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_HEALTH_BONUS,
	}
end
function modifier_bristleback_vitality_custom:GetModifierHealthBonus()
	if not self:GetAbility() then return end
	local owner = self:GetParent()
	local bonusHealth = self:GetAbility():GetSpecialValueFor("health_per_str")
	if owner.GetStrength then
		bonusHealth = owner:GetStrength() * bonusHealth
	end
	return bonusHealth
end
