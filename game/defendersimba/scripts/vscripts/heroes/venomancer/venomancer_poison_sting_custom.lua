LinkLuaModifier("modifier_venomancer_poison_sting_custom", "heroes/venomancer/venomancer_poison_sting_custom", LUA_MODIFIER_MOTION_NONE)


venomancer_poison_sting_custom = venomancer_poison_sting_custom or class({})
function venomancer_poison_sting_custom:GetIntrinsicModifierName() return "modifier_venomancer_poison_sting_custom" end


modifier_venomancer_poison_sting_custom = modifier_venomancer_poison_sting_custom or class({})
function modifier_venomancer_poison_sting_custom:IsHidden() return true end
function modifier_venomancer_poison_sting_custom:IsDebuff() return false end
function modifier_venomancer_poison_sting_custom:RemoveOnDeath() return false end
function modifier_venomancer_poison_sting_custom:OnCreated() self:OnRefresh() end
function modifier_venomancer_poison_sting_custom:OnRefresh()
	self.stack_count = self:GetAbility():GetSpecialValueFor("stack_count")
	self.target_count = self:GetAbility():GetSpecialValueFor("target_count")

	if not IsServer() then return end
	self.targetTeam = self:GetAbility():GetAbilityTargetTeam()
	self.targetType = self:GetAbility():GetAbilityTargetType()
	self.targetFlags = self:GetAbility():GetAbilityTargetFlags()
end
function modifier_venomancer_poison_sting_custom:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end
function modifier_venomancer_poison_sting_custom:OnAttack(keys)
	if not IsServer() then return end
	local target = keys.target
	if not target then return end
	local attacker = keys.attacker
	if not attacker then return end
	if attacker ~= self:GetParent() or keys.no_attack_cooldown == true then return end

	if not attacker:GetUnitName() == "npc_dota_venomancer_poison_ward" or not self:GetCaster():HasModifier("modifier_item_aghanims_shard") then return end
	local isRangedAttacker = (attacker:GetAttackCapability() == DOTA_UNIT_CAP_RANGED_ATTACK)

	local currentDamagedEnemies = 0
	local enemies = FindUnitsInRadius(attacker:GetTeamNumber(), attacker:GetAbsOrigin(), nil, attacker:Script_GetAttackRange(), self.targetTeam, self.targetType, self.targetFlags, FIND_ANY_ORDER, false)
	for _, enemy in pairs(enemies) do
		if enemy ~= target then
			attacker:PerformAttack(enemy, true, true, true, false, isRangedAttacker, false, false)
			self:ApplyToxin(enemy)
			currentDamagedEnemies = currentDamagedEnemies + 1
		end
		if currentDamagedEnemies >= self.target_count then
			break
		end
	end
end
function modifier_venomancer_poison_sting_custom:OnAttackLanded(keys)
	if not IsServer() then return end
	local target = keys.target
	if not target then return end
	local attacker = keys.attacker
	if not attacker then return end
	if attacker == self:GetParent() and keys.no_attack_cooldown == false then
		self:ApplyToxin(target)
	end
end
function modifier_venomancer_poison_sting_custom:ApplyToxin(enemy)
	if not IsServer() then return end
	local caster = self:GetCaster()
	if caster:GetUnitName() == "npc_dota_venomancer_poison_ward" then
		caster = caster:GetOwner()
	end
	if caster then
		local innate = caster:FindAbilityByName("venomancer_universal_toxin")
		if innate and innate:IsTrained() then
			local modif = enemy:AddNewModifier(caster, innate, "modifier_venomancer_universal_toxin_debuff", {duration = innate:GetSpecialValueFor("duration") * (1 - enemy:GetStatusResistance())})
			if modif then
				modif:SetStackCount(modif:GetStackCount() + self.stack_count)
			end
		end
	end
end
