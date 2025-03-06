-----------------
-- Witch Blade --
-----------------
LinkLuaModifier("modifier_witch_blade_cus", "items/witch_blade", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_witch_blade_cus_debuff", "items/witch_blade", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_parasma_debuff", "items/witch_blade", LUA_MODIFIER_MOTION_NONE)


item_witch_blade_cus = item_witch_blade_cus or class({})
function item_witch_blade_cus:Precache(context)
	PrecacheResource("particle", "particles/items3_fx/witch_blade_debuff.vpcf", context)
end
function item_witch_blade_cus:GetIntrinsicModifierName() return "modifier_witch_blade_cus" end


item_witch_blade_2_cus = item_witch_blade_cus
item_witch_blade_3_cus = item_witch_blade_cus
item_witch_blade_4_cus = item_witch_blade_cus
item_witch_blade_5_cus = item_witch_blade_cus
item_witch_blade_6_cus = item_witch_blade_cus


modifier_witch_blade_cus = modifier_witch_blade_cus or class({})
function modifier_witch_blade_cus:IsHidden() return true end
function modifier_witch_blade_cus:IsPurgable() return false end
function modifier_witch_blade_cus:IsPermanent() return true end
function modifier_witch_blade_cus:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end
function modifier_witch_blade_cus:OnCreated()
	if not IsServer() then return end
	self.attacks = {}
	self:OnIntervalThink()
	self:StartIntervalThink(0.1)
end
function modifier_witch_blade_cus:OnIntervalThink()
	if not IsServer() then return end
	if not self:GetAbility():IsCooldownReady() then
		self:SetStackCount(0)
		return
	end
	self:SetStackCount(1)
end
function modifier_witch_blade_cus:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_PROJECTILE_SPEED_BONUS,
		MODIFIER_EVENT_ON_ATTACK,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
		MODIFIER_EVENT_ON_ATTACK_RECORD_DESTROY,
	}
end
function modifier_witch_blade_cus:GetModifierBonusStats_Intellect()
	if self:GetAbility() then return self:GetAbility():GetSpecialValueFor("bonus_intellect") end
end
function modifier_witch_blade_cus:GetModifierConstantManaRegen()
	if self:GetAbility() then return self:GetAbility():GetSpecialValueFor("bonus_mana_regen") end
end
function modifier_witch_blade_cus:GetModifierPhysicalArmorBonus()
	if self:GetAbility() then return self:GetAbility():GetSpecialValueFor("bonus_armor") end
end
function modifier_witch_blade_cus:GetModifierAttackSpeedBonus_Constant()
	if self:GetAbility() then return self:GetAbility():GetSpecialValueFor("bonus_attack_speed") end
end
function modifier_witch_blade_cus:GetModifierProjectileSpeedBonus()
	if self:GetAbility() then return self:GetAbility():GetSpecialValueFor("projectile_speed") end
end
function modifier_witch_blade_cus:OnAttack(keys)
	if not IsServer() then return end
	if self:GetStackCount() == 0 then return end
	local caster = self:GetParent()
	local target = keys.target

	if keys.attacker ~= caster then return end
	if target:IsBuilding() then return end
	if target:IsDebuffImmune() then return end
	if caster:GetTeamNumber() == target:GetTeamNumber() then return end
	if caster:IsIllusion() then return end

	self.attacks[keys.record] = true
	self:GetAbility():UseResources(false, false, false, true)
	self:SetStackCount(0)
end
function modifier_witch_blade_cus:OnAttackLanded(keys)
	if not IsServer() then return end
	local ability = self:GetAbility()
	if not ability then return end
	local target = keys.target
	local attacker = keys.attacker

	if attacker ~= self:GetParent() then return end
	if target:IsBuilding() then return end
	if target:IsDebuffImmune() then return end
	if attacker:GetTeamNumber() == target:GetTeamNumber() then return end
	if attacker:IsIllusion() then return end

	local passive_cooldown = ability:GetSpecialValueFor("passive_cooldown")
	if passive_cooldown > 0 then
		target:AddNewModifier(attacker, ability, "modifier_parasma_debuff", {duration = passive_cooldown * (1 - target:GetStatusResistance())})
	end

	if self.attacks[keys.record] == nil then return end
	if attacker:IsRangedAttacker() then
		target:EmitSound("Item.WitchBlade.Target.Ranged")
	else
		target:EmitSound("Item.WitchBlade.Target")
	end

	target:AddNewModifier(attacker, ability, "modifier_witch_blade_cus_debuff", {duration = ability:GetSpecialValueFor("slow_duration") * (1 - target:GetStatusResistance())})
end
function modifier_witch_blade_cus:OnAttackRecordDestroy(keys)
	if not IsServer() then return end
	if self:GetParent() ~= keys.attacker then return end
	if not self.attacks[keys.record] then return end
	self.attacks[keys.record] = nil
end
function modifier_witch_blade_cus:CheckState()
	if self:GetStackCount() == 1 then
		return {[MODIFIER_STATE_CANNOT_MISS] = true}
	end
end

-- Witch Blade Debuff --
modifier_witch_blade_cus_debuff = modifier_witch_blade_cus_debuff or class({})
function modifier_witch_blade_cus_debuff:IsHidden() return false end
function modifier_witch_blade_cus_debuff:IsDebuff() return true end
function modifier_witch_blade_cus_debuff:IsPurgable() return true end
function modifier_witch_blade_cus_debuff:GetEffectName() return "particles/items3_fx/witch_blade_debuff.vpcf" end
function modifier_witch_blade_cus_debuff:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end
function modifier_witch_blade_cus_debuff:OnCreated()
	self:OnRefresh()
	
	if not IsServer() then return end
	self:StartIntervalThink(1)
end
function modifier_witch_blade_cus_debuff:OnRefresh()
	self.int_damage_multiplier = self:GetAbility():GetSpecialValueFor("int_damage_multiplier")
	self.slow = self:GetAbility():GetSpecialValueFor("slow")
end
function modifier_witch_blade_cus_debuff:OnIntervalThink()
	if not IsServer() then return end
	local ability = self:GetAbility()
	if not ability then return end
	local caster = self:GetCaster()
	if caster.GetIntellect and caster:GetIntellect(false) then
		local damage = caster:GetIntellect(false) * self.int_damage_multiplier
		SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_POISON_DAMAGE, self:GetParent(), damage, nil)
		ApplyDamage({
			attacker = caster,
			victim = self:GetParent(),
			ability = ability,
			damage = damage,
			damage_type = DAMAGE_TYPE_MAGICAL,
		})
	end
end
function modifier_witch_blade_cus_debuff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
	}
end
function modifier_witch_blade_cus_debuff:GetModifierMoveSpeedBonus_Percentage() return self.slow * (-1) end

-- Parasma Debuff --
modifier_parasma_debuff = modifier_parasma_debuff or class({})
function modifier_parasma_debuff:IsHidden() return false end
function modifier_parasma_debuff:IsDebuff() return true end
function modifier_parasma_debuff:IsPurgable() return true end
function modifier_parasma_debuff:OnCreated() self:OnRefresh() end
function modifier_parasma_debuff:OnRefresh()
	self.active_mres_reduction = self:GetAbility():GetSpecialValueFor("active_mres_reduction")
end
function modifier_parasma_debuff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS
	}
end
function modifier_parasma_debuff:GetModifierMagicalResistanceBonus() return self.active_mres_reduction * (-1) end
