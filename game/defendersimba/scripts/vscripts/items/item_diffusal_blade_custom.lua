LinkLuaModifier("modifier_item_diffusal_blade_passive_custom", "items/item_diffusal_blade_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_diffusal_blade_self_active_custom", "items/item_diffusal_blade_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_diffusal_blade_enemy_active_custom", "items/item_diffusal_blade_custom", LUA_MODIFIER_MOTION_NONE)

item_diffusal_blade_1 = class({})

item_diffusal_blade_3 = class({})
 
function item_diffusal_blade_1:OnSpellStart()
    local target = self:GetCursorTarget()
    local duration = self:GetSpecialValueFor("duration")
    local team = self:GetCaster():GetTeamNumber()

    EmitSoundOn("DOTA_Item.DiffusalBlade.Target", target)

    target:AddNewModifier(self:GetCaster(), self, "modifier_item_diffusal_blade_enemy_active_custom", {duration = duration})
end

function item_diffusal_blade_1:GetIntrinsicModifierName()
    return "modifier_item_diffusal_blade_passive_custom"
end

 
function item_diffusal_blade_3:OnSpellStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()
    local duration = self:GetSpecialValueFor("duration")
    local team = self:GetCaster():GetTeamNumber()

    EmitSoundOn("DOTA_Item.DiffusalBlade.Target", caster)

    caster:Purge(false, true, false, false, false)
    caster:AddNewModifier(caster, self, "modifier_item_diffusal_blade_self_active_custom", {duration = duration})
    if target == caster then return end

    if target:GetTeamNumber() == caster:GetTeamNumber() then 
        target:Purge(false, true, false, false, false)
        target:AddNewModifier(caster, self, "modifier_item_diffusal_blade_self_active_custom", {duration = duration})
    else 
        target:Purge(true, false, false, false, false)
        target:AddNewModifier(self:GetCaster(), self, "modifier_item_diffusal_blade_enemy_active_custom", {duration = duration})
    end
end

function item_diffusal_blade_3:GetIntrinsicModifierName()
    return "modifier_item_diffusal_blade_passive_custom"
end


modifier_item_diffusal_blade_passive_custom = class({})

function modifier_item_diffusal_blade_passive_custom:IsHidden()
    return true
end

function modifier_item_diffusal_blade_passive_custom:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_PHYSICAL,
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS
    }
end

function modifier_item_diffusal_blade_passive_custom:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_diffusal_blade_passive_custom:OnCreated()
    self.bonus_agility = self:GetAbility():GetSpecialValueFor("bonus_agility")
    self.bonus_intellect = self:GetAbility():GetSpecialValueFor("bonus_intellect")
end

function modifier_item_diffusal_blade_passive_custom:OnRefresh()
    self:OnCreated()
end

function modifier_item_diffusal_blade_passive_custom:GetModifierBonusStats_Agility()
    return self.bonus_agility
end

function modifier_item_diffusal_blade_passive_custom:GetModifierBonusStats_Intellect()
    return self.bonus_intellect
end

function modifier_item_diffusal_blade_passive_custom:GetModifierProcAttack_BonusDamage_Physical(params)
    local attacker = params.attacker
    local target = params.target
    
    if not attacker or not target then return 0 end

    if attacker == self:GetParent() then
        local mana_break = self:GetAbility():GetSpecialValueFor("mana_break")
        local illusion_mana_break = self:GetAbility():GetSpecialValueFor("illusion_mana_break")
        
        if target:GetMana() > 0 then
            local actualManaBreak = math.min(target:GetMana(), attacker:IsIllusion() and illusion_mana_break or mana_break)
            target:Script_ReduceMana(actualManaBreak, self:GetAbility())

            local particle = ParticleManager:CreateParticle("particles/generic_gameplay/generic_manaburn.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
            ParticleManager:ReleaseParticleIndex(particle)

            return actualManaBreak
        end
    end

    return 0
end

modifier_item_diffusal_blade_self_active_custom = class({})

function modifier_item_diffusal_blade_self_active_custom:IsHidden()
    return false
end

function modifier_item_diffusal_blade_self_active_custom:IsDebuff()
    return false
end

function modifier_item_diffusal_blade_self_active_custom:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
    }
end

function modifier_item_diffusal_blade_self_active_custom:OnCreated()
    if IsServer() then
        self.particle_fx = ParticleManager:CreateParticle("particles/items_fx/disperser_buff.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
    end
end

function modifier_item_diffusal_blade_self_active_custom:OnDestroy()
    if IsServer() and self.particle_fx then
        ParticleManager:DestroyParticle(self.particle_fx, false)
        ParticleManager:ReleaseParticleIndex(self.particle_fx)
    end
end

function modifier_item_diffusal_blade_self_active_custom:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("bonus_movement_speed")
end

modifier_item_diffusal_blade_enemy_active_custom = class({})

function modifier_item_diffusal_blade_enemy_active_custom:IsHidden()
    return false
end

function modifier_item_diffusal_blade_enemy_active_custom:IsDebuff()
    return true
end

function modifier_item_diffusal_blade_enemy_active_custom:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
    }
end

function modifier_item_diffusal_blade_enemy_active_custom:OnCreated()
    if IsServer() then
        self.particle_fx = ParticleManager:CreateParticle("particles/items_fx/diffusal_slow.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
    end
end

function modifier_item_diffusal_blade_enemy_active_custom:OnDestroy()
    if IsServer() and self.particle_fx then
        ParticleManager:DestroyParticle(self.particle_fx, false)
        ParticleManager:ReleaseParticleIndex(self.particle_fx)
    end
end

function modifier_item_diffusal_blade_enemy_active_custom:GetModifierMoveSpeedBonus_Percentage()
    return -self:GetAbility():GetSpecialValueFor("decrease_movement_speed")
end
