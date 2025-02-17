LinkLuaModifier("modifier_generic_handler", "modifiers/generic", LUA_MODIFIER_MOTION_NONE)

modifier_generic_handler = modifier_generic_handler or class({})
function modifier_generic_handler:IsHidden() return true end
function modifier_generic_handler:IsPurgable() return false end
function modifier_generic_handler:IsPurgeException() return false end
function modifier_generic_handler:RemoveOnDeath() return false end
function modifier_generic_handler:OnCreated()
	if not IsServer() then return end
	self.spellCritExceptions = {
		luna_moon_glaive = true,
		templar_assassin_psi_blades = true,
		orcl_false_promise = true,
	}
	self:OnIntervalThink()
	self:StartIntervalThink(1)
end
function modifier_generic_handler:OnIntervalThink()
	if not IsServer() then return end
	local parent = self:GetParent()
	if parent.CalculateStatBonus ~= nil then
		parent:CalculateStatBonus(false)
	end
end
function modifier_generic_handler:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_DIRECT_MODIFICATION,
		MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
	}
end
function modifier_generic_handler:GetModifierMoveSpeedBonus_Percentage()
	local parent = self:GetParent()
	if parent and parent.GetAgility then
		return parent:GetAgility() * 0.05
	end
end
function modifier_generic_handler:GetModifierMagicalResistanceDirectModification()
	local parent = self:GetParent()
	if parent.GetIntellect then
		return parent:GetIntellect(false) * (0.02 - 0.1)
	end
end
function modifier_generic_handler:CheckForSpellCrit(event)
	local inflictor = event.inflictor
	local damage_flags = event.damage_flags
	if self.spellCritExceptions[inflictor:GetAbilityName()] then return end
	if bit.band(damage_flags, DOTA_DAMAGE_FLAG_REFLECTION) == DOTA_DAMAGE_FLAG_REFLECTION then return end
	if bit.band(damage_flags, DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS) == DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS then return end
end
function modifier_generic_handler:GetModifierTotalDamageOutgoing_Percentage(event)
	if not IsServer() then return end
	local parent = self:GetParent()
	local attacker = event.attacker

	if not attacker then return end
	if attacker ~= self:GetParent() then return end
	if event.damage_category == DOTA_DAMAGE_CATEGORY_SPELL then
		if event.inflictor then
			if not self:CheckForSpellCrit(event) then
				--[[
				if RollPercentage(self.critChance) then
					local damage = event.original_damage * (self.critMultiplier / 100)
					local particle = ParticleManager:CreateParticle("particles/msg_fx/msg_crit.vpcf", PATTACH_OVERHEAD_FOLLOW, event.target)
					ParticleManager:SetParticleControl(particle, 1, Vector(9,damage,4))
					ParticleManager:SetParticleControl(particle, 2, Vector(1, 4, 0))
					ParticleManager:SetParticleControl(particle, 3, Vector(19,26,600))
					ParticleManager:ReleaseParticleIndex(particle)

					return self.critMultiplier - 100
				end
				]]
				
				local index = parent:entindex()
				local critDamage = 0
				local tableIndex = _G._UnitModifiers["CritModifiers"][index]
				if tableIndex then
					if tableIndex then
						local highestCrit = 0
						for i = #tableIndex, 1, -1 do
							local mod = tableIndex[i]
							if mod and not mod:IsNull() and mod.GetModifierSpellCritDamage then
								local crit = mod:GetModifierSpellCritDamage(event) or 0
								if crit > highestCrit then
									highestCrit = crit
								end
							else
								table.remove(tableIndex, i)
							end
						end
						critDamage = highestCrit
					end

					if critDamage > 0 then
						local damage = event.original_damage * (critDamage / 100)
						
						local particle = ParticleManager:CreateParticle("particles/msg_fx/msg_crit.vpcf", PATTACH_OVERHEAD_FOLLOW, event.target)
						ParticleManager:SetParticleControl(particle, 1, Vector(9, event.original_damage + damage ,4))
						ParticleManager:SetParticleControl(particle, 2, Vector(1, 4, 0))
						ParticleManager:SetParticleControl(particle, 3, Vector(19, 26, 600))
						ParticleManager:ReleaseParticleIndex(particle)

						return critDamage
					end
				end
			end
		end
	end
end





LinkLuaModifier("modifier_neutral_boss_cus", "modifiers/generic", LUA_MODIFIER_MOTION_NONE)

modifier_neutral_boss_cus = modifier_neutral_boss_cus or class({})
function modifier_neutral_boss_cus:IsHidden() return true end
function modifier_neutral_boss_cus:IsPurgable() return false end
function modifier_neutral_boss_cus:IsPurgeException() return false end
function modifier_neutral_boss_cus:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PROVIDES_FOW_POSITION,
	}
end
function modifier_neutral_boss_cus:GetModifierProvidesFOWVision() return 1 end





LinkLuaModifier("modifier_invulnerable_cus", "modifiers/generic", LUA_MODIFIER_MOTION_NONE)

modifier_invulnerable_cus = modifier_invulnerable_cus or class({})
function modifier_invulnerable_cus:IsHidden() return true end
function modifier_invulnerable_cus:IsPurgable() return false end
function modifier_invulnerable_cus:IsPurgeException() return false end
function modifier_invulnerable_cus:GetTexture() return "modifier_invulnerable" end
function modifier_invulnerable_cus:GetPriority() return 9999 end
function modifier_invulnerable_cus:OnCreated()
	if self:GetParent():GetUnitName() == "npc_dota_badguys_fort" then
--	if string.find(self:GetParent():GetUnitName(), "_fort") then
		self:StartIntervalThink(1)
	end
end
function modifier_invulnerable_cus:OnIntervalThink()
	if not IsServer() then return end
	local boss = GameMode:GetBoss()
	if boss then
		if boss:IsAlive() then
			self:SetStackCount(1)
		else
			self:SetStackCount(0)
		end
	end
end
function modifier_invulnerable_cus:CheckState()
	if self:GetStackCount() == 1 then
		return {
	--		[MODIFIER_STATE_INVULNERABLE] = true,
	--		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
		}
	end
end
