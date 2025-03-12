-- modifiers/modifier_golem_ai.lua

modifier_golem_ai = modifier_golem_ai or class({})
function modifier_golem_ai:IsHidden() return true end
function modifier_golem_ai:IsPurgable() return false end
function modifier_golem_ai:OnCreated(kv)
	if not IsServer() then return end
	local golem = self:GetParent()
--	golem:SetAcquisitionRange(1600)

	local enemy_base = Entities:FindByName(nil, "dota_goodguys_fort")		--Vector(-10562, 10484, 634)

	if enemy_base then
		self.target_point = enemy_base:GetAbsOrigin()
		golem:MoveToPositionAggressive(self.target_point)

		self:OnIntervalThink()
		self:StartIntervalThink(0.5)
	end
end

function modifier_golem_ai:OnIntervalThink()
	if not IsServer() then return end
	local golem = self:GetParent()

	if golem and golem:IsAlive() then
		-- Если голем не атакует и не движется, продолжаем движение
		if not golem:IsAttacking() and not golem:IsMoving() then
			-- Проверяем, достиг ли голем точки назначения
			local current_position = golem:GetAbsOrigin()
			local distance_to_target = (self.target_point - current_position):Length2D()
			if distance_to_target < 100 then
				-- Достиг точки назначения, продолжаем движение в ту же точку
				golem:MoveToPositionAggressive(self.target_point)
				return
			end

			-- Ищем ближайших врагов
			local enemies = FindUnitsInRadius(golem:GetTeamNumber(), current_position, nil, golem:GetAcquisitionRange(), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NO_INVIS + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE, FIND_ANY_ORDER, false)
			if #enemies > 0 then
				golem:MoveToTargetToAttack(enemies[1])
			else
				local target
				local targetPos
				for _, towers in ipairs(GameMode.TowersTable) do
					local tower_1Unit = EntIndexToHScript(towers._1.unit)
					local tower_2Unit = EntIndexToHScript(towers._2.unit)
					if tower_1Unit and tower_2Unit and tower_1Unit:IsAlive() and tower_2Unit:IsAlive() and (towers._1.team == DOTA_TEAM_GOODGUYS or towers._2.team == DOTA_TEAM_GOODGUYS) then
						targetPos = Entities:FindByName(nil, towers.key.."_point"):GetAbsOrigin()
					end
				end
				if targetPos then
					local buildings = FindUnitsInRadius(golem:GetTeamNumber(), targetPos, nil, 1000, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BUILDING, DOTA_UNIT_TARGET_FLAG_NO_INVIS, FIND_ANY_ORDER, false)
					for i = 1, #buildings do
						if not buildings[i]:IsAttackImmune() or not buildings[i]:IsInvulnerable() and string.match(buildings[i]:GetUnitName(), "_tower_cus") then
							target = buildings[i]
							break
						end
					end
				else
					targetPos = self.target_point
				end
				if target then
					golem:MoveToPositionAggressive(target:GetAbsOrigin())
				else
					golem:MoveToPositionAggressive(targetPos)
				end
			end
		end
	end
end




modifier_morph_boss_ai = modifier_morph_boss_ai or class({})
function modifier_morph_boss_ai:IsHidden() return true end
function modifier_morph_boss_ai:IsPurgable() return false end
function modifier_morph_boss_ai:OnCreated()
	if not IsServer() then return end
	local morph = self:GetParent()
--	morph:SetAcquisitionRange(1600)

	local enemy_base = Entities:FindByName(nil, "dota_goodguys_fort")		--Vector(-10562, 10484, 634)

	if enemy_base then
		self.target_point = enemy_base:GetAbsOrigin()
		morph:MoveToPositionAggressive(self.target_point)

		self:OnIntervalThink()
		self:StartIntervalThink(0.5)
	end
end

function modifier_morph_boss_ai:OnIntervalThink()
	if not IsServer() then return end
	local morph = self:GetParent()

	if morph and morph:IsAlive() then
		if morph:IsChanneling() then return end
		local target
		local targetPos
		if not morph:IsAttacking() and not morph:IsMoving() then
			for _, towers in ipairs(GameMode.TowersTable) do
				local tower_1Unit = EntIndexToHScript(towers._1.unit)
				local tower_2Unit = EntIndexToHScript(towers._2.unit)
				if tower_1Unit and tower_2Unit and tower_1Unit:IsAlive() and tower_2Unit:IsAlive() and (towers._1.team == DOTA_TEAM_GOODGUYS or towers._2.team == DOTA_TEAM_GOODGUYS) then
					targetPos = Entities:FindByName(nil, towers.key.."_point"):GetAbsOrigin()
				end
			end
			if targetPos then
				local buildings = FindUnitsInRadius(morph:GetTeamNumber(), targetPos, nil, 1000, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BUILDING, DOTA_UNIT_TARGET_FLAG_NO_INVIS, FIND_ANY_ORDER, false)
				for i = 1, #buildings do
					if not buildings[i]:IsAttackImmune() or not buildings[i]:IsInvulnerable() and string.match(buildings[i]:GetUnitName(), "_tower_cus") then
						target = buildings[i]
						break
					end
				end
			else
				targetPos = self.target_point
			end
			if target then
				morph:MoveToPositionAggressive(target:GetAbsOrigin())
			else
				morph:MoveToPositionAggressive(targetPos)
			end
		end
		local delay = ThinkNextAbility(morph)
		self:StartIntervalThink(delay)
	end
end
function modifier_morph_boss_ai:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MANACOST_PERCENTAGE_STACKING,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
	}
end
function modifier_morph_boss_ai:GetModifierPercentageManacostStacking() return 100 end
function modifier_morph_boss_ai:GetModifierPhysicalArmorBonus() return self:GetStackCount() * 1 end



function ThinkNextAbility(unit)
	if not IsServer() then return end
	if unit:IsNull() or not unit:IsAlive() then return -1 end
	if unit:IsChanneling() then return 0.5 end

	local abilities = {}
	for i = 0, unit:GetAbilityCount() - 1 do
		local ability = unit:GetAbilityByIndex(i)
		if ability and not ability:IsAttributeBonus() and not ability:IsHidden() and not ability:IsPassive() then
			table.insert(abilities, ability)
		end
	end
	for i = 0, 5 do
		local item = unit:GetItemInSlot(i)
		if item and not item:IsPassive() then
			table.insert(abilities, item)
		end
	end
	if #abilities > 0 then
		local unitPos = unit:GetAbsOrigin()
		local unitTeam = unit:GetTeamNumber()
		local delay = TryToCastSomeAbility(abilities[RandomInt(1, #abilities)], unit, unitPos, unitTeam)
		if delay then
			return delay
		end
	end
	return 0.5
end
function TryToCastSomeAbility(ability, unit, unitPos, unitTeam)
	if ability:IsCooldownReady() then
		local ability_behavior = ability:GetBehaviorInt()
		local delay = (ability:GetCastPoint() or 0.1) * 3
		local radius = ability:GetCastRange(unitPos, unit)
		if radius == 0 then
			radius = ability:GetAOERadius()
		end
		if radius == 0 then
			radius = unit:GetAcquisitionRange()
		end
		if radius == 0 then
			radius = 800
		end
		local teams = ability:GetAbilityTargetTeam() or DOTA_UNIT_TARGET_TEAM_ENEMY
		local types = ability:GetAbilityTargetType() or DOTA_UNIT_TARGET_HEROES_AND_CREEPS
		local flags = ability:GetAbilityTargetFlags() or DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE
		local foundTargets = {}
		if bit.band(ability_behavior, DOTA_ABILITY_BEHAVIOR_UNIT_TARGET) == DOTA_ABILITY_BEHAVIOR_UNIT_TARGET then
			if teams == DOTA_UNIT_TARGET_TEAM_ENEMY then
				local enemies = FindUnitsInRadius(unitTeam, unitPos, nil, radius, teams, types, flags, FIND_ANY_ORDER, false)
				for _, enemy in ipairs(enemies) do
					if UnitFilter(enemy, teams, types, flags, unitTeam) == UF_SUCCESS then
						table.insert(foundTargets, enemy)
					end
				end
			elseif teams == DOTA_UNIT_TARGET_TEAM_FRIENDLY then
				if UnitFilter(unit, teams, types, flags, unitTeam) == UF_SUCCESS then
					table.insert(foundTargets, unit)
				else
					for _, ally in ipairs(FindUnitsInRadius(unitTeam, unitPos, nil, radius, teams, types, flags, FIND_ANY_ORDER, false)) do
						if UnitFilter(ally, teams, types, flags, unitTeam) == UF_SUCCESS then
							table.insert(foundTargets, ally)
						end
					end
				end
			else
				local enemies = FindUnitsInRadius(unitTeam, unitPos, nil, radius, teams, types, flags, FIND_ANY_ORDER, false)
				for _, enemy in ipairs(enemies) do
					if UnitFilter(enemy, teams, types, flags, unitTeam) == UF_SUCCESS then
						table.insert(foundTargets, enemy)
					end
				end
				for _, ally in ipairs(FindUnitsInRadius(unitTeam, unitPos, nil, radius, teams, types, flags, FIND_ANY_ORDER, false)) do
					if UnitFilter(ally, teams, types, flags, unitTeam) == UF_SUCCESS then
						table.insert(foundTargets, ally)
					end
				end
			end
		end
		
		if bit.band(ability_behavior, DOTA_ABILITY_BEHAVIOR_POINT) == DOTA_ABILITY_BEHAVIOR_POINT then
			if teams == DOTA_UNIT_TARGET_TEAM_ENEMY then
				local enemies = FindUnitsInRadius(unitTeam, unitPos, nil, radius, teams, types, flags, FIND_ANY_ORDER, false)
				for _, enemy in ipairs(enemies) do
					table.insert(foundTargets, enemy)
				end
			elseif teams == DOTA_UNIT_TARGET_TEAM_FRIENDLY then
				for _, ally in ipairs(FindUnitsInRadius(unitTeam, unitPos, nil, radius, teams, types, flags, FIND_ANY_ORDER, false)) do
					table.insert(foundTargets, ally)
				end
			else
				local enemies = FindUnitsInRadius(unitTeam, unitPos, nil, radius, teams, types, flags, FIND_ANY_ORDER, false)
				for _, enemy in ipairs(enemies) do
					table.insert(foundTargets, enemy)
				end
				for _, ally in ipairs(FindUnitsInRadius(unitTeam, unitPos, nil, radius, teams, types, flags, FIND_ANY_ORDER, false)) do
					table.insert(foundTargets, ally)
				end
			end
		end

		local abilCasted = false
		if bit.band(ability_behavior, DOTA_ABILITY_BEHAVIOR_NO_TARGET) == DOTA_ABILITY_BEHAVIOR_NO_TARGET then
			local enemies = FindUnitsInRadius(unitTeam, unitPos, nil, radius, teams, types, flags, FIND_ANY_ORDER, false)
			if #enemies > 0 then
				abilCasted = true
				unit:CastAbilityNoTarget(ability, unit:GetPlayerOwnerID())
			end
		end
		if #foundTargets > 0 then
			local foundTarget = foundTargets[RandomInt(1, #foundTargets)]
			if bit.band(ability_behavior, DOTA_ABILITY_BEHAVIOR_UNIT_TARGET) == DOTA_ABILITY_BEHAVIOR_UNIT_TARGET then
				abilCasted = true
				unit:CastAbilityOnTarget(foundTarget, ability, unit:GetPlayerOwnerID())
			end
			if bit.band(ability_behavior, DOTA_ABILITY_BEHAVIOR_POINT) == DOTA_ABILITY_BEHAVIOR_POINT then
				abilCasted = true
				unit:CastAbilityOnPosition(foundTarget:GetAbsOrigin(), ability, unit:GetPlayerOwnerID())
			end
		end
		if abilCasted then
			return delay
		end
	end
end



				--[[
				for _, enemy in ipairs(has_enemy) do
					print(ability:GetAbilityName(), UnitFilter(enemy, teams, types, flags, unit:GetTeamNumber()))
					if enemy:IsBuilding() and bit.band(flags, DOTA_UNIT_TARGET_BUILDING) ~= DOTA_UNIT_TARGET_BUILDING then
						goto continue
					end
					if radius == 0 or (unitPos - enemy:GetAbsOrigin()):Length2D() <= radius then
						if bit.band(ability_behavior, DOTA_ABILITY_BEHAVIOR_UNIT_TARGET) == DOTA_ABILITY_BEHAVIOR_UNIT_TARGET then
							local result = UnitFilter(enemy, teams, types, flags, unit:GetTeamNumber())
							if result == UF_SUCCESS then
								foundTarget = enemy
								unit:CastAbilityOnTarget(enemy, ability, unit:GetPlayerOwnerID())
							end
						elseif bit.band(ability_behavior, DOTA_ABILITY_BEHAVIOR_NO_TARGET) == DOTA_ABILITY_BEHAVIOR_NO_TARGET then
							foundTarget = enemy
							unit:CastAbilityNoTarget(ability, unit:GetPlayerOwnerID())
						elseif bit.band(ability_behavior, DOTA_ABILITY_BEHAVIOR_POINT) == DOTA_ABILITY_BEHAVIOR_POINT then
							foundTarget = enemy
							unit:CastAbilityOnPosition(enemy:GetAbsOrigin(), ability, unit:GetPlayerOwnerID())
						end
					end
					::continue::
				end
				]]