LinkLuaModifier("modifier_bristleback_warpath_custom", "heroes/bristleback/bristleback_warpath_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_bristleback_warpath_custom_buff", "heroes/bristleback/bristleback_warpath_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_bristleback_warpath_custom_particles", "heroes/bristleback/bristleback_warpath_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_bristleback_warpath_custom_ignore", "heroes/bristleback/bristleback_warpath_custom", LUA_MODIFIER_MOTION_NONE)


bristleback_warpath_custom = bristleback_warpath_custom or class({})
function bristleback_warpath_custom:GetIntrinsicModifierName() return "modifier_bristleback_warpath_custom" end

function bristleback_warpath_custom:AddStack()
	if not IsServer() then return end
	local caster = self:GetCaster()
	if caster:PassivesDisabled() then return end
	local duration = self:GetSpecialValueFor("duration")
	caster:AddNewModifier(caster, self, "modifier_bristleback_warpath_custom_buff", {duration = duration})
end


modifier_bristleback_warpath_custom = class({})
function modifier_bristleback_warpath_custom:IsHidden() return true end
function modifier_bristleback_warpath_custom:DeclareFunctions()
	return {
	 	MODIFIER_EVENT_ON_ABILITY_FULLY_CAST,
	}
end
function modifier_bristleback_warpath_custom:OnAbilityFullyCast(params)
	if not IsServer() then return end
	local parent = self:GetParent()
	local ability = params.ability
	if not ability then return end
	if params.unit ~= parent then return end
	if parent:PassivesDisabled() then return end
	if ability:IsItem() then return end
	if ability:IsToggle() then return end
	if ability:GetEffectiveCooldown(-1) <= 0 then return end
	if not ability:ProcsMagicStick() then return end
	if ability:GetName() == "bristleback_bristleback_custom" then return end
	if parent:HasModifier("modifier_bristleback_warpath_custom_ignore") then return end

	self:GetAbility():AddStack()
end


modifier_bristleback_warpath_custom_buff = modifier_bristleback_warpath_custom_buff or class({})
function modifier_bristleback_warpath_custom_buff:IsHidden() return false end
function modifier_bristleback_warpath_custom_buff:IsPurgable() return false end
function modifier_bristleback_warpath_custom_buff:OnCreated(kv)
	if not IsServer() then return end
	self.stacks = {}
	self:OnRefresh(kv)
	self:StartIntervalThink(FrameTime())
end
function modifier_bristleback_warpath_custom_buff:OnRefresh(kv)
	if not IsServer() then return end
	local max_stacks = self:GetAbility():GetSpecialValueFor("max_stacks")
	if self:GetStackCount() >= max_stacks then
		self:DecrementStackCount()
		table.remove(self.stacks, 1)
	end
	self:IncrementStackCount()
	table.insert(self.stacks, {GameRules:GetGameTime(), kv.duration})
end
function modifier_bristleback_warpath_custom_buff:OnIntervalThink()
	if not IsServer() then return end
	local currentTime = GameRules:GetGameTime()
	for k, v in pairs(self.stacks) do
		if currentTime >= v[1] + v[2] then
			self.stacks[k] = nil
			self:DecrementStackCount()
		end
	end
	if self:GetStackCount() < 1 then
		self:Destroy()
	end
end
function modifier_bristleback_warpath_custom_buff:OnStackCountChanged(old)
	if not IsServer() then return end
	local owner = self:GetParent()
	if self:GetStackCount() == 0 then
		owner:RemoveModifierByName("modifier_bristleback_warpath_custom_particles")
	else
		if not owner:HasModifier("modifier_bristleback_warpath_custom_particles") then
			owner:AddNewModifier(owner, self:GetAbility(), "modifier_bristleback_warpath_custom_particles", {})
		else
			local ambientMod = owner:FindModifierByName("modifier_bristleback_warpath_custom_particles")
			if ambientMod and ambientMod.amb_pfx then
				ParticleManager:SetParticleControl(ambientMod.amb_pfx, 5, Vector(self:GetStackCount(), 0, 0))
			end
		end
	end
end
function modifier_bristleback_warpath_custom_buff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_TOOLTIP,

		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_EVENT_ON_TAKEDAMAGE,
		MODIFIER_PROPERTY_MODEL_SCALE,
	}
end
function modifier_bristleback_warpath_custom_buff:OnTakeDamage(params)
	if not IsServer() then return end
	local caster = self:GetCaster()
	local parent = self:GetParent()

	if params.attacker ~= parent then return end
	if params.unit == parent then return end
	if not params.unit:IsHero() or not params.unit:IsCreep() then return end

	local lifesteal_pct = self:GetAbility():GetSpecialValueFor("lifesteal_pct_per_stack") * self:GetStackCount()
	local lifesteal = params.damage * lifesteal_pct / 100
	if params.unit:IsCreep() then
		lifesteal = lifesteal * 0.4 --40% lifesteal for creeps
	end

	parent:HealWithParams(lifesteal, self:GetAbility(), true, true, caster, true)

	local lifesteal_fx = ParticleManager:CreateParticle("particles/items3_fx/octarine_core_lifesteal.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(lifesteal_fx, 0, caster:GetAbsOrigin())
end

function modifier_bristleback_warpath_custom_buff:GetModifierMoveSpeedBonus_Percentage()
    if self:GetAbility() then return self:GetAbility():GetSpecialValueFor("move_speed_per_stack") * self:GetStackCount() end
end

function modifier_bristleback_warpath_custom_buff:GetModifierBonusStats_Strength()
	if not self:GetAbility() then return end
	if self.str_lock then return end
    local str_ptc = self:GetAbility():GetSpecialValueFor("str_ptc_per_stack") * self:GetStackCount()

	self.str_lock = true
	local str = self:GetCaster():GetStrength()
	self.str_lock = false

	return str_ptc * str / 100
end

function modifier_bristleback_warpath_custom_buff:OnTooltip()
    local str_ptc = self:GetAbility():GetSpecialValueFor("str_ptc_per_stack") * self:GetStackCount()
	local str = self:GetCaster():GetStrength()

	return str_ptc * str / 100
end

function modifier_bristleback_warpath_custom_buff:GetModifierModelScale()
    return self:GetStackCount() * 5
end


modifier_bristleback_warpath_custom_particles = modifier_bristleback_warpath_custom_particles or class({})
function modifier_bristleback_warpath_custom_particles:IsHidden() return true end
function modifier_bristleback_warpath_custom_particles:IsPurgable() return false end
function modifier_bristleback_warpath_custom_particles:GetEffectName()
	return "particles/units/heroes/hero_bristleback/bristleback_warpath_dust.vpcf"
end
function modifier_bristleback_warpath_custom_particles:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end
function modifier_bristleback_warpath_custom_particles:OnCreated(kv)
	if not IsServer() then return end
	local particle_name = ParticleManager:GetParticleReplacement("particles/units/heroes/hero_bristleback/bristleback_warpath.vpcf", self:GetCaster())

	self.amb_pfx = ParticleManager:CreateParticle(particle_name, PATTACH_POINT_FOLLOW, self:GetParent())
	ParticleManager:SetParticleControlEnt(self.amb_pfx, 3, self:GetCaster(), PATTACH_POINT_FOLLOW, "attach_attack1", self:GetCaster():GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(self.amb_pfx, 4, self:GetCaster(), PATTACH_POINT_FOLLOW, "attach_attack2", self:GetCaster():GetAbsOrigin(), true)
	ParticleManager:SetParticleControl(self.amb_pfx, 5, Vector(1, 0, 0))
	self:AddParticle(self.amb_pfx, false, false, -1, false, false)
end


modifier_bristleback_warpath_custom_ignore = modifier_bristleback_warpath_custom_ignore or class({})
function modifier_bristleback_warpath_custom_ignore:IsHidden() return true end
function modifier_bristleback_warpath_custom_ignore:IsPurgable() return false end
function modifier_bristleback_warpath_custom_ignore:RemoveOnDeath() return false end
