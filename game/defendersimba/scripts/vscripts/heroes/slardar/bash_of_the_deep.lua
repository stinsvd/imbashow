----------------------
-- Bash of the Deep --
----------------------
LinkLuaModifier("modifier_slrdr_bash_of_the_deep", "heroes/slardar/bash_of_the_deep", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_slrdr_bash_of_the_deep_bash", "heroes/slardar/bash_of_the_deep", LUA_MODIFIER_MOTION_NONE)


slrdr_bash_of_the_deep = slrdr_bash_of_the_deep or class({})
function slrdr_bash_of_the_deep:Precache(context)
	PrecacheResource("particle", "particles/generic_gameplay/generic_stunned.vpcf", context)
end
function slrdr_bash_of_the_deep:GetIntrinsicModifierName() return "modifier_slrdr_bash_of_the_deep" end


modifier_slrdr_bash_of_the_deep = modifier_slrdr_bash_of_the_deep or class({})
function modifier_slrdr_bash_of_the_deep:IsHidden() return false end
function modifier_slrdr_bash_of_the_deep:OnCreated()
	if IsServer() then if not self:GetAbility() then self:Destroy() end end
	local attack_count = self:GetParent():HasModifier("modifier_slrdr_seaborn_sentinel_river") and self:GetAbility():GetSpecialValueFor("river_attack_count") or self:GetAbility():GetSpecialValueFor("attack_count")
	self:SetStackCount(attack_count)
end
function modifier_slrdr_bash_of_the_deep:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_PHYSICAL,
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
	}
end
function modifier_slrdr_bash_of_the_deep:GetModifierProcAttack_BonusDamage_Physical(keys)
	if not IsServer() then return end
	local target = keys.target
	local owner = self:GetParent()
	
	if not target then return end
	if target.GetUnitName == nil then return end
	if owner:IsIllusion() then return end
	if owner:PassivesDisabled() then return end
	if not self:GetAbility():IsCooldownReady() then return end
	if target:GetTeamNumber() == owner:GetTeamNumber() then return end
	if target:IsOther() then return end
	if target:IsBuilding() then return end
--	if target:HasModifier("modifier_slrdr_bash_of_the_deep_bash") then return end
	
	self:DecrementStackCount()
	
	if self:GetStackCount() == 0 then
		local duration = self:GetAbility():GetSpecialValueFor("duration")
		local bonus_damage = self:GetAbility():GetSpecialValueFor("bonus_damage")
		if owner.GetStrength and owner:GetStrength() > 0 then
			bonus_damage = bonus_damage + (owner:GetStrength() * self:GetAbility():GetSpecialValueFor("bonus_damage_str_pct") / 100)
		end
		local attack_count = owner:HasModifier("modifier_slrdr_seaborn_sentinel_river") and self:GetAbility():GetSpecialValueFor("river_attack_count") or self:GetAbility():GetSpecialValueFor("attack_count")
		local river_aoe = self:GetAbility():GetSpecialValueFor("river_aoe")
		
		self:SetStackCount(attack_count)
		
		target:EmitSound("Hero_Slardar.Bash")
		
		local damageTable = {
			victim = nil,
			attacker = owner,
			ability = self:GetAbility(),
			damage = bonus_damage,
			damage_type = DAMAGE_TYPE_PHYSICAL,
		}
		if owner:HasModifier("modifier_slrdr_guardian_sprint") and owner:HasModifier("modifier_slrdr_seaborn_sentinel_river") then
			local enemies = FindUnitsInRadius(owner:GetTeamNumber(), target:GetAbsOrigin(), nil, river_aoe, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HEROES_AND_CREEPS, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
			for i = 1, #enemies do
				enemies[i]:AddNewModifier(owner, self:GetAbility(), "modifier_slrdr_bash_of_the_deep_bash", {duration = duration * (1 - enemies[i]:GetStatusResistance())})
				
				damageTable.victim = enemies[i]
				ApplyDamage(damageTable)
			end
		else
			target:AddNewModifier(owner, self:GetAbility(), "modifier_slrdr_bash_of_the_deep_bash", {duration = duration * (1 - target:GetStatusResistance())})
			
			damageTable.victim = target
			ApplyDamage(damageTable)
		end
	end
end
function modifier_slrdr_bash_of_the_deep:GetModifierPreAttack_BonusDamage()
	local owner = self:GetParent()
	if owner:PassivesDisabled() then return end
	if owner:HasModifier("modifier_slrdr_seaborn_sentinel_river") then
		return self:GetAbility():GetSpecialValueFor("river_damage")
	end
end

-- Bash of the Deep Bash
modifier_slrdr_bash_of_the_deep_bash = modifier_slrdr_bash_of_the_deep_bash or class({})
function modifier_slrdr_bash_of_the_deep_bash:IsHidden() return false end
function modifier_slrdr_bash_of_the_deep_bash:IsStunDebuff() return true end
function modifier_slrdr_bash_of_the_deep_bash:IsPurgeException() return true end
function modifier_slrdr_bash_of_the_deep_bash:GetEffectName() return "particles/generic_gameplay/generic_stunned.vpcf" end
function modifier_slrdr_bash_of_the_deep_bash:GetEffectAttachType() return PATTACH_OVERHEAD_FOLLOW end
function modifier_slrdr_bash_of_the_deep_bash:CheckState()
	if not self:GetParent():IsDebuffImmune() then
		return {[MODIFIER_STATE_STUNNED] = true}
	end
end
function modifier_slrdr_bash_of_the_deep_bash:DeclareFunctions()
	if not self:GetParent():IsDebuffImmune() then
		return {MODIFIER_PROPERTY_OVERRIDE_ANIMATION}
	end
end
function modifier_slrdr_bash_of_the_deep_bash:GetOverrideAnimation() return ACT_DOTA_DISABLED end
