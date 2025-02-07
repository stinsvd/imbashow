--------------------
-- Infernal Stomp --
--------------------
LinkLuaModifier("modifier_infrnl_stomp", "heroes/warlock/infrnl_stomp", LUA_MODIFIER_MOTION_NONE)


infrnl_stomp = class({})
function infrnl_stomp:Precache(context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_huskar.vsndevts", context)
	PrecacheResource("particle", "particles/units/heroes/hero_huskar/huskar_inner_fire.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_dragon_knight/dragon_knight_shard_fireball.vpcf", context)
end
function infrnl_stomp:GetCastAnimation() return ACT_DOTA_ATTACK end
function infrnl_stomp:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor("radius")
	local base_damage = self:GetSpecialValueFor("impact_base_damage")
	local maxhp_damage = self:GetSpecialValueFor("impact_maxhp_damage")
	local stun_duration = self:GetSpecialValueFor("stun_duration")
	local burn_duration = self:GetSpecialValueFor("burn_duration")
	
	local cast_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_huskar/huskar_inner_fire.vpcf", PATTACH_WORLDORIGIN, caster)
	ParticleManager:SetParticleControl(cast_pfx, 0, caster:GetAbsOrigin())
	ParticleManager:SetParticleControl(cast_pfx, 1, Vector(radius, 0, 0))
	ParticleManager:SetParticleControl(cast_pfx, 3, caster:GetAbsOrigin())
	ParticleManager:ReleaseParticleIndex(cast_pfx)
	
	caster:EmitSound("Hero_Huskar.Inner_Fire.Cast")
	
	CreateModifierThinker(caster, self, "modifier_infrnl_stomp", {duration = burn_duration}, caster:GetAbsOrigin(), caster:GetTeamNumber(), false)
	
	local damageTable = {
		victim = nil,
		attacker = caster,
		damage = base_damage + (caster:GetMaxHealth() * (maxhp_damage / 100)),
		ability = self,
		damage_type = self:GetAbilityDamageType(),
	}
	local enemies = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HEROES_AND_CREEPS, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	for i = 1, #enemies do
		enemies[i]:AddNewModifier(caster, self, "modifier_stunned", {duration = stun_duration * (1 - enemies[i]:GetStatusResistance())})
		
		damageTable.victim = enemies[i]
		ApplyDamage(damageTable)
	end
end


modifier_infrnl_stomp = class({})
function modifier_infrnl_stomp:IsHidden() return true end
function modifier_infrnl_stomp:IsPurgable() return false end
function modifier_infrnl_stomp:OnCreated()
	self.radius = self:GetAbility():GetSpecialValueFor("radius")
	self.interval = self:GetAbility():GetSpecialValueFor("interval")
	self.base_damage = self:GetAbility():GetSpecialValueFor("burn_base_damage")
	self.maxhp_damage = self:GetAbility():GetSpecialValueFor("burn_maxhp_damage")
	
	if not IsServer() then return end
	local caster = self:GetCaster()
	local fireball_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_dragon_knight/dragon_knight_shard_fireball.vpcf", PATTACH_WORLDORIGIN, caster)
	ParticleManager:SetParticleControl(fireball_pfx, 0, self:GetParent():GetAbsOrigin())
	ParticleManager:SetParticleControl(fireball_pfx, 1, self:GetParent():GetAbsOrigin())
	ParticleManager:SetParticleControl(fireball_pfx, 2, Vector(self:GetDuration(), self.radius, self.radius))
	self:AddParticle(fireball_pfx, false, false, -1, false, false)
	
	self.damageTable = {
		victim = nil,
		attacker = caster,
		ability = self:GetAbility(),
		damage = (self.base_damage + (caster:GetMaxHealth() * (self.maxhp_damage / 100))) * self.interval,
		damage_type = DAMAGE_TYPE_MAGICAL,
		damage_flags = DOTA_DAMAGE_FLAG_NONE,
	}

	self:StartIntervalThink(self.interval)
end
function modifier_infrnl_stomp:OnIntervalThink()
	if not IsServer() then return end
	if not self:GetAbility() then return end
	local nearby_enemies = FindUnitsInRadius(self:GetCaster():GetTeamNumber(), self:GetParent():GetAbsOrigin(), nil, self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HEROES_AND_CREEPS, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	for _, enemy in pairs(nearby_enemies) do
		self.damageTable.victim = enemy
		ApplyDamage(self.damageTable)
	end
end
