LinkLuaModifier("modifier_item_mage_slayer_custom", "items/item_sheepstick_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_mage_slayer_custom_debuff", "items/item_sheepstick_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_sheepstick_custom", "items/item_sheepstick_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_sheepstick_custom_hex", "items/item_sheepstick_custom", LUA_MODIFIER_MOTION_NONE)
 
item_mage_slayer_1 = class({})

function item_mage_slayer_1:GetIntrinsicModifierName()
    return "modifier_item_mage_slayer_custom"
end

modifier_item_mage_slayer_custom = class({})

function modifier_item_mage_slayer_custom:IsHidden()
    return true
end

function modifier_item_mage_slayer_custom:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_mage_slayer_custom:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
end

function modifier_item_mage_slayer_custom:OnCreated()
    self.bonus_magical_armor = self:GetAbility():GetSpecialValueFor("bonus_magical_armor")
    self.bonus_attack_speed = self:GetAbility():GetSpecialValueFor("bonus_attack_speed") 
    self.bonus_intellect = self:GetAbility():GetSpecialValueFor("bonus_intellect")
    self.bonus_mana_regen = self:GetAbility():GetSpecialValueFor("bonus_mana_regen")
end

function modifier_item_mage_slayer_custom:OnRefresh()
    self:OnCreated()
end

function modifier_item_mage_slayer_custom:GetModifierMagicalResistanceBonus()
    return self.bonus_magical_armor
end

function modifier_item_mage_slayer_custom:GetModifierAttackSpeedBonus_Constant()
    return self.bonus_attack_speed
end

function modifier_item_mage_slayer_custom:GetModifierBonusStats_Intellect()
    return self.bonus_intellect
end

function modifier_item_mage_slayer_custom:GetModifierConstantManaRegen()
    return self.bonus_mana_regen
end

function modifier_item_mage_slayer_custom:OnAttackLanded(keys)
    if keys.attacker == self:GetParent() and not keys.target:IsMagicImmune() then
        local duration = self:GetAbility():GetSpecialValueFor("duration")
        keys.target:AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_item_mage_slayer_custom_debuff", {duration = duration})
    end
end

modifier_item_mage_slayer_custom_debuff = class({})

function modifier_item_mage_slayer_custom_debuff:IsDebuff()
    return true
end

function modifier_item_mage_slayer_custom_debuff:GetEffectName()
    return "particles/items3_fx/mage_slayer_debuff.vpcf"
end

function modifier_item_mage_slayer_custom_debuff:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW
end

function modifier_item_mage_slayer_custom_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT
    }
end

function modifier_item_mage_slayer_custom_debuff:OnCreated()
    self.spell_amp_debuff = -self:GetAbility():GetSpecialValueFor("spell_amp_debuff")
    self.dps = self:GetAbility():GetSpecialValueFor("dps")
    self:StartIntervalThink(1)
end

function modifier_item_mage_slayer_custom_debuff:OnRefresh()
    self:OnCreated()
end

function modifier_item_mage_slayer_custom_debuff:OnIntervalThink()
    if IsClient() then return end 
    
    ApplyDamage({
        victim = self:GetParent(),
        attacker = self:GetCaster(), 
        damage = self.dps,
        damage_type = self:GetAbility():GetAbilityDamageType(),
        ability = self:GetAbility()
    })
end

function modifier_item_mage_slayer_custom_debuff:GetModifierSpellAmplify_Percentage()
    return self.spell_amp_debuff
end


item_sheepstick_1 = class({})

function item_sheepstick_1:GetIntrinsicModifierName()
    return "modifier_item_sheepstick_custom"
end

function item_sheepstick_1:OnSpellStart()
    local target = self:GetCursorTarget()
    local duration = self:GetSpecialValueFor("sheep_duration")
    local movement_speed = self:GetSpecialValueFor("sheep_movement_speed")
    local radius = self:GetSpecialValueFor("upgrade_radius")
    
    if target:TriggerSpellAbsorb(self) then return end
    
    local particle = ParticleManager:CreateParticle("particles/items_fx/item_sheepstick.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
    ParticleManager:ReleaseParticleIndex(particle)
    target:AddNewModifier(self:GetCaster(), self, "modifier_item_sheepstick_custom_hex", {duration = duration})
    target:EmitSound("DOTA_Item.Sheepstick.Activate")
end

modifier_item_sheepstick_custom = class({})

function modifier_item_sheepstick_custom:IsHidden() return true end
function modifier_item_sheepstick_custom:IsPurgable() return false end

function modifier_item_sheepstick_custom:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_sheepstick_custom:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_EVENT_ON_ATTACK_LANDED,
    }
end

function modifier_item_sheepstick_custom:OnCreated()
    self.bonus_magical_armor = self:GetAbility():GetSpecialValueFor("bonus_magical_armor")
    self.bonus_attack_speed = self:GetAbility():GetSpecialValueFor("bonus_attack_speed") 

    self.bonus_mana_regen = self:GetAbility():GetSpecialValueFor("bonus_mana_regen")
    self.bonus_intellect = self:GetAbility():GetSpecialValueFor("bonus_intellect")
end

function modifier_item_sheepstick_custom:OnRefresh()
    self:OnCreated()
end

function modifier_item_sheepstick_custom:OnAttackLanded(keys)
    if keys.attacker == self:GetParent() and not keys.target:IsMagicImmune() then
        local duration = self:GetAbility():GetSpecialValueFor("duration")
        keys.target:AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_item_mage_slayer_custom_debuff", {duration = duration})
    end
end

function modifier_item_sheepstick_custom:GetModifierConstantManaRegen()
    return self.bonus_mana_regen
end

function modifier_item_sheepstick_custom:GetModifierBonusStats_Intellect()
    return self.bonus_intellect
end

function modifier_item_mage_slayer_custom:GetModifierMagicalResistanceBonus()
    return self.bonus_magical_armor
end

function modifier_item_mage_slayer_custom:GetModifierAttackSpeedBonus_Constant()
    return self.bonus_attack_speed
end

modifier_item_sheepstick_custom_hex = class({})

function modifier_item_sheepstick_custom_hex:IsPurgable() return false end
function modifier_item_sheepstick_custom_hex:IsPurgeException() return true end
function modifier_item_sheepstick_custom_hex:IsDebuff() return true end
 

function modifier_item_sheepstick_custom_hex:CheckState()
    return {
        [MODIFIER_STATE_HEXED] = true,
        [MODIFIER_STATE_DISARMED] = true,
        [MODIFIER_STATE_SILENCED] = true,
        [MODIFIER_STATE_MUTED] = true
    }
end

function modifier_item_sheepstick_custom_hex:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MODEL_CHANGE,
        MODIFIER_PROPERTY_MOVESPEED_BASE_OVERRIDE
    }
end

function modifier_item_sheepstick_custom_hex:GetModifierModelChange()
    return "models/props_gameplay/pig.vmdl"
end

function modifier_item_sheepstick_custom_hex:GetModifierMoveSpeedOverride()
    return self:GetAbility():GetSpecialValueFor("sheep_movement_speed")
end
