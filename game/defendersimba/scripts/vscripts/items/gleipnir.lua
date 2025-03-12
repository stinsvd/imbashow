-----------------
-- Rod of Atos --
-----------------
LinkLuaModifier("modifier_rod_of_atos_cus", "items/gleipnir", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_rod_of_atos_cus_debuff", "items/gleipnir", LUA_MODIFIER_MOTION_NONE)

item_rod_of_atos_cus = item_rod_of_atos_cus or class({})
function item_rod_of_atos_cus:GetIntrinsicModifierName() return "modifier_rod_of_atos_cus" end
function item_rod_of_atos_cus:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	
	caster:EmitSound("DOTA_Item.RodOfAtos.Cast")
	
	local projectile = {
		Target = target,
		Source = caster,
		Ability = self,
		EffectName = "particles/items2_fx/rod_of_atos_attack.vpcf",
		iMoveSpeed = 1900,
		vSourceLoc = caster:GetAbsOrigin(),
		bDrawsOnMinimap = false,
		bDodgeable = true,
		bIsAttack = false,
		bVisibleToEnemies = true,
		bReplaceExisting = false,
		flExpireTime = GameRules:GetGameTime() + 20,
		bProvidesVision = false,
	}
	
	ProjectileManager:CreateTrackingProjectile(projectile)
end
function item_rod_of_atos_cus:OnProjectileHit(target, loc)
	if not IsServer() then return end
	if not target then return end
	if target:IsMagicImmune() then return end
	local caster = self:GetCaster()
	
	target:EmitSound("DOTA_Item.RodOfAtos.Target")
	
	local duration = self:GetSpecialValueFor("duration")
	target:AddNewModifier(caster, self, "modifier_rod_of_atos_cus_debuff", {duration = duration * (1 - target:GetStatusResistance())})
end

modifier_rod_of_atos_cus = class({})
function modifier_rod_of_atos_cus:IsHidden() return true end
function modifier_rod_of_atos_cus:IsPurgable() return false end
function modifier_rod_of_atos_cus:IsPermanent() return true end
function modifier_rod_of_atos_cus:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end
function modifier_rod_of_atos_cus:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_HEALTH_BONUS,
	}
end
function modifier_rod_of_atos_cus:GetModifierBonusStats_Intellect()
	if self:GetAbility() then return self:GetAbility():GetSpecialValueFor("bonus_intellect") end
end
function modifier_rod_of_atos_cus:GetModifierHealthBonus()
	if self:GetAbility() then return self:GetAbility():GetSpecialValueFor("bonus_hp") end
end

-- Rod of Atos Debuff
modifier_rod_of_atos_cus_debuff = modifier_rod_of_atos_cus_debuff or class({})
function modifier_rod_of_atos_cus_debuff:IsHidden() return false end
function modifier_rod_of_atos_cus_debuff:IsDebuff() return true end
function modifier_rod_of_atos_cus_debuff:IsPurgable() return true end
function modifier_rod_of_atos_cus_debuff:GetEffectName() return self.effect end
function modifier_rod_of_atos_cus_debuff:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end
function modifier_rod_of_atos_cus_debuff:OnCreated() self:OnRefresh() end
function modifier_rod_of_atos_cus_debuff:OnRefresh()
	self.effect = "particles/items2_fx/rod_of_atos.vpcf"
	if self:GetAbility():GetAbilityName() == "item_gleipnir" then
		self.effect = "particles/items3_fx/gleipnir_root.vpcf"
	end
end
function modifier_rod_of_atos_cus_debuff:CheckState()
	if not self:GetParent():IsDebuffImmune() then
		return {[MODIFIER_STATE_ROOTED] = true}
	end
end



--------------
-- Gleipnir --
--------------
LinkLuaModifier("modifier_gleipnir", "items/gleipnir", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_orcl_fortunes_end_pull", "heroes/oracle/fortunes_end", LUA_MODIFIER_MOTION_HORIZONTAL)

item_gleipnir = item_gleipnir or class({})
function item_gleipnir:GetIntrinsicModifierName() return "modifier_gleipnir" end
function item_gleipnir:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end
function item_gleipnir:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local caster_pos = caster:GetAbsOrigin()
	self.target_pos = self:GetCursorPosition()
	local radius = self:GetSpecialValueFor("radius")
	
	caster:EmitSound("Item.Gleipnir.Cast")
	
	local projectile = {
		Target = nil,
		Source = caster,
		Ability = self,
		EffectName = "particles/items3_fx/gleipnir_projectile.vpcf",
		iMoveSpeed = 1900,
		vSourceLoc = caster_pos,
		bDrawsOnMinimap = false,
		bDodgeable = true,
		bIsAttack = false,
		bVisibleToEnemies = true,
		bReplaceExisting = false,
		flExpireTime = GameRules:GetGameTime() + 20,
		bProvidesVision = false,
	}
	
	local enemies = FindUnitsInRadius(caster:GetTeamNumber(), self.target_pos, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HEROES_AND_CREEPS, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	
	for _, enemy in pairs(enemies) do
		projectile.Target = enemy
		ProjectileManager:CreateTrackingProjectile(projectile)
	end
end
function item_gleipnir:OnProjectileHit(target, loc)
	if not IsServer() then return end
	if not target then return end
	if target:IsMagicImmune() then return end
	local caster = self:GetCaster()
	local duration = self:GetSpecialValueFor("duration")
	
	target:EmitSound("Item.Gleipnir.Target")
	
	if not target:IsDebuffImmune() then
		target:AddNewModifier(caster, self, "modifier_orcl_fortunes_end_pull", {duration = math.min(duration, 0.5) * (1 - target:GetStatusResistance()), pull_speed = 300, x = self.target_pos.x, y = self.target_pos.y})
	end
	target:AddNewModifier(caster, self, "modifier_rod_of_atos_cus_debuff", {duration = duration * (1 - target:GetStatusResistance())})
end

modifier_gleipnir = modifier_gleipnir or class({})
function modifier_gleipnir:IsHidden() return true end
function modifier_gleipnir:IsPurgable() return false end
function modifier_gleipnir:IsPermanent() return true end
function modifier_gleipnir:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end
function modifier_gleipnir:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_HEALTH_BONUS,
		MODIFIER_PROPERTY_MANA_BONUS,
	}
end
function modifier_gleipnir:GetModifierBonusStats_Intellect()
	if self:GetAbility() then return self:GetAbility():GetSpecialValueFor("bonus_intellect") end
end
function modifier_gleipnir:GetModifierHealthBonus()
	if self:GetAbility() then return self:GetAbility():GetSpecialValueFor("bonus_hp") end
end
function modifier_gleipnir:GetModifierManaBonus()
	if self:GetAbility() then return self:GetAbility():GetSpecialValueFor("bonus_mana") end
end
