LinkLuaModifier("modifier_item_range_btfury_custom", "items/item_range_btfury", LUA_MODIFIER_MOTION_NONE)

item_range_btfury_1 = class({})
item_range_btfury_2 = item_range_btfury_1
item_range_btfury_3 = item_range_btfury_1
item_range_btfury_4 = item_range_btfury_1
item_range_btfury_5 = item_range_btfury_1
item_range_btfury_6 = item_range_btfury_1

function item_range_btfury_1:GetIntrinsicModifierName()
    return "modifier_item_range_btfury_custom"
end

modifier_item_range_btfury_custom = class({})

function modifier_item_range_btfury_custom:IsHidden()
    return true
end

function modifier_item_range_btfury_custom:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_range_btfury_custom:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
        MODIFIER_EVENT_ON_ATTACK_LANDED,
    }
end

function modifier_item_range_btfury_custom:OnCreated()
    local ability = self:GetAbility()
    self.bonusStrength = ability:GetSpecialValueFor("bonus_strength")
    self.bonusAgility = ability:GetSpecialValueFor("bonus_agility")
    self.bonusIntellect = ability:GetSpecialValueFor("bonus_intellect")
    self.bonusDamage = ability:GetSpecialValueFor("bonus_damage")
    self.bonusAttackSpeed = ability:GetSpecialValueFor("bonus_attack_speed")
    self.bonusHealthRegen = ability:GetSpecialValueFor("bonus_health_regen")
    self.bonusManaRegen = ability:GetSpecialValueFor("bonus_mana_regen")
    self.splashDamagePercent = ability:GetSpecialValueFor("splash_damage_percent") / 100
    self.splashRadius = ability:GetSpecialValueFor("splash_radius")
end

function modifier_item_range_btfury_custom:GetModifierBonusStats_Strength()
    return self.bonusStrength
end

function modifier_item_range_btfury_custom:GetModifierBonusStats_Agility()
    return self.bonusAgility
end

function modifier_item_range_btfury_custom:GetModifierBonusStats_Intellect()
    return self.bonusIntellect
end

function modifier_item_range_btfury_custom:GetModifierPreAttack_BonusDamage()
    return self.bonusDamage
end

function modifier_item_range_btfury_custom:GetModifierAttackSpeedBonus_Constant()
    return self.bonusAttackSpeed
end

function modifier_item_range_btfury_custom:GetModifierConstantHealthRegen()
    return self.bonusHealthRegen
end

function modifier_item_range_btfury_custom:GetModifierConstantManaRegen()
    return self.bonusManaRegen
end

function modifier_item_range_btfury_custom:OnAttackLanded(event)
    local parent = self:GetParent()

    if event.attacker ~= parent or not parent:IsRangedAttacker() then
        return
    end

    local enemies = FindUnitsInRadius(
        parent:GetTeamNumber(),
        event.target:GetAbsOrigin(),
        nil,
        self.splashRadius,
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_ANY_ORDER,
        false
    )

    for _, enemy in pairs(enemies) do
        if enemy ~= event.target then
            local splashDamage = event.damage * self.splashDamagePercent
            ApplyDamage({
                victim = enemy,
                attacker = parent,
                damage = splashDamage,
                damage_type = DAMAGE_TYPE_PHYSICAL,
                ability = self:GetAbility(),
            })
        end
    end
end
