LinkLuaModifier("modifier_boss_silence", "abilities/boss_silence", LUA_MODIFIER_MOTION_NONE)


boss_silence = class({})

function boss_silence:GetIntrinsicModifierName()
    return "modifier_boss_silence"
end

 

modifier_boss_silence = class({})

function modifier_boss_silence:IsHidden()
    return true
end

function modifier_boss_silence:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_TAKEDAMAGE
    }
end


function modifier_boss_silence:OnCreated()
    local ability = self:GetAbility()
    self.isSilinced = false
    self.hpPercent = ability:GetSpecialValueFor("hp_percent")
    self.radius = ability:GetSpecialValueFor("radius")
    self.duration = ability:GetSpecialValueFor("duration")
end
 

function modifier_boss_silence:OnTakeDamage( event )
    local parent = self:GetParent()
	if event.unit == parent then
        if parent:GetHealthPercent() <= self.hpPercent and not self.isSilinced then 
            self.isSilinced = true
            local ability = self:GetAbility()
            
            local enemies = FindUnitsInRadius(
                parent:GetTeamNumber(),
                parent:GetAbsOrigin(),
                nil,
                self.radius, 
                DOTA_UNIT_TARGET_TEAM_ENEMY,
                DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
                0,
                FIND_ANY_ORDER,
                false
            )

            for _, enemy in pairs(enemies) do
                enemy:AddNewModifier(parent, ability, "modifier_silence", {duration = self.duration})
            end
        end
 	end
end