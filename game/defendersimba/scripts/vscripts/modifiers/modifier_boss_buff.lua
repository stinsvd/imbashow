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
		self.strengthGain = 0
		if parent.GetStrengthGain then
			self.strengthGain = parent:GetStrengthGain()
		end
		self.agilityGain = 0
		if parent.GetAgilityGain then
			self.agilityGain = parent:GetAgilityGain()
		end
		self.intellectGain = 0
		if parent.GetIntellectGain then
			self.intellectGain = parent:GetIntellectGain()
		end
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


LinkLuaModifier("modifier_boss_healthbar", "modifiers/modifier_boss_buff", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_boss_healthbar_aura", "modifiers/modifier_boss_buff", LUA_MODIFIER_MOTION_NONE)

modifier_boss_healthbar = modifier_boss_healthbar or class({})
function modifier_boss_healthbar:IsHidden() return true end
function modifier_boss_healthbar:IsPurgable() return false end
function modifier_boss_healthbar:RemoveOnDeath() return true end
function modifier_boss_healthbar:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_TAKEDAMAGE,
	}
end
function modifier_boss_healthbar:OnTakeDamage(keys)
	if not IsServer() then return end
	local unit = keys.unit
	if not unit then return end
	local attacker = keys.attacker
	if not attacker then return end
	if unit == self:GetParent() then
		if not attacker:HasModifier("modifier_boss_healthbar_aura") then
			attacker:AddNewModifier(unit, nil, "modifier_boss_healthbar_aura", {duration = 5})
		end
	end
end
function modifier_boss_healthbar:IsAura() return self:GetParent():GetHealth() > 0 end
function modifier_boss_healthbar:GetAuraRadius() return 1200 end
function modifier_boss_healthbar:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_ENEMY end
function modifier_boss_healthbar:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO end
function modifier_boss_healthbar:GetModifierAura() return "modifier_boss_healthbar_aura" end

modifier_boss_healthbar_aura = modifier_boss_healthbar_aura or class({})
function modifier_boss_healthbar_aura:IsHidden() return true end
function modifier_boss_healthbar_aura:IsPurgable() return false end
function modifier_boss_healthbar_aura:OnCreated()
	if not IsServer() then return end
	self.owner = self:GetAuraOwner()
	if self:GetDuration() > 0 then
		self.owner = self:GetCaster()
	end
	self.playerID = self:GetParent():GetPlayerOwnerID()
	self.currentPlayer = PlayerResource:GetPlayer(self.playerID)
	if PlayerResource:IsValidPlayerID(self.playerID) then
		self:StartIntervalThink(0.1)
	end
end
function modifier_boss_healthbar_aura:OnIntervalThink()
	if not IsServer() then return end
	if not self.owner or not self.owner:IsAlive() then self:Destroy() return end
	if not self.currentPlayer then return end
	local unitindex = self.owner:entindex()
	local isVisible = self.owner:CanBeSeenByAnyOpposingTeam()
	local MaxHealth = self.owner:GetMaxHealth()
	local Health = self.owner:GetHealth()
	local MaxMana = -1
	local Mana = -1
	if self.owner.GetMaxMana then
		MaxMana = self.owner:GetMaxMana()
		Mana = self.owner:GetMana()
	end
	CustomGameEventManager:Send_ServerToPlayer(self.currentPlayer, "RefreshBossHealthbar", {index = unitindex, isVisible = isVisible, health = Health, maxHealth = MaxHealth, mana = Mana, maxMana = MaxMana})
end
function modifier_boss_healthbar_aura:OnDestroy()
	if not IsServer() then return end
	CustomGameEventManager:Send_ServerToPlayer(self.currentPlayer, "HideBossHealthbar", {})
end
function modifier_boss_healthbar_aura:CheckState()
	return {
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
	}
end
