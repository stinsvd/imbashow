----------------
-- Echo Sabre --
----------------
LinkLuaModifier("modifier_echo_sabre_cus", "items/echo_sabre", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_echo_sabre_cus_echo_slow", "items/echo_sabre", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_echo_sabre_cus_echo_cd", "items/echo_sabre", LUA_MODIFIER_MOTION_NONE)

item_echo_sabre_cus = item_echo_sabre_cus or class({})
function item_echo_sabre_cus:GetIntrinsicModifierName() return "modifier_echo_sabre_cus" end

item_echo_sabre_2_cus = item_echo_sabre_cus
item_echo_sabre_3_cus = item_echo_sabre_cus

modifier_echo_sabre_cus = modifier_echo_sabre_cus or class({})
function modifier_echo_sabre_cus:IsHidden() return true end
function modifier_echo_sabre_cus:IsPurgable() return false end
function modifier_echo_sabre_cus:IsPermanent() return true end
function modifier_echo_sabre_cus:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end
function modifier_echo_sabre_cus:OnCreated()
	if not IsServer() then return end
	self:StartIntervalThink(FrameTime())
end
function modifier_echo_sabre_cus:OnIntervalThink()
	if not IsServer() then return end
	local ability = self:GetAbility()
	if not ability then return end
	local parent = self:GetParent()
	
	if parent:IsRangedAttacker() or parent:IsIllusion() or parent:FindAllModifiersByName(self:GetName())[1] ~= self then self:SetStackCount(0) return end
	if self:GetStackCount() > 0 then return end
	
	if ability:IsCooldownReady() then
		self:SetStackCount(ability:GetSpecialValueFor("echo_attacks")+1)
	end
end
function modifier_echo_sabre_cus:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_IGNORE_ATTACKSPEED_LIMIT,
		MODIFIER_EVENT_ON_ATTACK,
	}
end
function modifier_echo_sabre_cus:GetModifierPreAttack_BonusDamage()
	if self:GetAbility() then return self:GetAbility():GetSpecialValueFor("bonus_damage") end
end
function modifier_echo_sabre_cus:GetModifierBonusStats_Strength()
	if self:GetAbility() then return self:GetAbility():GetSpecialValueFor("bonus_strength") end
end
function modifier_echo_sabre_cus:GetModifierAttackSpeedBonus_Constant()
	if self:GetAbility() then
		if IsServer() and self:GetStackCount() > 0 and not self:GetParent():IsRangedAttacker() then return self:GetAbility():GetSpecialValueFor("echo_attack_speed") end
	end
end
function modifier_echo_sabre_cus:GetModifierConstantManaRegen()
	if self:GetAbility() then return self:GetAbility():GetSpecialValueFor("bonus_mana_regen") end
end
function modifier_echo_sabre_cus:GetModifierAttackSpeed_Limit()
	if self:GetStackCount() > 0 then return 1 end
end
function modifier_echo_sabre_cus:OnAttack(keys)
	if not IsServer() then return end
	local ability = self:GetAbility()
	if not ability then return end
	if self:GetStackCount() <= 0 then return end
	local parent = self:GetParent()
	local target = keys.target
	
	if parent:IsRangedAttacker() then return end
	if keys.attacker ~= parent then return end
	if parent:IsIllusion() then return end
	if parent:FindAllModifiersByName(self:GetName())[1] ~= self then return end
	
	if not target:IsBuilding() and not target:IsOther() then
		local duration = ability:GetSpecialValueFor("slow_duration")
		target:AddNewModifier(parent, ability, "modifier_echo_sabre_cus_echo_slow", {duration = duration * (1 - target:GetStatusResistance())})
	end
	self:DecrementStackCount()
	local attacks = ability:GetSpecialValueFor("echo_attacks")
	if self:GetStackCount() <= math.floor(attacks) and ability:IsCooldownReady() then
		ability:UseResources(true, false, false, true)
	end
end

-- Echo Sabre echo slow
modifier_echo_sabre_cus_echo_slow = modifier_echo_sabre_cus_echo_slow or class({})
function modifier_echo_sabre_cus_echo_slow:IsDebuff() return true end
function modifier_echo_sabre_cus_echo_slow:IsHidden() return false end
function modifier_echo_sabre_cus_echo_slow:IsPurgable() return true end
function modifier_echo_sabre_cus_echo_slow:IsStunDebuff() return false end
function modifier_echo_sabre_cus_echo_slow:RemoveOnDeath() return true end
function modifier_echo_sabre_cus_echo_slow:OnCreated()
	self.slow = self:GetAbility():GetSpecialValueFor("movement_slow")
end
function modifier_echo_sabre_cus_echo_slow:DeclareFunctions() return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE} end
function modifier_echo_sabre_cus_echo_slow:GetModifierMoveSpeedBonus_Percentage() return self.slow * (-1) end


modifier_echo_sabre_cus_echo_cd = modifier_echo_sabre_cus_echo_cd or class({})
function modifier_echo_sabre_cus_echo_cd:IsHidden() return false end
function modifier_echo_sabre_cus_echo_cd:IsDebuff() return true end
function modifier_echo_sabre_cus_echo_cd:IsPurgable() return false end
function modifier_echo_sabre_cus_echo_cd:RemoveOnDeath() return false end
