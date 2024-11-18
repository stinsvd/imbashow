require('tables/neutral_dire_camps')
-- Время респавна после убийства всех юнитов в точке
local RESPAWN_TIME = 5

if NeutralDireManager == nil then
    NeutralDireManager = class({})
end

function NeutralDireManager:Init()
    -- Инициализация таблицы точек спавна
    self.spawnPoints = {}

    -- Находим точки спавна, названные crepsdire_1_point, crepsdire_2_point, ..., crepsdire_4_point
    for i = 1, 4 do
        local point = Entities:FindByName(nil, "crepsdire_" .. i .. "_point")
        if point then
            point.index = i -- Привязываем индекс к точке
            table.insert(self.spawnPoints, point)
            self:SpawnCamp(point) -- Передаём точку напрямую
        else
            print("Точка спавна crepsdire_" .. i .. "_point не найдена!")
        end
    end

    -- Подписываемся на событие, чтобы отслеживать убийства юнитов
    ListenToGameEvent("entity_killed", Dynamic_Wrap(NeutralDireManager, "OnEntityKilled"), self)
end

function NeutralDireManager:SpawnCamp(point)
    local camp = NEUTRAL_DIRE_CAMPS[point.index]
    local spawnPoint = point:GetAbsOrigin()

    -- Считаем количество юнитов в лагере
    local countUnits = 0
    for _, npc in ipairs(camp) do
        countUnits = countUnits + npc.count
    end
    point.countUnits = countUnits -- Привязываем количество юнитов к самой точке

    -- Спавним юнитов
    for _, npc in ipairs(camp) do
        for i = 1, npc.count do
            local unit = CreateUnitByName(npc.unit, spawnPoint, true, nil, nil, DOTA_TEAM_NEUTRALS)
            if unit then
                unit.neutralCamp = point -- Привязываем юнита к точке спавна
            else
                print("Ошибка создания юнита:", npc.unit)
            end
        end
    end
end

function NeutralDireManager:OnEntityKilled(event)
    local killedUnit = EntIndexToHScript(event.entindex_killed)

    if killedUnit.neutralCamp then
        local point = killedUnit.neutralCamp
        point.countUnits = point.countUnits - 1 -- Уменьшаем счётчик юнитов в лагере

        if point.countUnits <= 0 then
            Timers:CreateTimer(RESPAWN_TIME, function()
                self:SpawnCamp(point) -- Передаём точку напрямую
            end)
        end
    end
end

-- Инициализация менеджера нейтралов Dire при запуске игры
if not NeutralDireManagerInit then
    NeutralDireManagerInit = true
    NeutralDireManager:Init()
end
