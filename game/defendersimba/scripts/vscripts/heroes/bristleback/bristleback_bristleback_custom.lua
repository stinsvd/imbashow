LinkLuaModifier("modifier_bristleback_bristleback_custom", "heroes/bristleback/bristleback_bristleback_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_bristleback_bristleback_custom_active", "heroes/bristleback/bristleback_bristleback_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_bristleback_bristleback_custom_spray", "heroes/bristleback/bristleback_bristleback_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_bristleback_bristleback_custom_taunt", "heroes/bristleback/bristleback_bristleback_custom", LUA_MODIFIER_MOTION_NONE)


bristleback_bristleback_custom = bristleback_bristleback_custom or class({})
function bristleback_bristleback_custom:GetIntrinsicModifierName()
	return "modifier_bristleback_bristleback_custom"
end
function bristleback_bristleback_custom:GetBehavior()
	local caster = self:GetCaster()
	if caster:HasScepter() and caster:GetModifierStackCount("modifier_bristleback_bristleback_custom", caster) > 0 and not caster:HasModifier("modifier_bristleback_bristleback_custom_active") then
		return DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_IMMEDIATE
	end
	return DOTA_ABILITY_BEHAVIOR_PASSIVE
end
function bristleback_bristleback_custom:GetAOERadius()
	if self:GetCaster():HasScepter() then
		return self:GetSpecialValueFor("taunt_radius")
	end
end
function bristleback_bristleback_custom:OnSpellStart()
	local caster = self:GetCaster()
	local taunt_radius = self:GetSpecialValueFor("taunt_radius")
	local taunt_duration = self:GetSpecialValueFor("taunt_duration")
	local goo_radius = self:GetSpecialValueFor("goo_radius")
	local mod = caster:FindModifierByName("modifier_bristleback_bristleback_custom")

	if mod:GetStackCount() == 0 then return end

	caster:StartGesture(ACT_DOTA_CAST_ABILITY_3)
	caster:EmitSound("Hero_Bristleback.Bristleback.Active")

	caster:AddNewModifier(caster, self, "modifier_bristleback_bristleback_custom_active", {goo_radius = goo_radius}):SetStackCount(mod:GetStackCount())

	mod:SetStackCount(0)

	local enemies = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, taunt_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HEROES_AND_CREEPS, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
	for _, enemy in pairs(enemies) do
		enemy:AddNewModifier(caster, self, "modifier_bristleback_bristleback_custom_taunt", {duration = taunt_duration * (1 - enemy:GetStatusResistance())})
	end
end

function bristleback_bristleback_custom:AddStack()
	local caster = self:GetCaster()
	local max_stacks = self:GetSpecialValueFor("max_stacks")
	local stacks = caster:FindModifierByName("modifier_bristleback_bristleback_custom")
	if stacks and stacks:GetStackCount() < max_stacks then
		stacks:IncrementStackCount()
	end
end


modifier_bristleback_bristleback_custom = modifier_bristleback_bristleback_custom or class({})
function modifier_bristleback_bristleback_custom:IsHidden() return (self:GetStackCount() == 0) or not self:GetCaster():HasScepter() end
function modifier_bristleback_bristleback_custom:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
	}
end
function modifier_bristleback_bristleback_custom:GetModifierIncomingDamage_Percentage(params)
	if not IsServer() then return end
	local ability = self:GetAbility()
	if not ability then return end
	local caster = self:GetCaster()
	local parent = self:GetParent()
	local parentPos = parent:GetAbsOrigin()
	if parent:PassivesDisabled() then return end
	if bit.band(params.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) == DOTA_DAMAGE_FLAG_HPLOSS then return end

	local forwardVector = parent:GetForwardVector()
	local forwardAngle = math.deg(math.atan2(forwardVector.x, forwardVector.y))

	local reverseEnemyVector = (parentPos - params.attacker:GetAbsOrigin()):Normalized()
	local reverseEnemyAngle = math.deg(math.atan2(reverseEnemyVector.x, reverseEnemyVector.y))

	local difference = math.abs(forwardAngle - reverseEnemyAngle)
	local back_angle = ability:GetSpecialValueFor("back_angle")
	local side_angle = ability:GetSpecialValueFor("side_angle")
	local isBack = parent:HasModifier("modifier_bristleback_bristleback_custom_active") or (difference <= back_angle) or (difference >= (360 - back_angle))
	local isSide = (difference <= side_angle) or (difference >= (360 - side_angle))

	if isBack then
		local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_bristleback/bristleback_back_dmg.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
		ParticleManager:SetParticleControlEnt(particle, 0, caster, PATTACH_ABSORIGIN_FOLLOW, nil, caster:GetAbsOrigin(), true)
		ParticleManager:SetParticleControlEnt(particle, 1, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parentPos, true)
		ParticleManager:ReleaseParticleIndex(particle)

		local particle2 = ParticleManager:CreateParticle("particles/units/heroes/hero_bristleback/bristleback_back_lrg_dmg.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
		ParticleManager:SetParticleControlEnt(particle2, 0, caster, PATTACH_ABSORIGIN_FOLLOW, nil, caster:GetAbsOrigin(), true)
		ParticleManager:SetParticleControlEnt(particle2, 1, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parentPos, true)
		ParticleManager:ReleaseParticleIndex(particle2)

		parent:EmitSound("Hero_Bristleback.Bristleback")

		if bit.band(params.damage_flags, DOTA_DAMAGE_FLAG_REFLECTION) ~= DOTA_DAMAGE_FLAG_REFLECTION then
			local goo_radius = self:GetAbility():GetSpecialValueFor("goo_radius")
			local quillSpray = parent:FindAbilityByName("bristleback_quill_spray_custom")
			if goo_radius > 0 then
				quillSpray = parent:FindAbilityByName("bristleback_viscous_nasal_goo_custom")
			end
			if quillSpray and quillSpray:IsTrained() then
				self:Spray(params.damage)
			end
		end

		return ability:GetSpecialValueFor("back_damage_reduction") * (-1)
	elseif isSide then
		local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_bristleback/bristleback_side_dmg.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
		ParticleManager:SetParticleControlEnt(particle, 0, caster, PATTACH_ABSORIGIN_FOLLOW, nil, caster:GetAbsOrigin(), true)
		ParticleManager:SetParticleControlEnt(particle, 1, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parentPos, true)
		ParticleManager:ReleaseParticleIndex(particle)

		return ability:GetSpecialValueFor("side_damage_reduction") * (-1)
	end

	return 0
end

function modifier_bristleback_bristleback_custom:Spray(damage)
	local parent = self:GetParent()
	local quill_release_threshold = self:GetAbility():GetSpecialValueFor("quill_release_threshold")

	self.accDamage = (self.accDamage or 0) + damage

	if self.accDamage >= quill_release_threshold then
		local delta = math.floor(self.accDamage / quill_release_threshold)

		local spray = parent:AddNewModifier(parent, self:GetAbility(), "modifier_bristleback_bristleback_custom_spray", {})
		if spray then
			spray:SetStackCount(delta)
		end

		self.accDamage = self.accDamage - (delta * quill_release_threshold)
	end
end


modifier_bristleback_bristleback_custom_spray = modifier_bristleback_bristleback_custom_spray or class({})
function modifier_bristleback_bristleback_custom_spray:IsHidden() return true end
function modifier_bristleback_bristleback_custom_spray:IsPurgable() return false end
function modifier_bristleback_bristleback_custom_spray:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end
function modifier_bristleback_bristleback_custom_spray:OnCreated()
	if not IsServer() then return end
	self.goo_radius = self:GetAbility():GetSpecialValueFor("goo_radius")
	self:OnRefresh()
	self:OnIntervalThink()
	self:StartIntervalThink(self:GetAbility():GetSpecialValueFor("quill_release_interval"))
end
function modifier_bristleback_bristleback_custom_spray:OnRefresh()
	self:IncrementStackCount()
end
function modifier_bristleback_bristleback_custom_spray:OnIntervalThink()
	if not IsServer() then return end
	self:DecrementStackCount()

	local caster = self:GetCaster()
	local spray = caster:FindAbilityByName("bristleback_quill_spray_custom")
	if self.goo_radius > 0 then
		spray = caster:FindAbilityByName("bristleback_viscous_nasal_goo_custom")
	end

	if spray and spray:IsTrained() then
		if self.goo_radius > 0 then
			spray:OnSpellStart(false, false, nil, self.goo_radius)
		else
			spray:OnSpellStart()
		end

		local warpath = caster:FindAbilityByName("bristleback_warpath_custom")
		if warpath and warpath:IsTrained() then
			warpath:AddStack(true)
		end
	end
	if self:GetStackCount() == 0 then
		self:Destroy()
	end
end


modifier_bristleback_bristleback_custom_active = modifier_bristleback_bristleback_custom_active or class({})
function modifier_bristleback_bristleback_custom_active:IsHidden() return true end
function modifier_bristleback_bristleback_custom_active:OnCreated(kv)
	if not IsServer() then return end
	self.delay = true
	self.goo_radius = kv.goo_radius
	self:StartIntervalThink(self:GetAbility():GetSpecialValueFor("delay"))
end
function modifier_bristleback_bristleback_custom_active:OnIntervalThink()
	if not IsServer() then return end
	if self.delay then
		self.delay = false

		self:StartIntervalThink(self:GetAbility():GetSpecialValueFor("spray_interval"))
		return
	end

	local caster = self:GetCaster()
	local spray = caster:FindAbilityByName("bristleback_quill_spray_custom")
	if self.goo_radius > 0 then
		spray = caster:FindAbilityByName("bristleback_viscous_nasal_goo_custom")
	end

	if spray and spray:IsTrained() then
		spray:OnSpellStart(false, true, nil)
	end

	self:DecrementStackCount()

	if self:GetStackCount() == 0 then
		self:Destroy()
	end
end


modifier_bristleback_bristleback_custom_taunt = modifier_bristleback_bristleback_custom_taunt or class({})
function modifier_bristleback_bristleback_custom_taunt:IsHidden() return true end
function modifier_bristleback_bristleback_custom_taunt:IsPurgable() return false end
function modifier_bristleback_bristleback_custom_taunt:GetStatusEffectName()
	return "particles/status_fx/status_effect_beserkers_call.vpcf"
end
function modifier_bristleback_bristleback_custom_taunt:OnCreated(kv)
	if not IsServer() then return end
	OrderAttackTarget(self:GetParent(), self:GetCaster())
	self:GetParent():MoveToTargetToAttack(self:GetCaster())

	self:StartIntervalThink(FrameTime())
end
function modifier_bristleback_bristleback_custom_taunt:OnRefresh(kv)
	OrderAttackTarget(self:GetParent(), self:GetCaster())
	self:GetParent():MoveToTargetToAttack(self:GetCaster())
end
function modifier_bristleback_bristleback_custom_taunt:OnIntervalThink()
	if not IsServer() then return end
	local caster = self:GetCaster()
	if not caster or caster:IsNull() or not caster:IsAlive() then
		self:Destroy()
		return
	end
	OrderAttackTarget(self:GetParent(), caster)
end
function modifier_bristleback_bristleback_custom_taunt:OnDestroy()
	if not IsServer() then return end
	self:GetParent():SetForceAttackTarget(nil)
end
function modifier_bristleback_bristleback_custom_taunt:CheckState()
	return {
		[MODIFIER_STATE_TAUNTED] = true,
	}
end



function IsFacingBack(caster, attacker, back_angle)
	if attacker:IsBuilding() then return false end

	local forwardVector = caster:GetForwardVector()
	local forwardAngle = math.deg(math.atan2(forwardVector.x, forwardVector.y))

	local reverseEnemyVector = (caster:GetAbsOrigin() - attacker:GetAbsOrigin()):Normalized()
	local reverseEnemyAngle = math.deg(math.atan2(reverseEnemyVector.x, reverseEnemyVector.y))

	local difference = math.abs(forwardAngle - reverseEnemyAngle)

	if (difference <= back_angle) or (difference >= (360 - back_angle)) then
		return true
	end

	return false
end
