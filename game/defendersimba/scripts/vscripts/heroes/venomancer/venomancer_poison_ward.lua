LinkLuaModifier("modifier_venomancer_poison_ward", "heroes/venomancer/venomancer_poison_ward", LUA_MODIFIER_MOTION_NONE)


venomancer_poison_ward = venomancer_poison_ward or class({})
function venomancer_poison_ward:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local spawn_position = self:GetCursorPosition()
	local ward = CreateUnitByName("npc_dota_venomancer_poison_ward", spawn_position, true, caster, caster, caster:GetTeamNumber())

	ward:AddNewModifier(caster, self, "modifier_venomancer_poison_ward", {})
	ward:AddNewModifier(caster, nil, "modifier_kill", {duration = self:GetSpecialValueFor("duration")})
end


modifier_venomancer_poison_ward = modifier_venomancer_poison_ward or class({})
function modifier_venomancer_poison_ward:IsHidden() return true end
function modifier_venomancer_poison_ward:IsPurgable() return false end
function modifier_venomancer_poison_ward:OnCreated()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	local parent = self:GetParent()

	local base_hp = ability:GetSpecialValueFor("base_hp")
	local hp_pct_caster = ability:GetSpecialValueFor("hp_pct_caster") / 100
	local base_dmg = ability:GetSpecialValueFor("base_dmg")
	local dmg_pct_caster_int = ability:GetSpecialValueFor("dmg_pct_caster_int") / 100

	local efficiency = ability:GetSpecialValueFor("poison_sting_efficiency_pct") / 100

	local venomancer_sting = caster:FindAbilityByName("venomancer_poison_sting_custom")
	if venomancer_sting then
		local ward_sting = parent:AddAbility("venomancer_poison_sting_custom")
		if ward_sting then
			ward_sting:SetLevel(venomancer_sting:GetLevel())
			ward_sting:SetActivated(true)
			local ward_sting_modif = self:GetParent():FindModifierByName("modifier_venomancer_poison_sting_custom")
			if ward_sting_modif then
				ward_sting_modif.stack_count = ward_sting_modif.stack_count * efficiency
				ward_sting_modif.target_count = self:GetAbility():GetSpecialValueFor("target_count")
			end
		end
	end

	local max_health = base_hp + (caster:GetMaxHealth() * hp_pct_caster)
	local attack_damage = base_dmg
	if caster.GetIntellect then
		attack_damage = base_dmg + math.floor(caster:GetIntellect(false) * dmg_pct_caster_int)
	end

	parent:SetBaseMaxHealth(max_health)
	parent:SetMaxHealth(max_health)
	parent:SetHealth(max_health)
	parent:SetBaseDamageMin(attack_damage)
	parent:SetBaseDamageMax(attack_damage)
end
