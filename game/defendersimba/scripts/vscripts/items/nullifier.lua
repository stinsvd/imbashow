LinkLuaModifier("modifier_nullifier_cus", "items/nullifier", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_nullifier_cus_debuff", "items/nullifier", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_nullifier_cus_slow", "items/nullifier", LUA_MODIFIER_MOTION_NONE)

item_nullifier_cus = item_nullifier_cus or class({})
function item_nullifier_cus:Precache(context)
	PrecacheResource("particle", "particles/items4_fx/nullifier_proj.vpcf", context)
	PrecacheResource("particle", "particles/items4_fx/nullifier_mute.vpcf", context)
	PrecacheResource("particle", "particles/items4_fx/nullifier_slow.vpcf", context)
end
function item_nullifier_cus:GetIntrinsicModifierName() return "modifier_nullifier_cus" end
function item_nullifier_cus:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local projectile_speed = self:GetSpecialValueFor("projectile_speed")

	target:EmitSound("DOTA_Item.Nullifier.Cast")
	local info = {
		Target = target,
		Source = caster,
		Ability = self,
		EffectName = "particles/items4_fx/nullifier_proj.vpcf",
		iMoveSpeed = projectile_speed,
		bDodgeable = true,
		bVisibleToEnemies = true,
		iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_HITLOCATION,
	}
	ProjectileManager:CreateTrackingProjectile(info)
end
function item_nullifier_cus:OnProjectileHit(target, loc)
	if not IsServer() then return end
	if not target then return end
	if target:TriggerSpellAbsorb(self) then return end
	local caster = self:GetCaster()
	target:EmitSound("DOTA_Item.Nullifier.Target")
	if not target:IsDebuffImmune() then
		target:Purge(true, false, false, false, false)
	end
	local duration = self:GetSpecialValueFor("mute_duration")
	target:AddNewModifier(caster, self, "modifier_nullifier_cus_debuff", {duration = duration * (1 - target:GetStatusResistance())})
end

item_nullifier_2_cus = item_nullifier_cus
item_nullifier_3_cus = item_nullifier_cus
item_nullifier_4_cus = item_nullifier_cus
item_nullifier_5_cus = item_nullifier_cus
item_nullifier_6_cus = item_nullifier_cus

modifier_nullifier_cus = modifier_nullifier_cus or class({})
function modifier_nullifier_cus:IsHidden() return true end
function modifier_nullifier_cus:IsPurgable() return false end
function modifier_nullifier_cus:IsPermanent() return true end
function modifier_nullifier_cus:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end
function modifier_nullifier_cus:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_EVENT_ON_ATTACKED,
	}
end
function modifier_nullifier_cus:GetModifierConstantHealthRegen()
	if self:GetAbility() then return self:GetAbility():GetSpecialValueFor("bonus_regen") end
end
function modifier_nullifier_cus:GetModifierPhysicalArmorBonus()
	if self:GetAbility() then return self:GetAbility():GetSpecialValueFor("bonus_armor") end
end
function modifier_nullifier_cus:GetModifierPreAttack_BonusDamage()
	if self:GetAbility() then return self:GetAbility():GetSpecialValueFor("bonus_damage") end
end

modifier_nullifier_cus_debuff = modifier_nullifier_cus_debuff or class({})
function modifier_nullifier_cus_debuff:IsHidden() return false end
function modifier_nullifier_cus_debuff:IsPurgable() return false end
function modifier_nullifier_cus_debuff:GetAttributes() return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end
function modifier_nullifier_cus_debuff:GetEffectName() return "particles/items4_fx/nullifier_mute.vpcf" end
function modifier_nullifier_cus_debuff:GetEffectAttachType() return PATTACH_OVERHEAD_FOLLOW end
function modifier_nullifier_cus_debuff:OnCreated()
	self:OnRefresh()

	if not IsServer() then return end
	self:StartIntervalThink(0.2)
end
function modifier_nullifier_cus_debuff:OnRefresh()
	self.slow = self:GetAbility():GetSpecialValueFor("slow_pct") * (-1)
	if not IsServer() then return end
	self.slow_duration = self:GetAbility():GetSpecialValueFor("slow_interval_duration")
end
function modifier_nullifier_cus_debuff:OnIntervalThink()
	if not IsServer() then return end
	if self:GetParent():IsDebuffImmune() then return end
	self:GetParent():Purge(true, false, false, false, false)
end
function modifier_nullifier_cus_debuff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
--		MODIFIER_EVENT_ON_ATTACKED,
	}
end
function modifier_nullifier_cus_debuff:GetModifierMoveSpeedBonus_Percentage() return self.slow end
--[[
function modifier_nullifier_cus_debuff:OnAttacked(keys)
	if not IsServer() then return end
	local ability = self:GetAbility()
	if not ability then return end
	local target = keys.target
	if not target then return end
	if target ~= self:GetParent() then return end
	target:EmitSound("DOTA_Item.Nullifier.Slow")
	target:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_nullifier_cus_slow", {duration = self.slow_duration * (1 - target:GetStatusResistance())})
end
]]

modifier_nullifier_cus_slow = modifier_nullifier_cus_slow or class({})
function modifier_nullifier_cus_slow:IsHidden() return false end
function modifier_nullifier_cus_slow:IsPurgable() return true end
function modifier_nullifier_cus_slow:OnCreated()
	self:OnRefresh()

	if not IsServer() then return end
	local amb_pfx = ParticleManager:CreateParticle("particles/items4_fx/nullifier_slow.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster())
	ParticleManager:SetParticleControlEnt(amb_pfx, 0, self:GetParent(), PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), true)
	self:AddParticle(amb_pfx, false, false, -1, false, false)
end
function modifier_nullifier_cus_slow:OnRefresh()
	self.slow = self:GetAbility():GetSpecialValueFor("slow_pct") * (-1)
end
function modifier_nullifier_cus_slow:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end
function modifier_nullifier_cus_slow:GetModifierMoveSpeedBonus_Percentage() return self.slow end

