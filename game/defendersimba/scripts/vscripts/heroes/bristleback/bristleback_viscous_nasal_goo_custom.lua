bristleback_viscous_nasal_goo_custom = class({})
LinkLuaModifier( "modifier_bristleback_viscous_nasal_goo_custom", "heroes/bristleback/bristleback_viscous_nasal_goo_custom", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------

function bristleback_viscous_nasal_goo_custom:MakeGoo( count, hairball )
    local caster = self:GetCaster()

    local projectile_name = ParticleManager:GetParticleReplacement("particles/units/heroes/hero_bristleback/bristleback_viscous_nasal_goo.vpcf", caster)
    local projectile_speed = self:GetSpecialValueFor("goo_speed")

    local radius = self:GetSpecialValueFor("radius")

    local source = caster
    if hairball then source = hairball end

    local attach = DOTA_PROJECTILE_ATTACHMENT_ATTACK_3
    if hairball then attach = DOTA_PROJECTILE_ATTACHMENT_HITLOCATION end

    local projectile_info = {
		Source = source,
		Ability = self,
		EffectName = projectile_name,
		iMoveSpeed = projectile_speed,
        iSourceAttachment = attach,
        ExtraData = {
            count = count
        }
    }

    local enemies = FindUnitsInRadius(
        caster:GetTeamNumber(),
        source:GetOrigin(),
        nil,
        radius,
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        DOTA_UNIT_TARGET_FLAG_NO_INVIS + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE,
        0,
        false
    )

    for _, enemy in pairs(enemies) do
        projectile_info.Target = enemy
        ProjectileManager:CreateTrackingProjectile( projectile_info )
    end

    caster:EmitSound("Hero_Bristleback.ViscousGoo.Cast")
end

function bristleback_viscous_nasal_goo_custom:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function bristleback_viscous_nasal_goo_custom:OnSpellStart()
    self:MakeGoo(1)
end

function bristleback_viscous_nasal_goo_custom:OnProjectileHit_ExtraData( target, location, data )
    local caster = self:GetCaster()

    if target == nil or target:IsInvulnerable() then return end

	local duration = self:GetSpecialValueFor("duration")

    for i = 1, data.count, 1 do
        if target:TriggerSpellAbsorb( self ) then goto continue end

        target:AddNewModifier(
            caster,
            self,
            "modifier_bristleback_viscous_nasal_goo_custom",
            {
                duration = duration * ( 1 - target:GetStatusResistance() )
            }
        )

        target:EmitSound("Hero_Bristleback.ViscousGoo.Target")
        ::continue::
    end
end

--------------------------------------------------------------------------------

modifier_bristleback_viscous_nasal_goo_custom = class({})

function modifier_bristleback_viscous_nasal_goo_custom:IsHidden() return false end
function modifier_bristleback_viscous_nasal_goo_custom:IsDebuff() return true end
function modifier_bristleback_viscous_nasal_goo_custom:IsStunDebuff() return false end
function modifier_bristleback_viscous_nasal_goo_custom:IsPurgable() return true end

function modifier_bristleback_viscous_nasal_goo_custom:OnCreated( kv )
	self.armor_stack = self:GetAbility():GetSpecialValueFor( "armor_per_stack" )

	if IsServer() then
		self:SetStackCount(1)
	end
end

function modifier_bristleback_viscous_nasal_goo_custom:OnRefresh( kv )
	self.armor_stack = self:GetAbility():GetSpecialValueFor( "armor_per_stack" )
	local max_stack = self:GetAbility():GetSpecialValueFor( "stack_limit" )

	if IsServer() then
		if self:GetStackCount() < max_stack then
			self:IncrementStackCount()
		end
	end
end

function modifier_bristleback_viscous_nasal_goo_custom:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
	}
end

function modifier_bristleback_viscous_nasal_goo_custom:GetModifierPhysicalArmorBonus()
	return -(self.armor_stack * self:GetStackCount())
end

function modifier_bristleback_viscous_nasal_goo_custom:GetEffectName()
	return "particles/units/heroes/hero_bristleback/bristleback_viscous_nasal_goo_debuff.vpcf"
end

function modifier_bristleback_viscous_nasal_goo_custom:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end
