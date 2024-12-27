bristleback_quill_spray_custom = class({})
LinkLuaModifier( "modifier_bristleback_quill_spray_custom", "heroes/bristleback/bristleback_quill_spray_custom", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_bristleback_quill_spray_custom_stack", "heroes/bristleback/bristleback_quill_spray_custom", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_bristleback_quill_spray_custom_armor", "heroes/bristleback/bristleback_quill_spray_custom", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------

function bristleback_quill_spray_custom:MakeSpray( count, hairball )
    local caster = self:GetCaster()

	local radius = self:GetSpecialValueFor("radius")
	local stack_damage = caster:GetStrength() * self:GetSpecialValueFor("quill_str_stack_damage") / 100
	local base_damage = caster:GetStrength() * self:GetSpecialValueFor("quill_str_base_damage") / 100
	local stack_duration = self:GetSpecialValueFor("duration")

    local source = caster
    if hairball then source = hairball end

    if not hairball then
        caster:FadeGesture(ACT_DOTA_CAST_ABILITY_2)
        caster:StartGesture(ACT_DOTA_CAST_ABILITY_2)
    end

    local enemies = FindUnitsInRadius(
		self:GetCaster():GetTeamNumber(),
		source:GetAbsOrigin(),
		nil,
		radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		0,
		false
	)

    local damage_table = {
		attacker = caster,
		damage_type = DAMAGE_TYPE_PHYSICAL,
		ability = self
	}

    for i = 1, count, 1 do
        for _, enemy in pairs(enemies) do
            local stack = 0
            local modifier = enemy:FindModifierByNameAndCaster( "modifier_bristleback_quill_spray_custom", caster )
            if modifier ~= nil then
                stack = modifier:GetStackCount()
            end

            damage_table.victim = enemy

            damage_table.damage = base_damage + stack * stack_damage
            self:ApplyDamage( damage_table )

            local goo = caster:FindAbilityByName("bristleback_viscous_nasal_goo_custom")
            if goo and goo:IsTrained() then
                local goo_stack = 0
                local goo_damage = goo:GetSpecialValueFor("spray_bonus_damage")

                local goo_modifier = enemy:FindModifierByNameAndCaster( "modifier_bristleback_viscous_nasal_goo_custom", caster )
                if goo_modifier ~= nil then
                    goo_stack = goo_modifier:GetStackCount()
                end

                damage_table.damage = goo_damage * goo_stack
                self:ApplyDamage( damage_table )
            end

            enemy:AddNewModifier(
                caster,
                self,
                "modifier_bristleback_quill_spray_custom",
                {
                    duration = stack_duration * ( 1 - enemy:GetStatusResistance() )
                }
            )

            self:PlayEffects2( enemy )
        end

        self:PlayEffects1( source )
    end
end

function bristleback_quill_spray_custom:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function bristleback_quill_spray_custom:OnSpellStart()
    self:MakeSpray(1, nil)
end

function bristleback_quill_spray_custom:PlayEffects1( source )
    local caster = self:GetCaster()

	local particle_cast = ParticleManager:GetParticleReplacement("particles/units/heroes/hero_bristleback/bristleback_quill_spray.vpcf", caster)

    local pattach = PATTACH_ABSORIGIN
    if source ~= caster then pattach = PATTACH_WORLDORIGIN end

	local effect_cast = ParticleManager:CreateParticle( particle_cast, pattach, source )
    ParticleManager:SetParticleControl(effect_cast, 0, source:GetOrigin())
	ParticleManager:ReleaseParticleIndex( effect_cast )

	source:EmitSound("Hero_Bristleback.QuillSpray.Cast")
end

function bristleback_quill_spray_custom:PlayEffects2( target )
    local caster = self:GetCaster()

	local particle_cast = ParticleManager:GetParticleReplacement("particles/units/heroes/hero_bristleback/bristleback_quill_spray_impact.vpcf", caster)

	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN, target )
	ParticleManager:ReleaseParticleIndex( effect_cast )

    target:EmitSound("Hero_Bristleback.QuillSpray.Target")
end

function bristleback_quill_spray_custom:ApplyDamage( damage_table )
	local victim = damage_table.victim

	if victim:IsCreep() then
		victim:AddNewModifier(
			damage_table.attacker,
			self,
			"modifier_bristleback_quill_spray_custom_armor",
			{}
		)
	end

	ApplyDamage( damage_table )

	if victim:IsCreep() then
		victim:RemoveModifierByName("modifier_bristleback_quill_spray_custom_armor")
	end
end

--------------------------------------------------------------------------------

modifier_bristleback_quill_spray_custom = class({})

function modifier_bristleback_quill_spray_custom:IsHidden() return false end
function modifier_bristleback_quill_spray_custom:IsDebuff() return true end
function modifier_bristleback_quill_spray_custom:IsPurgable() return false end
function modifier_bristleback_quill_spray_custom:DestroyOnExpire() return false end

function modifier_bristleback_quill_spray_custom:OnCreated( kv )
	if IsServer() then
		self:GetParent():AddNewModifier(
			self:GetCaster(),
			self:GetAbility(),
			"modifier_bristleback_quill_spray_custom_stack",
			{
				duration = kv.duration
			}
		)

		self:SetStackCount( 1 )
	end
end

function modifier_bristleback_quill_spray_custom:OnRefresh( kv )
	if IsServer() then
		self:GetParent():AddNewModifier(
			self:GetCaster(),
			self:GetAbility(),
			"modifier_bristleback_quill_spray_custom_stack",
			{
				duration = kv.duration
			}
		)

		self:IncrementStackCount()
	end
end

function modifier_bristleback_quill_spray_custom:RemoveStack()
	self:DecrementStackCount()
	if self:GetStackCount() < 1 then
		self:Destroy()
	end
end

function modifier_bristleback_quill_spray_custom:GetEffectName()
	return "particles/units/heroes/hero_bristleback/bristleback_quill_spray_hit_creep.vpcf"
end

function modifier_bristleback_quill_spray_custom:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

--------------------------------------------------------------------------------

modifier_bristleback_quill_spray_custom_stack = class({})

function modifier_bristleback_quill_spray_custom_stack:IsHidden() return true end
function modifier_bristleback_quill_spray_custom_stack:IsPurgable() return false end
function modifier_bristleback_quill_spray_custom_stack:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_bristleback_quill_spray_custom_stack:OnDestroy( kv )
	if IsServer() then
		local modifier = self:GetParent():FindModifierByName("modifier_bristleback_quill_spray_custom")
        if modifier then
            modifier:RemoveStack()
        end
	end
end

--------------------------------------------------------------------------------

modifier_bristleback_quill_spray_custom_armor = class({})

function modifier_bristleback_quill_spray_custom_armor:IsHidden() return true end
function modifier_bristleback_quill_spray_custom_armor:IsPurgable() return false end

function modifier_bristleback_quill_spray_custom_armor:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
	}
end

function modifier_bristleback_quill_spray_custom_armor:GetModifierPhysicalArmorBonus()
	if not IsServer() then return end
	if self.armor_lock then return end

	self.armor_lock = true
	local armor = self:GetParent():GetPhysicalArmorValue(false)
	self.armor_lock = false

	local pierce = self:GetAbility():GetSpecialValueFor("creep_armor_pierce")
	return -(armor * pierce / 100)
end
