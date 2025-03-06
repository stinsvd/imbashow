---------------------
-- Mask of Madness --
---------------------
LinkLuaModifier("modifier_mask_of_madness_cus", "items/mask_of_madness", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_mask_of_madness_cus_active", "items/mask_of_madness", LUA_MODIFIER_MOTION_NONE)

item_mask_of_madness_cus = item_mask_of_madness_cus or class({})
function item_mask_of_madness_cus:GetIntrinsicModifierName() return "modifier_mask_of_madness_cus" end
function item_mask_of_madness_cus:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	caster:EmitSound("DOTA_Item.MaskOfMadness.Activate")
	caster:AddNewModifier(caster, self, "modifier_mask_of_madness_cus_active", {duration = self:GetSpecialValueFor("berserk_duration")})
end

item_mask_of_madness_2_cus = item_mask_of_madness_cus
item_mask_of_madness_3_cus = item_mask_of_madness_cus
item_mask_of_madness_4_cus = item_mask_of_madness_cus
item_mask_of_madness_5_cus = item_mask_of_madness_cus

modifier_mask_of_madness_cus = modifier_mask_of_madness_cus or class({})
function modifier_mask_of_madness_cus:IsHidden() return true end
function modifier_mask_of_madness_cus:IsPurgable() return false end
function modifier_mask_of_madness_cus:IsPermanent() return true end
function modifier_mask_of_madness_cus:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end
function modifier_mask_of_madness_cus:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_EVENT_ON_TAKEDAMAGE,
	}
end
function modifier_mask_of_madness_cus:GetModifierPreAttack_BonusDamage()
	if self:GetAbility() then return self:GetAbility():GetSpecialValueFor("bonus_damage") end
end
function modifier_mask_of_madness_cus:GetModifierAttackSpeedBonus_Constant()
	if self:GetAbility() then return self:GetAbility():GetSpecialValueFor("bonus_attack_speed") end
end
function modifier_mask_of_madness_cus:OnTakeDamage(keys)
	if not IsServer() then return end
	local ability = self:GetAbility()
	if not ability then return end
	if not keys.unit then return end
	local attacker = keys.attacker
	if not attacker then return end
	if attacker ~= self:GetParent() then return end
	local damage = keys.damage
	if damage <= 0 then return end
	if keys.damage_category ~= DOTA_DAMAGE_CATEGORY_ATTACK then return end
	if keys.damage_type ~= DAMAGE_TYPE_PHYSICAL then return end
	
	local lifesteal = ability:GetSpecialValueFor("lifesteal_percent")
	local heal = damage * (lifesteal / 100)
	attacker:HealWithParams(heal, ability, true, true, attacker, false)
end

-- Mask of Madness Active --
modifier_mask_of_madness_cus_active = modifier_mask_of_madness_cus_active or class({})
function modifier_mask_of_madness_cus_active:IsHidden() return false end
function modifier_mask_of_madness_cus_active:IsDebuff() return false end
function modifier_mask_of_madness_cus_active:IsPurgable() return false end
function modifier_mask_of_madness_cus_active:GetTexture() return "mask_of_madness" end
function modifier_mask_of_madness_cus_active:GetEffectName() return "particles/items2_fx/mask_of_madness.vpcf" end
function modifier_mask_of_madness_cus_active:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end
function modifier_mask_of_madness_cus_active:OnCreated() self:OnRefresh() end
function modifier_mask_of_madness_cus_active:OnRefresh()
	self.berserk_bonus_attack_speed = self:GetAbility():GetSpecialValueFor("berserk_bonus_attack_speed")
	self.berserk_bonus_movement_speed = self:GetAbility():GetSpecialValueFor("berserk_bonus_movement_speed")
	self.berserk_armor_reduction = self:GetAbility():GetSpecialValueFor("berserk_armor_reduction") * (-1)
end
function modifier_mask_of_madness_cus_active:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
	}
end
function modifier_mask_of_madness_cus_active:GetModifierAttackSpeedBonus_Constant() return self.berserk_bonus_attack_speed end
function modifier_mask_of_madness_cus_active:GetModifierMoveSpeedBonus_Constant() return self.berserk_bonus_movement_speed end
function modifier_mask_of_madness_cus_active:GetModifierPhysicalArmorBonus() return self.berserk_armor_reduction end
function modifier_mask_of_madness_cus_active:CheckState()
	return {
		[MODIFIER_STATE_SILENCED] = true,
	}
end
