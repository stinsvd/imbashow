LinkLuaModifier("modifier_bristleback_quill_spray_custom", "heroes/bristleback/bristleback_quill_spray_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_bristleback_quill_spray_custom_armor", "heroes/bristleback/bristleback_quill_spray_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_bb_quill_spray_berserk", "heroes/bristleback/bristleback_quill_spray_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_bristleback_warpath_custom_ignore", "heroes/bristleback/bristleback_warpath_custom", LUA_MODIFIER_MOTION_NONE)


bristleback_quill_spray_custom = bristleback_quill_spray_custom or class({})
function bristleback_quill_spray_custom:Precache(context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_bristleback.vsndevts", context)
	PrecacheResource("particle", "particles/units/heroes/hero_bristleback/bristleback_quill_spray.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_bristleback/bristleback_quill_spray_impact.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_bristleback/bristleback_quill_spray_hit.vpcf", context)
end
function bristleback_quill_spray_custom:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end
function bristleback_quill_spray_custom:OnSpellStart(ignore_warpath, ignore_bristleback, newLoc)
	if not IsServer() then return end
	local caster = self:GetCaster()
	local source = newLoc or caster:GetAbsOrigin()
	local radius = self:GetSpecialValueFor("radius")
	local stack_duration = self:GetSpecialValueFor("duration")
	local base_damage = self:GetSpecialValueFor("quill_str_base_damage")
	local bonus_quill_str_stack_damage = self:GetSpecialValueFor("bonus_quill_str_stack_damage")
	local stack_damage = self:GetSpecialValueFor("quill_str_stack_damage") + (caster:GetModifierStackCount("modifier_bristleback_quill_spray_custom", caster) * bonus_quill_str_stack_damage)
	if caster.GetStrength then
		base_damage = caster:GetStrength() * base_damage / 100
		stack_damage = caster:GetStrength() * stack_damage / 100
	end

	if not newLoc then
		caster:FadeGesture(ACT_DOTA_CAST_ABILITY_2)
		caster:StartGesture(ACT_DOTA_CAST_ABILITY_2)
	end

	local damage_table = {
		victim = nil,
		attacker = caster,
		ability = self,
		damage = base_damage,
		damage_type = DAMAGE_TYPE_PHYSICAL,
	}

	local spray_pfx = ParticleManager:GetParticleReplacement("particles/units/heroes/hero_bristleback/bristleback_quill_spray.vpcf", caster)
	--[[
	local spray_impact_pfx = ParticleManager:GetParticleReplacement("particles/units/heroes/hero_bristleback/bristleback_quill_spray_impact.vpcf", caster)
	local enemies = FindUnitsInRadius(caster:GetTeamNumber(), source, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HEROES_AND_CREEPS, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
	for _, enemy in pairs(enemies) do
		local stack = enemy:GetModifierStackCount("modifier_bristleback_quill_spray_custom", caster)

		enemy:AddNewModifier(caster, self, "modifier_bristleback_quill_spray_custom", {duration = stack_duration * (1 - enemy:GetStatusResistance())})

		local impact_pfx = ParticleManager:CreateParticle(spray_impact_pfx, PATTACH_ABSORIGIN, enemy)
		ParticleManager:ReleaseParticleIndex(impact_pfx)

		EmitSoundOnLocationWithCaster(enemy:GetAbsOrigin(), "Hero_Bristleback.QuillSpray.Target", caster)

		local armorMod
		if enemy:IsCreep() then
			armorMod = enemy:AddNewModifier(damage_table.attacker, self, "modifier_bristleback_quill_spray_custom_armor", {})
		end

		damage_table.victim = enemy
		damage_table.damage = base_damage + (stack * stack_damage)
		ApplyDamage(damage_table)

		if armorMod then
			armorMod:Destroy()
		end
	end
	]]
	
	local projectile = {
		Source = caster,
		Ability = self,
		EffectName = nil,
		vSpawnOrigin = source,
		fDistance = 1,
		fStartRadius = 1,
		fEndRadius = radius,
		bHasFrontalCone = false,
		bReplaceExisting = false,
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetType = DOTA_UNIT_TARGET_HEROES_AND_CREEPS,
		iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		fExpireTime = GameRules:GetGameTime() + 5,
		bDeleteOnHit = false,
		vVelocity = caster:GetForwardVector() * 2.400 * (Vector(1, 1, 0)),
		bProvidesVision = false,
		ExtraData = {
			base_damage = base_damage,
			stack_damage = stack_damage,
			stack_duration = stack_duration,
		}
	}
	ProjectileManager:CreateLinearProjectile(projectile)

	if bonus_quill_str_stack_damage > 0 then
		caster:AddNewModifier(caster, self, "modifier_bb_quill_spray_berserk", {}):IncrementStackCount()
	end
	if ignore_warpath then
		caster:AddNewModifier(caster, self, "modifier_bristleback_warpath_custom_ignore", {duration = FrameTime()})
	end
	if caster:HasScepter() then
		if not ignore_bristleback then
			local bb = caster:FindAbilityByName("bristleback_bristleback_custom")
			if bb and bb:IsTrained() and bb:GetSpecialValueFor("goo_radius") <= 0 then
				bb:AddStack()
			end
		end
	end

	local cast_pfx = ParticleManager:CreateParticle(spray_pfx, PATTACH_WORLDORIGIN, caster)
	ParticleManager:SetParticleControl(cast_pfx, 0, source)
	ParticleManager:ReleaseParticleIndex(cast_pfx)

	EmitSoundOnLocationWithCaster(source, "Hero_Bristleback.QuillSpray.Cast", caster)
end
function bristleback_quill_spray_custom:OnProjectileHit_ExtraData(target, loc, data)
	if not IsServer() then return end
	if target then
		local caster = self:GetCaster()
		local spray_impact_pfx = ParticleManager:GetParticleReplacement("particles/units/heroes/hero_bristleback/bristleback_quill_spray_impact.vpcf", caster)
		local stack = target:GetModifierStackCount("modifier_bristleback_quill_spray_custom", caster)

		target:AddNewModifier(caster, self, "modifier_bristleback_quill_spray_custom", {duration = data.stack_duration * (1 - target:GetStatusResistance())})

		local impact_pfx = ParticleManager:CreateParticle(spray_impact_pfx, PATTACH_ABSORIGIN, target)
		ParticleManager:ReleaseParticleIndex(impact_pfx)

		EmitSoundOnLocationWithCaster(target:GetAbsOrigin(), "Hero_Bristleback.QuillSpray.Target", caster)

		local armorMod
		if target:IsCreep() then
			armorMod = target:AddNewModifier(caster, self, "modifier_bristleback_quill_spray_custom_armor", {})
		end

		ApplyDamage({
			victim = target,
			attacker = caster,
			ability = self,
			damage = data.base_damage + (stack * data.stack_damage),
			damage_type = DAMAGE_TYPE_PHYSICAL,
		})

		if armorMod then
			armorMod:Destroy()
		end
	end
end


modifier_bristleback_quill_spray_custom = modifier_bristleback_quill_spray_custom or class({})
function modifier_bristleback_quill_spray_custom:IsHidden() return false end
function modifier_bristleback_quill_spray_custom:IsDebuff() return true end
function modifier_bristleback_quill_spray_custom:IsPurgable() return false end
function modifier_bristleback_quill_spray_custom:DestroyOnExpire() return false end
function modifier_bristleback_quill_spray_custom:GetEffectName()
	return "particles/units/heroes/hero_bristleback/bristleback_quill_spray_hit.vpcf"
end
function modifier_bristleback_quill_spray_custom:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end
function modifier_bristleback_quill_spray_custom:OnCreated()
	if not IsServer() then return end
	self.stacks = {}
	self:OnRefresh()
	self:StartIntervalThink(FrameTime())
end
function modifier_bristleback_quill_spray_custom:OnRefresh()
	local caster = self:GetCaster()
	self.base_damage = self:GetAbility():GetSpecialValueFor("quill_str_base_damage")
	self.stack_damage = self:GetAbility():GetSpecialValueFor("quill_str_stack_damage")
	if caster.GetStrength then
		self.base_damage = caster:GetStrength() * self.base_damage / 100
		self.stack_damage = caster:GetStrength() * self.stack_damage / 100
	end

	if not IsServer() then return end
	self:IncrementStackCount()
	table.insert(self.stacks, {GameRules:GetGameTime(), self:GetRemainingTime()})
end
function modifier_bristleback_quill_spray_custom:OnIntervalThink()
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
function modifier_bristleback_quill_spray_custom:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_TOOLTIP,
	}
end
function modifier_bristleback_quill_spray_custom:OnTooltip()
	return self.base_damage + self.stack_damage * self:GetStackCount()
end


modifier_bristleback_quill_spray_custom_armor = modifier_bristleback_quill_spray_custom_armor or class({})
function modifier_bristleback_quill_spray_custom_armor:IsHidden() return true end
function modifier_bristleback_quill_spray_custom_armor:IsPurgable() return false end
function modifier_bristleback_quill_spray_custom_armor:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
	}
end
function modifier_bristleback_quill_spray_custom_armor:GetModifierPhysicalArmorBonus()
	if not IsServer() then return end
	if self.armor_lock then return end

	self.armor_lock = true
	local armor = self:GetParent():GetPhysicalArmorValue(false)
	self.armor_lock = false

	local pierce = self:GetAbility():GetSpecialValueFor("creep_armor_pierce")
	return -(armor * pierce / 100)
end


modifier_bb_quill_spray_berserk = modifier_bb_quill_spray_berserk or class({})
function modifier_bb_quill_spray_berserk:IsHidden() return false end
function modifier_bb_quill_spray_berserk:IsPurgable() return false end
function modifier_bb_quill_spray_berserk:RemoveOnDeath() return false end
function modifier_bb_quill_spray_berserk:OnRefresh()
--	self:IncrementStackCount()
	local bonus_quill_str_stack_damage = self:GetAbility():GetSpecialValueFor("bonus_quill_str_stack_damage")
	self.bonus_damage = bonus_quill_str_stack_damage * self:GetStackCount()
end
function modifier_bb_quill_spray_berserk:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_TOOLTIP,
	}
end
function modifier_bb_quill_spray_berserk:OnTooltip() return self.bonus_damage end
