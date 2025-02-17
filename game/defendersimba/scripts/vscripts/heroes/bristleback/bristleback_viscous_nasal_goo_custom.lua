LinkLuaModifier("modifier_bristleback_viscous_nasal_goo_custom", "heroes/bristleback/bristleback_viscous_nasal_goo_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_bb_viscous_nasal_goo_snot_rocket", "heroes/bristleback/bristleback_viscous_nasal_goo_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_bristleback_warpath_custom_ignore", "heroes/bristleback/bristleback_warpath_custom", LUA_MODIFIER_MOTION_NONE)


bristleback_viscous_nasal_goo_custom = bristleback_viscous_nasal_goo_custom or class({})
function bristleback_viscous_nasal_goo_custom:Precache(context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_bristleback.vsndevts", context)
	PrecacheResource("particle", "particles/units/heroes/hero_bristleback/bristleback_viscous_nasal_goo.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_bristleback/bristleback_viscous_nasal_goo_debuff.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_bristleback/bristleback_viscous_nasal_stack.vpcf", context)
	PrecacheResource("particle", "particles/status_fx/status_effect_goo.vpcf", context)
end
function bristleback_viscous_nasal_goo_custom:OnSpellStart(ignore_warpath, ignore_bristleback, newLoc, newRadius)
	local caster = self:GetCaster()
	local casterPos = newLoc or caster:GetAbsOrigin()
	local radius = newRadius or self:GetSpecialValueFor("radius")
	local goo_speed = self:GetSpecialValueFor("goo_speed")
	local goo_duration = self:GetSpecialValueFor("goo_duration")
	local goo_str_dmg = self:GetSpecialValueFor("goo_str_dmg")
	local info = {
		Target = nil,
		Ability = self,
		Source = nil,
		vSourceLoc = newLoc,
		EffectName = "particles/units/heroes/hero_bristleback/bristleback_viscous_nasal_goo.vpcf",
		iMoveSpeed = goo_speed,
		ExtraData = {
			goo_str_dmg = goo_str_dmg,
			goo_duration = goo_duration,
		}
	}
	if not newLoc then
		info.Source = caster
	end

	local enemies = FindUnitsInRadius(caster:GetTeamNumber(), casterPos, nil, radius, self:GetAbilityTargetTeam(), self:GetAbilityTargetType(), self:GetAbilityTargetFlags(), FIND_ANY_ORDER, false)
	for _, enemy in pairs(enemies) do
		info.Target = enemy
		ProjectileManager:CreateTrackingProjectile(info)
	end

	EmitSoundOnLocationWithCaster(info.vSourceLoc or casterPos, "Hero_Bristleback.ViscousGoo.Cast", caster)

	if ignore_warpath then
		caster:AddNewModifier(caster, self, "modifier_bristleback_warpath_custom_ignore", {duration = FrameTime()})
	end
	if caster:HasScepter() then
		if not ignore_bristleback then
			local bb = caster:FindAbilityByName("bristleback_bristleback_custom")
			if bb and bb:IsTrained() and bb:GetSpecialValueFor("goo_radius") > 0 then
				bb:AddStack()
			end
		end
	end
end
function bristleback_viscous_nasal_goo_custom:OnProjectileHit_ExtraData(target, loc, data)
	if not target then return end
	local caster = self:GetCaster()
	if data.goo_str_dmg > 0 then
		target:AddNewModifier(caster, self, "modifier_bb_viscous_nasal_goo_snot_rocket", {duration = data.goo_duration * (1 - target:GetStatusResistance())})
	else
		target:AddNewModifier(caster, self, "modifier_bristleback_viscous_nasal_goo_custom", {duration = data.goo_duration * (1 - target:GetStatusResistance())})
	end
	EmitSoundOn("Hero_Bristleback.ViscousGoo.Target", target)
end


modifier_bristleback_viscous_nasal_goo_custom = modifier_bristleback_viscous_nasal_goo_custom or class({})
function modifier_bristleback_viscous_nasal_goo_custom:IsHidden() return false end
function modifier_bristleback_viscous_nasal_goo_custom:IsDebuff() return true end
function modifier_bristleback_viscous_nasal_goo_custom:IsPurgable() return true end
function modifier_bristleback_viscous_nasal_goo_custom:GetStatusEffectName() return "particles/status_fx/status_effect_goo.vpcf" end
function modifier_bristleback_viscous_nasal_goo_custom:StatusEffectPriority() return 10 end
function modifier_bristleback_viscous_nasal_goo_custom:OnCreated()
	self:OnRefresh()

	if not IsServer() then return end
	local amb_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_bristleback/bristleback_viscous_nasal_goo_debuff.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster())
	ParticleManager:SetParticleControlEnt(amb_pfx, 0, self:GetParent(), PATTACH_ABSORIGIN_FOLLOW, nil, self:GetParent():GetAbsOrigin(), true)
	self:AddParticle(amb_pfx, false, false, -1, false, false)

	self.stacks_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_bristleback/bristleback_viscous_nasal_stack.vpcf", PATTACH_OVERHEAD_FOLLOW, self:GetCaster())
	ParticleManager:SetParticleControlEnt(self.stacks_pfx, 0, self:GetParent(), PATTACH_OVERHEAD_FOLLOW, nil, self:GetParent():GetAbsOrigin(), true)
	ParticleManager:SetParticleControl(self.stacks_pfx, 1, Vector(0, self:GetStackCount(), 0))
	self:AddParticle(self.stacks_pfx, false, false, -1, false, false)
end
function modifier_bristleback_viscous_nasal_goo_custom:OnRefresh()
	self.base_armor = self:GetAbility():GetSpecialValueFor("base_armor")
	self.armor_per_stack = self:GetAbility():GetSpecialValueFor("armor_per_stack")
	self.spray_bonus_damage = self:GetAbility():GetSpecialValueFor("spray_bonus_damage")
	self.stack_limit = self:GetAbility():GetSpecialValueFor("stack_limit")

	if not IsServer() then return end
	self:SetStackCount(math.min(self.stack_limit, self:GetStackCount() + 1))
	if self.stacks_pfx then
		ParticleManager:SetParticleControl(self.stacks_pfx, 1, Vector(0, self:GetStackCount(), 0))
	end
end
function modifier_bristleback_viscous_nasal_goo_custom:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_EVENT_ON_TAKEDAMAGE,
	}
end
function modifier_bristleback_viscous_nasal_goo_custom:GetModifierPhysicalArmorBonus()
	return (self.base_armor + self.armor_per_stack * self:GetStackCount()) * (-1)
end
function modifier_bristleback_viscous_nasal_goo_custom:OnTakeDamage(params)
	if not IsServer() then return end
	local target = params.unit
	local attacker = params.attacker
	if not target then return end
	if not attacker then return end
	if target ~= self:GetParent() then return end
	if not target:IsAlive() then return end
	local inflictor = params.inflictor
	if not inflictor then return end
	if inflictor:GetAbilityName() ~= "bristleback_quill_spray_custom" then return end

	ApplyDamage({
		victim = target,
		attacker = attacker,
		ability = self:GetAbility(),
		damage = self.spray_bonus_damage * self:GetStackCount(),
		damage_type = DAMAGE_TYPE_PHYSICAL,
	})
end


modifier_bb_viscous_nasal_goo_snot_rocket = modifier_bb_viscous_nasal_goo_snot_rocket or class({})
function modifier_bb_viscous_nasal_goo_snot_rocket:IsHidden() return false end
function modifier_bb_viscous_nasal_goo_snot_rocket:IsDebuff() return true end
function modifier_bb_viscous_nasal_goo_snot_rocket:IsPurgable() return true end
function modifier_bb_viscous_nasal_goo_snot_rocket:GetStatusEffectName() return "particles/status_fx/status_effect_goo.vpcf" end
function modifier_bb_viscous_nasal_goo_snot_rocket:StatusEffectPriority() return 10 end
function modifier_bb_viscous_nasal_goo_snot_rocket:OnCreated()
	self.stacks = {}
	self:OnRefresh()

	if not IsServer() then return end
	local amb_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_bristleback/bristleback_viscous_nasal_goo_debuff.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster())
	ParticleManager:SetParticleControlEnt(amb_pfx, 0, self:GetParent(), PATTACH_ABSORIGIN_FOLLOW, nil, self:GetParent():GetAbsOrigin(), true)
	self:AddParticle(amb_pfx, false, false, -1, false, false)

	self.stacks_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_bristleback/bristleback_viscous_nasal_stack.vpcf", PATTACH_OVERHEAD_FOLLOW, self:GetCaster())
	ParticleManager:SetParticleControlEnt(self.stacks_pfx, 0, self:GetParent(), PATTACH_OVERHEAD_FOLLOW, nil, self:GetParent():GetAbsOrigin(), true)
	ParticleManager:SetParticleControl(self.stacks_pfx, 1, Vector(0, self:GetStackCount(), 0))
	self:AddParticle(self.stacks_pfx, false, false, -1, false, false)

	self.interval = FrameTime()
	self:StartIntervalThink(self.interval)
end
function modifier_bb_viscous_nasal_goo_snot_rocket:OnRefresh()
	local caster = self:GetCaster()
	self.base_armor = self:GetAbility():GetSpecialValueFor("base_armor")
	self.armor_per_stack = self:GetAbility():GetSpecialValueFor("armor_per_stack")
	self.goo_str_dmg = self:GetAbility():GetSpecialValueFor("goo_str_dmg")
	if caster.GetStrength then
		self.goo_str_dmg = caster:GetStrength() * self.goo_str_dmg / 100
	end
	self.dmg_interval = 0.5

	if not IsServer() then return end
	self:IncrementStackCount()
	table.insert(self.stacks, {GameRules:GetGameTime(), self:GetRemainingTime()})
	if self.stacks_pfx then
		ParticleManager:SetParticleControl(self.stacks_pfx, 1, Vector(0, self:GetStackCount(), 0))
	end
	self.damageTable = {
		attacker = caster,
		victim = self:GetParent(),
		ability = self:GetAbility(),
		damage = self.goo_str_dmg,
		damage_type = DAMAGE_TYPE_PHYSICAL,
	}
end
function modifier_bb_viscous_nasal_goo_snot_rocket:OnIntervalThink()
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
	else
		self.dmgTimer = (self.dmgTimer or 0) + self.interval
		if self.dmgTimer >= self.dmg_interval then
			self.dmgTimer = 0
			self.damageTable.damage = (self.goo_str_dmg * self:GetStackCount()) * self.dmg_interval
			ApplyDamage(self.damageTable)
		end
	end
end
function modifier_bb_viscous_nasal_goo_snot_rocket:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
	}
end
function modifier_bb_viscous_nasal_goo_snot_rocket:GetModifierPhysicalArmorBonus()
	return (self.base_armor + self.armor_per_stack * self:GetStackCount()) * (-1)
end
