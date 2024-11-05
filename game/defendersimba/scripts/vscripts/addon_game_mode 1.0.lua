--Рабочий код, реализовано:
-- 1. Игра начинается с -00:10. 2. На 00:00 спавнится юнит и двигается в сторону трона. 3. При движении атакует все вражеское на пути.
-- 4. Юниты спавнятся ровно каждые 30 секунд
-- addon_game_mode.lua
-- Подключаем необходимые библиотеки
require('internal/util')
require('libraries/timers')

-- Подключаем модификатор
require('modifiers/modifier_golem_ai')

-- Регистрируем модификатор
LinkLuaModifier("modifier_golem_ai", "modifiers/modifier_golem_ai.lua", LUA_MODIFIER_MOTION_NONE)

-- Объявляем класс GameMode
if GameMode == nil then
    _G.GameMode = class({})
end

-- Функция Precache загружает необходимые ресурсы перед началом игры
function Precache(context)
    -- Предварительно загружаем нашего кастомного юнита
    PrecacheUnitByNameSync("npc_dota_custom_warlock_golem", context)
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
    ListenToGameEvent("game_rules_state_change", Dynamic_Wrap(GameMode, "OnGameRulesStateChange"), GameMode)
end

-- Функция, вызываемая при изменении состояния игры
function GameMode:OnGameRulesStateChange()
    local state = GameRules:State_Get()
    print("Game state changed to ", state)

    if state == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
        print("Game is in progress, spawning golems")

        -- Устанавливаем день
        GameRules:SetTimeOfDay(0.25)

        -- Спавним первого голема
        GameMode:SpawnGolem()

        -- Запускаем таймер для спавна големов каждые 30 секунд
        GameMode:StartGolemSpawnTimer()
    end
end

-- Функция для спавна голема
function GameMode:SpawnGolem()
    -- Координаты для спавна
    local spawnPoint = Vector(2732, -2869, 366)
    print("Spawning Golem at ", spawnPoint)

    -- Спавним юнита 'npc_dota_custom_warlock_golem' на указанной точке от команды BADGUYS
    local golem = CreateUnitByName("npc_dota_custom_warlock_golem", spawnPoint, true, nil, nil, DOTA_TEAM_BADGUYS)

    -- Проверяем, что голем был успешно создан
    if golem then
        -- Добавляем модификатор AI без способности
        golem:AddNewModifier(golem, nil, "modifier_golem_ai", {})
    else
        print("Failed to spawn golem!")
    end
end

-- Функция для запуска таймера спавна големов каждые 30 секунд
function GameMode:StartGolemSpawnTimer()
    print("Starting timer to spawn golems every 30 seconds")
    Timers:CreateTimer(30, function()
        print("Timer triggered, spawning new golem")
        GameMode:SpawnGolem()
        return 30.0  -- Повторяем таймер каждые 30 секунд
    end)
end
