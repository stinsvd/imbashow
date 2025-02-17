LinkLuaModifier("modifier_item_magical_crit_custom", "items/item_magical_crit", LUA_MODIFIER_MOTION_NONE)

item_magical_crit_1 = class({})
item_magical_crit_2 = item_magical_crit_1
item_magical_crit_3 = item_magical_crit_1
item_magical_crit_4 = item_magical_crit_1
item_magical_crit_5 = item_magical_crit_1
item_magical_crit_6 = item_magical_crit_1

function item_magical_crit_1:GetIntrinsicModifierName()
    return "modifier_item_magical_crit_custom"
end


modifier_item_magical_crit_custom = modifier_item_magical_crit_custom or class({})
function modifier_item_magical_crit_custom:IsHidden() return true end
function modifier_item_magical_crit_custom:IsPurgable() return false end
function modifier_item_magical_crit_custom:IsPermanent() return true end
function modifier_item_magical_crit_custom:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end
function modifier_item_magical_crit_custom:OnCreated()
	self:OnRefresh()

	if not IsServer() then return end
	self:AddSpellCritModifier()
end
function modifier_item_magical_crit_custom:OnRefresh()
    self.critChance = self:GetAbility():GetSpecialValueFor("crit_chance")
    self.critMultiplier = self:GetAbility():GetSpecialValueFor("crit_multiplier")
end
function modifier_item_magical_crit_custom:GetModifierSpellCritDamage(event)
	if not IsServer() then return end
	if RollPercentage(self.critChance) then
		return self.critMultiplier - 100
	end
end

--[[
function modifier_item_magical_crit_custom:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
	}
end

function modifier_item_magical_crit_custom:GetModifierTotalDamageOutgoing_Percentage(event)
	if not IsServer() then return end
	local parent = self:GetParent()
	local attacker = event.attacker

	if not attacker then return end
	if attacker ~= self:GetParent() then return end
	if event.inflictor and event.inflictor:GetAbilityName() == "orcl_false_promise" then return end
	if event.damage_category ~= DOTA_DAMAGE_CATEGORY_SPELL then return end
	if bit.band(event.damage_flags, DOTA_DAMAGE_FLAG_REFLECTION) ~= DOTA_DAMAGE_FLAG_REFLECTION and RollPercentage(self.critChance) then
		local damage = event.original_damage * (self.critMultiplier / 100)
		local particle = ParticleManager:CreateParticle("particles/msg_fx/msg_crit.vpcf", PATTACH_OVERHEAD_FOLLOW, event.target)
		ParticleManager:SetParticleControl(particle, 1, Vector(9,damage,4))
		ParticleManager:SetParticleControl(particle, 2, Vector(1, 4, 0))
		ParticleManager:SetParticleControl(particle, 3, Vector(19,26,600))
		ParticleManager:ReleaseParticleIndex(particle)

		return self.critMultiplier - 100
	end
end
]]