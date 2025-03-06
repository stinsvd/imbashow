LinkLuaModifier("modifier_moon_shard_cus", "items/moon_shard", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_moon_shard_cus_consume", "items/moon_shard", LUA_MODIFIER_MOTION_NONE)

item_moon_shard_cus = item_moon_shard_cus or class({})
function item_moon_shard_cus:GetIntrinsicModifierName() return "modifier_moon_shard_cus" end
function item_moon_shard_cus:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local bonus_as = self:GetSpecialValueFor("consumed_bonus")
	local bonus_nv = self:GetSpecialValueFor("consumed_bonus_night_vision")
	
	if caster:IsTempestDouble() then return end
	if target:IsTempestDouble() then return end
	
	target:EmitSound("Item.MoonShard.Consume")
	
	local modifier = target:AddNewModifier(caster, self, "modifier_moon_shard_cus_consume", {attack_speed = bonus_as, night_vision = bonus_nv})
	for i = 1, self:GetCurrentCharges() do
		modifier:IncrementStackCount()
	end
	caster:ConsumeItem(self)
end

modifier_moon_shard_cus = modifier_moon_shard_cus or class({})
function modifier_moon_shard_cus:IsHidden() return true end
function modifier_moon_shard_cus:IsPurgable() return false end
function modifier_moon_shard_cus:IsPermanent() return true end
function modifier_moon_shard_cus:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end
function modifier_moon_shard_cus:OnCreated()
	if not IsServer() then return end
	self:StartIntervalThink(0.1)
end
function modifier_moon_shard_cus:OnIntervalThink()
	local sum = 0
	for i = 1, self:GetAbility():GetCurrentCharges() do
		sum = sum + 1 / i
	end
	self:SetStackCount(sum * 100)
end
function modifier_moon_shard_cus:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_BONUS_NIGHT_VISION_UNIQUE,
	}
end
function modifier_moon_shard_cus:GetModifierAttackSpeedBonus_Constant()
	if self:GetAbility() then return self:GetAbility():GetSpecialValueFor("bonus_attack_speed") * (self:GetStackCount() / 100) end
end
function modifier_moon_shard_cus:GetBonusNightVisionUnique()
	if self:GetAbility() then return self:GetAbility():GetSpecialValueFor("bonus_night_vision") * (self:GetStackCount() / 100) end
end

modifier_moon_shard_cus_consume = modifier_moon_shard_cus_consume or class({})
function modifier_moon_shard_cus_consume:IsHidden() return false end
function modifier_moon_shard_cus_consume:IsPurgable() return false end
function modifier_moon_shard_cus_consume:RemoveOnDeath() return false end
function modifier_moon_shard_cus_consume:GetTexture() return "moon_shard" end
function modifier_moon_shard_cus_consume:OnCreated(kv)
	if not IsServer() then return end
	self.as_consume = kv.attack_speed
	self.night_vision_consume = kv.night_vision
	self.as_total = self.as_consume
	self.night_vision_total = self.night_vision_consume
	self:SetHasCustomTransmitterData(true)
end
function modifier_moon_shard_cus_consume:OnRefresh(kv)
	if not IsServer() then return end
	self.as_consume = kv.attack_speed
	self.night_vision_consume = kv.night_vision
end
function modifier_moon_shard_cus_consume:OnStackCountChanged(old)
	if not IsServer() then return end
	local sum = 0
	for i = 1, self:GetStackCount() do
		sum = sum + 1 / i
	end
	self.as_total = self.as_consume * sum
	self.night_vision_total = self.night_vision_consume * sum
	self:SendBuffRefreshToClients()
end
function modifier_moon_shard_cus_consume:AddCustomTransmitterData()
	return {
		as_total = self.as_total,
		night_vision_total = self.night_vision_total,
	}
end
function modifier_moon_shard_cus_consume:HandleCustomTransmitterData(data)
	self.as_total = data.as_total
	self.night_vision_total = data.night_vision_total
end
function modifier_moon_shard_cus_consume:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_BONUS_NIGHT_VISION_UNIQUE,
	}
end
function modifier_moon_shard_cus_consume:GetModifierAttackSpeedBonus_Constant() return self.as_total end
function modifier_moon_shard_cus_consume:GetBonusNightVisionUnique() return self.night_vision_total end
