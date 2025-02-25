venomancer_poison_sting_custom = class({
    GetIntrinsicModifierName = function(self)
        return "modifier_venomancer_poison_sting_custom"
    end,
})

LinkLuaModifier("modifier_venomancer_poison_sting_custom", "heroes/venomancer/venomancer_poison_sting_custom", LUA_MODIFIER_MOTION_NONE)

modifier_venomancer_poison_sting_custom = class({
    IsHidden            = function() return true end,
    IsDebuff            = function() return false end,
    IsPurchasable       = function() return false end,
    RemoveOnDeath       = function() return false end,
    DeclareFunctions    = function() 
        return {
            MODIFIER_EVENT_ON_ATTACK_LANDED,
            MODIFIER_EVENT_ON_ATTACK
        }
    end,

    OnCreated = function(self)
        self:ForceRefresh()
    end,

    OnRefresh = function(self)
        self.stack_count        = self:GetAbility():GetSpecialValueFor("stack_count")
        self.target_count       = self:GetAbility():GetSpecialValueFor("target_count")

        if not IsServer() then return end
        self.targetTeam         = self:GetAbility():GetAbilityTargetTeam()
        self.targetType         = self:GetAbility():GetAbilityTargetType()
        self.targetFlags        = self:GetAbility():GetAbilityTargetFlags()
    end,

    OnAttack = function(self, EventData)
        if EventData.attacker ~= self:GetParent() or EventData.no_attack_cooldown == true then return end
        
        if not EventData.attacker:GetUnitName() == "npc_dota_venomancer_poison_ward" or not self:GetCaster():HasModifier("modifier_item_aghanims_shard") then return end
        local isRangedAttacker = (self:GetParent():GetAttackCapability() == DOTA_UNIT_CAP_RANGED_ATTACK)

        local enemies = FindUnitsInRadius(
            self:GetParent():GetTeamNumber(),
            self:GetParent():GetAbsOrigin(),
            nil,
            self:GetParent():Script_GetAttackRange(),
            self.targetTeam,
            self.targetType,
            self.targetFlags,
            FIND_ANY_ORDER,
            false
        )
        local currentDamagedEnemies = 0

        for _, enemy in pairs(enemies) do
            if currentDamagedEnemies >= self.target_count then
                break
            end
            if enemy ~= EventData.target then
                self:GetParent():PerformAttack(enemy, true, true, true, false, isRangedAttacker, false, false)
                self:ApplyToxin(enemy)
                currentDamagedEnemies = currentDamagedEnemies + 1
            end
        end
    end,

    OnAttackLanded = function(self, EventData)
        if EventData.attacker == self:GetParent() and EventData.no_attack_cooldown == false then
            self:ApplyToxin(EventData.target)
        end
    end,

    ApplyToxin = function(self, enemy)
        local modif  = enemy:FindModifierByName("modifier_venomancer_universal_toxin_debuff")
        local caster = self:GetCaster()
        if modif then
            modif:SetStackCount(modif:GetStackCount() + self.stack_count)
            modif:SetDuration(modif.duration, true)
        else
            if self:GetCaster():GetUnitName() == "npc_dota_venomancer_poison_ward" then
                caster = self:GetCaster():GetOwner()
            end

            local venomancer_universal_toxin = caster:FindAbilityByName("venomancer_universal_toxin")
            if venomancer_universal_toxin then
                local new_modif = enemy:AddNewModifier(caster, venomancer_universal_toxin, "modifier_venomancer_universal_toxin_debuff", { duration = venomancer_universal_toxin:GetSpecialValueFor("duration")})
                if new_modif then
                    new_modif:SetStackCount(self.stack_count)
                end
            end
        end
    end,
})