-- addon_game_mode.lua

-- Подключаем необходимые библиотеки
require('libraries/timers')
require('internal/util')
require('utils')
require('neutral_manager')
require('boss_spawn')
require('tables/wave_rewards')
require('tables/boss_gold')

-- Объявляем класс GameMode
if GameMode == nil then
	_G.GameMode = class({})
end

RESPAWN_TIME = 15

TRANSFER_FINAL_BOSS = 11
BOSS_FIGHT_INTERVAL = 5
WAVE_INTERVAL = 60


GameMode.currentWave = 0
GameMode.maxWaves = 60

GameMode.playerChoices = {}

_G.HeroExpTable = {0}
local expTable = {
	240,
	400,
	520,
	600,
	680,
	760,
	800,
	900,
	1000,
	1100,
	1200,
	1300,
	1400,
	1500,
	1600,
	1700,
	1800,
	1900,
	2000,
	2200,
	2400,
	2600,
	2800,
	3000,
	4000,
	5000,
	6000,
	7000,
	7500,
	-- После 30 лвла
	8000,
	8500,
	9000,
	9500,
	10000,
	10500,
	11000,
	11500,
	12000,
	12500,
	13000,
	13500,
	14000,
	14500,
	15000,
	15500,
	16000,
	16500,
	17000,
	17500
}

for i=2,#expTable + 1 do
	_G.HeroExpTable[i] = _G.HeroExpTable[i-1] + expTable[i-1]
end

function Precache(context)
	PrecacheResource("particle", "particles/generic/magic_crit.vpcf", context)
	PrecacheResource("particle", "particles/dark_moon/darkmoon_creep_warning.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_centaur/centaur_warstomp.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_snapfire/hero_snapfire_ultimate_calldown.vpcf", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_centaur.vsndevts", context)
	PrecacheUnitByNameSync("npc_dota_badguys_tower_cus", context)
	PrecacheUnitByNameSync("npc_dota_goodguys_tower_cus", context)

	for i = 1, GameMode.maxWaves do
		local unitName = "npc_dota_wave_" .. i
		PrecacheUnitByNameSync(unitName, context)
	end

	for i = 1, GameMode.maxWaves do
		local abilityName = "golem_ability_wave_" .. i
		PrecacheItemByNameSync(abilityName, context)
	end

	_G.GLOBAL_PRECACHE = _G.GLOBAL_PRECACHE or {}
	local units = LoadKeyValues("scripts/npc/npc_units_custom.txt")
	for k, v in pairs(units) do
		local unitKV = GetUnitKeyValuesByName(k)
		if unitKV then
			local model = unitKV.Model or "models/development/invisiblebox.vmdl"
			if GLOBAL_PRECACHE[model] == nil then
				PrecacheResource("model", model, context)
				_G.GLOBAL_PRECACHE[model] = true
			end
		end
	end
end

function Activate()
	GameMode:InitGameMode()
end

function GameMode:InitGameMode()
	print("GameMode инициализирован")

	GameRules:EnableCustomGameSetupAutoLaunch(true)
	GameRules:SetCustomGameSetupAutoLaunchDelay(0.5)
	GameRules:SetHeroSelectionTime(15)

	GameRules:GetGameModeEntity():SetUseCustomHeroLevels( true )
	GameRules:GetGameModeEntity():SetCustomXPRequiredToReachNextLevel(_G.HeroExpTable)

	GameRules:SetStrategyTime(10)
	GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_GOODGUYS, 6)
	GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_BADGUYS, 0)

	GameRules:SetShowcaseTime(0)
	GameRules:GetGameModeEntity():SetFreeCourierModeEnabled(true)
	GameRules:GetGameModeEntity():SetUseTurboCouriers(true)
	
	GameRules:SetPreGameTime(10)
	GameRules:SetUseUniversalShopMode(true)
--	GameRules:GetGameModeEntity():SetUnseenFogOfWarEnabled(true)
	if IsInToolsMode() then
--		GameRules:GetGameModeEntity():SetFogOfWarDisabled(true)
		if GetMapName() == "test" then
			SendToServerConsole("dota_easybuy 1")
		end
	end
	
	GameRules:SetTimeOfDay(0.75)

	ListenToGameEvent("player_chat", Dynamic_Wrap(GameMode, "OnPlayerChat"), self)
	ListenToGameEvent("game_rules_state_change", Dynamic_Wrap(GameMode, "OnGameRulesStateChange"), self)
	ListenToGameEvent("dota_player_used_ability", Dynamic_Wrap(GameMode, "OnPlayerUsedAbility"), self)
	ListenToGameEvent("dota_ability_channel_finished", Dynamic_Wrap(GameMode, "OnPlayerChannelAbility"), self)
	ListenToGameEvent("npc_spawned", Dynamic_Wrap(GameMode, "OnNPCSpawned"), self)
	ListenToGameEvent("entity_killed", Dynamic_Wrap(GameMode, "OnEntityKilled"), self)
	CustomGameEventManager:RegisterListener("OnPlayerChoseBoss", Dynamic_Wrap(GameMode, "OnPlayerChoseBoss"))
	local mode = GameRules:GetGameModeEntity()
	mode:SetCustomBackpackSwapCooldown(0)
	mode:SetExecuteOrderFilter(Dynamic_Wrap(GameMode, 'OrderFilter'), self)
end

function GameMode:OnGameRulesStateChange()
	local state = GameRules:State_Get()
	print("Game state changed to ", state)

	if state == DOTA_GAMERULES_STATE_STRATEGY_TIME then
		for i = 1, PlayerResource:GetPlayerCount() do
			if not PlayerResource:HasSelectedHero(i-1) then
				local player = PlayerResource:GetPlayer(i-1)
				if player then
					player:MakeRandomHeroSelection()
					PlayerResource:SetHasRandomed(i-1)
				end
			end
		end
	end

	if state == DOTA_GAMERULES_STATE_PRE_GAME then
		GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_BADGUYS, 1)

		print("Игра в состоянии предыгровой подготовки")

		CustomNetTables:SetTableValue("game_options", "creepLevel", {current = 1})
		NeutralManager:Init()
		BossManager:Init()
		
		GameMode.TowersTable = {
			{key = "tower1", _1 = {unit = -1}, _2 = {unit = -1}},
			{key = "tower2", _1 = {unit = -1}, _2 = {unit = -1}},
			{key = "tower3", _1 = {unit = -1}, _2 = {unit = -1}},
			{key = "tower4", _1 = {unit = -1}, _2 = {unit = -1}},
			{key = "tower5", _1 = {unit = -1}, _2 = {unit = -1}},
			{key = "tower6", _1 = {unit = -1}, _2 = {unit = -1}},
			{key = "tower7", _1 = {unit = -1}, _2 = {unit = -1}},
			{key = "tower8", _1 = {unit = -1}, _2 = {unit = -1}},
			{key = "baracks", _1 = {unit = -1}, _2 = {unit = -1}},
		}
		for _, towers in ipairs(GameMode.TowersTable) do
			local tower_1 = Entities:FindByName(nil, towers.key.."_1")
			local tower_2 = Entities:FindByName(nil, towers.key.."_2")
			if tower_1 and tower_2 then
				local team = string.match(towers.key, "tower[1-4]") and DOTA_TEAM_GOODGUYS or DOTA_TEAM_BADGUYS
				local nameT = string.match(towers.key, "tower[1-4]") and "npc_dota_goodguys_tower_cus" or "npc_dota_badguys_tower_cus"
				local t1 = towers._1
				local t2 = towers._2
				if t1.unit == -1 then
					local unit = CreateUnitByName(nameT, tower_1:GetAbsOrigin(), true, nil, nil, team)
					unit.entName = {towers.key, "_1"}
					t1.unit = unit:entindex()
					t1.team = team
					unit:SetAbsOrigin(tower_1:GetAbsOrigin())
					unit:AddNewModifier(unit, nil, "modifier_towers_changer", {})
				end
				if t2.unit == -1 then
					local unit = CreateUnitByName(nameT, tower_2:GetAbsOrigin(), true, nil, nil, team)
					unit.entName = {towers.key, "_2"}
					t2.unit = unit:entindex()
					t2.team = team
					unit:SetAbsOrigin(tower_2:GetAbsOrigin())
					unit:AddNewModifier(unit, nil, "modifier_towers_changer", {})
				end
			end
		end
		GameMode:RefreshTowersInvul()
	elseif state == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		print("Игра началась")

		--[[
		for _, towers in pairs(GameMode.TowersTable) do
			local t1 = towers._1
			local t2 = towers._2
			if t1.unit ~= -1 then
				local unit = EntIndexToHScript(t1.unit)
				unit:RemoveModifierByName("modifier_invulnerable")
			end
			if t2.unit ~= -1 then
				local unit = EntIndexToHScript(t2.unit)
				unit:RemoveModifierByName("modifier_invulnerable")
			end
		end
		]]
		GameMode:RefreshTowersInvul()

		GameMode:ProcessPlayerChoices()

	--	GameMode:StartWaveSpawnTimer()
		GameRules:GetGameModeEntity():SetThink("WaveSpawnThink", GameMode, "WaveThink", 0.1)
	end
end

function GameMode:OnPlayerChoseBoss(args)
	local playerID = args.PlayerID
	local choice = args.choice

	if playerID ~= nil and choice ~= nil then
		print("Игрок", playerID, "сделал выбор:", choice)

		GameMode.playerChoices[playerID] = choice
	end
end

function GameMode:OnPlayerUsedAbility(event)
	local abiltyName = event.abilityname
	local playerID = event.PlayerID

	if abiltyName == "item_tpscroll" then
		local hero = PlayerResource:GetSelectedHeroEntity(playerID)
		local hasItem = false
		for i = 0, 5 do
			local item = hero:GetItemInSlot(i)
			if item and item:GetName() == "item_travel_boots" then
				hasItem = true
				break
			end
		end
		if not hasItem then
			hero:AddItemByName("item_tpscroll")
		end
	end
end
function GameMode:OnPlayerChannelAbility(event)
	local abiltyName = event.abilityname
	local caster = EntIndexToHScript(event.caster_entindex)
	local interrupted = event.interrupted

	if interrupted == 0 then
		if abiltyName == "item_tpscroll" then
			local pos = caster:GetAbsOrigin()
			local buildings = FindUnitsInRadius(caster:GetTeamNumber(), pos, nil, 9999999, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BUILDING, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_CLOSEST, false)
			if #buildings > 0 then
				local building_pos = buildings[1]:GetAbsOrigin()
				local diraction = (building_pos - pos):Normalized()
				local distance = 0
				local step = 20
				while distance < 9999999 do
					local checkPos = pos + diraction * distance
					if GridNav:CanFindPath(building_pos, checkPos) then
						GridNav:DestroyTreesAroundPoint(checkPos, 150, true)
						FindClearSpaceForUnit(caster, checkPos, true)
						break
					end
					distance = distance + step
				end
			end
		--	GridNav:DestroyTreesAroundPoint(caster:GetAbsOrigin(), 150, true)
		--	caster:AddNewModifier(caster, nil, "modifier_rune_haste", {duration = 5})
		end
	end
end

function GameMode:ProcessPlayerChoices()
	print("Обрабатываем выборы игроков")

	local bossCandidates = {}
	for playerID, choice in pairs(GameMode.playerChoices) do
		if choice == 0 then
			table.insert(bossCandidates, playerID)
		end
	end

	local bossPlayerID = nil
	if #bossCandidates > 0 then
		bossPlayerID = bossCandidates[RandomInt(1, #bossCandidates)]
	else
		--[[
		local allPlayers = {}
		for playerID = 0, PlayerResource:GetPlayerCount() - 1 do
			if PlayerResource:IsValidPlayerID(playerID) and PlayerResource:HasSelectedHero(playerID) and PlayerResource:GetConnectionState(playerID) == DOTA_CONNECTION_STATE_CONNECTED then
				table.insert(allPlayers, playerID)
			end
		end
		bossPlayerID = allPlayers[RandomInt(1, #allPlayers)]
		]]
		return
	end

	GameMode.bossPlayerID = bossPlayerID

	local heroName = PlayerResource:GetSelectedHeroName(bossPlayerID)

	if heroName == nil or heroName == "" then
		heroName = "Неизвестный герой"
	else
		heroName = string.gsub(heroName, "npc_dota_hero_", "")
		heroName = string.gsub(heroName, "_", " ")
		heroName = string.upper(string.sub(heroName, 1, 1)) .. string.sub(heroName, 2)
	end
end


function GameMode:OnNPCSpawned(keys)
	local npc = EntIndexToHScript(keys.entindex)
	if not npc then return end
--	if keys.is_respawn == 0 then
--		if npc:IsHero() then
			npc:AddNewModifier(npc, nil, "modifier_generic_handler", {})
--		end
--	end

	Timers:CreateTimer(0.1, function()
		if npc and not npc:IsNull() then
			local tpscroll = npc:FindItemInInventory("item_tpscroll")
			if tpscroll then
				tpscroll:EndCooldown()
			end
		end
	end)
end

function GameMode:OnEntityKilled(event)
	local killedUnit = EntIndexToHScript(event.entindex_killed)
	
	if killedUnit:IsRealHero() then
		killedUnit:SetTimeUntilRespawn(RESPAWN_TIME)

		if GameMode:IsStartBossFight() and GameMode:GetBoss() == killedUnit then
		--	local soul = GameMode:GetSoulBoss()
			GameMode:SetStartBossFight(false)
		--	soul:Destroy()
		end
	end

	if killedUnit:HasModifier("modifier_golem_ai") then
		local isCurrentWaveUnit = false
		for i,unit in ipairs(self.waveUnits) do
			if unit:GetEntityIndex() == killedUnit:GetEntityIndex() then
				isCurrentWaveUnit = true
				table.remove(self.waveUnits, i)
				break
			end
		end

		if isCurrentWaveUnit and #self.waveUnits == 0 then
			self:GiveRewardWave()
		end
	end

	if killedUnit:IsBossCreature() then
		local reward = BOSS_GOLD[killedUnit:GetUnitName()]
	--	DeepPrintTable(reward)
		if reward then
			GiveAllGoldAndXp(reward, DOTA_TEAM_GOODGUYS)
		end
	end

	if killedUnit:GetUnitName() == "npc_dota_boss_6" then
		self:OpenGate()
	end
end

function GameMode:IsGateOpen()
	return self.isGateOpen or false
end
function GameMode:OpenGate()
	local gate = Entities:FindByName(nil, "gate")
	local blocks = Entities:FindAllByName("gate_obstruction")
	UTIL_Remove(gate)
	for _,block in ipairs(blocks) do
		block:Destroy()
	end
	self.isGateOpen = true
end

function GameMode:TransformPlayerToBoss()
	if GameMode:GetBoss() then return end
	local playerID = GameMode.bossPlayerID
	if not playerID then return end
	local player = PlayerResource:GetPlayer(playerID)

	if not player then return end

	local hero = player:GetAssignedHero()
	Timers:CreateTimer(0.1, function()
		if not hero or hero:IsNull() then return end
		if not hero:IsAlive() then
			hero:RespawnUnit()
		end
		self:SetBoss(hero)
		if hero then
			player:SetTeam(DOTA_TEAM_BADGUYS)
			PlayerResource:SetCustomTeamAssignment(playerID, DOTA_TEAM_BADGUYS)

			hero:SetTeam(DOTA_TEAM_BADGUYS)
			hero:SetOwner(player)
			hero:SetControllableByPlayer(playerID, true)
			hero:AddNewModifier(hero, nil, "modifier_boss_healthbar", {})
			hero:AddNewModifier(hero, nil, "modifier_boss_buff", {})
	
			local courierPlayer = PlayerResource:GetPreferredCourierForPlayer(playerID)
			courierPlayer:SetTeam(DOTA_TEAM_BADGUYS)
			UTIL_Remove(courierPlayer)
			
			local pointName = "info_courier_spawn_dire"
			local point = Entities:FindByClassname(nil, pointName):GetAbsOrigin()
			courierPlayer = player:SpawnCourierAtPosition(point)
			
			FindClearSpaceForUnit(courierPlayer, point, true)
			courierPlayer:RespawnUnit()

			GameMode:UpdateTeamPlayerCounts()
		end

		self:StartBossFight()
	end)
end

function GameMode:SetBoss(hero)
	if hero:IsRealHero() then
		self.boss = hero
	end
end


function GameMode:GetBoss()
	return self.boss
end

function GameMode:GetSoulBoss()
	return self.soul
end

function GameMode:IsStartBossFight()
	return self.bossFight
end

function GameMode:SetStartBossFight(state)
	self.bossFight = state
end

function GameMode:StartBossFight()
	local boss = self:GetBoss()
	if boss then
		local point = self:GetWaveSpawnPoint()
		--[[
		if self.soul then UTIL_Remove(self.soul) end
		self.soul = CreateUnitByName("npc_boss_soul", point, true, nil, nil, DOTA_TEAM_BADGUYS)

		Timers:CreateTimer(0.2, function()
			self.soul:MoveToPosition(Vector(-10862, 10454, 0))
		end)
		]]
		if not boss:IsAlive() then
			boss:RespawnUnit()
		end
		FindClearSpaceForUnit(boss, point, true)
		GameMode:SetStartBossFight(true)
	end
end

function GameMode:UpdateTeamPlayerCounts()
	local goodGuysCount = 0
	local badGuysCount = 0

	for playerID = 0, PlayerResource:GetPlayerCount() - 1 do
		if PlayerResource:IsValidPlayerID(playerID) then
			local team = PlayerResource:GetTeam(playerID)
			if team == DOTA_TEAM_GOODGUYS then
				goodGuysCount = goodGuysCount + 1
			elseif team == DOTA_TEAM_BADGUYS then
				badGuysCount = badGuysCount + 1
			end
		end
	end

	GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_GOODGUYS, goodGuysCount)
	GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_BADGUYS, badGuysCount)
end
--[[
function GameMode:GetWaveSpawnPoint(isForWave)
	local tables = {
		"tower1",
		"tower2",
		"tower3",
		"tower4",
		"tower5",
		"baracks",
	}

	local spawnPoint

	for i, name in ipairs(tables) do
		local towers = Entities:FindAllByName(name)

		if #towers ~= 0 then
			for _,tower in ipairs(towers) do
				if tower:IsAlive() then
					spawnPoint = Entities:FindByName(nil, name.. "_point"):GetAbsOrigin()
					break
				end
			end
		end

		if spawnPoint then break end
	end

	if not isForWave and spawnPoint == nil then
	spawnPoint = Entities:FindByName(nil, "global_point")
	end

	return spawnPoint
end
]]

function GameMode:GetWaveSpawnPoint(isForWave)
	local spawnPoint
	
	for _, towers in ipairs(GameMode.TowersTable) do
		local tower_1Unit = EntIndexToHScript(towers._1.unit)
		local tower_2Unit = EntIndexToHScript(towers._2.unit)
		
		if tower_1Unit and tower_2Unit and tower_1Unit:IsAlive() and tower_2Unit:IsAlive() and towers._1.team == DOTA_TEAM_BADGUYS and towers._2.team == DOTA_TEAM_BADGUYS then
			spawnPoint = Entities:FindByName(nil, towers.key.."_point"):GetAbsOrigin()
			break
		end
	end

	if spawnPoint == nil then
		local name = "global_point"
		if GameMode:IsGateOpen() and isForWave then
			name = "last_point"
		end
		local ent = Entities:FindByName(nil, name)
		if ent then
			spawnPoint = ent:GetAbsOrigin()
		end
	end

	return spawnPoint
end
function GameMode:RefreshTowersInvul()
	local towersTable = GameMode.TowersTable
	local RTowers = {}
	local DTowers = {}

	for i, towers in ipairs(towersTable) do
		local tower_1Unit = EntIndexToHScript(towers._1.unit)
		local tower_2Unit = EntIndexToHScript(towers._2.unit)

		if tower_1Unit and tower_2Unit and tower_1Unit:IsAlive() and tower_2Unit:IsAlive() then
			if tower_1Unit:GetTeamNumber() == tower_2Unit:GetTeamNumber() then
				table.insert(tower_1Unit:GetTeamNumber() == DOTA_TEAM_GOODGUYS and RTowers or DTowers, {tower_1Unit, tower_2Unit})
			else
				table.insert(tower_1Unit:GetTeamNumber() == DOTA_TEAM_GOODGUYS and RTowers or DTowers, {tower_1Unit, tower_2Unit})
				table.insert(tower_2Unit:GetTeamNumber() == DOTA_TEAM_GOODGUYS and RTowers or DTowers, {tower_1Unit, tower_2Unit})
			end
		end
	end
	--[[
	for i = #RTowers, 1, -1 do
		local tower1 = RTowers[i][1]
		local tower2 = RTowers[i][2]
		local newTower = RTowers[i+1]
		if newTower and ((tower1:GetTeamNumber() == DOTA_TEAM_GOODGUYS) or (tower2:GetTeamNumber() == DOTA_TEAM_GOODGUYS)) then
			tower1:AddNewModifier(tower1, nil, "modifier_invulnerable", {}):SetStackCount((#RTowers - i) + 1)
			tower2:AddNewModifier(tower2, nil, "modifier_invulnerable", {}):SetStackCount((#RTowers - i) + 1)
		else
			tower1:RemoveModifierByName("modifier_invulnerable")
			tower2:RemoveModifierByName("modifier_invulnerable")
		end
		tower1:AddNewModifier(tower1, nil, "modifier_towers_tier", {}):SetStackCount((#RTowers - i) + 1)
		tower2:AddNewModifier(tower2, nil, "modifier_towers_tier", {}):SetStackCount((#RTowers - i) + 1)
	end
	for i = 1, #DTowers do
		local tower1 = DTowers[i][1]
		local tower2 = DTowers[i][2]
		local newTower = DTowers[i-1]
		if newTower and ((tower1:GetTeamNumber() == DOTA_TEAM_BADGUYS) or (tower2:GetTeamNumber() == DOTA_TEAM_BADGUYS)) then
			tower1:AddNewModifier(tower1, nil, "modifier_invulnerable", {}):SetStackCount(i)
			tower2:AddNewModifier(tower2, nil, "modifier_invulnerable", {}):SetStackCount(i)
		else
			tower1:RemoveModifierByName("modifier_invulnerable")
			tower2:RemoveModifierByName("modifier_invulnerable")
		end
		tower1:AddNewModifier(tower1, nil, "modifier_towers_tier", {}):SetStackCount(i)
		tower2:AddNewModifier(tower2, nil, "modifier_towers_tier", {}):SetStackCount(i)
	end
	]]
	for _, teamTowers in ipairs({RTowers, DTowers}) do
		for i = #teamTowers, 1, -1 do
			local tower1, tower2 = unpack(teamTowers[i])
			local stacks
			local newTower
			if teamTowers == RTowers then
				stacks = #teamTowers - i + 1
				newTower = teamTowers[i + 1]
			else
				stacks = i
				newTower = teamTowers[i - 1]
			end
			
			if newTower and (tower1:GetTeamNumber() == tower2:GetTeamNumber()) then
				tower1:AddNewModifier(tower1, nil, "modifier_invulnerable", {}):SetStackCount(stacks)
				tower2:AddNewModifier(tower2, nil, "modifier_invulnerable", {}):SetStackCount(stacks)
			else
				tower1:RemoveModifierByName("modifier_invulnerable")
				tower2:RemoveModifierByName("modifier_invulnerable")
			end
			tower1:AddNewModifier(tower1, nil, "modifier_towers_tier", {}):SetStackCount(stacks)
			tower2:AddNewModifier(tower2, nil, "modifier_towers_tier", {}):SetStackCount(stacks)

			if not tower1:HasModifier("modifier_invulnerable_cus") then
				tower1:AddNewModifier(tower1, nil, "modifier_invulnerable_cus", {})
			end
			if not tower2:HasModifier("modifier_invulnerable_cus") then
				tower2:AddNewModifier(tower2, nil, "modifier_invulnerable_cus", {})
			end
		end
	end

	local RThrone = Entities:FindByName(nil, "dota_goodguys_fort")
	if RThrone then
		if #RTowers ~= 0 then
			RThrone:AddNewModifier(RThrone, nil, "modifier_invulnerable", {}):SetStackCount(#RTowers)
		else
			RThrone:RemoveModifierByName("modifier_invulnerable")
		end

		if not RThrone:HasModifier("modifier_invulnerable_cus") then
			RThrone:AddNewModifier(RThrone, nil, "modifier_invulnerable_cus", {})
		end
	end

	local DThrone = Entities:FindByName(nil, "dota_badguys_fort")
	if DThrone then
		if #DTowers ~= 0 then
			DThrone:AddNewModifier(DThrone, nil, "modifier_invulnerable", {}):SetStackCount(#DTowers)
		else
			DThrone:RemoveModifierByName("modifier_invulnerable")
		end

		if not DThrone:HasModifier("modifier_invulnerable_cus") then
			DThrone:AddNewModifier(DThrone, nil, "modifier_invulnerable_cus", {})
		end
	end
end

function GameMode:SpawnWave()
	if GameMode.currentWave > GameMode.maxWaves then return end

	GameMode.currentWave = GameMode.currentWave + 1

	
	local unitName = "npc_dota_wave_" .. GameMode.currentWave

	local spawnPoint = self:GetWaveSpawnPoint(true)

	self.waveUnits = {}

	if spawnPoint then
		for i = 1, 10 do
			local offset = Vector(RandomFloat(-200, 200), RandomFloat(-200, 200), 0)
			local spawnLocation = spawnPoint + offset

			local unit = CreateUnitByName(unitName, spawnLocation, true, nil, nil, DOTA_TEAM_BADGUYS)
			table.insert(self.waveUnits, unit)
			if unit then
				unit:AddNewModifier(unit, nil, "modifier_golem_ai", {})
			else
		--		print("Не удалось заспавнить юнита:", unitName)
			end
		end

		if GameMode.currentWave % 5 == 0 then
			local offset = Vector(RandomFloat(-200, 200), RandomFloat(-200, 200), 0)
			local spawnLocation = spawnPoint + offset

			local unit = CreateUnitByName("npc_dota_wave_mini_boss_" .. GameMode.currentWave, spawnLocation, true, nil, nil, DOTA_TEAM_BADGUYS)
			if unit then
				unit:AddNewModifier(unit, nil, "modifier_golem_ai", {})
			end
		end
	end

	if GameMode.currentWave == TRANSFER_FINAL_BOSS then
	--	GameMode:TransformPlayerToBoss()
	end

	if self.currentWave > TRANSFER_FINAL_BOSS and (self.currentWave - TRANSFER_FINAL_BOSS)%BOSS_FIGHT_INTERVAL == 0 then
		self:StartBossFight()
	end
end

function GameMode:SpawnMorph()
	local spawnPoint = self:GetWaveSpawnPoint(true)
	if spawnPoint then
		local blockedHeroes = {
		}
		local blockedAbilities = {
			kez_switch_weapons = true,
		}
		PrecacheUnitByNameAsync("npc_dota_morph_boss_cus", function()
			local morph = CreateUnitByName("npc_dota_morph_boss_cus", spawnPoint, true, nil, nil, DOTA_TEAM_BADGUYS)
			if morph then
				morph:SetCanSellItems(false)
				for abilitySlot = 0, morph:GetAbilityCount() - 1 do
					local morphAbility = morph:GetAbilityByIndex(abilitySlot)
					blockedAbilities[morphAbility:GetAbilityName()] = true
					if morphAbility then
						morphAbility:RemoveSelf()
					end
				end
				local maxHealth = 0
				local maxMana = 0
				local abilitiesCount = 0
				local players = {}
				local playersAbilities = {}
				local playersItems = {}
				for playerID = 0, PlayerResource:GetPlayerCount() - 1 do
					if PlayerResource:IsValidPlayerID(playerID) then--and PlayerResource:GetConnectionState(playerID) == DOTA_CONNECTION_STATE_CONNECTED then
						local hero = PlayerResource:GetSelectedHeroEntity(playerID)
						if hero then
							if hero:GetMaxHealth() > maxHealth then
								maxHealth = hero:GetMaxHealth()
							end
							if hero:GetMaxMana() > maxMana then
								maxMana = hero:GetMaxMana()
							end
							table.insert(players, hero)

							local playerAbilCount = 0
							for abilitySlot = 0, hero:GetAbilityCount() - 1 do
								local heroAbility = hero:GetAbilityByIndex(abilitySlot)
								if heroAbility and heroAbility:GetLevel() > 0 then
									local abilityName = heroAbility:GetAbilityName()
									local abilityLvl = heroAbility:GetLevel()
									playerAbilCount = playerAbilCount + 1
									if not heroAbility:IsAttributeBonus() and not heroAbility:IsHidden() and not blockedAbilities[abilityName] then
										table.insert(playersAbilities, {abilityName, abilityLvl})
									end
								end
							end
							if playerAbilCount > abilitiesCount then
								abilitiesCount = playerAbilCount
							end
							for itemSlot = 0, 5 do
								local heroItem = hero:GetItemInSlot(itemSlot)
								if heroItem then
									local itemName = heroItem:GetName()
									table.insert(playersItems, itemName)
								end
							end
						end
					end
				end
				if #players > 0 then
					local hero = players[RandomInt(1, #players)]
					if hero then
						--[[
						local morphAbils = 0
						while #playersAbilities > 0 and morphAbils < abilitiesCount do
							local randomAbil = RandomInt(1, #playersAbilities)
							local abilityName = playersAbilities[randomAbil][1]
							local abilityLvl = playersAbilities[randomAbil][2]
							local morphAbility = morph:AddAbility(abilityName)
							if morphAbility then
								morphAbility:SetActivated(true)
								morphAbility:SetLevel(abilityLvl)
								morphAbils = morphAbils + 1
								table.remove(playersAbilities, randomAbil)
							end
						end
						]]
						local morphInv = 0
						while #playersItems > 0 and morphInv < 6 do
							local randomItem = RandomInt(1, #playersItems)
							local itemName = playersItems[randomItem]
							if not morph:HasItemInInventory(itemName) then
								local morphItem = morph:AddItemByName(itemName)
								if morphItem then
									morphItem:SetPurchaseTime(0)
									morphInv = morphInv + 1
								end
							end
							table.remove(playersItems, randomItem)
						end
						for abilitySlot = 0, hero:GetAbilityCount() - 1 do
							local heroAbility = hero:GetAbilityByIndex(abilitySlot)
							if heroAbility and heroAbility:GetLevel() > 0 then
								local abilityName = heroAbility:GetAbilityName()
								if not blockedAbilities[abilityName] then
									local morphAbility = morph:AddAbility(abilityName)
									if morphAbility then
										morphAbility:SetActivated(true)
										morphAbility:SetLevel(math.max(heroAbility:GetLevel(), 1))
									end
								end
							end
						end
						--[[
						for itemSlot = 0, 5 do
							local heroItem = hero:GetItemInSlot(itemSlot)
							if heroItem then
								local itemName = heroItem:GetName()
								local morphItem = morph:AddItemByName(itemName)
								if morphItem then
									morphItem:SetPurchaseTime(0)
								end
							end
						end
						]]
						
						local morphAbils = 0
						while #playersAbilities > 0 and morphAbils < 4 do
							local randomAbil = RandomInt(1, #playersAbilities)
							local abilityName = playersAbilities[randomAbil][1]
							if not morph:HasAbility(abilityName) then
								local abilityLvl = playersAbilities[randomAbil][2]
								local morphAbility = morph:AddAbility(abilityName)
								if morphAbility then
									morphAbility:SetActivated(true)
									morphAbility:SetLevel(math.max(abilityLvl, 1))
									morphAbils = morphAbils + 1
								end
							end
							table.remove(playersAbilities, randomAbil)
						end
					--	morph:SetControllableByPlayer(hero:GetPlayerID(), true)
					end
					morph:SetBaseMaxHealth(maxHealth)
					morph:SetMaxHealth(maxHealth)
					morph:SetHealth(maxHealth)
					morph:SetMaxMana(maxMana)
					morph:SetMana(maxMana)
					morph:SetBaseDamageMin(50 + (GameMode.currentWave * 3))
					morph:SetBaseDamageMax(50 + (GameMode.currentWave * 6))
				end
				morph:AddNewModifier(morph, nil, "modifier_morph_boss_ai", {}):SetStackCount(GameMode.currentWave)
				morph:AddNewModifier(morph, nil, "modifier_boss_healthbar", {})
				morph:AddNewModifier(morph, nil, "modifier_boss_buff", {})
			end
		end)
	end
end

function GameMode:GiveRewardWave()
	local reward = WAVE_REWARDS[self.currentWave]
	GiveAllGoldAndXp(reward, DOTA_TEAM_GOODGUYS)
end

function GameMode:StartWaveSpawnTimer()
	print("Запуск таймера спавна волн")
	Timers:CreateTimer(0, function()
		GameMode:SpawnWave()
		
		if GameMode.currentWave > GameMode.maxWaves then
			print("Все волны были заспавнены.")
			return nil
		else
			return WAVE_INTERVAL
		end
	end)
end
function GameMode:WaveSpawnThink()
	local interval = 0.1
	if GameMode.currentWave < GameMode.maxWaves then
		local options = CustomNetTables:GetTableValue("game_options", "waveOptions") or {waveInterval = WAVE_INTERVAL, waveTimer = 0, currentWave = GameMode.currentWave, maxWaves = GameMode.maxWaves}
		if options then
			if options.waveTimer <= 0 then
				GameMode:SpawnWave()
				options.waveTimer = WAVE_INTERVAL
				options.currentWave = GameMode.currentWave

				--[[
				if GameMode.currentWave % 1 == 0 then
					GameMode:SpawnMorph()
				end
				]]
			end
			options.waveTimer = options.waveTimer - interval
			CustomNetTables:SetTableValue("game_options", "waveOptions", options)
		end
	end

	self.SpawnMorphInterval = self.SpawnMorphInterval or 120
	self.SpawnMorphInterval = self.SpawnMorphInterval - interval
	if self.SpawnMorphInterval <= 0 then
		self.SpawnMorphInterval = RandomInt(60, 180)
		self:SpawnMorph()
	end
	return interval
end

function GameMode:OrderFilter(event)
	local type = event.order_type
	local playerId = event.issuer_player_id_const
	local ability = EntIndexToHScript(event.entindex_ability)
	local position
	if event.position_x and event.position_y and event.position_z then
		position = Vector(event.position_x, event.position_y, event.position_z)
	end
	local unit
	if event.units and event.units["0"] then
		unit = EntIndexToHScript(event.units["0"])
	end

	if type == DOTA_UNIT_ORDER_PURCHASE_ITEM then
		local item = event.shop_item_name

		if string.sub(item, 1, 19) == "item_upgrade_scroll" then
			local upgradeLevel = tonumber(string.sub(item, 21))
			local hero = PlayerResource:GetSelectedHeroEntity(playerId)
			local team = hero:GetTeamNumber()
			
			if upgradeLevel ~= 1 then
				local index = team == DOTA_TEAM_GOODGUYS and 1 or 2
				if not BossManager:IsBossKilled(upgradeLevel - index) then
					CreateHudError(PlayerResource:GetPlayer(playerId), "#error_boss_not_killed", {level = upgradeLevel - index})
					return false
				end
			end
		end
	end
	if type == DOTA_UNIT_ORDER_CAST_POSITION then
		if ability and ability:GetAbilityName() == "item_tpscroll" then
			local hero = PlayerResource:GetSelectedHeroEntity(playerId)
			if hero == GameMode:GetBoss() then
				
			end
		end
	end

	return true
end

function GameMode:OnPlayerChat(keys)
	local playerID = keys.playerid
	local cheats_on = GameRules:IsCheatMode()
	local tools_on = IsInToolsMode()
	local normal_text = keys.text
	local text = string.pipei(string.trim(string.lower(keys.text)))
	
	if normal_text == "-resc" and cheats_on then
		SendToServerConsole("script_reload")
		SendToServerConsole("cl_script_reload")
	end
	if normal_text == "-imtheboss" and cheats_on then
		GameMode.bossPlayerID = playerID
		GameMode:TransformPlayerToBoss()
	end

	if AllowedToDo(playerID) then
		if text[1] == "-kb" then
			local value = tonumber(text[2])
			local value2 = tonumber(text[3])
			if value and value2 then
				CustomGameEventManager:Send_ServerToAllClients("ShowBossKilledNotif", {text = value, delay = value2})
			end
		end

		if text[1] == "-hero" then
			local name = tostring(text[2])
			if name then
				PlayerResource:GetPlayer(playerID):SetSelectedHero("npc_dota_hero_"..name)
			end
		end
	end
end
