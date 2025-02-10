LinkLuaModifier("modifier_item_shivasguard_custom", "items/item_shivasguard", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_shivasguard_custom_slow", "items/item_shivasguard", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_shivasguard_custom_debuff", "items/item_shivasguard", LUA_MODIFIER_MOTION_NONE)

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
	local radius = 0
	local units = {}
	Timers:CreateTimer(0, function()
		if radius < blast_radius then
			radius = radius + blast_speed * 0.03

			-- Обеспечение обзора
			self:CreateVisibilityNode(caster:GetAbsOrigin(), vision_radius, vision_duration)

			-- Поиск врагов в текущем радиусе
			local enemies = FindUnitsInRadius(
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

			for _, enemy in ipairs(enemies) do
				if not units[enemy:entindex()] then
					units[enemy:entindex()] = true
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
					enemy:AddNewModifier(caster, self, "modifier_item_shivasguard_custom_slow", {duration = slow_duration * (1 - enemy:GetStatusResistance())})
				end
			end
			return 0.03  -- повторяет таймер каждые 0.03 сек до достижения радиуса
		else
			return nil  -- остановка таймера
		end
	end)
end

modifier_item_shivasguard_custom = class({})

function modifier_item_shivasguard_custom:IsHidden()
    return true
end
function modifier_item_shivasguard_custom:IsPurgable() return false end
function modifier_item_shivasguard_custom:IsPermanent() return true end

function modifier_item_shivasguard_custom:IsAura()
    return true
end

function modifier_item_shivasguard_custom:GetModifierAura()
    return "modifier_item_shivasguard_custom_debuff"
end

function modifier_item_shivasguard_custom:GetAuraRadius()
    return self:GetAbility():GetSpecialValueFor("aura_radius")
end

function modifier_item_shivasguard_custom:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_item_shivasguard_custom:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_item_shivasguard_custom:GetAuraSearchFlags()
    return DOTA_UNIT_TARGET_FLAG_NONE
end

 
function modifier_item_shivasguard_custom:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_shivasguard_custom:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
    }
end

function modifier_item_shivasguard_custom:OnCreated()
    local ability = self:GetAbility()
    self.bonusIntellect = ability:GetSpecialValueFor("bonus_intellect")
    self.bonusArmor = ability:GetSpecialValueFor("bonus_armor")
    self.bonusHpRegen = ability:GetSpecialValueFor("bonus_hp_regen")
end

function modifier_item_shivasguard_custom:OnRefresh()
    self:OnCreated()
end

function modifier_item_shivasguard_custom:GetModifierBonusStats_Intellect()
    return self.bonusIntellect
end

function modifier_item_shivasguard_custom:GetModifierPhysicalArmorBonus()
    return self.bonusArmor
end

function modifier_item_shivasguard_custom:GetModifierConstantHealthRegen()
    return self.bonusHpRegen
end



modifier_item_shivasguard_custom_slow = modifier_item_shivasguard_custom_slow or class({})
function modifier_item_shivasguard_custom_slow:IsHidden() return false end
function modifier_item_shivasguard_custom_slow:IsDebuff() return true end
function modifier_item_shivasguard_custom_slow:OnCreated() self:OnRefresh() end
function modifier_item_shivasguard_custom_slow:OnRefresh()
    self.slow_movement_speed = self:GetAbility():GetSpecialValueFor("slow_movement_speed")
end
function modifier_item_shivasguard_custom_slow:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    }
end
function modifier_item_shivasguard_custom_slow:GetModifierMoveSpeedBonus_Percentage() return self.slow_movement_speed end


modifier_item_shivasguard_custom_debuff = modifier_item_shivasguard_custom_debuff or class({})
function modifier_item_shivasguard_custom_debuff:IsHidden() return false end
function modifier_item_shivasguard_custom_debuff:IsDebuff() return true end
function modifier_item_shivasguard_custom_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
        MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_SOURCE,
    }
end
function modifier_item_shivasguard_custom_debuff:GetModifierAttackSpeedBonus_Constant()
	if self:GetAbility() then return self:GetAbility():GetSpecialValueFor("aura_attack_speed") end
end
function modifier_item_shivasguard_custom_debuff:GetModifierHPRegenAmplify_Percentage()
	if self:GetAbility() then return self:GetAbility():GetSpecialValueFor("aura_heal_percent") end
end
function modifier_item_shivasguard_custom_debuff:GetModifierHealAmplify_PercentageSource()
	if self:GetAbility() then return self:GetAbility():GetSpecialValueFor("aura_heal_percent") end
end