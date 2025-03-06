--------------------
-- Black King Bar --
--------------------
LinkLuaModifier("modifier_black_king_bar_cus", "items/black_king_bar", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_black_king_bar_cus_active", "items/black_king_bar", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_black_king_bar_cus_invis", "items/black_king_bar", LUA_MODIFIER_MOTION_NONE)

item_black_king_bar_cus = class({})
function item_black_king_bar_cus:Precache(context)
	PrecacheResource("particle", "particles/items_fx/black_king_bar_avatar.vpcf", context)
	PrecacheResource("particle", "particles/status_fx/status_effect_avatar.vpcf", context)
	PrecacheResource("particle", "particles/items3_fx/glimmer_cape_initial.vpcf", context)
end
function item_black_king_bar_cus:GetIntrinsicModifierName() return "modifier_black_king_bar_cus" end
function item_black_king_bar_cus:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local duration = self:GetSpecialValueFor("duration")

	caster:EmitSound("DOTA_Item.BlackKingBar.Activate")
	caster:Purge(false, true, false, false, false)
	caster:AddNewModifier(caster, self, "modifier_black_king_bar_cus_active", {duration = duration})

	local invis = self:GetSpecialValueFor("invis")
	if invis > 0 then
		local invis_ms = self:GetSpecialValueFor("invis_ms")
		if invis_ms > 0 then
			caster:AddNewModifier(caster, self, "modifier_black_king_bar_cus_invis", {duration = duration})
		else
			caster:AddNewModifier(caster, self, "modifier_invisible", {duration = duration})
		end
	end
end

item_black_king_bar_2_cus = item_black_king_bar_cus
item_black_king_bar_3_cus = item_black_king_bar_cus
item_black_king_bar_4_cus = item_black_king_bar_cus
item_black_king_bar_5_cus = item_black_king_bar_cus
item_black_king_bar_6_cus = item_black_king_bar_cus


modifier_black_king_bar_cus = class({})
function modifier_black_king_bar_cus:IsHidden() return true end
function modifier_black_king_bar_cus:IsPurgable() return false end
function modifier_black_king_bar_cus:IsPermanent() return true end
function modifier_black_king_bar_cus:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end
function modifier_black_king_bar_cus:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
	}
end
function modifier_black_king_bar_cus:GetModifierBonusStats_Strength()
	if self:GetAbility() then return self:GetAbility():GetSpecialValueFor("bonus_strength") end
end
function modifier_black_king_bar_cus:GetModifierPreAttack_BonusDamage()
	if self:GetAbility() then return self:GetAbility():GetSpecialValueFor("bonus_damage") end
end
function modifier_black_king_bar_cus:GetModifierMagicalResistanceBonus()
	if self:GetAbility() then return self:GetAbility():GetSpecialValueFor("bonus_magic_resist") end
end


modifier_black_king_bar_cus_active = class({})
function modifier_black_king_bar_cus_active:IsHidden() return false end
function modifier_black_king_bar_cus_active:IsPurgable() return false end
function modifier_black_king_bar_cus_active:GetEffectName() return "particles/items_fx/black_king_bar_avatar.vpcf" end
function modifier_black_king_bar_cus_active:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end
function modifier_black_king_bar_cus_active:GetStatusEffectName() return "particles/status_fx/status_effect_avatar.vpcf" end
function modifier_black_king_bar_cus_active:StatusEffectPriority() return 100 end
function modifier_black_king_bar_cus_active:OnCreated() self:OnRefresh() end
function modifier_black_king_bar_cus_active:OnRefresh()
	self.model_scale = self:GetAbility():GetSpecialValueFor("model_scale")
	self.magic_resist = self:GetAbility():GetSpecialValueFor("magic_resist")
end
function modifier_black_king_bar_cus_active:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MODEL_SCALE,
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE
	}
end
function modifier_black_king_bar_cus_active:GetModifierModelScale() return self.model_scale end
function modifier_black_king_bar_cus_active:GetModifierMagicalResistanceBonus() return self.magic_resist end
function modifier_black_king_bar_cus_active:GetModifierIncomingDamage_Percentage(keys)
	if not IsServer() then return end
	if not keys.attacker then return end
	if not keys.target then return end
	if keys.damage <= 0 then return end
	
	if keys.damage_type == DAMAGE_TYPE_PURE or bit.band(params.damage_flags, DOTA_DAMAGE_FLAG_REFLECTION) ~= DOTA_DAMAGE_FLAG_REFLECTION then
		return -999
	end
	return 0
end
function modifier_black_king_bar_cus_active:CheckState()
	return {
		[MODIFIER_STATE_DEBUFF_IMMUNE] = true,
	}
end


modifier_black_king_bar_cus_invis = modifier_black_king_bar_cus_invis or class({})
function modifier_black_king_bar_cus_invis:IsHidden() return false end
function modifier_black_king_bar_cus_invis:IsPurgable() return true end
function modifier_black_king_bar_cus_invis:OnCreated()
	self.active_movement_speed = self:GetAbility():GetSpecialValueFor("active_movement_speed")

	if not IsServer() then return end
	local cast_pfx = ParticleManager:CreateParticle("particles/items3_fx/glimmer_cape_initial.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster())
	ParticleManager:SetParticleControlEnt(cast_pfx, 1, self:GetParent(), PATTACH_ABSORIGIN_FOLLOW, nil, self:GetParent():GetAbsOrigin(), true)
	ParticleManager:ReleaseParticleIndex(cast_pfx)
end
function modifier_black_king_bar_cus_invis:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ABILITY_EXECUTED,
		MODIFIER_EVENT_ON_ATTACK,
		MODIFIER_PROPERTY_INVISIBILITY_LEVEL,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
	}
end
function modifier_black_king_bar_cus_invis:OnAbilityExecuted(keys)
	if not IsServer() then return end
	if self:GetParent() ~= keys.unit then return end
	self:Destroy()
end
function modifier_black_king_bar_cus_invis:OnAttack(keys)
	if not IsServer() then return end
	local target = keys.target
	local attacker = keys.attacker
	
	if self:GetParent() ~= attacker then return end
	if not target then return end
	if not attacker then return end
	
	self:Destroy()
end
function modifier_black_king_bar_cus_invis:GetModifierInvisibilityLevel() return 1 end
function modifier_black_king_bar_cus_invis:GetModifierMoveSpeedBonus_Constant()
	return self.active_movement_speed
end
function modifier_black_king_bar_cus_invis:CheckState()
	return {[MODIFIER_STATE_INVISIBLE] = true}
end
