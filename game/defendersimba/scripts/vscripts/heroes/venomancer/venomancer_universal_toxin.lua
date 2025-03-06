LinkLuaModifier("modifier_venomancer_universal_toxin", "heroes/venomancer/venomancer_universal_toxin", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_venomancer_universal_toxin_debuff", "heroes/venomancer/venomancer_universal_toxin", LUA_MODIFIER_MOTION_NONE)


venomancer_universal_toxin = venomancer_universal_toxin or class({})
function venomancer_universal_toxin:GetIntrinsicModifierName() return "modifier_venomancer_universal_toxin" end
function venomancer_universal_toxin:OnHeroLevelUp()
	if not IsServer() then return end
	local caster = self:GetCaster()
	caster:SetModifierStackCount("modifier_venomancer_universal_toxin", caster, caster:GetLevel())
end


modifier_venomancer_universal_toxin = modifier_venomancer_universal_toxin or class({})
function modifier_venomancer_universal_toxin:IsHidden() return true end
function modifier_venomancer_universal_toxin:IsDebuff() return false end
function modifier_venomancer_universal_toxin:RemoveOnDeath() return false end
function modifier_venomancer_universal_toxin:OnCreated() self:OnRefresh() end
function modifier_venomancer_universal_toxin:OnRefresh()
	if not IsServer() then return end
	self.hero_abilities = {}
	local parent = self:GetParent()
	for i = 0, parent:GetAbilityCount() - 1 do
		local ability = parent:GetAbilityByIndex(i)
		if ability then
			table.insert(self.hero_abilities, ability:GetAbilityName())
		end
	end
end
function modifier_venomancer_universal_toxin:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_TAKEDAMAGE,
		MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL,
		MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL_VALUE,
	}
end
function modifier_venomancer_universal_toxin:OnTakeDamage(keys)
	if not IsServer() then return end
	local ability = self:GetAbility()
	if not ability then return end
	local unit = keys.unit
	if not unit then return end
	local attacker = keys.attacker
	if not attacker then return end
	if attacker ~= self:GetParent() or unit == self:GetParent() then return end
	if keys.damage_category == DOTA_DAMAGE_CATEGORY_ATTACK then return end
	if keys.inflictor and (keys.inflictor:IsItem() ~= true or self:IsHeroAbility(keys.inflictor:GetAbilityName())) then return end

	local duration = ability:GetSpecialValueFor("duration")
	local stack_count = ability:GetSpecialValueFor("stack_count_per_item_tick")
	local modif = unit:AddNewModifier(attacker, ability, "modifier_venomancer_universal_toxin_debuff", {duration = duration * (1 - unit:GetStatusResistance())})
	modif:SetStackCount(modif:GetStackCount() + stack_count)
end
function modifier_venomancer_universal_toxin:GetModifierOverrideAbilitySpecial(keys)
	if self.lock then return end
	if not self:GetAbility() then return end
	if self:GetParent() == nil or keys.ability == nil then return 0 end
	if keys.ability == self:GetAbility() and keys.ability_special_value == "damage_per_sec" then return 1 end
	return 0
end
function modifier_venomancer_universal_toxin:GetModifierOverrideAbilitySpecialValue(keys)
	self.lock = true
	local valueName = keys.ability_special_value
	local abilityValue = keys.ability:GetLevelSpecialValueFor(valueName, keys.ability_special_level)
	self.lock = false
	if abilityValue <= 0 then return end
	local ability = self:GetAbility()
	if not ability then return end
	if keys.ability == ability and valueName == "damage_per_sec" then
		local int_scale = 0
		if self:GetParent():HasScepter() and self:GetParent().GetIntellect then
			int_scale = (ability:GetSpecialValueFor("int_scale") / 100) * self:GetParent():GetIntellect(false)
		end
		local damage_per_lvl = ability:GetSpecialValueFor("bonus_damage_per_lvl")
		return abilityValue + (damage_per_lvl * (math.max(self:GetStackCount(), 1) - 1)) + int_scale
	end
end
function modifier_venomancer_universal_toxin:IsHeroAbility(ability_name)
	for _, name in pairs(self.hero_abilities) do
		if name == ability_name then
			return true
		end
	end
	return false
end


modifier_venomancer_universal_toxin_debuff = modifier_venomancer_universal_toxin_debuff or class({})
function modifier_venomancer_universal_toxin_debuff:IsHidden() return false end
function modifier_venomancer_universal_toxin_debuff:IsDebuff() return true end
function modifier_venomancer_universal_toxin_debuff:OnCreated()
	self:OnRefresh()

	if not IsServer() then return end
	self:StartIntervalThink(self.damage_tick_rate)
end
function modifier_venomancer_universal_toxin_debuff:OnRefresh()
	self.damage_tick_rate = self:GetAbility():GetSpecialValueFor("damage_tick_rate")
	self.damage_per_sec = self:GetAbility():GetSpecialValueFor("damage_per_sec")
	self.ms_debuff_treshold = self:GetAbility():GetSpecialValueFor("ms_debuff_treshold")
	self.ms_debuff_value = self:GetAbility():GetSpecialValueFor("ms_debuff_value") * (-1)

	if not IsServer() then return end
	self.damageTabel = {
		victim = self:GetParent(),
		attacker = self:GetCaster(),
		ability = self:GetAbility(),
		damage = ((self.damage_per_sec / self.damage_tick_rate) * self:GetStackCount()),
		damage_type = self:GetAbility():GetAbilityDamageType(),
	}
end
function modifier_venomancer_universal_toxin_debuff:OnIntervalThink()
	if not IsServer() then return end
	if not self:GetAbility() then return end
	ApplyDamage(self.damageTabel)
end
function modifier_venomancer_universal_toxin_debuff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end
function modifier_venomancer_universal_toxin_debuff:GetModifierMoveSpeedBonus_Percentage()
	return (self.ms_debuff_value) * (self:GetStackCount() / self.ms_debuff_treshold)
end
