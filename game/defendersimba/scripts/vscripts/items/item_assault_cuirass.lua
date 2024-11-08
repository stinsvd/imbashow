LinkLuaModifier("modifier_item_assault_cuirass_custom", "items/item_assault_cuirass", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_assault_cuirass_armor_reduction_aura", "items/item_assault_cuirass", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_assault_cuirass_armor_reduction", "items/item_assault_cuirass", LUA_MODIFIER_MOTION_NONE)

item_assault_cuirass_1 = class({})
item_assault_cuirass_2 = item_assault_cuirass_1
item_assault_cuirass_3 = item_assault_cuirass_1
item_assault_cuirass_4 = item_assault_cuirass_1
item_assault_cuirass_5 = item_assault_cuirass_1
item_assault_cuirass_6 = item_assault_cuirass_1

function item_assault_cuirass_1:GetIntrinsicModifierName()
    return "modifier_item_assault_cuirass_custom"
end

modifier_item_assault_cuirass_custom = class({})

function modifier_item_assault_cuirass_custom:IsHidden()
    return true
end

function modifier_item_assault_cuirass_custom:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_assault_cuirass_custom:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,  -- Бонус к скорости атаки
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,       -- Бонус к броне
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,      -- Бонус к регенерации здоровья
    }
end

function modifier_item_assault_cuirass_custom:OnCreated()
    self.ability = self:GetAbility()
    self.bonus_attack_speed = self.ability:GetSpecialValueFor("bonus_attack_speed")     -- Значение от всех предметов, дающих скорость атаки
    self.bonus_armor = self.ability:GetSpecialValueFor("bonus_armor")                   -- Суммарный бонус от предметов, дающих броню
    self.bonus_health_regen = self.ability:GetSpecialValueFor("bonus_health_regen")     -- От item_helm_of_iron_will
end

function modifier_item_assault_cuirass_custom:GetModifierAttackSpeedBonus_Constant()
    return self.bonus_attack_speed
end

function modifier_item_assault_cuirass_custom:GetModifierPhysicalArmorBonus()
    return self.bonus_armor
end

function modifier_item_assault_cuirass_custom:GetModifierConstantHealthRegen()
    return self.bonus_health_regen
end

-- Настройка ауры снижения брони
function modifier_item_assault_cuirass_custom:IsAura()
    return true
end

function modifier_item_assault_cuirass_custom:GetAuraRadius()
    return self:GetAbility():GetSpecialValueFor("aura_radius")
end

function modifier_item_assault_cuirass_custom:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_item_assault_cuirass_custom:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_item_assault_cuirass_custom:GetModifierAura()
    return "modifier_item_assault_cuirass_armor_reduction"
end

-- Модификатор снижения брони для врагов в радиусе
modifier_item_assault_cuirass_armor_reduction = class({})

function modifier_item_assault_cuirass_armor_reduction:DeclareFunctions()
    return { MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS }
end

function modifier_item_assault_cuirass_armor_reduction:GetModifierPhysicalArmorBonus()
    return self:GetAbility():GetSpecialValueFor("armor_reduction")
end
