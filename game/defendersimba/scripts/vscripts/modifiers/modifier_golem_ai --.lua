-- modifiers/modifier_golem_ai.lua

modifier_golem_ai = class({})

function modifier_golem_ai:IsHidden()
    return true  -- Модификатор скрыт
end

function modifier_golem_ai:IsPurgable()
    return false  -- Модификатор не может быть удален
end

function modifier_golem_ai:OnCreated(kv)
    if IsServer() then
        local golem = self:GetParent()

        if not golem then
            print("modifier_golem_ai: Ошибка - нет родительского юнита.")
            return
        end

        -- Определяем целевую точку (например, база противника)
        self.target_point = Vector(-10862, 10454, 0)  -- Задай нужные координаты

        -- Отдаём команду движения
        golem:MoveToPositionAggressive(self.target_point)

        -- Запускаем периодический вызов функции Think
        self:StartIntervalThink(1.0)  -- Интервал: 1 секунда
    end
end

function modifier_golem_ai:OnIntervalThink()
    if IsServer() then
        local golem = self:GetParent()

        if not golem or not golem:IsAlive() then
            -- Если юнита нет или он мертв, ничего не делаем
            return
        end

        -- Проверяем, есть ли враги в радиусе
        -- Заменяем GetAcquisitionRange на фиксированное значение, например, 300
        local acquisition_range = 300
        local enemies = FindUnitsInRadius(
            golem:GetTeamNumber(),
            golem:GetAbsOrigin(),
            nil,
            acquisition_range,
            DOTA_UNIT_TARGET_TEAM_ENEMY,
            DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
            DOTA_UNIT_TARGET_FLAG_NO_INVIS + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE,
            FIND_ANY_ORDER,
            false
        )

        if #enemies > 0 then
            -- Атакуем первого врага
            golem:MoveToTargetToAttack(enemies[1])
            print("Юнит атакует врага.")
        else
            -- Если юнит не движется, продолжаем движение к цели
            if not golem:IsMoving() then
                golem:MoveToPositionAggressive(self.target_point)
                print(string.format("Юнит продолжает движение к: %s", tostring(self.target_point)))
            end
        end
    end
end
