LinkLuaModifier("modifier_item_diffusal_blade_passive_custom", "items/item_diffusal_blade_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_diffusal_blade_active_custom", "items/item_diffusal_blade_custom", LUA_MODIFIER_MOTION_NONE)

item_diffusal_blade_cus_1 = item_diffusal_blade_cus_1 or class({})
item_diffusal_blade_cus_2 = item_diffusal_blade_cus_1
item_diffusal_blade_cus_3 = item_diffusal_blade_cus_3 or class({})
item_diffusal_blade_cus_4 = item_diffusal_blade_cus_3
item_diffusal_blade_cus_5 = item_diffusal_blade_cus_3
item_diffusal_blade_cus_6 = item_diffusal_blade_cus_3

function item_diffusal_blade_cus_1:OnSpellStart()
    local target = self:GetCursorTarget()
    local duration = self:GetSpecialValueFor("duration")

    EmitSoundOn("DOTA_Item.DiffusalBlade.Target", target)

	target:AddNewModifier(self:GetCaster(), self, "modifier_diffusal_blade_active_custom", {duration = duration * (1 - target:GetStatusResistance())})
end

function item_diffusal_blade_cus_1:GetIntrinsicModifierName()
    return "modifier_item_diffusal_blade_passive_custom"
end


function item_diffusal_blade_cus_3:OnSpellStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()
    local duration = self:GetSpecialValueFor("duration")

    EmitSoundOn("DOTA_Item.DiffusalBlade.Target", caster)

    caster:Purge(false, true, false, false, false)
    caster:AddNewModifier(caster, self, "modifier_diffusal_blade_active_custom", {duration = duration})
    if target == caster then return end

    if target:GetTeamNumber() == caster:GetTeamNumber() then
        target:Purge(false, true, false, false, false)
    else
        target:Purge(true, false, false, false, false)
        duration = duration * (1 - target:GetStatusResistance())
    end
	target:AddNewModifier(caster, self, "modifier_diffusal_blade_active_custom", {duration = duration})
end

function item_diffusal_blade_cus_3:GetIntrinsicModifierName()
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


modifier_diffusal_blade_active_custom = class({})
function modifier_diffusal_blade_active_custom:IsHidden() return false end
function modifier_diffusal_blade_active_custom:GetEffectName() return "particles/items_fx/disperser_buff.vpcf" end
function modifier_diffusal_blade_active_custom:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end
function modifier_diffusal_blade_active_custom:OnCreated() self:OnRefresh() end
function modifier_diffusal_blade_active_custom:OnRefresh()
	local ms_bonus = self:GetAbility():GetSpecialValueFor("bonus_movement_speed")
	local ms_reduc = self:GetAbility():GetSpecialValueFor("decrease_movement_speed")
	self.bonus_movement_speed = (self:GetParent():GetTeamNumber() == self:GetCaster():GetTeamNumber()) and ms_bonus or (ms_reduc * (-1))
end
function modifier_diffusal_blade_active_custom:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
    }
end
function modifier_diffusal_blade_active_custom:GetModifierMoveSpeedBonus_Percentage() return self.bonus_movement_speed end
