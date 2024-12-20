LinkLuaModifier("modifier_item_satanic_custom", "items/item_satanic_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_satanic_custom_buff", "items/item_satanic_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_satanic_custom_active", "items/item_satanic_custom", LUA_MODIFIER_MOTION_NONE)

item_satanic_1 = class({})

function item_satanic_1:GetIntrinsicModifierName()
    return "modifier_item_satanic_custom"
end

function item_satanic_1:OnSpellStart()
    local caster = self:GetCaster()
    local duration = self:GetSpecialValueFor("duration")

    caster:AddNewModifier(caster, self, "modifier_item_satanic_custom_active", {duration = duration})
    caster:Purge(false, true, false, false, false)
    EmitSoundOn("DOTA_Item.Satanic.Activate", caster)
end

modifier_item_satanic_custom = class({})

function modifier_item_satanic_custom:IsHidden()
    return true
end

function modifier_item_satanic_custom:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_satanic_custom:IsAura()					return true end
function modifier_item_satanic_custom:IsAuraActiveOnDeath() 		return false end

function modifier_item_satanic_custom:GetAuraRadius()				 return self:GetAbility():GetSpecialValueFor("aura_radius") end
function modifier_item_satanic_custom:GetAuraSearchFlags()		return DOTA_UNIT_TARGET_FLAG_INVULNERABLE end
function modifier_item_satanic_custom:GetAuraSearchTeam()			return DOTA_UNIT_TARGET_TEAM_FRIENDLY end
function modifier_item_satanic_custom:GetAuraSearchType()			return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC end
function modifier_item_satanic_custom:GetModifierAura()				return "modifier_item_satanic_custom_buff" end

function modifier_item_satanic_custom:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
    }
end

function modifier_item_satanic_custom:GetModifierConstantManaRegen()
    return self:GetAbility():GetSpecialValueFor("bonus_mana_regen")
end

function modifier_item_satanic_custom:GetModifierPhysicalArmorBonus()
    return self:GetAbility():GetSpecialValueFor("bonus_armor")
end
 
function modifier_item_satanic_custom:GetModifierBonusStats_Strength()
    return self:GetAbility():GetSpecialValueFor("bonus_strength")
end

function modifier_item_satanic_custom:GetModifierPreAttack_BonusDamage()
    return self:GetAbility():GetSpecialValueFor("bonus_damage")
end


modifier_item_satanic_custom_active = class({})

function modifier_item_satanic_custom_active:IsHidden()
    return false
end

function modifier_item_satanic_custom_active:GetEffectName()
    return "particles/items2_fx/satanic_buff.vpcf"
end

function modifier_item_satanic_custom_active:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_TOOLTIP
    }
end

function modifier_item_satanic_custom_active:OnTooltip()
    return self:GetAbility():GetSpecialValueFor("lifesteal_percent_activate")
end

modifier_item_satanic_custom_buff = class({})

function modifier_item_satanic_custom_buff:IsHidden()
    return false
end

function modifier_item_satanic_custom_buff:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK_LANDED,
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
        MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE,

    }
end

function modifier_item_satanic_custom_buff:GetModifierBaseDamageOutgoing_Percentage()
    return self:GetAbility():GetSpecialValueFor("aura_damage_percent")
end

function modifier_item_satanic_custom_buff:GetModifierConstantManaRegen()
    return self:GetAbility():GetSpecialValueFor("aura_mana_regen")
end

function modifier_item_satanic_custom_buff:GetModifierPhysicalArmorBonus()
    return self:GetAbility():GetSpecialValueFor("aura_armor")
end

function modifier_item_satanic_custom_buff:OnAttackLanded(params)
    if not IsServer() then return end
    
    local parent = self:GetParent()
    if params.attacker == parent and not params.target:IsBuilding() then
        local ability = self:GetAbility()
        local lifesteal_pct = parent:HasModifier("modifier_item_satanic_custom_active") and 
            ability:GetSpecialValueFor("lifesteal_percent_activate") or 
            ability:GetSpecialValueFor("lifesteal_percent")
            
        local lifesteal = (params.damage * lifesteal_pct) / 100
        parent:Heal(lifesteal, ability)

        local particle = ParticleManager:CreateParticle("particles/generic_gameplay/generic_lifesteal.vpcf", PATTACH_ABSORIGIN_FOLLOW, params.attacker)
        ParticleManager:ReleaseParticleIndex(particle)
    end
end

