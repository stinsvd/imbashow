bristleback_hairball_custom = class({})
LinkLuaModifier( "modifier_bristleback_hairball_custom_unit", "heroes/bristleback/bristleback_hairball_custom", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------

function bristleback_hairball_custom:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function bristleback_hairball_custom:OnSpellStart()
    local caster = self:GetCaster()
    local position = self:GetCursorPosition()
    local speed = self:GetSpecialValueFor("projectile_speed")

    caster:EmitSound("Hero_Bristleback.Hairball.Cast")

    local projectile = {
        Ability = self,
        EffectName = "particles/units/heroes/hero_bristleback/bristleback_hairball.vpcf",
        vSpawnOrigin = caster:GetAttachmentOrigin(caster:ScriptLookupAttachment("attach_hitloc")),
        fDistance = (position - caster:GetAbsOrigin()):Length2D(),
        fStartRadius = 0,
        fEndRadius = 0,
        Source = caster,
        bHasFrontalCone = false,
        bReplaceExisting = false,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_NONE,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_NONE,
        fExpireTime = GameRules:GetGameTime() + 5.0,
        bDeleteOnHit = false,
        vVelocity = (position - caster:GetAbsOrigin()):Normalized() * speed * Vector(1, 1, 0),
        bProvidesVision = false
    }

    ProjectileManager:CreateLinearProjectile(projectile)
end

function bristleback_hairball_custom:OnProjectileHit(hTarget, vLocation)
    local caster = self:GetCaster()
    local radius = self:GetSpecialValueFor("radius")

    if not IsServer() then return end

    AddFOWViewer(caster:GetTeamNumber(), vLocation, radius, 2, false)

    local spray = caster:FindAbilityByName("bristleback_quill_spray_custom")
    local goo = caster:FindAbilityByName("bristleback_viscous_nasal_goo_custom")

    local dummy = nil
    if spray or goo then
        dummy = CreateUnitByName("npc_dota_templar_assassin_psionic_trap", vLocation, false, caster, caster, caster:GetTeamNumber())
        dummy:AddNewModifier(
            dummy,
            self,
            "modifier_bristleback_hairball_custom_unit",
            {
                duration = 1
            }
        )
    end

    if spray and spray:IsTrained() then
        local count = self:GetSpecialValueFor("quill_stacks")
        spray:MakeSpray( count, dummy )
    end

    if goo and goo:IsTrained() then
        local count = self:GetSpecialValueFor("goo_stacks")
        goo:MakeGoo( count, dummy )
    end
end

---------------------------------------------------------------------------------

modifier_bristleback_hairball_custom_unit = class({})

function modifier_bristleback_hairball_custom_unit:IsHidden() return true end
function modifier_bristleback_hairball_custom_unit:IsPurgable() return false end

function modifier_bristleback_hairball_custom_unit:CheckState()
    return {
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_OUT_OF_GAME] = true,
        [MODIFIER_STATE_STUNNED] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true
    }
end


function modifier_bristleback_hairball_custom_unit:OnCreated()
    if IsServer() then
        self:GetParent():AddNoDraw()
    end
end

function modifier_bristleback_hairball_custom_unit:OnDestroy()
    if IsServer() then
        UTIL_Remove(self:GetParent())
    end
end