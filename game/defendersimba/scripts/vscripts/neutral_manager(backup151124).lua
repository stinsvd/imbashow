require('tables/neutral_camps')

if NeutralManager == nil then
    NeutralManager = class({})
end

-- Время спавна нейтралов
SPAWN_TIME = 1

function NeutralManager:Init() 

    
    for level = 1, 6 do
        local points = Entities:FindAllByName("creeps_"..level.."_point")

        for _, point in ipairs(points) do
            point.level = level
            self:SpawnCamp(point)
        end
    end

    ListenToGameEvent("entity_killed", Dynamic_Wrap(NeutralManager, "OnEntityKilled"), self)
end

function NeutralManager:SpawnCamp(point)
    local camps = NEUTRAL_CAMPS[point.level]
    local spawnPoint = point:GetAbsOrigin()
    local camp = camps[RandomInt(1, #camps)]

    local countUnits = 0
    for _, npc in ipairs(camp) do
        countUnits = countUnits + npc.count
    end
    point.countUnits = countUnits

    for _, npc in ipairs(camp) do
        for i = 1, npc.count do
            local unit = CreateUnitByName(npc.unit, spawnPoint, true, nil, nil, DOTA_TEAM_NEUTRALS)
            unit.neutralCamp = point
        end
    end
end

function NeutralManager:OnEntityKilled(event)
    local killedUnit = EntIndexToHScript(event.entindex_killed)

    if killedUnit.neutralCamp then
        local point = killedUnit.neutralCamp
        point.countUnits = point.countUnits - 1
        print(point.countUnits)
        if point.countUnits <= 0 then
            Timers:CreateTimer(SPAWN_TIME, function()
                self:SpawnCamp(point)
            end)   
        end
    end
end
