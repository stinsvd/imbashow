--Designed by: AniPream from ImbaShow :)
--19/12/2024
--Способность отслеживает удары по владельцу от (ГЕРОЕВ, КРИПОВ, КРИПГЕРОЕВ.) Каждый удар дает стак(ЖЕЛЕЗОБЕТОННО). Каждый стак сам по себе дает Бонусную броню.
--Удаление стаков работает через уникальный таймер а не Интервал так что нагрузка немного меньше.
--Присутсвует (Тултип) Отображение количества брони на текущий момент на иконке модификатора.
--Так же можно забацать эффект Хускара (партикл) при определенных количествах стаков particles/units/heroes/hero_huskar/huskar_inner_vitality.vpcf, менять цвет модели, размер модели и т.д.
LinkLuaModifier("modifier_axe_innate_ability", "heroes/hero_axe/axe_innate_ability", LUA_MODIFIER_MOTION_NONE) -- Прекэш (Подключаем) модификатора. В любой точке проэкта можно теперь взаимодейтсовать с данным модификатором.

axe_innate_ability = class({})


function axe_innate_ability:GetIntrinsicModifierName() -- какой модификатор дает абилка
    return "modifier_axe_innate_ability"
end

modifier_axe_innate_ability = class({
    IsHidden = function(self) return false end, -- можно скрыть иконку модификатора
    IsPurgable = function(self) return false end, --Развеивается?
    IsDebuff = function(self) return false end, --Дэбафф?
    IsBuff = function(self) return true end, --Бафф
    RemoveOnDeath = function(self) return false end, --Удаляется после смерти
    DeclareFunctions = function(self) return
        {
            MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, -- бонусная броня
            MODIFIER_EVENT_ON_ATTACK_LANDED, -- эвент атаки по кому либо
            MODIFIER_PROPERTY_TOOLTIP,-- отображение значений в модификаторе
        } end,
})

function modifier_axe_innate_ability:OnCreated()
    self.stacks = 0
    self:SetStackCount(1) -- Изначально 0 стаков тоесть ничего 
    print("врожденка OnCreated")

end

function modifier_axe_innate_ability:OnAttackLanded(keys)
    if keys.target == self:GetParent() and (keys.attacker:IsHero() or keys.attacker:IsCreep() or keys.attacker:IsCreepHero()) then -- кто меня ударил???
        local stack_per_attack = self:GetAbility():GetSpecialValueFor("stack_per_attack") -- количества стаков за ОДИН УДАР!
        local duration = self:GetAbility():GetSpecialValueFor("duration") -- Длительность каждого стака по отдельности

        self.stacks = self.stacks + stack_per_attack
        self:SetStackCount(self.stacks)
        -- Устанавливаем таймер для удаления стаков
        Timers:CreateTimer(duration, function()
            self:RemoveStack(stack_per_attack) -- Удаляем стаки через duration
        end)
    end
end

function modifier_axe_innate_ability:RemoveStack(amount)
    self.stacks = math.max(0, self.stacks - amount) -- Уменьшаем количество стаков
    self:SetStackCount(self.stacks) -- Обновляем количество стаков в модификаторе
end

function modifier_axe_innate_ability:GetModifierPhysicalArmorBonus()-- сама выдача брони. Обновляется сам по себе.
    local armor_per_stack = self:GetAbility():GetSpecialValueFor("armor_per_stack")
    local bonus_armor = self:GetStackCount() * armor_per_stack
    return bonus_armor -- Бонус к броне на основе количества стаков
end

function modifier_axe_innate_ability:OnTooltip()-- какую информацию мы хотим вывести(Далее добавляем в  локализацию)
    local armor_per_stack = self:GetAbility():GetSpecialValueFor("armor_per_stack")
    local bonus_armor = self:GetStackCount() * armor_per_stack
    return bonus_armor -- Передаем количество полученной брони
end