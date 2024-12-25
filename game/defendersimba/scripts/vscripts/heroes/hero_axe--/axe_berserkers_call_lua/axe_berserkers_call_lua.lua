--Designed by: AniPream from ImbaShow :)
--19/12/2024
--Код состоит из трех частей для удобства. Этот - основной код способности, два остальных, это модификаторы для владельца и для врагов.
--Способность агрит на владельца вражеских существ и героев в радиусе(Имеющийся партикл подсдстравивается под радиус способности).
--Способность дает броню владельцу и увеличивает скорость атаки врагов.
LinkLuaModifier( "modifier_axe_berserkers_call_lua", "heroes/hero_axe/axe_berserkers_call_lua/modifier_axe_berserkers_call_lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_axe_berserkers_call_lua_debuff", "heroes/hero_axe/axe_berserkers_call_lua/modifier_axe_berserkers_call_lua_debuff", LUA_MODIFIER_MOTION_NONE )
axe_berserkers_call_lua = class({})

function axe_berserkers_call_lua:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local point = caster:GetOrigin()

    self.radius = self:GetSpecialValueFor("radius")-- Получаем ключ радиуса поиска врагов
    local duration = self:GetSpecialValueFor("duration")  -- Получаем ключ длительности
    local buff_attack_speed_enemy = self:GetSpecialValueFor("buff_attack_speed_enemy") -- Получаем ключ скорости атаки

    -- Ищем врагов
    local enemies = FindUnitsInRadius(
        caster:GetTeamNumber(),
        point, 
        nil,
        self.radius,  -- Используем радиус, который у вас уже есть
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,    -- Кого ищем?
        DOTA_UNIT_TARGET_FLAG_NOT_MAGIC_IMMUNE_ALLIES,    -- Не работает на иммунных к магии врагов
        0,
        false
    )
    -- если есть шард и абилка изучена то вызываем метод OnSpellStart напрямую с укзаанием цели.
    if caster:HasModifier("modifier_item_aghanims_shard") then
        local ability = caster:FindAbilityByName("axe_battle_hunger_lua")
        if ability and ability:IsTrained() then
            for _, enemy in pairs(enemies) do
                if enemy and not enemy:IsNull() then
                    -- Вызываем логику способности с передачей цели
                    ability:OnSpellStart(enemy)
                end
            end
        end
    end

    for _,enemy in pairs(enemies) do
        enemy:AddNewModifier(
            caster,
            self,
            "modifier_axe_berserkers_call_lua_debuff",
            { duration = duration, buff_attack_speed_enemy = buff_attack_speed_enemy } -- передаем значение скорости атаки и длительности
        )
    end

	caster:AddNewModifier(
		caster,
		self, 
		"modifier_axe_berserkers_call_lua",
		{ duration = duration }
	)

	if #enemies>0 then
		local fx = ParticleManager:CreateParticle("particles/econ/items/centaur/centaur_ti6/centaur_ti6_warstomp.vpcf", PATTACH_ABSORIGIN, caster) -- рекамендую использовать данный партикл
		-- так как стандартный партикл акса particles/units/heroes/hero_axe/axe_beserkers_call_owner.vpcf не увеличивается в радиусе(вольво молодцы?)
		ParticleManager:SetParticleControl(fx, 0, caster:GetAbsOrigin())
		ParticleManager:SetParticleControl(fx, 1, Vector(self.radius,self.radius,self.radius)) -- то что отвечает за радиус
		ParticleManager:ReleaseParticleIndex(fx)
		local sound_cast = "Hero_Axe.Berserkers_Call"
		EmitSoundOn(sound_cast, self:GetCaster())
	end
	self:PlayEffects(caster)
end

--------------------------------------------------------------------------------
function axe_berserkers_call_lua:PlayEffects(sourceUnit)
	local particle_cast = "particles/econ/items/centaur/centaur_ti6/centaur_ti6_warstomp.vpcf" -- рекамендую использовать данный партикл
	-- так как стандартный партикл акса particles/units/heroes/hero_axe/axe_beserkers_call_owner.vpcf не увеличивается в радиусе(вольво молодцы?)

	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, sourceUnit )
	ParticleManager:SetParticleControl( effect_cast, 1, Vector(self.radius,self.radius,self.radius) ) -- то что отвечает за радиус
	ParticleManager:ReleaseParticleIndex( effect_cast )
end