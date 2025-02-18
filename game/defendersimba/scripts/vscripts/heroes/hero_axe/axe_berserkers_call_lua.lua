LinkLuaModifier("modifier_axe_berserkers_call_lua", "heroes/hero_axe/axe_berserkers_call_lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_axe_berserkers_call_lua_debuff", "heroes/hero_axe/axe_berserkers_call_lua", LUA_MODIFIER_MOTION_NONE)

axe_berserkers_call_lua = axe_berserkers_call_lua or class({})
function axe_berserkers_call_lua:Precache(context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_axe.vsndevts", context)
	PrecacheResource("particle", "particles/status_fx/status_effect_beserkers_call.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_axe/axe_beserkers_call.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_axe/axe_beserkers_call_owner.vpcf", context)
end
function axe_berserkers_call_lua:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor("radius")
	local duration = self:GetSpecialValueFor("duration")
	local buff_attack_speed_enemy = self:GetSpecialValueFor("buff_attack_speed_enemy")

	caster:AddNewModifier(caster, self, "modifier_axe_berserkers_call_lua", {duration = duration})

	local battleHunger
	if caster:HasModifier("modifier_item_aghanims_shard") then
		local ability = caster:FindAbilityByName("axe_battle_hunger_lua")
		if ability and ability:IsTrained() then
			battleHunger = ability
		end
	end

	local enemies = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HEROES_AND_CREEPS, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
	for _,enemy in pairs(enemies) do
		enemy:AddNewModifier(caster, self, "modifier_axe_berserkers_call_lua_debuff", {duration = duration * (1 - enemy:GetStatusResistance()), buff_attack_speed_enemy = buff_attack_speed_enemy})
		if battleHunger then
			battleHunger:OnSpellStart(enemy)
		end
	end

	local call_cast = ParticleManager:CreateParticle("particles/units/heroes/hero_axe/axe_beserkers_call_owner.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(call_cast, 0, caster, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", Vector(0, 0, 0), true)
	ParticleManager:SetParticleControlEnt(call_cast, 1, caster, PATTACH_POINT_FOLLOW, "attach_mouth", Vector(0, 0, 0), true)
	ParticleManager:SetParticleControl(call_cast, 2, Vector(radius, radius, radius))
	ParticleManager:ReleaseParticleIndex(call_cast)

	caster:EmitSound("Hero_Axe.Berserkers_Call")
end


modifier_axe_berserkers_call_lua = modifier_axe_berserkers_call_lua or class({})
function modifier_axe_berserkers_call_lua:IsHidden() return false end
function modifier_axe_berserkers_call_lua:IsPurgable() return false end
function modifier_axe_berserkers_call_lua:GetEffectName() return "particles/units/heroes/hero_axe/axe_beserkers_call.vpcf" end
function modifier_axe_berserkers_call_lua:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end
function modifier_axe_berserkers_call_lua:OnCreated(kv) self:OnRefresh(kv) end
function modifier_axe_berserkers_call_lua:OnRefresh(kv)
	self.armor = kv.armor or self:GetAbility():GetSpecialValueFor("bonus_armor")
end
function modifier_axe_berserkers_call_lua:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
	}
end
function modifier_axe_berserkers_call_lua:GetModifierPhysicalArmorBonus() return self.armor end


modifier_axe_berserkers_call_lua_debuff = modifier_axe_berserkers_call_lua_debuff or class({})
function modifier_axe_berserkers_call_lua_debuff:IsHidden() return false end
function modifier_axe_berserkers_call_lua_debuff:IsPurgable() return false end
function modifier_axe_berserkers_call_lua_debuff:IsDebuff() return true end
function modifier_axe_berserkers_call_lua_debuff:GetStatusEffectName() return "particles/status_fx/status_effect_beserkers_call.vpcf" end
function modifier_axe_berserkers_call_lua_debuff:OnCreated(kv)
	if not IsServer() then return end
	self.buff_attack_speed_enemy = kv.buff_attack_speed_enemy
	OrderAttackTarget(self:GetParent(), self:GetCaster())
	self:GetParent():SetForceAttackTarget(self:GetCaster())
	self:SetHasCustomTransmitterData(true)

	self:StartIntervalThink(FrameTime())
end
function modifier_axe_berserkers_call_lua_debuff:OnRefresh(kv)
	if not IsServer() then return end
	self.buff_attack_speed_enemy = kv.buff_attack_speed_enemy
	OrderAttackTarget(self:GetParent(), self:GetCaster())
	self:GetParent():SetForceAttackTarget(self:GetCaster())
	self:SendBuffRefreshToClients()
end
function modifier_axe_berserkers_call_lua_debuff:OnIntervalThink()
	if not IsServer() then return end
	local caster = self:GetCaster()
	if not caster or caster:IsNull() or not caster:IsAlive() then
		self:Destroy()
		return
	end
	OrderAttackTarget(self:GetParent(), caster)
end
function modifier_axe_berserkers_call_lua_debuff:OnDestroy()
	if not IsServer() then return end
	self:GetParent():SetForceAttackTarget(nil)
end
function modifier_axe_berserkers_call_lua_debuff:AddCustomTransmitterData()
	return {
		buff_attack_speed_enemy = self.buff_attack_speed_enemy,
	}
end
function modifier_axe_berserkers_call_lua_debuff:HandleCustomTransmitterData(data)
	self.buff_attack_speed_enemy = data.buff_attack_speed_enemy
end
function modifier_axe_berserkers_call_lua_debuff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
	}
end
function modifier_axe_berserkers_call_lua_debuff:GetModifierAttackSpeedBonus_Constant() return self.buff_attack_speed_enemy end
function modifier_axe_berserkers_call_lua_debuff:CheckState()
	return {
		[MODIFIER_STATE_COMMAND_RESTRICTED] = true,
	}
end
