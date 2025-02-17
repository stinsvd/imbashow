LinkLuaModifier("modifier_axe_counter_helix_custom_lua", "heroes/hero_axe/axe_counter_helix_custom_lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_axe_counter_helix_custom_lua_debuff", "heroes/hero_axe/axe_counter_helix_custom_lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_axe_counter_helix_custom_lua_buff", "heroes/hero_axe/axe_counter_helix_custom_lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_axe_culling_blade_refresh_counter", "heroes/hero_axe/axe_culling_blade_custom_lua", LUA_MODIFIER_MOTION_NONE)

axe_counter_helix_custom_lua = axe_counter_helix_custom_lua or class({})
function axe_counter_helix_custom_lua:Precache(context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_axe.vsndevts", context)
	PrecacheResource("particle", "particles/units/heroes/hero_axe/axe_counterhelix.vpcf", context)
end
function axe_counter_helix_custom_lua:GetAOERadius() return self:GetSpecialValueFor("radius") end
function axe_counter_helix_custom_lua:GetIntrinsicModifierName() return "modifier_axe_counter_helix_custom_lua" end


modifier_axe_counter_helix_custom_lua = modifier_axe_counter_helix_custom_lua or class({})
function modifier_axe_counter_helix_custom_lua:IsHidden() return false end
function modifier_axe_counter_helix_custom_lua:IsPurgable() return false end
function modifier_axe_counter_helix_custom_lua:IsDebuff() return false end
function modifier_axe_counter_helix_custom_lua:RemoveOnDeath() return false end
function modifier_axe_counter_helix_custom_lua:OnCreated()
	if not IsServer() then return end
	self:SetStackCount(self:GetAbility():GetSpecialValueFor("attack_need"))
end
function modifier_axe_counter_helix_custom_lua:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end
function modifier_axe_counter_helix_custom_lua:OnAttackLanded(params)
	if not IsServer() then return end
	local ability = self:GetAbility()
	if not ability then return end
	local caster = self:GetCaster()
	local target = params.target
	local attacker = params.attacker

	if caster == attacker or target == caster then
		self:DecrementStackCount()

		if self:GetStackCount() == 0 then
			local radius = ability:GetSpecialValueFor("radius")
			local damage = ability:GetSpecialValueFor("base_damage")
			if caster.GetStrength then
				damage = damage + (caster:GetStrength() * ability:GetSpecialValueFor("damage_per_str")) / 100
			end
			local steal_str = self:GetAbility():GetSpecialValueFor("steal_str")

			caster:FadeGesture(ACT_DOTA_CAST_ABILITY_3)
			caster:StartGesture(ACT_DOTA_CAST_ABILITY_3)

			local effect_cast = ParticleManager:CreateParticle("particles/units/heroes/hero_axe/axe_counterhelix.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
			ParticleManager:SetParticleControlEnt(effect_cast, 0, caster, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
			ParticleManager:ReleaseParticleIndex(effect_cast)
			caster:EmitSound("Hero_Axe.CounterHelix")

			local damageTable = {
				victim = nil,
				attacker = caster,
				ability = ability,
				damage = damage,
				damage_type = DAMAGE_TYPE_PURE,
				damage_flags = DOTA_DAMAGE_FLAG_NONE,
			}
			
			local enemies = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HEROES_AND_CREEPS, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
			for i = 1, #enemies do
		--		SendOverheadEventMessage(nil, OVERHEAD_ALERT_CRITICAL, enemies[i], damageTable.damage, nil)
				damageTable.victim = enemies[i]
				ApplyDamage(damageTable)

				if enemies[i]:IsHero() and enemies[i]:IsAlive() then
					local duration = self:GetAbility():GetSpecialValueFor("duration")
					for x = 1, steal_str do
						caster:AddNewModifier(caster, ability, "modifier_axe_counter_helix_custom_lua_buff", {duration = duration})
						enemies[i]:AddNewModifier(caster, ability, "modifier_axe_counter_helix_custom_lua_debuff", {duration = duration * (1 - enemies[i]:GetStatusResistance())})
					end
				end
			end
			
			local cullingBlade = caster:FindAbilityByName("axe_culling_blade_custom_lua")
			if cullingBlade and cullingBlade:IsTrained() then
				caster:AddNewModifier(caster, cullingBlade, "modifier_axe_culling_blade_refresh_counter", {})
			end
			ability:UseResources(true, true, false, true)
			self:SetStackCount(ability:GetSpecialValueFor("attack_need"))
		end
	end
end


modifier_axe_counter_helix_custom_lua_buff = modifier_axe_counter_helix_custom_lua_buff or class({})
function modifier_axe_counter_helix_custom_lua_buff:IsHidden() return false end
function modifier_axe_counter_helix_custom_lua_buff:IsPurgable() return false end
function modifier_axe_counter_helix_custom_lua_buff:IsDebuff() return false end
function modifier_axe_counter_helix_custom_lua_buff:OnCreated() self:OnRefresh() end
function modifier_axe_counter_helix_custom_lua_buff:OnRefresh()
	self:IncrementStackCount()
end
function modifier_axe_counter_helix_custom_lua_buff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_TOOLTIP
	}
end
function modifier_axe_counter_helix_custom_lua_buff:GetModifierBonusStats_Strength()
	return self:GetStackCount()
end
function modifier_axe_counter_helix_custom_lua_buff:OnTooltip()
	return self:GetModifierBonusStats_Strength()
end


modifier_axe_counter_helix_custom_lua_debuff = modifier_axe_counter_helix_custom_lua_debuff or class({})
function modifier_axe_counter_helix_custom_lua_debuff:IsHidden() return false end
function modifier_axe_counter_helix_custom_lua_debuff:IsPurgable() return true end
function modifier_axe_counter_helix_custom_lua_debuff:IsDebuff() return true end
function modifier_axe_counter_helix_custom_lua_debuff:OnCreated() self:OnRefresh() end
function modifier_axe_counter_helix_custom_lua_debuff:OnRefresh()
	self:IncrementStackCount()
end
function modifier_axe_counter_helix_custom_lua_debuff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_TOOLTIP
	}
end
function modifier_axe_counter_helix_custom_lua_debuff:GetModifierBonusStats_Strength()
	return -self:GetStackCount()
end
function modifier_axe_counter_helix_custom_lua_debuff:OnTooltip()
	return self:GetModifierBonusStats_Strength()
end
