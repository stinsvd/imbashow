bristleback_warpath_custom = class({})
LinkLuaModifier( "modifier_bristleback_warpath_custom", "heroes/bristleback/bristleback_warpath_custom", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_bristleback_warpath_custom_buff", "heroes/bristleback/bristleback_warpath_custom", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_bristleback_warpath_custom_stack", "heroes/bristleback/bristleback_warpath_custom", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------

function bristleback_warpath_custom:GetIntrinsicModifierName()
	return "modifier_bristleback_warpath_custom"
end

--------------------------------------------------------------------------------

modifier_bristleback_warpath_custom = class({})

function modifier_bristleback_warpath_custom:IsHidden() return true end
function modifier_bristleback_warpath_custom:IsHidden() return true end

function modifier_bristleback_warpath_custom:DeclareFunctions()
	return {
	 	MODIFIER_EVENT_ON_ABILITY_FULLY_CAST
	}
end

function modifier_bristleback_warpath_custom:OnAbilityFullyCast( params )
	local parent = self:GetParent()

	if not params.ability then return end
	if params.unit ~= parent then return end
	if parent:PassivesDisabled() then return end
	if params.ability:GetName() == "bristleback_bristleback_custom" then return end

	self:AddStack()
end

function modifier_bristleback_warpath_custom:AddStack()
	local parent = self:GetParent()

	if not IsServer() then return end

	local max_stacks = self:GetAbility():GetSpecialValueFor("max_stacks")
	local duration = self:GetAbility():GetSpecialValueFor("duration")

	local mod = parent:AddNewModifier(
		parent,
		self:GetAbility(),
		"modifier_bristleback_warpath_custom_buff",
		{
			duration = duration
		}
	)

	if not mod then return end

	if mod:GetStackCount() < max_stacks then
	 	mod:IncrementStackCount()

	 	parent:AddNewModifier(
			parent,
			self:GetAbility(),
			"modifier_bristleback_warpath_custom_stack",
			{
				duration = duration
			}
		)
	else
		for _, all_stacks in ipairs(parent:FindAllModifiersByName("modifier_bristleback_warpath_custom_stack")) do
			all_stacks:Destroy()

			mod:IncrementStackCount()

			parent:AddNewModifier(
				parent,
				self:GetAbility(),
				"modifier_bristleback_warpath_custom_stack",
				{
					duration = duration
				}
			)

			break
		end
	end

end

--------------------------------------------------------------------------------

modifier_bristleback_warpath_custom_buff = class({})

function modifier_bristleback_warpath_custom_buff:IsHidden() return false end
function modifier_bristleback_warpath_custom_buff:IsPurgable() return false end

function modifier_bristleback_warpath_custom_buff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_TOOLTIP,

		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_MODEL_SCALE
	}
end

function modifier_bristleback_warpath_custom_buff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("move_speed_per_stack") * self:GetStackCount()
end

function modifier_bristleback_warpath_custom_buff:GetModifierBonusStats_Strength()
    local str_ptc = self:GetAbility():GetSpecialValueFor("str_ptc_per_stack") * self:GetStackCount()

	if not IsServer() then return end

	if self.str_lock then return end

	self.str_lock = true
	local str = self:GetCaster():GetStrength()
	self.str_lock = false

	return str_ptc * str / 100
end

function modifier_bristleback_warpath_custom_buff:OnTooltip()
    local str_ptc = self:GetAbility():GetSpecialValueFor("str_ptc_per_stack") * self:GetStackCount()
	local str = self:GetCaster():GetStrength()

	return str_ptc * str / 100
end

function modifier_bristleback_warpath_custom_buff:GetModifierModelScale()
    return self:GetStackCount() * 5
end

--------------------------------------------------------------------------------

modifier_bristleback_warpath_custom_stack = class({})

function modifier_bristleback_warpath_custom_stack:IsHidden() return true end
function modifier_bristleback_warpath_custom_stack:IsPurgable() return false end
function modifier_bristleback_warpath_custom_stack:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_bristleback_warpath_custom_stack:OnCreated( kv )
	if not IsServer() then return end

	local particle_name = ParticleManager:GetParticleReplacement("particles/units/heroes/hero_bristleback/bristleback_warpath.vpcf", self:GetCaster())

	self.particle = ParticleManager:CreateParticle(particle_name, PATTACH_POINT_FOLLOW, self:GetParent())
	ParticleManager:SetParticleControlEnt(self.particle, 3, self:GetCaster(), PATTACH_POINT_FOLLOW, "attach_attack1", self:GetCaster():GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(self.particle, 4, self:GetCaster(), PATTACH_POINT_FOLLOW, "attach_attack2", self:GetCaster():GetAbsOrigin(), true)
	self:AddParticle(self.particle, false, false, -1, false, false)
end

function modifier_bristleback_warpath_custom_stack:OnDestroy()
	if not IsServer() then return end

	local mod = self:GetParent():FindModifierByName("modifier_bristleback_warpath_custom_buff")

	if mod then
		mod:DecrementStackCount()
	end
end

function modifier_bristleback_warpath_custom_stack:GetEffectName()
	return "particles/units/heroes/hero_bristleback/bristleback_warpath_dust.vpcf"
end