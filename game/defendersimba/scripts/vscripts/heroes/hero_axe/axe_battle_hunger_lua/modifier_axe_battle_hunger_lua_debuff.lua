modifier_axe_battle_hunger_lua_debuff = class({
    IsHidden = function(self) return false end, -- можно скрыть иконку модификатора
    IsPurgable = function(self) return true end, --Развеивается?
    IsDebuff = function(self) return true end, --Дэбафф?
    IsStunDebuff = function(self) return false end, --Бафф
    RemoveOnDeath = function(self) return true end, --Удаляется после смерти
	GetAttributes = function(self) return MODIFIER_ATTRIBUTE_MULTIPLE end,
    DeclareFunctions = function(self) return
	{
		MODIFIER_EVENT_ON_DEATH,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
	} end,
})
--------------------------------------------------------------------------------
function modifier_axe_battle_hunger_lua_debuff:OnCreated( kv )
	self.slow = self:GetAbility():GetSpecialValueFor("slow")
	local interval = self:GetAbility():GetSpecialValueFor("interval")
	self.damage = kv.damage or 0
	if kv.str_debuff then
		self.str_debuff = kv.str_debuff
	else
		self.str_debuff = 0 -- Если бонус не передан, устанавливаем его в 0
	end

	if IsServer() then
		-- precache damage
		self.damageTable = {
			victim = self:GetParent(),
			attacker = self:GetCaster(),
			damage = self.damage,
			damage_type = DAMAGE_TYPE_MAGICAL,
			ability = self:GetAbility(),
			damage_flags = DOTA_DAMAGE_FLAG_NONE,
		}
		self:StartIntervalThink(interval)		
		self:OnIntervalThink()			
	end
end

function modifier_axe_battle_hunger_lua_debuff:GetModifierBonusStats_Strength()
    return self.str_debuff
end

function modifier_axe_battle_hunger_lua_debuff:OnDeath( params )
	if IsServer() then
		if params.attacker~=self:GetParent() then return end
		self:Destroy()
	end
end

function modifier_axe_battle_hunger_lua_debuff:GetModifierMoveSpeedBonus_Percentage()
	return self.slow
end

function modifier_axe_battle_hunger_lua_debuff:OnIntervalThink()
	ApplyDamage(self.damageTable)	
end

function modifier_axe_battle_hunger_lua_debuff:GetEffectName()
	return "particles/econ/items/axe/axe_cinder/axe_cinder_battle_hunger.vpcf"
end

function modifier_axe_battle_hunger_lua_debuff:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end