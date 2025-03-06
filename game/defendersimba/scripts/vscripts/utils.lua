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

function RefreshThings(hero, cdr, abilities, items, ignore, backpack)
	if not IsServer() then return end
	ignore = ignore or false
	
	local exepctions = {
	-- Кастомные
		
	-- Обычные
		item_tango = false,
		item_tango_single = false,
		item_tpscroll = false,
		item_refresher_shard = false,
		item_bottle = false,
		item_dust = false,
		item_clarity = false,
		item_flask = false,
		item_faerie_fire = false,
		item_enchanted_mango = false,
		item_famango = false,
		item_great_famango = false,
		item_greater_famango = false,
		item_royale_with_cheese = false,
		item_blood_grenade = false,
		item_infused_raindrop = false,
		item_cheese = false,
		item_ward_observer = false,
		item_ward_sentry = false,
		item_ward_dispenser = false,
		item_tome_of_knowledge = false,
		item_royal_jelly = false,
		item_tome_of_aghanim = false,
		item_smoke_of_deceit = false,
	}
	
	if items then
		local invSlots = backpack and 8 or 5
		for i = 0, 16 do
			if i <= invSlots or i >= 15 then
				local item = hero:GetItemInSlot(i)
				if item and (item:IsRefreshable() or ignore) then
					local item_cd = item:GetCooldownTimeRemaining()
					if item_cd > 0 then
						item:EndCooldown()
						item:StartCooldown(math.max(item_cd - (item_cd * cdr / 100), 0))
					end
					if exepctions[item:GetAbilityName()] ~= false then
						if item:GetMaxAbilityCharges(-1) > 1 and item:GetCurrentAbilityCharges() < item:GetMaxAbilityCharges(-1) then
							local remCharges = item:GetMaxAbilityCharges(-1) - item:GetCurrentAbilityCharges()
							local newCharges = math.floor(item:GetCurrentAbilityCharges() + (remCharges * cdr / 100))
							item:SetCurrentCharges(newCharges)
						end
					end
				end
			end
		end
	end
	
	if abilities then
		for i = 0, hero:GetAbilityCount() - 1 do
			local abil = hero:GetAbilityByIndex(i)
			if abil and (abil:IsRefreshable() or ignore) then
				local abil_cd = abil:GetCooldownTimeRemaining()
				if abil_cd > 0 then
					abil:EndCooldown()
					abil:StartCooldown(math.max(abil_cd - (abil_cd * cdr / 100), 0))
				end
				if exepctions[abil:GetAbilityName()] ~= false then
					if abil:GetMaxAbilityCharges(-1) > 1 and abil:GetCurrentAbilityCharges() < abil:GetMaxAbilityCharges(-1) then
						local remCharges = abil:GetMaxAbilityCharges(-1) - abil:GetCurrentAbilityCharges()
						local newCharges = math.floor(abil:GetCurrentAbilityCharges() + (remCharges * cdr / 100))
						abil:SetCurrentAbilityCharges(newCharges)
					end
				end
			end
		end
	end
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
