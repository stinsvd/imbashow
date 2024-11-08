LinkLuaModifier("modifier_item_daedalus_custom", "items/item_daedalus", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_daedalus_custom_crit", "items/item_daedalus", LUA_MODIFIER_MOTION_NONE)

item_daedalus_1 = class({})
item_daedalus_2 = item_daedalus_1
item_daedalus_3 = item_daedalus_1
item_daedalus_4 = item_daedalus_1
item_daedalus_5 = item_daedalus_1
item_daedalus_6 = item_daedalus_1

function item_daedalus_1:GetIntrinsicModifierName()
    return "modifier_item_daedalus_custom"
end

modifier_item_daedalus_custom = class({})

function modifier_item_daedalus_custom:IsHidden()
    return true
end

function modifier_item_daedalus_custom:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_daedalus_custom:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,           -- Бонус к урону
        MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,        -- Шанс критического удара и множитель
    }
end

function modifier_item_daedalus_custom:OnCreated()
    self.bonusDamage = self:GetAbility():GetSpecialValueFor("bonus_damage")
    self.critChance = self:GetAbility():GetSpecialValueFor("crit_chance")
    self.critMultiplier = self:GetAbility():GetSpecialValueFor("crit_multiplier")
end

function modifier_item_daedalus_custom:GetModifierPreAttack_BonusDamage()
    return self.bonusDamage
end

function modifier_item_daedalus_custom:GetModifierPreAttack_CriticalStrike(params)
    if IsServer() and RandomInt(1, 100) <= self.critChance then
        return self.critMultiplier
    end
    return nil
end
