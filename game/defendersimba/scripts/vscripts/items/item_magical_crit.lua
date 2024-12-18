LinkLuaModifier("modifier_item_magical_crit_custom", "items/item_magical_crit", LUA_MODIFIER_MOTION_NONE)

item_magical_crit_1 = class({})

function item_magical_crit_1:GetIntrinsicModifierName()
    return "modifier_item_magical_crit_custom"
end

modifier_item_magical_crit_custom = class({})

function modifier_item_magical_crit_custom:IsHidden()
    return true
end

function modifier_item_magical_crit_custom:OnCreated()
    self.critChance = self:GetAbility():GetSpecialValueFor("crit_chance")
    self.critMultiplier = self:GetAbility():GetSpecialValueFor("crit_multiplier")
end

function modifier_item_magical_crit_custom:OnRefresh()
    self:OnCreated()
end

function modifier_item_magical_crit_custom:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_magical_crit_custom:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE ,
    }
end

function modifier_item_magical_crit_custom:GetModifierTotalDamageOutgoing_Percentage(event)
    local parent = self:GetParent()
    local attacker = event.attacker
  
    if (
    attacker == self:GetParent() and
    event.damage_category == DOTA_DAMAGE_CATEGORY_SPELL  and
    bit.band(event.damage_flags, DOTA_DAMAGE_FLAG_REFLECTION) ~= DOTA_DAMAGE_FLAG_REFLECTION and 
    RollPercentage(self.critChance)
    ) then 

        local damage = event.original_damage * (self.critMultiplier / 100)
        local particle = ParticleManager:CreateParticle("particles/msg_fx/msg_crit.vpcf", PATTACH_OVERHEAD_FOLLOW, event.target)
        ParticleManager:SetParticleControl(particle, 1, Vector(9,damage,4))
		ParticleManager:SetParticleControl(particle, 2, Vector(1, 4, 0))
        ParticleManager:SetParticleControl(particle, 3, Vector(19,26,600))
        ParticleManager:ReleaseParticleIndex(particle)

        return self.critMultiplier - 100
    end
end