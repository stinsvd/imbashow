modifier_axe_battle_hunger_lua = class({
    IsHidden = function(self) return false end, -- можно скрыть иконку модификатора
    IsPurgable = function(self) return false end, -- Развеивается?
    IsDebuff = function(self) return false end, -- Дэбафф?
    IsStunDebuff = function(self) return false end, -- Бафф
    RemoveOnDeath = function(self) return true end, -- Удаляется после смерти
    GetAttributes = function(self) return MODIFIER_ATTRIBUTE_MULTIPLE end,
    DeclareFunctions = function(self) return
    {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    } end,
})

function modifier_axe_battle_hunger_lua:OnCreated(kv)
    self.bonus = self:GetAbility():GetSpecialValueFor("speed_bonus")
    if kv.str_bonus_per_hero then
        self.strength_bonus = kv.str_bonus_per_hero
    else
        self.strength_bonus = 0 -- Если бонус не передан, устанавливаем его в 0
    end
end

function modifier_axe_battle_hunger_lua:GetModifierMoveSpeedBonus_Percentage()
    return self.bonus
end

function modifier_axe_battle_hunger_lua:GetModifierBonusStats_Strength()
    return self.strength_bonus
end