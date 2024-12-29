LinkLuaModifier("modifier_item_butterfly_custom", "items/item_butterfly", LUA_MODIFIER_MOTION_NONE)

item_butterfly_1 = class({})
item_butterfly_2 = item_butterfly_1
item_butterfly_3 = item_butterfly_1
item_butterfly_4 = item_butterfly_1
item_butterfly_5 = item_butterfly_1
item_butterfly_6 = item_butterfly_1

function item_butterfly_1:GetIntrinsicModifierName()
    return "modifier_item_butterfly_custom"
end

modifier_item_butterfly_custom = class({})

function modifier_item_butterfly_custom:IsHidden()
    return true
end

function modifier_item_butterfly_custom:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end
 
function modifier_item_butterfly_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_PROPERTY_EVASION_CONSTANT,
    }
    return funcs
end

function modifier_item_butterfly_custom:OnCreated()
    self.bonus_agility = self:GetAbility():GetSpecialValueFor("bonus_agility")
    self.bonus_attack_speed = self:GetAbility():GetSpecialValueFor("bonus_attack_speed")
    self.bonus_damage = self:GetAbility():GetSpecialValueFor("bonus_damage")
    self.bonus_evasion = self:GetAbility():GetSpecialValueFor("bonus_evasion")
end


function modifier_item_butterfly_custom:OnRefresh()
    self:OnCreated()
end

function modifier_item_butterfly_custom:GetModifierBonusStats_Agility()
    return self.bonus_agility
end

function modifier_item_butterfly_custom:GetModifierAttackSpeedBonus_Constant()
    return self.bonus_attack_speed
end

function modifier_item_butterfly_custom:GetModifierPreAttack_BonusDamage()
    return self.bonus_damage
end

function modifier_item_butterfly_custom:GetModifierEvasion_Constant()
    return self.bonus_evasion
end


