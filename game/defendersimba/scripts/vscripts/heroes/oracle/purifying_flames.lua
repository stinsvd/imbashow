----------------------
-- Purifying Flames --
----------------------
LinkLuaModifier("modifier_orcl_purifying_flames_buff", "heroes/oracle/purifying_flames", LUA_MODIFIER_MOTION_NONE)


orcl_purifying_flames = orcl_purifying_flames or class({})
function orcl_purifying_flames:GetAbilityTextureName()
	if self:GetCaster():HasModifier("modifier_oracle_immortal_head") then
		return "oracle/immortal_head_ti10/oracle_purifying_flames_immortal"
	end
	return "oracle_purifying_flames"
end
function orcl_purifying_flames:OnSpellStart(newTarget)
	if not IsServer() then return end
	local caster = self:GetCaster()
	local target = newTarget or self:GetCursorTarget()
	local damage = self:GetSpecialValueFor("damage")
	local duration = self:GetSpecialValueFor("duration")
	local dmg_radius = self:GetSpecialValueFor("dmg_radius")
	local radius_dmg_pct = self:GetSpecialValueFor("radius_dmg_pct")
	local isEnemy = target:GetTeamNumber() ~= caster:GetTeamNumber() and not target:HasModifier("modifier_orcl_false_promise_buff")
	local damage_flag = DOTA_DAMAGE_FLAG_NONE
	
	target:EmitSound("Hero_Oracle.PurifyingFlames")
	
	local pf_cast = ParticleManager:CreateParticle("particles/units/heroes/hero_oracle/oracle_purifyingflames_cast.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(pf_cast, 1, caster, PATTACH_POINT_FOLLOW, "attach_attack1", caster:GetAbsOrigin(), true)
	ParticleManager:ReleaseParticleIndex(pf_cast)
	
	if isEnemy then
		if target:TriggerSpellAbsorb(self) then return end
	else
--		damage_flag = damage_flag + DOTA_DAMAGE_FLAG_NON_LETHAL
	end
	
	target:EmitSound("Hero_Oracle.PurifyingFlames.Damage")
	
	local pf = ParticleManager:CreateParticle("particles/units/heroes/hero_oracle/oracle_purifyingflames_hit.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
	ParticleManager:SetParticleControlEnt(pf, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:ReleaseParticleIndex(pf)
	
	local damadeTable = {
		attacker = caster,
		victim = target,
		ability = self,
		damage = damage,
		damage_type = self:GetAbilityDamageType(),
		damage_flags = damage_flag,
	}
	
	if dmg_radius > 0 then
		local units = FindUnitsInRadius(caster:GetTeamNumber(), target:GetAbsOrigin(), nil, dmg_radius, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_HEROES_AND_CREEPS, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, false)
		for _, unit in pairs(units) do
			if unit ~= target then
		--		unit:AddNewModifier(caster, self, "modifier_orcl_purifying_flames_buff", {duration = duration, damage = (damage * (1 + caster:GetSpellAmplification(false)) * (radius_dmg_pct / 100))})
				damadeTable.victim = unit
				ApplyDamage(damadeTable)
			end
		end
	end
	
	target:AddNewModifier(caster, self, "modifier_orcl_purifying_flames_buff", {duration = duration, damage = damage * (1 + caster:GetSpellAmplification(false))})
	damadeTable.victim = target
	ApplyDamage(damadeTable)
end

-- Purifying Flames Buff --
modifier_orcl_purifying_flames_buff = modifier_orcl_purifying_flames_buff or class({})
function modifier_orcl_purifying_flames_buff:IsDebuff() return false end
--function modifier_orcl_purifying_flames_buff:IgnoreTenacity() return true end
--function modifier_orcl_purifying_flames_buff:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end
function modifier_orcl_purifying_flames_buff:GetTexture() return "oracle_purifying_flames" end
function modifier_orcl_purifying_flames_buff:OnCreated(kv)
	if not IsServer() then return end
	self.tick_rate = FrameTime()	--self:GetAbility():GetSpecialValueFor("tick_rate")
	self.stacks = {}
	self:OnRefresh(kv)
	
	local flames_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_oracle/oracle_purifyingflames.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster())
	ParticleManager:SetParticleControlEnt(flames_pfx, 0, self:GetParent(), PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), true)
	self:AddParticle(flames_pfx, false, false, -1, false, false)
	
	self:StartIntervalThink(self.tick_rate)
end
function modifier_orcl_purifying_flames_buff:OnRefresh(kv)
	if not IsServer() then return end
	local dd = kv.damage
	--[[
	local tick_rate = self:GetAbility():GetSpecialValueFor("tick_rate")
	if self.tick_rate ~= tick_rate then
		self.tick_rate = tick_rate
		self:StartIntervalThink(self.tick_rate)
	end
	]]
	local heal_from_dd = self:GetAbility():GetSpecialValueFor("heal_from_dd")
	self.heal_radius = self:GetAbility():GetSpecialValueFor("heal_radius")
	self.radius_heal_pct = self:GetAbility():GetSpecialValueFor("radius_heal_pct")
	self.heal_per_tick = dd * (heal_from_dd / 100)
	
	self:IncrementStackCount()
	table.insert(self.stacks, {GameRules:GetGameTime(), kv.duration})
end
function modifier_orcl_purifying_flames_buff:OnIntervalThink()
	if not IsServer() then return end
	self:HealEffect(false)
	
	local currentTime = GameRules:GetGameTime()
	for k, v in pairs(self.stacks) do
		if currentTime >= v[1] + v[2] then
			self.stacks[k] = nil
			self:DecrementStackCount()
		end
	end
end
function modifier_orcl_purifying_flames_buff:HealEffect(removed, healEfficiency)
	if not IsServer() then return end
	local ability = self:GetAbility()
	if not ability then return end
	local caster = self:GetCaster()
	local target = self:GetParent()
	local heal_per_tick = (self.heal_per_tick * self:GetStackCount()) / self:GetDuration() * self.tick_rate
	local heal = (removed and heal_per_tick * self:GetRemainingTime() or heal_per_tick) * ((healEfficiency or 100) / 100)
	target:HealWithParams(heal, ability, false, true, caster, false)
	self.numbersThink = (self.numbersThink or 0) + self.tick_rate
	if self.numbersThink >= 0.5 then
		self.numbersThink = 0
		local numbers = (self.heal_per_tick * self:GetStackCount()) / self:GetDuration() * 0.5
		SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, target, numbers, nil)
	end
	
	if self.heal_radius > 0 then
		heal = heal * (self.radius_heal_pct / 100)
		local units = FindUnitsInRadius(target:GetTeamNumber(), target:GetAbsOrigin(), nil, self.heal_radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HEROES_AND_CREEPS, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, false)
		for _, unit in pairs(units) do
			if unit ~= target then
				unit:HealWithParams(heal, ability, false, true, caster, false)
				SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, unit, heal, nil)
			end
		end
	end
	if removed then
		self:Destroy()
	end
end
