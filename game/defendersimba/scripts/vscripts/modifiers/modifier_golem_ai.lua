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
	--	golem:SetAcquisitionRange(1600)

        -- Координаты вражеской базы
        local enemy_base = Entities:FindByName(nil, "dota_goodguys_fort"):GetAbsOrigin()		--Vector(-10562, 10484, 634)

        -- Рассчитываем точку назначения
        self.target_point = enemy_base

        -- Отдаём команду движения в режиме атаки
        golem:MoveToPositionAggressive(self.target_point)

        -- Запускаем периодический вызов функции Think
        self:OnIntervalThink()
        self:StartIntervalThink(0.5)
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
					local target
					local targetPos
					for _, towers in ipairs(GameMode.TowersTable) do
						local tower_1Unit = EntIndexToHScript(towers._1.unit)
						local tower_2Unit = EntIndexToHScript(towers._2.unit)
						if tower_1Unit and tower_2Unit and tower_1Unit:IsAlive() and tower_2Unit:IsAlive() and (towers._1.team == DOTA_TEAM_GOODGUYS or towers._2.team == DOTA_TEAM_GOODGUYS) then
							targetPos = Entities:FindByName(nil, towers.key.."_point"):GetAbsOrigin()
						end
					end
					if targetPos then
						local buildings = FindUnitsInRadius(golem:GetTeamNumber(), targetPos, nil, 1000, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BUILDING, DOTA_UNIT_TARGET_FLAG_NO_INVIS, FIND_ANY_ORDER, false)
						for i = 1, #buildings do
							if not buildings[i]:IsAttackImmune() or not buildings[i]:IsInvulnerable() and string.match(buildings[i]:GetUnitName(), "_tower_cus") then
								target = buildings[i]
								break
							end
						end
					else
						targetPos = self.target_point
					end
					if target then
						golem:MoveToPositionAggressive(target:GetAbsOrigin())
					else
						golem:MoveToPositionAggressive(targetPos)
					end
                end
            end
        end
    end
end
