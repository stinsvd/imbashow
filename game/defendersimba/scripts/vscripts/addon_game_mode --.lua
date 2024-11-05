-- addon_game_mode.lua

-- Подключаем необходимые библиотеки
require('internal/util')
require('libraries/timers')
-- Подключаем модификатор
require('modifiers/modifier_golem_ai')
-- Регистрируем модификатор
LinkLuaModifier("modifier_golem_ai", "modifiers/modifier_golem_ai", LUA_MODIFIER_MOTION_NONE)

-- Объявляем класс GameMode, если он ещё не объявлен
if GameMode == nil then
    _G.GameMode = class({})
end

-- Переменные для отслеживания текущей волны и максимального количества волн
GameMode.currentWave = 1        -- Текущая волна
GameMode.maxWaves = 5           -- Максимальное количество волн

-- Таблица для хранения выбора игроков (пока не используем)
GameMode.playerChoices = {}

-- Функция Precache загружает необходимые ресурсы перед началом игры
function Precache(context)
    print("Начало Precache")
    for i = 1, GameMode.maxWaves do
        local unitName = "npc_dota_wave_" .. i
        print("Предварительная загрузка юнита:", unitName)
        PrecacheUnitByNameSync(unitName, context)
    end

    for i = 1, GameMode.maxWaves do
        local abilityName = "golem_ability_wave_" .. i
        print("Предварительная загрузка способности:", abilityName)
        PrecacheItemByNameSync(abilityName, context)
    end
    print("Precache завершён")
end


-- Функция Activate вызывается при старте кастомки
function Activate()
    GameMode:InitGameMode()
end

-- Функция инициализации режима игры
function GameMode:InitGameMode()
    print("GameMode инициализирован")

    -- Устанавливаем время выбора героев в 15 секунд
    GameRules:SetHeroSelectionTime(15)

    -- Устанавливаем стратегическое время в 0 секунд
    GameRules:SetStrategyTime(0)

    -- Устанавливаем время демонстрации героев в 0 секунд
    GameRules:SetShowcaseTime(0)

    -- Устанавливаем предыгровое время в 10 секунд
    GameRules:SetPreGameTime(10)

    -- Отключаем задержку автозапуска игры
    GameRules:SetCustomGameSetupAutoLaunchDelay(0)

    -- Устанавливаем начальное время суток на ночь (0.75 соответствует ночи)
    GameRules:SetTimeOfDay(0.75)

    -- Подписываемся на изменение состояния игры
    ListenToGameEvent("game_rules_state_change", Dynamic_Wrap(GameMode, "OnGameRulesStateChange"), self)
end

-- Функция, вызываемая при изменении состояния игры
function GameMode:OnGameRulesStateChange()
    local state = GameRules:State_Get()
    print("Game state changed to ", state)

    if state == DOTA_GAMERULES_STATE_PRE_GAME then
        print("Игра в состоянии предыгровой подготовки")

        -- Запускаем таймер для показа сообщения на отметке -00:05
        Timers:CreateTimer(function()
            local time = GameRules:GetDOTATime(true, true)
            print("Текущее игровое время: ", time)

            if time >= -5 and not GameMode.dialogShown then
                GameMode.dialogShown = true

                -- Показываем сообщение игрокам (пока убираем вызов функции)
                -- GameMode:ShowRandomBossMessage()

                -- Начинаем проверять выбор игроков (пока убираем вызов функции)
                -- GameMode:StartChoiceCheckTimer()

                return nil  -- Останавливаем таймер
            else
                return 1.0  -- Проверяем каждую секунду
            end
        end)
    elseif state == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
        print("Игра началась")

        -- Обрабатываем результаты выбора игроков (пока убираем вызов функции)
        -- GameMode:ProcessPlayerChoices()

        -- Запускаем спавн волн
        GameMode:StartWaveSpawnTimer()

        -- Запускаем таймер для преобразования игрока в финального босса на отметке 00:30 (пока убираем)
        -- GameMode:StartBossTransformationTimer()
    end
end

-- Функция для спавна волны юнитов
function GameMode:SpawnWave()
    print("Спавн волны номер:", GameMode.currentWave)

    -- Проверяем, не превысили ли мы максимальное количество волн
    if GameMode.currentWave > GameMode.maxWaves then
        print("Все волны были заспавнены.")
        return
    end

    -- Имя юнита для текущей волны
    local unitName = "npc_dota_wave_" .. GameMode.currentWave

    -- Координаты для спавна (настрой по своей карте)
    local spawnPoint = Vector(2732, -2869, 366)

    -- Спавним 10 юнитов
    for i = 1, 10 do
        -- Смещаем точку спавна, чтобы юниты не накладывались друг на друга
        local offset = Vector(RandomFloat(-200, 200), RandomFloat(-200, 200), 0)
        local spawnLocation = spawnPoint + offset

        -- Спавним юнита
        local unit = CreateUnitByName(unitName, spawnLocation, true, nil, nil, DOTA_TEAM_BADGUYS)

        if unit then
            print("Юнит заспавнен успешно:", unitName, "на позиции:", spawnLocation)
            -- Добавляем модификатор AI
            unit:AddNewModifier(unit, nil, "modifier_golem_ai", {})
        else
            print("Не удалось заспавнить юнита:", unitName)
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
            print("Все волны были заспавнены.")
            return nil  -- Останавливаем таймер
        else
            return 30.0  -- Повторяем каждые 30 секунд
        end
    end)
end
