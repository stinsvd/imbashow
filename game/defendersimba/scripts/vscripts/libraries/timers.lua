-- timers.lua

-- Версия библиотеки Timers
TIMERS_VERSION = "1.07"

-- Интервал проверки таймеров
local TIMERS_THINK = 0.01

if not Timers then
    print("[Timers] Creating Timers Library...")
    Timers = {}
    Timers.__index = Timers
end

-- Создаём новую таблицу таймеров
function Timers:new(o)
    o = o or {}
    setmetatable(o, Timers)
    return o
end

-- Инициализируем библиотеку таймеров
function Timers:start()
    Timers = self
    self.timers = {}

    -- Создаём энтити, которая будет выполнять функцию Think
    local ent = Entities:CreateByClassname("info_target") -- Создаём пустую энтити
    ent:SetThink("Think", self, "timers", TIMERS_THINK)
end

-- Главная функция Think, которая вызывается каждый тик
function Timers:Think()
    -- Получаем текущее игровое время
    local now = GameRules:GetGameTime()

    -- Проходим по всем таймерам
    for k, v in pairs(self.timers) do
        local bUseGameTime = v.useGameTime ~= false
        local bOldStyle = v.useOldStyle == true

        local currentTime = now
        if not bUseGameTime then
            currentTime = Time()
        end

        -- Проверяем, истёк ли таймер
        if currentTime >= v.endTime then
            -- Удаляем таймер из списка
            self.timers[k] = nil

            -- Запускаем функцию обратного вызова
            local status, nextCall = pcall(v.callback, v)

            -- Проверяем, успешно ли отработала функция
            if status then
                if nextCall then
                    -- Если функция вернула значение, переустанавливаем таймер
                    v.endTime = currentTime + nextCall
                    self.timers[k] = v
                end
            else
                -- В случае ошибки выводим её в консоль
                print("[Timers] Timer '" .. k .. "' callback error: " .. nextCall)
            end
        end
    end

    return TIMERS_THINK
end

-- Функция для создания нового таймера
function Timers:CreateTimer(name, args)
    if type(name) == "function" then
        args = { callback = name }
        name = DoUniqueString("timer")
    elseif type(name) == "table" then
        args = name
        name = DoUniqueString("timer")
    elseif type(name) == "number" then
        args = { endTime = name, callback = args }
        name = DoUniqueString("timer")
    end

    if not args.callback then
        print("[Timers] Invalid timer created: " .. name)
        return
    end

    local now = GameRules:GetGameTime()
    if args.useGameTime == false then
        now = Time()
    end

    if args.endTime == nil then
        args.endTime = now
    else
        if args.useOldStyle then
            args.endTime = args.endTime
        else
            args.endTime = now + args.endTime
        end
    end

    self.timers[name] = args

    return name
end

-- Функция для удаления таймера
function Timers:RemoveTimer(name)
    self.timers[name] = nil
end

-- Функция для удаления всех таймеров
function Timers:RemoveTimers(killAll)
    local timers = {}

    if not killAll then
        for k, v in pairs(self.timers) do
            if v.persist then
                timers[k] = v
            end
        end
    end

    self.timers = timers
end

-- Инициализируем библиотеку таймеров, если она ещё не инициализирована
if not Timers.timers then Timers:start() end

-- Привязываем Timers к GameRules, чтобы иметь к ней доступ из других скриптов
GameRules.Timers = Timers
