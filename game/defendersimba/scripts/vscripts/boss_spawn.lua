-- Время респавна босса после его убийства (в секундах)
BOSS_RESPAWN_TIME = 99999

if BossManager == nil then
	BossManager = class({})
end

function BossManager:Init()
	-- Таблица точек для спавна боссов
	self.bossPoints = {}
	self.bossKilled = {}
	if GetMapName() == "test" then
		for i = 1, 6 do
			self.bossKilled[i] = true
		end
	end

	local maxUnlockedLevels = 1
	local options = CustomNetTables:GetTableValue("game_options", "creepLevel")
	if options then
		maxUnlockedLevels = options.current
	end
	for i = 1, 6 do
		local point = Entities:FindByName(nil, "boss_" .. i .. "_point")
		if point then
			table.insert(self.bossPoints, point)
			if i <= maxUnlockedLevels then
				self:SpawnBoss(i)
			end
		end
	end

	ListenToGameEvent("entity_killed", Dynamic_Wrap(BossManager, "OnEntityKilled"), self)
end

function BossManager:IsBossKilled(bossIndex)
	if bossIndex <= 0 then return true end
	return self.bossKilled[bossIndex]
end

function BossManager:SpawnBoss(bossIndex)
	local spawnPoint = self.bossPoints[bossIndex]:GetAbsOrigin()
	local bossName = "npc_dota_boss_" .. bossIndex

	-- Спавн юнита босса
	local bossUnit = CreateUnitByName(bossName, spawnPoint, true, nil, nil, DOTA_TEAM_BADGUYS)
	bossUnit.bossIndex = bossIndex  -- привязываем индекс босса к юниту, чтобы знать, какой именно босс был убит
end

function BossManager:OnEntityKilled(event)
	local killedUnit = EntIndexToHScript(event.entindex_killed)

	-- Проверяем, убит ли босс, у которого задан индекс
	if killedUnit.bossIndex then
		local bossIndex = killedUnit.bossIndex

		if self.bossKilled[bossIndex] == nil then
			local options = CustomNetTables:GetTableValue("game_options", "creepLevel")
			if options then
				options.current = options.current + 1
				BossManager:SpawnBoss(options.current)
				NeutralManager:UnlockNeutralCamp(options.current)
				CustomNetTables:SetTableValue("game_options", "creepLevel", options)
			end
		end

		self.bossKilled[bossIndex] = true
		print("Босс " .. bossIndex .. " убит, респавн через " .. BOSS_RESPAWN_TIME .. " секунд.")
		
		if BOSS_RESPAWN_TIME > 0 then
			Timers:CreateTimer(BOSS_RESPAWN_TIME, function()
				self:SpawnBoss(bossIndex)
			end)
		end
	end
end

-- Инициализация менеджера боссов при запуске игры
if not BossManagerInit then
	BossManagerInit = true
	BossManager:Init()
end
