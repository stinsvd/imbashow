require('tables/neutral_camps')

if NeutralManager == nil then
	NeutralManager = class({})
end

-- Время спавна нейтралов
NM_SPAWN_TIME = 10
NeutralManager.LevelsUnlocked = {}

function NeutralManager:Init()
	local maxLevel = 6
	local maxUnlockedLevels = 1
	local options = CustomNetTables:GetTableValue("game_options", "creepLevel")
	if options then
		maxUnlockedLevels = options.current
	end
	for level = 1, 10 do
		if level <= maxUnlockedLevels then
			NeutralManager:UnlockNeutralCamp(level)
		end
		if level > maxLevel then
			NeutralManager:UnlockNeutralCamp(level)
		end
	end

	ListenToGameEvent("entity_killed", Dynamic_Wrap(NeutralManager, "OnEntityKilled"), self)
end

function NeutralManager:UnlockNeutralCamp(level)
	if not NeutralManager.LevelsUnlocked[level] then
		NeutralManager.LevelsUnlocked[level] = true
		if level <= 6 then
			CustomNetTables:SetTableValue("game_options", "creepLevel", {current = level})
		end

		local points = Entities:FindAllByName("creeps_"..level.."_point")
		
		if level == 6 then
			GameMode:TransformPlayerToBoss()
		end
		
		for _, point in ipairs(points) do
			point.level = level
			if level > 6 then
				AddFOWViewer(DOTA_TEAM_BADGUYS, point:GetAbsOrigin(), 1000, 86400, true)
			end
			self:SpawnCamp(point)
		end
	end
end

function NeutralManager:SpawnCamp(point)
	local camps = NEUTRAL_CAMPS[point.level]
	local spawnPoint = point:GetAbsOrigin()
	local camp = camps[RandomInt(1, #camps)]

	local countUnits = 0
	for _, npc in ipairs(camp) do
		countUnits = countUnits + npc.count
	end
	point.countUnits = countUnits

	for _, npc in ipairs(camp) do
		for i = 1, npc.count do
			local unit = CreateUnitByName(npc.unit, spawnPoint + RandomVector(RandomInt(25, 125)), true, nil, nil, DOTA_TEAM_NEUTRALS)
			unit.neutralCamp = point
		end
	end
end

function NeutralManager:OnEntityKilled(event)
	local killedUnit = EntIndexToHScript(event.entindex_killed)

	if killedUnit.neutralCamp then
		local point = killedUnit.neutralCamp
		point.countUnits = point.countUnits - 1
	--	print(point.countUnits)
		if point.countUnits <= 0 then
			if NM_SPAWN_TIME > 0 then
				Timers:CreateTimer(NM_SPAWN_TIME, function()
					self:SpawnCamp(point)
				end)
			end
		end
	end
end
