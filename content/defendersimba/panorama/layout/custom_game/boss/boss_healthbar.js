function RefreshHealthbar(data) {
//	$.Schedule(0.1, RefreshHealthbar)
	if (data == null) return
	$("#MainPanel").SetHasClass("Hidden", !data.isVisible)
	let Unit = data.index	//Players.GetLocalPlayerPortraitUnit()
	$("#BossName").text = $.Localize("#"+Entities.GetUnitName(Unit))
	
	let Health = data.health	//Entities.GetHealth(Unit)
	let MaxHealth = data.maxHealth	//Entities.GetMaxHealth(Unit)
	$("#BossHealthProgressBar").value = Health / MaxHealth
	$("#ProgressBarLabel").text = `${Health} / ${MaxHealth}`
	
	$("#BossManaProgressBar").SetHasClass("Hidden", data.mana == -1)
	if (data.mana != -1) {
		let Mana = data.mana	//Entities.GetMana(Unit)
		let MaxMana = data.maxMana	//Entities.GetMaxMana(Unit)
		$("#BossManaProgressBar").value = data.mana / data.maxMana
	}
}
function HideHealthbar() {
	$("#MainPanel").SetHasClass("Hidden", true)
}

(function() {
//	$.Schedule(0.1, RefreshHealthbar)
	
	GameEvents.Subscribe("RefreshBossHealthbar", RefreshHealthbar)
	GameEvents.Subscribe("HideBossHealthbar", HideHealthbar)
})();
