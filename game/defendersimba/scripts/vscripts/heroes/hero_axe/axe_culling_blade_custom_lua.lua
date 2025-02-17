LinkLuaModifier("modifier_axe_culling_blade_custom_lua", "heroes/hero_axe/axe_culling_blade_custom_lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_axe_culling_blade_refresh_counter", "heroes/hero_axe/axe_culling_blade_custom_lua", LUA_MODIFIER_MOTION_NONE)

axe_culling_blade_custom_lua = axe_culling_blade_custom_lua or class({})
function axe_culling_blade_custom_lua:Precache(context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_axe.vsndevts", context)
	PrecacheResource("particle", "particles/units/heroes/hero_axe/axe_culling_blade_kill.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_axe/axe_culling_blade.vpcf", context)
end
function axe_culling_blade_custom_lua:GetIntrinsicModifierName() return "modifier_axe_culling_blade_custom_lua" end
function axe_culling_blade_custom_lua:GetAOERadius() return self:GetSpecialValueFor("radius") end
function axe_culling_blade_custom_lua:OnAbilityPhaseStart()
	self:GetCaster():StartGesture(ACT_DOTA_CAST_ABILITY_4)
end
function axe_culling_blade_custom_lua:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local casterPos = caster:GetAbsOrigin()
	local damage = 0
	if caster.GetStrength then
		damage = caster:GetStrength() * self:GetSpecialValueFor("str_to_damage_pct") / 100
	end
	local radius = self:GetSpecialValueFor("radius")
	local damageTable = {
		victim = target,
		attacker = caster,
		ability = self,
		damage = damage,
		damage_type = self:GetAbilityDamageType(),
	}

	local target_killed = false
	local targets = {target}
	if caster:HasScepter() then
		targets = FindUnitsInRadius(caster:GetTeamNumber(), target:GetAbsOrigin(), nil, radius, self:GetAbilityTargetTeam(), self:GetAbilityTargetType(), DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	end
	for _, enemy in pairs(targets) do
		if enemy:GetHealth() < damage and not (enemy:GetUnitName() == "npc_dota_roshan" or enemy:GetUnitName() == "npc_dota_miniboss") then
			enemy:Kill(self, caster)
		else
			damageTable.victim = enemy
			ApplyDamage(damageTable)
		end
	--	SendOverheadEventMessage(nil, OVERHEAD_ALERT_DAMAGE, enemy, damage, nil)
		if not enemy:IsAlive() then
			target_killed = true
			local count
			if enemy:IsHero() then
				count = self:GetSpecialValueFor("str_per_hero")
			else
				count = self:GetSpecialValueFor("str_per_creep")
			end

			local mod = caster:FindModifierByName("modifier_axe_culling_blade_custom_lua")
			for _ = 1, count do
				mod:IncrementStackCount()
			end

			local target_location = enemy:GetAbsOrigin()
			local direction = (target_location - casterPos):Normalized()
			local pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_axe/axe_culling_blade_kill.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
			ParticleManager:SetParticleControlEnt(pfx, 0, enemy, PATTACH_ABSORIGIN_FOLLOW, nil, enemy:GetAbsOrigin(), true)
			ParticleManager:SetParticleControl(pfx, 4, target_location)
			ParticleManager:SetParticleControlForward(pfx, 3, direction)
			ParticleManager:SetParticleControlForward(pfx, 4, direction)
			ParticleManager:ReleaseParticleIndex(pfx)
		else
			local pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_axe/axe_culling_blade.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
			ParticleManager:SetParticleControlEnt(pfx, 0, enemy, PATTACH_ABSORIGIN_FOLLOW, nil, enemy:GetAbsOrigin(), true)
			ParticleManager:ReleaseParticleIndex(pfx)
		end
	end

	if target_killed then
		EmitSoundOnLocationWithCaster(casterPos, "Hero_Axe.Culling_Blade_Success", caster)
	else
		EmitSoundOnLocationWithCaster(casterPos, "Hero_Axe.Culling_Blade_Fail", caster)
	end
end


modifier_axe_culling_blade_custom_lua = modifier_axe_culling_blade_custom_lua or class({})
function modifier_axe_culling_blade_custom_lua:IsHidden() return false end
function modifier_axe_culling_blade_custom_lua:IsPurgable() return false end
function modifier_axe_culling_blade_custom_lua:IsDebuff() return false end
function modifier_axe_culling_blade_custom_lua:RemoveOnDeath() return false end
function modifier_axe_culling_blade_custom_lua:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_TOOLTIP
	}
end
function modifier_axe_culling_blade_custom_lua:GetModifierBonusStats_Strength()
	return self:GetStackCount()
end
function modifier_axe_culling_blade_custom_lua:OnTooltip()
	return self:GetModifierBonusStats_Strength()
end


modifier_axe_culling_blade_refresh_counter = modifier_axe_culling_blade_refresh_counter or class({})
function modifier_axe_culling_blade_refresh_counter:IsHidden() return true end
function modifier_axe_culling_blade_refresh_counter:IsPurgable() return false end
function modifier_axe_culling_blade_refresh_counter:RemoveOnDeath() return false end
function modifier_axe_culling_blade_refresh_counter:IsDebuff() return false end
function modifier_axe_culling_blade_refresh_counter:OnCreated()
	if not IsServer() then return end
	self:SetStackCount(self:GetAbility():GetSpecialValueFor("counter_to_refresh"))
end
function modifier_axe_culling_blade_refresh_counter:OnRefresh()
	if not IsServer() then return end
	self:DecrementStackCount()
	if self:GetStackCount() == 0 then
		self:GetAbility():EndCooldown()
		self:SetStackCount(self:GetAbility():GetSpecialValueFor("counter_to_refresh"))
	end
end
