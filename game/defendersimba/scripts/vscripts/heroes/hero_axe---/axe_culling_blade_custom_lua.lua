--Designed by: AniPream and kxllswxtch from ImbaShow :)
--22/12/2024
-- Способность наносит чистый урон во врага. С агнимом урон наносится в радиусе 500 от основной цели способности.
-- Если способность убила врага или крипа то выдается сила на всегда в виде стаков.
-- Каждое N-ое срабатывание способности "axe_counter_helix_custom_lua" сбрасывает перезарядку ультимейта.
LinkLuaModifier("modifier_axe_culling_blade_custom_lua", "heroes/hero_axe/axe_culling_blade_custom_lua", LUA_MODIFIER_MOTION_NONE)

axe_culling_blade_custom_lua = class({})

function axe_culling_blade_custom_lua:GetIntrinsicModifierName()
    return "modifier_axe_culling_blade_custom_lua"
end

function axe_culling_blade_custom_lua:GetAOERadius()
    if not self:GetCaster():HasScepter() then return end
    return self:GetSpecialValueFor("radius") -- для отображение радиуса под курсором
end

function axe_culling_blade_custom_lua:OnAbilityPhaseStart()
    local target = self:GetCursorTarget()
    self:GetCaster():StartGesture(ACT_DOTA_CAST_ABILITY_4)
end

function axe_culling_blade_custom_lua:OnSpellStart()
    if IsServer() then
        local caster = self:GetCaster()
        local target = self:GetCursorTarget()
        local str_to_damage_pct = self:GetSpecialValueFor("str_to_damage_pct") / 100
        local str_per_hero = self:GetSpecialValueFor("str_per_hero") --стаков за героя
        local str_per_creep = self:GetSpecialValueFor("str_per_creep") --стаков за крипа
        self.radius = self:GetSpecialValueFor("radius")
        local strength = caster:GetStrength()
		local damage = strength * str_to_damage_pct -- Расчитываем урон от силы. Преобразуем целое число в процент.

        if caster:HasScepter() then -- если есть скипетр
            -- Находим врагов в радиусе
            local targets = FindUnitsInRadius(
                caster:GetTeamNumber(),
                target:GetAbsOrigin(),
                nil,
                self.radius,
                DOTA_UNIT_TARGET_TEAM_ENEMY,
                DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
                DOTA_UNIT_TARGET_FLAG_NONE, 
                FIND_ANY_ORDER,
                false
            )

            -- Наносим урон всем врагам в радиусе
            for _, enemy in pairs(targets) do
                if enemy:GetHealth() < damage and not (enemy:GetUnitName() == "npc_dota_roshan" or enemy:GetUnitName() == "npc_dota_miniboss") then
                    enemy:Kill(caster, self) -- Убедитесь, что передаете caster и ability
                    if enemy:IsHero() then
                        caster:IncrementKills(enemy:GetPlayerID())
                    end
                else
                    ApplyDamage({
                        victim = enemy,
                        attacker = caster,
                        damage = damage,
                        damage_type = DAMAGE_TYPE_PURE,
                        ability = self,
                    })
                end
                SendOverheadEventMessage(nil, OVERHEAD_ALERT_DAMAGE, enemy, damage, nil)
                if not enemy:IsAlive() then -- если цели не выжили, то добавляем стаки за них
                    local count
                    if enemy:IsHero() then
                        count = str_per_hero
                    else
                        count = str_per_creep
                    end -- если герой, то даем стаки как за героя, если крип, то как за крипа
                    local mod = caster:FindModifierByName("modifier_axe_culling_blade_custom_lua")
                    for _ = 1, count do
                        mod:IncrementStackCount()
                    end
                end
            end
            if target:IsAlive() then self:PlayEffects2(false, target) else self:PlayEffects2(true, target) end
        else -- НЕТ АГАНИМА
            if target:GetHealth() < damage and not (target:GetUnitName() == "npc_dota_roshan" or target:GetUnitName() == "npc_dota_miniboss") then
                -- Убиваем цель, передавая параметры
                target:Kill(caster, self)  -- caster как атакующий, self как способность
                if target:IsHero() then 
                    caster:IncrementKills(target:GetPlayerID())
                end
            else
                ApplyDamage({
                    victim = target,
                    attacker = caster,
                    damage = damage,
                    damage_type = DAMAGE_TYPE_PURE,
                    ability = self,
                })
            end
            
            if not target:IsAlive() then -- если цель не выжила то добавляем стак
                local count
                if target:IsHero() then 
                    count = str_per_hero 
                else 
                    count = str_per_creep 
                end -- если герой то даем стаки как за героя если крип то как за крипа
                local mod = caster:FindModifierByName("modifier_axe_culling_blade_custom_lua")
                for _ = 1, count do
                    mod:IncrementStackCount()
                end
                self:PlayEffects(true, target)
            else
                self:PlayEffects(false, target)
            end
        end
        _G.counter = 0 -- сбрасываем счетчик у глобальной переменной, мы хотим сбрасывать перезарядку только когда она начнется.
    end
end


function axe_culling_blade_custom_lua:PlayEffects(state, target)
    local caster = self:GetCaster()
    local fx
    if state then
        EmitSoundOnLocationWithCaster(caster:GetAbsOrigin(), "Hero_Axe.Culling_Blade_Success", caster)
        fx = "particles/units/heroes/hero_axe/axe_culling_blade_kill.vpcf"
    else
        EmitSoundOnLocationWithCaster(caster:GetAbsOrigin(), "Hero_Axe.Culling_Blade_Fail", caster)
        fx = "particles/units/heroes/hero_axe/axe_culling_blade.vpcf"
    end

    local direction = (target:GetOrigin() - self:GetCaster():GetOrigin()):Normalized()
    local index = ParticleManager:CreateParticle(fx, PATTACH_ABSORIGIN_FOLLOW, target)
    ParticleManager:SetParticleControl(index, 4, target:GetOrigin())
    ParticleManager:SetParticleControlForward(index, 3, direction)
    ParticleManager:SetParticleControlForward(index, 4, direction)
    ParticleManager:ReleaseParticleIndex(index)
end

function axe_culling_blade_custom_lua:PlayEffects2(state, target)
    local caster = self:GetCaster()
    local fx2
    local fx
    if state then
        EmitSoundOnLocationWithCaster(caster:GetAbsOrigin(), "Hero_Axe.Culling_Blade_Success", caster)
        fx2 = "particles/econ/items/centaur/centaur_ti6/centaur_ti6_warstomp.vpcf"
        local index = ParticleManager:CreateParticle(fx2, PATTACH_ABSORIGIN_FOLLOW, target)
        ParticleManager:SetParticleControl(index, 4, target:GetAbsOrigin())
        ParticleManager:SetParticleControlForward(index, 3, (target:GetOrigin() - self:GetCaster():GetOrigin()):Normalized())
        ParticleManager:SetParticleControlForward(index, 4, (target:GetOrigin() - self:GetCaster():GetOrigin()):Normalized())
        ParticleManager:SetParticleControl(index, 1, Vector(self.radius, 0, -225)) -- то что отвечает за радиус
        ParticleManager:ReleaseParticleIndex(index)
    else
        EmitSoundOnLocationWithCaster(caster:GetAbsOrigin(), "Hero_Axe.Culling_Blade_Fail", caster)
        fx2 = "particles/units/heroes/hero_axe/axe_culling_blade.vpcf"
        local direction = (target:GetOrigin() - self:GetCaster():GetOrigin()):Normalized()
        local index = ParticleManager:CreateParticle(fx2, PATTACH_ABSORIGIN_FOLLOW, target)
        ParticleManager:SetParticleControl(index, 4, target:GetOrigin())
        ParticleManager:SetParticleControlForward(index, 3, direction)
        ParticleManager:SetParticleControlForward(index, 4, direction)
        ParticleManager:ReleaseParticleIndex(index)
    end
end


modifier_axe_culling_blade_custom_lua = class({
    IsHidden = function(self) return false end,
    IsPurgable = function(self) return false end,
    IsDebuff = function(self) return false end,
    IsBuff = function(self) return true end,
    RemoveOnDeath = function(self) return false end,
    DeclareFunctions = function(self) return
        {
            MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
            MODIFIER_PROPERTY_TOOLTIP,
        } end,
})

function modifier_axe_culling_blade_custom_lua:OnCreated()
    if IsServer() then
        -- Устанавливаем начальное количество стеков
        self:SetStackCount(0)
        
        -- Глобальная переменная для отслеживания срабатываний другой абилки
        _G.counter = 0 
        
        -- Получаем способность, связанную с модификатором
        local ability = self:GetAbility()
        --ability:StartCooldown(0.1)
        
        -- Запускаем таймер на 1 секунду
        Timers:CreateTimer(1.0, function()
            -- Запускаем интервал после задержки
            self:StartIntervalThink(0.5)
        end)
    end
end

function modifier_axe_culling_blade_custom_lua:OnIntervalThink()
    local ability = self:GetAbility()
    if ability:IsCooldownReady() then
        _G.counter = 0
    end
    if _G.counter == self:GetAbility():GetSpecialValueFor("counter_to_refresh") then -- если число стало равным необбходимому то обнуляем число и сбрасываем кулдаун.
        _G.counter = 0
        self:GetAbility():EndCooldown()
    end
end

function modifier_axe_culling_blade_custom_lua:GetModifierBonusStats_Strength()
    return self:GetStackCount()
end

function modifier_axe_culling_blade_custom_lua:OnTooltip()
    return self:GetModifierBonusStats_Strength()
end