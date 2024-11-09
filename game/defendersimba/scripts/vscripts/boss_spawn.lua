-- Время респавна босса после его убийства (в секундах)
BOSS_RESPAWN_TIME = 1

if BossManager == nil then
    BossManager = class({})
end

function BossManager:Init()
    -- Таблица точек для спавна боссов
    self.bossPoints = {}

    -- Находим все точки спавна боссов, названные boss_1_point, boss_2_point, ..., boss_6_point
    for i = 1, 6 do
        local point = Entities:FindByName(nil, "boss_" .. i .. "_point")
        if point then
            table.insert(self.bossPoints, point)
            self:SpawnBoss(i)
        else
            print("Точка спавна boss_" .. i .. "_point не найдена!")
        end
    end

    -- Подписываемся на событие, чтобы респавнить босса после его убийства
    ListenToGameEvent("entity_killed", Dynamic_Wrap(BossManager, "OnEntityKilled"), self)
end

function BossManager:SpawnBoss(bossIndex)
    local spawnPoint = self.bossPoints[bossIndex]:GetAbsOrigin()
    local bossName = "npc_dota_boss_" .. bossIndex

    -- Спавн юнита босса
    local bossUnit = CreateUnitByName(bossName, spawnPoint, true, nil, nil, DOTA_TEAM_NEUTRALS)
    bossUnit.bossIndex = bossIndex  -- привязываем индекс босса к юниту, чтобы знать, какой именно босс был убит
end

function BossManager:OnEntityKilled(event)
    local killedUnit = EntIndexToHScript(event.entindex_killed)

    -- Проверяем, убит ли босс, у которого задан индекс
    if killedUnit.bossIndex then
        local bossIndex = killedUnit.bossIndex
        print("Босс " .. bossIndex .. " убит, респавн через " .. BOSS_RESPAWN_TIME .. " секунд.")
        
        -- Запускаем таймер для респавна босса
        Timers:CreateTimer(BOSS_RESPAWN_TIME, function()
            self:SpawnBoss(bossIndex)
        end)
    end
end

-- Инициализация менеджера боссов при запуске игры
if not BossManagerInit then
    BossManagerInit = true
    BossManager:Init()
end
