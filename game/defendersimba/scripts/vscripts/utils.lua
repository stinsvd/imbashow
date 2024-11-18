function CreateHudError(player, message, options)
    CustomGameEventManager:Send_ServerToPlayer(player, "create_error_message", { message = message, options = options });
end