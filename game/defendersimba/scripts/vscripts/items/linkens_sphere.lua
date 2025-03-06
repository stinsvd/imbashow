---------------------
-- Linken's Sphere --
---------------------
LinkLuaModifier("modifier_linkens_sphere_cus", "items/linkens_sphere", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_linkens_sphere_cus_buff", "items/linkens_sphere", LUA_MODIFIER_MOTION_NONE)


item_linkens_sphere_cus = item_linkens_sphere_cus or class({})
function item_linkens_sphere_cus:Precache(context)
	PrecacheResource("particle", "particles/items_fx/immunity_sphere.vpcf", context)
	PrecacheResource("particle", "particles/items_fx/immunity_sphere_buff.vpcf", context)
end
function item_linkens_sphere_cus:GetCooldown(lvl)
	return self:GetSpecialValueFor("block_cooldown")
end
function item_linkens_sphere_cus:GetIntrinsicModifierName() return "modifier_linkens_sphere_cus" end
function item_linkens_sphere_cus:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	
	target:EmitSound("DOTA_Item.LinkensSphere.Target")
	target:AddNewModifier(caster, self, "modifier_linkens_sphere_cus_buff", {duration = self:GetSpecialValueFor("block_duration")})
end

item_linkens_sphere_2_cus = item_linkens_sphere_cus
item_linkens_sphere_3_cus = item_linkens_sphere_cus
item_linkens_sphere_4_cus = item_linkens_sphere_cus
item_linkens_sphere_5_cus = item_linkens_sphere_cus
item_linkens_sphere_6_cus = item_linkens_sphere_cus


modifier_linkens_sphere_cus = modifier_linkens_sphere_cus or class({})
function modifier_linkens_sphere_cus:IsHidden() return true end
function modifier_linkens_sphere_cus:IsPurgable() return false end
function modifier_linkens_sphere_cus:IsPermanent() return true end
function modifier_linkens_sphere_cus:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end
function modifier_linkens_sphere_cus:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
		MODIFIER_PROPERTY_ABSORB_SPELL,
	}
end
function modifier_linkens_sphere_cus:GetModifierBonusStats_Strength()
	if self:GetAbility() then return self:GetAbility():GetSpecialValueFor("bonus_all_stats") end
end
function modifier_linkens_sphere_cus:GetModifierBonusStats_Agility()
	if self:GetAbility() then return self:GetAbility():GetSpecialValueFor("bonus_all_stats") end
end
function modifier_linkens_sphere_cus:GetModifierBonusStats_Intellect()
	if self:GetAbility() then return self:GetAbility():GetSpecialValueFor("bonus_all_stats") end
end
function modifier_linkens_sphere_cus:GetModifierConstantHealthRegen()
	if self:GetAbility() then return self:GetAbility():GetSpecialValueFor("bonus_health_regen") end
end
function modifier_linkens_sphere_cus:GetModifierConstantManaRegen()
	if self:GetAbility() then return self:GetAbility():GetSpecialValueFor("bonus_mana_regen") end
end
function modifier_linkens_sphere_cus:GetAbsorbSpell(params)
	if not IsServer() then return end
	if not self:GetAbility():IsCooldownReady() then return end
	local owner = self:GetParent()
	local target = params.ability:GetCaster()
	if target:GetTeamNumber() == self:GetParent():GetTeamNumber() then return end

	local proc_pfx = ParticleManager:CreateParticle("particles/items_fx/immunity_sphere.vpcf", PATTACH_CENTER_FOLLOW, self:GetCaster())
	ParticleManager:SetParticleControlEnt(proc_pfx, 0, owner, PATTACH_CENTER_FOLLOW, nil, owner:GetAbsOrigin(), true)
	ParticleManager:ReleaseParticleIndex(proc_pfx)

	self:GetAbility():UseResources(false, false, false, true)
	owner:EmitSound("DOTA_Item.LinkensSphere.Activate")
	return 1
end


modifier_linkens_sphere_cus_buff = modifier_linkens_sphere_cus_buff or class({})
function modifier_linkens_sphere_cus_buff:IsHidden() return false end
function modifier_linkens_sphere_cus_buff:IsPurgable() return false end
function modifier_linkens_sphere_cus_buff:RemoveOnDeath() return false end
function modifier_linkens_sphere_cus_buff:OnCreated()
	if not IsServer() then return end
	local buff_pfx = ParticleManager:CreateParticle("particles/items_fx/immunity_sphere_buff.vpcf", PATTACH_CENTER_FOLLOW, self:GetCaster())
	ParticleManager:SetParticleControlEnt(buff_pfx, 0, self:GetParent(), PATTACH_CENTER_FOLLOW, nil, self:GetParent():GetAbsOrigin(), true)
	self:AddParticle(buff_pfx, false, false, -1, false, false)
end
function modifier_linkens_sphere_cus_buff:OnIntervalThink()
	if not IsServer() then return end
	self:Destroy()
end
function modifier_linkens_sphere_cus_buff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ABSORB_SPELL,
	}
end
function modifier_linkens_sphere_cus_buff:GetAbsorbSpell(params)
	if not IsServer() then return end
	local owner = self:GetParent()
	local target = params.ability:GetCaster()
	if target:GetTeamNumber() == self:GetParent():GetTeamNumber() then return end

	owner:EmitSound("DOTA_Item.LinkensSphere.Activate")
	self:StartIntervalThink(FrameTime())
	return 1
end
