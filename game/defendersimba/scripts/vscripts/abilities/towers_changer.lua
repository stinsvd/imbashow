LinkLuaModifier("modifier_towers_changer", "abilities/towers_changer", LUA_MODIFIER_MOTION_NONE)

modifier_towers_changer = class({})
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
			end
		end
	end
end
