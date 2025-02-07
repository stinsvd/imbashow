LinkLuaModifier("modifier_item_radiance_custom", "items/item_radiance_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_radiance_custom_aura", "items/item_radiance_custom", LUA_MODIFIER_MOTION_NONE)

item_radiance_custom_1 = class({})
item_radiance_custom_2 = item_radiance_custom_1
item_radiance_custom_3 = item_radiance_custom_1
item_radiance_custom_4 = item_radiance_custom_1
item_radiance_custom_5 = item_radiance_custom_1
item_radiance_custom_6 = item_radiance_custom_1

function item_radiance_custom_1:GetIntrinsicModifierName()
    return "modifier_item_radiance_custom"
end

modifier_item_radiance_custom = class({})

function modifier_item_radiance_custom:IsHidden()
    return true
end

function modifier_item_radiance_custom:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_radiance_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
    }
    return funcs
end

function modifier_item_radiance_custom:OnCreated()
    local ability = self:GetAbility()
    self.bonus_strength = ability:GetSpecialValueFor("bonus_strength")
    self.bonus_agility = ability:GetSpecialValueFor("bonus_agility")
    self.bonus_intellect = ability:GetSpecialValueFor("bonus_intellect")
    self.bonus_damage = ability:GetSpecialValueFor("bonus_damage")
    self.radius = ability:GetSpecialValueFor("aura_radius")
    self.burn_damage = ability:GetSpecialValueFor("aura_damage")

    if IsServer() then
        -- Создаем частицу ауры
        local particle = ParticleManager:CreateParticle("particles/items_fx/radiance.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
        ParticleManager:SetParticleControl(particle, 1, Vector(self.radius, 0, 0)) -- Устанавливаем радиус частицы
        self:AddParticle(particle, false, false, -1, false, false) -- Привязываем частицу к модификатору

        self:StartIntervalThink(1.0)  -- Аура будет наносить урон каждую секунду
    end
end

function modifier_item_radiance_custom:GetModifierBonusStats_Strength()
    return self.bonus_strength
end

function modifier_item_radiance_custom:GetModifierBonusStats_Agility()
    return self.bonus_agility
end

function modifier_item_radiance_custom:GetModifierBonusStats_Intellect()
    return self.bonus_intellect
end

function modifier_item_radiance_custom:GetModifierPreAttack_BonusDamage()
    return self.bonus_damage
end

function modifier_item_radiance_custom:OnIntervalThink()
	if not IsServer() then return end
	if not self:GetAbility() then return end
    local parent = self:GetParent()
    local level = self:GetAbility():GetLevel()
    local other_modifiers = parent:FindAllModifiersByName(self:GetName())
    for _, modifier in pairs(other_modifiers) do
        if modifier ~= self and modifier:GetAbility():GetLevel() > level then
            return
        end
    end
	
    local enemies = FindUnitsInRadius(
        parent:GetTeamNumber(),
        parent:GetAbsOrigin(),
        nil,
        self.radius,
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
            damage = self.burn_damage,
            damage_type = DAMAGE_TYPE_MAGICAL,
            ability = self:GetAbility()
        })
    end
end
