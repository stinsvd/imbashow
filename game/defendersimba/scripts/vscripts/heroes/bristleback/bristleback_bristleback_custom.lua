bristleback_bristleback_custom = class({})
LinkLuaModifier( "modifier_bristleback_bristleback_custom", "heroes/bristleback/bristleback_bristleback_custom", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_bristleback_bristleback_custom_damage", "heroes/bristleback/bristleback_bristleback_custom", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_bristleback_bristleback_custom_active", "heroes/bristleback/bristleback_bristleback_custom", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_bristleback_bristleback_custom_spray", "heroes/bristleback/bristleback_bristleback_custom", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_bristleback_bristleback_custom_taunt", "heroes/bristleback/bristleback_bristleback_custom", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------

function bristleback_bristleback_custom:IsFacingBack( attacker )
    if attacker:IsBuilding() then return false end

    local forwardVector = self:GetCaster():GetForwardVector()
    local forwardAngle = math.deg(math.atan2(forwardVector.x, forwardVector.y))

    local reverseEnemyVector = (self:GetCaster():GetAbsOrigin() - attacker:GetAbsOrigin()):Normalized()
    local reverseEnemyAngle = math.deg(math.atan2(reverseEnemyVector.x, reverseEnemyVector.y))

    local back_angle = self:GetSpecialValueFor("back_angle")

    local difference = math.abs(forwardAngle - reverseEnemyAngle)

    if (difference <= back_angle) or (difference >= (360 - back_angle)) then
        return true
    end

    return false
end

--------------------------------------------------------------------------------

function bristleback_bristleback_custom:GetBehavior()
    if self:GetCaster():HasScepter() then
        return DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_IMMEDIATE
    end

    return DOTA_ABILITY_BEHAVIOR_PASSIVE
end

function bristleback_bristleback_custom:GetAOERadius()
    return self:GetSpecialValueFor("taunt_radius")
end

function bristleback_bristleback_custom:GetIntrinsicModifierName()
    return "modifier_bristleback_bristleback_custom"
end

function bristleback_bristleback_custom:OnSpellStart()
    local caster = self:GetCaster()

    if not caster:HasScepter() then return end

    local mod = caster:FindModifierByName("modifier_bristleback_bristleback_custom")

    if mod:GetStackCount() == 0 then return end

    caster:StartGesture(ACT_DOTA_CAST_ABILITY_3)
    caster:EmitSound("Hero_Bristleback.Bristleback.Active")

    local interval = self:GetSpecialValueFor("spray_interval")

    caster:AddNewModifier(
        caster,
        self,
        "modifier_bristleback_bristleback_custom_active",
        {}
    ):SetStackCount(mod:GetStackCount())

    mod:SetStackCount(0)

    local enemies = FindUnitsInRadius(
        caster:GetTeamNumber(),
        caster:GetAbsOrigin(),
        nil,
        self:GetSpecialValueFor("taunt_radius"),
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
        0,
        false
    )

    local taunt_duration = self:GetSpecialValueFor("taunt_duration")

    for _, enemy in pairs(enemies) do
        enemy:AddNewModifier(
            caster,
            self,
            "modifier_bristleback_bristleback_custom_taunt",
            {
                duration = taunt_duration * (1 - enemy:GetStatusResistance())
            }
        )
    end
end

--------------------------------------------------------------------------------

modifier_bristleback_bristleback_custom = class({})

function modifier_bristleback_bristleback_custom:IsHidden() return self:GetStackCount() == 0 end

function modifier_bristleback_bristleback_custom:OnCreated()
    local parent = self:GetParent()

    if IsServer() then
        self:StartIntervalThink(FrameTime())

        parent:AddNewModifier(
            parent,
            self:GetAbility(),
            "modifier_bristleback_bristleback_custom_damage",
            {}
        )
    end
end

function modifier_bristleback_bristleback_custom:OnIntervalThink()
    if self:GetStackCount() > 0 and not self:GetCaster():HasScepter() then
        self:SetStackCount(0)
    end

    if self:GetCaster():HasScepter() then
        self:GetAbility():SetActivated( self:GetStackCount() > 0 )
    else
        self:GetAbility():SetActivated( true )
    end
end

function modifier_bristleback_bristleback_custom:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,

        MODIFIER_EVENT_ON_TAKEDAMAGE,
        MODIFIER_EVENT_ON_ABILITY_FULLY_CAST
    }
end

function modifier_bristleback_bristleback_custom:GetModifierIncomingDamage_Percentage( params )
    local parent = self:GetParent()

    if not IsServer() then return end
    if parent:PassivesDisabled() then return end
    if bit.band(params.damage_flags, DOTA_DAMAGE_FLAG_REFLECTION) == DOTA_DAMAGE_FLAG_REFLECTION then return end
    if bit.band(params.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) == DOTA_DAMAGE_FLAG_HPLOSS then return end

    local side_angle = self:GetAbility():GetSpecialValueFor("side_angle")
    local back_angle = self:GetAbility():GetSpecialValueFor("back_angle")

    local forwardVector = parent:GetForwardVector()
    local forwardAngle = math.deg(math.atan2(forwardVector.x, forwardVector.y))

    local reverseEnemyVector = (parent:GetAbsOrigin() - params.attacker:GetAbsOrigin()):Normalized()
    local reverseEnemyAngle = math.deg(math.atan2(reverseEnemyVector.x, reverseEnemyVector.y))

    local difference = math.abs(forwardAngle - reverseEnemyAngle)

    local side_damage_reduction = self:GetAbility():GetSpecialValueFor("side_damage_reduction")
    local back_damage_reduction = self:GetAbility():GetSpecialValueFor("back_damage_reduction")

    if (difference <= back_angle) or (difference >= (360 - back_angle)) then
        local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_bristleback/bristleback_back_dmg.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
        ParticleManager:SetParticleControl(particle, 1, parent:GetAbsOrigin())
        ParticleManager:SetParticleControlEnt(particle, 1, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
        ParticleManager:ReleaseParticleIndex(particle)

        local particle2 = ParticleManager:CreateParticle("particles/units/heroes/hero_bristleback/bristleback_back_lrg_dmg.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
        ParticleManager:SetParticleControlEnt(particle2, 1, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
        ParticleManager:ReleaseParticleIndex(particle2)

        parent:EmitSound("Hero_Bristleback.Bristleback")

        return back_damage_reduction * (-1)
    elseif (difference <= (side_angle)) or (difference >= (360 - (side_angle))) then
        local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_bristleback/bristleback_back_dmg.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
        ParticleManager:SetParticleControl(particle, 1, parent:GetAbsOrigin())
        ParticleManager:SetParticleControlEnt(particle, 1, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
        ParticleManager:ReleaseParticleIndex(particle)

        return side_damage_reduction * (-1)
    end

    return 0
end

function modifier_bristleback_bristleback_custom:OnTakeDamage( params )
    local parent = self:GetParent()

    if params.attacker == nil then return end
    if params.unit ~= parent then return end
    if parent:PassivesDisabled() then return end
    if bit.band(params.damage_flags, DOTA_DAMAGE_FLAG_REFLECTION) == DOTA_DAMAGE_FLAG_REFLECTION then return end
    if bit.band(params.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) == DOTA_DAMAGE_FLAG_HPLOSS then return end
    if not parent:HasAbility("bristleback_quill_spray_custom") then return end
    if not parent:FindAbilityByName("bristleback_quill_spray_custom"):IsTrained() then return end

    if self:GetAbility():IsFacingBack(params.attacker) then
        self:Spray(params.damage)
    end
end

function modifier_bristleback_bristleback_custom:Spray( damage )
    local parent = self:GetParent()

    local mod = parent:FindModifierByName("modifier_bristleback_bristleback_custom_damage")
    if not mod then return end

    local quill_release_threshold = self:GetAbility():GetSpecialValueFor("quill_release_threshold")

    local final = mod:GetStackCount() + damage

    if final >= quill_release_threshold then
        local delta = math.floor(final / quill_release_threshold)

        for i = 1, delta do
            parent:AddNewModifier(
                parent,
                self:GetAbility(),
                "modifier_bristleback_bristleback_custom_spray",
                {}
            )
        end

        mod:SetStackCount(final - delta * quill_release_threshold)
    else
        mod:SetStackCount(final)
    end
end

function modifier_bristleback_bristleback_custom:AddStack()
    local max_stacks = self:GetAbility():GetSpecialValueFor("max_stacks")
    if self:GetStackCount() < max_stacks then
        self:IncrementStackCount()
    end
end

function modifier_bristleback_bristleback_custom:OnAbilityFullyCast( params )
    if not params.ability then return end
    if params.unit ~= self:GetParent() then return end
    if params.ability:GetName() ~= "bristleback_quill_spray_custom" then return end

    self:AddStack()
end

------------------------------------------------------------------

modifier_bristleback_bristleback_custom_damage = class({})
function modifier_bristleback_bristleback_custom_damage:IsHidden() return true end
function modifier_bristleback_bristleback_custom_damage:IsPurgable() return false end
function modifier_bristleback_bristleback_custom_damage:RemoveOnDeath() return false end
function modifier_bristleback_bristleback_custom_damage:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT end

------------------------------------------------------------------

modifier_bristleback_bristleback_custom_spray = class({})
function modifier_bristleback_bristleback_custom_spray:IsHidden() return true end
function modifier_bristleback_bristleback_custom_spray:IsPurgable() return false end

function modifier_bristleback_bristleback_custom_spray:OnCreated(table)
    if not IsServer() then return end

    self:SetStackCount(1)
    self:Proc()

    self:StartIntervalThink( self:GetAbility():GetSpecialValueFor("spray_interval") )
end

function modifier_bristleback_bristleback_custom_spray:OnRefresh(table)
    if IsServer() then self:IncrementStackCount() end
end

function modifier_bristleback_bristleback_custom_spray:OnIntervalThink()
    if not IsServer() then return end

    self:Proc()

    if self:GetStackCount() == 0 then
        self:Destroy()
    end
end

function modifier_bristleback_bristleback_custom_spray:Proc()
    if not IsServer() then return end
    if self:GetStackCount() == 0 then return end

    self:DecrementStackCount()

    local caster = self:GetCaster()
    local spray = caster:FindAbilityByName("bristleback_quill_spray_custom")

    if spray and spray:IsTrained() then
        spray:MakeSpray( 1, nil )

        local mod = caster:FindModifierByName("modifier_bristleback_warpath_custom")
        if mod then
            mod:AddStack()
        end

        self:AddStack()
    end
end

------------------------------------------------------------------

modifier_bristleback_bristleback_custom_active = class({})

function modifier_bristleback_bristleback_custom_active:IsHidden() return true end

function modifier_bristleback_bristleback_custom_active:OnCreated()
    self.delay = true

    if IsServer() then self:StartIntervalThink( self:GetAbility():GetSpecialValueFor("delay") ) end
end

function modifier_bristleback_bristleback_custom_active:OnIntervalThink()
    if self.delay then
        self.delay = false

        self:StartIntervalThink( self:GetAbility():GetSpecialValueFor("spray_interval") )
        return
    end

    local caster = self:GetCaster()
    local spray = caster:FindAbilityByName("bristleback_quill_spray_custom")

    if spray and spray:IsTrained() then
        spray:MakeSpray( 1, nil )

        local mod = caster:FindModifierByName("modifier_bristleback_warpath_custom")
        if mod then
            mod:AddStack()
        end
    end

    self:DecrementStackCount()

    if self:GetStackCount() == 0 then
        self:Destroy()
    end
end

------------------------------------------------------------------

modifier_bristleback_bristleback_custom_taunt = class({})

function modifier_bristleback_bristleback_custom_taunt:IsHidden() return true end
function modifier_bristleback_bristleback_custom_taunt:IsPurgable() return false end

function modifier_bristleback_bristleback_custom_taunt:OnCreated( kv )
  if not IsServer() then return end

  self.parent = self:GetParent()
  self.caster = self:GetCaster()

  self.parent:Stop()
  self.parent:Interrupt()

    if not self.parent:IsCreep() then
        self.parent:MoveToTargetToAttack( self.caster )
        self.parent:MoveToPositionAggressive( self.caster:GetAbsOrigin() )
        self.parent:SetForceAttackTarget( self.caster )
    end

    self:StartIntervalThink(FrameTime())
end

function modifier_bristleback_bristleback_custom_taunt:OnIntervalThink()
    if not IsServer() then return end

    if not self.caster or self.caster:IsNull() or not self.caster:IsAlive() then
        self:Destroy()
    end
end

function modifier_bristleback_bristleback_custom_taunt:OnDestroy()
    if not IsServer() then return end

    if not self.parent:IsCreep() then
        self.parent:SetForceAttackTarget( nil )
    end
end

function modifier_bristleback_bristleback_custom_taunt:CheckState()
    return {
        [MODIFIER_STATE_TAUNTED] = true,
    }
end

function modifier_bristleback_bristleback_custom_taunt:GetStatusEffectName()
    return "particles/status_fx/status_effect_beserkers_call.vpcf"
end