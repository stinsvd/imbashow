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
function modifier_item_skadi_custom:IsPurgable() return false end
function modifier_item_skadi_custom:IsPermanent() return true end

function modifier_item_skadi_custom:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_skadi_custom:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
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
    self.bonusArmor = ability:GetSpecialValueFor("bonus_armor")
    self.bonusAttackSpeed = ability:GetSpecialValueFor("bonus_attack_speed")
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

function modifier_item_skadi_custom:GetModifierPhysicalArmorBonus()
    return self.bonusArmor
end

function modifier_item_skadi_custom:GetModifierAttackSpeedBonus_Constant()
    return self.bonusAttackSpeed
end

function modifier_item_skadi_custom:GetModifierHealthBonus()
    return self.healthBonus
end

function modifier_item_skadi_custom:GetModifierManaBonus()
    return self.manaBonus
end

function modifier_item_skadi_custom:OnAttackLanded(params)
	if not IsServer() then return end
	local target = keys.target
	local attacker = keys.attacker
	if not target then return end
	if not attacker then return end
	if attacker ~= self:GetParent() then return end
	if target:IsBuilding() or target:IsOther() or target:IsMagicImmune() then return end
	target:AddNewModifier(attacker, self:GetAbility(), "modifier_item_skadi_custom_slow", {duration = self.slowDuration * (1 - target:GetStatusResistance())})
end

modifier_item_skadi_custom_slow = modifier_item_skadi_custom_slow or class({})
function modifier_item_skadi_custom_slow:IsDebuff() return true end
function modifier_item_skadi_custom_slow:GetStatusEffectName() return "particles/status_fx/status_effect_frost_lich.vpcf" end
function modifier_item_skadi_custom_slow:StatusEffectPriority() return 10 end
function modifier_item_skadi_custom_slow:OnCreated() self:OnRefresh() end
function modifier_item_skadi_custom_slow:OnRefresh()
	self.slow_movement_speed = self:GetAbility():GetSpecialValueFor("slow_movement_speed")
	self.slow_attack_speed = self:GetAbility():GetSpecialValueFor("slow_attack_speed")
	self.heal_reduction = self:GetAbility():GetSpecialValueFor("heal_reduction")
end
function modifier_item_skadi_custom_slow:DeclareFunctions()
    return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET,
		MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
		MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE,
		MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE,
	}
end
function modifier_item_skadi_custom_slow:GetModifierMoveSpeedBonus_Percentage() return self.slow_movement_speed end
function modifier_item_skadi_custom_slow:GetModifierAttackSpeedBonus_Constant() return self.slow_attack_speed end
function modifier_item_skadi_custom_slow:GetModifierHealAmplify_PercentageTarget() return self.heal_reduction end
function modifier_item_skadi_custom_slow:GetModifierHPRegenAmplify_Percentage() return self.heal_reduction end
function modifier_item_skadi_custom_slow:GetModifierLifestealRegenAmplify_Percentage() return self.heal_reduction end
function modifier_item_skadi_custom_slow:GetModifierSpellLifestealRegenAmplify_Percentage() return self.heal_reduction end
