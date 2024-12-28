-------------------
-- False Promise --
-------------------
LinkLuaModifier("modifier_orcl_false_promise_buff", "heroes/oracle/false_promise", LUA_MODIFIER_MOTION_NONE)


orcl_false_promise = orcl_false_promise or class({})
function orcl_false_promise:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local duration = self:GetSpecialValueFor("duration")
	
	caster:EmitSound("Hero_Oracle.FalsePromise.Cast")
	
	target:EmitSound("Hero_Oracle.FalsePromise.FP")
	target:EmitSound("Hero_Oracle.FalsePromise.Target")
	
	local pf_cast = ParticleManager:CreateParticle("particles/units/heroes/hero_oracle/oracle_false_promise_cast.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(pf_cast, 0, target, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:SetParticleControl(pf_cast, 2, caster:GetAbsOrigin())
	ParticleManager:ReleaseParticleIndex(pf_cast)
	
	local pf_target = ParticleManager:CreateParticle("particles/units/heroes/hero_oracle/oracle_false_promise_cast_enemy.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(pf_target, 0, target, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:ReleaseParticleIndex(pf_target)
	
	target:Purge(false, true, false, true, true)
	target:AddNewModifier(caster, self, "modifier_orcl_false_promise_buff", {duration = duration})
end

-- False Promise Buff --
modifier_orcl_false_promise_buff = modifier_orcl_false_promise_buff or class({})
function modifier_orcl_false_promise_buff:IsHidden() return false end
function modifier_orcl_false_promise_buff:IsPurgable() return false end
function modifier_orcl_false_promise_buff:IsDebuff() return false end
function modifier_orcl_false_promise_buff:DestroyOnExpire() return (not self:GetParent():IsInvulnerable()) end
function modifier_orcl_false_promise_buff:GetTexture() return "oracle_false_promise" end
function modifier_orcl_false_promise_buff:GetPriority() return MODIFIER_PRIORITY_ULTRA end
function modifier_orcl_false_promise_buff:OnCreated()
	if IsServer() then if not self:GetAbility() then self:Destroy() end end
	self:OnRefresh()
	self.heal = 0
	self.damage = 0
	
	if not IsServer() then return end
	self.damageInstances = {}
	self.instanceCounter = 1
	
	local owner = self:GetParent()
	self.promise_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_oracle/oracle_false_promise.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster())
	ParticleManager:SetParticleControlEnt(self.promise_pfx, 0, owner, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", owner:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(self.promise_pfx, 1, owner, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", owner:GetAbsOrigin(), true)
	ParticleManager:SetParticleControl(self.promise_pfx, 2, Vector(0, 0, 0))
	self:AddParticle(self.promise_pfx, false, false, -1, false, false)
	
	self.overhead_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_oracle/oracle_false_promise_indicator.vpcf", PATTACH_OVERHEAD_FOLLOW, owner)
	self:AddParticle(self.overhead_particle, false, false, -1, true, true)
	self:SetStackCount(0)
end
function modifier_orcl_false_promise_buff:OnRefresh()
	if IsServer() then if not self:GetAbility() then self:Destroy() end end
	self.isEnemy = self:GetCaster():GetTeamNumber() ~= self:GetParent():GetTeamNumber()
	self.bonus_armor = self.isEnemy and 0 or self:GetAbility():GetSpecialValueFor("bonus_armor")
	self.heal_amp_pct = self:GetAbility():GetSpecialValueFor("heal_amp_pct")
	self.scepter_spell_amp_bonus = self:GetAbility():GetSpecialValueFor("scepter_spell_amp_bonus")
	self.scepter_bat_bonus = self:GetAbility():GetSpecialValueFor("scepter_bat_bonus")
end
function modifier_orcl_false_promise_buff:OnRemoved()
	if not IsServer() then return end
	local owner = self:GetParent()
	if owner:GetTeamNumber() == self:GetCaster():GetTeamNumber() then
		if self:GetStackCount() >= 0 then
			local heal_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_oracle/oracle_false_promise_heal.vpcf", PATTACH_ABSORIGIN_FOLLOW, owner)
			ParticleManager:ReleaseParticleIndex(heal_pfx)
			
			owner:EmitSound("Hero_Oracle.FalsePromise.Healed")
			
			local TrueHeal = self:GetStackCount()
			owner:HealWithParams(TrueHeal, self:GetAbility(), false, true, self:GetCaster(), false)
			SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, owner, TrueHeal, nil)
		elseif self:GetStackCount() < 0 then
			local damage_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_oracle/oracle_false_promise_dmg.vpcf", PATTACH_ABSORIGIN_FOLLOW, owner)
			ParticleManager:ReleaseParticleIndex(damage_pfx)
			
			owner:EmitSound("Hero_Oracle.FalsePromise.Damaged")
			
			SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, owner, self:GetStackCount() * (-1), nil)
			
			for i = 1, #self.damageInstances do
				ApplyDamage(self.damageInstances[i])
			end
		end
	else
		local damage_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_oracle/oracle_false_promise_dmg.vpcf", PATTACH_ABSORIGIN_FOLLOW, owner)
		ParticleManager:ReleaseParticleIndex(damage_pfx)
		
		owner:EmitSound("Hero_Oracle.FalsePromise.Damaged")
		
		SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, owner, self.heal, nil)
		ApplyDamage({
			victim = owner,
			attacker = self:GetCaster(),
			ability = self:GetAbility(),
			damage = self.heal,
			damage_type = DAMAGE_TYPE_MAGICAL,
			damage_flags = DOTA_DAMAGE_FLAG_NONE,
		})
		
		SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, owner, self.damage, nil)
		for i = 1, #self.damageInstances do
			ApplyDamage(self.damageInstances[i])
		end
	end
end
function modifier_orcl_false_promise_buff:OnStackCountChanged(old)
	if not IsServer() then return end
	local damage = self:GetStackCount() * (-1)
	if self.promise_pfx then
		ParticleManager:SetParticleControl(self.promise_pfx, 2, Vector(math.max((damage / self:GetParent():GetMaxHealth()) / 10, 0), 0, 0))
	end
	if self.overhead_particle then
		ParticleManager:SetParticleControl(self.overhead_particle, 1, Vector(damage, 0, 0))
		ParticleManager:SetParticleControl(self.overhead_particle, 2, Vector(damage * (-1), 0, 0))
	end
end
function modifier_orcl_false_promise_buff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
		MODIFIER_EVENT_ON_HEAL_RECEIVED,
		MODIFIER_PROPERTY_DISABLE_HEALING,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
		MODIFIER_PROPERTY_BASE_ATTACK_TIME_CONSTANT,
		MODIFIER_PROPERTY_TOOLTIP, MODIFIER_PROPERTY_TOOLTIP2
	}
end
function modifier_orcl_false_promise_buff:GetModifierIncomingDamage_Percentage(keys)
	if not IsServer() then return end
	local owner = self:GetParent()
	local attacker = keys.attacker
	local target = keys.target
	local damage = keys.damage
	
	if not attacker then return end
	if not target then return end
	if damage <= 0 then return end
	if keys.ability == self:GetAbility() then return end
	
	local damage_flags = keys.damage_flags + DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL
	if bit.band(keys.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) ~= DOTA_DAMAGE_FLAG_HPLOSS then
		damage_flags = damage_flags + DOTA_DAMAGE_FLAG_HPLOSS
	end
	
	if bit.band(keys.damage_flags, DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION) ~= DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION then
		damage_flags = damage_flags + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION
	end
	
	if keys.damage_type == 1 then
		damage_flags = damage_flags + DOTA_DAMAGE_FLAG_IGNORES_PHYSICAL_ARMOR
	elseif keys.damage_type == 2 then
		damage_flags = damage_flags + DOTA_DAMAGE_FLAG_IGNORES_MAGIC_ARMOR
	end
	
	self.damageInstances[self.instanceCounter] = {
		victim = owner,
		attacker = attacker,
		ability = self:GetAbility(),
		damage = nil,
		damage_type = keys.damage_type,
		damage_flags = damage_flags,
	}
	self.instanceCounter = self.instanceCounter + 1
	
	self.damageInstances[self.instanceCounter - 1].damage = damage
	self.damage = self.damage + damage
	self:SetStackCount(math.floor(self.heal - self.damage))
	
	local hit_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_oracle/oracle_false_promise_attacked.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster())
	ParticleManager:SetParticleControlEnt(hit_pfx, 0, owner, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", owner:GetAbsOrigin(), true)
	ParticleManager:ReleaseParticleIndex(hit_pfx)
	
	return -999
end
function modifier_orcl_false_promise_buff:GetDisableHealing() return 1 end
function modifier_orcl_false_promise_buff:GetModifierPhysicalArmorBonus() return self.bonus_armor end
function modifier_orcl_false_promise_buff:OnHealReceived(keys)
	if not IsServer() then return end
	if keys.unit ~= self:GetParent() then return end
	
	self.heal = self.heal + keys.gain * (1 + (self.heal_amp_pct / 100))
	
	self:SetStackCount(math.floor(self.heal - self.damage))
	
--	self:GetParent():ModifyHealth(self:GetParent():GetHealth() - keys.gain, nil, false, 0)
end
function modifier_orcl_false_promise_buff:GetModifierSpellAmplify_Percentage()
	if self:GetCaster():HasScepter() then
		return self.scepter_spell_amp_bonus
	end
end
function modifier_orcl_false_promise_buff:GetModifierBaseAttackTimeConstant()
	if self:GetCaster():HasScepter() then
		if self.bat_check ~= true then
			self.bat_check = true
			local current_bat = self:GetParent():GetBaseAttackTime()
			local new_bat = current_bat - self.scepter_bat_bonus
			self.bat_check = false
			return new_bat
		end
	end
end
function modifier_orcl_false_promise_buff:OnTooltip()
	if self:GetStackCount() >= 0 then
		return self:GetStackCount()
	end
	return 0
end
function modifier_orcl_false_promise_buff:OnTooltip2()
	if self:GetStackCount() < 0 then
		return self:GetStackCount()
	end
	return 0
end
