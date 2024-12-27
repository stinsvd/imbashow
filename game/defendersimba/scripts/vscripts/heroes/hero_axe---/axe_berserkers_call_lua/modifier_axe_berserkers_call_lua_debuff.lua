-- Модификатор Дебафф для врагов данной способности.
modifier_axe_berserkers_call_lua_debuff = class({
    IsHidden = function(self) return false end, -- можно скрыть иконку модификатора
    IsPurgable = function(self) return false end, -- Развеивается?
    IsDebuff = function(self) return true end, -- Дэбафф?
    IsStunDebuff = function(self) return false end,
    DeclareFunctions = function(self) return
    {
        MODIFIER_EVENT_ON_DEATH, -- бонусная броня
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT -- добавляем скорость атаки
    } end,
})

-- Initializations
function modifier_axe_berserkers_call_lua_debuff:OnCreated(kv)
    if IsServer() then
        self.buff_attack_speed_enemy = kv.buff_attack_speed_enemy -- принимаем ключ скорости атаки из абилки
        self:GetParent():SetForceAttackTarget(self:GetCaster()) -- для крипов
        self:GetParent():MoveToTargetToAttack(self:GetCaster()) -- для героев
		self:SetHasCustomTransmitterData(true) -- вызов трансмитера
    end
end

function modifier_axe_berserkers_call_lua_debuff:AddCustomTransmitterData()
    return {
        buff_attack_speed_enemy = self.buff_attack_speed_enemy,
    }
end
--=======================================================================================
-- ВНИМАНИЕ!!! НЕ ТРОГАТЬ, Позволяет отображать у врага скорость атаки уже с бонусом,
-- без трансмитера скорость атаки у врага будет прежней! а бонус который дается, отображатся у него не будет!!! хоть он и есть)))
function modifier_axe_berserkers_call_lua_debuff:HandleCustomTransmitterData(data)
	if data.buff_attack_speed_enemy then
		self.buff_attack_speed_enemy = data.buff_attack_speed_enemy
	end
end

function modifier_axe_berserkers_call_lua_debuff:OnRemoved()
    if IsServer() then
        self:GetParent():SetForceAttackTarget(nil)
    end
end
--=======================================================================================
-- Метод для изменения скорости атаки
function modifier_axe_berserkers_call_lua_debuff:GetModifierAttackSpeedBonus_Constant()
    return self.buff_attack_speed_enemy
end

function modifier_axe_berserkers_call_lua_debuff:CheckState()
	local state = {
		[MODIFIER_STATE_COMMAND_RESTRICTED] = true, -- отключает возможность управление и т.д.
	}

	return state
end

function modifier_axe_berserkers_call_lua_debuff:GetStatusEffectName()
	return "particles/status_fx/status_effect_beserkers_call.vpcf"
end

function modifier_axe_berserkers_call_lua_debuff:OnDeath(params)
	if params.unit ~= self:GetParent() then return end
end