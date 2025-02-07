LinkLuaModifier("modifier_item_octarine_core_custom", "items/item_octarine_core", LUA_MODIFIER_MOTION_NONE)

item_octarine_core_1 = class({})
item_octarine_core_2 = item_octarine_core_1
item_octarine_core_3 = item_octarine_core_1
item_octarine_core_4 = item_octarine_core_1
item_octarine_core_5 = item_octarine_core_1
item_octarine_core_6 = item_octarine_core_1

function item_octarine_core_1:GetIntrinsicModifierName()
    return "modifier_item_octarine_core_custom"
end


modifier_item_octarine_core_custom = class({})
function modifier_item_octarine_core_custom:IsHidden() return true end
function modifier_item_octarine_core_custom:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_item_octarine_core_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_HEALTH_BONUS,
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        MODIFIER_PROPERTY_MANA_BONUS,
        MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE,
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
        MODIFIER_PROPERTY_CAST_RANGE_BONUS_STACKING,
    }
    return funcs
end

function modifier_item_octarine_core_custom:OnCreated()
	self:OnRefresh()

	if not IsServer() then return end
	self:OnIntervalThink()
	self:StartIntervalThink(0.5)
end
function modifier_item_octarine_core_custom:OnRefresh()
	self.bonus_health = self:GetAbility():GetSpecialValueFor("bonus_health")
	self.bonus_intellect = self:GetAbility():GetSpecialValueFor("bonus_intellect")
	self.bonus_mana = self:GetAbility():GetSpecialValueFor("bonus_mana")
	self.bonusManaRegen = self:GetAbility():GetSpecialValueFor("bonus_mana_regen")
	self.cooldown_reduction = self:GetAbility():GetSpecialValueFor("cooldown_reduction")
	self.cast_range_bonus = self:GetAbility():GetSpecialValueFor("cast_range_bonus")
end
function modifier_item_octarine_core_custom:OnIntervalThink()
	if not IsServer() then return end
	if self:GetParent():FindAllModifiersByName(self:GetName())[1] == self then
		self:SetStackCount(0)
	else
		self:SetStackCount(1)
	end
end

function modifier_item_octarine_core_custom:GetModifierHealthBonus()
	return self.bonus_health
end

function modifier_item_octarine_core_custom:GetModifierBonusStats_Intellect()
	return self.bonus_intellect
end

function modifier_item_octarine_core_custom:GetModifierManaBonus()
	return self.bonus_mana
end

function modifier_item_octarine_core_custom:GetModifierConstantManaRegen()
	return self.bonusManaRegen
end

function modifier_item_octarine_core_custom:GetModifierPercentageCooldown()
	if self:GetStackCount() == 1 then return end
	return self.cooldown_reduction
end

function modifier_item_octarine_core_custom:GetModifierCastRangeBonusStacking()
	if self:GetStackCount() == 1 then return end
	return self.cast_range_bonus
end