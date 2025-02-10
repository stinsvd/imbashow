LinkLuaModifier("modifier_item_desolator_custom", "items/item_desolator_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_desolator_custom_debuff", "items/item_desolator_custom", LUA_MODIFIER_MOTION_NONE)

item_desolator_custom_1 = class({})
item_desolator_custom_2 = item_desolator_custom_1
item_desolator_custom_3 = item_desolator_custom_1
item_desolator_custom_4 = item_desolator_custom_1
item_desolator_custom_5 = item_desolator_custom_1
item_desolator_custom_6 = item_desolator_custom_1

function item_desolator_custom_1:GetIntrinsicModifierName()
    return "modifier_item_desolator_custom"
end

modifier_item_desolator_custom = class({})

function modifier_item_desolator_custom:IsHidden()
    return true
end
function modifier_item_desolator_custom:IsPurgable() return false end
function modifier_item_desolator_custom:IsPermanent() return true end

function modifier_item_desolator_custom:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_desolator_custom:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,          -- Бонус к урону
        MODIFIER_EVENT_ON_ATTACK_LANDED,                   -- Событие при успешной атаке для снижения брони
    }
end

function modifier_item_desolator_custom:OnCreated()
    self.bonusDamage = self:GetAbility():GetSpecialValueFor("bonus_damage")
    self.armorReductionDuration = self:GetAbility():GetSpecialValueFor("armor_reduction_duration")
end

function modifier_item_desolator_custom:GetModifierPreAttack_BonusDamage()
    return self.bonusDamage
end

function modifier_item_desolator_custom:OnAttackLanded(params)
    if params.attacker == self:GetParent() and params.target:IsAlive() then
        params.target:AddNewModifier(
            self:GetParent(),
            self:GetAbility(),
            "modifier_item_desolator_custom_debuff",
            { duration = self.armorReductionDuration * (1 - params.target:GetStatusResistance()) }
        )
    end
end

-- Модификатор дебаффа, который уменьшает броню цели
modifier_item_desolator_custom_debuff = modifier_item_desolator_custom_debuff or class({})
function modifier_item_desolator_custom_debuff:IsHidden() return false end
function modifier_item_desolator_custom_debuff:OnCreated() self:OnRefresh() end
function modifier_item_desolator_custom_debuff:OnRefresh()
	self.armor_reduction = self:GetAbility():GetSpecialValueFor("armor_reduction")
end
function modifier_item_desolator_custom_debuff:DeclareFunctions()
    return {MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS}
end
function modifier_item_desolator_custom_debuff:GetModifierPhysicalArmorBonus() return self.armor_reduction * (-1) end
