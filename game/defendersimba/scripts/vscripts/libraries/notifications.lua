-- notifications.lua

if Notifications == nil then
    Notifications = {}
    Notifications.__index = Notifications
end

-- Отправляет уведомление снизу всем игрокам
function Notifications:BottomToAll(params)
    CustomGameEventManager:Send_ServerToAllClients("notifications_bottom", params)
end

-- Добавьте дополнительные функции для уведомлений, если необходимо
