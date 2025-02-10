LinkLuaModifier("modifier_item_ring_of_aquila_custom", "items/item_power_treads", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_power_treads_2", "items/item_power_treads", LUA_MODIFIER_MOTION_NONE)

item_ring_of_aquila_custom = class({})

function item_ring_of_aquila_custom:GetIntrinsicModifierName()
    return "modifier_item_ring_of_aquila_custom"
end

modifier_item_ring_of_aquila_custom= class({})
function modifier_item_ring_of_aquila_custom:IsHidden() return true end
function modifier_item_ring_of_aquila_custom:IsPurgable() return false end
function modifier_item_ring_of_aquila_custom:IsPermanent() return true end
function modifier_item_ring_of_aquila_custom:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end
function modifier_item_ring_of_aquila_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS, 
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
        MODIFIER_PROPERTY_HEALTH_BONUS,
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    }
    return funcs
end
function modifier_item_ring_of_aquila_custom:OnCreated()
    local ability = self:GetAbility()
    self.bonus_attack_speed = ability:GetSpecialValueFor("bonus_attack_speed")
    self.bonus_armor = ability:GetSpecialValueFor("bonus_armor")
    self.bonus_mana_regen = ability:GetSpecialValueFor("bonus_mana_regen")
    self.bonus_strength = ability:GetSpecialValueFor("bonus_strength")
    self.bonus_agility = ability:GetSpecialValueFor("bonus_agility")
    self.bonus_intellect = ability:GetSpecialValueFor("bonus_intellect")
    self.bonus_health_regen = ability:GetSpecialValueFor("bonus_health_regen")
    self.bonus_health = ability:GetSpecialValueFor("bonus_health")
end

function modifier_item_ring_of_aquila_custom:GetModifierAttackSpeedBonus_Constant()
    return self.bonus_attack_speed
end

function modifier_item_ring_of_aquila_custom:GetModifierPhysicalArmorBonus()
    return self.bonus_armor
end

function modifier_item_ring_of_aquila_custom:GetModifierConstantManaRegen()
    return self.bonus_mana_regen
end

function modifier_item_ring_of_aquila_custom:GetModifierBonusStats_Strength()
    return self.bonus_strength
end

function modifier_item_ring_of_aquila_custom:GetModifierBonusStats_Agility()
    return self.bonus_agility
end

function modifier_item_ring_of_aquila_custom:GetModifierBonusStats_Intellect()
    return self.bonus_intellect
end

function modifier_item_ring_of_aquila_custom:GetModifierConstantHealthRegen()
    return self.bonus_health_regen
end

function modifier_item_ring_of_aquila_custom:GetModifierHealthBonus()
    return self.bonus_health
end

item_power_treads_2 = class({})
item_power_treads_3 = item_power_treads_2
item_power_treads_4 = item_power_treads_2
item_power_treads_5 = item_power_treads_2
item_power_treads_6 = item_power_treads_2

function item_power_treads_2:OnSpellStart()
    local caster = self:GetCaster()
    local modifier = caster:FindModifierByName(self:GetIntrinsicModifierName())

    if not modifier then return end

    modifier:SetStackCount((modifier:GetStackCount() + 1)%3)
end

function item_power_treads_2:GetAbilityTextureName()
    local iconItem = {
        strength = "item_power_treads",
        agility = "item_ring_of_aquila",
        intellect = "item_pipe"
    }
    return iconItem[self.activeStat] or "item_power_treads"
 end

function item_power_treads_2:GetIntrinsicModifierName()
    return "modifier_item_power_treads_2"
end

modifier_item_power_treads_2 = class({})
function modifier_item_power_treads_2:IsHidden() return true end
function modifier_item_power_treads_2:IsPurgable() return false end
function modifier_item_power_treads_2:IsPermanent() return true end
function modifier_item_power_treads_2:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end
function modifier_item_power_treads_2:OnStackCountChanged(oldCount)
    local stackCount = self:GetStackCount()
    local ability = self:GetAbility()

    local stats = {
        [0] = "strength",
        [1] = "agility",
        [2] = "intellect"
    }

    self.activeStat = stats[stackCount] or "strength"
    ability.activeStat = stats[stackCount] or "strength"

    if IsServer() then
        self:GetParent():CalculateStatBonus(true)
    end
end

function modifier_item_power_treads_2:OnCreated()
    local ability = self:GetAbility()
    self.bonus_active_stat = ability:GetSpecialValueFor("bonus_active_stat")
    self.bonus_all_stats = ability:GetSpecialValueFor("bonus_all_stats")
    self.bonus_movement_speed = ability:GetSpecialValueFor("bonus_movement_speed")
    self.bonus_health_regen = ability:GetSpecialValueFor("bonus_health_regen")
    self.bonus_health = ability:GetSpecialValueFor("bonus_health")
    self.bonus_mana_regen = ability:GetSpecialValueFor("bonus_mana_regen")
    self.bonus_attack_speed = ability:GetSpecialValueFor("bonus_attack_speed")
    self.bonus_armor = ability:GetSpecialValueFor("bonus_armor")
end

function modifier_item_power_treads_2:OnRefresh()
    self:OnCreated()
end

function modifier_item_power_treads_2:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_UNIQUE,
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
        MODIFIER_PROPERTY_HEALTH_BONUS,
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
    }
    return funcs
end

function modifier_item_power_treads_2:GetModifierMoveSpeedBonus_Special_Boots()
    return self.bonus_movement_speed
end

function modifier_item_power_treads_2:GetModifierConstantHealthRegen()
    return self.bonus_health_regen
end

function modifier_item_power_treads_2:GetModifierHealthBonus()
    return self.bonus_health
end

function modifier_item_power_treads_2:GetModifierConstantManaRegen()
    return self.bonus_mana_regen
end

function modifier_item_power_treads_2:GetModifierAttackSpeedBonus_Constant()
    return self.bonus_attack_speed
end

function modifier_item_power_treads_2:GetModifierPhysicalArmorBonus()
    return self.bonus_armor
end


function modifier_item_power_treads_2:GetModifierBonusStats_Strength()
    return (self.activeStat == "strength" and self.bonus_active_stat or  0) + self.bonus_all_stats
end

function modifier_item_power_treads_2:GetModifierBonusStats_Agility()
    return (self.activeStat == "agility" and self.bonus_active_stat or  0) + self.bonus_all_stats
end

function modifier_item_power_treads_2:GetModifierBonusStats_Intellect()
    return (self.activeStat == "intellect" and self.bonus_active_stat or  0) + self.bonus_all_stats
end
