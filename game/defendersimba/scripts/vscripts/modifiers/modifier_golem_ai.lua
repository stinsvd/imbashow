-- modifiers/modifier_golem_ai.lua

modifier_golem_ai = class({})

function modifier_golem_ai:IsHidden()
    return true
end

function modifier_golem_ai:IsPurgable()
    return false
end

function modifier_golem_ai:OnCreated(kv)
    if IsServer() then
        local golem = self:GetParent()

        -- Координаты вражеской базы
        local enemy_base = Vector(-10562, 10484, 634)

        -- Рассчитываем точку назначения
        self.target_point = enemy_base

        -- Отдаём команду движения в режиме атаки
        golem:MoveToPositionAggressive(self.target_point)

        -- Запускаем периодический вызов функции Think
        self:StartIntervalThink(1.0)
    end
end

function modifier_golem_ai:OnIntervalThink()
    if IsServer() then
        local golem = self:GetParent()

        if golem and golem:IsAlive() then
            -- Если голем не атакует и не движется, продолжаем движение
            if not golem:IsAttacking() and not golem:IsMoving() then
                -- Проверяем, достиг ли голем точки назначения
                local current_position = golem:GetAbsOrigin()
                local distance_to_target = (self.target_point - current_position):Length2D()
                if distance_to_target < 100 then
                    -- Достиг точки назначения, продолжаем движение в ту же точку
                    golem:MoveToPositionAggressive(self.target_point)
                    return
                end

                -- Ищем ближайших врагов
                local enemies = FindUnitsInRadius(
                    golem:GetTeamNumber(),
                    golem:GetAbsOrigin(),
                    nil,
                    golem:GetAcquisitionRange(),
                    DOTA_UNIT_TARGET_TEAM_ENEMY,
                    DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
                    DOTA_UNIT_TARGET_FLAG_NO_INVIS + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE,
                    FIND_ANY_ORDER,
                    false
                )

                if #enemies > 0 then
                    -- Атакуем первого врага
                    golem:MoveToTargetToAttack(enemies[1])
                else
                    -- Продолжаем движение к вражеской базе
                    golem:MoveToPositionAggressive(self.target_point)
                end
            end
        end
    end
end
