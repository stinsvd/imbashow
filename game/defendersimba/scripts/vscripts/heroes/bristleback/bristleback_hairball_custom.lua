bristleback_hairball_custom = bristleback_hairball_custom or class({})
function bristleback_hairball_custom:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end
function bristleback_hairball_custom:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local targetPos = self:GetCursorPosition()
	local radius = self:GetSpecialValueFor("radius")
	local projectile_speed = self:GetSpecialValueFor("projectile_speed")
	local goo_stacks = self:GetSpecialValueFor("goo_stacks")
	local quill_stacks = self:GetSpecialValueFor("quill_stacks")
	caster:EmitSound("Hero_Bristleback.Hairball.Cast")

	local diraction = targetPos - caster:GetAbsOrigin()
	local projectile = {
		Ability = self,
		EffectName = "particles/units/heroes/hero_bristleback/bristleback_hairball.vpcf",
		vSpawnOrigin = caster:GetAttachmentOrigin(caster:ScriptLookupAttachment("attach_hitloc")),
		fDistance = diraction:Length2D(),
		fStartRadius = 0,
		fEndRadius = 0,
		Source = caster,
		bHasFrontalCone = false,
		bReplaceExisting = false,
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_NONE,
		iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
		iUnitTargetType = DOTA_UNIT_TARGET_NONE,
		fExpireTime = GameRules:GetGameTime() + 10,
		bDeleteOnHit = false,
		vVelocity = diraction:Normalized() * projectile_speed * (Vector(1, 1, 0)),
		bProvidesVision = false,
		ExtraData = {
			radius = radius,
			goo_stacks = goo_stacks,
			quill_stacks = quill_stacks,
		}
	}
	ProjectileManager:CreateLinearProjectile(projectile)
end
function bristleback_hairball_custom:OnProjectileHit_ExtraData(target, loc, data)
	if not IsServer() then return end
	local caster = self:GetCaster()
	
	local goo = caster:FindAbilityByName("bristleback_viscous_nasal_goo_custom")
	if goo and goo:IsTrained() then
		for i = 1, data.goo_stacks do
			goo:OnSpellStart(true, false, loc)
		end
	end
	local spray = caster:FindAbilityByName("bristleback_quill_spray_custom")
	if spray and spray:IsTrained() then
		for i = 1, data.quill_stacks do
			spray:OnSpellStart(true, false, loc)
		end
	end
end