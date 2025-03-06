---------------
-- Refresher --
---------------
LinkLuaModifier("modifier_refresher_cus", "items/refresher", LUA_MODIFIER_MOTION_NONE)

item_refresher_cus = item_refresher_cus or class({})
function item_refresher_cus:Precache(context)
	PrecacheResource("particle", "particles/items2_fx/refresher.vpcf", context)
end
function item_refresher_cus:IsRefreshable() return false end
function item_refresher_cus:GetIntrinsicModifierName() return "modifier_refresher_cus" end
function item_refresher_cus:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	
	RefreshThings(caster, 100, true, true, false, true)
	
	caster:EmitSound("DOTA_Item.Refresher.Activate")
	local refresh_fx = ParticleManager:CreateParticle("particles/items2_fx/refresher.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(refresh_fx, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
	ParticleManager:ReleaseParticleIndex(refresh_fx)
end

item_refresher_2_cus = item_refresher_cus
item_refresher_3_cus = item_refresher_cus
item_refresher_4_cus = item_refresher_cus
item_refresher_5_cus = item_refresher_cus
item_refresher_6_cus = item_refresher_cus

modifier_refresher_cus = modifier_refresher_cus or class({})
function modifier_refresher_cus:IsHidden() return true end
function modifier_refresher_cus:IsPurgable() return false end
function modifier_refresher_cus:IsPermanent() return true end
function modifier_refresher_cus:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end
function modifier_refresher_cus:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
	}
end
function modifier_refresher_cus:GetModifierConstantHealthRegen()
	if self:GetAbility() then return self:GetAbility():GetSpecialValueFor("bonus_health_regen") end
end
function modifier_refresher_cus:GetModifierConstantManaRegen()
	if self:GetAbility() then return self:GetAbility():GetSpecialValueFor("bonus_mana_regen") end
end
function modifier_refresher_cus:GetModifierPreAttack_BonusDamage()
	if self:GetAbility() then return self:GetAbility():GetSpecialValueFor("bonus_damage") end
end
