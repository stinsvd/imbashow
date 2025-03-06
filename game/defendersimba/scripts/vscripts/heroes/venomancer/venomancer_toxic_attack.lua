LinkLuaModifier("modifier_venomancer_toxic_attack_debuff", "heroes/venomancer/venomancer_toxic_attack", LUA_MODIFIER_MOTION_NONE)


venomancer_toxic_attack = venomancer_toxic_attack or class({})
function venomancer_toxic_attack:Precache(context)
	PrecacheResource("particle", "particles/econ/items/venomancer/veno_2022_immortal_tail/veno_2022_immortal_poison_nova.vpcf", context)
end
function venomancer_toxic_attack:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor("radius")
	local duration = self:GetSpecialValueFor("duration")
	local stack_count = self:GetSpecialValueFor("stack_count")
	local burns_stacks_pct = self:GetSpecialValueFor("burns_stacks_pct") / 100
	local innate = caster:FindAbilityByName("venomancer_universal_toxin")

	local particle = ParticleManager:CreateParticle("particles/econ/items/venomancer/veno_2022_immortal_tail/veno_2022_immortal_poison_nova.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(particle, 0, caster:GetAbsOrigin())
	ParticleManager:SetParticleControl(particle, 1, Vector(radius, (radius - 0) / 600, 600))
	ParticleManager:ReleaseParticleIndex(particle)
	caster:EmitSound("Hero_Venomancer.PoisonNova")

	local enemies = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HEROES_AND_CREEPS, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	local damageTable = {
		victim = nil,
		attacker = caster,
		ability = innate,
		damage = nil,
		damage_type = innate:GetAbilityDamageType(),
	}

	for _, enemy in pairs(enemies) do
		local statusRes = 1 - enemy:GetStatusResistance()
		enemy:AddNewModifier(caster, self, "modifier_venomancer_toxic_attack_debuff", {duration = duration * statusRes})
		
		if innate and innate:IsTrained() then
			local modif = enemy:FindModifierByName("modifier_venomancer_universal_toxin_debuff")
			local toxin_duration = innate:GetSpecialValueFor("duration")
			local damage_per_sec = innate:GetSpecialValueFor("damage_per_sec")
			local total_damage = 0
			
			if modif then
				modif:SetDuration(modif.duration, true)
				local stacks = modif:GetStackCount() * burns_stacks_pct
				total_damage = stacks * damage_per_sec * modif.duration
				
				if burns_stacks_pct > 0 then
					modif:SetStackCount(stacks)
				end
			else
				modif = enemy:AddNewModifier(caster, innate, "modifier_venomancer_universal_toxin_debuff", {duration = toxin_duration * statusRes})
			end
			
			modif:SetStackCount(modif:GetStackCount() + stack_count)
			
			if total_damage > 0 then
				damageTable.victim = enemy
				damageTable.damage = total_damage
				ApplyDamage(damageTable)
			end
		end
	end
end


modifier_venomancer_toxic_attack_debuff = modifier_venomancer_toxic_attack_debuff or class({})
function modifier_venomancer_toxic_attack_debuff:IsHidden() return false end
function modifier_venomancer_toxic_attack_debuff:IsDebuff() return true end
function modifier_venomancer_toxic_attack_debuff:IsPurgable() return true end
function modifier_venomancer_toxic_attack_debuff:OnCreated() self:OnRefresh() end
function modifier_venomancer_toxic_attack_debuff:OnRefresh()
	self.ms_debuff_pct = self:GetAbility():GetSpecialValueFor("ms_debuff_pct") * (-1)
	self.duration = self:GetRemainingTime()
end
function modifier_venomancer_toxic_attack_debuff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end
function modifier_venomancer_toxic_attack_debuff:GetModifierMoveSpeedBonus_Percentage()
	return (self:GetRemainingTime() / self.duration) * self.ms_debuff_pct
end
