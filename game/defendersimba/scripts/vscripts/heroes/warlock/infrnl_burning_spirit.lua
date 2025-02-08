--------------------
-- Burning Spirit --
--------------------
LinkLuaModifier("modifier_infrnl_burning_spirit", "heroes/warlock/infrnl_burning_spirit", LUA_MODIFIER_MOTION_NONE)

infrnl_burning_spirit = infrnl_burning_spirit or class({})
function infrnl_burning_spirit:Precache(context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_doombringer.vsndevts", context)
	PrecacheResource("particle", "particles/units/heroes/hero_doom_bringer/doom_bringer_devour.vpcf", context)
end
function infrnl_burning_spirit:GetIntrinsicModifierName() return "modifier_infrnl_burning_spirit" end


modifier_infrnl_burning_spirit = modifier_infrnl_burning_spirit or class({})
function modifier_infrnl_burning_spirit:IsHidden() return self:GetStackCount() == 0 end
function modifier_infrnl_burning_spirit:IsPurgable() return false end
function modifier_infrnl_burning_spirit:OnCreated()
	if not IsServer() then return end
	self.allUpgrades = {
		bonus_health = 0,
		bonus_mana = 0,
		bonus_hp_regen = 0,
		infrnl_stomp_impact_base_damage = 0,
		infrnl_stomp_burn_base_damage = 0,
		infrnl_flaming_fists_base_damage = 0,
		infrnl_immolation_base_damage_per_second = 0,
		infrnl_eonite_heart_burn_damage = 0,
	}
	self:SetHasCustomTransmitterData(true)
end
function modifier_infrnl_burning_spirit:OnStackCountChanged(old)
	if not IsServer() then return end
	self:StartIntervalThink(1)
end
function modifier_infrnl_burning_spirit:OnIntervalThink()
	if not IsServer() then return end
	self:Upgrade()
	self:DecrementStackCount()

	local caster = self:GetCaster()
	local devour = ParticleManager:CreateParticle("particles/units/heroes/hero_doom_bringer/doom_bringer_devour.vpcf", PATTACH_POINT_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(devour, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(devour, 1, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
	ParticleManager:ReleaseParticleIndex(devour)
	EmitSoundOn("Hero_DoomBringer.Devour", caster)

	if self:GetStackCount() <= 0 then
		self:StartIntervalThink(-1)
	end
end
function modifier_infrnl_burning_spirit:AddCustomTransmitterData()
	return self.allUpgrades
end
function modifier_infrnl_burning_spirit:HandleCustomTransmitterData(data)
	self.allUpgrades = {}
	for k, v in pairs(data) do
		self.allUpgrades[k] = v
	end
end
function modifier_infrnl_burning_spirit:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_HEALTH_BONUS,
		MODIFIER_PROPERTY_MANA_BONUS,
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
	--	MODIFIER_EVENT_ON_ABILITY_EXECUTED,
		MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL,
		MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL_VALUE,
	}
end
function modifier_infrnl_burning_spirit:GetModifierHealthBonus()
	if self.allUpgrades then return self.allUpgrades.bonus_health end
end
function modifier_infrnl_burning_spirit:GetModifierManaBonus()
	if self.allUpgrades then return self.allUpgrades.bonus_mana end
end
function modifier_infrnl_burning_spirit:GetModifierConstantHealthRegen()
	if self.allUpgrades then return self.allUpgrades.bonus_hp_regen end
end
--[[
function modifier_infrnl_burning_spirit:OnAbilityExecuted(keys)
	if not IsServer() then return end
	if keys.unit == self:GetParent() then
		local ability = keys.ability
		if not ability then return end
		if keys.unit:IsIllusion() then return end
		if ability:IsItem() then return end
		if ability:IsToggle() then return end
		if not ability:ProcsMagicStick() then return end
		
		local count = self:GetAbility():GetSpecialValueFor("upgrades_per_cast")
		for i = 1, count do
			self:Upgrade()
		end
	end
end
]]
function modifier_infrnl_burning_spirit:GetModifierOverrideAbilitySpecial(keys)
	if self:GetParent() == nil or keys.ability == nil then return 0 end
	local abilityName = keys.ability:GetAbilityName()
	local valueName = keys.ability_special_value
	local taable = self.allUpgrades[abilityName.."_"..valueName]
	if taable ~= nil and taable > 0 then
		return 1
	end
end
function modifier_infrnl_burning_spirit:GetModifierOverrideAbilitySpecialValue(keys)
	local ability = keys.ability
	local abilityName = ability:GetAbilityName()
	local valueName = keys.ability_special_value
	local taable = self.allUpgrades[abilityName.."_"..valueName]
	if taable ~= nil and taable > 0 then
		return ability:GetLevelSpecialValueNoOverride(valueName, keys.ability_special_level) + (taable * ability:GetSpecialValueFor("up_"..valueName))
	end
end

function modifier_infrnl_burning_spirit:Upgrade(num)
	if not IsServer() then return end
	if not self:GetAbility() then return end
	local buff = num or RandomInt(1, 9)
	local count = self:GetAbility():GetSpecialValueFor("upgrades_per_cast")
	for i = 1, count do
		local owner = self:GetParent()
	--	print(buff)
		if buff == 1 then
			self.allUpgrades.bonus_health = self.allUpgrades.bonus_health + self:GetAbility():GetSpecialValueFor("bonus_health")
		elseif buff == 2 then
			self.allUpgrades.bonus_mana = self.allUpgrades.bonus_mana + self:GetAbility():GetSpecialValueFor("bonus_mana")
		elseif buff == 3 then
			self.allUpgrades.bonus_hp_regen = self.allUpgrades.bonus_hp_regen + self:GetAbility():GetSpecialValueFor("bonus_hp_regen")
		elseif buff == 4 then
			local bonus_gold = self:GetAbility():GetSpecialValueFor("bonus_gold") * owner:GetLevel()
			local midas_particle = ParticleManager:CreateParticle("particles/items2_fx/hand_of_midas.vpcf", PATTACH_ABSORIGIN_FOLLOW, owner)
			ParticleManager:SetParticleControlEnt(midas_particle, 0, owner, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", owner:GetAbsOrigin(), false)
			ParticleManager:SetParticleControlEnt(midas_particle, 1, owner, PATTACH_POINT_FOLLOW, "attach_hitloc", owner:GetAbsOrigin(), false)
			ParticleManager:ReleaseParticleIndex(midas_particle)
			owner:ModifyGold(bonus_gold, true, 0)
			EmitSoundOnClient("DOTA_Item.Hand_Of_Midas", owner:GetPlayerOwner())
			SendOverheadEventMessage(PlayerResource:GetPlayer(owner:GetPlayerOwnerID()), OVERHEAD_ALERT_GOLD, owner, bonus_gold, nil)
		elseif buff == 5 then
			local bonus_exp = self:GetAbility():GetSpecialValueFor("bonus_exp") * owner:GetLevel()
			owner:AddExperience(bonus_exp, 4, false, false)
			EmitSoundOnClient("Item.TomeOfKnowledge", owner:GetPlayerOwner())
			SendOverheadEventMessage(PlayerResource:GetPlayer(owner:GetPlayerOwnerID()), OVERHEAD_ALERT_XP, owner, bonus_exp, nil)
		elseif buff == 6 then
			self.allUpgrades.infrnl_stomp_impact_base_damage = self.allUpgrades.infrnl_stomp_impact_base_damage + 1
			self.allUpgrades.infrnl_stomp_burn_base_damage = self.allUpgrades.infrnl_stomp_burn_base_damage + 1
		elseif buff == 7 then
			self.allUpgrades.infrnl_flaming_fists_base_damage = self.allUpgrades.infrnl_flaming_fists_base_damage + 1
		elseif buff == 8 then
			self.allUpgrades.infrnl_immolation_base_damage_per_second = self.allUpgrades.infrnl_immolation_base_damage_per_second + 1
		elseif buff == 9 then
			self.allUpgrades.infrnl_eonite_heart_burn_damage = self.allUpgrades.infrnl_eonite_heart_burn_damage + 1
		end
		self:SendBuffRefreshToClients()
		
		if owner.CalculateStatBonus ~= nil then
			owner:CalculateStatBonus(false)
		end
	end
end
