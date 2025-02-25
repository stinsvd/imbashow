LinkLuaModifier("modifier_item_heart_of_tarrasque", "items/item_heart_of_tarrasque", LUA_MODIFIER_MOTION_NONE)

item_heart_of_tarrasque_1 = class({})
item_heart_of_tarrasque_2 = item_heart_of_tarrasque_1
item_heart_of_tarrasque_3 = item_heart_of_tarrasque_1
item_heart_of_tarrasque_4 = item_heart_of_tarrasque_1
item_heart_of_tarrasque_5 = item_heart_of_tarrasque_1
item_heart_of_tarrasque_6 = item_heart_of_tarrasque_1

function item_heart_of_tarrasque_1:GetIntrinsicModifierName()
	return "modifier_item_heart_of_tarrasque"
end


modifier_item_heart_of_tarrasque = class({})

function modifier_item_heart_of_tarrasque:IsHidden()
	return true
end
function modifier_item_heart_of_tarrasque:IsPurgable() return false end
function modifier_item_heart_of_tarrasque:IsPermanent() return true end

function modifier_item_heart_of_tarrasque:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_heart_of_tarrasque:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_HEALTH_BONUS,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE_UNIQUE,
	}
end

function modifier_item_heart_of_tarrasque:OnCreated()
	self.bonus_health = self:GetAbility():GetSpecialValueFor("bonus_health")
	self.bonus_strength = self:GetAbility():GetSpecialValueFor("bonus_strength")
	self.health_regen_pct = self:GetAbility():GetSpecialValueFor("health_regen_pct")
	self.bonus_health_regen = self:GetAbility():GetSpecialValueFor("bonus_health_regen")
end

function modifier_item_heart_of_tarrasque:GetModifierHealthBonus()
	return self.bonus_health
end

function modifier_item_heart_of_tarrasque:GetModifierBonusStats_Strength()
	return self.bonus_strength
end

function modifier_item_heart_of_tarrasque:GetModifierHealthRegenPercentage()
	return self.health_regen_pct
end

function modifier_item_heart_of_tarrasque:GetModifierConstantHealthRegen()
	return self.bonus_health_regen
end