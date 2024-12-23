----------------------
-- Seaborn Sentinel --
----------------------
LinkLuaModifier("modifier_slrdr_seaborn_sentinel", "heroes/slardar/seaborn_sentinel", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_slrdr_seaborn_sentinel_river", "heroes/slardar/seaborn_sentinel", LUA_MODIFIER_MOTION_NONE)


slrdr_seaborn_sentinel = slrdr_seaborn_sentinel or class({})
function slrdr_seaborn_sentinel:GetIntrinsicModifierName() return "modifier_slrdr_seaborn_sentinel" end


modifier_slrdr_seaborn_sentinel = modifier_slrdr_seaborn_sentinel or class({})
function modifier_slrdr_seaborn_sentinel:IsHidden() return true end
function modifier_slrdr_seaborn_sentinel:OnCreated()
	if not IsServer() then return end
	self:StartIntervalThink(FrameTime())
end
function modifier_slrdr_seaborn_sentinel:OnIntervalThink()
	if not IsServer() then return end
	if not self:GetAbility() then return end
	local owner = self:GetParent()
--	print(owner:GetAbsOrigin().z)
	if not owner:PassivesDisabled() and (owner:HasModifier("modifier_slrdr_slithereen_crush_puddle") or owner:HasModifier("modifier_slrdr_corrosive_haze_puddle")) then
		owner:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_slrdr_seaborn_sentinel_river", {})
	else
		owner:RemoveModifierByName("modifier_slrdr_seaborn_sentinel_river")
	end
end


modifier_slrdr_seaborn_sentinel_river = modifier_slrdr_seaborn_sentinel_river or class({})
function modifier_slrdr_seaborn_sentinel_river:IsHidden() return true end
function modifier_slrdr_seaborn_sentinel_river:IsPurgable() return false end
function modifier_slrdr_seaborn_sentinel_river:OnCreated() self:OnRefresh() end
function modifier_slrdr_seaborn_sentinel_river:OnRefresh()
	self.hp_regen = self:GetAbility():GetSpecialValueFor("puddle_regen")
	self.armor = self:GetAbility():GetSpecialValueFor("puddle_armor")
	self.str = self:GetAbility():GetSpecialValueFor("puddle_strength")
	self.movement_pct = self:GetAbility():GetSpecialValueFor("puddle_speed")
end
function modifier_slrdr_seaborn_sentinel_river:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end
function modifier_slrdr_seaborn_sentinel_river:GetModifierConstantHealthRegen() return self.hp_regen end
function modifier_slrdr_seaborn_sentinel_river:GetModifierPhysicalArmorBonus() return self.armor end
function modifier_slrdr_seaborn_sentinel_river:GetModifierBonusStats_Strength() return self.str end
function modifier_slrdr_seaborn_sentinel_river:GetModifierMoveSpeedBonus_Percentage() return self.movement_pct end
