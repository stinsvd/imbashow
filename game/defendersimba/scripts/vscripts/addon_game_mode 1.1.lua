- addon_game_mode.lua

-- Подключаем необходимые библиотеки
require('internal/util')
require('libraries/timers')
require('libraries/notifications')

-- Подключаем модификатор
require('modifiers/modifier_golem_ai')

-- Регистрируем модификатор
LinkLuaModifier("modifier_golem_ai", "modifiers/modifier_golem_ai.lua", LUA_MODIFIER_MOTION_NONE)

-- Объявляем класс GameMode
if GameMode == nil then
    _G.GameMode = class({})
end

-- Объявляем переменные для отслеживания текущей волны и максимального количества волн
GameMode.currentWave = 1        -- Текущая волна
GameMode.maxWaves = 5           -- Максимальное количество волн

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
    PrecacheResource("lua", "modifiers/modifier_golem_ai.lua", context)

    -- Предварительно загружаем иконки юнитов (если используются)
    for i = 1, GameMode.maxWaves do
        local unitName = "npc_dota_wave_" .. i
        -- Добавьте путь к иконкам, если они имеются
        -- PrecacheResource("particle", "particles/units/heroes/hero_alchemist/alchemist_unstable_concoction.vpcf", context)
    end
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
    GameRules:SetHeroSelectionTime(0)

    -- Устанавливаем стратегическое время в 0 секунд
    GameRules:SetStrategyTime(0)

    -- Устанавливаем время демонстрации героев в 0 секунд
    GameRules:SetShowcaseTime(0)

    -- Устанавливаем предыгровое время в 10 секунд
    GameRules:SetPreGameTime(10)

    -- Отключаем время повторного соединения
    GameRules:SetCustomGameSetupAutoLaunchDelay(0)

    -- Устанавливаем начальное время суток на ночь (0.75 соответствует ночи)
    GameRules:SetTimeOfDay(0.75)

    -- Подписываемся на событие изменения состояния игры
    ListenToGameEvent("game_rules_state_change", Dynamic_Wrap(GameMode, "OnGameRulesStateChange"), self)

    -- Подписываемся на пользовательское событие выбора игрока
    CustomGameEventManager:RegisterListener("player_chose_boss", Dynamic_Wrap(GameMode, "OnPlayerChoseBoss"))
end

-- Функция, вызываемая при изменении состояния игры
function GameMode:OnGameRulesStateChange()
    local state = GameRules:State_Get()
    print("Game state changed to ", state)

    if state == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
        print("Game is in progress")

        -- Устанавливаем день
        GameRules:SetTimeOfDay(0.25)

        -- Показываем диалоговое окно игрокам
        GameMode:ShowRandomBossDialog()

        -- Запускаем таймер для проверки, когда все игроки сделают выбор
        GameMode:StartChoiceCheckTimer()
    end
end

-- Функция для показа диалога игрокам
function GameMode:ShowRandomBossDialog()
    print("Показываем диалоговое окно игрокам")

    -- Отправляем событие всем игрокам для отображения диалога
    CustomGameEventManager:Send_ServerToAllClients("show_random_boss_dialog", {})
end

-- Функция для обработки выбора игрока
function GameMode:OnPlayerChoseBoss(eventSourceIndex, args)
    local playerID = args.PlayerID
    local choice = args.choice

    if playerID ~= nil and choice ~= nil then
        print("Игрок", playerID, "сделал выбор:", choice)

        -- Сохраняем выбор игрока
        GameMode.playerChoices[playerID] = choice
    end
end

-- Функция для проверки, когда все игроки сделают выбор
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

            -- Обработка результатов выбора
            GameMode:ProcessPlayerChoices()

            -- Запускаем спавн волн
            GameMode:StartWaveSpawnTimer()

            return nil  -- Останавливаем таймер
        else
            -- Продолжаем проверять через 1 секунду
            return 1.0
        end
    end)
end

-- Функция для обработки результатов выбора игроков
function GameMode:ProcessPlayerChoices()
    print("Обработка результатов выбора игроков")

    -- Собираем список игроков, выбравших "Да"
    local bossCandidates = {}
    for playerID, choice in pairs(GameMode.playerChoices) do
        if choice == 1 then
            table.insert(bossCandidates, playerID)
        end
    end

    -- Выбираем случайного игрока из кандидатов или из всех игроков, если никто не выбрал "Да"
    local bossPlayerID = nil
    if #bossCandidates > 0 then
        bossPlayerID = bossCandidates[RandomInt(1, #bossCandidates)]
    else
        -- Если никто не выбрал "Да", выбираем случайного игрока из всех
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
    print("Игрок", bossPlayerID, "станет финальным боссом")

    -- Отправляем уведомление игрокам
    local playerName = PlayerResource:GetPlayerName(bossPlayerID)
    Notifications:BottomToAll({ text = playerName .. " станет финальным боссом!", duration = 5.0, style = { color = "red", ["font-size"] = "24px" } })

    -- Здесь вы можете добавить дополнительную логику для преобразования игрока в босса в конце игры
end

-- Функция для спавна волны юнитов
function GameMode:SpawnWave()
    print("Спавн волны номер:", GameMode.currentWave)

    -- Проверяем, не превышает ли текущая волна максимальное количество
    if GameMode.currentWave > GameMode.maxWaves then
        print("Все волны были спавнены.")
        return
    end

    -- Имя юнита для текущей волны
    local unitName = "npc_dota_wave_" .. GameMode.currentWave

    -- Координаты для спавна (настройте по вашей карте)
    local spawnPoint = Vector(2732, -2869, 366)

    -- Спавним 10 юнитов
    for i = 1, 10 do
        -- Смещаем точку спавна для каждого юнита, чтобы они не накладывались друг на друга
        local offset = Vector(RandomFloat(-200, 200), RandomFloat(-200, 200), 0)
        local spawnLocation = spawnPoint + offset

        -- Спавним юнита
        local unit = CreateUnitByName(unitName, spawnLocation, true, nil, nil, DOTA_TEAM_BADGUYS)

        if unit then
            -- Добавляем модификатор AI
            unit:AddNewModifier(unit, nil, "modifier_golem_ai", {})
        else
            print("Не удалось спавнить юнита:", unitName)
        end
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
            print("Все волны были спавнены.")
            return nil  -- Останавливаем таймер
        else
            return 30.0  -- Повторяем таймер каждые 30 секунд
        end
    end)
end
