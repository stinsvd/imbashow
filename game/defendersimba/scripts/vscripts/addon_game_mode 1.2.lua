-- addon_game_mode.lua

-- Подключаем необходимые библиотеки
require('internal/util')
require('libraries/timers')

-- Подключаем модификатор
require('modifiers/modifier_golem_ai')

-- Регистрируем модификатор
LinkLuaModifier("modifier_golem_ai", "modifiers/modifier_golem_ai", LUA_MODIFIER_MOTION_NONE)

-- Объявляем класс GameMode
if GameMode == nil then
    _G.GameMode = class({})
end

-- Переменные для отслеживания текущей волны и максимального количества волн
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
    --PrecacheResource("lua", "modifiers/modifier_golem_ai.lua", context)
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

                -- Показываем сообщение игрокам
                GameMode:ShowRandomBossMessage()

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



-- Функция для показа сообщения игрокам
function GameMode:ShowRandomBossMessage()
    print("Показываем сообщение игрокам")

    -- Отображаем сообщение, используя ключ локализации
    GameRules:SendCustomMessage("#random_boss_message", 0, 0)

    -- Подписываемся на событие чата игроков
    ListenToGameEvent("player_chat", Dynamic_Wrap(GameMode, "OnPlayerChat"), self)
end

-- Функция для обработки ввода чата игроков
function GameMode:OnPlayerChat(keys)
    local text = string.lower(keys.text)
    local playerID = keys.playerid

    if text == "да" or text == "yes" then
        GameMode:OnPlayerChoseBoss({ PlayerID = playerID, choice = 1 })
    elseif text == "нет" or text == "no" then
        GameMode:OnPlayerChoseBoss({ PlayerID = playerID, choice = 0 })
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
    print("Игрок", bossPlayerID, "станет финальным боссом")

    -- Получаем имя героя игрока
    local heroName = PlayerResource:GetSelectedHeroName(bossPlayerID)
    print("Имя героя игрока:", heroName)

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

    -- Уведомляем всех игроков
    GameRules:SendCustomMessage("Финальным боссом станет " .. heroName .. "!", 0, 0)
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
