------------------
-- Fate's Edict --
------------------
LinkLuaModifier("modifier_orcl_fates_edict_ally", "heroes/oracle/fates_edict", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_orcl_fates_edict_enemy", "heroes/oracle/fates_edict", LUA_MODIFIER_MOTION_NONE)


orcl_fates_edict = orcl_fates_edict or class({})
function orcl_fates_edict:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local duration = self:GetSpecialValueFor("duration")
	local isEnemy = target:GetTeamNumber() ~= caster:GetTeamNumber() and not target:HasModifier("modifier_orcl_false_promise_buff")
	caster:EmitSound("Hero_Oracle.FatesEdict.Cast")
	
	if target ~= caster then
		caster:AddNewModifier(caster, self, "modifier_orcl_fates_edict_ally", {duration = duration})
	end

	if isEnemy then
		if target:TriggerSpellAbsorb(self) then return end
		target:AddNewModifier(caster, self, "modifier_orcl_fates_edict_enemy", {duration = duration * (1 - target:GetStatusResistance())})
	else
		target:AddNewModifier(caster, self, "modifier_orcl_fates_edict_ally", {duration = duration})
	end
	
	target:EmitSound("Hero_Oracle.FatesEdict")
end

-- Fate's Edict Ally
modifier_orcl_fates_edict_ally = modifier_orcl_fates_edict_ally or class({})
function modifier_orcl_fates_edict_ally:IsHidden() return false end
function modifier_orcl_fates_edict_ally:IgnoreTenacity() return true end
function modifier_orcl_fates_edict_ally:IsDebuff() return false end
function modifier_orcl_fates_edict_ally:GetTexture() return "oracle_fates_edict" end
function modifier_orcl_fates_edict_ally:OnCreated()
	self:OnRefresh()
	
	if not IsServer() then return end
	local fatesedict_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_oracle/oracle_fatesedict.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster())
	ParticleManager:SetParticleControlEnt(fatesedict_pfx, 0, self:GetParent(), PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), true)
	self:AddParticle(fatesedict_pfx, false, false, -1, false, false)

	self:StartIntervalThink(self.interval)
end
function modifier_orcl_fates_edict_ally:OnRefresh()
	self.heal_max_hp_pct = self:GetAbility():GetSpecialValueFor("heal_max_hp_pct")
	self.mana_max_mana_pct = self:GetAbility():GetSpecialValueFor("mana_max_mana_pct")
	self.magic_damage_resistance = self:GetAbility():GetSpecialValueFor("magic_damage_resistance_pct")
	self.interval = 1
end
function modifier_orcl_fates_edict_ally:OnIntervalThink()
	if not IsServer() then return end
	if not self:GetAbility() then return end
	local caster = self:GetCaster()
	local owner = self:GetParent()
	if self.heal_max_hp_pct > 0 then
		local heal = caster:GetMaxHealth() * (self.heal_max_hp_pct / 100) * self.interval
		owner:HealWithParams(heal, self:GetAbility(), false, true, caster, false)
		SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, owner, heal, nil)
	end
	
	if self.mana_max_mana_pct > 0 then
		local mana = caster:GetMaxMana() * (self.mana_max_mana_pct / 100) * self.interval
		owner:GiveMana(mana)
		SendOverheadEventMessage(nil, OVERHEAD_ALERT_MANA_ADD, owner, mana, nil)
	end
end
function modifier_orcl_fates_edict_ally:OnDestroy()
	if not IsServer() then return end
	self:GetParent():StopSound("Hero_Oracle.FatesEdict")
end
function modifier_orcl_fates_edict_ally:DeclareFunctions()
	return {MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS}
end
function modifier_orcl_fates_edict_ally:GetModifierMagicalResistanceBonus() return self.magic_damage_resistance end

-- Fate's Edict Enemy
modifier_orcl_fates_edict_enemy = modifier_orcl_fates_edict_enemy or class({})
function modifier_orcl_fates_edict_enemy:IsHidden() return false end
function modifier_orcl_fates_edict_enemy:IgnoreTenacity() return false end
function modifier_orcl_fates_edict_enemy:IsDebuff() return true end
function modifier_orcl_fates_edict_enemy:GetTexture() return "oracle_fates_edict" end
function modifier_orcl_fates_edict_enemy:OnCreated()
	self:OnRefresh()
	
	if not IsServer() then return end
	local caster = self:GetCaster()
	local owner = self:GetParent()
	local fatesedict_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_oracle/oracle_fatesedict.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(fatesedict_pfx, 0, owner, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", owner:GetAbsOrigin(), true)
	self:AddParticle(fatesedict_pfx, false, false, -1, false, false)
	
	local disarm_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_oracle/oracle_fatesedict_disarm.vpcf", PATTACH_OVERHEAD_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(disarm_pfx, 0, owner, PATTACH_OVERHEAD_FOLLOW, "attach_hitloc", owner:GetAbsOrigin(), true)
	self:AddParticle(disarm_pfx, false, false, -1, true, true)
end
function modifier_orcl_fates_edict_enemy:OnRefresh()
	local caster = self:GetCaster()
	local owner = self:GetParent()
	self.heal_max_hp_pct = self:GetAbility():GetSpecialValueFor("heal_max_hp_pct")
	if self.heal_max_hp_pct > 0 then
		self.interval = 1
		self.damageTable = {
			attacker = caster,
			victim = owner,
			ability = self:GetAbility(),
			damage = self.heal_max_hp_pct * self.interval,
			damage_type = DAMAGE_TYPE_MAGICAL,
		}
	end
end
function modifier_orcl_fates_edict_enemy:OnIntervalThink()
	if not IsServer() then return end
	self.damageTable.damage = self:GetCaster():GetMaxHealth() * (self.heal_max_hp_pct / 100) * self.interval
	ApplyDamage(self.damageTable)
end
function modifier_orcl_fates_edict_enemy:OnDestroy()
	if not IsServer() then return end
	self:GetParent():StopSound("Hero_Oracle.FatesEdict")
end
function modifier_orcl_fates_edict_enemy:CheckState()
	local state = {}
	if not self:GetParent():IsDebuffImmune() then
		state[MODIFIER_STATE_DISARMED] = true
	end
	return state
end
