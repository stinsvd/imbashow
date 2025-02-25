venomancer_universal_toxin = class({
    GetIntrinsicModifierName = function()
        return "modifier_venomancer_universal_toxin"
    end,
    OnHeroLevelUp = function(self)
        if not IsServer() then return end

        local modif = self:GetCaster():FindModifierByName("modifier_venomancer_universal_toxin")

        if modif then
            modif.caster_lvl = self:GetCaster():GetLevel()
            modif:UpdateDamageValues()
        end
    end,
})

LinkLuaModifier("modifier_venomancer_universal_toxin", "heroes/venomancer/venomancer_universal_toxin", LUA_MODIFIER_MOTION_NONE)

modifier_venomancer_universal_toxin = class({
    IsHidden            = function() return true end,
    IsDebuff            = function() return false end,
    IsPurchasable       = function() return false end,
    RemoveOnDeath       = function() return false end,
    DeclareFunctions    = function() 
        return {
            MODIFIER_EVENT_ON_TAKEDAMAGE,
            MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL,
            MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL_VALUE,
        }
    end,

    OnCreated = function(self)
        self.caster_lvl = self:GetCaster():GetLevel()
        self:SetHasCustomTransmitterData(true)
        self:ForceRefresh()
        self:UpdateDamageValues()

        if not IsServer() then return end
        
        self.hero_abilities = {}

        local parent = self:GetParent()
        for i = 0, parent:GetAbilityCount() - 1 do
            local ability = parent:GetAbilityByIndex(i)
            if ability then
                table.insert(self.hero_abilities, ability:GetAbilityName())
            end
        end
    end,

    OnRefresh = function(self)
        self.overriden_damage_per_sec   = self.overriden_damage_per_sec or 0
        self.stack_count_per_item_tick  = self:GetAbility():GetSpecialValueFor("stack_count_per_item_tick")
        self.duration                   = self:GetAbility():GetSpecialValueFor("duration")

        self.base_damage_per_sec        = self:GetAbility():GetSpecialValueFor("damage_per_sec_base")
        self.bonus_damage_per_lvl       = self:GetAbility():GetSpecialValueFor("bonus_damage_per_lvl")

        if self:GetCaster():HasScepter() then
            self.int_scale              =  self:GetAbility():GetSpecialValueFor("int_scale") / 100    
        else
            self.int_scale              = 0
        end
    end,

    OnTakeDamage = function(self, EventData)
        if not IsServer() then return end
        if EventData.attacker ~= self:GetParent() or EventData.unit == self:GetParent()                                                 then return end
        if EventData.inflictor and (EventData.inflictor:IsItem() ~= true or self:IsHeroAbility(EventData.inflictor:GetAbilityName()))   then return end
        if EventData.damage_category == DOTA_DAMAGE_CATEGORY_ATTACK                                                                     then return end


        local modif = EventData.unit:FindModifierByName("modifier_venomancer_universal_toxin_debuff")
        if modif then
            modif:SetStackCount(modif:GetStackCount() + self.stack_count_per_item_tick)
            modif:SetDuration(self.duration, true)
        else
            local modif = EventData.unit:AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_venomancer_universal_toxin_debuff", {duration = self.duration})
            modif:SetStackCount(modif:GetStackCount() + self.stack_count_per_item_tick)
        end
    end,

    IsHeroAbility = function(self, ability_name)
        for _, name in pairs(self.hero_abilities) do
            if name == ability_name then
                return true
            end
        end
        return false
    end,

    UpdateDamageValues = function(self)
        self.overriden_damage_per_sec = self.base_damage_per_sec + (self.bonus_damage_per_lvl * self.caster_lvl)
        self:ForceRefresh()
    end,

    AddCustomTransmitterData = function(self)
        return {
            overriden_damage_per_sec = self.overriden_damage_per_sec
        }
    end,
    
    HandleCustomTransmitterData = function(self, data)
        if data.overriden_damage_per_sec then
            self.overriden_damage_per_sec = data.overriden_damage_per_sec
        end
    end,

    GetModifierOverrideAbilitySpecial = function(self, data)
        if data.ability:GetAbilityName() == self:GetAbility():GetAbilityName() and data.ability_special_value == "damage_per_sec" then
            return 1
        end
        return 0
    end,

    GetModifierOverrideAbilitySpecialValue = function(self, data)
        if data.ability:GetAbilityName() == self:GetAbility():GetAbilityName() and data.ability_special_value == "damage_per_sec" then
            return self.overriden_damage_per_sec + (self.int_scale * self:GetCaster():GetIntellect(false))
        end
    end,
})

LinkLuaModifier("modifier_venomancer_universal_toxin_debuff", "heroes/venomancer/venomancer_universal_toxin", LUA_MODIFIER_MOTION_NONE)

modifier_venomancer_universal_toxin_debuff = class({
    IsHidden            = function() return false end,
    IsDebuff            = function() return true end,
    IsPurchasable       = function() return true end,
    RemoveOnDeath       = function() return true end,
    DeclareFunctions    = function()
        return {
            MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        }
    end,

    OnCreated = function(self)
        self:ForceRefresh()
        self:SetHasCustomTransmitterData(true)
    end,

    OnRefresh = function(self)
        self.damage_tick_rate           =  self:GetAbility():GetSpecialValueFor("damage_tick_rate")
        self.bonus_damage_per_lvl       = (self:GetAbility():GetSpecialValueFor("bonus_damage_per_lvl") / self.damage_tick_rate)
        self.ms_debuff_treshold         =  self:GetAbility():GetSpecialValueFor("ms_debuff_treshold")
        self.ms_debuff_value            = (self:GetAbility():GetSpecialValueFor("ms_debuff_value") * -1)
        self.duration                   = self:GetAbility():GetSpecialValueFor("duration")

        self:StartIntervalThink(self.damage_tick_rate)
    end,

    OnIntervalThink = function(self)
        if not IsServer() then return end
        ApplyDamage({
            victim      = self:GetParent(),
            attacker    = self:GetCaster(),
            damage      = ((self:GetAbility():GetSpecialValueFor("damage_per_sec") / self.damage_tick_rate) * self:GetStackCount()),
            damage_type = self:GetAbility():GetAbilityDamageType(),
            ability     = self:GetAbility(),
        })
    end,

    AddCustomTransmitterData = function(self)
        return {
            ms_debuff_value = self.ms_debuff_value,
        }
    end,
    
    HandleCustomTransmitterData = function(self, data)
        if data.ms_debuff_value then
            self.ms_debuff_value = data.ms_debuff_value
        end
    end,
    
    GetModifierMoveSpeedBonus_Percentage = function(self)
        return (self.ms_debuff_value) * (self:GetStackCount() / self.ms_debuff_treshold)
    end,
})
