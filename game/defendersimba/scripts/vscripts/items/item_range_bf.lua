LinkLuaModifier("modifier_item_range_bf_custom", "items/item_range_bf", LUA_MODIFIER_MOTION_NONE)

item_range_bf = class({})

function item_range_bf:GetIntrinsicModifierName()
    return "modifier_item_range_bf_custom"
end

modifier_item_range_bf_custom = class({})

function modifier_item_range_bf_custom:IsHidden()
    return true
end
function modifier_item_range_bf_custom:IsPurgable() return false end
function modifier_item_range_bf_custom:IsPermanent() return true end

function modifier_item_range_bf_custom:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_range_bf_custom:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        MODIFIER_EVENT_ON_ATTACK_LANDED,
    }
end

function modifier_item_range_bf_custom:OnCreated()
    self.bonusStrength = self:GetAbility():GetSpecialValueFor("bonus_strength")
    self.bonusAgility = self:GetAbility():GetSpecialValueFor("bonus_agility")
    self.bonusIntellect = self:GetAbility():GetSpecialValueFor("bonus_intellect")
    self.splashDamagePercent = self:GetAbility():GetSpecialValueFor("splash_damage_percent") / 100
    self.splashRadius = self:GetAbility():GetSpecialValueFor("splash_radius")
end

function modifier_item_range_bf_custom:GetModifierBonusStats_Strength()
    return self.bonusStrength
end

function modifier_item_range_bf_custom:GetModifierBonusStats_Agility()
    return self.bonusAgility
end

function modifier_item_range_bf_custom:GetModifierBonusStats_Intellect()
    return self.bonusIntellect
end

function modifier_item_range_bf_custom:OnAttackLanded(event)
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
