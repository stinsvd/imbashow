LinkLuaModifier("modifier_item_ethereal_blade_custom", "items/item_ethereal_blade_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_ethereal_blade_custom_ethereal", "items/item_ethereal_blade_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_ethereal_blade_custom_cooldown", "items/item_ethereal_blade_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_ethereal_blade_custom_phylacteria", "items/item_ethereal_blade_custom", LUA_MODIFIER_MOTION_NONE)
 

item_ethereal_blade_1 = class({})
 
function item_ethereal_blade_1:GetIntrinsicModifierName()
	return "modifier_item_ethereal_blade_custom"
end
 
function item_ethereal_blade_1:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	
 	local duration					=	self:GetSpecialValueFor("duration")
 	local projectile_speed			=	self:GetSpecialValueFor("projectile_speed")
 	
	local target = self:GetCursorTarget()
 
    caster:EmitSound("DOTA_Item.EtherealBlade.Activate")

    local projectile = {
        Target 				= target,
        Source 				= caster,
        Ability 			= self,
        EffectName 			= "particles/items_fx/ethereal_blade.vpcf",
        iMoveSpeed			= projectile_speed,
        vSourceLoc 			= self:GetCaster(),
        bDrawsOnMinimap 	= false,
        bDodgeable 			= true,
        bIsAttack 			= false,
        bVisibleToEnemies 	= true,
        bReplaceExisting 	= false,
        flExpireTime 		= GameRules:GetGameTime() + 20,
        bProvidesVision 	= false,
    }
    
    ProjectileManager:CreateTrackingProjectile(projectile)
end

function item_ethereal_blade_1:OnProjectileHit(target, location)	
	if target and not target:IsMagicImmune() then
        local caster = self:GetCaster()

		if target:TriggerSpellAbsorb(self) then return nil end
		
		target:EmitSound("DOTA_Item.EtherealBlade.Target")
        local duration = self:GetSpecialValueFor("duration")
        local blast_agility_multiplier	=	self:GetSpecialValueFor("blast_agility_multiplier")
        local blast_damage_base	=	self:GetSpecialValueFor("blast_damage_base")

		if target:GetTeam() == caster:GetTeam() then
			target:AddNewModifier(caster, self, "modifier_item_ethereal_blade_custom_ethereal", {duration = duration})
		else
			target:AddNewModifier(caster, self, "modifier_item_ethereal_blade_custom_ethereal", {duration = duration * (1 - target:GetStatusResistance())})
						
			local damageTable = {
				victim 			= target,
				damage 			= caster:GetPrimaryStatValue() * blast_agility_multiplier + blast_damage_base,
				damage_type		= DAMAGE_TYPE_MAGICAL,
				damage_flags 	= DOTA_DAMAGE_FLAG_NONE,
				attacker 		= caster,
				ability 		= self
			}
									
			ApplyDamage(damageTable)		
		end
	end
end

modifier_item_ethereal_blade_custom_ethereal = class({})

function modifier_item_ethereal_blade_custom_ethereal:IsHidden()
	return false
end

function modifier_item_ethereal_blade_custom_ethereal:GetStatusEffectName()
	return "particles/status_fx/status_effect_ghost.vpcf"
end

function modifier_item_ethereal_blade_custom_ethereal:StatusEffectPriority()
    return MODIFIER_PRIORITY_SUPER_ULTRA
  end

function modifier_item_ethereal_blade_custom_ethereal:OnCreated()
	self.ability					= self:GetAbility()
	self.caster						= self:GetCaster()
	self.parent						= self:GetParent()
	
	self.ethereal_damage_bonus		= self.ability:GetSpecialValueFor("ethereal_damage_bonus")
	self.blast_movement_slow				=	self:GetAbility():GetSpecialValueFor("blast_movement_slow")

	self:StartIntervalThink(FrameTime())
end

function modifier_item_ethereal_blade_custom_ethereal:OnRefresh()
	self:OnCreated()
end

function modifier_item_ethereal_blade_custom_ethereal:CheckState()
	local state = {
		[MODIFIER_STATE_ATTACK_IMMUNE] = true,
		[MODIFIER_STATE_DISARMED] = true
	}
	
	return state
end

function modifier_item_ethereal_blade_custom_ethereal:DeclareFunctions()
    local decFuncs = {
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_DECREPIFY_UNIQUE,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,		  
    }
	
	return decFuncs
end

function modifier_item_ethereal_blade_custom_ethereal:GetModifierMoveSpeedBonus_Percentage()
    if self:GetParent():GetTeamNumber() ~= self:GetCaster():GetTeamNumber() then 
        return self.blast_movement_slow
    end
end
 
function modifier_item_ethereal_blade_custom_ethereal:GetModifierMagicalResistanceDecrepifyUnique()
    return self.ethereal_damage_bonus
end

function modifier_item_ethereal_blade_custom_ethereal:GetAbsoluteNoDamagePhysical()
	return 1
end

modifier_item_ethereal_blade_custom = class({})
 
function modifier_item_ethereal_blade_custom:IsHidden()		return true end
function modifier_item_ethereal_blade_custom:IsPurgable()		return false end
function modifier_item_ethereal_blade_custom:RemoveOnDeath()	return false end
function modifier_item_ethereal_blade_custom:GetAttributes()	return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_item_ethereal_blade_custom:DeclareFunctions()
    return {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
        MODIFIER_PROPERTY_HEALTH_BONUS,
        MODIFIER_PROPERTY_MANA_BONUS,
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
        MODIFIER_EVENT_ON_SPELL_TARGET_READY,
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE ,
    }
end

function modifier_item_ethereal_blade_custom:OnCreated()
    local ability = self:GetAbility()
    self.bonusStrength = ability:GetSpecialValueFor("bonus_strength")
    self.bonusAgility = ability:GetSpecialValueFor("bonus_agility")
    self.bonusIntellect = ability:GetSpecialValueFor("bonus_intellect")
    self.bonusManaRegen = ability:GetSpecialValueFor("bonus_mana_regen")

    self.bonusHealth = ability:GetSpecialValueFor("bonus_health")
    self.bonusMana = ability:GetSpecialValueFor("bonus_mana")

    self.bonusDamage = ability:GetSpecialValueFor("bonus_damage")
    self.critChance = ability:GetSpecialValueFor("crit_chance")
    self.critMultiplier = ability:GetSpecialValueFor("crit_multiplier")

    self.magicalCritChance = self:GetAbility():GetSpecialValueFor("magical_crit_chance")
    self.magicalCritMultiplier = self:GetAbility():GetSpecialValueFor("magical_crit_multiplier")
end
 
function modifier_item_ethereal_blade_custom:GetModifierConstantManaRegen()
	return self.bonusManaRegen
end

function modifier_item_ethereal_blade_custom:GetModifierBonusStats_Strength()
	return self.bonusStrength
end

function modifier_item_ethereal_blade_custom:GetModifierBonusStats_Agility()
	return self.bonusAgility
end

function modifier_item_ethereal_blade_custom:GetModifierBonusStats_Intellect()
	return self.bonusIntellect
end

function modifier_item_ethereal_blade_custom:GetModifierHealthBonus()
	return self.bonusHealth
end

function modifier_item_ethereal_blade_custom:GetModifierManaBonus()
	return self.bonusMana
end

function modifier_item_ethereal_blade_custom:GetModifierPreAttack_BonusDamage()
	return self.bonusDamage
end

function modifier_item_ethereal_blade_custom:GetModifierPreAttack_CriticalStrike()
    if RollPercentage(self.critChance) then
        return self.critMultiplier
    end
end

function modifier_item_ethereal_blade_custom:OnSpellTargetReady(params)
	if not IsServer() then return end
	if params.unit ~= self:GetParent() then return end
    if params.ability:IsItem() then return end
	if params.unit:GetTeamNumber() == params.target:GetTeamNumber() then return end

    local parent = self:GetParent()

    if parent:HasModifier("modifier_item_ethereal_blade_custom_cooldown") then return end

    local target = params.target or params.unit

    local damage = self:GetAbility():GetSpecialValueFor("bonus_spell_damage")
    local damageCrit = self:GetAbility():GetSpecialValueFor("spell_crit_multiplier")

    if damageCrit then 
        damage = damage + parent:GetAverageTrueAttackDamage(nil) * (damageCrit/100)
    end

    SendOverheadEventMessage(target, 4, target, damage, nil)

    params.unit:AddNewModifier(parent, self:GetAbility(), "modifier_item_ethereal_blade_custom_cooldown", {duration = self:GetAbility():GetSpecialValueFor("cooldown_phylacrery")})
    ApplyDamage({attacker = self:GetCaster(), victim = target, ability = self:GetAbility(), damage = damage, damage_type = DAMAGE_TYPE_MAGICAL})
    target:AddNewModifier(parent, self:GetAbility(), "modifier_item_ethereal_blade_custom_phylacteria", {duration = self:GetAbility():GetSpecialValueFor("slow_duration")})

    local particle = ParticleManager:CreateParticle("particles/items_fx/phylactery_target.vpcf", PATTACH_ABSORIGIN_FOLLOW, params.unit)
    ParticleManager:SetParticleControlEnt(particle, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
    ParticleManager:ReleaseParticleIndex(particle)

    local particle_2 = ParticleManager:CreateParticle("particles/items_fx/phylactery.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
    ParticleManager:SetParticleControlEnt(particle_2, 0, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(particle_2, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
    ParticleManager:ReleaseParticleIndex(particle_2)

    target:EmitSound("Item.Phylactery.Target")
end

function modifier_item_ethereal_blade_custom:GetModifierTotalDamageOutgoing_Percentage(event)
    local parent = self:GetParent()
    local attacker = event.attacker
  
    if (
    attacker == self:GetParent() and
    event.damage_category == DOTA_DAMAGE_CATEGORY_SPELL  and
    bit.band(event.damage_flags, DOTA_DAMAGE_FLAG_REFLECTION) ~= DOTA_DAMAGE_FLAG_REFLECTION and 
    RollPercentage(self.magicalCritChance)
    ) then 

        local damage = event.original_damage * (self.magicalCritMultiplier / 100)
        local particle = ParticleManager:CreateParticle("particles/msg_fx/msg_crit.vpcf", PATTACH_OVERHEAD_FOLLOW, event.target)
        ParticleManager:SetParticleControl(particle, 1, Vector(9,damage,4))
		ParticleManager:SetParticleControl(particle, 2, Vector(1, 4, 0))
        ParticleManager:SetParticleControl(particle, 3, Vector(19,26,600))
        ParticleManager:ReleaseParticleIndex(particle)

        return self.magicalCritMultiplier - 100
    end
end

modifier_item_ethereal_blade_custom_cooldown = class({})

function modifier_item_ethereal_blade_custom_cooldown:IsHidden()
    return false
end

function modifier_item_ethereal_blade_custom_cooldown:RemoveOnDeath()
    return false
end

function modifier_item_ethereal_blade_custom_cooldown:IsPurgable()
    return false
end

function modifier_item_ethereal_blade_custom_cooldown:IsPurgeException()
    return false
end


modifier_item_ethereal_blade_custom_phylacteria = class({
    GetModifierMoveSpeedBonus_Percentage = function (self) return self:GetAbility():GetSpecialValueFor("slow_phylacrery") end,
    DeclareFunctions = function (self)
        return
        {
            MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        }
    end
})