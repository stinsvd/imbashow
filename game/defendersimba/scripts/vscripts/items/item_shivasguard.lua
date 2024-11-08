LinkLuaModifier("modifier_item_shivasguard_custom", "items/item_shivasguard", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_shivasguard_custom_slow", "items/item_shivasguard", LUA_MODIFIER_MOTION_NONE)

item_shivasguard_1 = class({})
item_shivasguard_2 = item_shivasguard_1
item_shivasguard_3 = item_shivasguard_1
item_shivasguard_4 = item_shivasguard_1
item_shivasguard_5 = item_shivasguard_1
item_shivasguard_6 = item_shivasguard_1

function item_shivasguard_1:GetIntrinsicModifierName()
    return "modifier_item_shivasguard_custom"
end

function item_shivasguard_1:OnSpellStart()
    local caster = self:GetCaster()
    local blast_radius = self:GetSpecialValueFor("blast_radius")
    local blast_speed = self:GetSpecialValueFor("blast_speed")
    local blast_damage = self:GetSpecialValueFor("blast_damage")
    local slow_duration = self:GetSpecialValueFor("slow_duration")
    local vision_radius = self:GetSpecialValueFor("vision_radius")
    local vision_duration = self:GetSpecialValueFor("vision_duration")
    local slow_movement_speed = self:GetSpecialValueFor("slow_movement_speed")

    -- Создание эффекта волны и звука
    local particle = ParticleManager:CreateParticle("particles/items2_fx/shivas_guard_active.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:SetParticleControl(particle, 1, Vector(blast_radius, blast_radius / blast_speed, blast_speed))
    caster:EmitSound("DOTA_Item.ShivasGuard.Activate")

    -- Установка начального радиуса и таймера
    caster.shivas_guard_current_radius = 0
    Timers:CreateTimer(0, function()
        if caster.shivas_guard_current_radius < blast_radius then
            caster.shivas_guard_current_radius = caster.shivas_guard_current_radius + blast_speed * 0.03

            -- Обеспечение обзора
            self:CreateVisibilityNode(caster:GetAbsOrigin(), vision_radius, vision_duration)

            -- Поиск врагов в текущем радиусе
            local enemies = FindUnitsInRadius(
                caster:GetTeamNumber(),
                caster:GetAbsOrigin(),
                nil,
                caster.shivas_guard_current_radius,
                DOTA_UNIT_TARGET_TEAM_ENEMY,
                DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
                DOTA_UNIT_TARGET_FLAG_NONE,
                FIND_ANY_ORDER,
                false
            )

            for _, enemy in ipairs(enemies) do
                if not enemy:HasModifier("modifier_item_shivasguard_custom_slow") then
                    ApplyDamage({
                        victim = enemy,
                        attacker = caster,
                        damage = blast_damage,
                        damage_type = DAMAGE_TYPE_MAGICAL,
                        ability = self,
                    })
                    
                    -- Эффект удара волны
                    local impact_particle = ParticleManager:CreateParticle("particles/items2_fx/shivas_guard_impact.vpcf", PATTACH_ABSORIGIN_FOLLOW, enemy)
                    ParticleManager:SetParticleControl(impact_particle, 1, enemy:GetAbsOrigin())
                    ParticleManager:ReleaseParticleIndex(impact_particle)

                    -- Применение замедления
                    enemy:AddNewModifier(caster, self, "modifier_item_shivasguard_custom_slow", {duration = slow_duration})
                end
            end
            return 0.03  -- повторяет таймер каждые 0.03 сек до достижения радиуса
        else
            caster.shivas_guard_current_radius = 0
            return nil  -- остановка таймера
        end
    end)
end

modifier_item_shivasguard_custom = class({})

function modifier_item_shivasguard_custom:IsHidden()
    return true
end

function modifier_item_shivasguard_custom:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_shivasguard_custom:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    }
end

function modifier_item_shivasguard_custom:OnCreated()
    local ability = self:GetAbility()
    self.bonusIntellect = ability:GetSpecialValueFor("bonus_intellect")
    self.bonusArmor = ability:GetSpecialValueFor("bonus_armor")
end

function modifier_item_shivasguard_custom:GetModifierBonusStats_Intellect()
    return self.bonusIntellect
end

function modifier_item_shivasguard_custom:GetModifierPhysicalArmorBonus()
    return self.bonusArmor
end

modifier_item_shivasguard_custom_slow = class({})

function modifier_item_shivasguard_custom_slow:IsDebuff()
    return true
end

function modifier_item_shivasguard_custom_slow:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    }
end

function modifier_item_shivasguard_custom_slow:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("slow_movement_speed")
end

function modifier_item_shivasguard_custom_slow:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("aura_attack_speed")
end
