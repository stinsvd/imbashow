--Designed by: AniPream and kxllswxtch from ImbaShow :)
--21/12/2024
--Способность наносит чистый урон в радиусе. Срабатывает когда владелец ударит несколько раз по врагам(крипы, герои, строения) или по владельцу ударят(крипы, герои, строения).
--Способность крадет силу у вражеских героев и дает силу нам. Эффект обновляется каждый раз при добавлении стаков
--Присутсвует глобальная переменная для отслеживания количества срабатываний что бы сбросить кулдаун у способности "axe_culling_blade_custom_lua"

LinkLuaModifier("modifier_axe_counter_helix_custom_lua", "heroes/hero_axe/axe_counter_helix_custom_lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_axe_counter_helix_custom_lua_debuff", "heroes/hero_axe/axe_counter_helix_custom_lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_axe_counter_helix_custom_lua_buff", "heroes/hero_axe/axe_counter_helix_custom_lua", LUA_MODIFIER_MOTION_NONE)

axe_counter_helix_custom_lua = class({})

function axe_counter_helix_custom_lua:GetCastRange()
    return self:GetSpecialValueFor("radius")
end

function axe_counter_helix_custom_lua:GetIntrinsicModifierName()
    return "modifier_axe_counter_helix_custom_lua"
end

modifier_axe_counter_helix_custom_lua = class({
    IsHidden = function(self) return false end,
    IsPurgable = function(self) return false end,
    IsDebuff = function(self) return false end,
    IsBuff = function(self) return true end,
    RemoveOnDeath = function(self) return false end,
    GetAttributes = function(self) return MODIFIER_ATTRIBUTE_MULTIPLE end,
    DeclareFunctions = function(self) return
        {
            MODIFIER_EVENT_ON_ATTACK_LANDED,
        } end,
})

function modifier_axe_counter_helix_custom_lua:OnCreated()
    local ability = self:GetAbility()
    self.radius = ability:GetSpecialValueFor("radius")
    self.duration = ability:GetSpecialValueFor("duration")
    -- Инициализируем стеки при создании модификатора
    self:SetStackCount(ability:GetSpecialValueFor("attack_need")) -- Устанавливаем начальное количество стаков
    self.steal_str = ability:GetSpecialValueFor("steal_str")
end

function modifier_axe_counter_helix_custom_lua:OnAttackLanded(params)
    if not IsServer() then return end

    local caster = self:GetCaster()
    local ability = self:GetAbility()

    if caster == params.attacker or params.target == caster then

        -- Уменьшаем количество стаков
        local currentStacks = self:GetStackCount()
        if currentStacks > 0 then
            self:SetStackCount(currentStacks - 1)
            print("Stacks decreased to: " .. self:GetStackCount())
        end

        -- Проверяем, если стаков больше нет
        if self:GetStackCount() == 0 then
            self:PlayEffects() -- Проигрываем эффект
            self:DealDamage()   -- Наносим урон

            -- Восстанавливаем стеки из ключа "attack_need"
            local attackNeed = ability:GetSpecialValueFor("attack_need")
            if attackNeed then
                self:SetStackCount(attackNeed)
                print("Stacks restored to: " .. self:GetStackCount())
            else
                print("attack_need is nil!")
            end
        end
    end
end


function modifier_axe_counter_helix_custom_lua:PlayEffects()
    local caster = self:GetCaster()

    local fx = ParticleManager:CreateParticle("particles/econ/items/axe/axe_weapon_bloodchaser/axe_attack_blur_counterhelix_bloodchaser.vpcf", PATTACH_ABSORIGIN, caster) -- рекамендую использовать данный партикл
    ParticleManager:SetParticleControl(fx, 0, caster:GetAbsOrigin())
    ParticleManager:SetParticleControl(fx, 1, Vector(self.radius,self.radius,self.radius)) -- то что отвечает за радиус(Не увеличивается от радиусе стандарт 300)
    ParticleManager:ReleaseParticleIndex(fx)

    local fx2 = ParticleManager:CreateParticle("particles/econ/items/axe/ti9_jungle_axe/ti9_jungle_axe_attack_blur_counterhelix_leaves.vpcf", PATTACH_ABSORIGIN, caster) -- рекамендую использовать данный партикл
    ParticleManager:SetParticleControl(fx2, 0, caster:GetAbsOrigin())
    ParticleManager:SetParticleControl(fx2, 1, Vector(self.radius,self.radius,self.radius)) -- то что отвечает за радиус(Не увеличивается от радиусе стандарт 300)
    ParticleManager:ReleaseParticleIndex(fx2)
    
    caster:StartGesture(ACT_DOTA_CAST_ABILITY_3)
    -- Проигрываем звук (если нужно)
    EmitSoundOn("Hero_Axe.CounterHelix", caster)
end

function modifier_axe_counter_helix_custom_lua:DealDamage()
    local caster = self:GetCaster()
    local ability = self:GetAbility()
    local strength = caster:GetStrength()
    local damage_per_str = ability:GetSpecialValueFor("damage_per_str")
    local damage = (strength * damage_per_str) / 100 -- Расчитываем урон от силы. Преобразуем целое число в процент.
    local base_damage = ability:GetSpecialValueFor("base_damage") -- Базовый урон
    local multy_damage = damage + base_damage
    local radius = ability:GetSpecialValueFor("radius") -- Радиус

    -- Находим врагов в радиусе
    local targets = FindUnitsInRadius(
        caster:GetTeamNumber(),
        caster:GetAbsOrigin(),
        nil,
        radius,
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_ANY_ORDER,
        false
    )

    -- Наносим урон всем врагам в радиусе
    for _, enemy in pairs(targets) do
        if enemy:IsHero() then self:AddStack(enemy, caster) end -- если крутилка сработала на героев, то добавляем силу себе и отнимаем силу врагу.
        ApplyDamage({
            victim = enemy,
            attacker = caster,
            damage = multy_damage,
            damage_type = DAMAGE_TYPE_PURE,
            ability = ability
        })
        SendOverheadEventMessage(nil, OVERHEAD_ALERT_CRITICAL, enemy, multy_damage, nil)
    end

    _G.counter = _G.counter + 1 -- когда срабатывает то увеличиваем число глобальной переменной на +1
    ability:StartCooldown(ability:GetSpecialValueFor("AbilityCooldown"))
end

function modifier_axe_counter_helix_custom_lua:AddStack(enemy, caster)
    for _ = 1, self.steal_str do
        local buf = caster:AddNewModifier(caster, self:GetAbility(), "modifier_axe_counter_helix_custom_lua_buff", {duration = self.duration})
        buf:SetDuration(self.duration, true)
    end

    if not enemy:IsAlive() then return end
    for _ = 1, self.steal_str do
        local deb = enemy:AddNewModifier(caster, self:GetAbility(), "modifier_axe_counter_helix_custom_lua_debuff", {duration = self.duration})
        deb:SetDuration(self.duration, true)
    end
end


modifier_axe_counter_helix_custom_lua_buff = class({
    IsHidden = function(self) return self:GetStackCount() == 0 end,
    IsPurgable = function(self) return false end,
    IsDebuff = function(self) return false end,
    IsBuff = function(self) return true end,
    RemoveOnDeath = function(self) return true end,
    DeclareFunctions = function(self) return
        {
            MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
            MODIFIER_PROPERTY_TOOLTIP,
        } end,
})

function modifier_axe_counter_helix_custom_lua_buff:OnCreated()
    self.ability = self:GetAbility()
    self.bonus_str = self.ability:GetSpecialValueFor("steal_str")
end

function modifier_axe_counter_helix_custom_lua_buff:OnRefresh()
    self:IncrementStackCount()
end

function modifier_axe_counter_helix_custom_lua_buff:GetModifierBonusStats_Strength()
    return self:GetStackCount()
end

function modifier_axe_counter_helix_custom_lua_buff:OnTooltip()
    return self:GetModifierBonusStats_Strength()
end

modifier_axe_counter_helix_custom_lua_debuff = class({
    IsHidden = function(self) return false end,
    IsPurgable = function(self) return true end,
    IsDebuff = function(self) return true end,
    IsBuff = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    DeclareFunctions = function(self) return
        {
            MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
            MODIFIER_PROPERTY_TOOLTIP,
        } end,
})

function modifier_axe_counter_helix_custom_lua_debuff:OnCreated()
    local ability = self:GetAbility()
    self.steal_str_debuff = ability:GetSpecialValueFor("steal_str")
end

function modifier_axe_counter_helix_custom_lua_debuff:OnRefresh(params)
    self:IncrementStackCount()
end

function modifier_axe_counter_helix_custom_lua_debuff:GetModifierBonusStats_Strength()
    return -self:GetStackCount()
end

function modifier_axe_counter_helix_custom_lua_debuff:OnTooltip()
    return self:GetModifierBonusStats_Strength()
end