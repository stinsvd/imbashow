var center_block = FindDotaHudElement("center_block")
$.GetContextPanel().SetParent(center_block);

function UpdateHeroHudBuffs() {
	let hero_id = Players.GetLocalPlayerPortraitUnit()
	let hero = Entities.GetUnitName(hero_id)
	let WarlockPanel = $("#WarlockBuffPanel")
	WarlockPanel.SetHasClass("panel_hidden", hero != "npc_dota_hero_warlock")
	
	if (!WarlockPanel.BHasClass("panel_hidden")) {
		let Health_stacks = 0
		let Health_amount = 0
		let Mana_stacks = 0
		let Mana_amount = 0
		let HealthRegen_stacks = 0
		let HealthRegen_amount = 0
		let GoldGain_stacks = 0
		let GoldGain_amount = 0
		let ExpGain_stacks = 0
		let ExpGain_amount = 0
		
		let Buff_1_stacks = 0
		let Buff_2_stacks = 0
		let Buff_3_stacks = 0
		let Buff_4_stacks = 0
		let Buff_5_stacks = 0
		
		let data = CustomNetTables.GetTableValue("heroes_stats", "Infernal");
		if (data) {
			Health_stacks = data.bonus_health_stacks
			Health_amount = data.bonus_health
			Mana_stacks = data.bonus_mana_stacks
			Mana_amount = data.bonus_mana
			HealthRegen_stacks = data.bonus_hp_regen_stacks
			HealthRegen_amount = data.bonus_hp_regen
			GoldGain_stacks = data.gold_gain_stacks
			GoldGain_amount = data.gold_gain
			ExpGain_stacks = data.exp_gain_stacks
			ExpGain_amount = data.exp_gain
			
			Buff_1_stacks = data.infrnl_stomp_impact_base_damage
			Buff_2_stacks = data.infrnl_flaming_fists_base_damage
			Buff_3_stacks = data.infrnl_immolation_base_damage_per_second
			Buff_4_stacks = data.infrnl_eonite_heart_burn_damage
			Buff_5_stacks = data.infrnl_infernal_invasion_burn_damage
		}
		
		let StatsBuffs = WarlockPanel.GetChild(0)
		StatsBuffs.SetHasClass("panel_ability", Entities.GetAbilityByName(hero_id, "infrnl_burning_spirit") == -1)
		if (!StatsBuffs.BHasClass("panel_ability")) {
			StatsBuffs.GetChild(0).GetChild(1).text = Health_stacks
			StatsBuffs.GetChild(1).GetChild(1).text = Mana_stacks
			StatsBuffs.GetChild(2).GetChild(1).text = HealthRegen_stacks
			StatsBuffs.GetChild(3).GetChild(1).text = GoldGain_stacks
			StatsBuffs.GetChild(4).GetChild(1).text = ExpGain_stacks
			
			SetShowText(StatsBuffs.GetChild(0), $.Localize("#Infernal_Buff_Health")+" "+Health_amount)
			SetShowText(StatsBuffs.GetChild(1), $.Localize("#Infernal_Buff_Mana")+" "+Mana_amount)
			SetShowText(StatsBuffs.GetChild(2), $.Localize("#Infernal_Buff_HealthRegen")+" "+HealthRegen_amount)
			SetShowText(StatsBuffs.GetChild(3), $.Localize("#Infernal_Buff_GoldGain")+" "+GoldGain_amount)
			SetShowText(StatsBuffs.GetChild(4), $.Localize("#Infernal_Buff_ExpGain")+" "+ExpGain_amount)
		}
		
		let AbilitiesBuffs = WarlockPanel.GetChild(1)
		AbilitiesBuffs.GetChild(0).GetChild(1).text = Buff_1_stacks
		AbilitiesBuffs.GetChild(1).GetChild(1).text = Buff_2_stacks
		AbilitiesBuffs.GetChild(2).GetChild(1).text = Buff_3_stacks
		AbilitiesBuffs.GetChild(3).GetChild(1).text = Buff_4_stacks
		AbilitiesBuffs.GetChild(4).GetChild(1).text = Buff_5_stacks

		for (let i = 0; i < 5; i++) {
			let Buff = AbilitiesBuffs.GetChild(i)
			Buff.SetHasClass("panel_ability", Entities.GetAbilityByName(hero_id, $("#Buff_"+(i+1)+"_ability").abilityname) == -1)
			SetShowText(Buff, $.Localize("#Infernal_Buff_"+(i+1)))
			SetAbilityDesc(Buff, $("#Buff_"+(i+1)+"_ability").abilityname, hero_id)
		}
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
	$("#WarlockBuffPanel").GetChild(0).GetChild(3).GetChild(0).SetImage("s2r://panorama/images/spellicons/alchemist_goblins_greed_png.vtex")
	$("#WarlockBuffPanel").GetChild(0).GetChild(4).GetChild(0).SetImage("s2r://panorama/images/items/tome_of_knowledge_png.vtex")
	UpdateHeroHudBuffs()
})()