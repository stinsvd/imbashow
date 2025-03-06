------------------
-- Shadow Blade --
------------------
LinkLuaModifier("modifier_shadow_blade_cus", "items/shadow_blade", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_shadow_blade_cus_windwalk", "items/shadow_blade", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_silver_edge_cus_windwalk", "items/shadow_blade", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_silver_edge_cus_debuff", "items/shadow_blade", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_echo_sabre_cus_echo_slow", "items/echo_sabre", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_echo_sabre_cus_echo_cd", "items/echo_sabre", LUA_MODIFIER_MOTION_NONE)


item_shadow_blade_cus = item_shadow_blade_cus or class({})
function item_shadow_blade_cus:Precache(context)
	PrecacheResource("particle", "particles/items3_fx/silver_edge.vpcf", context)
	PrecacheResource("particle", "particles/generic_gameplay/generic_break.vpcf", context)
end
function item_shadow_blade_cus:GetIntrinsicModifierName() return "modifier_shadow_blade_cus" end
function item_shadow_blade_cus:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	caster:EmitSound("DOTA_Item.InvisibilitySword.Activate")
	
	local invis = "modifier_shadow_blade_cus_windwalk"
	if self:GetLevel() > 3 then
		invis = "modifier_silver_edge_cus_windwalk"
	end
	caster:AddNewModifier(caster, self, invis, {duration = self:GetSpecialValueFor("windwalk_duration")})
end

item_shadow_blade_2_cus = item_shadow_blade_cus
item_shadow_blade_3_cus = item_shadow_blade_cus
item_shadow_blade_4_cus = item_shadow_blade_cus
item_shadow_blade_5_cus = item_shadow_blade_cus
item_shadow_blade_6_cus = item_shadow_blade_cus


modifier_shadow_blade_cus = modifier_shadow_blade_cus or class({})
function modifier_shadow_blade_cus:IsHidden() return true end
function modifier_shadow_blade_cus:IsPurgable() return false end
function modifier_shadow_blade_cus:IsPermanent() return true end
function modifier_shadow_blade_cus:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end
function modifier_shadow_blade_cus:OnCreated()
	if not IsServer() then return end
	if self:GetAbility():GetSpecialValueFor("echo_attacks") > 0 then
		self:StartIntervalThink(FrameTime())
	end
end
function modifier_shadow_blade_cus:OnIntervalThink()
	if not IsServer() then return end
	local ability = self:GetAbility()
	if not ability then return end
	local parent = self:GetParent()
	
	if parent:IsRangedAttacker() or parent:IsIllusion() or parent:FindAllModifiersByName(self:GetName())[1] ~= self then self:SetStackCount(0) return end
	if self:GetStackCount() > 0 then return end
	
	if not parent:HasModifier("modifier_echo_sabre_cus_echo_cd") then
		self:SetStackCount(ability:GetSpecialValueFor("echo_attacks")+1)
	end
end
function modifier_shadow_blade_cus:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
		MODIFIER_PROPERTY_IGNORE_ATTACKSPEED_LIMIT,
		MODIFIER_EVENT_ON_ATTACK,
	}
end
function modifier_shadow_blade_cus:GetModifierPreAttack_BonusDamage()
	if self:GetAbility() then return self:GetAbility():GetSpecialValueFor("bonus_damage") end
end
function modifier_shadow_blade_cus:GetModifierAttackSpeedBonus_Constant()
	if self:GetAbility() then
		if IsServer() and self:GetStackCount() > 0 and not self:GetParent():IsRangedAttacker() then return self:GetAbility():GetSpecialValueFor("echo_attack_speed") end
		return self:GetAbility():GetSpecialValueFor("bonus_attack_speed")
	end
end
function modifier_shadow_blade_cus:GetModifierBonusStats_Strength()
	if self:GetAbility() then return self:GetAbility():GetSpecialValueFor("bonus_strength") end
end
function modifier_shadow_blade_cus:GetModifierConstantManaRegen()
	if self:GetAbility() then return self:GetAbility():GetSpecialValueFor("bonus_mana_regen") end
end
function modifier_shadow_blade_cus:GetModifierAttackSpeed_Limit()
	if self:GetStackCount() > 0 then return 1 end
end
function modifier_shadow_blade_cus:OnAttack(keys)
	if not IsServer() then return end
	local ability = self:GetAbility()
	if not ability then return end
	if self:GetStackCount() <= 0 then return end
	local parent = self:GetParent()
	local target = keys.target

	if parent:IsRangedAttacker() then return end
	if keys.attacker ~= parent then return end
	if parent:IsIllusion() then return end
	if parent:FindAllModifiersByName(self:GetName())[1] ~= self then return end

	if not target:IsBuilding() and not target:IsOther() then
		local duration = ability:GetSpecialValueFor("slow_duration")
		target:AddNewModifier(parent, ability, "modifier_echo_sabre_cus_echo_slow", {duration = duration * (1 - target:GetStatusResistance())})
	end
	self:DecrementStackCount()
	local attacks = ability:GetSpecialValueFor("echo_attacks")
	if self:GetStackCount() <= math.floor(attacks) and not parent:HasModifier("modifier_echo_sabre_cus_echo_cd") then
		parent:AddNewModifier(parent, ability, "modifier_echo_sabre_cus_echo_cd", {duration = ability:GetSpecialValueFor("echo_cooldown")})
	end
end


modifier_shadow_blade_cus_windwalk = modifier_shadow_blade_cus_windwalk or class({})
function modifier_shadow_blade_cus_windwalk:IsHidden() return self:GetStackCount() > 0 end
function modifier_shadow_blade_cus_windwalk:IsPurgable() return false end
function modifier_shadow_blade_cus_windwalk:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end
function modifier_shadow_blade_cus_windwalk:OnCreated()
	self.bonus_speed = self:GetAbility():GetSpecialValueFor("windwalk_movement_speed")
	self.bonus_damage = self:GetAbility():GetSpecialValueFor("windwalk_bonus_damage")
	self.fade_time = self:GetAbility():GetSpecialValueFor("windwalk_fade_time")
	self.duration = self:GetAbility():GetSpecialValueFor("backstab_duration")
end
function modifier_shadow_blade_cus_windwalk:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_INVISIBILITY_LEVEL,
		MODIFIER_EVENT_ON_ATTACK,
		MODIFIER_EVENT_ON_ABILITY_EXECUTED,
		MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_PHYSICAL,
		MODIFIER_PROPERTY_TOOLTIP,
	}
end
function modifier_shadow_blade_cus_windwalk:GetModifierMoveSpeedBonus_Percentage() return self.bonus_speed end
function modifier_shadow_blade_cus_windwalk:GetModifierInvisibilityLevel()
	if self:GetStackCount() > 0 then return 0 end
	return math.min(self:GetElapsedTime() / self.fade_time, 1)
end
function modifier_shadow_blade_cus_windwalk:OnAttack(params)
	if not IsServer() then return end
	if self.fade_time > self:GetElapsedTime() then return end
	if self:GetStackCount() > 0 then return end
	local attacker = params.attacker
	if not attacker then return end
	if attacker ~= self:GetParent() then return end
	self.record = params.record
	self:IncrementStackCount()
end
function modifier_shadow_blade_cus_windwalk:OnAbilityExecuted()
	self:Destroy()
end
function modifier_shadow_blade_cus_windwalk:GetModifierProcAttack_BonusDamage_Physical(params)
	if not IsServer() then return end
	if not self:GetAbility() then return end
	local target = params.target
	if not target then return end
	local attacker = params.attacker
	if not attacker then return end
	if attacker ~= self:GetParent() then return end
	if self.record ~= params.record then return end
	local bonus_damage = self.bonus_damage
	if target:IsBuilding() or target:IsOther() then
		bonus_damage = 0
	end
	
	if self.duration > 0 then
		target:EmitSound("DOTA_Item.SilverEdge.Target")
		target:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_silver_edge_cus_debuff", {duration = self.duration * (1 - target:GetStatusResistance())})
	end
	self:Destroy()
	return bonus_damage
end
function modifier_shadow_blade_cus_windwalk:OnTooltip() return self.bonus_damage end
function modifier_shadow_blade_cus_windwalk:CheckState()
	if self:GetStackCount() > 0 then return {} end
	local satte = {}
	satte[MODIFIER_STATE_NO_UNIT_COLLISION] = true
	if self.fade_time < self:GetElapsedTime() then
		satte[MODIFIER_STATE_LOW_ATTACK_PRIORITY] = true
	end
	return satte
end

modifier_silver_edge_cus_windwalk = modifier_shadow_blade_cus_windwalk or class({})


modifier_silver_edge_cus_debuff = modifier_silver_edge_cus_debuff or class({})
function modifier_silver_edge_cus_debuff:IsHidden() return false end
function modifier_silver_edge_cus_debuff:IsPurgable() return false end
function modifier_silver_edge_cus_debuff:OnCreated()
	local caster = self:GetCaster()
	local owner = self:GetParent()
	if IsServer() then
		local amb_pfx = ParticleManager:CreateParticle("particles/items3_fx/silver_edge.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
		ParticleManager:SetParticleControlEnt(amb_pfx, 0, owner, PATTACH_ABSORIGIN_FOLLOW, nil, owner:GetAbsOrigin(), true)
		self:AddParticle(amb_pfx, false, false, -1, false, false)
	else
		local break_amb = ParticleManager:CreateParticle("particles/generic_gameplay/generic_break.vpcf", PATTACH_OVERHEAD_FOLLOW, caster)
		ParticleManager:SetParticleControlEnt(break_amb, 0, owner, PATTACH_OVERHEAD_FOLLOW, nil, owner:GetAbsOrigin(), true)
		ParticleManager:SetParticleControl(break_amb, 1, owner:GetAbsOrigin())
		self:AddParticle(break_amb, false, false, -1, false, false)
	end
end
function modifier_silver_edge_cus_debuff:CheckState()
	return {
		[MODIFIER_STATE_PASSIVES_DISABLED] = true,
	}
end