modifier_boss_buff = modifier_boss_buff or class({})
function modifier_boss_buff:IsHidden() return false end
function modifier_boss_buff:IsPurgable() return false end
function modifier_boss_buff:IsPurgeException() return false end
function modifier_boss_buff:RemoveOnDeath() return false end
function modifier_boss_buff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
		MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
		MODIFIER_PROPERTY_MODEL_SCALE,
		MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE_STACKING,
	}
end

function modifier_boss_buff:OnCreated()
	local parent = self:GetParent()
	self.parent = parent
	self.multiplier = 4

	if IsServer() then
		self.strengthGain = parent:GetStrengthGain()
		self.agilityGain = parent:GetAgilityGain()
		self.intellectGain = parent:GetIntellectGain()
		self:SetHasCustomTransmitterData(true)
	end
	self.magicResistance = 25
	self.incomingDamage = -25
	self.statusResistance = 50
	self.cooldown_reduction = 50
	self.modelScale = 80
	self:StartIntervalThink(0.1)
end
function modifier_boss_buff:OnIntervalThink()
	if not IsServer() then return end
	if GameMode.bossFight ~= nil then
		local tp = self:GetParent():FindItemInInventory("item_tpscroll")
		if tp then
			tp:SetActivated(not GameMode.bossFight)
		end
	end
end
function modifier_boss_buff:AddCustomTransmitterData() return {strengthGain = self.strengthGain, agilityGain = self.agilityGain, intellectGain = self.intellectGain} end
function modifier_boss_buff:HandleCustomTransmitterData(data) self.strengthGain = data.strengthGain; self.agilityGain = data.agilityGain; self.intellectGain = data.intellectGain end

function modifier_boss_buff:GetModifierBonusStats_Strength()
	return (self.strengthGain * (self.parent:GetLevel() or 1)) * (self.multiplier - 1)
end

function modifier_boss_buff:GetModifierBonusStats_Agility()
	return (self.agilityGain * (self.parent:GetLevel() or 1)) * (self.multiplier - 1)
end

function modifier_boss_buff:GetModifierBonusStats_Intellect()
	return (self.intellectGain * (self.parent:GetLevel() or 1)) * (self.multiplier - 1)
end

function modifier_boss_buff:GetModifierMagicalResistanceBonus()
	return self.magicResistance
end

function modifier_boss_buff:GetModifierIncomingDamage_Percentage(event)
	local damageType = event.damage_type

	return self.incomingDamage
end

function modifier_boss_buff:GetModifierStatusResistanceStacking()
	return self.statusResistance
end

function modifier_boss_buff:GetModifierModelScale()
	return self.modelScale
end

function modifier_boss_buff:GetModifierPercentageCooldownStacking()
	return self.cooldown_reduction
end
