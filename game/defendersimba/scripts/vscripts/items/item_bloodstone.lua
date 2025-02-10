LinkLuaModifier("modifier_item_bloodstone_custom", "items/item_bloodstone", LUA_MODIFIER_MOTION_NONE)

item_bloodstone_1 = class({})
item_bloodstone_2 = item_bloodstone_1
item_bloodstone_3 = item_bloodstone_1
item_bloodstone_4 = item_bloodstone_1
item_bloodstone_5 = item_bloodstone_1
item_bloodstone_6 = item_bloodstone_1

function item_bloodstone_1:GetIntrinsicModifierName()
    return "modifier_item_bloodstone_custom"
end

function item_bloodstone_1:OnSpellStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()
    local damage = self:GetSpecialValueFor("damage")
    local max_targets = self:GetSpecialValueFor("max_targets")
    local radius = self:GetSpecialValueFor("radius")

    target:EmitSound("DOTA_Item.Dagon.Activate")

    local enemies = FindUnitsInRadius(
        caster:GetTeamNumber(), 
        target:GetAbsOrigin(), 
        nil, radius,
        DOTA_UNIT_TARGET_TEAM_ENEMY, 
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 
        0,
        FIND_CLOSEST, 
        false
    )

    local targetCount = 0
 
    local dagonTarget = function(target)
        targetCount = targetCount + 1
        if target:TriggerSpellAbsorb(self) then return end

        local damageTable = {
            victim = target,
            attacker = caster,
            damage = damage,
            damage_type = self:GetAbilityDamageType(),
            ability = self
        }
    
        ApplyDamage(damageTable)
    
        local particle = ParticleManager:CreateParticle("particles/items_fx/dagon.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
        ParticleManager:SetParticleControlEnt(particle, 0, caster, PATTACH_POINT_FOLLOW, "attach_attack1", caster:GetAbsOrigin(), true)
        ParticleManager:SetParticleControlEnt(particle, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
        ParticleManager:ReleaseParticleIndex(particle)
        target:EmitSound("DOTA_Item.Dagon5.Target")
    end

    dagonTarget(target)

    for _, enemy in pairs(enemies) do
        if enemy ~= target then
            if targetCount >= max_targets then break end
            dagonTarget(enemy)
       end
    end
 end

modifier_item_bloodstone_custom = class({})

function modifier_item_bloodstone_custom:IsHidden()
    return true
end
function modifier_item_bloodstone_custom:IsPurgable() return false end
function modifier_item_bloodstone_custom:IsPermanent() return true end

function modifier_item_bloodstone_custom:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_bloodstone_custom:OnCreated()
    local ability = self:GetAbility()
    self.bonus_all_stats = ability:GetSpecialValueFor("bonus_all_stats")
    self.bonus_health = ability:GetSpecialValueFor("bonus_health")
    self.bonus_mana = ability:GetSpecialValueFor("bonus_mana")
    self.bonus_mp_regen = ability:GetSpecialValueFor("bonus_mp_regen")
    self.spell_lifesteal = ability:GetSpecialValueFor("spell_lifesteal")
 end

 function modifier_item_bloodstone_custom:OnRefresh()
    self:OnCreated()
 end

function modifier_item_bloodstone_custom:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_PROPERTY_HEALTH_BONUS,
        MODIFIER_PROPERTY_MANA_BONUS,
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
        MODIFIER_EVENT_ON_TAKEDAMAGE
    }
end

function modifier_item_bloodstone_custom:GetModifierBonusStats_Intellect()
    return self.bonus_all_stats
end

function modifier_item_bloodstone_custom:GetModifierBonusStats_Agility()
    return self.bonus_all_stats
end

function modifier_item_bloodstone_custom:GetModifierBonusStats_Strength()
    return self.bonus_all_stats
end

function modifier_item_bloodstone_custom:GetModifierHealthBonus()
    return self.bonus_health
end

function modifier_item_bloodstone_custom:GetModifierManaBonus()
    return self.bonus_mana
end

function modifier_item_bloodstone_custom:GetModifierConstantManaRegen()
    return self.bonus_mp_regen
end

function modifier_item_bloodstone_custom:OnTakeDamage(keys)
	if not IsServer() then return end
	local target = keys.unit
	local attacker = keys.attacker
	if attacker ~= self:GetParent() then return end
	print(keys.damage, keys.original_damage)
	if attacker:FindAllModifiersByName(self:GetName())[1] ~= self then return end
	if target:IsBuilding() or target:IsOther() then return end
	if not keys.inflictor or keys.damage_category ~= DOTA_DAMAGE_CATEGORY_SPELL then return end

	if bit.band(keys.damage_flags, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL) == DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL then return end
	if bit.band(keys.damage_flags, DOTA_DAMAGE_FLAG_REFLECTION) == DOTA_DAMAGE_FLAG_REFLECTION then return end
	local damage = keys.damage
	if damage <= 0 then return end

	local lifesteal_pfx = ParticleManager:CreateParticle("particles/items3_fx/octarine_core_lifesteal.vpcf", PATTACH_ABSORIGIN_FOLLOW, attacker)
	ParticleManager:SetParticleControl(lifesteal_pfx, 0, attacker:GetAbsOrigin())
	ParticleManager:ReleaseParticleIndex(lifesteal_pfx)

	-- "However, when attacking illusions, the heal is not affected by the illusion's changed incoming damage values."
	-- This is EXTREMELY rough because I am not aware of any functions that can explicitly give you the incoming/outgoing damage of an illusion, or to give you the "displayed" damage when you're hitting illusions, which show numbers as if you were hitting a non-illusion.
	if target:IsIllusion() then
		if keys.damage_type == DAMAGE_TYPE_PHYSICAL and target.GetPhysicalArmorValue and GetReductionFromArmor then
			damage = keys.original_damage * (1 - GetReductionFromArmor(target:GetPhysicalArmorValue(false)))
		elseif keys.damage_type == DAMAGE_TYPE_MAGICAL and target.GetMagicalArmorValue then
			damage = keys.original_damage * (1 - GetReductionFromArmor(target:GetMagicalArmorValue()))
		elseif keys.damage_type == DAMAGE_TYPE_PURE then
			damage = keys.original_damage
		end
	end

	local spell_lifesteal = keys.inflictor == self:GetAbility() and self:GetAbility():GetSpecialValueFor("spell_lifesteal_active") or self:GetAbility():GetSpecialValueFor("spell_lifesteal")
	attacker:HealWithParams(damage * (spell_lifesteal / 100), self:GetAbility(), false, true, attacker, true)
end