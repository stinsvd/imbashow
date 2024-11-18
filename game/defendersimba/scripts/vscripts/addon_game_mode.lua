-- addon_game_mode.lua

-- Подключаем необходимые библиотеки
require('internal/util')
require('libraries/timers')
require('utils')
require('neutral_manager')
require('boss_spawn')
 
-- Подключаем модификатор
require('modifiers/modifier_golem_ai')

-- Регистрируем модификатор
LinkLuaModifier("modifier_golem_ai", "modifiers/modifier_golem_ai", LUA_MODIFIER_MOTION_NONE)

-- Объявляем класс GameMode
if GameMode == nil then
    _G.GameMode = class({})
end

TRANSFER_FINAL_BOSS = 1
WAVE_INTERVAL = 60


GameMode.currentWave = 1        -- Текущая волна
GameMode.maxWaves = 60           -- Максимальное количество волн

-- Таблица для хранения выбора игроков
GameMode.playerChoices = {}

-- Функция Precache загружает необходимые ресурсы перед началом игры
function Precache(context)
    -- Предварительно загружаем юниты для всех волн
    for i = 1, GameMode.maxWaves do
        local unitName = "npc_dota_wave_" .. i
        PrecacheUnitByNameSync(unitName, context)
    end

    -- Предварительно загружаем способности юнитов
    for i = 1, GameMode.maxWaves do
        local abilityName = "golem_ability_wave_" .. i
        PrecacheItemByNameSync(abilityName, context)
    end

    -- Предварительно загружаем модификатор AI
    -- Не нужно кэшировать Lua-модификаторы
end

-- Функция Activate вызывается при старте кастомки
function Activate()
    -- Инициализируем режим игры
    GameMode:InitGameMode()
end

-- Функция инициализации режима игры
function GameMode:InitGameMode()
    print("GameMode инициализирован")

    -- Устанавливаем время выбора героев в 0 секунд
    GameRules:SetHeroSelectionTime(15)

    -- Устанавливаем стратегическое время в 0 секунд
    GameRules:SetStrategyTime(10)

    -- Устанавливаем время демонстрации героев в 0 секунд
    GameRules:SetShowcaseTime(0)
    GameRules:GetGameModeEntity():SetFreeCourierModeEnabled(true)
    GameRules:GetGameModeEntity():SetUseTurboCouriers(true)
    -- Устанавливаем предыгровое время в 10 секунд
    GameRules:SetPreGameTime(10)
    GameRules:SetUseUniversalShopMode(true)
    GameRules:GetGameModeEntity():SetUnseenFogOfWarEnabled(true)
    if IsInToolsMode() then
        GameRules:GetGameModeEntity():SetFogOfWarDisabled(true)
    end
    -- Отключаем задержку автозапуска игры
    GameRules:SetCustomGameSetupAutoLaunchDelay(0)

    -- Устанавливаем начальное время суток на ночь (0.75 соответствует ночи)
    GameRules:SetTimeOfDay(0.75)

    -- Подписываемся на изменение состояния игры
    ListenToGameEvent("game_rules_state_change", Dynamic_Wrap(GameMode, "OnGameRulesStateChange"), self)
    ListenToGameEvent("dota_player_used_ability", Dynamic_Wrap(GameMode, "OnPlayerUsedAbility"), self)
    local mode = GameRules:GetGameModeEntity()
    mode:SetExecuteOrderFilter(Dynamic_Wrap(GameMode, 'OrderFilter'), self)
end

-- Функция, вызываемая при изменении состояния игры
function GameMode:OnGameRulesStateChange()
    local state = GameRules:State_Get()
    print("Game state changed to ", state)

    if state == DOTA_GAMERULES_STATE_PRE_GAME then
        print("Игра в состоянии предыгровой подготовки")

        NeutralManager:Init()
        BossManager:Init()

        
        -- Запускаем таймер для показа сообщения на отметке -00:05
        Timers:CreateTimer(function()
            local time = GameRules:GetDOTATime(true, true)
            print("Текущее игровое время: ", time)

            if time >= -5 and not GameMode.dialogShown then
                GameMode.dialogShown = true


                -- Начинаем проверять выбор игроков
                GameMode:StartChoiceCheckTimer()

                return nil  -- Останавливаем таймер
            else
                return 1.0  -- Проверяем каждую секунду
            end
        end)
    elseif state == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
        print("Игра началась")

        -- Обрабатываем результаты выбора игроков
        GameMode:ProcessPlayerChoices()

        -- Запускаем спавн волн
        GameMode:StartWaveSpawnTimer()
    end
end


-- Функция для обработки выбора игрока
function GameMode:OnPlayerChoseBoss(args)
    local playerID = args.PlayerID
    local choice = args.choice

    if playerID ~= nil and choice ~= nil then
        print("Игрок", playerID, "сделал выбор:", choice)

        -- Сохраняем выбор игрока
        GameMode.playerChoices[playerID] = choice
    end
end

function GameMode:OnPlayerUsedAbility(event)
	local abiltyName = event.abilityname 
    local playerID = event.PlayerID
    print("asads")
    if abiltyName == "item_tpscroll" then
        local hero = PlayerResource:GetSelectedHeroEntity(playerID)
        hero:AddItemByName("item_tpscroll")
    end
end
-- Функция для проверки, когда все игроки сделали выбор
function GameMode:StartChoiceCheckTimer()
    Timers:CreateTimer(1, function()
        local allPlayersMadeChoice = true
        for playerID = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
            if PlayerResource:IsValidPlayerID(playerID) and PlayerResource:GetConnectionState(playerID) == DOTA_CONNECTION_STATE_CONNECTED then
                if GameMode.playerChoices[playerID] == nil then
                    allPlayersMadeChoice = false
                    break
                end
            end
        end

        if allPlayersMadeChoice then
            print("Все игроки сделали выбор")
            return nil  -- Останавливаем таймер
        else
            -- Продолжаем проверять каждую секунду
            return 1.0
        end
    end)
end

-- Функция для обработки выборов игроков
function GameMode:ProcessPlayerChoices()
    print("Обрабатываем выборы игроков")

    -- Собираем игроков, выбравших "Да"
    local bossCandidates = {}
    for playerID, choice in pairs(GameMode.playerChoices) do
        if choice == 1 then
            table.insert(bossCandidates, playerID)
        end
    end

    -- Выбираем случайного игрока из кандидатов или из всех, если никто не выбрал "Да"
    local bossPlayerID = nil
    if #bossCandidates > 0 then
        bossPlayerID = bossCandidates[RandomInt(1, #bossCandidates)]
    else
        -- Если никто не выбрал "Да", выбираем случайного игрока
        local allPlayers = {}
        for playerID = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
            if PlayerResource:IsValidPlayerID(playerID) and PlayerResource:GetConnectionState(playerID) == DOTA_CONNECTION_STATE_CONNECTED then
                table.insert(allPlayers, playerID)
            end
        end
        bossPlayerID = allPlayers[RandomInt(1, #allPlayers)]
    end

    -- Сохраняем ID игрока, который станет боссом
    GameMode.bossPlayerID = bossPlayerID

    -- Получаем имя героя игрока
    local heroName = PlayerResource:GetSelectedHeroName(bossPlayerID)

    -- Проверяем, есть ли имя героя
    if heroName == nil or heroName == "" then
        heroName = "Неизвестный герой"
    else
        -- Преобразуем имя героя в читаемый формат
        -- Например, "npc_dota_hero_axe" -> "Axe"
        heroName = string.gsub(heroName, "npc_dota_hero_", "")
        heroName = string.gsub(heroName, "_", " ")
        heroName = string.upper(string.sub(heroName, 1, 1)) .. string.sub(heroName, 2)
    end

end

 
 

-- Функция для преобразования игрока в финального босса
function GameMode:TransformPlayerToBoss()
    local playerID = GameMode.bossPlayerID
    local player = PlayerResource:GetPlayer(playerID)

    if not player then return end

    -- Получаем текущего героя игрока
    local hero = player:GetAssignedHero()
    if hero then
        -- Переводим игрока в команду BADGUYS
        player:SetTeam(DOTA_TEAM_BADGUYS) -- поменял временно на DOTA_TEAM_GOODGUYS
        PlayerResource:SetCustomTeamAssignment(playerID, DOTA_TEAM_BADGUYS) -- поменял временно на DOTA_TEAM_GOODGUYS

        -- Меняем команду героя
        hero:SetTeam(DOTA_TEAM_BADGUYS) -- поменял временно на DOTA_TEAM_GOODGUYS
        hero:SetOwner(player)
        hero:SetControllableByPlayer(playerID, true)
        hero:AddNewModifier(hero, nil, "modifier_boss_buff", {})
  
        -- Обновляем количество игроков в командах
        GameMode:UpdateTeamPlayerCounts()
    end

    FindClearSpaceForUnit(hero, self:GetWaveSpawnPoint(), true)
end

-- Функция для обновления количества игроков в командах
function GameMode:UpdateTeamPlayerCounts()
    local goodGuysCount = 0
    local badGuysCount = 0

    for playerID = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
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

function GameMode:GetWaveSpawnPoint()
    local tables = {
        "tower1",
        "tower2",
        "tower3",
        "tower4",
        "tower5",
    }

    local spawnPoint

    for i,name in ipairs(tables) do
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

    if spawnPoint == nil then
      spawnPoint = Entities:FindByName(nil, "global_point")
    end

    return spawnPoint
end

function GameMode:SpawnWave()
    if GameMode.currentWave > GameMode.maxWaves then return end

    -- Имя юнита для текущей волны
    local unitName = "npc_dota_wave_" .. GameMode.currentWave
 
    local spawnPoint = self:GetWaveSpawnPoint()
 
    -- Спавним 10 юнитов
    for i = 1, 10 do
        -- Смещаем точку спавна, чтобы юниты не накладывались друг на друга
        local offset = Vector(RandomFloat(-200, 200), RandomFloat(-200, 200), 0)
        local spawnLocation = spawnPoint + offset

        -- Спавним юнита
        local unit = CreateUnitByName(unitName, spawnLocation, true, nil, nil, DOTA_TEAM_BADGUYS)

        if unit then
            -- Добавляем модификатор AI
            unit:AddNewModifier(unit, nil, "modifier_golem_ai", {})
        else
            print("Не удалось заспавнить юнита:", unitName)
        end
    end

    if GameMode.currentWave%5 == 0 then
        local offset = Vector(RandomFloat(-200, 200), RandomFloat(-200, 200), 0)
        local spawnLocation = spawnPoint + offset

        local unit = CreateUnitByName("npc_dota_wave_mini_boss_" .. GameMode.currentWave, spawnLocation, true, nil, nil, DOTA_TEAM_BADGUYS)

        if unit then
            unit:AddNewModifier(unit, nil, "modifier_golem_ai", {})
        end
    end

    if GameMode.currentWave == TRANSFER_FINAL_BOSS then 
        GameMode:TransformPlayerToBoss()
    end
    -- Увеличиваем номер волны для следующего спавна
    GameMode.currentWave = GameMode.currentWave + 1
end

-- Функция для запуска таймера спавна волн каждые 30 секунд
function GameMode:StartWaveSpawnTimer()
    print("Запуск таймера спавна волн")
    Timers:CreateTimer(0, function()
        -- Спавним волну
        GameMode:SpawnWave()

        -- Проверяем, достигли ли мы последней волны
        if GameMode.currentWave > GameMode.maxWaves then
            print("Все волны были заспавнены.")
            return nil  -- Останавливаем таймер
        else
            return WAVE_INTERVAL  -- Повторяем каждые 30 секунд
        end
    end)
end

function GameMode:OrderFilter(event)
	local type = event.order_type
	local playerId = event.issuer_player_id_const
	local unit 

	if event.units and event.units["0"] then 
		unit = EntIndexToHScript(event.units["0"])
	end

	if type == DOTA_UNIT_ORDER_PURCHASE_ITEM then 
        local item = event.shop_item_name
 
        if string.sub(item, 1, 19) == "item_upgrade_scroll" then
             local upgradeLevel  = tonumber(string.sub(item, 21)) 

            if upgradeLevel ~= 1 then
                if not BossManager:IsBossKilled(upgradeLevel - 1) then
                    CreateHudError(PlayerResource:GetPlayer(playerId), "#error_boss_not_killed", {level = upgradeLevel - 1})
                    return false
                end
            end
        end
	end

	return true
end

