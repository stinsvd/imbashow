LinkLuaModifier("modifier_item_satanic_custom", "items/item_satanic_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_satanic_custom_buff", "items/item_satanic_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_satanic_custom_active", "items/item_satanic_custom", LUA_MODIFIER_MOTION_NONE)
for i = 1, 6 do
	LinkLuaModifier("modifier_item_satanic_custom"..i.."_buff", "items/item_satanic_custom", LUA_MODIFIER_MOTION_NONE)
end

item_satanic_1 = item_satanic_1 or class({})
item_satanic_2 = item_satanic_1
item_satanic_3 = item_satanic_1
item_satanic_4 = item_satanic_1
item_satanic_5 = item_satanic_1
item_satanic_6 = item_satanic_1

function item_satanic_1:GetIntrinsicModifierName()
	return "modifier_item_satanic_custom"
end

function item_satanic_1:OnSpellStart()
	local caster = self:GetCaster()
	local duration = self:GetSpecialValueFor("duration")

	caster:AddNewModifier(caster, self, "modifier_item_satanic_custom_active", {duration = duration})
	caster:Purge(false, true, false, false, false)
	EmitSoundOn("DOTA_Item.Satanic.Activate", caster)
end


modifier_item_satanic_custom_active = modifier_item_satanic_custom_active or class({})
function modifier_item_satanic_custom_active:IsHidden() return false end
function modifier_item_satanic_custom_active:GetEffectName()
	return "particles/items2_fx/satanic_buff.vpcf"
end
function modifier_item_satanic_custom_active:OnCreated() self:OnRefresh() end
function modifier_item_satanic_custom_active:OnRefresh()
	self.lifesteal_percent_activate = self:GetAbility():GetSpecialValueFor("lifesteal_percent_activate")
end
function modifier_item_satanic_custom_active:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_LANDED,
		MODIFIER_PROPERTY_TOOLTIP,
	}
end
function modifier_item_satanic_custom_active:OnAttackLanded(params)
	if not IsServer() then return end
	local ability = self:GetAbility()
	if not ability then return end
	
	local parent = self:GetParent()
	if params.attacker == parent and not params.target:IsBuilding() then
		local lifesteal = params.damage * (self.lifesteal_percent_activate / 100)
		parent:HealWithParams(lifesteal, ability, true, false, parent, false)

		local particle = ParticleManager:CreateParticle("particles/generic_gameplay/generic_lifesteal.vpcf", PATTACH_ABSORIGIN_FOLLOW, params.attacker)
		ParticleManager:ReleaseParticleIndex(particle)
	end
end
function modifier_item_satanic_custom_active:OnTooltip() return self.lifesteal_percent_activate end


modifier_item_satanic_custom = modifier_item_satanic_custom or class({})
function modifier_item_satanic_custom:IsHidden() return true end
function modifier_item_satanic_custom:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end
function modifier_item_satanic_custom:OnCreated()
	self.level = self:GetAbility():GetLevel()
end

function modifier_item_satanic_custom:IsAura() return true end
function modifier_item_satanic_custom:IsAuraActiveOnDeath() return false end
function modifier_item_satanic_custom:GetAuraRadius() if self:GetAbility() then return self:GetAbility():GetSpecialValueFor("aura_radius") end end
function modifier_item_satanic_custom:GetAuraSearchFlags() return DOTA_UNIT_TARGET_FLAG_INVULNERABLE end
function modifier_item_satanic_custom:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_FRIENDLY end
function modifier_item_satanic_custom:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC end
function modifier_item_satanic_custom:GetModifierAura() return "modifier_item_satanic_custom"..self.level.."_buff" end
function modifier_item_satanic_custom:GetAuraEntityReject(target)
	local level = self.level
	for i = 6, level + 1, -1 do
		if target:HasModifier("modifier_item_satanic_custom"..i.."_buff") then
			return true
		end
	end
end

function modifier_item_satanic_custom:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
	}
end
function modifier_item_satanic_custom:GetModifierBonusStats_Strength()
	if self:GetAbility() then return self:GetAbility():GetSpecialValueFor("bonus_strength") end
end
function modifier_item_satanic_custom:GetModifierPreAttack_BonusDamage()
	if self:GetAbility() then return self:GetAbility():GetSpecialValueFor("bonus_damage") end
end
function modifier_item_satanic_custom:GetModifierPhysicalArmorBonus()
	if self:GetAbility() then return self:GetAbility():GetSpecialValueFor("bonus_armor") end
end
function modifier_item_satanic_custom:GetModifierConstantManaRegen()
	if self:GetAbility() then return self:GetAbility():GetSpecialValueFor("bonus_mana_regen") end
end


modifier_item_satanic_custom_buff = modifier_item_satanic_custom_buff or class({})
function modifier_item_satanic_custom_buff:IsHidden() return false end
function modifier_item_satanic_custom_buff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE,
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_TOOLTIP,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end
function modifier_item_satanic_custom_buff:GetModifierBaseDamageOutgoing_Percentage()
	if self:GetAbility() then return self:GetAbility():GetSpecialValueFor("aura_damage_percent") end
end
function modifier_item_satanic_custom_buff:GetModifierConstantManaRegen()
	if self:GetAbility() then return self:GetAbility():GetSpecialValueFor("aura_mana_regen") end
end
function modifier_item_satanic_custom_buff:GetModifierPhysicalArmorBonus()
	if self:GetAbility() then return self:GetAbility():GetSpecialValueFor("aura_armor") end
end
function modifier_item_satanic_custom_buff:OnTooltip()
	if self:GetAbility() then return self:GetAbility():GetSpecialValueFor("lifesteal_percent") end
end
function modifier_item_satanic_custom_buff:OnAttackLanded(params)
	if not IsServer() then return end
	local ability = self:GetAbility()
	if not ability then return end
	
	local parent = self:GetParent()
	if params.attacker == parent and not params.target:IsBuilding() then
		local lifesteal_pct = ability:GetSpecialValueFor("lifesteal_percent")
		
		local lifesteal = (params.damage * lifesteal_pct) / 100
		parent:HealWithParams(lifesteal, ability, true, false, parent, false)

		local particle = ParticleManager:CreateParticle("particles/generic_gameplay/generic_lifesteal.vpcf", PATTACH_ABSORIGIN_FOLLOW, params.attacker)
		ParticleManager:ReleaseParticleIndex(particle)
	end
end


modifier_item_satanic_custom1_buff = modifier_item_satanic_custom_buff
modifier_item_satanic_custom2_buff = modifier_item_satanic_custom_buff
modifier_item_satanic_custom3_buff = modifier_item_satanic_custom_buff
modifier_item_satanic_custom4_buff = modifier_item_satanic_custom_buff
modifier_item_satanic_custom5_buff = modifier_item_satanic_custom_buff
modifier_item_satanic_custom6_buff = modifier_item_satanic_custom_buff
