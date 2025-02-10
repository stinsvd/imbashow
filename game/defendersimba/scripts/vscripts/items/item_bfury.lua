LinkLuaModifier("modifier_item_bfury_custom", "items/item_bfury", LUA_MODIFIER_MOTION_NONE)

item_bfury_1 = class({})
item_bfury_2 = item_bfury_1
item_bfury_3 = item_bfury_1
item_bfury_4 = item_bfury_1
item_bfury_5 = item_bfury_1
item_bfury_6 = item_bfury_1

function item_bfury_1:GetIntrinsicModifierName()
    return "modifier_item_bfury_custom"
end

function item_bfury_1:OnSpellStart()
	local target = self:GetCursorTarget()
	if target and target.CutDown then
		target:CutDown(self:GetCaster():GetTeamNumber())
	else
		GridNav:DestroyTreesAroundPoint(target:GetAbsOrigin(), 10, true)
	end
end

modifier_item_bfury_custom = class({})

function modifier_item_bfury_custom:IsHidden()
    return true
end
function modifier_item_bfury_custom:IsPurgable() return false end
function modifier_item_bfury_custom:IsPermanent() return true end

function modifier_item_bfury_custom:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_bfury_custom:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK_LANDED,
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    }
end

function modifier_item_bfury_custom:OnCreated()
    self.ability = self:GetAbility()
    self.cleaveDamage = self.ability:GetSpecialValueFor("cleave_damage")
    self.cleaveDistance = self.ability:GetSpecialValueFor("cleave_distance")
    self.cleaveStartingWidth = self.ability:GetSpecialValueFor("cleave_starting_width")
    self.cleaveEndingWidth = self.ability:GetSpecialValueFor("cleave_ending_width")
    self.bonusDamage = self.ability:GetSpecialValueFor("bonus_damage")
    self.bonusHealthRegen = self.ability:GetSpecialValueFor("bonus_hp_regen")
    self.bonusManaRegen = self.ability:GetSpecialValueFor("bonus_mana_regen")
    self.bonusAttackSpeed = self.ability:GetSpecialValueFor("bonus_attack_speed")
end

function modifier_item_bfury_custom:OnAttackLanded(event)
    local parent = self:GetParent()

    if event.attacker ~= parent then return end
    if parent:IsRangedAttacker() then return end

    local cleaveDamage = (self.cleaveDamage * event.damage) / 100.0
    DoCleaveAttack(
        parent,
        event.target,
        self.ability,
        cleaveDamage,
        self.cleaveStartingWidth,
        self.cleaveEndingWidth,
        self.cleaveDistance,
        "particles/items_fx/battlefury_cleave.vpcf"
    )
end

function modifier_item_bfury_custom:GetModifierPreAttack_BonusDamage()
    return self.bonusDamage
end

function modifier_item_bfury_custom:GetModifierConstantHealthRegen()
    return self.bonusHealthRegen
end

function modifier_item_bfury_custom:GetModifierConstantManaRegen()
    return self.bonusManaRegen
end

function modifier_item_bfury_custom:GetModifierAttackSpeedBonus_Constant()
    return self.bonusAttackSpeed
end
