--Designed by: AniPream from ImbaShow :)
--20/12/2024
--Код состоит из трех частей для удобства. Этот - основной код способности, два остальных, это модификаторы для владельца и для врагов.
--Способность накладывает стакающийся эффект на врагов. Дэбафф отнимает скорость передвижение и силу(кража).Бафф дает аксу скорость пердвижение и украденую силу.
--Дебафф не снимается когда враг кого нибудь убьет(Как в оригинале. Если нужно то добавлю.)
--Урон способности наносится только от  ОБЩЕЙ силы владельца.
LinkLuaModifier( "modifier_axe_battle_hunger_lua", "heroes/hero_axe/axe_battle_hunger_lua/modifier_axe_battle_hunger_lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_axe_battle_hunger_lua_debuff", "heroes/hero_axe/axe_battle_hunger_lua/modifier_axe_battle_hunger_lua_debuff", LUA_MODIFIER_MOTION_NONE )

axe_battle_hunger_lua = class({})

function axe_battle_hunger_lua:OnSpellStart(target) -- принимаем цель из вне когда нам не нужен курсор
    if IsServer() then
        local caster = self:GetCaster()
        -- Используем переданную цель
        local target = target or self:GetCursorTarget()
        local duration = self:GetSpecialValueFor("duration")
        local damage_per_str = self:GetSpecialValueFor("damage_per_str")
        local str_bonus_per_hero = self:GetSpecialValueFor("str_bonus_per_hero")
        local str_debuff = self:GetSpecialValueFor("str_debuff")
        local strength = caster:GetStrength()
		
		local damage = (strength * damage_per_str) / 100 -- Расчитываем урон от силы. Преобразуем целое число в процент.
		--===============================
		--модификатор на врага
		if target:IsHero() then -- если герой то отнимаем силу
			target:AddNewModifier(
				caster,
				self,
				"modifier_axe_battle_hunger_lua_debuff",
				{ duration = duration, damage = damage, str_debuff = str_debuff  }
			)
		else
			target:AddNewModifier(
				caster,
				self,
				"modifier_axe_battle_hunger_lua_debuff",
				{ duration = duration, damage = damage }
			)
		end	
		--===============================
		--модификатор нам
		if target:IsHero() then -- если герой то выдаем себе силу
			caster:AddNewModifier(
				caster,
				self,
				"modifier_axe_battle_hunger_lua",
				{ duration = duration, str_bonus_per_hero = str_bonus_per_hero }
			)
		else
			caster:AddNewModifier(
				caster,
				self,
				"modifier_axe_battle_hunger_lua",
				{ duration = duration }
			)
		end

		local sound_cast = "Hero_Axe.Battle_Hunger"
		caster:EmitSound(sound_cast)
	end
end
