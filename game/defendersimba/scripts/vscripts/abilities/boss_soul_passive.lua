LinkLuaModifier("modifier_boss_soul_passive", "abilities/boss_soul_passive", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_boss_soul_passive_buff", "abilities/boss_soul_passive", LUA_MODIFIER_MOTION_NONE)

boss_soul_passive = class({})

function boss_soul_passive:GetIntrinsicModifierName()
    return "modifier_boss_soul_passive"
end

modifier_boss_soul_passive = class({})

function modifier_boss_soul_passive:IsHidden()
    return true
end

function modifier_boss_soul_passive:OnCreated()
    if IsClient() then return end

    local ability = self:GetAbility()
    self.radius = ability:GetSpecialValueFor("radius")
    self.boss = GameMode:GetBoss()
    self:StartIntervalThink(ability:GetSpecialValueFor("tick"))
end
 
function modifier_boss_soul_passive:OnIntervalThink()
    if IsClient() then return end
    local unit = self:GetParent()

 
    if not self.boss or not self.boss:IsAlive() then return end
    local enemies = FindUnitsInRadius(
        unit:GetTeamNumber(),
        unit:GetAbsOrigin(),
        nil,
        self.radius,
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_BUILDING,
        DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_ANY_ORDER,
        false
    )

    if #enemies > 0 then
        if not self.isUnitStoped then
            unit:Stop()
            self.isUnitStoped = true
        end
     else 
        self.isUnitStoped = false
        unit:MoveToPosition(Vector(-10862, 10454, 0))
    end
    local distance = (unit:GetAbsOrigin() - self.boss:GetAbsOrigin()):Length2D()
 
    if distance > self.radius then
        FindClearSpaceForUnit(self.boss, unit:GetAbsOrigin(), true)
    end
end
 

function modifier_boss_soul_passive:CheckState()
    return {
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true
    }
end



 