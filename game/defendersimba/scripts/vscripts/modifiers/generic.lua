LinkLuaModifier("modifier_generic_handler", "modifiers/generic", LUA_MODIFIER_MOTION_NONE)

modifier_generic_handler = class({})
function modifier_generic_handler:IsHidden() return true end
function modifier_generic_handler:IsPurgable() return false end
function modifier_generic_handler:IsPurgeException() return false end
function modifier_generic_handler:RemoveOnDeath() return false end
function modifier_generic_handler:OnCreated()
	if not IsServer() then return end
	self:OnIntervalThink()
	self:StartIntervalThink(1)
end
function modifier_generic_handler:OnIntervalThink()
	if not IsServer() then return end
	local parent = self:GetParent()
	if parent.CalculateStatBonus ~= nil then
		parent:CalculateStatBonus(false)
	end
end
function modifier_generic_handler:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_DIRECT_MODIFICATION,
	}
end
function modifier_generic_handler:GetModifierNoVisionOfAttacker() return 1 end
function modifier_generic_handler:GetModifierMagicalResistanceDirectModification()
	local parent = self:GetParent()
	if parent.GetIntellect then
		return parent:GetIntellect(false) * (0.02 - 0.1)
	end
end
