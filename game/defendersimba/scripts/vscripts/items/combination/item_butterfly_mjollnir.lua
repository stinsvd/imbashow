LinkLuaModifier("modifier_item_butterfly_mjollnir", "items/combination/item_butterfly_mjollnir", LUA_MODIFIER_MOTION_NONE)

item_butterfly_mjollnir = class({})

function item_butterfly_mjollnir:GetIntrinsicModifierName()
    return "modifier_item_butterfly_mjollnir"
end

modifier_item_butterfly_mjollnir = class({})

function modifier_item_butterfly_mjollnir:IsHidden()
    return true
end

function modifier_item_butterfly_mjollnir:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end
 
function modifier_item_butterfly_mjollnir:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_PROPERTY_EVASION_CONSTANT,
        MODIFIER_EVENT_ON_ATTACK_LANDED,
    }
    return funcs
end

function modifier_item_butterfly_mjollnir:OnCreated()
    local ability = self:GetAbility()

    self.bonus_agility = ability:GetSpecialValueFor("bonus_agility")
    self.bonus_attack_speed = ability:GetSpecialValueFor("bonus_attack_speed")
    self.bonus_damage = ability:GetSpecialValueFor("bonus_damage")
    self.bonus_evasion = ability:GetSpecialValueFor("bonus_evasion")
    self.lightningChance = ability:GetSpecialValueFor("lightning_chance")
    self.lightningDamage = ability:GetSpecialValueFor("lightning_damage")
    self.lightningRadius = ability:GetSpecialValueFor("lightning_radius")
    self.mkbDamageChance = ability:GetSpecialValueFor("mkb_damage_chance")
    self.mkbBonusDamage = ability:GetSpecialValueFor("mkb_bonus_damage")
end

function modifier_item_butterfly_mjollnir:OnRefresh()
    self:OnCreated()
end

function modifier_item_butterfly_mjollnir:GetModifierBonusStats_Agility()
    return self.bonus_agility
end

function modifier_item_butterfly_mjollnir:GetModifierAttackSpeedBonus_Constant()
    return self.bonus_attack_speed
end

function modifier_item_butterfly_mjollnir:GetModifierPreAttack_BonusDamage()
    return self.bonus_damage
end

function modifier_item_butterfly_mjollnir:GetModifierEvasion_Constant()
    return self.bonus_evasion
end


function modifier_item_butterfly_mjollnir:OnAttackLanded(event)
    local parent = self:GetParent()

    if event.attacker == parent then
        -- Шанс на нанесение молнии
        if RandomInt(1, 100) <= self.lightningChance then
            local enemies = FindUnitsInRadius(
                parent:GetTeamNumber(),
                event.target:GetAbsOrigin(),
                nil,
                self.lightningRadius,
                DOTA_UNIT_TARGET_TEAM_ENEMY,
                DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
                DOTA_UNIT_TARGET_FLAG_NONE,
                FIND_ANY_ORDER,
                false
            )

            for _, enemy in pairs(enemies) do
                ApplyDamage({
                    victim = enemy,
                    attacker = parent,
                    damage = self.lightningDamage,
                    damage_type = DAMAGE_TYPE_MAGICAL,
                    ability = self:GetAbility(),
                })
                
                -- Создаём анимацию молнии для каждого поражённого врага
                local particle = ParticleManager:CreateParticle("particles/items_fx/chain_lightning.vpcf", PATTACH_POINT_FOLLOW, parent)
                ParticleManager:SetParticleControlEnt(particle, 0, parent, PATTACH_POINT_FOLLOW, "attach_attack1", parent:GetAbsOrigin(), true)
                ParticleManager:SetParticleControlEnt(particle, 1, enemy, PATTACH_POINT_FOLLOW, "attach_hitloc", enemy:GetAbsOrigin(), true)
                ParticleManager:ReleaseParticleIndex(particle)
            end
        end

        -- Шанс на дополнительный урон от item_monkey_king_bar
        if RandomInt(1, 100) <= self.mkbDamageChance then
            ApplyDamage({
                victim = event.target,
                attacker = parent,
                damage = self.mkbBonusDamage,
                damage_type = DAMAGE_TYPE_MAGICAL,
                ability = self:GetAbility(),
            })

            -- Визуализация "фиолетовых чисел" для mkb_bonus_damage
            SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, event.target, self.mkbBonusDamage, nil)
        end
    end
end
