LinkLuaModifier("modifier_item_orchid_custom_passive", "items/item_orchid_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_bloodthorn_custom_passive", "items/item_orchid_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_bloodthorn_custom_debuff", "items/item_orchid_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_orchid_custom_debuff", "items/item_orchid_custom.lua", LUA_MODIFIER_MOTION_NONE)

item_orchid_1 = class({})
item_orchid_2 = item_orchid_1
item_orchid_3 = class({})
item_orchid_4 = item_orchid_3
item_orchid_5 = item_orchid_3
item_orchid_6 = item_orchid_3

function item_orchid_1:GetIntrinsicModifierName()
    return "modifier_item_orchid_custom_passive"
end

function item_orchid_1:OnSpellStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()
    local duration = self:GetSpecialValueFor("silence_duration")
    
    target:EmitSound("DOTA_Item.Orchid.Activate")
    target:AddNewModifier(caster, self, "modifier_item_orchid_custom_debuff", {duration = duration * (1 - target:GetStatusResistance())})
end


modifier_item_orchid_custom_passive = class({})

function modifier_item_orchid_custom_passive:IsHidden() return true end
function modifier_item_orchid_custom_passive:IsPurgable() return false end
function modifier_item_orchid_custom_passive:IsPermanent() return true end

function modifier_item_orchid_custom_passive:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS
    }
end

function modifier_item_orchid_custom_passive:OnCreated()
    self.bonus_attack_speed = self:GetAbility():GetSpecialValueFor("bonus_attack_speed")
    self.bonus_damage = self:GetAbility():GetSpecialValueFor("bonus_damage") 
    self.bonus_health_regen = self:GetAbility():GetSpecialValueFor("bonus_health_regen")
    self.bonus_mana_regen = self:GetAbility():GetSpecialValueFor("bonus_mana_regen")
    self.bonus_intellect = self:GetAbility():GetSpecialValueFor("bonus_intellect")
end

function modifier_item_orchid_custom_passive:OnRefresh()
    self:OnCreated()
end

function modifier_item_orchid_custom_passive:GetModifierAttackSpeedBonus_Constant()
    return self.bonus_attack_speed
end

function modifier_item_orchid_custom_passive:GetModifierPreAttack_BonusDamage()
    return self.bonus_damage
end

function modifier_item_orchid_custom_passive:GetModifierConstantHealthRegen()
    return self.bonus_health_regen
end

function modifier_item_orchid_custom_passive:GetModifierConstantManaRegen()
    return self.bonus_mana_regen
end

function modifier_item_orchid_custom_passive:GetModifierBonusStats_Intellect()
    return self.bonus_intellect
end

modifier_item_orchid_custom_debuff = class({})

function modifier_item_orchid_custom_debuff:IsDebuff() return true end
function modifier_item_orchid_custom_debuff:IsPurgable() return true end

function modifier_item_orchid_custom_debuff:GetEffectName()
	return "particles/econ/items/silencer/silencer_ti6/silencer_last_word_ti6_silence.vpcf"
end


function modifier_item_orchid_custom_debuff:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW 
end


function modifier_item_orchid_custom_debuff:CheckState()
	local states = { [MODIFIER_STATE_SILENCED] = true }
	return states
end

function modifier_item_orchid_custom_debuff:OnCreated()
    if IsServer() then
        self.damage_percent = self:GetAbility():GetSpecialValueFor("silence_damage_percent")
        self.total_damage = 0

        local particle = ParticleManager:CreateParticle("particles/items2_fx/orchid.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
        self:AddParticle(particle, false, false, -1, false, false)
    end
end

function modifier_item_orchid_custom_debuff:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_TAKEDAMAGE
    }
end

function modifier_item_orchid_custom_debuff:OnTakeDamage(params)
    if IsServer() then
        if params.unit == self:GetParent() then
            self.total_damage = self.total_damage + params.original_damage
        end
    end
end

function modifier_item_orchid_custom_debuff:DestroyOnExpire()
    if IsServer() then
        local damage = self.total_damage * self.damage_percent / 100
        ApplyDamage({
            victim = self:GetParent(),
            attacker = self:GetCaster(),
            damage = damage,
            damage_type = DAMAGE_TYPE_MAGICAL,
            ability = self:GetAbility()
        })
    end
end



item_bloodthorn_1 = class({})
function item_bloodthorn_1:GetIntrinsicModifierName() return "modifier_item_bloodthorn_custom_passive" end
function item_orchid_3:OnSpellStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()
    local duration = self:GetSpecialValueFor("silence_duration")
    
    target:EmitSound("DOTA_Item.Bloodthorn.Activate")
    target:AddNewModifier(caster, self, "modifier_item_bloodthorn_custom_debuff", {duration = duration * (1 - target:GetStatusResistance())})
end


modifier_item_bloodthorn_custom_passive = class({})
function modifier_item_bloodthorn_custom_passive:IsHidden() return true end
function modifier_item_bloodthorn_custom_passive:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_MAGICAL,
		MODIFIER_EVENT_ON_ATTACK_RECORD
	}
end

function modifier_item_bloodthorn_custom_passive:OnCreated()
    self.bonus_attack_speed = self:GetAbility():GetSpecialValueFor("bonus_attack_speed")
    self.bonus_damage = self:GetAbility():GetSpecialValueFor("bonus_damage") 
    self.bonus_health_regen = self:GetAbility():GetSpecialValueFor("bonus_health_regen")
    self.bonus_mana_regen = self:GetAbility():GetSpecialValueFor("bonus_mana_regen")
    self.bonus_intellect = self:GetAbility():GetSpecialValueFor("bonus_intellect")

	self.bonus_chance = self:GetAbility():GetSpecialValueFor("bonus_chance")
	self.bonus_chance_damage = self:GetAbility():GetSpecialValueFor("bonus_chance_damage")
    self.parent = self:GetParent()
	self.pierce_proc = false
	self.pierce_records = {}
end

function modifier_item_bloodthorn_custom_passive:OnRefresh()
    self:OnCreated()
end

-- function modifier_item_bloodthorn_custom_passive:GetModifierProcAttack_BonusDamage_Magical(keys)
--     print("1234")
--     if self.pierce_proc and not self:GetParent():IsIllusion() and not keys.target:IsBuilding() then
--         SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, keys.target, self.bonus_chance_damage, nil)
--         self:GetParent():EmitSound("DOTA_Item.MKB.proc")
--         self.pierce_proc = false
--         return self.bonus_chance_damage
--     end
--  end

function modifier_item_bloodthorn_custom_passive:GetModifierProcAttack_BonusDamage_Magical(keys)
	for _, record in pairs(self.pierce_records) do
		if record == keys.record then
			table.remove(self.pierce_records, _)

			if not self.parent:IsIllusion() and not keys.target:IsBuilding() then
				SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, keys.target, self.bonus_chance_damage, nil)
				
				return self.bonus_chance_damage
			end
		end
	end
end

function modifier_item_bloodthorn_custom_passive:OnAttackRecord(keys)
	if keys.attacker == self.parent then
		if self.pierce_proc then
			table.insert(self.pierce_records, keys.record)
			self.pierce_proc = false
		end

        if RollPercentage(self.bonus_chance) then
			self.pierce_proc = true
		end
	end
end

function modifier_item_bloodthorn_custom_passive:CheckState()
	local state = {}

    if self.pierce_proc then
		state = {[MODIFIER_STATE_CANNOT_MISS] = true}
	end

	return state
end

function modifier_item_bloodthorn_custom_passive:GetModifierAttackSpeedBonus_Constant()
    return self.bonus_attack_speed
end

function modifier_item_bloodthorn_custom_passive:GetModifierPreAttack_BonusDamage()
    return self.bonus_damage
end

function modifier_item_bloodthorn_custom_passive:GetModifierConstantHealthRegen()
    return self.bonus_health_regen
end

function modifier_item_bloodthorn_custom_passive:GetModifierConstantManaRegen()
    return self.bonus_mana_regen
end

function modifier_item_bloodthorn_custom_passive:GetModifierBonusStats_Intellect()
    return self.bonus_intellect
end

modifier_item_bloodthorn_custom_debuff = class({})

function modifier_item_bloodthorn_custom_debuff:IsDebuff() return true end
function modifier_item_bloodthorn_custom_debuff:IsPurgable() return true end

function modifier_item_bloodthorn_custom_debuff:GetEffectName()
	return "particles/econ/items/silencer/silencer_ti6/silencer_last_word_ti6_silence.vpcf"
end


function modifier_item_bloodthorn_custom_debuff:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW 
end


function modifier_item_bloodthorn_custom_debuff:CheckState()
	local states = { [MODIFIER_STATE_SILENCED] = true, 	[MODIFIER_STATE_EVADE_DISABLED] = true}
	return states
end

function modifier_item_bloodthorn_custom_debuff:OnCreated()
    if IsServer() then
        self.damage_percent = self:GetAbility():GetSpecialValueFor("silence_damage_percent")
        self.debuff_damage_hero = self:GetAbility():GetSpecialValueFor("debuff_damage_hero")
        self.debuff_damage_other = self:GetAbility():GetSpecialValueFor("debuff_damage_other")
         
        self.total_damage = 0

        local particle = ParticleManager:CreateParticle("particles/items2_fx/orchid.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
        self:AddParticle(particle, false, false, -1, false, false)
    end
end

function modifier_item_bloodthorn_custom_debuff:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_TAKEDAMAGE,
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
end

function modifier_item_bloodthorn_custom_debuff:OnAttackLanded(params)
    local parent = self:GetParent()
    if params.target ~= parent then return end

    local damage = 0
    if params.attacker:IsHero() then
        damage = self.debuff_damage_hero
    else
        damage = self.debuff_damage_other
    end
    
    ApplyDamage({
        victim = parent,
        attacker = params.attacker, 
        damage = damage,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self:GetAbility()
    })

    parent:EmitSound("DOTA_Item.MKB.mele")
    SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, parent, damage, nil)
end

function modifier_item_bloodthorn_custom_debuff:OnTakeDamage(params)
    if IsServer() then
        if params.unit == self:GetParent() then
            self.total_damage = self.total_damage + params.original_damage
        end
    end
end

function modifier_item_bloodthorn_custom_debuff:DestroyOnExpire()
    if IsServer() then
        local damage = self.total_damage * self.damage_percent / 100
        ApplyDamage({
            victim = self:GetParent(),
            attacker = self:GetCaster(),
            damage = damage,
            damage_type = DAMAGE_TYPE_MAGICAL,
            ability = self:GetAbility()
        })
    end
end
