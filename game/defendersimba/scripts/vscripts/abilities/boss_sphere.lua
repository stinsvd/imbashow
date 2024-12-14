LinkLuaModifier( "modifier_boss_sphere","abilities/boss_sphere", LUA_MODIFIER_MOTION_NONE )

boss_sphere = class({})

function boss_sphere:OnAbilityPhaseStart()
	if IsServer() then
 
 		EmitSoundOn( "Hero_VengefulSpirit.MagicMissileImpact", self:GetCaster() )

		self.nPreviewFX = ParticleManager:CreateParticle( "particles/dark_moon/darkmoon_creep_warning.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster() )
		ParticleManager:SetParticleControlEnt( self.nPreviewFX, 0, self:GetCaster(), PATTACH_ABSORIGIN_FOLLOW, nil, self:GetCaster():GetOrigin(), true )
		ParticleManager:SetParticleControl( self.nPreviewFX, 1, Vector( 150, 150, 150 ) )
		ParticleManager:SetParticleControl( self.nPreviewFX, 15, Vector( 188, 26, 26 ) )
	end

	return true
end

function boss_sphere:OnAbilityPhaseInterrupted()
	if IsServer() then
		self:GetCaster():RemoveGesture( ACT_DOTA_CAST_ABILITY_1 )
		ParticleManager:DestroyParticle( self.nPreviewFX, false )
 
 		StopSoundOn("Hero_VengefulSpirit.MagicMissileImpact", self:GetCaster())
	end 
end


function boss_sphere:OnSpellStart()
	ParticleManager:DestroyParticle( self.nPreviewFX, false )
	local vDirection = self:GetCursorPosition() - self:GetCaster():GetOrigin()
	vDirection = vDirection:Normalized()

	self.wave_speed = self:GetSpecialValueFor( "wave_speed" )
	self.wave_width = self:GetSpecialValueFor( "wave_width" )
	self.vision_aoe = self:GetSpecialValueFor( "vision_aoe" )
	self.vision_duration = self:GetSpecialValueFor( "vision_duration" )
	self.tooltip_duration = self:GetSpecialValueFor( "tooltip_duration" )
	self.wave_damage = self:GetSpecialValueFor( "wave_damage" )

	local info = {
		EffectName = "particles/neutral_fx/satyr_hellcaller.vpcf",
		Ability = self,
		vSpawnOrigin = self:GetCaster():GetOrigin(), 
		fStartRadius = self.wave_width,
		fEndRadius = self.wave_width,
		vVelocity = vDirection * self.wave_speed,
		fDistance = self:GetCastRange( self:GetCaster():GetOrigin(), self:GetCaster() ),
		Source = self:GetCaster(),
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP,
		iUnitTargetFlags = self:GetAbilityTargetFlags(),
		bProvidesVision = true,
		iVisionTeamNumber = self:GetCaster():GetTeamNumber(),
		iVisionRadius = self.vision_aoe,
	}

 

	self.flVisionTimer = self.wave_width / self.wave_speed
	self.flLastThinkTime = GameRules:GetGameTime()
	self.nProjID = ProjectileManager:CreateLinearProjectile( info )
	EmitSoundOn( "Hero_VengefulSpirit.MagicMissile", self:GetCaster() )
end

--------------------------------------------------------------------------------

function boss_sphere:OnProjectileThink( vLocation )
	self.flVisionTimer = self.flVisionTimer - ( GameRules:GetGameTime() - self.flLastThinkTime )

	if self.flVisionTimer <= 0.0 then
		local vVelocity = ProjectileManager:GetLinearProjectileVelocity( self.nProjID )
		AddFOWViewer( self:GetCaster():GetTeamNumber(), vLocation + vVelocity * ( self.wave_width / self.wave_speed ), self.vision_aoe, self.vision_duration, false )
		self.flVisionTimer = self.wave_width / self.wave_speed
	end
end


--------------------------------------------------------------------------------

function boss_sphere:OnProjectileHit( hTarget, vLocation )
	if hTarget ~= nil then
		local damage = {
			victim = hTarget,
			attacker = self:GetCaster(),
			damage = self.wave_damage,
			damage_type =  self:GetAbilityDamageType(),
			ability = this,
		}

		ApplyDamage( damage )
		if hTarget:IsAlive() then 
		if hTarget:HasModifier("modifier_boss_sphere") then  
                hTarget:FindModifierByName("modifier_boss_sphere"):IncrementStackCount()
                hTarget:FindModifierByName("modifier_boss_sphere"):SetDuration(self.tooltip_duration * (1 - hTarget:GetStatusResistance() ), true)		 
	    else 
            hTarget:AddNewModifier( self:GetCaster(), self, "modifier_boss_sphere", { duration = self.tooltip_duration * (1 - hTarget:GetStatusResistance() )} )
                            hTarget:FindModifierByName("modifier_boss_sphere"):IncrementStackCount()
	    end 
       end
	end

	return false
end

 
modifier_boss_sphere = class({})

--------------------------------------------------------------------------------

function modifier_boss_sphere:IsDebuff()
	return true
end

function modifier_boss_sphere:IsPurgable()
	return false
end
--------------------------------------------------------------------------------

function modifier_boss_sphere:GetEffectName()
	return "particles/units/heroes/hero_vengeful/vengeful_wave_of_terror_recipient.vpcf"
end

--------------------------------------------------------------------------------

function modifier_boss_sphere:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

--------------------------------------------------------------------------------

function modifier_boss_sphere:OnCreated( kv )
	self.manacost_reduction = self:GetAbility():GetSpecialValueFor( "manacost_reduction" )
end

--------------------------------------------------------------------------------

function modifier_boss_sphere:OnRefresh( kv )
	self.manacost_reduction = self:GetAbility():GetSpecialValueFor( "manacost_reduction" )  
end

--------------------------------------------------------------------------------

function modifier_boss_sphere:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MANACOST_PERCENTAGE_STACKING
	}
	return funcs
end

--------------------------------------------------------------------------------

function modifier_boss_sphere:GetModifierPercentageManacostStacking()
 
		return self.manacost_reduction * self:GetStackCount()
 
end
 