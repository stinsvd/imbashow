var center_block = FindDotaHudElement("center_block")
$.GetContextPanel().SetParent(center_block);

function UpdateHeroHudBuffs() {
	let hero_id = Players.GetLocalPlayerPortraitUnit()
	let hero = Entities.GetUnitName(hero_id)
	let WarlockPanel = $("#WarlockBuffPanel")
	WarlockPanel.SetHasClass("panel_hidden", hero != "npc_dota_hero_warlock")
	
	if (!WarlockPanel.BHasClass("panel_hidden")) {
		let Health_stacks = 0
		let Mana_stacks = 0
		let HealthRegen_stacks = 0
		
		let Buff_1_stacks = 0
		let Buff_2_stacks = 0
		let Buff_3_stacks = 0
		let Buff_4_stacks = 0
		
		let data = CustomNetTables.GetTableValue("heroes_stats", "Infernal");
		if (data) {
			Health_stacks = data.bonus_health
			Mana_stacks = data.bonus_mana
			HealthRegen_stacks = data.bonus_hp_regen
			
			Buff_1_stacks = data.infrnl_stomp_impact_base_damage
			Buff_2_stacks = data.infrnl_flaming_fists_base_damage
			Buff_3_stacks = data.infrnl_immolation_base_damage_per_second
			Buff_4_stacks = data.infrnl_eonite_heart_burn_damage
		}
		let StatsBuffs = WarlockPanel.GetChild(0)
		let StatsHealth = StatsBuffs.GetChild(0)
		let StatsMana = StatsBuffs.GetChild(1)
		let StatsHealthRegen = StatsBuffs.GetChild(2)
		StatsHealth.GetChild(1).text = Health_stacks
		StatsMana.GetChild(1).text = Mana_stacks
		StatsHealthRegen.GetChild(1).text = HealthRegen_stacks
		
		let AbilitiesBuffs = WarlockPanel.GetChild(1)
		let Buff1 = AbilitiesBuffs.GetChild(0)
		let Buff2 = AbilitiesBuffs.GetChild(0)
		let Buff3 = AbilitiesBuffs.GetChild(0)
		let Buff4 = AbilitiesBuffs.GetChild(0)
		Buff1.GetChild(1).text = Buff_1_stacks
		Buff2.GetChild(1).text = Buff_2_stacks
		Buff3.GetChild(1).text = Buff_3_stacks
		Buff4.GetChild(1).text = Buff_4_stacks
		
		let bonusesAbility = Entities.GetAbilityByName(hero_id, "infrnl_burning_spirit")
		if (bonusesAbility) {
			Health_stacks = Health_stacks * Abilities.GetSpecialValueFor(bonusesAbility, "bonus_health")
			Mana_stacks = Mana_stacks * Abilities.GetSpecialValueFor(bonusesAbility, "bonus_mana")
			HealthRegen_stacks = HealthRegen_stacks * Abilities.GetSpecialValueFor(bonusesAbility, "bonus_hp_regen")
		}
		SetShowText(StatsBuffs.GetChild(0), $.Localize("#Infernal_Buff_Health")+" "+Health_stacks)
		SetShowText(StatsBuffs.GetChild(1), $.Localize("#Infernal_Buff_Mana")+" "+Mana_stacks)
		SetShowText(StatsBuffs.GetChild(2), $.Localize("#Infernal_Buff_HealthRegen")+" "+HealthRegen_stacks)
		SetAbilityDesc(Buff1, $("#Buff_1_ability").abilityname, hero_id)
		SetAbilityDesc(Buff2, $("#Buff_2_ability").abilityname, hero_id)
		SetAbilityDesc(Buff3, $("#Buff_3_ability").abilityname, hero_id)
		SetAbilityDesc(Buff4, $("#Buff_4_ability").abilityname, hero_id)
	}

	$.Schedule(0.05, UpdateHeroHudBuffs)
}

function SetShowText(panel, text) {
	panel.SetPanelEvent("onmouseover", function() {
		$.DispatchEvent("DOTAShowTextTooltip", panel, text);
	});
	
	panel.SetPanelEvent("onmouseout", function() {
		$.DispatchEvent("DOTAHideTextTooltip", panel);
	});
}
function SetAbilityDesc(panel, ability_name, hero_id) {
	panel.SetPanelEvent("onmouseover", function() {
		$.DispatchEvent("DOTAShowAbilityTooltipForEntityIndex", panel, ability_name, hero_id);
	});
	panel.SetPanelEvent("onmouseout", function() {
		$.DispatchEvent("DOTAHideAbilityTooltip", panel);
	});
}

function HasModifier(unit, modifier) {
	for (var i = 0; i < Entities.GetNumBuffs(unit); i++) {
		if (Buffs.GetName(unit, Entities.GetBuff(unit, i)) == modifier){
			return Entities.GetBuff(unit, i)
		}
	}
	return false
}
function FindDotaHudElement(id) {
	var hudRoot;
	for(panel=$.GetContextPanel();panel!=null;panel=panel.GetParent()){
		hudRoot = panel;
	}
	var comp = hudRoot.FindChildTraverse(id);
	return comp;
}

(function() {
	UpdateHeroHudBuffs()
})()