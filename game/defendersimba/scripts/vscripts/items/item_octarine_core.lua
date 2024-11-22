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

function modifier_item_octarine_core_custom:IsHidden()
    return true
end

function modifier_item_octarine_core_custom:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_octarine_core_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_HEALTH_BONUS,
        MODIFIER_PROPERTY_MANA_BONUS,
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
        MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE,
        MODIFIER_PROPERTY_CAST_RANGE_BONUS_STACKING,
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
    }
    return funcs
end

function modifier_item_octarine_core_custom:GetModifierCastRangeBonusStacking()
    return self:GetAbility():GetSpecialValueFor("cast_range_bonus")
end

function modifier_item_octarine_core_custom:OnCreated()
    self.bonus_health = self:GetAbility():GetSpecialValueFor("bonus_health")
    self.bonus_mana = self:GetAbility():GetSpecialValueFor("bonus_mana")
    self.bonusManaRegen = self.ability:GetSpecialValueFor("bonus_mana_regen")
    self.cooldown_reduction = self:GetAbility():GetSpecialValueFor("cooldown_reduction")
    self.bonus_intellect = self:GetAbility():GetSpecialValueFor("bonus_intellect")
end

function modifier_item_octarine_core_custom:GetModifierHealthBonus()
    return self.bonus_health
end

function modifier_item_octarine_core_custom:GetModifierManaBonus()
    return self.bonus_mana
end

function modifier_item_octarine_core_custom:GetModifierMagicalResistanceBonus()
    return self.magical_resistance
end

function modifier_item_octarine_core_custom:GetModifierPercentageCooldown()
    return self.cooldown_reduction
end

function modifier_item_octarine_core_custom:GetModifierBonusStats_Intellect()
    return self.bonus_intellect
end