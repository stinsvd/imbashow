-- npc_dota_courier.lua

-- Модуль для создания курьеров
if CourierManager == nil then
    CourierManager = class({})
end

-- Функция для автоматического создания курьеров
function CourierManager()
    print("[Custom Game] Spawning couriers for all players...")

    -- Проходим по всем игрокам
    for playerID = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
        if PlayerResource:IsValidPlayerID(playerID) and PlayerResource:GetConnectionState(playerID) == DOTA_CONNECTION_STATE_CONNECTED then
            -- Проверяем, есть ли у игрока герой
            local hero = PlayerResource:GetSelectedHeroEntity(playerID)
            if hero then
                -- Создаем курьера
                local courier = CreateUnitByName("npc_dota_courier", hero:GetAbsOrigin(), true, hero, hero, hero:GetTeam())

                -- Привязываем курьера к игроку
                courier:SetControllableByPlayer(playerID, true)

                -- Назначаем курьеру команду игрока
                courier:SetTeam(hero:GetTeam())

                -- Логируем успешный спавн
                print("Courier spawned for player ID: " .. playerID)
            else
                print("No hero found for player ID: " .. playerID)
            end
        end
    end
end

-- Подключаем функцию к стадии PRE_GAME
ListenToGameEvent("game_rules_state_change", function()
    if GameRules:State_Get() == DOTA_GAMERULES_STATE_PRE_GAME then
        CourierManager()
    end
end, nil)
