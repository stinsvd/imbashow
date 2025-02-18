LinkLuaModifier("modifier_bristleback_prickly_custom", "heroes/bristleback/bristleback_prickly_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_bristleback_prickly_custom_buff", "heroes/bristleback/bristleback_prickly_custom", LUA_MODIFIER_MOTION_NONE)


bristleback_prickly_custom = bristleback_prickly_custom or class({})
function bristleback_prickly_custom:GetIntrinsicModifierName()
	return "modifier_bristleback_prickly_custom"
end
function bristleback_prickly_custom:IsFacingBack(attacker)
	if attacker:IsBuilding() then return false end

	local forwardVector = self:GetCaster():GetForwardVector()
	local forwardAngle = math.deg(math.atan2(forwardVector.x, forwardVector.y))

	local reverseEnemyVector = (self:GetCaster():GetAbsOrigin() - attacker:GetAbsOrigin()):Normalized()
	local reverseEnemyAngle = math.deg(math.atan2(reverseEnemyVector.x, reverseEnemyVector.y))

	local back_angle = self:GetSpecialValueFor("back_angle")

	local difference = math.abs(forwardAngle - reverseEnemyAngle)

	if (difference <= back_angle) or (difference >= (360 - back_angle)) then
		return true
	end

	return false
end


modifier_bristleback_prickly_custom = modifier_bristleback_prickly_custom or class({})
function modifier_bristleback_prickly_custom:IsHidden() return true end
function modifier_bristleback_prickly_custom:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end
function modifier_bristleback_prickly_custom:OnAttackLanded(params)
	if not IsServer() then return end
	local parent = self:GetParent()
	if parent:PassivesDisabled() then return end
	if params.attacker == nil then return end
	if params.target ~= parent then return end
	if bit.band(params.damage_flags, DOTA_DAMAGE_FLAG_REFLECTION) == DOTA_DAMAGE_FLAG_REFLECTION then return end
	if bit.band(params.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) == DOTA_DAMAGE_FLAG_HPLOSS then return end

	if self:GetAbility():IsFacingBack(params.attacker) then
		params.attacker:AddNewModifier(parent, self:GetAbility(), "modifier_bristleback_prickly_custom_buff", {duration = self:GetAbility():GetSpecialValueFor("duration")})
	end
end
function modifier_bristleback_prickly_custom:GetModifierTotalDamageOutgoing_Percentage(params)
	if not IsServer() then return end
	local parent = self:GetParent()
	if parent:PassivesDisabled() then return end
	if params.attacker == nil then return end
	if not params.attacker:IsCreep() then return end
	if params.target ~= parent then return end

	if self:GetAbility():IsFacingBack(params.attacker) then
		return self:GetAbility():GetSpecialValueFor("bonus_damage")
	end
end


modifier_bristleback_prickly_custom_buff = modifier_bristleback_prickly_custom_buff or class({})
function modifier_bristleback_prickly_custom_buff:IsHidden() return false end
function modifier_bristleback_prickly_custom_buff:IsPurgable() return false end
function modifier_bristleback_prickly_custom_buff:IsDebuff() return false end
function modifier_bristleback_prickly_custom_buff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
	}
end

function modifier_bristleback_prickly_custom_buff:GetModifierAttackSpeedBonus_Constant()
	return self:GetAbility():GetSpecialValueFor("bonus_attack_speed")
end