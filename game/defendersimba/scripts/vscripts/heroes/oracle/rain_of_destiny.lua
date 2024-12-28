LinkLuaModifier("modifier_orcl_rain_of_destiny_aura", "heroes/oracle/rain_of_destiny", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_orcl_rain_of_destiny", "heroes/oracle/rain_of_destiny", LUA_MODIFIER_MOTION_NONE)


orcl_rain_of_destiny = orcl_rain_of_destiny or class({})
function orcl_rain_of_destiny:Precache(context)
	PrecacheResource("particle", "particles/units/heroes/hero_oracle/oracle_scepter_rain_of_destiny.vpcf", context)
end
function orcl_rain_of_destiny:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end
function orcl_rain_of_destiny:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()
	local duration = self:GetSpecialValueFor("duration")
	
	CreateModifierThinker(caster, self, "modifier_orcl_rain_of_destiny_aura", {duration = duration}, point, caster:GetTeamNumber(), false)
	EmitSoundOnLocationWithCaster(point, "Hero_Oracle.RainOfDestiny.Cast", caster)
end


modifier_orcl_rain_of_destiny_aura = modifier_orcl_rain_of_destiny_aura or class({})
function modifier_orcl_rain_of_destiny_aura:IsPurgable() return false end
function modifier_orcl_rain_of_destiny_aura:IsPurgeException() return false end
function modifier_orcl_rain_of_destiny_aura:OnCreated()
	self.radius = self:GetAbility():GetSpecialValueFor("radius")
	self.flames_per_second = self:GetAbility():GetSpecialValueFor("flames_per_second")
	
	if not IsServer() then return end
	local owner = self:GetParent()
	local amb_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_oracle/oracle_scepter_rain_of_destiny.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster())
	ParticleManager:SetParticleControlEnt(amb_pfx, 0, owner, PATTACH_ABSORIGIN_FOLLOW, nil, owner:GetAbsOrigin(), true)
	ParticleManager:SetParticleControl(amb_pfx, 1, Vector(self.radius, self.radius, self.radius))
	self:AddParticle(amb_pfx, false, false, -1, false, false)
	
	owner:EmitSound("Hero_Oracle.RainOfDestiny")
	self:StartIntervalThink(0.1)
end
function modifier_orcl_rain_of_destiny_aura:OnIntervalThink()
	if not IsServer() then return end
	self.currentTime = (self.currentTime or 0) + 0.1
	if self.currentTime >= 1 / self.flames_per_second then
		self.currentTime = 0
		local flames = self:GetCaster():FindAbilityByName("orcl_purifying_flames")
		if flames and flames:IsTrained() then
			local targets = FindUnitsInRadius(self:GetCaster():GetTeamNumber(), self:GetParent():GetAbsOrigin(), nil, self.radius, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_HEROES_AND_CREEPS, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
			flames:OnSpellStart(targets[math.random(1, #targets)])
		end
	end
end
function modifier_orcl_rain_of_destiny_aura:OnDestroy()
	if not IsServer() then return end
	self:GetParent():StopSound("Hero_Oracle.RainOfDestiny")
	self:GetParent():CarefulRemoveUnit()
end
function modifier_orcl_rain_of_destiny_aura:IsAura() return true end
function modifier_orcl_rain_of_destiny_aura:GetAuraDuration() return 0.1 end
function modifier_orcl_rain_of_destiny_aura:GetAuraRadius() return self.radius end
--function modifier_orcl_rain_of_destiny_aura:GetAuraSearchFlags() return DOTA_UNIT_TARGET_FLAG_INVULNERABLE end
function modifier_orcl_rain_of_destiny_aura:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_BOTH end
function modifier_orcl_rain_of_destiny_aura:GetAuraSearchType() return DOTA_UNIT_TARGET_HEROES_AND_CREEPS end
function modifier_orcl_rain_of_destiny_aura:GetModifierAura() return "modifier_orcl_rain_of_destiny" end
--[[
function modifier_orcl_rain_of_destiny_aura:GetAuraEntityReject(unit)
	if not IsServer() then return end
	if unit == self:GetParent() then return true end
	return false
end
]]


modifier_orcl_rain_of_destiny = modifier_orcl_rain_of_destiny or class({})
function modifier_orcl_rain_of_destiny:IsHidden() return false end
function modifier_orcl_rain_of_destiny:OnCreated()
	self.damage = self:GetAbility():GetSpecialValueFor("damage")
	local tick_rate = self:GetAbility():GetSpecialValueFor("tick_rate")
	self.heal_amp = self:GetAbility():GetSpecialValueFor("heal_amp")
	self.isEnemy = self:GetParent():GetTeamNumber() ~= self:GetCaster():GetTeamNumber() and not self:GetParent():HasModifier("modifier_orcl_false_promise_buff")
	
	if not IsServer() then return end
	self.damageTable = {
		victim = self:GetParent(),
		attacker = self:GetCaster(),
		ability = self:GetAbility(),
		damage = self.damage,
		damage_type = DAMAGE_TYPE_MAGICAL,
	}
	self:StartIntervalThink(tick_rate)
end
function modifier_orcl_rain_of_destiny:OnIntervalThink()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local owner = self:GetParent()
	self.isEnemy = owner:GetTeamNumber() ~= caster:GetTeamNumber() and not owner:HasModifier("modifier_orcl_false_promise_buff")
	if self.isEnemy then
		ApplyDamage(self.damageTable)
	else
		owner:HealWithParams(self.damage, self:GetAbility(), false, true, caster, false)
		SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, owner, self.damage, nil)
	end
end
function modifier_orcl_rain_of_destiny:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET,
		MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_SOURCE
	}
end
function modifier_orcl_rain_of_destiny:GetModifierHealAmplify_PercentageTarget() return self.isEnemy and self.heal_amp * (-1) or self.heal_amp end
function modifier_orcl_rain_of_destiny:GetModifierHealAmplify_PercentageSource() return self.isEnemy and self.heal_amp * (-1) or self.heal_amp end
