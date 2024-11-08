LinkLuaModifier("modifier_item_skadi_custom", "items/item_skadi_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_skadi_custom_slow", "items/item_skadi_custom", LUA_MODIFIER_MOTION_NONE)

item_skadi_custom_1 = class({})
item_skadi_custom_2 = item_skadi_custom_1
item_skadi_custom_3 = item_skadi_custom_1
item_skadi_custom_4 = item_skadi_custom_1
item_skadi_custom_5 = item_skadi_custom_1
item_skadi_custom_6 = item_skadi_custom_1

function item_skadi_custom_1:GetIntrinsicModifierName()
    return "modifier_item_skadi_custom"
end

modifier_item_skadi_custom = class({})

function modifier_item_skadi_custom:IsHidden()
    return true
end

function modifier_item_skadi_custom:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_skadi_custom:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_PROPERTY_EVASION_CONSTANT,
        MODIFIER_PROPERTY_HEALTH_BONUS,
        MODIFIER_PROPERTY_MANA_BONUS,
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
end

function modifier_item_skadi_custom:OnCreated()
    local ability = self:GetAbility()
    self.bonusStrength = ability:GetSpecialValueFor("bonus_strength")
    self.bonusAgility = ability:GetSpecialValueFor("bonus_agility")
    self.bonusIntellect = ability:GetSpecialValueFor("bonus_intellect")
    self.bonusHealthRegen = ability:GetSpecialValueFor("bonus_health_regen")
    self.bonusDamage = ability:GetSpecialValueFor("bonus_damage")
    self.evasion = ability:GetSpecialValueFor("evasion")
    self.healthBonus = ability:GetSpecialValueFor("health_bonus")
    self.manaBonus = ability:GetSpecialValueFor("mana_bonus")
    self.slowDuration = ability:GetSpecialValueFor("slow_duration")
end

function modifier_item_skadi_custom:GetModifierBonusStats_Strength()
    return self.bonusStrength
end

function modifier_item_skadi_custom:GetModifierBonusStats_Agility()
    return self.bonusAgility
end

function modifier_item_skadi_custom:GetModifierBonusStats_Intellect()
    return self.bonusIntellect
end

function modifier_item_skadi_custom:GetModifierConstantHealthRegen()
    return self.bonusHealthRegen
end

function modifier_item_skadi_custom:GetModifierPreAttack_BonusDamage()
    return self.bonusDamage
end

function modifier_item_skadi_custom:GetModifierEvasion_Constant()
    return self.evasion
end

function modifier_item_skadi_custom:GetModifierHealthBonus()
    return self.healthBonus
end

function modifier_item_skadi_custom:GetModifierManaBonus()
    return self.manaBonus
end

function modifier_item_skadi_custom:OnAttackLanded(params)
    if IsServer() then
        local parent = self:GetParent()
        if params.attacker == parent and params.target:IsAlive() and not params.target:IsMagicImmune() then
            params.target:AddNewModifier(parent, self:GetAbility(), "modifier_item_skadi_custom_slow", {duration = self.slowDuration})
        end
    end
end

modifier_item_skadi_custom_slow = class({})

function modifier_item_skadi_custom_slow:IsDebuff()
    return true
end

function modifier_item_skadi_custom_slow:DeclareFunctions()
    return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT }
end

function modifier_item_skadi_custom_slow:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("slow_movement_speed")
end

function modifier_item_skadi_custom_slow:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("slow_attack_speed")
end
