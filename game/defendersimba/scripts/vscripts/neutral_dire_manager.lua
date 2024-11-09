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
            table.insert(self.spawnPoints, point)
            self:SpawnCamp(i)
        else
            print("Точка спавна crepsdire_" .. i .. "_point не найдена!")
        end
    end

    -- Подписываемся на событие, чтобы отслеживать убийства юнитов
    ListenToGameEvent("entity_killed", Dynamic_Wrap(NeutralDireManager, "OnEntityKilled"), self)
end

function NeutralDireManager:SpawnCamp(index)
    local spawnPoint = self.spawnPoints[index]:GetAbsOrigin()
    local camp = NEUTRAL_DIRE_CAMPS[index]

    local countUnits = 0
    for _, npc in ipairs(camp) do
        countUnits = countUnits + npc.count
    end
    self.spawnPoints[index].countUnits = countUnits

    for _, npc in ipairs(camp) do
        for i = 1, npc.count do
            local unit = CreateUnitByName(npc.unit, spawnPoint, true, nil, nil, DOTA_TEAM_NEUTRALS)
            if unit then
                unit.spawnIndex = index
            else
                print("Ошибка создания юнита:", npc.unit)
            end
        end
    end
end

function NeutralDireManager:OnEntityKilled(event)
    local killedUnit = EntIndexToHScript(event.entindex_killed)

    if killedUnit.spawnIndex then
        local index = killedUnit.spawnIndex
        local point = self.spawnPoints[index]
        point.countUnits = point.countUnits - 1

        if point.countUnits <= 0 then
            Timers:CreateTimer(RESPAWN_TIME, function()
                self:SpawnCamp(index)
            end)
        end
    end
end

-- Инициализация менеджера нейтралов Dire при запуске игры
if not NeutralDireManagerInit then
    NeutralDireManagerInit = true
    NeutralDireManager:Init()
end
