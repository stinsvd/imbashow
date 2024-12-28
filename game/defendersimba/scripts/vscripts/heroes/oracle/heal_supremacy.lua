--------------------
-- Heal Supremacy --
--------------------
LinkLuaModifier("modifier_orcl_heal_supremacy", "heroes/oracle/heal_supremacy", LUA_MODIFIER_MOTION_NONE)


orcl_heal_supremacy = orcl_heal_supremacy or class({})
function orcl_heal_supremacy:GetIntrinsicModifierName() return "modifier_orcl_heal_supremacy" end


modifier_orcl_heal_supremacy = modifier_orcl_heal_supremacy or class({})
function modifier_orcl_heal_supremacy:IsHidden() return false end
function modifier_orcl_heal_supremacy:IsPurgable() return false end
function modifier_orcl_heal_supremacy:OnCreated()
	if not IsServer() then return end
	self.healing = 0
	self:SetHasCustomTransmitterData(true)
	self:OnIntervalThink()
	self:StartIntervalThink(1)
end
function modifier_orcl_heal_supremacy:OnIntervalThink()
	if not IsServer() then return end
	if not self:GetAbility() then return end
	self.healing = PlayerResource:GetHealing(self:GetCaster():GetPlayerOwnerID()) / self:GetAbility():GetSpecialValueFor("healing_to_stack")
	self:SendBuffRefreshToClients()
end
function modifier_orcl_heal_supremacy:AddCustomTransmitterData() return {healing = self.healing} end
function modifier_orcl_heal_supremacy:HandleCustomTransmitterData(data) self.healing = data.healing end
function modifier_orcl_heal_supremacy:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_SOURCE,
	}
end
function modifier_orcl_heal_supremacy:GetModifierHealAmplify_PercentageSource()
	if self:GetAbility() then return math.min(100, (self.healing * self:GetAbility():GetSpecialValueFor("heal_amp_per_stack"))) end
end
