LinkLuaModifier("modifier_axe_battle_hunger_lua", "heroes/hero_axe/axe_battle_hunger_lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_axe_battle_hunger_lua_debuff", "heroes/hero_axe/axe_battle_hunger_lua", LUA_MODIFIER_MOTION_NONE)

axe_battle_hunger_lua = axe_battle_hunger_lua or class({})
function axe_battle_hunger_lua:OnSpellStart(newTarget)
	if not IsServer() then return end
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	if newTarget then
		target = newTarget
	else
		if target:TriggerSpellAbsorb(self) then return end
	end
	local duration = self:GetSpecialValueFor("duration")

	target:AddNewModifier(caster, self, "modifier_axe_battle_hunger_lua_debuff", {duration = duration * (1 - target:GetStatusResistance())})

	caster:EmitSound("Hero_Axe.Battle_Hunger")
end


modifier_axe_battle_hunger_lua = modifier_axe_battle_hunger_lua or class({})
function modifier_axe_battle_hunger_lua:IsHidden() return false end
function modifier_axe_battle_hunger_lua:IsPurgable() return false end
function modifier_axe_battle_hunger_lua:IsDebuff() return false end
function modifier_axe_battle_hunger_lua:OnCreated() self:OnRefresh() end
function modifier_axe_battle_hunger_lua:OnRefresh()
	self.bonus = self:GetAbility():GetSpecialValueFor("speed_bonus")
--	self.strength_bonus = self:GetParent():IsHero() and self:GetAbility():GetSpecialValueFor("str_bonus_per_hero") or 0
	self.strength_bonus = self:GetAbility():GetSpecialValueFor("str_bonus_per_hero")
end
function modifier_axe_battle_hunger_lua:OnStackCountChanged(old)
	if not IsServer() then return end
	if self:GetStackCount() == 0 then self:Destroy() end
end
function modifier_axe_battle_hunger_lua:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS
	}
end
function modifier_axe_battle_hunger_lua:GetModifierMoveSpeedBonus_Percentage() return self.bonus * self:GetStackCount() end
function modifier_axe_battle_hunger_lua:GetModifierBonusStats_Strength() return self.strength_bonus * self:GetStackCount() end


modifier_axe_battle_hunger_lua_debuff = modifier_axe_battle_hunger_lua_debuff or class({})
function modifier_axe_battle_hunger_lua_debuff:IsHidden() return false end
function modifier_axe_battle_hunger_lua_debuff:IsPurgable() return true end
function modifier_axe_battle_hunger_lua_debuff:IsDebuff() return true end
function modifier_axe_battle_hunger_lua_debuff:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end
function modifier_axe_battle_hunger_lua_debuff:GetEffectName() return "particles/units/heroes/hero_axe/axe_battle_hunger.vpcf" end
function modifier_axe_battle_hunger_lua_debuff:GetEffectAttachType() return PATTACH_OVERHEAD_FOLLOW end
function modifier_axe_battle_hunger_lua_debuff:OnCreated()
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	self.slow = ability:GetSpecialValueFor("slow")
	self.damage = 0
	if caster.GetStrength then
		local damage_per_str = ability:GetSpecialValueFor("damage_per_str")
		self.damage = self.damage + (caster:GetStrength() * (damage_per_str / 100))
	end
	local interval = ability:GetSpecialValueFor("interval")
	self.str_debuff = ability:GetSpecialValueFor("str_bonus_per_hero")

	if not IsServer() then return end
	self.damageTable = {
		victim = self:GetParent(),
		attacker = self:GetCaster(),
		damage = self.damage * interval,
		ability = ability,
		damage_type = DAMAGE_TYPE_MAGICAL,
		damage_flags = DOTA_DAMAGE_FLAG_NONE,
	}
	caster:AddNewModifier(caster, ability, "modifier_axe_battle_hunger_lua", {}):IncrementStackCount()
	self:OnIntervalThink()
	self:StartIntervalThink(interval)
end
function modifier_axe_battle_hunger_lua_debuff:OnIntervalThink()
	if not IsServer() then return end
	if not self:GetAbility() then return end
	ApplyDamage(self.damageTable)
end
function modifier_axe_battle_hunger_lua_debuff:OnDestroy()
	if not IsServer() then return end
	local caster = self:GetCaster()
	caster:SetModifierStackCount("modifier_axe_battle_hunger_lua", caster, caster:GetModifierStackCount("modifier_axe_battle_hunger_lua", caster) - 1)
end
function modifier_axe_battle_hunger_lua_debuff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_EVENT_ON_DEATH,
	}
end
function modifier_axe_battle_hunger_lua_debuff:GetModifierMoveSpeedBonus_Percentage() return self.slow end
function modifier_axe_battle_hunger_lua_debuff:GetModifierBonusStats_Strength() return self.str_debuff * (-1) end
function modifier_axe_battle_hunger_lua_debuff:OnDeath(params)
	if not IsServer() then return end
	local unit = params.unit
	if not unit then return end
	local attacker = params.attacker
	if not attacker then return end
	if attacker ~= self:GetParent() then return end
	self:Destroy()
end
