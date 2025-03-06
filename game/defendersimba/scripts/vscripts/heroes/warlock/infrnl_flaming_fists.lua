-------------------
-- Flaming Fists --
-------------------
LinkLuaModifier("modifier_infrnl_flaming_fists", "heroes/warlock/infrnl_flaming_fists", LUA_MODIFIER_MOTION_NONE)

infrnl_flaming_fists = infrnl_flaming_fists or class({})
function infrnl_flaming_fists:Precache(context)
	PrecacheResource("particle", "particles/units/heroes/hero_doom_bringer/doom_bringer_lvl_death.vpcf", context)
end
function infrnl_flaming_fists:GetIntrinsicModifierName() return "modifier_infrnl_flaming_fists" end


modifier_infrnl_flaming_fists = modifier_infrnl_flaming_fists or class({})
function modifier_infrnl_flaming_fists:IsHidden() return true end
function modifier_infrnl_flaming_fists:IsPurgable() return false end
function modifier_infrnl_flaming_fists:OnCreated() self:OnRefresh() end
function modifier_infrnl_flaming_fists:OnRefresh()
	if not IsServer() then return end
	self.damageTable = {
		victim = nil,
		attacker = self:GetCaster(),
		ability = self:GetAbility(),
		damage = nil,
		damage_type = DAMAGE_TYPE_MAGICAL,
	}
end
function modifier_infrnl_flaming_fists:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end
function modifier_infrnl_flaming_fists:OnAttackLanded(keys)
	if not IsServer() then return end
	local target = keys.target
	if not target then return end
	local attacker = keys.attacker
	if not attacker then return end
	if target:IsBuilding() or target:IsOther() then return end
	if attacker:PassivesDisabled() then return end
	if self:GetParent() == attacker then
		local targetPos = target:GetAbsOrigin()
		local hpleft_damage = self:GetAbility():GetSpecialValueFor("hpleft_damage") / 100
		local damage = (attacker:GetMaxHealth() - attacker:GetHealth()) * hpleft_damage
		
		self.damageTable.damage = damage
		self.damageTable.victim = target
		ApplyDamage(self.damageTable)
		
		local base_damage = self:GetAbility():GetSpecialValueFor("base_damage")
		if base_damage > 0 then
			local hit_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_doom_bringer/doom_bringer_lvl_death.vpcf", PATTACH_ABSORIGIN_FOLLOW, attacker)
			ParticleManager:SetParticleControlEnt(hit_pfx, 0, target, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), false)
			ParticleManager:ReleaseParticleIndex(hit_pfx)

			local radius = self:GetAbility():GetSpecialValueFor("radius")
			self.damageTable.damage = base_damage + damage
			local enemies = FindUnitsInRadius(attacker:GetTeamNumber(), targetPos, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HEROES_AND_CREEPS, DOTA_UNIT_TARGET_FLAG_NOT_ATTACK_IMMUNE + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
			for _, enemy in pairs(enemies) do
				self.damageTable.victim = enemy
				ApplyDamage(self.damageTable)
			end
		end
	end
end
