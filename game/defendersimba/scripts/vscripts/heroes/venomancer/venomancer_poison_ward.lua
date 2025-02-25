venomancer_poison_ward = class({
	OnSpellStart = function(self)
		if not IsServer() then return end
		local caster = self:GetCaster()
		local spawn_position = self:GetCursorPosition()
		local ward = CreateUnitByName("npc_dota_venomancer_poison_ward", spawn_position, true, caster, caster, caster:GetTeamNumber())

		ward:AddNewModifier(caster, self, "modifier_venomancer_poison_ward", {})
		ward:AddNewModifier(caster, nil, "modifier_kill", { duration = self:GetSpecialValueFor("duration") })
	end,
})

LinkLuaModifier("modifier_venomancer_poison_ward", "heroes/venomancer/venomancer_poison_ward", LUA_MODIFIER_MOTION_NONE)

modifier_venomancer_poison_ward = class({
	IsHidden        = function() return true  end,
	IsPurgable      = function() return false end,
	RemoveOnDeath   = function() return true  end,

	OnCreated       = function(self)
		if not IsServer() then return end
		self.caster = self:GetCaster()
		self.ability = self:GetAbility()
		self.parent = self:GetParent()

		self.efficiency = self.ability:GetSpecialValueFor("poison_sting_efficiency_pct") / 100
		self.ward_sting_values = {}

		local venomancer_sting = self.caster:FindAbilityByName("venomancer_poison_sting_custom")

		if venomancer_sting then
			local ward_sting = self.parent:AddAbility("venomancer_poison_sting_custom")

			if ward_sting then
				ward_sting:SetLevel(venomancer_sting:GetLevel())
				ward_sting:SetActivated(true)

				local ward_sting_modif = self:GetParent():FindModifierByName("modifier_venomancer_poison_sting_custom")
				if ward_sting_modif then
					ward_sting_modif.stack_count  = ward_sting_modif.stack_count * self.efficiency
					ward_sting_modif.target_count = self:GetAbility():GetSpecialValueFor("target_count")
				end
			end
		end

		self:UpdateStats()
	end,
	
	UpdateStats = function(self)
		if not IsServer() then return end
		local base_hp = self.ability:GetSpecialValueFor("base_hp")
		local hp_pct_caster = self.ability:GetSpecialValueFor("hp_pct_caster") / 100
		local base_dmg = self.ability:GetSpecialValueFor("base_dmg")
		local dmg_pct_caster_int = self.ability:GetSpecialValueFor("dmg_pct_caster_int") / 100
		
		local max_health = base_hp + (self.caster:GetMaxHealth() * hp_pct_caster)
		local attack_damage = base_dmg + math.floor(self.caster:GetIntellect(false) * dmg_pct_caster_int)
		
		self.parent:SetBaseMaxHealth(max_health)
		self.parent:SetHealth(max_health)
		self.parent:SetBaseDamageMin(attack_damage)
		self.parent:SetBaseDamageMax(attack_damage)
	end,
})