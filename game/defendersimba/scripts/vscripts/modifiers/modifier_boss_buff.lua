modifier_boss_buff = class({})

function modifier_boss_buff:IsHidden()
    return false
end

function modifier_boss_buff:IsPurgable()
    return false
end

function modifier_boss_buff:IsPurgeException()
    return false
end

function modifier_boss_buff:RemoveOnDeath()
    return false
end

function modifier_boss_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, 
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
        MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
        MODIFIER_PROPERTY_MODEL_SCALE,
        MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE_STACKING, 
    }
end

function modifier_boss_buff:OnCreated()
    local parent = self:GetParent()
    self.parent = parent
    self.multiplier = 4

    if IsServer() then
        self.strengthGain = parent:GetStrengthGain()
        self.agilityGain = parent:GetAgilityGain()
        self.intellectGain = parent:GetIntellectGain()
    end
    self.magicResistance = 55
    self.incomingDamage = -55
    self.statusResistance = 25
    self.cooldownReduction = 50
    self.modelScale = 105
end

function modifier_boss_buff:GetModifierBonusStats_Strength()
    return (self.strengthGain * self.parent:GetLevel()) * (self.multiplier - 1)
end

function modifier_boss_buff:GetModifierBonusStats_Agility()
    return (self.agilityGain * self.parent:GetLevel()) * (self.multiplier - 1)
end

function modifier_boss_buff:GetModifierBonusStats_Intellect()
    return (self.intellectGain * self.parent:GetLevel()) * (self.multiplier - 1)
end

function modifier_boss_buff:GetModifierMagicalResistanceBonus()
    return self.magicResistance
end

function modifier_boss_buff:GetModifierIncomingDamage_Percentage(event)
    local damageType = event.damage_type

 	return self.incomingDamage
 end
 
 function modifier_boss_buff:GetModifierStatusResistanceStacking()
    return self.statusResistance
end

function modifier_boss_buff:GetModifierModelScale()
    return self.modelScale
end

function modifier_boss_buff:GetModifierPercentageCooldownStacking()
    return self.cooldownReduction
end

 