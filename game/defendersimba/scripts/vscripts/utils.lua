function CreateHudError(player, message, options)
    CustomGameEventManager:Send_ServerToPlayer(player, "create_error_message", { message = message, options = options });
end

function DoWithAllPlayers(func)
    for i=0, PlayerResource:GetPlayerCount() - 1 do 
      local player = PlayerResource:GetPlayer(i)
      local hero = PlayerResource:GetSelectedHeroEntity(i) 
  
      func(player, hero, i)
    end 
end

function GiveAllGoldAndXp(reward, team)
    DoWithAllPlayers(function(player, hero, playerID)
        if not hero then return end
        if hero:GetTeamNumber() ~= team then return end

        SendOverheadEventMessage(player, OVERHEAD_ALERT_GOLD, hero, reward.gold, nil)
        PlayerResource:ModifyGold(playerID, reward.gold, true, 0)
        hero:AddExperience(reward.xp, 0, false, false)
    end)
end