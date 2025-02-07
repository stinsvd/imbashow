LinkLuaModifier("modifier_item_assault_cuirass_custom", "items/item_assault_cuirass", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_assault_cuirass_armor_reduction", "items/item_assault_cuirass", LUA_MODIFIER_MOTION_NONE)
for i = 1, 6 do
	LinkLuaModifier("modifier_assault_cuirass"..i.."_armor_reduction", "items/item_assault_cuirass", LUA_MODIFIER_MOTION_NONE)
end

item_assault_cuirass_1 = class({})
item_assault_cuirass_2 = item_assault_cuirass_1
item_assault_cuirass_3 = item_assault_cuirass_1
item_assault_cuirass_4 = item_assault_cuirass_1
item_assault_cuirass_5 = item_assault_cuirass_1
item_assault_cuirass_6 = item_assault_cuirass_1

function item_assault_cuirass_1:GetIntrinsicModifierName() return "modifier_item_assault_cuirass_custom" end


modifier_item_assault_cuirass_custom = modifier_item_assault_cuirass_custom or class({})
function modifier_item_assault_cuirass_custom:IsHidden() return true end
function modifier_item_assault_cuirass_custom:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end
function modifier_item_assault_cuirass_custom:OnCreated()
	self.level = self:GetAbility():GetLevel()
end
function modifier_item_assault_cuirass_custom:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
	}
end
function modifier_item_assault_cuirass_custom:GetModifierAttackSpeedBonus_Constant()
	if self:GetAbility() then return self:GetAbility():GetSpecialValueFor("bonus_attack_speed") end
end
function modifier_item_assault_cuirass_custom:GetModifierPhysicalArmorBonus()
	if self:GetAbility() then return self:GetAbility():GetSpecialValueFor("bonus_armor") end
end
function modifier_item_assault_cuirass_custom:GetModifierConstantHealthRegen()
	if self:GetAbility() then return self:GetAbility():GetSpecialValueFor("bonus_health_regen") end
end

function modifier_item_assault_cuirass_custom:IsAura() return true end
function modifier_item_assault_cuirass_custom:GetAuraRadius()
	if self:GetAbility() then return self:GetAbility():GetSpecialValueFor("aura_radius") end
end
function modifier_item_assault_cuirass_custom:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_ENEMY end
function modifier_item_assault_cuirass_custom:GetAuraSearchType() return DOTA_UNIT_TARGET_HEROES_AND_CREEPS end
function modifier_item_assault_cuirass_custom:GetAuraSearchFlags() return DOTA_UNIT_TARGET_FLAG_NONE end
function modifier_item_assault_cuirass_custom:GetModifierAura() return "modifier_assault_cuirass"..self.level.."_armor_reduction" end
function modifier_item_assault_cuirass_custom:GetAuraEntityReject(target)
	local level = self.level
	for i = 6, level + 1, -1 do
		if target:HasModifier("modifier_assault_cuirass"..i.."_armor_reduction") then
			return true
		end
	end
end


modifier_assault_cuirass_armor_reduction = modifier_assault_cuirass_armor_reduction or class({})
function modifier_assault_cuirass_armor_reduction:IsHidden() return false end
function modifier_assault_cuirass_armor_reduction:DeclareFunctions()
	return {MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS}
end
function modifier_assault_cuirass_armor_reduction:GetModifierPhysicalArmorBonus()
	if self:GetAbility() then return self:GetAbility():GetSpecialValueFor("armor_reduction") end
end


modifier_assault_cuirass1_armor_reduction = modifier_assault_cuirass_armor_reduction
modifier_assault_cuirass2_armor_reduction = modifier_assault_cuirass_armor_reduction
modifier_assault_cuirass3_armor_reduction = modifier_assault_cuirass_armor_reduction
modifier_assault_cuirass4_armor_reduction = modifier_assault_cuirass_armor_reduction
modifier_assault_cuirass5_armor_reduction = modifier_assault_cuirass_armor_reduction
modifier_assault_cuirass6_armor_reduction = modifier_assault_cuirass_armor_reduction
