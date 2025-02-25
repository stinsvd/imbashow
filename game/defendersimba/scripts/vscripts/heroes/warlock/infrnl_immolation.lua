----------------
-- Immolation --
----------------
LinkLuaModifier("modifier_infrnl_immolation", "heroes/warlock/infrnl_immolation", LUA_MODIFIER_MOTION_NONE)


infrnl_immolation = infrnl_immolation or class({})
function infrnl_immolation:Precache(context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_ember_spirit.vsndevts", context)
	PrecacheResource("particle", "particles/units/heroes/hero_ember_spirit/ember_spirit_flameguard.vpcf", context)
end
function infrnl_immolation:ProcsMagicStick() return false end
function infrnl_immolation:GetHealthCost(lvl)
	if self:GetCaster():HasModifier("modifier_infrnl_immolation") then
		return self:GetCaster():GetMaxHealth() * (self:GetLevelSpecialValueFor("health_per_second", math.min(lvl, 1)) / 100)
	end
	return 0
end
function infrnl_immolation:GetManaCost(lvl)
	if self:GetCaster():HasModifier("modifier_infrnl_immolation") then
		return 0
	end
	return self:GetLevelSpecialValueFor("AbilityManaCost", math.min(lvl, 1))
end
function infrnl_immolation:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end
function infrnl_immolation:OnToggle()
	if not IsServer() then return end
	local caster = self:GetCaster()
	if self:GetToggleState() then
		caster:EmitSound("Hero_EmberSpirit.FlameGuard.Cast")
		caster:AddNewModifier(caster, self, "modifier_infrnl_immolation", {})
	else
		caster:StopSound("Hero_EmberSpirit.FlameGuard.Cast")
		caster:RemoveModifierByName("modifier_infrnl_immolation")
	end
end


modifier_infrnl_immolation = modifier_infrnl_immolation or class({})
function modifier_infrnl_immolation:IsHidden() return false end
function modifier_infrnl_immolation:IsPurgable() return false end
function modifier_infrnl_immolation:OnCreated()
	self.radius = self:GetAbility():GetSpecialValueFor("radius")
	self.interval = self:GetAbility():GetSpecialValueFor("interval")
	self.up_shards = self:GetAbility():GetSpecialValueFor("up_shards")
	
	if not IsServer() then return end
	local caster = self:GetCaster()
	local owner = self:GetParent()
	self.upTime = 0
	local amb_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_ember_spirit/ember_spirit_flameguard.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(amb_pfx, 0, owner, PATTACH_ABSORIGIN_FOLLOW, nil, owner:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(amb_pfx, 1, owner, PATTACH_ABSORIGIN_FOLLOW, nil, owner:GetAbsOrigin(), true)
	ParticleManager:SetParticleControl(amb_pfx, 2, Vector(self.radius, 0, 0))
	ParticleManager:SetParticleControl(amb_pfx, 3, Vector(120, 0, 0))
	self:AddParticle(amb_pfx, false, false, -1, false, false)
	
	self.damageTable = {
		victim = nil,
		attacker = caster,
		ability = self:GetAbility(),
		damage = nil,
		damage_type = DAMAGE_TYPE_MAGICAL,
		damage_flags = DOTA_DAMAGE_FLAG_NONE,
	}
	
	EmitSoundOn("Hero_EmberSpirit.FlameGuard.Loop", caster)
	self:StartIntervalThink(self.interval)
end
function modifier_infrnl_immolation:OnIntervalThink()
	if not IsServer() then return end
	local ability = self:GetAbility()
	if not ability then return end
	local caster = self:GetCaster()
	local owner = self:GetParent()
	
	local health_per_second = ability:GetHealthCost(-1) * self.interval --ability:GetSpecialValueFor("health_per_second")
--	caster:Script_ReduceMana(health_per_second, ability)
	caster:ModifyHealth(caster:GetHealth() - health_per_second, nil, false, 0)
	if caster:GetHealth() < health_per_second then
		if ability:GetToggleState() then
			ability:ToggleAbility()
		end
	end
	
	local up_time = ability:GetSpecialValueFor("up_time")
	self.upTime = self.upTime + self.interval
	if self.upTime >= up_time then
		local upgrade = caster:FindModifierByName("modifier_infrnl_burning_spirit")
		if upgrade then
			for i = 1, self.up_shards do
			--	upgrade:Upgrade()
				upgrade:IncrementStackCount()
				self.upTime = self.upTime - up_time
			end
		end
	end
	
	local base_dps = ability:GetSpecialValueFor("base_damage_per_second")
	local maxhp_dps = ability:GetSpecialValueFor("maxhp_damage_per_second")
	self.damageTable.damage = (base_dps + (caster:GetMaxHealth() * (maxhp_dps / 100))) * self.interval
	local nearby_enemies = FindUnitsInRadius(caster:GetTeamNumber(), owner:GetAbsOrigin(), nil, self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HEROES_AND_CREEPS, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	for _, enemy in pairs(nearby_enemies) do
		self.damageTable.victim = enemy
		ApplyDamage(self.damageTable)
	end
end
function modifier_infrnl_immolation:OnDestroy()
	if not IsServer() then return end
	StopSoundEvent("Hero_EmberSpirit.FlameGuard.Loop", self:GetCaster())
end
