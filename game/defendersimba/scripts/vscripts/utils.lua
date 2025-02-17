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

function AllowedToDo(playerID)
	local allowedSteamIDS = {
		[107155453] = true, --Aplpn
	}
	if PlayerResource:IsValidPlayerID(playerID) then
		local steamID = tonumber(PlayerResource:GetSteamAccountID(playerID))
		if steamID and allowedSteamIDS[steamID] then
			return true
		end
	end
	return false
end

function OrderAttackTarget(owner, target, queue)
	if not target:IsInvulnerable() and not target:IsAttackImmune() and not owner:IsCommandRestricted() and not owner:IsTaunted() then
		ExecuteOrderFromTable({
			UnitIndex = owner:entindex(),
			OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
			TargetIndex = target:entindex(),
			Queue = queue or false,
		})
	end
end


function string.trim(s)
	return s:match "^%s*(.-)%s*$"
end
function string.pipei(s, sep)
	if sep == nil then
		sep = "%s"
	end
	local i
	local t={} ; i = 1
	for str in string.gmatch(s, "([^"..sep.."]+)") do
		t[i] = str
		i = i + 1
	end
	return t
end


_G._UnitModifiers = _G._UnitModifiers or {
	CritModifiers = {},
}
-- Spell Crit
function CDOTA_Modifier_Lua:AddSpellCritModifier()
	local index = self:GetParent():entindex()
	local new_mod = self
	if _G._UnitModifiers["CritModifiers"][index] == nil then
		_G._UnitModifiers["CritModifiers"][index] = {}
	end
	local ttable = _UnitModifiers["CritModifiers"][index]
	for _, mod in pairs(ttable) do
		if mod and not mod:IsNull() and mod == new_mod then
			return
		end
	end
	table.insert(_G._UnitModifiers["CritModifiers"][index], new_mod)
end
