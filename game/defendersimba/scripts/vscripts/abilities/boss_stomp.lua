boss_stomp = class({})
 
function boss_stomp:OnAbilityPhaseStart()
	if IsServer() then
 
        local particle_cast = "particles/units/heroes/hero_snapfire/hero_snapfire_ultimate_calldown.vpcf"
        local point = self:GetAbsOrigin()
        local radius = self:GetSpecialValueFor("radius")
        local duration = self:GetSpecialValueFor("duration")

        self.particle = ParticleManager:CreateParticle( particle_cast, PATTACH_CUSTOMORIGIN, caster)
        ParticleManager:SetParticleControl( self.particle, 0, point )
        ParticleManager:SetParticleControl( self.particle, 1, Vector( radius, 0,  -radius ))
        ParticleManager:SetParticleControl( self.particle, 2, Vector( self:GetCastPoint(), 0, 0 ) )
    end

	return true
end

function boss_stomp:OnAbilityPhaseInterrupted()
	if IsClient() then return end
 
    ParticleManager:DestroyParticle(self.particle, true)
end
 
function boss_stomp:OnSpellStart()
    ParticleManager:DestroyParticle(self.particle, true)

	local radius = self:GetSpecialValueFor("radius")
	local damage = self:GetSpecialValueFor("damage")
	local duration = self:GetSpecialValueFor("duration")
	local caster = self:GetCaster()
	local casterPos = caster:GetAbsOrigin()

	local enemies = FindUnitsInRadius(
		caster:GetTeamNumber(),
		casterPos,
		nil,
		radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		0,
		0,
		false
	)

	for _, enemy in pairs(enemies) do
		enemy:AddNewModifier(caster, self, "modifier_stunned", {duration = duration * (1 - enemy:GetStatusResistance())})
		
		local damageTable = {
			victim = enemy,
			attacker = caster,
			damage = damage,
			damage_type = self:GetAbilityDamageType(),
			ability = self
		}
		ApplyDamage(damageTable)
	end

	EmitSoundOnLocationWithCaster(casterPos, "Hero_Centaur.HoofStomp", caster)
	
	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_centaur/centaur_warstomp.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 0, casterPos)
	ParticleManager:SetParticleControl(particle, 1, Vector(radius, 1, 1))
	ParticleManager:ReleaseParticleIndex(particle)
end