LinkLuaModifier("modifier_towers_changer", "abilities/towers_changer", LUA_MODIFIER_MOTION_NONE)

modifier_towers_changer = modifier_towers_changer or class({})
function modifier_towers_changer:IsHidden() return true end
function modifier_towers_changer:IsPurgable() return false end
function modifier_towers_changer:OnCreated()
	if not IsServer() then return end
	local owner = self:GetParent()
	self.unit = owner:entindex()
	self.team = owner:GetTeamNumber()
	self.entName = owner.entName
end
function modifier_towers_changer:OnRemoved(params)
	if not IsServer() then return end
	if params == true then
		self:GetParent():AddNoDraw()
		for _, towers in ipairs(GameMode.TowersTable) do
			if towers.key == self.entName[1] then
				local towerTable = towers[self.entName[2]]
				local team = towerTable.team == DOTA_TEAM_GOODGUYS and DOTA_TEAM_BADGUYS or DOTA_TEAM_GOODGUYS
				local nameT = team == DOTA_TEAM_GOODGUYS and "npc_dota_goodguys_tower_cus" or "npc_dota_badguys_tower_cus"
				local unit = CreateUnitByName(nameT, self:GetParent():GetAbsOrigin(), true, nil, nil, team)
				unit.entName = self.entName
				towerTable.unit = unit:entindex()
				towerTable.team = team
				unit:SetAbsOrigin(self:GetParent():GetAbsOrigin())
				unit:AddNewModifier(unit, nil, "modifier_towers_changer", {})
				unit:RemoveModifierByName("modifier_invulnerable")
				GameMode:RefreshTowersInvul()
			end
		end
	end
end



LinkLuaModifier("modifier_towers_tier", "abilities/towers_changer", LUA_MODIFIER_MOTION_NONE)

modifier_towers_tier = modifier_towers_tier or class({})
function modifier_towers_tier:IsHidden() return true end
function modifier_towers_tier:IsPurgable() return false end
function modifier_towers_tier:OnCreated()
	self.bonus_health = 100
	self.bonus_health_regen = 2
	self.bonus_armor = 1
	self.bonus_magic_armor = 2

	if not IsServer() then return end
	self.baseHP = self:GetParent():GetMaxHealth()
end
function modifier_towers_tier:OnStackCountChanged(old)
	if not IsServer() then return end
	local owner = self:GetParent()
	local bonusHealth = self.bonus_health * self:GetStackCount()
	owner:SetMaxHealth((self.baseHP or 1800) + bonusHealth)
	owner:SetBaseMaxHealth((self.baseHP or 1800) + bonusHealth)
	owner:Heal(bonusHealth, nil)
	owner:CalculateGenericBonuses()
end
function modifier_towers_tier:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
	}
end
function modifier_towers_tier:GetModifierConstantHealthRegen()
	return self.bonus_health_regen * self:GetStackCount()
end
function modifier_towers_tier:GetModifierPhysicalArmorBonus()
	return self.bonus_armor * self:GetStackCount()
end
function modifier_towers_tier:GetModifierMagicalResistanceBonus()
	return self.bonus_magic_armor * self:GetStackCount()
end
