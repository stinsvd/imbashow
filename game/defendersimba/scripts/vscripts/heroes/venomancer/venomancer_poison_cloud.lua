LinkLuaModifier("modifier_venomancer_poison_cloud", "heroes/venomancer/venomancer_poison_cloud", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_venomancer_poison_cloud_buff", "heroes/venomancer/venomancer_poison_cloud", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_venomancer_poison_cloud_debuff_aura","heroes/venomancer/venomancer_poison_cloud", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_venomancer_poison_cloud_debuff","heroes/venomancer/venomancer_poison_cloud", LUA_MODIFIER_MOTION_NONE)


venomancer_poison_cloud = venomancer_poison_cloud or class({})
function venomancer_poison_cloud:Precache(context)
	PrecacheResource("particle", "particles/custom/heroes/venomancer/venomancer_toxic_cloud.vpcf", context)
end
function venomancer_poison_cloud:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()
	local duration = self:GetSpecialValueFor("duration")

	CreateModifierThinker(caster, self, "modifier_venomancer_poison_cloud", {duration = duration}, point, caster:GetTeamNumber(), false)

	caster:EmitSound("Hero_Venomancer.PoisonNova")
end


modifier_venomancer_poison_cloud = modifier_venomancer_poison_cloud or class({})
function modifier_venomancer_poison_cloud:IsHidden() return true end
function modifier_venomancer_poison_cloud:IsPurgable() return false end
function modifier_venomancer_poison_cloud:RemoveOnDeath() return true end
function modifier_venomancer_poison_cloud:OnCreated()
	if not IsServer() then return end
	local owner = self:GetParent()
	self.radius = self:GetAbility():GetSpecialValueFor("radius")

	local particle = ParticleManager:CreateParticle("particles/custom/heroes/venomancer/venomancer_toxic_cloud.vpcf", PATTACH_WORLDORIGIN, owner)
	ParticleManager:SetParticleControl(particle, 0, owner:GetAbsOrigin())
	ParticleManager:SetParticleControl(particle, 1, Vector(self.radius, 0, 0))
	self:AddParticle(particle, false, false, -1, false, false)

	owner:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_venomancer_poison_cloud_debuff_aura", {})
end
function modifier_venomancer_poison_cloud:OnDestroy()
	if not IsServer() then return end
	self:GetParent():RemoveSelf()
end
function modifier_venomancer_poison_cloud:IsAura() return true end
function modifier_venomancer_poison_cloud:GetAuraRadius() return self.radius end
function modifier_venomancer_poison_cloud:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_FRIENDLY end
function modifier_venomancer_poison_cloud:GetAuraSearchType() return DOTA_UNIT_TARGET_HEROES_AND_CREEPS end
function modifier_venomancer_poison_cloud:GetAuraSearchFlags() return DOTA_UNIT_TARGET_FLAG_NONE end
function modifier_venomancer_poison_cloud:GetModifierAura() return "modifier_venomancer_poison_cloud_buff" end


modifier_venomancer_poison_cloud_buff = modifier_venomancer_poison_cloud_buff or class({})
function modifier_venomancer_poison_cloud_buff:IsHidden() return false end
function modifier_venomancer_poison_cloud_buff:IsPurgable() return false end
function modifier_venomancer_poison_cloud_buff:OnCreated()
	self.bonus_as = self:GetAbility():GetSpecialValueFor("bonus_as")
end
function modifier_venomancer_poison_cloud_buff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
	}
end
function modifier_venomancer_poison_cloud_buff:GetModifierAttackSpeedBonus_Constant() return self.bonus_as end


modifier_venomancer_poison_cloud_debuff_aura = modifier_venomancer_poison_cloud_debuff_aura or class({})
function modifier_venomancer_poison_cloud_debuff_aura:IsHidden() return true end
function modifier_venomancer_poison_cloud_debuff_aura:IsPurgable() return false end
function modifier_venomancer_poison_cloud_debuff_aura:RemoveOnDeath() return true end
function modifier_venomancer_poison_cloud_debuff_aura:OnCreated()
	self.radius = self:GetAbility():GetSpecialValueFor("radius")
end
function modifier_venomancer_poison_cloud_debuff_aura:IsAura() return true end
function modifier_venomancer_poison_cloud_debuff_aura:GetAuraRadius() return self.radius end
function modifier_venomancer_poison_cloud_debuff_aura:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_ENEMY end
function modifier_venomancer_poison_cloud_debuff_aura:GetAuraSearchType() return DOTA_UNIT_TARGET_HEROES_AND_CREEPS end
function modifier_venomancer_poison_cloud_debuff_aura:GetAuraSearchFlags() return DOTA_UNIT_TARGET_FLAG_NONE end
function modifier_venomancer_poison_cloud_debuff_aura:GetModifierAura() return "modifier_venomancer_poison_cloud_debuff" end


modifier_venomancer_poison_cloud_debuff = modifier_venomancer_poison_cloud_debuff or class({})
function modifier_venomancer_poison_cloud_debuff:IsHidden() return false end
function modifier_venomancer_poison_cloud_debuff:IsPurgable() return false end
function modifier_venomancer_poison_cloud_debuff:OnCreated()
	self.heal_debuff = self:GetAbility():GetSpecialValueFor("heal_debuff") * (-1)
	self.stack_count_per_sec = self:GetAbility():GetSpecialValueFor("stack_count_per_sec")
	self.debuff_interval = self:GetAbility():GetSpecialValueFor("debuff_interval")

	if not IsServer() then return end
	self:OnIntervalThink()
	self:StartIntervalThink(self.debuff_interval)
end
function modifier_venomancer_poison_cloud_debuff:OnIntervalThink()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local owner = self:GetParent()
	local innate = caster:FindAbilityByName("venomancer_universal_toxin")
	if innate and innate:IsTrained() then
		local debuff = owner:AddNewModifier(caster, innate, "modifier_venomancer_universal_toxin_debuff", {duration = innate:GetSpecialValueFor("duration") * (1 - owner:GetStatusResistance())})
		debuff:SetStackCount(debuff:GetStackCount() + (self.stack_count_per_sec * self.debuff_interval))
	end
end
function modifier_venomancer_poison_cloud_debuff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET,
		MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
	}
end
function modifier_venomancer_poison_cloud_debuff:GetModifierHealAmplify_PercentageTarget() return self.heal_debuff end
function modifier_venomancer_poison_cloud_debuff:GetModifierHPRegenAmplify_Percentage() return self.heal_debuff end
