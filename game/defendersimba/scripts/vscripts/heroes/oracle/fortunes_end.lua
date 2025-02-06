-------------------
-- Fortune's End --
-------------------
LinkLuaModifier("modifier_orcl_fortunes_end", "heroes/oracle/fortunes_end", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_orcl_fortunes_end_purge_constantly", "heroes/oracle/fortunes_end", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_orcl_fortunes_end_pull", "heroes/oracle/fortunes_end", LUA_MODIFIER_MOTION_HORIZONTAL)

orcl_fortunes_end = orcl_fortunes_end or class({})
function orcl_fortunes_end:Precache(context)
	PrecacheResource("particle", "particles/units/heroes/hero_oracle/oracle_fortune_channel.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_oracle/oracle_fortune_cast_tgt.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_oracle/oracle_fortune_prj.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_oracle/oracle_fortune_aoe.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_oracle/oracle_fortune_dmg.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_oracle/oracle_fortune_purge.vpcf", context)
end
function orcl_fortunes_end:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end
function orcl_fortunes_end:GetChannelTime()
	if self:GetSpecialValueFor("instacast") > 0 then
		return 1
	end
	return self:GetSpecialValueFor("channel_time")
end
function orcl_fortunes_end:GetBehavior()
	if self:GetSpecialValueFor("instacast") > 0 then
		return DOTA_ABILITY_BEHAVIOR_UNIT_TARGET + DOTA_ABILITY_BEHAVIOR_AOE + DOTA_ABILITY_BEHAVIOR_DONT_CANCEL_CHANNEL
	end
	return DOTA_ABILITY_BEHAVIOR_UNIT_TARGET + DOTA_ABILITY_BEHAVIOR_AOE + DOTA_ABILITY_BEHAVIOR_CHANNELLED + DOTA_ABILITY_BEHAVIOR_DONT_CANCEL_CHANNEL
end

function orcl_fortunes_end:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	self.target = self:GetCursorTarget()
	
	caster:EmitSound("Hero_Oracle.FortunesEnd.Channel")
	
	if self.fortunes_pfx then
		ParticleManager:DestroyParticle(self.fortunes_pfx, false)
		ParticleManager:ReleaseParticleIndex(self.fortunes_pfx)
	end
	
	self.fortunes_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_oracle/oracle_fortune_channel.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(self.fortunes_pfx, 0, caster, PATTACH_POINT_FOLLOW, "attach_attack1", caster:GetAbsOrigin(), true)
	
	local target_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_oracle/oracle_fortune_cast_tgt.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(target_pfx, 0, self.target, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", self.target:GetAbsOrigin(), true)
	ParticleManager:ReleaseParticleIndex(target_pfx)
	
	if self:GetSpecialValueFor("instacast") > 0 then
		self:OnChannelFinish(false)
	end
end
function orcl_fortunes_end:OnChannelFinish(bInterrupted)
	if not IsServer() then return end
	local caster = self:GetCaster()
	local damage = self:GetSpecialValueFor("damage")
	local radius = self:GetSpecialValueFor("radius")
	local bolt_speed = self:GetSpecialValueFor("bolt_speed")
	local maximum_duration = self:GetSpecialValueFor("maximum_purge_duration")
	local minimum_duration = self:GetSpecialValueFor("minimum_purge_duration")
	local mana_per_purge = self:GetSpecialValueFor("mana_per_purge")
	local damage_per_buff = self:GetSpecialValueFor("damage_per_buff")
	local heal_per_debuff = self:GetSpecialValueFor("heal_per_debuff")
	local purge_constantly = self:GetSpecialValueFor("purge_constantly")
	local ally_aoe = self:GetSpecialValueFor("ally_aoe")
	local pull_speed = self:GetSpecialValueFor("pull_speed")
	local pull_radius = self:GetSpecialValueFor("pull_radius")
	local pull_duration = self:GetSpecialValueFor("pull_duration")
	if caster:GetUnitName() == "npc_dota_hero_oracle" then
		caster:StartGesture(ACT_DOTA_CAST_ABILITY_1_END)
	end
	caster:StopSound("Hero_Oracle.FortunesEnd.Channel")
	caster:EmitSound("Hero_Oracle.FortunesEnd.Attack")
	
	if self.fortunes_pfx then
		ParticleManager:DestroyParticle(self.fortunes_pfx, false)
		ParticleManager:ReleaseParticleIndex(self.fortunes_pfx)
	end

	ProjectileManager:CreateTrackingProjectile({
		Target = self.target,
		Source = caster,
		Ability = self,
		EffectName = "particles/units/heroes/hero_oracle/oracle_fortune_prj.vpcf",
		iMoveSpeed = bolt_speed,
		vSourceLoc = caster:GetAbsOrigin(),
		bDrawsOnMinimap = false,
		bDodgeable = false,
		bIsAttack = false,
		bVisibleToEnemies = true,
		bReplaceExisting = false,
		flExpireTime = GameRules:GetGameTime() + 10,
		bProvidesVision = false,
		iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_2,
		ExtraData = {
			damage = damage,
			radius = radius,
			maximum_duration = maximum_duration,
			minimum_duration = minimum_duration,
			mana_per_purge = mana_per_purge,
			damage_per_buff = damage_per_buff,
			heal_per_debuff = heal_per_debuff,
			purge_constantly = purge_constantly,
			ally_aoe = ally_aoe,
			pull_speed = pull_speed,
			pull_radius = pull_radius,
			pull_duration = pull_duration,
			charge_pct = ((GameRules:GetGameTime() - self:GetChannelStartTime()) / self:GetChannelTime()),
		}
	})
end

function orcl_fortunes_end:OnProjectileHit_ExtraData(target, loc, data)
	if not IsServer() then return end
	if target == nil then return end
	local caster = self:GetCaster()
	local damage = data.damage
	local radius = data.radius
	local charge_pct = math.min(data.charge_pct, 1)
	local maximum_duration = data.maximum_duration
	local minimum_duration = data.minimum_duration
	local mana_per_purge = data.mana_per_purge
	local damage_per_buff = data.damage_per_buff
	local heal_per_debuff = data.heal_per_debuff
	local purge_constantly = data.purge_constantly
	local ally_aoe = data.ally_aoe
	local pull_speed = data.pull_speed
	local pull_radius = data.pull_radius
	local pull_duration = data.pull_duration
	local isEnemy = target:GetTeamNumber() ~= caster:GetTeamNumber() and not target:HasModifier("modifier_orcl_false_promise_buff")
	
	if isEnemy then
		if target:TriggerSpellAbsorb(self) then return end
	end
	
	if charge_pct ~= nil then
		local targetPos = target:GetAbsOrigin()
		local duration = math.max(maximum_duration * charge_pct, minimum_duration)
		EmitSoundOnLocationWithCaster(targetPos, "Hero_Oracle.FortunesEnd.Target", caster)
		local aoe_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_oracle/oracle_fortune_aoe.vpcf", PATTACH_ABSORIGIN, caster)
		ParticleManager:SetParticleControlEnt(aoe_pfx, 0, target, PATTACH_ABSORIGIN, nil, targetPos, true)
		ParticleManager:SetParticleControl(aoe_pfx, 2, Vector(radius, radius, radius))
		ParticleManager:SetParticleControlEnt(aoe_pfx, 3, target, PATTACH_ABSORIGIN, nil, targetPos, true)
		ParticleManager:ReleaseParticleIndex(aoe_pfx)
		
		local damageTable = {
			victim = target,
			attacker = caster,
			ability = self,
			damage = damage,
			damage_type = DAMAGE_TYPE_MAGICAL,
			damage_flags = DOTA_DAMAGE_FLAG_NONE,
		}
		
		if not isEnemy then
			local mods = self:PurgeAndCheck(target, isEnemy)
			if heal_per_debuff > 0 then
				target:HealWithParams(mods * heal_per_debuff, self, false, true, caster, false)
			end
			if purge_constantly > 0 then
				target:AddNewModifier(caster, self, "modifier_orcl_fortunes_end_purge_constantly", {duration = duration})
			end
		else
			target:AddNewModifier(caster, self, "modifier_orcl_fortunes_end", {duration = duration})
			local buffs = self:PurgeAndCheck(target, isEnemy)
			damageTable.damage = damage_per_buff > 0 and damage + (damage_per_buff * buffs) or damage
			ApplyDamage(damageTable)
		end
		
		local targets = FindUnitsInRadius(caster:GetTeamNumber(), targetPos, nil, pull_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HEROES_AND_CREEPS, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
		for _, unit in pairs(targets) do
			if unit ~= target then
				unit:AddNewModifier(caster, self, "modifier_orcl_fortunes_end_pull", {duration = pull_duration * (1 - unit:GetStatusResistance()), pull_speed = pull_speed, x = targetPos.x, y = targetPos.y})
			end
		end
		
		local team = ally_aoe > 0 and DOTA_UNIT_TARGET_TEAM_BOTH or DOTA_UNIT_TARGET_TEAM_ENEMY
		local targets = FindUnitsInRadius(caster:GetTeamNumber(), targetPos, nil, radius, team, DOTA_UNIT_TARGET_HEROES_AND_CREEPS, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
		for _, unit in pairs(targets) do
			if unit ~= target then
				local unitPos = unit:GetAbsOrigin()
				isEnemy = unit:GetTeamNumber() ~= caster:GetTeamNumber() and not unit:HasModifier("modifier_orcl_false_promise_buff")
				local impact_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_oracle/oracle_fortune_dmg.vpcf", PATTACH_POINT_FOLLOW, caster)
				ParticleManager:SetParticleControlEnt(impact_pfx, 0, unit, PATTACH_POINT_FOLLOW, "attach_hitloc", unitPos, true)
				ParticleManager:SetParticleControlEnt(impact_pfx, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", targetPos, true)
				ParticleManager:SetParticleControlEnt(impact_pfx, 3, unit, PATTACH_POINT_FOLLOW, "attach_hitloc", unitPos, true)
				ParticleManager:ReleaseParticleIndex(impact_pfx)
				
				if purge_constantly > 0 then
					unit:AddNewModifier(caster, self, "modifier_orcl_fortunes_end_purge_constantly", {duration = isEnemy and (duration * (1 - unit:GetStatusResistance())) or duration})
				end
				if not isEnemy then
					local mods = self:PurgeAndCheck(unit, isEnemy)
					if heal_per_debuff > 0 then
						unit:HealWithParams(mods * heal_per_debuff, self, false, true, caster, false)
					end
				else
					unit:AddNewModifier(caster, self, "modifier_orcl_fortunes_end", {duration = (duration * (1 - unit:GetStatusResistance()))})
					
					local mods = self:PurgeAndCheck(unit, isEnemy)
					damageTable.victim = unit
					damageTable.damage = damage_per_buff > 0 and damage + (damage_per_buff * mods) or damage
					ApplyDamage(damageTable)
				end
			end
		end
	end
end
function orcl_fortunes_end:PurgeAndCheck(target, isEnemy)
	local caster = self:GetCaster()
	local old = #target:FindAllModifiers()
	if not isEnemy then
		local heal = 0
		local healEfficiency = self:GetSpecialValueFor("flames_heal_efficiency")
		local flames = target:FindAllModifiersByName("modifier_orcl_purifying_flames_buff")
		for _, buff in pairs(flames) do
			buff:HealEffect(true)
		end
		heal = heal * (healEfficiency / 100)
		target:HealWithParams(heal, self, false, true, caster, false)
		SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, target, heal, nil)
	end
	
	target:Purge(isEnemy, not isEnemy, false, false, false)
	local new = #target:FindAllModifiers()
	
	local mana_per_purge = self:GetSpecialValueFor("mana_per_purge")
	caster:GiveMana(mana_per_purge * (old - new))
	SendOverheadEventMessage(nil, OVERHEAD_ALERT_MANA_ADD, caster, mana_per_purge * (old - new), nil)
	return old - new
end


modifier_orcl_fortunes_end = modifier_orcl_fortunes_end or class({})
function modifier_orcl_fortunes_end:IsHidden() return false end
function modifier_orcl_fortunes_end:IsPurgable() return true end
function modifier_orcl_fortunes_end:OnCreated(kv)
	if not IsServer() then return end
	local roots_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_oracle/oracle_fortune_purge.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster())
	ParticleManager:SetParticleControlEnt(roots_pfx, 0, self:GetParent(), PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), true)
	self:AddParticle(roots_pfx, false, false, -1, false, false)
end
function modifier_orcl_fortunes_end:CheckState()
	local states = {
		[MODIFIER_STATE_INVISIBLE] = false,
		[MODIFIER_STATE_PROVIDES_VISION] = true,
	}
	if not self:GetParent():IsDebuffImmune() then
		states[MODIFIER_STATE_ROOTED] = true
	end
	return states
end


modifier_orcl_fortunes_end_purge_constantly = modifier_orcl_fortunes_end_purge_constantly or class({})
function modifier_orcl_fortunes_end_purge_constantly:IsHidden() return false end
function modifier_orcl_fortunes_end_purge_constantly:IsPurgable() return true end
function modifier_orcl_fortunes_end_purge_constantly:OnCreated()
	if not IsServer() then return end
	if not self:GetAbility() then return end
	self.isEnemy = self:GetParent():GetTeamNumber() ~= self:GetCaster():GetTeamNumber() and not self:GetParent():HasModifier("modifier_orcl_false_promise_buff")
	self:OnIntervalThink()
	self:StartIntervalThink(0.1)
end
function modifier_orcl_fortunes_end_purge_constantly:OnIntervalThink()
	if not IsServer() then return end
	local parent = self:GetParent()
	if self.isEnemy then
		if not parent:IsDebuffImmune() then
			parent:Purge(true, false, false, false, false)
		end
	else
		parent:Purge(false, true, false, false, false)
	end
end


modifier_orcl_fortunes_end_pull = modifier_orcl_fortunes_end_pull or class({})
function modifier_orcl_fortunes_end_pull:IsDebuff() return true end
function modifier_orcl_fortunes_end_pull:IgnoreTenacity() return true end
function modifier_orcl_fortunes_end_pull:OnCreated(kv)
	self:OnRefresh(kv)
end
function modifier_orcl_fortunes_end_pull:OnRefresh(kv)
	if not IsServer() then return end
	self.duration = kv.duration
	self.centerPos = GetGroundPosition(Vector(kv.x, kv.y, 0), nil)
	self.distance = self:GetParent():GetAbsOrigin() - self.centerPos
	self.pull_speed = kv.pull_speed		--self.distance:Length2D() / self.duration
	
	if self:ApplyHorizontalMotionController() == false then
		self:Destroy()
	end
end
function modifier_orcl_fortunes_end_pull:OnDestroy()
	if not IsServer() then return end
	self:GetParent():RemoveHorizontalMotionController(self)
	ResolveNPCPositions(self:GetParent():GetAbsOrigin(), 72)
end
function modifier_orcl_fortunes_end_pull:UpdateHorizontalMotion(me, dt)
	if not IsServer() then return end
	local distance = (self.centerPos - me:GetAbsOrigin()):Normalized()
	me:SetOrigin(me:GetAbsOrigin() + distance * self.pull_speed * dt)
end
function modifier_orcl_fortunes_end_pull:OnHorizontalMotionInterrupted()
	self:Destroy()
end
function modifier_orcl_fortunes_end_pull:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION
	}
end
function modifier_orcl_fortunes_end_pull:GetOverrideAnimation() return ACT_DOTA_FLAIL end
function modifier_orcl_fortunes_end_pull:CheckState()
	return {[MODIFIER_STATE_STUNNED] = true}
end

