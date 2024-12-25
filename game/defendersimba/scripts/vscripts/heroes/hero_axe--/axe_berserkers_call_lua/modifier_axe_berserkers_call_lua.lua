-- Модификатор Бафф Для владельца способности
modifier_axe_berserkers_call_lua = class({
    IsHidden = function(self) return false end, -- скрыть иконку модификатора ?
    IsPurgable = function(self) return true end, --Развеивается?
    IsDebuff = function(self) return false end, --Дэбафф?
    DeclareFunctions = function(self) return
	{
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, -- бонусная броня
	} end,
})

function modifier_axe_berserkers_call_lua:OnCreated( kv )
	self.armor = self:GetAbility():GetSpecialValueFor( "bonus_armor" )
end

function modifier_axe_berserkers_call_lua:OnRefresh( kv )
	self.armor = self:GetAbility():GetSpecialValueFor( "bonus_armor" )
end

function modifier_axe_berserkers_call_lua:GetModifierPhysicalArmorBonus()
	return self.armor
end

function modifier_axe_berserkers_call_lua:GetEffectName()
	return "particles/units/heroes/hero_axe/axe_beserkers_call.vpcf"
end

function modifier_axe_berserkers_call_lua:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end